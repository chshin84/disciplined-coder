# 선행연구 에이전트 탐색 워크플로 — 하부 명세

이 문서는 큰 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`(아래 '큰 명세')의 「워크스트림 분할」에서 `specworkflow` 행을 구현하는 하부 명세다. 2026-10-18에 명세 서브 세션이 썼다. 맡는 파일은 탐색 워크플로 `workflows/prior-art-search.js`, 시험 도구 `scripts/workflow_harness.mjs`, 계약 테스트 `scripts/test_workflow.sh`다.

큰 명세가 고정한 값을 명세 서브 세션은 다시 정하지 않고 절 이름으로 가리켰다. 키 이름과 바깥 형식의 원본은 큰 명세 「출력 스키마」의 「키 이름과 바깥 형식」 표다. 프롬프트 형식의 원본은 같은 절의 「에이전트에게 보내는 프롬프트」이고, 단계 순서의 원본은 「오케스트레이터 절차」 2단계다. 명명과 공용 유틸리티와 주장 참조 형식의 원본은 「결정 기록」이며, 이 하부 명세에는 그 원본이 비워 둔 내부 규칙만 적었다.

리뷰 기록은 `docs/superpowers/reviews/2026-10-18-prior-art-agent-specworkflow-review.md`다. 리뷰로 바뀐 판단은 각 절에 적었다.

## 용어

용어는 큰 명세 「용어」의 이름을 그대로 쓰고, 아래 이름을 덧붙인다.

| 이름 | 뜻 |
|---|---|
| `specagents` | 큰 명세 「워크스트림 분할」의 다른 행이다. 오케스트레이터 스킬과 연구자·검증자 정의를 맡는다 |
| 항목 | 검증자가 판정할 주장의 단위다. 연구자 출력의 `issues` 원소 하나나 `evidence_map` 행 하나가 항목 하나다 |
| 주장 참조 | 항목을 가리키는 문자열 `<하위 질문 ID>#<issue\|case>#<배열 위치>`다. 형식의 원본은 큰 명세 「결정 기록」의 「주장 참조 형식」이다 |
| URL 묶음 | 같은 URL 을 인용한 항목을 모은 단위다. 인용 판정 검증자 하나가 URL 묶음 하나를 맡는다 |
| 판정 함수 | `checkQueries`·`groupByUrl`·`classify`·`mergeStatus`다. 큰 명세 「결정 기록」의 「추상화 수준」이 정한 결정론 판정을 맡는 순수 함수다 |
| 통과 행 | `passed`에 든 항목 중 주장 참조가 `#case#`인 항목이다. `{ ref, row }`로 적는다 |
| 시험 도구 | `scripts/workflow_harness.mjs`다. 워크플로 스크립트를 가짜 런타임 훅으로 node 에서 실행한다 |
| 계약 테스트 | `scripts/test_workflow.sh`다. 시험 도구의 출력과 스크립트 원문을 단언한다. 병합 전 시험(큰 명세 「시험 계획」)과는 다른 대상이다 |
| 응답표 | 계약 테스트가 시험 도구에 넘기는 가짜 에이전트 응답의 표다. 키는 `agent()`의 `label`이다 |

## 맡는 일과 전제

이 워크스트림은 탐색 워크플로의 실행 흐름과 판정 함수를 만들고, 그것을 런타임 없이 확인하는 시험 도구와 계약 테스트를 만든다. 에이전트 정의의 본문과 연구자 출력의 내부 칸(`axes` 안의 형식 등)은 `specagents`가 맡는다. 반환값을 읽어 기록 파일을 쓰는 절차도 `specagents`가 맡는다.

**전제.** 워크플로는 `agent()`의 `agentType` 옵션으로 플러그인 에이전트 `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`를 실행한다. 현재 세션이 2026-10-18에 이 해석을 실측으로 확인했다(큰 명세 「결정 기록」의 「런타임 확인」).

**런타임 제약.** 아래 사실은 내장 `workflow-authoring` 스킬의 원문에서 옮겼다.

- **금지 호출** — 런타임은 파일 시스템과 Node.js API 를 주지 않는다. `Date.now()`·`Math.random()`·인자 없는 `new Date()`를 부르면 예외가 난다.
- **`meta`** — 스크립트의 첫 문장은 순수 리터럴 `export const meta = {...}`여야 한다.
- **실패 반환** — `agent()`는 사용자가 실행 중에 그 에이전트를 건너뛰거나 서브에이전트가 재시도 뒤 API 오류로 끝나면 `null`을 돌려준다. `parallel()`은 예외를 던진 thunk 의 자리에 `null`을 둔다.
- **동시 실행 한도** — 런타임이 `min(16, CPU 수 - 2)`로 정한다.

그래서 스크립트는 시각과 난수를 쓰지 않고 파일을 쓰지 않는다. 기록할 내용은 반환값으로만 넘긴다.

## 실행 흐름

스크립트는 큰 명세 「오케스트레이터 절차」 2단계의 처리를 아래 차례로 한다. 단계 사이에는 모두 `parallel()` 장벽을 둔다. 같은 URL 을 하나로 묶으려면 모든 연구자의 인용이 모여야 하고, 한 항목이 여러 URL 에 기대므로 통과 판정에는 모든 판정이 모여야 하기 때문이다.

