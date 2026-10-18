# 선행연구 에이전트 specagents — 하부 명세

2026-10-18에 명세 서브 세션이 큰 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md` 「워크스트림 분할」의 `specagents` 행을 구현할 하부 명세로 썼다. 이 문서는 오케스트레이터 스킬, 연구자와 검증자 정의, 발동 넛지, 그리고 「기존 파일과의 관계」 절 전체를 구현하는 데 필요한 내용만 적는다. 탐색 워크플로 `workflows/prior-art-search.js`는 `specworkflow`가 맡으므로 다루지 않는다. 리뷰 기록은 `docs/superpowers/reviews/2026-10-18-prior-art-agent-specagents-review.md`이며, 리뷰로 바뀐 판단은 각 절에 적었다.

## 큰 명세에서 가리키는 값

이 워크스트림은 큰 명세가 고정한 값을 다시 정하지 않고 그대로 옮긴다. 빌더(이 문서로 plan 을 쓰고 구현하는 구현 서브 세션)는 아래 절을 원본으로 삼는다.

| 값 | 큰 명세의 원본 |
|---|---|
| 구성 요소의 위치, 도구, `maxTurns` | 「구성」 |
| JSON 키 이름과 바깥 형식, 결측 처리 | 계약 코드 `scripts/prior_art_contract.json`과 「다시 나눈 분할」의 계약 표(「키 이름과 바깥 형식」은 같은 내용을 옮겨 적은 표) |
| 워크플로가 에이전트에게 보내는 프롬프트의 형식 | 「출력 스키마」의 「에이전트에게 보내는 프롬프트」 |
| 제안·승인·판정 기록·서브 세션 규칙과 넛지 조건 | 「발동과 기록」 |
| 관례 골격, 공용 유틸리티, 주장 참조 형식, 묶음 FAIL 수 세기 | 「결정 기록」 |
| 연구자 수의 통상 2와 최대 20, 공백 라운드 1회 | 「실행할 때 지킬 상한」 |

옛 렌즈의 원문은 커밋 `7a2d26d`의 `skills/lens-prior-art/SKILL.md`다. 아래에서 '옛 렌즈'는 그 파일을 가리킨다.

## 산출 파일

이 워크스트림이 만들거나 고치거나 지우는 파일은 아래가 전부다. 기존 파일에서 고칠 줄은 「참조 처리 목록」이 정한다.

| 파일 | 처리 | 정하는 절 |
|---|---|---|
| `skills/agent-prior-art/SKILL.md` | 새로 만든다 | 「스킬의 절과 옮길 원본」 |
| `agents/prior-art-researcher.md` | 새로 만든다 | 「연구자와 검증자 정의」 |
| `agents/prior-art-verifier.md` | 새로 만든다 | 「연구자와 검증자 정의」 |
| `hooks/prior_art_nudge_userpromptsubmit.sh` | 새로 만든다 | 「발동 넛지」 |
| `hooks/hooks.json` | `UserPromptSubmit` 연결을 추가한다 | 「발동 넛지」 |
| `README.md` | 훅 표의 행과 끄는 변수를 추가한다 | 「발동 넛지」 |
| `scripts/test_hooks.sh` | 넛지 묶음을 추가한다 | 「계약 테스트」 |
| `scripts/test_docs_drift.sh` | 기존 검사를 바꾸고 묶음을 추가한다 | 「계약 테스트」 |
| `skills/lens-prior-art/` | 디렉터리를 지운다 | 「구현 순서의 제약」 |
| 그 밖에 `lens-prior-art`를 부르거나 전제로 한 파일 | 고친다 | 「참조 처리 목록」 |

## 스킬의 frontmatter

`skills/agent-prior-art/SKILL.md`의 frontmatter 는 `name: agent-prior-art`와 `description` 두 키다. `description`에는 여는 때, 넛지 주제어("선행연구", "prior art", "선행 사례", "누가 해봤"), 옛 이름 `lens-prior-art`와 "선행연구렌즈"를 넣는다. 값은 YAML 평문 스칼라라 `: `와 ` #`을 넣지 않는다(`domain-plugin` 「frontmatter」).

빌더는 아래 초안을 그대로 쓴다. 병합 전 발동 시험에서 고칠 필요가 드러나면 현재 세션이 고친다.

> 선행연구·선행 사례·prior art를 찾아 달라거나 "이걸 이미 누가 해봤나"·"쓸 만한 도구가 있나"·"이 결정의 근거를 찾아 달라"고 할 때, 그리고 review-specs·review-docs가 선행연구를 제안해 승인받았을 때 연다. 연구 계획을 승인받고 연구자 서브에이전트 여럿으로 웹을 탐색한 뒤 검증자가 인용을 판정하는 선행연구 에이전트다. 옛 이름 lens-prior-art(선행연구렌즈)를 부르는 요청도 여기서 받는다.

## 스킬의 절과 옮길 원본

스킬은 큰 명세 「구성」이 정한 절을 `##` 제목으로 두고, 절마다 아래 원본에서 오케스트레이터가 따를 지시와 값을 옮긴다. 리서치 근거, 리뷰 경위, 빌더에게 내린 지시("빌더는 …")는 옮기지 않는다. 값의 출처가 사용자 결정이나 외부 자료이면 그 사실을 한 문장으로 남긴다(예: "통상 2와 최대 20은 사용자가 2026-10-18에 정했다").

| 절 | 옮길 원본 | 원본과 다르게 적을 것 |
|---|---|---|
| 「오케스트레이터 절차」 | 큰 명세 같은 이름 절(프로토콜 항목, 단계 1~4와 각 확인, 상태 값, 세션이 끊긴 때, 워크플로가 꺼진 환경) | 「절차의 연결」 |
| 「발동과 기록」 | 큰 명세 같은 이름 절 | 「발동과 기록의 소유와 주제어」 |
| 「상황별 전략」 | 큰 명세 같은 이름 절의 표와 그 아래 문장 | 첫 줄에 산문 한 문장을 둔다 |
| 「실행할 때 지킬 상한」 | 큰 명세 같은 이름 절 | 옛 렌즈의 '최대한 6'을 대체한다는 문장을 옮기지 않는다 |
| 「판정 규약」 | 옛 렌즈의 「체크리스트」, 네 축 대조 문단, 「가드」와, 큰 명세 「판정 규약」의 연구자·검증자 적용 문장 | 「판정 규약을 옮기는 규칙」 |
| 「출력 스키마」 | 큰 명세 같은 이름 절과, 옛 렌즈 출력 스키마의 칸과 `search_status` 표 | 「출력 스키마를 옮기는 규칙」 |
| 「인용 확인」 | 큰 명세 같은 이름 절 | 빌더 지시 문단("이 절이 범위 문장의 원본이다 …")은 "이 절이 인용 확인 범위의 원본이다" 한 문장으로 줄인다 |
| 「레퍼런스 프롬프트」 | 옛 렌즈의 「레퍼런스 프롬프트」 system 문장 | 「레퍼런스 프롬프트의 요건」 |