1. **탐색(Research)** — 스크립트가 하위 질문마다 연구자를 하나씩 탐색 모드로 실행한다. 옵션은 `agentType: 'disciplined-coder:prior-art-researcher'`, `schema: RESEARCHER_SCHEMA`, `label: 'research:<하위 질문 ID>'`, `phase: 'Research'`다. 스크립트는 `parallel()`의 반환 배열을 하위 질문 차례와 짝지어 `researchers`(`[{ id, output }]`)를 만든다.
2. **질의 경계 검사** — `checkQueries`가 연구자의 `queries`를 검사하고, 스크립트는 그 결과를 `query_violations`에 그대로 둔다. 스크립트는 위반한 연구자의 결과를 지우지 않는다. 검색어는 이미 밖으로 나갔으므로 지워도 되돌릴 것이 없고, 지우면 사용자가 결과와 위반을 함께 볼 수 없기 때문이다.
3. **URL 묶기** — `groupByUrl`이 항목을 뽑고 URL 묶음을 만든다.
4. **인용 판정(Verify)** — 스크립트가 URL 묶음마다 검증자를 인용 판정 모드로 실행한다. 옵션은 `agentType: 'disciplined-coder:prior-art-verifier'`, `schema: VERIFIER_SCHEMA`, `label: 'verify:<URL>'`, `phase: 'Verify'`다. 스크립트는 반환 배열을 URL 묶음 차례와 짝지어 `verifiers`(`[{ url, subquestions, output }]`)를 만든다.
5. **통과 판정과 상태 합치기** — `classify`가 항목의 행선지를 정하고, `mergeStatus`가 커버리지 표와 상태 값을 만든다.
6. **종합(Synthesize)** — `survey` 모드에서만 한다. 통과 행이 하나 이상이면 스크립트가 연구자를 종합 모드로 실행한다(`label: 'synthesize'`, `phase: 'Synthesize'`, `schema: SYNTHESIS_SCHEMA`). 통과 행이 없으면 실행하지 않는다.
7. **지도 대조(MapCheck)** — 종합 결과가 `null`이 아니면 스크립트가 검증자를 지도 대조 모드로 실행한다(`label: 'map-check'`, `phase: 'MapCheck'`, `schema: MAP_SCHEMA`).
8. **반환** — 스크립트가 「반환값의 형식」대로 돌려준다.

`parallel()`에 넘기는 thunk 는 `agent()`를 부르고 그 반환을 돌려주기만 한다. 결과의 짝짓기와 후처리는 `parallel()` 밖에서 반환 배열로 한다. 런타임은 thunk 를 동시에 실행해 완료 차례가 바뀌므로, thunk 안에서 공유 배열에 쌓으면 차례가 흐트러진다. 그리고 thunk 안의 후처리가 던진 예외는 `parallel()`이 `null`로 바꿔 에이전트 실패와 구별되지 않는다(리뷰의 `lens-adversarial` 지적).

`meta`에는 `name: 'prior-art-search'`, 한 줄 `description`, `whenToUse`, `phases`를 둔다. `whenToUse`에는 `agent-prior-art` 오케스트레이터가 승인받은 프로토콜로만 실행한다고 적는다. `phases`의 제목은 `Research`·`Verify`·`Synthesize`·`MapCheck`이며 `phase` 옵션의 문자열과 글자가 같다.

스크립트는 어느 `agent()` 호출에도 `model`과 `effort` 옵션을 넣지 않는다. 큰 명세 「판정 모델 교체」는 검증자 정의의 `model`만 바꿔 판정 모델을 바꾼다. `workflow-authoring` 스킬은 `opts.model`이 그 호출의 모델을 바꾼다고만 적고, `agentType`으로 고른 정의의 `model`과 어느 쪽이 이기는지는 적지 않는다. 그래서 정의의 값이 쓰이도록 호출 쪽 옵션을 비운다.

## 판정 함수

판정 함수는 모두 스크립트 끝에 `function` 선언으로 두고, 본문의 `const`(스키마 등)와 런타임 훅(`log` 등)을 참조하지 않는다. 시험 도구가 본문이 실행되기 전에 판정 함수를 부르기 때문이다. 끌어올림은 `function` 선언에만 일어나고, `const`를 초기화 전에 참조하면 예외가 난다. 정규식은 함수 안에 리터럴로 둔다.

**`checkQueries(researchers, forbiddenTerms)`** — 이 함수는 `output`이 `null`이 아닌 연구자의 `queries`를 차례로 보고 `[{ id, query, rule }]`을 돌려준다. `rule`의 값은 아래와 같다.

- **`forbidden-term`** — 대소문자를 무시하고 `forbidden_terms`의 원소 하나라도 검색어에 들어 있다. 빈 문자열 원소는 무시한다.
- **`path-shape`** — 검색어를 공백으로 나눈 토큰 중 하나가 경로 형태다. 토큰 앞뒤의 따옴표·괄호·대괄호·쉼표·마침표·쌍점·쌍반점을 떼고 본다. 경로 형태는 `~/`·`./`·`../`·`/`로 시작하는 토큰과, `C:\`·`C:/`처럼 드라이브 문자로 시작하는 토큰이다. `/`나 `\`를 포함하고 `.` 뒤 영문자로 시작하는 1~5자의 확장자로 끝나는 토큰도 경로 형태다.

`A/B`처럼 확장자도 시작 기호도 없는 토큰과 `HTTP/1.1`처럼 확장자가 숫자로 시작하는 토큰은 경로로 보지 않는다. 이 규칙은 `SKILL.md` 같은 맨 파일 이름과 `agents/x`처럼 확장자 없는 상대 경로를 놓친다. 그래서 위반 수 0 은 '경로를 넣지 않았다'의 증명이 되지 못한다. 한 검색어가 규칙 둘에 모두 해당하면 원소가 둘이고, 한 규칙에 금지어 여럿이 해당해도 원소는 하나다.

**`groupByUrl(researchers)`** — 이 함수는 `{ items, groups }`를 돌려준다. `output`이 `null`인 연구자는 항목을 내지 않는다.

- **`items`** — `[{ ref, urls, text, row? }]`다. 차례는 하위 질문 차례이고, 그 안에서 `issues`가 `evidence_map`보다 앞이며, 그 안에서는 배열 위치 차례다.
- **이슈 항목** — `urls`는 `citations`에서 빈 문자열이 아닌 `url`을 중복 없이 모은 것이고 `text`는 그 이슈의 `prior_claim`이다(큰 명세 「공유 결정」의 「인용 판정 범위」).
- **근거 지도 항목** — `urls`는 그 행의 `url`이 빈 문자열이 아니면 그 하나이고, 비었으면 빈 배열이다. `text`는 `JSON.stringify({ case, outcome, prior })`이고 `prior`는 네 축의 `prior`만 모은 객체다. `row`는 행 전체다. 칸의 정의는 `specagents` 「출력 스키마를 옮기는 규칙」에 있다.
- **`groups`** — `[{ url, subquestions, claims: [{ ref, text }] }]`이며 URL 이 처음 나온 차례다. `subquestions`는 그 URL 을 인용한 하위 질문 ID 를 중복 없이 모은 것이다. URL 은 문자열이 같을 때만 같은 묶음이다.

`kind`가 `derived`인 인용처럼 URL 이 없는 인용은 묶음을 만들지 않는다. 그런 인용에만 기댄 항목은 `urls`가 빈 배열이 되어 「목록의 행선지」에 따라 `rejected`로 간다.

**`classify(items, verifiers)`** — 이 함수는 `{ passed, rejected, unverifiable, verify_failed }`를 돌려준다. `passed`·`rejected`·`unverifiable`의 원소는 `{ ref, urls }`이고 `urls`는 그 항목의 `urls` 전체다. `verify_failed`의 원소는 `{ url, refs }`이며 URL 묶음 차례다. 행선지는 「목록의 행선지」를 따른다.

`classify`는 검증자 출력의 `url` 칸을 보지 않고, 그 검증자에게 보낸 URL 묶음의 `url`을 쓴다. 그 묶음에 보내지 않은 `ref`의 판정은 버린다.

**`mergeStatus(researchers, items, classified)`** — 이 함수는 `{ coverage, subquestion_status, overall_status }`를 돌려주며, 원소는 하위 질문 차례다. 값의 뜻은 큰 명세 「오케스트레이터 절차」의 「상태 값」이 원본이다.

- **`coverage[k]`** — `cases_found`는 그 하위 질문의 항목 수(이슈와 근거 지도 행의 합)이고, `passed`는 그중 `passed`에 든 수다.
- **`search_status`** — 연구자 출력의 값이고, 출력이 `null`이면 `failed`다.
- **`verification_status`** — `verify_failed`의 어느 원소의 `refs`에 `<그 하위 질문 ID>#`로 시작하는 참조가 하나라도 있으면 `partial`이고, 없으면 `ok`다.
- **`overall_status`** — 모든 하위 질문의 두 값이 `ok`이면 `ok`이고, 아니면 `not-ok`다.

## 목록의 행선지

`classify`는 항목마다 아래 표를 위 행부터 차례로 보고, 처음 해당하는 행의 행선지에 그 항목을 둔다. 표의 '판정'은 그 항목의 `ref`로 나온 판정이며, 그 항목의 `urls` 중 검증자가 실패하지 않은 URL 에서 나온 것만 든다. 표의 '실패한 URL'은 그 항목의 `urls` 중 검증자가 실패한 URL 이다.

검증자의 실패는 두 경우다. 하나는 `agent()`가 `null`을 돌려준 경우다. 다른 하나는 검증자가 응답했지만 그 묶음에 보낸 `ref` 중 하나라도 판정을 내지 않은 경우다. 뒤의 경우는 출력이 큰 명세의 「인용 판정 출력」 계약(주장별 `verdict`)을 지키지 못한 에이전트 실패로 보고, 그 묶음의 판정을 모두 버린다. 그래서 `verify_failed`는 큰 명세 「상태 값」의 '검증자 에이전트의 실패'만 뜻한다(리뷰의 `lens-consistency` 지적 뒤 판정 누락을 따로 두던 규칙을 바꾸었다).