스킬 파일은 `skills/lens-*/SKILL.md`가 아니므로 `docs/domain-korean.md` 「첫 문장 규칙의 예외」를 받지 않는다. 그래서 빌더는 모든 `##` 절의 첫 줄을 산문 한 문장으로 쓴다. 스킬 본문에 `lens-prior-art`와 `lens-derived`는 쓰지 않는다. 옛 이름은 `description`에만 둔다.

## 절차의 연결

오케스트레이터는 2단계와 3단계에서 Workflow 도구로 워크플로 `disciplined-coder:prior-art-search`를 실행하고, `args`에는 「키 이름과 바깥 형식」의 프로토콜 객체를 넣는다. `principles_path`를 도출하는 규칙은 `dispatching-lenses`의 「렌즈에게 에이전트원칙을 알리는 법」을 가리키고 그 문장을 베끼지 않는다. 그 절의 첫 항목 문장이 다른 스킬에 나타나면 `scripts/test_docs_drift.sh`가 실패하기 때문이다.

오케스트레이터는 반환값의 `researchers`·`verifiers` 원소와 사유의 위치를 `specworkflow` 「반환값의 형식」「목록의 행선지」대로 읽어, `review-docs` 「기록 파일 이름 규칙」의 원본 파일 이름으로 기록 폴더에 쓴다. 판정과 보고에는 `passed` 항목만 쓰고, `synthesis: null`의 두 사정은 `passed`에 `#case#` 항목이 있는지로 구별한다(큰 명세 「공유 결정」과 「다시 나눈 분할」의 계약 표).

워크플로가 꺼진 환경에서는 Agent 도구의 `subagent_type`에 `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`를 넣고, 프롬프트는 워크플로와 같은 형식으로 쓴다.

원본 파일 이름 규칙의 표는 `review-docs` 「기록 파일 이름 규칙」 한 곳에 둔다(「참조 처리 목록」의 `review-docs` 62행). 스킬의 「원본 파일 규칙」 문단은 표 대신 그 절을 가리키며, 4단계 확인 문장의 '아래 원본 파일 규칙'도 그 포인터로 바꾼다. 이름 규칙의 소유자가 `review-docs`이기 때문이다. 4단계 기록에 적을 항목은 `review-specs`의 「`prior-art` 기록에 적을 것」을 가리키며, spec 리뷰가 아니면 그 항목에서 spec·plan 구분을 뺀다.

## 발동과 기록의 소유와 주제어

「발동과 기록」의 첫 문단에는 "이 규칙은 여기가 소유한다"는 소유 선언을 둔다. 큰 명세는 이 절이 `dispatching-lenses` 「렌즈 그룹」의 공통 규칙을 옮긴 것이라 적으며, 선행연구 에이전트에는 그 절이 적용되지 않는다.

넛지의 주제어와 요청형 표현 목록은 스킬에 옮기지 않는다. 스킬은 "넛지가 알리는 조건과 낱말 목록은 `hooks/prior_art_nudge_userpromptsubmit.sh`가 정한다"는 문장으로 그 파일을 가리킨다. 목록이 두 곳에 있으면 발동 시험으로 고칠 때 한쪽만 바뀌고, 목록의 옛 이름이 스킬 본문에 들어온다.

## 판정 규약을 옮기는 규칙

빌더는 옛 렌즈의 체크리스트, 네 축 대조 문단, 가드의 문장을 바꾸지 않는다. 예외는 아래와 같다.

- **가드의 머리 문장** — "이 가드는 이 렌즈에만 있다."는 옮기지 않는다.
- **`lens-derived`** — 가드의 `lens-derived`는 `derived`로 적는다.
- **'이 설계'의 뜻** — 절 첫 문장에서 "옮긴 문장의 '이 설계'는 대조 대상(spec·제안서의 방법, 사용자가 만들려는 것, 사용자가 고르려는 결정 후보안)을 가리킨다"고 밝힌다.

가드 뒤에는 큰 명세 「판정 규약」의 적용 문장을 둔다. 그 문장은 "인용한 URL은 실제로 열어 확인하고 출처의 성격을 구분해 적는다"는 가드를 연구자가 따르고, 그 결과를 검증자가 다시 판정한다는 내용이다.

## 출력 스키마를 옮기는 규칙

옛 렌즈의 출력 스키마는 연구자 출력의 기본 칸이다. 빌더는 그 코드 블록을 옮기면서 `lens` 칸을 `agent`로, 값을 `agent-prior-art`로, `kind` 열거를 `peer-reviewed|preprint|vendor|blog|standard|derived`로 바꾸고, 큰 명세 표의 칸(`mode`·`subquestion_id`·`queries`·`evidence_map`·`saturation`·`issues[].prior_claim`)을 추가한다. `evidence_map` 행의 `axes`는 축마다 `{ prior, same, note }`다. 이 두 칸이 `specworkflow`가 검증자에게 보내는 `text`의 재료이며, 큰 명세 「경계」가 이 절을 원본으로 가리킨다. 블록 안 `principles_applied`의 설명은 "읽고 적용한 원칙 ID"로 줄인다. 옛 설명은 `aggregating-lenses`의 계약을 가리키는데, 선행연구 에이전트의 출력은 그 계약을 따르지 않고 이 절이 원본이다.

`contrast` 모드에서 `evidence_map`은 빈 배열이다. 옛 렌즈의 `search_status` 값 표와 "발견은 문서에 자동으로 반영하지 않는다"는 문장도 옮긴다. 옛 렌즈의 "필드의 뜻과 공통 규칙은 `aggregating-lenses`의 리뷰 산출물 계약이 소유한다"는 옮기지 않는다.

`derived`의 뜻은 "에이전트가 스스로 계산하거나 추론한 값"으로 적고 옛 이름은 쓰지 않는다. 큰 명세 「출력 스키마」의 나머지(인용 판정 출력, 지도 대조 출력, 워크플로 반환값, 키 이름과 바깥 형식, 에이전트에게 보내는 프롬프트, `principles_applied`가 빈 때, 판정 모델 교체)는 그대로 옮긴다.

## 레퍼런스 프롬프트의 요건