| 조건 | 행선지 | 이유 |
|---|---|---|
| 판정 중 `supported`가 하나라도 있다 | `passed`에 둔다 | 큰 명세 「오케스트레이터 절차」 2단계에서 `supported` 판정에 기댄 사례만 통과한다 |
| 실패한 URL 이 하나라도 있다 | 어느 판정 목록에도 두지 않는다 | 판정을 받지 못한 URL 이 지지했을 수 있으므로, 탈락으로 단정하면 판정의 역전이 된다 |
| 판정이 하나 이상이고 모두 `unverifiable`이다 | `unverifiable`에 둔다 | 큰 명세 「출력 스키마」에서 `unverifiable`은 반박이 아니다 |
| 앞의 조건에 들지 않는다(판정에 `unsupported`가 있거나 `urls`가 비었다) | `rejected`에 둔다 | 지지 구절을 얻지 못했다 |

`verify_failed`는 실패한 URL 마다 원소 하나이고, `refs`는 그 묶음에 보낸 참조 전부다. 그래서 다른 URL 에서 `supported`를 받은 항목은 `passed`에 들면서 그 참조가 `verify_failed`에도 나올 수 있다. 오케스트레이터가 사례 수를 셀 때는 `passed`·`rejected`·`unverifiable`만 세고 `verify_failed`는 세지 않는다.

연구자가 `null`이면 그 하위 질문은 항목을 내지 않으므로 검증자도 실행되지 않는다. 그 하위 질문의 `search_status`는 `failed`이고 `verification_status`는 `ok`이며, `overall_status`는 `not-ok`가 된다. 사용자가 건너뛴 에이전트도 `null`이므로 같은 행선지로 간다. 런타임이 두 경우를 구별해 주지 않기 때문이다.

**사유의 위치.** 큰 명세 2단계는 탈락·판정 불가·검증 실패 목록에 사유를 함께 적으라고 한다. 목록 원소는 큰 명세 표의 `{ ref, urls }`와 `{ url, refs }`를 그대로 쓰므로, 사유는 아래 칸에서 읽는다.

- **`rejected`·`unverifiable`** — `verifiers[].output.judgments[]` 중 같은 `ref`의 `verdict`와 `reason`이다. `urls`가 빈 `rejected` 원소의 사유는 '인용에 URL 이 없다'이다.
- **`verify_failed`** — 같은 `url`의 `verifiers[].output`이다. `null`이면 에이전트가 응답하지 않았고, `null`이 아니면 판정이 빠진 출력이다.

## 반환값의 형식

반환값의 키 목록은 큰 명세 「키 이름과 바깥 형식」 표의 '워크플로 반환값' 행이 원본이다. `round`는 `args.round`를 그대로 옮긴 값이다. 그 표가 형식을 적지 않은 키는 아래와 같다.

| 키 | 형식 | 정한 이유 |
|---|---|---|
| `researchers` | 하위 질문 차례의 `[{ id, output }]`이다. `output`은 연구자 출력이거나 `null`이다 | 오케스트레이터가 `researcher-<하위 질문 ID>-r<n>.json`을 쓰려면 실패한 연구자의 ID 도 있어야 한다 |
| `verifiers` | URL 묶음 차례의 `[{ url, subquestions, output }]`이다. `output`은 인용 판정 출력이거나 `null`이다 | 큰 명세 「원본 파일 규칙」에서 `verifier-r<n>.json`은 판정마다 그 URL 을 인용한 하위 질문 ID 를 적는다 |
| `verifier_count` | `verifiers`의 길이다. 실패한 검증자도 세고, 지도 대조 검증자는 세지 않는다 | 큰 명세 표가 이 키를 인용 판정 검증자 수로 정한다 |
| `synthesis` | `survey`에서만 두는 키다. 종합 모드 연구자 출력이거나 `null`이다 | 큰 명세 표가 `survey`에서만 두는 키로 표시한다 |
| `map_check` | `survey`에서만 두는 키다. 지도 대조 출력이거나 `null`이다 | 큰 명세 표가 `survey`에서만 두는 키로 표시한다 |

`synthesis`가 `null`인 사정은 통과 행이 없어 실행하지 않은 때와, 실행했으나 실패한 때다. 오케스트레이터는 통과 행이 있는지로 두 사정을 구별한다. `synthesis`가 `null`이면 지도 대조를 실행하지 않으므로 `map_check`도 `null`이다.

두 값은 `overall_status`에 영향을 주지 않는다. 큰 명세의 `overall_status`는 하위 질문의 두 값으로만 정해지기 때문이다.

## 프롬프트와 입력

프롬프트의 줄 형식(`MODE:`·`PRINCIPLES:`와 모드 값)과 모드별 입력의 키는 큰 명세 「에이전트에게 보내는 프롬프트」가 원본이다. 명세 서브 세션은 아래만 정했다.