스킬의 「레퍼런스 프롬프트」 절은 산문 한 문장 뒤에 연구자 시스템 프롬프트를 `- system: "<본문>"` 한 줄로 둔다. 본문은 줄을 바꾸지 않는다. 연구자 정의는 이 본문을 한 줄 그대로 포함하며, 같은지는 「계약 테스트」의 대조 검사가 본다.

본문은 옛 렌즈의 system 문장으로 시작한다. 빌더는 그 문장을 지우거나 고치지 않고, 아래 지시 가운데 옛 문장에 없는 것을 뒤에 덧붙인다.

- 체크리스트를 항목마다 따로 검토하고, 참신함을 채점하지 말며, 못 찾은 것을 `not_found`에 적고 독창성의 근거로 삼지 말라는 지시
- 선행 사례를 네 축으로 대조하고 하나라도 다르면 같은 사례로 단정하지 말라는 지시
- 모든 주장에 출처 URL 과 `kind`를 달고 실제로 열어 확인하며, 열지 못하면 `opened`를 거짓으로 두라는 지시
- 질의 경계와 입력의 `forbidden_terms`를 지키고, 실행한 검색어를 빠짐없이 `queries`에 적으라는 지시
- 도구 호출을 20회 이하로, 인용할 출처를 약 100개 이하로 두라는 지시(큰 명세 「턴 상한」「세는 대상」)
- `survey` 모드면 자기 하위 질문의 `evidence_map` 행을 채우고 `contrast` 모드면 빈 배열로 두며, `saturation`을 적으라는 지시
- 출력을 연구자 출력 JSON 하나로만 내라는 지시

이 절은 사용자 메시지 형식을 다시 정하지 않고 「출력 스키마」의 「에이전트에게 보내는 프롬프트」를 가리킨다. 리뷰 전에는 프롬프트를 새로 쓰게 했으나, 큰 명세 「기존 파일과의 관계」가 레퍼런스 프롬프트를 옮긴다고 정했고 병합 전 시험의 기준선이 옛 렌즈 프롬프트를 쓰므로 옛 문장에서 시작하게 바꿨다.

## 연구자와 검증자 정의

두 정의는 `agents/` 아래 마크다운 파일이며, 등록 이름은 `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`다. frontmatter 는 아래와 같다.

| 키 | `prior-art-researcher` | `prior-art-verifier` |
|---|---|---|
| `name` | `prior-art-researcher` | `prior-art-verifier` |
| `description` | 선행연구 에이전트의 연구자이며 `agent-prior-art` 절차와 워크플로 `disciplined-coder:prior-art-search`에서만 실행한다는 문장 | 선행연구 에이전트의 검증자이며 `agent-prior-art` 절차와 워크플로 `disciplined-coder:prior-art-search`에서만 실행한다는 문장 |
| `tools` | `WebSearch, WebFetch, Read, Grep, Glob` | `WebFetch, Read` |
| `maxTurns` | `20` | `20` |
| `model` | 두지 않음(세션 모델을 따름) | 두지 않음(세션 모델을 따름) |

`description`은 다른 대화에서 메인 세션이 이 에이전트를 스스로 고르지 않게 쓰며, `: `와 ` #`을 넣지 않는다. `tools`에는 Agent 도구가 없다. 검증자의 기본 `model`을 `haiku`로 바꿀지는 현재 세션이 병합 전 시험 결과로 정한다(큰 명세 「채택 기준」).

본문은 공통 단락과 모드 단락과 출력 형식 블록으로 이루어진다. 공통 단락은 프롬프트 첫 줄 `MODE:`로 모드를 고르고, 둘째 줄 `PRINCIPLES:` 경로의 에이전트원칙을 먼저 읽어 적용한 조항 ID 를 `principles_applied`에 적으며, 셋째 줄부터의 JSON 블록을 입력으로 쓰라는 지시다. 블록의 표기는 `specworkflow` 「프롬프트와 입력」이 정한다(큰 명세 「경계」). 모드 이름과 입력 키는 「에이전트에게 보내는 프롬프트」를 따른다. 출력은 JSON 하나이며 앞뒤에 다른 글을 두지 않는다.

출력 형식 블록은 그 정의가 내는 자료의 형식을 코드 블록으로 싣는다. 블록마다 바로 앞 줄에 `<!-- output: <자료 이름> -->`(자료 이름은 `researcher`·`synthesis`·`verifier`·`map`)를 두고, 블록은 `JSON.parse`로 읽히는 예시 JSON 하나로 쓴다. 계약 테스트가 이 표지로 블록을 찾는다(큰 명세 「다시 나눈 분할」의 「계약 코드와 계약 테스트」). 연구자는 연구자 출력과 종합 모드 연구자 출력을, 검증자는 인용 판정 출력과 지도 대조 출력을 싣는다. 서브에이전트는 스킬 파일을 받지 못하므로 절 이름만으로는 키를 알 수 없기 때문이다. 블록의 내용은 스킬 「출력 스키마」의 같은 자료와 같아야 한다.

연구자의 `explore` 모드 단락은 「레퍼런스 프롬프트」 본문 한 줄과 "입력의 `subquestion` 하나만 탐색한다"는 문장이다. `synthesize` 모드 단락은 웹 도구를 쓰지 않고 입력 `passed_rows`(원소 `{ ref, row }`, `specworkflow` 「용어」의 '통과 행')의 행만으로 `evidence_map`을 다시 만들라는 지시다. 그 단락은 통과 목록에 없는 사례를 넣지 말고, `conclusions`의 `refs`에는 근거가 된 행의 주장 참조를 「결정 기록」 「주장 참조 형식」(`<하위 질문 ID>#case#<배열 위치>`)으로 적으라고 지시한다.

검증자의 `cite` 모드 단락은 입력 `url`을 WebFetch 로 한 번 열고, `claims`의 주장마다 `verdict`·`quote`·`reason`을 내라는 지시다. 판정 기준은 큰 명세 「인용 판정 출력」의 고정 문장("옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported")을 그대로 쓰고, `quote`는 원문에서 고치지 않고 옮긴다. 원문을 열지 못하면(봇 차단, 유료 장벽, 응답 없음) 모든 주장을 `unverifiable`로 두고 `reason`에 그 사정을 적으며, 다시 열지 않는다. 판정 대상은 큰 명세 「인용 판정 출력」이 정한 선행 사례 쪽 서술뿐이며, `claims[].text`의 형태는 `specworkflow` 「판정 함수」의 `groupByUrl` 항목이 정한다(큰 명세 「경계」).

검증자의 `map` 모드 단락은 웹 도구를 쓰지 않고, 입력 `evidence_map`의 칸마다 입력 `passed`에 근거가 있는지 `grounded`로 표시하며, 근거가 된 항목의 `ref`를 `source_ref`에 적으라는 지시다.

## 발동 넛지

`hooks/prior_art_nudge_userpromptsubmit.sh`는 사용자 메시지에 주제어와 요청형 표현이 함께 있으면 `agent-prior-art`를 열라는 알림을 추가 컨텍스트로 내고, 차단하지 않는다. 조건과 낱말 목록의 원본은 큰 명세 「발동 넛지의 조건」이며, 빌더는 그 목록을 그대로 넣는다.

훅의 흐름은 아래 차례다.

1. `set -euo pipefail`로 시작한다. `DISCIPLINED_CODER_PRIOR_ART_NUDGE`가 `off`이면(`${변수:-on}` 비교) 아무것도 내지 않고 0 으로 끝난다.
2. stdin 을 `INPUT="$(cat)"`으로 읽는다. `json_str`은 첫 따옴표에서 끊으므로 쓰지 않는다(「결정 기록」 「공용 유틸리티」).
3. `INPUT`에 `"prompt"` 키가 없으면 아무것도 내지 않고 0 으로 끝난다(FAIL-OPEN). 있으면 그 키 뒤의 문자열 전체(`${INPUT#*\"prompt\"}`)를 대조 대상으로 삼는다. 메시지 안의 이스케이프된 따옴표와 `\n`은 낱말 대조를 방해하지 않으므로 풀지 않는다.
4. `shopt -s nocasematch` 아래에서 주제어 목록과 요청형 목록을 각각 `[[ $p == *"$t"* ]]`로 대조한다. 둘 다 하나 이상 맞으면 알린다. 외부 명령을 실행하지 않는다.
5. 알림은 `hooks/_json_escape.sh`의 `escape_for_json`으로 이스케이프해 `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"<알림>"}}` 한 줄로 낸다.

알림에는 `disciplined-coder` 플러그인의 `agent-prior-art` 스킬을 열어 그 절차대로 진행하라는 지시, 손으로 짠 워크플로나 일반 리서치로 대신하지 말라는 지시, 요청이 아니면 무시하라는 문장, "넛지일 뿐 차단은 아니다"를 넣는다. 스킬의 절 이름은 넣지 않는다(`hooks/rules_nudge_pretooluse.sh`와 같은 규칙). 세션당 횟수 제한과 표시 파일은 두지 않는다(큰 명세 「발동 넛지의 조건」).

`hooks/hooks.json`에는 `"UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/prior_art_nudge_userpromptsubmit.sh\""}]}]`를 추가한다. UserPromptSubmit 은 matcher 를 받지 않으므로 matcher 를 두지 않는다.

`README.md` 「하드 게이트와 넛지와 전역 설정 수정」 표에는 SessionStart 행들 뒤에 `| UserPromptSubmit | \`hooks/prior_art_nudge_userpromptsubmit.sh\` | 사용자 메시지에 선행연구 주제어와 요청형 표현이 함께 있으면 \`agent-prior-art\`를 열라고 알린다. 메시지마다 본다 | 알림 |` 행을 추가한다. 「끄는 법」에는 `DISCIPLINED_CODER_PRIOR_ART_NUDGE=off`가 `prior_art_nudge_userpromptsubmit.sh`를 끈다는 불릿을 추가하고, 91행의 "두 변수는"을 "세 변수는"으로 고친다.

빌더는 넛지 훅 한 번의 실행 시간을 픽스처 입력으로 측정해 리포트에 적는다. 큰 명세 「측정값」의 「넛지 실행 시간」이며, 사람 입력이 필요 없으므로 구현 서브 세션이 측정한다.

## 참조 처리 목록

명세 서브 세션이 2026-10-18 커밋 `1c784ec`에서 `docs/superpowers/reviews`·`specs`·`plans` 밖을 `grep -rn`으로 찾았다. 찾은 말은 `lens-prior-art`, '필요할 때 그룹', '필요할 때 렌즈', '선행연구 렌즈', '웹에 나가', `search_status`, '외부 탐색', '사용자 승인이 필요한 렌즈', '렌즈 그룹 판정'이다. 아래 표의 줄 번호는 그 커밋 기준이며, 빌더는 plan 을 쓸 때 같은 grep 을 다시 실행해 줄이 밀렸는지 확인한다.