- **JSON 블록** — 셋째 줄부터 ` ```json ` 줄, `JSON.stringify(입력, null, 2)`, ` ``` ` 줄을 차례로 둔다. 프롬프트는 이 블록에서 끝난다.
- **`PRINCIPLES:`의 값** — `args.principles_path`를 그대로 옮긴다.
- **`args`에서 옮기는 값** — 탐색 모드의 `question`·`situation`·`target`·`mode`·`forbidden_terms`와 종합 모드의 `question`·`target`은 `args`의 값을 그대로 옮긴다. 탐색 모드의 `subquestion`에는 프로토콜의 하위 질문 객체 `{ id, scope, include, exclude }`를 그대로 넣는다.
- **통과 행 배열** — 종합 모드의 `passed_rows`와 지도 대조 모드의 `passed`는 같은 배열이며, 통과 행을 `passed` 차례로 담는다. 종합 결과의 `conclusions[].refs`와 지도 대조의 `source_ref`가 이 `ref`를 가리킨다.
- **지도 대조 모드의 `evidence_map`** — 종합 출력의 `evidence_map`이다.
- **인용 판정 모드의 입력** — URL 묶음의 `{ url, claims }`다. `text`의 형태는 「판정 함수」의 `groupByUrl` 항목이 정한다.

근거 지도 항목의 `text` 형태는 검증자 정의가 판정 기준을 적용할 입력이다. 그래서 명세 서브 세션은 이 형태를 리포트의 「확정한 계약 의미」에 적어 현재 세션에 넘겼다.

스크립트는 네 모드가 함께 쓰는 프롬프트 도우미 함수 하나를 둔다. 이 도우미는 판정 함수가 아니어서 시험 도구가 이름으로 부르지 않는다. 계약 테스트는 시험 도구가 기록한 프롬프트로 형식을 확인한다.

## 출력 스키마 상수

`agent()`에 넘기는 스키마의 `required`에는 큰 명세 「키 이름과 바깥 형식」 표가 키 이름을 적은 칸 중 모드와 무관하게 늘 있는 칸을 둔다. 연구자 출력은 그 표가 키를 현행 렌즈 칸에 기대어 적으므로, `required`에는 워크플로가 읽는 칸만 둔다. 출력의 칸은 `specagents`가 소유하고(큰 명세 공유 항목 표 첫 행), 큰 명세가 적지 않은 칸까지 묶으면 두 워크스트림의 형식이 어긋날 때 실패만 늘기 때문이다(리뷰의 `lens-consistency` 지적 뒤 규칙과 표를 맞추었다).

런타임은 루트가 `type: 'object'`가 아니거나 `required`가 `properties`의 부분집합이 아닌 스키마에 예외를 던진다. 그래서 상수의 루트는 `type: 'object'`이며 모든 객체 스키마에서 `required`는 `properties`의 부분집합이다.

| 상수 | 루트의 `required` | 원소의 `required` | 열거로 묶는 칸 |
|---|---|---|---|
| `RESEARCHER_SCHEMA` | `search_status`, `queries`, `issues` | 없음 | `search_status`의 `ok`·`no-results`·`failed`·`not-attempted` |
| `VERIFIER_SCHEMA` | `url`, `judgments`, `principles_applied` | `judgments` 원소의 `ref`, `verdict`, `quote`, `reason` | `verdict`의 `supported`·`unsupported`·`unverifiable` |
| `SYNTHESIS_SCHEMA` | `evidence_map`, `conclusions`, `principles_applied` | 없음 | 없음 |
| `MAP_SCHEMA` | `cells`, `principles_applied` | `cells` 원소의 `row`, `column`, `grounded`, `source_ref` | 없음 |

`RESEARCHER_SCHEMA`는 `evidence_map`과 이슈의 `citations`를 `properties`에 두되 `required`에 넣지 않는다. `contrast` 모드의 연구자는 `evidence_map`을 채우지 않기 때문이다.

## 시험 도구

`scripts/workflow_harness.mjs`는 node 로 실행하는 ES 모듈이다. 워크플로 스크립트의 경로는 `import.meta.url` 기준 `../workflows/prior-art-search.js`로 정하며 인자로 받지 않는다. 시험 도구는 입력 JSON 을 표준 입력으로 받고, 결과를 표준 출력에 `JSON.stringify` 한 줄로 쓴다.