| 파일:줄 | 지금 적힌 것 | 처리 |
|---|---|---|
| `agent-principles.md:132` | `LENS-ALLOWED`의 예시 괄호 "(웹에 나가는 `lens-prior-art` 등)" | 괄호만 지운다. 규칙 문장은 그대로 둔다. 클린룸 시험은 사용자 결정으로 생략한다 |
| `docs/domain-discipline.md:315` | `NO-RAW-OUTPUT` 절의 과거 서술 "(예: `lens-prior-art`)" | 그대로 두고 절 끝에 "2026-10-18 `lens-prior-art`를 삭제하고 `agent-prior-art`로 대체했다"는 문장을 추가한다 |
| `docs/domain-discipline.md:329·332·341` | `LENS-ALLOWED` 절의 과거 서술과 측정 | 그대로 두고 절 끝에 문단을 추가한다. 그 문단은 2026-10-18 `lens-prior-art`를 삭제하고 `agent-prior-art`로 대체하면서 조항의 예시 괄호를 지웠다는 사실, "선행연구 에이전트의 이름은 `lens-*` 형태가 아니어서 이 조항의 허가 밖에 있고 승인 규칙은 그 스킬의 「발동과 기록」이 정한다"는 사실, 지시 내용이 바뀌지 않아 사용자가 같은 날 클린룸 시험 생략을 정했다는 사실을 적는다 |
| `scripts/test_audit.sh:211` | 뒤따르는 검사가 없는 주석 "한 줄에 lens-prior-art 이름과 '예외' 가 함께 있는지를 본다." | 지운다. 가리키던 검사가 이미 없다 |
| `scripts/test_docs_drift.sh:226` | review-docs 가 「웹에 나가는 렌즈의 인용 검증」을 가리키는지 보는 검사 | 「계약 테스트」의 새 포인터 검사로 바꾼다 |
| `scripts/test_docs_drift.sh:846-849` | `canon: 선행연구 렌즈를 이름으로 예외` 검사와 그 주석 | 「계약 테스트」의 소유 검사로 바꾸고 주석을 새 이유로 고친다 |
| `skills/aggregating-lenses/SKILL.md:22` | `lens` 열거의 `lens-prior-art` | 열거에서 지운다 |
| `skills/aggregating-lenses/SKILL.md:53` | "`lens-readability`와 `lens-prior-art`는 빠지는 칸이 서로 달라 예외마다 따로 적는다." | "공통 계약을 따르지 않는 렌즈는 아래와 같다."로 바꾼다 |
| `skills/aggregating-lenses/SKILL.md:56` | `lens-prior-art` 예외 불릿 | 지운다 |
| `skills/aggregating-lenses/SKILL.md:84-87` | 「렌즈가 추가하는 칸」의 `search_status`·`citations`·`not_found`·`disclosures` 행 | 지운다 |
| `skills/aggregating-lenses/SKILL.md:95` | "`search_status`와 `purpose`는 … 두 칸은 호출자가 원본을 열어 확인한다." | "`purpose`는 집계본만 보고 넘어가면 조용한 통과가 생긴다. 이 칸은 호출자가 원본을 열어 확인한다."로 바꾼다 |
| `skills/audit-repo-docs/SKILL.md:49` | "`lens-prior-art`는 제안하지 않는다." | "선행연구 에이전트(`agent-prior-art`)는 제안하지 않는다."로 바꾼다 |
| `skills/dispatching-lenses/SKILL.md:73` | 「렌즈 그룹」 표의 `lens-prior-art` 행 | 지운다 |
| `skills/dispatching-lenses/SKILL.md:75` | "생성은 고친 문장을 내고 외부 탐색은 웹을 찾는다." | "생성은 고친 문장을 낸다."로 바꾼다 |
| `skills/dispatching-lenses/SKILL.md:88` | "`lens-prior-art`는 웹에 나가므로 … 「실행할 때 지킬 상한」이 정한다." 두 문장 | 지운다. 앞의 두 문장은 `lens-readability`에 적용되므로 그대로 둔다 |
| `skills/dispatching-lenses/SKILL.md:100` | "`lens-prior-art`의 발동 기준은 호출자마다 달라 각 호출자가 정한다." | "선행연구 대조는 렌즈 대신 `agent-prior-art`가 맡는다. 제안과 승인은 그 스킬의 「발동과 기록」이 정한다."로 바꾼다 |
| `skills/lens-fit/SKILL.md:38` | "`lens-readability`의 `purpose`와 `lens-prior-art`의 `search_status`가 같은 구실을 한다." | "`lens-readability`의 `purpose`가 같은 구실을 한다."로 바꾼다 |
| `skills/review-docs/SKILL.md:34` | 「필요할 때 렌즈」 첫 문단의 소유 문장 | 선행연구 에이전트의 제안과 승인, 직접 요청, 판정 기록은 `agent-prior-art`의 「발동과 기록」이 소유한다는 문장을 추가하고, 마지막 문장을 "필요할 때 렌즈와 선행연구 에이전트를 그 질문의 선택지에 합쳐 한 번만 묻는다"로 고친다 |
| `skills/review-docs/SKILL.md:38` | "`lens-prior-art`는 … 질의 경계는 `lens-prior-art`의 「가드」가 정하며 …" | 주어를 "선행연구 에이전트(`agent-prior-art`)"로 바꾸고, 질의 경계 포인터를 `agent-prior-art`의 「판정 규약」으로 바꾼다 |
| `skills/review-docs/SKILL.md:40` | "`review-specs`의 「웹에 나가는 렌즈의 인용 검증」을 따르고" | "`agent-prior-art`의 「인용 확인」을 따르고"로 바꾼다 |
| `skills/review-docs/SKILL.md:50` | "필요할 때 렌즈를 제안했는지와 … 이 의무는 `dispatching-lenses`의 「렌즈 그룹」이 소유한다." | "필요할 때 렌즈와 선행연구 에이전트를 제안했는지와 승인 여부와 그 이유도 기록에 적는다. 이 의무는 렌즈면 `dispatching-lenses`의 「렌즈 그룹」이, 선행연구 에이전트면 `agent-prior-art`의 「발동과 기록」이 소유한다."로 바꾼다 |
| `skills/review-docs/SKILL.md:62` | 「기록 파일 이름 규칙」의 렌즈별 원본 규칙 | 문단 끝에 "`prior-art` 종류의 원본은 렌즈별 원본 규칙 대신 아래 이름을 쓴다"는 문장과, 큰 명세 「원본 파일 규칙」의 표와 `r<n>` 뜻을 추가한다 |
| `skills/review-specs/SKILL.md:23` | 절차 표 "선행연구 렌즈를 실행할지 제안한다 \| 「선행연구 렌즈의 제안과 승인」 절" | "선행연구 에이전트를 실행할지 제안한다 \| 「선행연구 에이전트의 제안과 승인」 절"로 바꾼다 |
| `skills/review-specs/SKILL.md:27` | 절차 표 "인용을 검증한다 \| 「웹에 나가는 렌즈의 인용 검증」 절" | "선행연구 결과를 처리한다 \| 「선행연구 결과의 처리」 절"로 바꾼다 |
| `skills/review-specs/SKILL.md:32` | "선행연구 렌즈의 서브에이전트 상한은 `lens-prior-art`의 「실행할 때 지킬 상한」에" | "선행연구 에이전트의 절차와 상한은 `agent-prior-art`에"로 바꾼다 |
| `skills/review-specs/SKILL.md:34` | "`lens-prior-art`는 이 넷에 들지 않고 … 사용자가 정한 값이다." 두 문장 | "선행연구 에이전트는 렌즈 개수 넷에 들지 않는다. 그 에이전트가 실행하는 연구자 수의 상한은 `agent-prior-art`의 「실행할 때 지킬 상한」이 정한다."로 바꾼다 |
| `skills/review-specs/SKILL.md:41` | PREP 의 "선행연구 제안" 불릿 | 절 이름을 「선행연구 에이전트의 제안과 승인」으로 바꾸고 "승인받으면 렌즈와 동시에 실행한다"를 지운다 |
| `skills/review-specs/SKILL.md:52` | "`lens-prior-art`는 이 셈에서 빠진다. …" | 지운다. 34행이 같은 사실을 적는다 |
| `skills/review-specs/SKILL.md:59` | "`dispatching-lenses`의 「렌즈 그룹」에서 필요할 때 그룹이라 …" | "`agent-prior-art`가 맡으며 제안과 승인을 거쳐 따로 실행된다."로 바꾼다 |
| `skills/review-specs/SKILL.md:61` | "예외는 `lens-prior-art` 하나이며 … 무엇을 못 보는지 알린다." | 첫 문장만 남기고 뒤 두 문장을 지운다 |
| `skills/review-specs/SKILL.md:63-64` | 절 제목 "선행연구 렌즈의 제안과 승인"과 "필요할 때 그룹이다 … 「렌즈 그룹」이 소유한다" | 제목을 "선행연구 에이전트의 제안과 승인"으로, 소유 문장을 "제안과 승인, 직접 요청, 판정 기록, 서브 세션 처리는 `agent-prior-art`의 「발동과 기록」이 소유한다"로 바꾼다 |
| `skills/review-specs/SKILL.md:70` | 동시 실행, 단계 상한을 넘으면 다음 단계로 미루기, 통상과 최대한 중 고르기 | 제안 시점 두 문장은 남긴다. 나머지는 "사용자가 제안을 받아들이면 `agent-prior-art`를 열어 그 절차를 따르며, 연구자 수는 그 절차의 프로토콜 승인에서 정한다. 승인이 없으면 실행하지 않는다."로 바꾼다 |
| `skills/review-specs/SKILL.md:72` | 실행 도중 상한을 늘릴 때 묻기와 `notes` 확인 | 지운다. 공백 라운드 판단이 `agent-prior-art` 3단계에 있다 |
| `skills/review-specs/SKILL.md:74` | 에이전트가 웹 검색과 웹 페치를 보유하는지 확인 | 지운다. 연구자와 검증자 정의가 도구를 고정한다 |
| `skills/review-specs/SKILL.md:76` | "판정에 쓸 수 있는 발견이 하나 이상 있으면(search_status 가 ok이면)" | 괄호를 지우고 "판정에 쓸 수 있는 발견은 워크플로 반환값 `passed`의 항목이다. `overall_status`가 `ok`가 아니면 그중 `ok`인 하위 질문의 항목만 쓴다"를 뒤에 추가한다(큰 명세 「공유 결정」의 「판정에 쓰는 발견」). 큰 명세 「상태 값」의 하위 질문별 처리와 맞추기 위해서다 |
| `skills/review-specs/SKILL.md:101` | "선행연구 렌즈를 제안했는지와 승인 여부와 그 판정 이유" | "선행연구 에이전트를"로 바꾼다 |
| `skills/review-specs/SKILL.md:118` | "`lens-prior-art`의 발견은 … 전부 `🔴`로 간다." | "선행연구 에이전트의 발견은"으로 바꾼다 |
| `skills/review-specs/SKILL.md:137-138` | 절 제목 「웹에 나가는 렌즈의 인용 검증 (`lens-prior-art` 전용)」과 "이 절차는 여기가 소유한다. 그 렌즈를 실행했을 때만 따르며 인용 검증은 호출자 책임이다." | 제목을 「선행연구 결과의 처리」로, 둘째 문장을 "선행연구 에이전트를 실행했을 때만 따른다."로 바꾼다 |
| `skills/review-specs/SKILL.md:140-143` | 인용 검증 불릿 | 지우고 "인용 확인의 범위와 방법은 `agent-prior-art`의 「인용 확인」이, 상태 값에 따른 처리는 그 스킬의 「오케스트레이터 절차」가 정한다"는 문장으로 대신한다 |
| `skills/review-specs/SKILL.md:145` | 「`prior-art` 기록에 적을 것」 | 남기고 항목을 고친다. 항목은 선행연구 에이전트를 제안했는지와 그 판정 이유, spec 과 plan 의 구분(spec 리뷰일 때), 프로토콜 전문, `ok`가 아닌 `overall_status`와 하위 질문별 상태, 탈락·판정 불가·검증 실패 목록, 질의 경계 위반, 오케스트레이터가 확인하지 못한 인용, 연구자가 `disclosures`와 `not_found`에 적은 항목 중 결론에 영향을 주는 항목이다 |
| `skills/nested-orchestration/references/sub-session-protocol.md:56` | "사용자 승인이 필요한 렌즈를 실행해야" | "사용자 승인이 필요한 렌즈나 선행연구 에이전트를 실행해야"로 바꾼다 |
| `skills/nested-orchestration/references/sub-session-protocol.md:60` | "필요할 때 그룹의 발동 기준에 해당했을 뿐 … `렌즈 그룹 판정`에 적는다" | 뒤에 "선행연구 에이전트의 발동 기준에 해당했을 때도 같으며, 그 규칙은 `agent-prior-art`의 「발동과 기록」이 정한다."를 추가한다 |
| `skills/nested-orchestration/references/sub-session-protocol.md:114` | `렌즈 그룹 판정` 행의 줄 형식 "'렌즈 — 대상 문서 — 발동 기준에 해당한 이유'" | "'렌즈나 선행연구 에이전트 — 대상 문서 — 발동 기준에 해당한 이유'"로 바꾼다. 절 제목 `렌즈 그룹 판정`은 바꾸지 않는다 |
| `skills/nested-orchestration/SKILL.md:228` | 「판정 기록 확인」의 "`렌즈 그룹 판정` 절을 읽어 … `REVISE`의 `고칠 항목`으로 보낸다" | 뒤에 "선행연구 에이전트가 적혀 있으면 현재 세션이 `agent-prior-art`의 「발동과 기록」대로 사용자에게 제안하고, 승인받으면 직접 실행한다. 결과로 하부 명세나 구현을 고쳐야 하면 그 항목을 `REVISE`(명세 서브 세션이면 `RESTART`)로 보낸다. 서브 세션은 선행연구 에이전트를 실행하지 않는다."를 추가한다 |
| `skills/domain-plugin/SKILL.md:14` | 「frontmatter」 불릿 | "에이전트 정의 `agents/*.md`는 `name`과 `description`을 쓰고 도구와 턴 상한을 `tools`·`maxTurns`로 둔다"는 문장을 추가한다. YAML 평문 스칼라 규칙이 에이전트 정의에도 적용된다는 것도 함께 적는다 |
| `skills/domain-plugin/SKILL.md:16` | 「스킬 이름의 부류」 | "사용자와 여러 턴을 주고받는 절차와 서브에이전트 정의와 워크플로를 묶은 구성은 `agent-` 접두사를 쓴다(`agent-prior-art`)"를 추가한다 |
| `skills/domain-plugin/SKILL.md:17` | 「컴포넌트 위치」의 목록 | `workflows/`를 추가한다 |