입력을 인자로 받지 않는 이유는 MSYS2 의 자동 경로 변환이다. MSYS2 문서 「Filesystem Paths」(https://www.msys2.org/docs/filesystem-paths/)는 Git Bash 같은 MSYS2 셸이 네이티브 프로그램에 넘기는 인자 중 POSIX 경로처럼 보이는 문자열을 Windows 경로로 바꾼다고 적는다. 시험 입력에는 `/`로 시작하는 경로 형태의 검색어가 들어가므로, 인자로 넘기면 node 가 바뀐 문자열을 받을 수 있다. 어떤 입력이 실제로 바뀌는지는 측정하지 않았고, 표준 입력은 그 변환을 받지 않는다.

**적재.** 시험 도구는 파일 첫 줄의 맨 앞 `export ` 일곱 글자만 뗀다. 첫 줄이 `export const meta = {`로 시작하지 않으면 종료 코드 2로 끝난다. 다른 `export`는 떼지 않으므로 그대로 남으면 구문 오류가 된다. 런타임이 거부하는 스크립트를 시험 도구가 통과시키지 않게 하기 위해서다(이미 겪은 함정).

시험 도구는 뗀 본문을 `AsyncFunction`의 본문으로 삼고, 매개변수는 `agent`·`parallel`·`phase`·`log`·`args`·`__fn`·`__fnArgs`로 둔다. 본문 앞에는 `'use strict';`와 `if (__fn) return eval(__fn)(...__fnArgs);` 두 줄을 덧붙인다. 직접 `eval`은 함수 안의 끌어올린 `function` 선언을 볼 수 있어, 본문이 실행되기 전에 판정 함수를 부를 수 있다. 런타임이 엄격 모드로 실행하는지는 확인하지 못했으므로, 시험 도구를 엄격 쪽에 맞춰 엄격 모드에서만 나는 오류를 먼저 잡는다.

**하위 명령.**

| 명령 | 표준 입력 | 표준 출력 |
|---|---|---|
| `fn <함수 이름>` | 인자 배열 | 그 함수의 반환값 |
| `run` | `{ args, responses }` | `{ result, calls, logs }` |

`fn`의 함수 이름이 판정 함수가 아니면 시험 도구는 종료 코드 2로 끝난다. `fn`은 훅 매개변수에 `undefined`를 넘긴다. 판정 함수는 훅을 쓰지 않으므로, 판정 함수가 훅을 부르면 예외가 나서 그 규칙 위반이 드러난다.

`run`은 `args`를 런타임의 `args`로 넘기고 가짜 `agent`·`parallel`·`phase`·`log`를 준다. 스크립트가 이 밖의 훅(`pipeline`·`budget`·`workflow`)을 쓰면 정의되지 않은 이름이라 예외가 나고, 시험 도구는 종료 코드 1로 끝난다.

**가짜 `agent(prompt, opts)`.** 가짜 `agent`는 먼저 `opts.schema`를 검사한다. 루트가 `type: 'object'`가 아니거나 어느 객체 스키마에서든 `required`가 `properties`의 부분집합이 아니면 치명 오류다. 검사를 통과하면 `calls`에 `{ label, agentType, phase, model, effort, prompt }`를 덧붙이고, `responses[label]`의 깊은 사본을 돌려준다. 값이 `null`이면 `null`을 돌려준다.

`responses`에 `label`이 없으면 그것도 치명 오류다. 응답표에 없는 호출이 조용히 `null`로 통과하면, 실행되지 말아야 할 호출을 시험이 잡지 못하기 때문이다. 시험 도구는 치명 오류마다 내부 표시를 남기고 예외를 던진다. 스크립트나 가짜 `parallel`이 그 예외를 삼켜도, 시험 도구는 실행이 끝난 뒤 표시를 보고 종료 코드 1로 끝난다(리뷰의 `lens-adversarial` 지적).

**가짜 `parallel`·`phase`·`log`.** 가짜 `parallel(thunks)`은 thunk 를 차례로 실행해 결과를 차례대로 돌려주고, 예외를 던진 thunk 의 자리에는 `null`을 둔다. 가짜 `log(message)`는 메시지를 `logs`에 덧붙이고, 가짜 `phase(title)`는 아무것도 하지 않는다. 로그 문구는 계약이 아니므로 계약 테스트가 단언하지 않는다.

**종료 코드.** 성공은 0, 스크립트 예외나 치명 오류는 1, 사용법 오류는 2다. 계약 테스트는 출력을 해석하는 단언으로 실패를 잡으므로 종료 코드에만 기대지 않는다.

## 계약 테스트

`scripts/test_workflow.sh`는 저장소의 다른 계약 테스트처럼 `set -euo pipefail`로 시작한다. 단언에는 `scripts/_test_check.sh`의 `check`를 쓰고, JSON 해석에는 `scripts/_json_valid.sh`의 `json_run`을 쓴다. 큰 명세 「결정 기록」의 공용 유틸리티 목록은 같은 파일의 `json_valid_stdin`을 들지만, 그 함수는 유효성만 보고 값을 꺼내지 못한다. `json_run`은 `json_valid_stdin`이 쓰는 같은 파일의 기반 함수다.

묶음 머리는 `echo "[<묶음 이름>]"`이다(큰 명세 「결정 기록」의 「명명」). CI 의 `contracts` 작업이 `scripts/test_*.sh`를 모두 실행하므로 따로 등록하지 않는다.

**단언 규칙.** 아래 규칙은 큰 명세 「결정 기록」의 「이미 겪은 함정」이 가리키는 렌즈 원본에서 나왔다.

- **출력 해석** — 시험 도구의 출력은 한 줄 JSON 이므로 `grep -c`로 세지 않는다. 계약 테스트는 값을 `json_run`의 파이썬 식으로 꺼내 기대값과 같은지 비교한다.
- **양의 단언** — `! 명령 | grep` 형태의 부정 단언을 쓰지 않는다. 실행 오류도 '찾지 못함'이 되어 통과로 세기 때문이다. '무엇이 없다'는 단언도 해석한 값이 빈 배열이나 0 과 같은지로 쓴다.
- **node 확인** — 첫 묶음에서 `command -v node`를 단언한다. node 가 없으면 이 단언과 시험 도구를 쓰는 모든 단언이 FAIL 이 된다. 검증하지 못한 것을 통과로 세지 않는 규칙은 `scripts/_json_valid.sh`의 머리 주석과 같다.
- **입력 heredoc** — 응답표와 `args`는 테스트 파일 안의 heredoc 으로 두고, 구분자는 따옴표로 감싼다(`<<'EOF'`). 따옴표 없는 heredoc 은 역슬래시와 `$`를 바꾸기 때문이다. 시험 도구에는 표준 입력으로 넘긴다.
- **묶음 FAIL 수** — 구현 중 한 묶음의 FAIL 수는 큰 명세 「결정 기록」의 「묶음 FAIL 수 세기」 명령으로 센다.

아래 표가 묶음과 그 안의 단언이다. 판정 함수 묶음은 출력 전체가 기대값과 같은지로 단언한다. 그래서 차례와 중복 제거와 `text`·`row` 같은 세부 규칙도 함께 확인된다.

| 묶음 | 입력 | 기대 결과 |
|---|---|---|
| `[정적 형식]` | 스크립트 원문 | node 가 있다. 첫 줄이 `export const meta = {`로 시작한다. 줄 머리(공백 뒤 포함)가 `export `인 줄이 정확히 하나다. 첫 줄부터 줄 전체가 `}`나 `};`인 첫 줄까지를 `meta` 구간으로 본다. `meta` 구간에는 `(`·`${`·`...`·백틱이 없고 `name: 'prior-art-search'`가 있으며, `Research`·`Verify`·`Synthesize`·`MapCheck` 제목이 있다. 원문에 `Date.now`·`Math.random`·`new Date(`·`require(`·`import `가 없다. 줄 단위 원문이라 `grep -c`의 줄 수가 뜻에 맞는다 |
| `[질의 경계 검사]` | `fn checkQueries` | 금지어 `Acme`에 검색어 `acme agent plugin`이 `forbidden-term`으로 잡힌다. 빈 문자열 금지어는 아무 검색어도 잡지 않는다. `skills/agent-prior-art/SKILL.md`, `C:\Users\x\a.md`, `~/.claude`, `(docs/x.md),`를 포함한 검색어가 각각 `path-shape`로 잡힌다. `A/B testing`, `HTTP/1.1 caching`, `prior art search agent`는 잡히지 않는다. 금지어 둘과 경로를 함께 담은 검색어는 원소 둘을 낸다. `output`이 `null`인 연구자는 원소를 내지 않는다. 출력이 기대 배열과 같다 |
| `[URL 묶기]` | `fn groupByUrl` | 하위 질문 둘이 같은 URL 을 인용하면 묶음 하나에 참조 둘과 하위 질문 ID 둘이 든다. URL 둘을 인용한 이슈는 묶음 둘에 든다. 한 이슈가 같은 URL 을 두 번 인용해도 `urls`에는 하나다. URL 이 없는 인용만 가진 이슈와 `url`이 빈 근거 지도 행은 `urls`가 빈 배열이고 묶음을 만들지 않는다. 근거 지도 항목의 `text`와 `row`가 정해진 형태다. `output`이 `null`인 연구자는 항목을 내지 않는다. 출력이 기대 `{ items, groups }`와 같다 |
| `[통과 판정]` | `fn classify` | `supported`가 하나라도 있으면 `passed`다. 모두 `unverifiable`이면 `unverifiable`이다. `unsupported`만 있으면 `rejected`이고, `urls`가 빈 항목도 `rejected`다. 한 URL 이 `unsupported`이고 다른 URL 의 검증자가 `null`인 항목은 판정 목록 어디에도 없고 `verify_failed`의 그 URL 원소에 있다. 한 URL 이 `supported`이고 다른 URL 의 검증자가 `null`인 항목은 `passed`에 있고 그 참조가 `verify_failed`에도 있다. 응답한 검증자가 한 참조의 판정을 빠뜨리면 그 URL 이 `verify_failed`에 보낸 참조 전부와 함께 든다. 검증자 출력의 `url`이 보낸 URL 과 달라도 결과가 같다. 보내지 않은 참조의 판정은 결과에 없다. 출력이 기대값과 같다 |
| `[상태 합치기]` | `fn mergeStatus` | 연구자가 `null`인 하위 질문은 `search_status`가 `failed`다. `verify_failed`에 `S1#` 참조만 있으면 S1 은 `partial`이고 S2 는 `ok`다. 하나라도 `ok`가 아니면 `overall_status`는 `not-ok`이고, 모두 `ok`이면 `ok`다. `no-results`도 `not-ok`를 만든다. 출력이 기대값과 같다(`coverage` 포함) |
| `[실행 흐름: contrast]` | `run`, 하위 질문 둘 | 연구자 호출의 `agentType`과 `phase`가 `disciplined-coder:prior-art-researcher`와 `Research`이고, 검증자 호출은 `disciplined-coder:prior-art-verifier`와 `Verify`다. 연구자 프롬프트의 첫 줄이 `MODE: explore`, 둘째 줄이 `PRINCIPLES: <args 의 경로>`다. 그 JSON 블록이 큰 명세의 탐색 모드 입력 키를 정확히 가지고 값이 `args`와 같다. 검증자 프롬프트의 첫 줄은 `MODE: cite`이고 블록은 `{ url, claims }`다. 검증자 호출 수와 `verifier_count`가 서로 다른 URL 수와 같다. `synthesize`·`map-check` 호출 수가 0 이다. 모든 호출의 `model`과 `effort`가 없다. 반환값의 키 집합이 큰 명세 표의 키에서 `synthesis`·`map_check`를 뺀 집합과 같다. `round`가 `args.round`와 같다. 금지어가 든 검색어가 `query_violations`에 든다 |
| `[실행 흐름: survey]` | `run`, 하위 질문 둘 | `synthesize` 호출이 하나이고, 첫 줄이 `MODE: synthesize`이며 `phase`가 `Synthesize`다. 그 블록이 `{ question, target, passed_rows }` 키를 정확히 가지고 `passed_rows`는 통과 행과 같다. `map-check` 호출이 하나이고, 첫 줄이 `MODE: map`이며 `phase`가 `MapCheck`다. 그 블록이 `{ evidence_map, passed }` 키를 정확히 가진다. `verifier_count`가 지도 대조 검증자를 세지 않는다. 반환값에 `synthesis`와 `map_check`가 있다. 통과 행이 없는 응답표에서는 `synthesize` 호출 수가 0 이고 `synthesis`가 `null`이다. 종합 응답이 `null`인 응답표에서는 `map-check` 호출 수가 0 이고 `map_check`가 `null`이다 |
| `[실패 행선지]` | `run` | 검증자가 `null`인 URL 이 `verify_failed`에 그 묶음의 참조 전부와 함께 든다. 그 URL 을 인용한 하위 질문이 `partial`이고 `overall_status`가 `not-ok`다. `verifier_count`가 `null`인 검증자를 센다. 연구자가 `null`인 하위 질문은 `search_status`가 `failed`이고 `researchers`에 `output: null`로 남는다 |
| `[시험 도구 자체]` | `run`과 `fn` | 응답표에 없는 `label`을 부르는 응답표로 `run`을 실행하면 종료 코드가 1 이다. `fn`에 판정 함수가 아닌 이름을 주면 종료 코드가 2 다 |

`[시험 도구 자체]` 묶음은 종료 코드를 `$?`로 받아 기대값과 같은지로 단언한다. 응답표 누락이 조용히 통과하면 다른 묶음의 단언이 모두 헛돌기 때문이다. `scripts/test_assertions.sh`는 묶음마다 `check`가 하나 이상 있는지 검사하므로, 위 묶음은 모두 그 검사를 통과해야 한다.

## 결정 기록에서 따르는 것

- **명명** — 계약 테스트 이름과 묶음 머리와 단언 함수는 큰 명세 「결정 기록」의 「관례 골격」을 따른다. 시험 도구는 계약 테스트가 아니므로 `test_` 접두사를 쓰지 않는다.
- **오류 처리** — `agent()`가 `null`을 돌려주면 스크립트는 예외를 던지지 않고, 「목록의 행선지」와 `mergeStatus`의 규칙으로 상태와 목록에 반영한다.
- **추상화 수준** — 판정 함수는 「용어」에 적은 것뿐이다. 프롬프트 도우미는 판정을 하지 않는 형식 함수다.
- **디렉터리 구조** — 워크플로는 `workflows/`, 시험 도구와 계약 테스트는 `scripts/`에 둔다.

## 열린 위험

**시험 도구와 런타임의 차이.** 시험 도구는 런타임의 훅을 흉내 낼 뿐이다. `agentType` 해석, 스키마 강제, 동시 실행, 엄격 모드 여부, `label` 길이 제한은 확인하지 못한다. 실제 런타임의 적재는 병합 전 시험(큰 명세 「시험 계획」)에서 처음 실행된다.

**CI 의 node.** CI 의 `contracts` 작업에는 `setup-node` 단계가 없다. 명세 서브 세션은 GitHub 의 `ubuntu-latest` 이미지에 node 가 미리 설치되어 있다고 가정했다. 이 가정이 틀리면 `[정적 형식]`의 node 단언이 FAIL 로 드러난다.

**근거 지도 항목의 판정 범위.** 처음 쓴 형태 `{ case, axes, outcome }`에는 대조 대상 쪽의 같음·다름이 들어 있어, 판정 기준을 그대로 적용하면 항목이 계통적으로 `unsupported`가 될 수 있었다. 완전체 명세에서 판정 대상을 선행 사례 쪽 서술로 정했고 `text`의 형태를 바꿨다(큰 명세 「공유 결정」). 연구자가 `prior` 칸을 비우면 그 항목은 판정 근거가 없어 탈락하므로, 그 비율은 병합 전 시험에서 확인한다.

**판정 누락 검증자의 판정 폐기.** 판정을 빠뜨린 검증자는 실패로 보고 그 묶음의 판정을 모두 버린다. 그래서 같은 출력 안의 `supported` 판정도 쓰이지 않아, 통과 사례 수가 줄 수 있다.

<!-- spec-review: passed -->