`skills/nested-orchestration/SKILL.md:228`과 `skills/review-docs/SKILL.md:50`은 큰 명세 「기존 파일과의 관계」 표에 없다. 그러나 두 줄은 선행연구를 렌즈로 전제하므로 참조 처리 규칙의 대상이다.

grep 에 걸리지만 그대로 두는 줄은 `skills/dispatching-lenses/SKILL.md:38·88(앞 두 문장)·90-96`, `skills/review-docs/SKILL.md:30·32`, `skills/lens-readability/SKILL.md:3`이다. 이 줄들의 '필요할 때 그룹'과 '필요할 때 렌즈'는 `lens-readability`에도 적용되는 규칙이다. 봉인된 리뷰 기록과 지난 spec 은 고치지 않는다(큰 명세 「기존 파일과의 관계」).

## 계약 테스트

이 워크스트림이 바꾸는 계약 테스트는 `scripts/test_docs_drift.sh`와 `scripts/test_hooks.sh`에 있다. 단언은 `check`로 쓰고, 문서 대조는 문장 대신 절 제목·포인터·소유 선언으로 판정한다(CLAUDE.md 「변경 뒤 실행」).

아래에서 쓰는 헬퍼의 뜻은 이렇다. `scripts/_doc_keys.sh`의 `has_sec`은 절이 있는지, `sec_has`는 절 안에 문자열이 있는지, `owns_sec`은 절이 소유를 밝히는지, `points_to`는 한 줄에 소유자 이름과 절 이름이 함께 있는지, `doc_sec`은 절 본문을 꺼내는지를 본다. `scripts/_json_valid.sh`의 `json_valid_stdin`은 표준 입력이 유효한 JSON 인지 보고, `json_run`은 JSON 을 읽는 파이썬 한 줄을 실행한다.

`scripts/test_docs_drift.sh`의 기존 검사는 아래처럼 바꾼다.

- **226행** — `check "그 절이 선행연구 인용 확인을 agent-prior-art 로 넘긴다" "points_to \"\$DOCS\" '\`agent-prior-art\`' '「인용 확인」'"`로 바꾼다.
- **849행** — 검사를 "선행연구 에이전트가 승인 규칙을 소유한다"(`owns_sec "$AP" '발동과 기록'`, `$AP`는 `skills/agent-prior-art/SKILL.md`)로 바꾼다. 846-848행 주석은 "선행연구 에이전트는 이름이 `lens-*` 형태가 아니어서 상시 허가에 들지 않고, 승인 규칙은 자기 절이 소유한다"는 이유로 고친다.
- **609행 frontmatter 안전 묶음** — 순회 대상에 `"$HERE"/agents/*.md`를 추가한다. 소유자 `domain-plugin` 「frontmatter」는 「참조 처리 목록」의 14행 처리로 에이전트 정의를 다루게 된다.

`scripts/test_docs_drift.sh`에는 묶음 `[선행연구 에이전트]`를 추가한다. 이 묶음의 단언은 모두 대상이 있다는 긍정 조건으로 쓴다.

- **절** — `agent-prior-art`에 큰 명세 「구성」이 정한 절이 모두 있다(`has_sec`). `review-specs`와 `review-docs`가 이 절 이름으로 가리키므로 이름이 바뀌면 실패해야 한다.
- **포인터** — `review-specs`가 「발동과 기록」을 가리킨다(`points_to "$CALLER" '\`agent-prior-art\`' '「발동과 기록」'`).
- **정의의 도구** — 두 정의의 `tools:` 줄이 「구성」의 목록과 글자로 같고, `maxTurns:` 줄의 값이 `20`이다. 같은지 보는 긍정 비교라 Agent 도구가 끼면 실패한다.
- **연구자 프롬프트 대조** — `doc_sec "$AP" '레퍼런스 프롬프트'`에서 `- system: "`로 시작하는 줄을 뽑아 앞뒤 따옴표를 떼어 `RP`에 둔다. 판정은 `[ -n "$RP" ] && grep -qF -- "$RP" "$HERE/agents/prior-art-researcher.md"`다. `RP`가 비면 `grep -qF ""`가 모든 파일과 맞아 항상 통과하므로 빈 값 검사를 앞에 둔다.
- **삭제 표시** — `docs/domain-discipline.md`의 `` `NO-RAW-OUTPUT` ``과 `` `LENS-ALLOWED` `` 절에 `agent-prior-art`가 있다(`sec_has`). 그 파일은 약 100자에서 줄을 바꾸어 표시와 옛 이름이 다른 줄에 놓이므로 줄 단위가 아닌 절 단위로 본다.

`scripts/test_hooks.sh`에는 묶음 `[prior-art-nudge]`를 추가한다. 입력은 `{"session_id":"s","hook_event_name":"UserPromptSubmit","prompt":"<메시지>"}` 형태의 픽스처다.

- **알림** — 아래 메시지마다 출력에 `agent-prior-art`와 `"hookEventName":"UserPromptSubmit"`이 있고 `json_valid_stdin`을 통과한다.
  - "선행연구에 쓸 만한 에이전트 플러그인이 있나 찾아봐"
  - "에이전트원칙의 목차를 어떤 기준으로 배치해야 하는지 선행연구를 조사해 줘"
  - "docs/superpowers/specs/2026-10-09-nested-orchestration-large-dev-design.md 의 선행 사례를 찾아 줘"
  - "선행연구렌즈로 뒤져봐"
  - "lens-prior-art 로 찾아봐"
  - `\"이 방법\"의 선행연구를 찾아 줘`(주제어 앞에 이스케이프된 큰따옴표가 있는 메시지)
  - "Prior Art 있나"
- **침묵** — "선행연구 결과를 기록에 정리했다", "선행연구 단계는 끝났다", "prior art 기록 파일 이름을 바꿨다", "이 함수를 고쳐봐"에서 출력이 비어 있다.
- **끄기와 입력 오류** — `DISCIPLINED_CODER_PRIOR_ART_NUDGE=off`이면 출력이 비어 있다. `{}`와 빈 입력에서 출력이 비어 있고 종료 코드가 0 이다.
- **연결** — `hooks/hooks.json`의 `UserPromptSubmit` 명령에 `prior_art_nudge_userpromptsubmit.sh`가 있다(`json_run`). README 행은 기존 「README — 배선된 스크립트를 모두 적는다」 묶음이 본다.

알림 묶음의 앞 세 메시지는 큰 명세 「시험 계획」의 과제를 요청 문장으로 바꾼 것이다. 현재 세션은 병합 전 발동 시험에서 같은 문장을 쓴다.

## 한 번 하는 확인

옛 이름이 남지 않았는지는 계약 테스트로 남기지 않고, 빌더가 마지막 참조 처리 뒤 한 번 실행해 결과를 리포트에 적는다. 옛 이름이 없다는 부정 조건은 `domain-pruning` 「분류」의 일회성에 해당하고, 영구 검사로 두면 옛 이름을 설명하는 문서가 생길 때마다 예외 목록을 고쳐야 한다. 큰 명세 「참조 처리 규칙」도 완료 조건을 grep 결과의 상태로만 정한다.

- **완료 조건** — `git -C "$HERE" grep -n --untracked 'lens-prior-art' -- . ':!docs/superpowers/reviews' ':!docs/superpowers/specs' ':!docs/superpowers/plans' ':!docs/domain-discipline.md' ':!skills/agent-prior-art/SKILL.md' ':!hooks/prior_art_nudge_userpromptsubmit.sh' ':!scripts/test_hooks.sh' ':!scripts/test_docs_drift.sh'`가 종료 코드 1(일치 없음)로 끝난다. 종료 코드 2 이상은 명령 오류이므로 통과로 보지 않는다. `--untracked`는 커밋 전 새 파일까지 보고 `.gitignore`의 `.claude/worktrees/`를 건너뛴다.
- **예외 파일 안의 범위** — `skills/agent-prior-art/SKILL.md`에서 `lens-prior-art`가 있는 줄은 `description:` 줄뿐이고, 같은 파일에 `lens-derived`가 없다. 빌더는 파일이 있는지 먼저 확인한다.
- **옮긴 문장의 대조** — 「판정 규약」「출력 스키마」「레퍼런스 프롬프트」로 옮긴 문장을 `git show 7a2d26d:skills/lens-prior-art/SKILL.md`와 대조한다. 다른 곳은 「판정 규약을 옮기는 규칙」「출력 스키마를 옮기는 규칙」「레퍼런스 프롬프트의 요건」이 정한 차이뿐이어야 한다.
- **정의의 출력 형식** — 두 정의의 출력 형식 블록이 스킬 「출력 스키마」의 같은 자료와 같다.

`specworkflow`의 파일은 옛 이름을 쓰지 않으므로 예외에 넣지 않는다. 통합 트리에서의 확인은 현재 세션이 한다(큰 명세 「공유 결정」).

## 구현 순서의 제약

빌더는 아래 순서 제약을 plan 의 태스크 경계로 지킨다. 각 커밋 시점에 CLAUDE.md 「변경 뒤 실행」 명령이 `ALL PASS`이어야 한다.

- **스킬과 첫 포인터** — `skills/agent-prior-art/`를 만드는 커밋에 그 이름을 부르는 다른 스킬 문장(`review-specs` 23·64행 처리)을 함께 넣는다. 「스킬 등재」 검사는 다른 스킬이나 에이전트원칙이 그 이름을 불러야 통과한다.
- **옛 렌즈의 삭제와 열거** — `skills/lens-prior-art/` 삭제, `aggregating-lenses` 22·53·56·84-87행 처리, `dispatching-lenses` 73행 처리를 한 커밋에 넣는다. `test_docs_drift.sh`의 「집계 태깅 == 실제 디렉터리」와 렌즈 그룹 표 대조가 렌즈 디렉터리와 두 열거가 같은지 보기 때문이다. 삭제는 「한 번 하는 확인」의 옮긴 문장 대조를 마친 뒤에 한다.
- **감사 대상 등록** — 새 `.md`(스킬과 두 정의)를 만들면 테스트 전에 `git add`한다. `scripts/audit_targets.sh`가 `git ls-files`로 대상을 도출하므로, 추가하지 않으면 첫 문장·대구 한도·소유 표 검사가 새 파일을 보지 않아 커밋 뒤에야 실패가 드러난다.
- **실패 확인** — 새 검사가 구현 전에 실패하는지는 큰 명세 「결정 기록」 「묶음 FAIL 수 세기」의 명령으로 센다.
- **마지막 검증** — 마지막 커밋 뒤 `claude plugin validate ./`가 `Validation passed`를 낸다. 경고가 나오면 이번 변경 때문에 생긴 경고만 고친다.

## 확인 방법

빌더는 아래 차례로 완료를 확인한다.

1. 「참조 처리 목록」의 모든 행을 처리했다. 확인: 같은 grep 을 다시 실행해 남은 줄이 「참조 처리 목록」의 그대로 두는 줄과 완료 조건의 예외 파일뿐이다.
2. 스킬과 두 정의가 이 문서의 요건을 따른다. 확인: `[선행연구 에이전트]` 묶음이 통과하고, 「한 번 하는 확인」의 옮긴 문장 대조와 정의의 출력 형식 대조가 차이 없이 끝난다.
3. 넛지가 조건대로 알린다. 확인: `[prior-art-nudge]` 묶음이 통과하고, 실행 시간 측정값이 리포트에 있다.
4. 옛 렌즈가 없어졌다. 확인: `skills/lens-prior-art/`가 없고 「한 번 하는 확인」의 완료 조건이 종료 코드 1로 끝난다.
5. 저장소 전체 계약이 유지된다. 확인: CLAUDE.md 「변경 뒤 실행」 명령이 `ALL PASS`이고 `claude plugin validate ./`가 `Validation passed`다.

## 가정과 남은 위험

넛지는 Claude Code 가 훅 입력의 `prompt`에 한글을 `\uXXXX`로 이스케이프하지 않고 UTF-8 그대로 넣는다고 가정한다. 이 가정은 측정하지 않았다. 이스케이프되어 들어오면 한글 주제어가 하나도 맞지 않아 넛지가 뜨지 않는다. 현재 세션이 병합 전 발동 시험에서 이 가정을 확인한다.

넛지는 `prompt` 키 뒤의 문자열 전체를 대조하며, 공식 훅 문서의 입력 예시는 `prompt`를 마지막 키로 둔다. 키 순서는 문서가 보장하지 않으므로 이것도 가정이다. `prompt` 뒤에 경로 필드가 오면 경로에 든 낱말로 오탐이 날 수 있다.

낱말 대조는 주제어와 요청형이 함께 있지만 요청이 아닌 메시지("선행연구 에이전트 spec 리뷰해봐" 같은 것)를 구분하지 못하고 알림을 낸다. 알림은 차단하지 않으며 요청이 아니면 무시하라고 적으므로 비용은 추가 컨텍스트 한 줄이다. 병합 전 발동 시험의 '언급만 하는 메시지'에 요청형 표현이 들어가면 채택 기준이 실패할 수 있다.

`synthesize` 모드의 `refs`는 `passed_rows` 원소가 주장 참조를 함께 싣는다고 전제한다. 그 원소 형식 `{ ref, row }`는 `specworkflow`가 정했고 이 전제를 충족한다(큰 명세 「경계」).

`agentType`의 플러그인 에이전트 해석은 현재 세션이 2026-10-18에 실측으로 확인했다(큰 명세 「결정 기록」의 「런타임 확인」).

<!-- spec-review: passed -->
