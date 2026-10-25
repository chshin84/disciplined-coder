---
name: agent-prior-art
description: 선행연구·선행 사례·prior art를 찾아 달라거나 "이걸 이미 누가 해봤나"·"쓸 만한 도구가 있나"·"이 결정의 근거를 찾아 달라"고 할 때, 그리고 review-specs·review-docs가 선행연구를 제안해 승인받았을 때 연다. 연구 계획을 승인받고 연구자 서브에이전트 여럿으로 웹을 탐색한 뒤 검증자가 인용을 판정하는 선행연구 에이전트다. 옛 이름 lens-prior-art(선행연구렌즈)를 부르는 요청도 여기서 받는다.
---
# agent-prior-art — 선행연구 에이전트

이 스킬은 오케스트레이터(이 스킬을 따르는 메인 세션)가 선행연구를 운영하는 절차다. 오케스트레이터는 연구 계획을 사용자에게 승인받고, 탐색 워크플로 `disciplined-coder:prior-art-search`로 연구자 서브에이전트 여럿을 실행하며, 검증 단계가 판정을 통과시킨 인용만으로 보고한다.

## 오케스트레이터 절차

워크플로는 실행 도중에 사용자 입력을 받지 못하므로, 오케스트레이터는 승인이 필요한 지점마다 워크플로 실행을 나눈다. 단계 사이에 오케스트레이터와 사용자가 대화하는 턴이 들어가며, 그래서 선행연구는 여러 턴에 걸쳐 진행된다.

**프로토콜 항목.** 프로토콜은 오케스트레이터가 실행 전에 쓰는 연구 계획이다. 항목은 연구 질문, 상황, 대조 대상, 모드, 하위 질문(ID, 범위 문장, 포함·제외 기준), 질의 금지 목록, 탐색 모드 연구자 수와 그 산정 근거, `principles_path`다. 오케스트레이터는 `principles_path`를 실행 시점에 도출하며, 도출 규칙은 `dispatching-lenses`의 「렌즈에게 에이전트원칙을 알리는 법」을 따른다. 워크플로가 그 경로를 연구자와 검증자의 프롬프트에 넣는다.

**워크플로 실행.** 오케스트레이터는 2단계와 3단계에서 Workflow 도구로 `disciplined-coder:prior-art-search`를 실행하고, `args`에는 「출력 스키마」의 「키 이름과 바깥 형식」이 정한 프로토콜 객체를 넣는다.

오케스트레이터는 아래 단계를 차례로 진행한다.

**1. 상황 판정과 프로토콜** — 오케스트레이터가 「상황별 전략」으로 상황과 대조 대상을 정하고 프로토콜을 쓴다. 사용자에게 프로토콜을 보이고 승인을 받으며, 승인이 없으면 실행하지 않는다. 승인을 받으면 오케스트레이터는 곧바로 기록 파일을 만들고 프로토콜 전문과 승인 사실을 적는다.

   - **확인** — 기록 파일에 프로토콜 전문과 승인 사실이 있다.

**2. 탐색** — 오케스트레이터가 `disciplined-coder:prior-art-search`를 프로토콜과 함께 실행한다. 아래 처리는 워크플로가 한다.

   - 하위 질문마다 탐색 모드 연구자를 실행한다.
   - 스크립트가 연구자의 `queries`를 질의 금지 목록과 경로 형태 정규식으로 검사하고 위반을 기록한다.
   - 스크립트가 인용을 URL 로 묶고, URL 마다 추출 검증자를 실행한다.
   - 추출이 모두 끝나면 스크립트가 추출을 통과한 주장을 묶음으로 모으고, 판정 에이전트를 묶음마다 한 번 실행한다.
   - 처음 판정에 `정보 부족`이 있고 `불일치`가 없는 주장은 추출 검증자가 원문을 다시 열어 보충한다. 스크립트가 보충한 주장을 다시 묶음으로 모으고, 판정 에이전트가 보충 구절로 다시 판정한다.
   - 끝까지 `판정 불가`가 남은 주장은 스크립트가 `unsupported`로 정한다.
   - 스크립트는 `supported` 판정을 받은 주장에 기댄 사례만 통과 목록에 넣는다.
   - 나머지 사례는 탈락 목록, 판정 불가 목록, 검증 실패 목록에 사유와 함께 들어간다.
   - `survey` 모드에서는 종합 모드 연구자와 지도 대조 에이전트를 차례로 실행한다.

   - **확인** — 반환값이 「출력 스키마」의 워크플로 반환값 형식을 따른다.
   오케스트레이터는 반환 직후 원본을 기록 폴더에 쓴다.

**3. 공백 판단** — 오케스트레이터가 커버리지 표와 연구자의 `saturation`·`not_found`를 사용자에게 보이고, 공백 라운드를 실행할지 묻는다. 공백 라운드는 커버리지 공백이 남은 하위 질문만 대상으로 `disciplined-coder:prior-art-search`를 다시 실행하며, 한 연구 질문에 1회까지다. 오케스트레이터는 두 실행의 결과를 하위 질문 ID 로 합치고, 같은 URL 이 두 실행에 다 있으면 공백 라운드의 판정을 쓴다. 주장 참조에는 실행 차례가 없어 두 실행에서 같은 참조가 서로 다른 사례를 가리킬 수 있으므로, 합친 결과에는 참조 앞에 원본 이름의 실행 차례를 붙여 `r<n>:<참조>`로 적는다. `survey`에서는 두 실행의 종합을 따로 보고한다.

   - **확인** — 기록에 공백 라운드 실행 여부와 사유가 있고, 공백 라운드 원본이 반환 직후 기록 폴더에 있다.

**4. 인용 확인과 보고** — 오케스트레이터가 「인용 확인」의 범위에 드는 인용을 직접 열어 확인한다. 그다음 기록 파일에 처분 전 결과를 적고 사용자에게 보고한다. 문서에 반영할지는 사용자가 정한다.

   - **확인** — 기록 파일과 원본의 이름이 `review-docs`의 「기록 파일 이름 규칙」을 따른다.

**원본 파일 규칙.** 기록 폴더 안의 원본 이름은 `review-docs`의 「기록 파일 이름 규칙」이 `prior-art` 종류에 정한 이름을 쓰며, 이름에 붙는 실행 차례 `r<n>`은 첫 탐색이 1, 공백 라운드가 2 다. 4단계 기록에 적을 항목은 `review-specs`의 「`prior-art` 기록에 적을 것」을 따르며, spec 리뷰가 아니면 그 항목에서 spec·plan 구분을 뺀다.

**반환값을 읽는 규칙.** 판정과 보고에는 `passed`의 `ref`가 가리키는 항목만 쓴다. `rejected`·`unverifiable`·`verify_failed`의 항목은 사유와 함께 보고하되 판정에 쓰지 않는다. 사례 수는 `passed`·`rejected`·`unverifiable`로 세고 `verify_failed`는 세지 않는다. 오케스트레이터는 반환값의 원소와 사유를 아래 위치에서 읽는다.

**연구자와 검증자의 원본** — `researchers`는 하위 질문 차례의 `[{ id, output }]`이고, `verifiers`는 URL 묶음 차례의 `[{ url, subquestions, output, stages }]`이다. `output`은 워크플로가 검증 단계의 출력을 합친 인용 판정 출력이고, 실패한 연구자와 URL 은 `output: null`이다. `stages`는 `{ extract, judge, refetch, rejudge }`이며 단계마다 에이전트의 원본 출력을 포함한다. `refetch`는 보충, `rejudge`는 재판정의 출력이다. `judge`와 `rejudge`는 묶음 출력 중 그 URL 의 판정만 포함한다.

**탈락과 판정 불가의 사유** — 같은 `ref`의 `verifiers[].output.judgments[]`에 있는 `verdict`와 `reason`이다. 판정할 선행 사례 서술이 없는 항목은 검증자에게 보내지 않고 `rejected`에 든다. 그래서 `rejected` 원소에 그 `ref`의 판정이 없으면, 오케스트레이터는 `urls`가 비었을 때 사유를 '인용에 URL 이 없다'로, 그 밖에는 '판정할 선행 사례 서술이 없다'로 적는다.

**`stages`의 `null`** — `verifiers[].stages`의 단계가 `null`이면 그 단계를 실행하지 않았거나 응답이 없었다는 뜻이며, 둘을 값으로는 구별하지 못한다. 추출과 보충은 URL 마다 실행하므로, 오케스트레이터는 호출 label(`extract:<url>`, `refetch:<url>`)이 있는지로 구별한다. 판정과 재판정은 묶음마다 실행하므로, 오케스트레이터는 그 URL 이 든 묶음의 호출 label(`judge:<n>`, `rejudge:<n>`)과 그 호출의 결과로 구별한다. `<n>`은 1 부터 세는 묶음 번호이고, 그 URL 이 어느 묶음에 들었는지는 그 호출 프롬프트의 `items`에서 찾는다. 그 URL 이 든 묶음 호출이 없으면 그 단계를 실행하지 않았고, 호출이 있는데 결과가 없으면 응답이 없었다. 추출을 통과한 주장이 없는 URL 은 판정 묶음에 넣지 않는다. 불일치 없이 정보 부족이 있는 주장이 없으면 보충을 실행하지 않고, 보충을 통과한 주장이 없는 URL 은 재판정 묶음에 넣지 않는다.

**검증 실패의 사유** — URL 전체의 실패는 같은 `url`의 `verifiers[].output`이 `null`인 때다. 추출이 응답하지 않았거나 판정이 빠졌거나, 그 URL 이 든 판정 묶음이 응답하지 않았거나, 판정의 칸이 빠졌다는 뜻이다. 어느 단계인지는 `stages`와 호출 label 로 찾는다. 주장 하나의 실패는 `verifiers[].output.judgments[]`에서 `verdict`가 `verify_failed`인 판정이다. 판정 출력에서 그 주장이 빠졌거나, 보충이나 재판정이 그 주장에서 실패했거나, 재판정에도 정보 부족이 남았다는 뜻이다. 어느 사정인지는 `stages`의 `judge`·`refetch`·`rejudge`에서 그 `ref`의 판정으로 찾는다. 한 URL 의 실패한 주장이 여럿이면 `verify_failed`에는 그 URL 의 `{ url, refs }` 한 원소로 모인다.

**종합 결론의 사용** — 종합은 하위 질문의 상태와 무관하게 통과한 근거 지도 행 전부를 받는다. 그래서 `conclusions[].refs`에 `ok`가 아닌 하위 질문의 참조가 하나라도 있으면, 오케스트레이터는 그 결론을 판정에 쓰지 않고 보고에만 적는다.

**`synthesis: null`의 두 사정** — 통과 행이 없어 종합을 실행하지 않은 사정과 종합이 실패한 사정은 `passed`에 `#case#` 항목이 있는지로 구별한다. `synthesis`가 `null`이면 `map_check`도 `null`이다.

**질의 경계 위반** — `query_violations[].rule`의 값은 `forbidden-term`과 `path-shape`다.

**상태 값.** `search_status`는 연구자마다 `ok`·`no-results`·`failed`·`not-attempted` 중 하나이며 뜻은 「출력 스키마」의 표가 정한다. `verification_status`는 하위 질문마다 `ok`·`partial` 중 하나다. 그 하위 질문의 URL 에 검증 실패(검증 단계 에이전트의 실패, 시간 초과, 속도 제한, 판정 누락, 보충 실패, 재판정 실패, 재판정 정보 부족)가 하나라도 있으면 `partial`이다. 보충 실패는 보충이 응답하지 않았거나 그 주장을 빠뜨렸거나, 보충 출력의 `access`가 `실패`이거나 `exists`가 `불일치`이거나 `quote`가 없는 때다. 판정 누락은 판정 출력에서 그 주장이 빠진 때다. 재판정 실패는 그 주장이 든 재판정 묶음이 응답하지 않았거나 재판정이 그 주장이나 칸을 빠뜨린 때이고, 재판정 정보 부족은 재판정에도 `정보 부족`이 남은 때다. 끝까지 `판정 불가`가 남은 주장은 검증 실패가 아니라 `unsupported`로 기각된다. 구절이 주장을 뒷받침한다는 확인이 없기 때문이다. 연구 질문 전체의 `overall_status`는 모든 하위 질문의 두 값이 `ok`일 때만 `ok`다. `overall_status`가 `ok`가 아니면 오케스트레이터는 `ok`가 아닌 하위 질문의 결과를 판정으로 쓰지 않고 하위 질문별 값을 보고에 적는다.

**세션이 끊긴 때.** 워크플로가 실행 중에 중단되면 오케스트레이터는 같은 세션 안에서 런타임의 이어 실행 기능으로 다시 시작한다. 반환 전에 세션 자체가 끝나면 기록에는 프로토콜과 승인 사실만 남는다. 다음 세션의 오케스트레이터는 검색어가 이미 나갔을 수 있다고 기록에 적은 뒤, 같은 프로토콜로 사용자 승인을 다시 받아 처음부터 실행한다.

**워크플로가 꺼진 환경.** `disableWorkflows`가 켜져 있으면 오케스트레이터는 같은 순서로 연구자와 검증자를 Agent 도구로 실행한다. `subagent_type`에는 `disciplined-coder:prior-art-researcher`, `disciplined-coder:prior-art-verifier`(추출과 보충), `disciplined-coder:prior-art-judge`(판정과 재판정), `disciplined-coder:prior-art-mapcheck`를 단계에 맞게 넣고, 프롬프트는 「출력 스키마」의 「에이전트에게 보내는 프롬프트」 형식으로 쓴다. 이 경로에서는 질의 경계 검사와 통과 목록 분리를 오케스트레이터가 직접 하고, 단계 출력의 합치기도 오케스트레이터가 한다. 검증 단계는 추출, 판정, 보충, 재판정 차례로 실행한다. 판정과 재판정은 주장을 「실행할 때 지킬 상한」의 묶음 크기대로 묶어 묶음마다 한 번 실행한다. 합치기는 「출력 스키마」의 「최종 판정과 실패 처리」 순서를 직접 적용하는 일이며, 접근 실패, 존재 불일치와 구절 없음, 판정 실패와 판정 누락, 처음 판정의 불일치, 보충과 재판정, 판정 불가, 칸별 불일치를 그 순서로 구분한다. 그래서 이 경로의 검사와 분리와 합치기는 지시 준수에만 기댄다. 오케스트레이터는 이 사실을 보고와 기록에 적는다.

## 발동과 기록

선행연구 에이전트의 제안과 승인, 직접 요청, 판정 기록, 서브 세션 처리의 규칙은 여기가 소유한다. 선행연구 에이전트는 렌즈가 아니므로 `dispatching-lenses`의 「렌즈 그룹」은 적용되지 않는다.

**제안과 승인.** `review-specs`와 `review-docs`는 각자의 발동 기준에 해당하면 실행을 제안한다. 1단계의 프로토콜 승인이 실행 승인이다.

**직접 요청.** 사용자가 선행연구를 직접 요청하면 그 요청이 실행 제안의 승인이다. 오케스트레이터는 그래도 1단계의 프로토콜 승인을 받는다.

**판정 기록.** `review-specs`와 `review-docs`는 선행연구 에이전트를 제안했는지, 승인받았는지, 각각의 이유를 그 차수의 기록에 적는다. 그래야 실행하지 않은 사실이 조용히 사라지지 않는다.

**서브 세션.** `nested-orchestration`의 서브 세션은 사용자에게 묻지 못하므로 선행연구 에이전트를 실행하지 않는다. 서브 세션은 발동 기준에 해당한 사실만 리포트에 적어 현재 세션에 넘긴다. 선행연구 없이 진행할 수 없으면 서브 세션은 멈추고 현재 세션에 승인을 요청하며, 그 형식은 `nested-orchestration`의 프로토콜 파일(`references/sub-session-protocol.md`)이 정한다.

**발동 넛지.** 넛지는 사용자 메시지가 선행연구를 요청하면 이 스킬을 열라는 알림을 추가 컨텍스트로 내고, 차단하지 않는다. 넛지가 알리는 조건과 낱말 목록은 `hooks/prior_art_nudge_userpromptsubmit.sh`가 정한다. 넛지는 메시지마다 실행되며 세션당 횟수 제한을 두지 않는다. 같은 세션의 두 번째 요청에서도 발동 누락이 생길 수 있기 때문이다.

## 상황별 전략

오케스트레이터는 1단계에서 아래 표로 상황을 판정하고, 그 상황에 따라 대조 대상과 하위 질문 분해와 모드를 정한다. 상황 목록은 사용자가 2026-10-18에 확정했다.

| 상황 | 발동 경로 | 대조 대상 | 하위 질문 분해 | 모드 |
|---|---|---|---|---|
| spec 대조 | `review-specs`의 제안과 승인 | spec 의 메커니즘 | 핵심 메커니즘마다 하나 | `contrast` |
| 제안서 검진 | `review-docs`의 제안과 승인 | 문서가 주장하는 방법 | 주장하는 방법마다 하나 | `contrast` |
| 기존 도구 탐색 | 사용자 직접 요청("쓸 만한 것 없나") | 사용자가 만들려는 것 | 검색 경로마다 하나(목록 사이트, 저장소, 논문) | `survey` |
| 결정 근거 탐색 | 사용자 직접 요청("근거를 찾아 달라", "어떻게 배치해야 하나") | 사용자가 고르려는 결정 후보안 | 결정이 기대는 주제마다 하나 | `survey` |
| 사실 확인 | 사용자 직접 요청, 단일 사실 | 확인하려는 주장 | 나누지 않음 | `survey` |

오케스트레이터가 상황이나 대조 대상을 하나로 정하지 못하면 사용자에게 묻는다.

## 실행할 때 지킬 상한

오케스트레이터는 탐색 모드 연구자 수, 연구자와 검증자의 턴 수, 공백 라운드 수에 아래 상한을 지킨다.

**상한 값.** 탐색 모드 연구자 수의 통상은 2개, 최대는 20개다. 사용자가 2026-10-18에 이 두 값을 정했으므로, 바꾸려면 사용자에게 물어야 한다.

**통상을 넘을 때.** 통상은 오케스트레이터가 이유를 적지 않고 고를 수 있는 값이다. 통상을 넘는 수는 프로토콜에 이유를 적어 승인받는다. 하위 질문이 통상보다 많으면 오케스트레이터는 하위 질문을 묶지 않고, 연구자 수를 올리는 근거를 적는다.

**세는 대상.** 상한은 탐색 모드 연구자만 센다. 검증자와 종합 모드 연구자는 URL 수와 모드에 따라 정해지므로 상한에 넣지 않는다. 검증자 수는 URL 마다 추출 1, 보충 0~1 이고, 묶음마다 판정 1, 재판정 0~1 이다. 묶음 하나의 주장은 20개 이하이고, 한 URL 의 주장은 한 묶음에 둔다. 한 URL 의 주장이 20개를 넘으면 그 URL 만으로 묶음 하나를 만든다. 이 크기는 사용자가 2026-10-22에 정했고, 근거와 측정 계획은 spec 「Opus 일괄 판정」에 있다. 판정 묶음에는 추출을 통과한 주장만, 재판정 묶음에는 보충을 통과한 주장만 넣는다. 보충은 주장마다 한 번만 한다. 검증자 수는 탐색이 끝나야 정해지므로, 오케스트레이터는 승인 때 연구자 수만 보이고 실제 검증자 수는 보고에 적는다. 연구자 하나가 인용할 출처는 약 100개 이하로 둔다. 이 값은 Anthropic cookbook 의 research subagent 프롬프트가 적은 "under about 100 sources"를 따른다.

**단계당 상한의 예외.** 선행연구 에이전트에는 `dispatching-lenses`의 "한 단계가 실행하는 에이전트는 10개 이하"를 적용하지 않는다. 사용자가 2026-10-18에 이 예외를 정했다. 한 단계의 규모는 연구자 상한 20과 런타임의 동시 실행 한도(기본 16)가 정한다.

**턴 상한.** 연구자와 검증자 정의의 `maxTurns`는 20 이다. 이 값은 같은 cookbook 프롬프트의 절대 상한인 도구 호출 20회를 따른다. 공식 문서는 `maxTurns`를 "agentic turns"로만 정의하며 도구 호출과의 관계는 적지 않으므로, 도구 호출 20회 상한은 연구자 프롬프트의 지시로도 둔다. 런타임이 상한에 이른 연구자의 출력을 partial 로 표시하면, 오케스트레이터는 그 하위 질문을 공백 후보로 다룬다.

**공백 라운드 상한.** 공백 라운드는 한 연구 질문에 1회다. 이 PC에 설치된 Anthropic deep-research 스킬이 추가 라운드에 적은 "This step can only be followed once"를 따른다.

## 판정 규약

옮긴 문장의 '이 설계'는 대조 대상(spec·제안서의 방법, 사용자가 만들려는 것, 사용자가 고르려는 결정 후보안)을 가리킨다. 연구자는 아래 체크리스트와 축별 대조와 가드로 판정한다.

**체크리스트**

- **기시감** — 이 설계의 핵심 메커니즘에 대응하는 선행 사례가 연구·상용 제품·오픈소스 어디에 있는가.
- **결말** — 그 사례가 성공했는가, 실패했는가, 판정에 이르지 못했는가.
- **전이** — 그 실패 원인이 이 설계에도 있는가.
- **기준선** — 선행 사례가 쓴 단순한 기준선이 있는데 이 설계가 그것과 비교조차 하지 않았는가.
- **붐빔** — 이미 상용화되거나 표준이 된 것을 처음부터 다시 지으려 하는가.

**전이** — 있으면 그것이 이슈다.

대조는 축을 나눠 판정한다. 선행 사례와 이 설계가 무엇을 이루려는가(목적), 어떻게 이루는가(메커니즘), 무엇으로 됐다고 판정하는가(평가), 어디에 쓰이는가(적용 대상) 각 축에서 같은지 다른지를 적는다. 모든 축이 같아야 같은 사례이고, 하나라도 다르면 그 차이를 `evidence`에 적는다. 축을 나누지 않으면 겉만 닮은 것을 선행 사례로 오인한다. 축의 같고 다름은 선행 사례 전체를 대조 대상 전체와 비교해 정하며, 대조 대상의 구성요소 하나와만 같은 축은 다르다고 적고 그 구성요소를 밝힌다.

**가드**

- 참신함을 채점하지 않는다. 이슈가 되는 순간은 선행 결과가 이 설계의 전제를 반박하거나, 알려진 실패 원인이 이 설계에도 남아 있을 때뿐이다.
- "찾지 못했다"를 "존재하지 않는다"로 쓰지 않는다. 못 찾은 것은 `not_found`에 이유와 함께 적고 독창성의 근거로 삼지 않는다.
- 오인도 못 찾음만큼 차단한다. 네 축 대조에서 하나라도 다르면 그 차이를 명시하고 같은 사례라고 단정하지 않는다. 못 찾음은 아무것도 바꾸지 않지만 오인은 멀쩡한 설계를 지운다.
- `weak-baseline`은 비교를 요구하되 구현을 요구하지 않는다. 그 유형의 `claim`은 "이 기준선과 비교되지 않았다"까지만 적고 무엇을 만들라고 적지 않는다.
- 인용한 URL은 실제로 열어 확인하고 출처의 성격을 구분해 적는다. 열지 못했으면 `opened`를 거짓으로 두고 `disclosures`에 적는다. 스스로 계산하거나 추론한 값은 `derived`로 표시한다.
- 질의 경계를 지킨다. 검색어에는 일반화된 기술 용어와 공개된 개념만 넣는다. 고유명사와 파일 경로와 사내 식별자와 미공개 제품명과 사람 이름과 코드 조각은 넣지 않는다. 검색 질의는 제3자가 보관하는 로그다(`SECRETS`). 그 경계 안에서 대조가 불가능하면 질의를 넓히지 말고 `not_found`에 "질의 경계 때문에 확인하지 못했다"고 적는다.

연구자는 가드의 "인용한 URL은 실제로 열어 확인하고 출처의 성격을 구분해 적는다"를 그대로 따르고, 검증자는 연구자가 적은 결과를 다시 판정한다.

## 출력 스키마

연구자·종합·추출·판정·합친 인용 판정·지도 대조 출력과 워크플로 반환값의 형식은 아래와 같으며, 키 이름의 원본은 계약 코드 `scripts/prior_art_contract.json`이다. 연구자 정의는 `researcher`·`synthesis`, 추출 검증자 정의는 `extract`와 입력 예시 `refetch`, 판정 정의는 `judge`와 입력 예시 `judge_input`, 지도 대조 정의는 `map`의 예시 블록을 싣는다. 출력 예시 블록은 아래 블록과 글자가 같다. 합친 `verifier` 블록은 어느 정의에도 없고 워크플로가 단계 출력을 합쳐 만든다.

**연구자 출력.** 연구자 출력의 칸은 아래 `researcher` 예시 블록과 같다. `agent` 칸의 값은 `agent-prior-art`다. `citations`의 `kind` 중 `standard`는 표준기구 문서이고, `derived`는 에이전트가 스스로 계산하거나 추론한 값이다. 그중 아래 표의 칸이 선행연구 에이전트가 추가한 칸이다. 이슈 하나의 `citations`는 출처 하나뿐이며, 워크플로 스키마가 `maxItems: 1`로 강제한다. 검증자가 URL 하나에 주장 전체를 대조하므로, 여러 출처에 기대는 주장은 연구자가 출처마다 이슈로 나눠 적는다.

| 칸 | 내용 |
|---|---|
| `mode` | `contrast`(이슈만) 또는 `survey`(이슈와 근거 지도)다. 상황이 정한다 |
| `subquestion_id` | 프로토콜의 하위 질문 ID 다 |
| `queries` | 연구자가 WebSearch 에 보낸 검색어 전부다. WebFetch 로 연 URL 은 `read`에 적고 여기에 적지 않는다. 질의 경계 검사의 입력이다 |
| `evidence_map` | `survey`에서만 채운다. 탐색 모드 연구자는 자기 하위 질문의 행을 채우고, 종합 모드 연구자는 통과 목록의 행만으로 다시 만든다. 행마다 사례 이름, URL, 각 축의 `{ prior, same, note }`(`prior`는 선행 사례 쪽 서술, `same`은 대조 대상과 같은지, `note`는 그 판단의 근거), 결말(성공·실패·판정 못 함), 출처 성격, 1차·2차 출처 구분, 찾은 경로(`route`)를 적는다. 기존 도구 탐색 상황에서는 `adoption`(채택·흡수·참고·해당 없음)도 채운다 |
| `saturation` | 마지막 세 번의 검색에서 새 사례가 몇 건 나왔는지다 |
| `issues[].prior_claim` | 이슈마다 선행 사례와 그 결말에 관한 서술만 적은 문장이다. 검증자가 판정하는 대상이다. 대조 대상에 관한 서술(전이, 기준선과 비교되지 않음)은 `claim`에 남기고 판정하지 않는다 |

`contrast` 모드에서 `evidence_map`은 빈 배열이다. 근거 지도 행의 `axes`와 이슈의 `prior_claim`은 워크플로가 검증자에게 보내는 판정 대상의 재료다.

<!-- output: researcher -->
```json
{
  "agent": "agent-prior-art",
  "mode": "contrast|survey",
  "subquestion_id": "sq1",
  "search_status": "ok|no-results|failed|not-attempted",
  "queries": [ "실행한 검색어" ],
  "read": [ "..." ],
  "issues": [
    {
      "where": "...",
      "type": "refuted-premise|known-failure|crowded|weak-baseline",
      "claim": "...",
      "prior_claim": "선행 사례와 그 결말에 관한 서술만 적은 문장",
      "consequence": "...",
      "evidence": "그렇게 본 근거 — 문서 인용, 파일 경로와 줄, URL. 이 렌즈는 선행 사례와 그 결말, 네 축의 같고 다름을 적는다",
      "citations": [ { "url": "...", "kind": "peer-reviewed|preprint|vendor|blog|standard|derived", "opened": true } ]
    }
  ],
  "evidence_map": [
    {
      "case": "사례 이름",
      "url": "...",
      "axes": {
        "purpose": { "prior": "선행 사례 쪽 서술", "same": true, "note": "그 판단의 근거" },
        "mechanism": { "prior": "선행 사례 쪽 서술", "same": false, "note": "그 판단의 근거" },
        "evaluation": { "prior": "선행 사례 쪽 서술", "same": true, "note": "그 판단의 근거" },
        "target": { "prior": "선행 사례 쪽 서술", "same": true, "note": "그 판단의 근거" }
      },
      "outcome": "성공|실패|판정 못 함",
      "kind": "peer-reviewed|preprint|vendor|blog|standard|derived",
      "source_level": "1차|2차",
      "route": "찾은 경로(목록 사이트, 저장소, 논문)",
      "adoption": "채택|흡수|참고|해당 없음",
      "bearing": "그 근거가 어느 후보안을 어느 방향으로 움직이는지"
    }
  ],
  "saturation": 0,
  "not_found": [ "찾지 못한 것과 그 이유 — 독창성의 근거가 아니다" ],
  "disclosures": [ "렌즈 자신의 불확실성" ],
  "principles_applied": [ "읽고 적용한 원칙 ID" ],
  "notes": ""
}
```

`search_status`는 빈 `issues`가 어느 사정에서 나왔는지 구별한다.

| 값 | 뜻 | 빈 `issues`의 해석 |
|---|---|---|
| `ok` | 검색이 실행되었고 결과도 있었다 | 선행 사례를 봤으나 문제될 것이 없었다는 뜻이라 판정으로 쓸 수 있다 |
| `no-results` | 검색은 실행되었으나 아무것도 못 찾았다 | 판정이 아니다. 이유가 `not_found`에 있어야 한다 |
| `failed` | 도구가 오류를 냈거나 접근이 차단되었다 | 판정이 아니다. 호출자가 검색 실패로 보고한다 |
| `not-attempted` | 검색을 시도하지 않았다 | 판정이 아니다. 선행연구 에이전트가 검색을 실행한 것으로 치지 않는다 |

선행연구 에이전트의 발견은 문서에 자동으로 반영하지 않는다. 웹에서 읽어 온 내용이 문서를 저절로 고치는 길을 닫기 위해서다. spec 리뷰에서는 발견을 전부 `🔴`로 처분하며 그 규칙은 `review-specs`가 소유한다. 문서 검진에서는 `review-docs`가 발견을 사용자에게만 전달한다.

**종합 모드 연구자 출력.** 종합 모드 연구자는 통과 행만으로 근거 지도를 다시 만들고, 결론마다 근거가 된 행의 주장 참조를 `refs`에 적는다. 주장 참조의 형식은 `<하위 질문 ID>#<issue|case>#<배열 위치>`이며, 배열은 연구자 출력의 `issues`나 `evidence_map`이다.

<!-- output: synthesis -->
```json
{
  "evidence_map": [
    {
      "case": "사례 이름",
      "url": "...",
      "axes": {
        "purpose": { "prior": "선행 사례 쪽 서술", "same": true, "note": "그 판단의 근거" },
        "mechanism": { "prior": "선행 사례 쪽 서술", "same": false, "note": "그 판단의 근거" },
        "evaluation": { "prior": "선행 사례 쪽 서술", "same": true, "note": "그 판단의 근거" },
        "target": { "prior": "선행 사례 쪽 서술", "same": true, "note": "그 판단의 근거" }
      },
      "outcome": "성공|실패|판정 못 함",
      "kind": "peer-reviewed|preprint|vendor|blog|standard|derived",
      "source_level": "1차|2차",
      "route": "찾은 경로(목록 사이트, 저장소, 논문)",
      "adoption": "채택|흡수|참고|해당 없음",
      "bearing": "그 근거가 어느 후보안을 어느 방향으로 움직이는지"
    }
  ],
  "conclusions": [ { "text": "결론 문장", "refs": [ "sq1#case#0" ], "supports": "지지하는 후보안" } ],
  "principles_applied": [ "읽고 적용한 원칙 ID" ]
}
```

**검증 단계와 출력.** 검증은 추출, 판정, 보충, 재판정 차례로 진행한다. 추출 검증자(`prior-art-verifier`, `MODE: extract`)가 URL 하나를 열어 주장마다 접근·존재·구절을 판정한다. 추출이 모두 끝나면 워크플로가 추출을 통과한 주장을 묶음으로 모은다. 판정 에이전트(`prior-art-judge`, `MODE: judge`)는 묶음 하나를 받아, 웹을 열지 않고 추출 검증자가 옮긴 `quote`와 `context`, 존재 확인 사유 `source_note`만 보고 수치·조건, 방향, 범위를 판정한다. 판정 에이전트는 주장마다 같은 `items` 원소의 구절만 근거로 쓴다. 판정 에이전트는 칸마다 먼저 판정에 필요한 정보가 있는지 판단하고, 없으면 그 칸을 `정보 부족`으로 둔다. 처음 판정에 `정보 부족`이 있고 `불일치`가 없는 주장은 추출 검증자가 URL 마다 원문을 다시 열어 보충한다(`MODE: refetch`). 워크플로가 보충한 주장을 다시 묶음으로 모으고, 판정 에이전트가 보충 구절로 그 주장의 모든 칸을 다시 판정한다(재판정). 판정 기준은 "옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported"로 고정한다. 판정 대상은 선행 사례 쪽 서술뿐이다. 이슈는 `prior_claim`, 근거 지도 행은 사례 이름과 `outcome`과 각 축의 `prior`다. 근거 지도 행은 사례가 있다는 것과 그 결말을 뒷받침하는 구절이 있으면 `supported`이고, 축마다의 판정은 `reason`에 적는다. 대조 대상 쪽 판단(`same`, `note`, 이슈의 `claim`)은 연구자가 책임지며 사용자가 보고에서 확인한다(2026-10-18 사용자 결정). `unverifiable`은 원문 쪽 사정(봇 차단, 유료 장벽, 응답 없음)만 뜻하며 반박으로 세지 않는다.

추출 출력은 주장마다 `access`(성공·실패), `exists`(일치·불일치), `exists_note`(확인한 제목·저자·학회), `quote`, `context`(그 구절 앞뒤의 부정·조건·비교 문장), `reason`을 포함한다. 보충 출력의 형식은 추출 출력과 같다. 판정 출력은 묶음 하나의 판정 전부이며, 주장마다 그 주장의 `url`과 `ref`, `numbers_conditions`·`direction`·`scope` 세 칸에 `일치`·`불일치`·`판정 불가`·`정보 부족`을 포함한다. `정보 부족`인 칸에는 `missing`에 없는 요소를 적고, `판정 불가`인 칸에는 `unsure_reasons`에 이유 유형(`조건 얽힘`·`표·그림 값`·`언어 해석`)을 적는다. 워크플로는 판정 출력을 `url`로 나누고, 입력에 없던 URL 이나 `ref`의 판정은 버린다. 재판정 출력의 형식은 판정 출력과 같다.

<!-- output: extract -->
```json
{
  "url": "판정한 URL",
  "judgments": [
    { "ref": "sq1#issue#0", "access": "성공|실패", "exists": "일치|불일치", "exists_note": "확인한 제목·저자·학회", "quote": "원문에서 고치지 않고 옮긴 지지 구절", "context": "그 구절 앞뒤의 부정·조건·비교 문장", "reason": "판정 이유" }
  ],
  "principles_applied": [ "읽고 적용한 원칙 ID" ]
}
```

<!-- output: judge -->
```json
{
  "judgments": [
    { "url": "판정한 주장의 URL", "ref": "sq1#issue#0", "numbers_conditions": "일치|불일치|판정 불가|정보 부족", "direction": "일치|불일치|판정 불가|정보 부족", "scope": "일치|불일치|판정 불가|정보 부족", "missing": { "정보 부족인 칸 이름": "없는 요소" }, "unsure_reasons": { "판정 불가인 칸 이름": "조건 얽힘|표·그림 값|언어 해석" }, "reason": "판정 이유" }
  ],
  "principles_applied": [ "읽고 적용한 원칙 ID" ]
}
```

**최종 판정과 실패 처리.** 최종 `verdict`는 워크플로 스크립트가 아래 순서로 정하며 에이전트는 정하지 않는다. 워크플로가 꺼진 환경에서는 오케스트레이터가 같은 순서를 직접 적용한다.

1. 추출 검증자가 응답하지 않았거나 판정이 빠졌으면 그 URL 은 검증 실패다.
2. `access`가 `실패`이면 `unverifiable`이다.
3. `exists`가 `불일치`이거나 `quote`가 없으면 `unsupported`다.
4. 그 URL 이 든 판정 묶음이 응답하지 않았거나, 그 URL 의 판정 중 하나라도 세 칸 중 하나가 빠졌으면 그 URL 은 검증 실패다. 빠진 칸을 `일치`로 보지 않는다. 판정 출력에서 주장이 빠졌으면 그 주장만 `verify_failed`다.
5. 처음 판정에 `불일치`인 칸이 있으면 `unsupported`다. 이 주장은 보충을 하지 않는다.
6. `정보 부족`인 칸이 있으면 보충하고 재판정한다. 보충이 응답하지 않았거나 그 주장을 빠뜨렸거나, 그 주장이 든 재판정 묶음이 응답하지 않았거나 재판정이 그 주장을 빠뜨렸거나, 보충 출력의 `access`가 `실패`이거나 `exists`가 `불일치`이거나 `quote`가 없으면, 그 주장만 `verify_failed`다. 재판정은 그 주장의 세 칸을 모두 대체한다. 재판정에 `불일치`가 있으면 `unsupported`이고, 재판정에도 `정보 부족`이 있으면 그 주장만 `verify_failed`다.
7. 남은 칸에 `판정 불가`가 있으면 `unsupported`다. 판정 불가 칸의 이유 유형은 합친 출력의 `reason`에 남는다.
8. 그 밖은 `supported`다.

합친 출력은 아래 형식이며 `verifiers[].output`에 들어간다. `quote`는 보충 출력이 추출 기준을 통과했으면 보충 구절이고, 아니면 추출 검증자의 값이다. `reason`은 단계별 이유를 이어 붙인 값이다.

<!-- output: verifier -->
```json
{
  "url": "판정한 URL",
  "judgments": [
    { "ref": "sq1#issue#0", "verdict": "supported|unsupported|unverifiable|verify_failed", "quote": "원문에서 고치지 않고 옮긴 지지 구절", "reason": "판정 이유" }
  ],
  "principles_applied": [ "읽고 적용한 원칙 ID" ]
}
```

**지도 대조 출력.** 지도 대조 에이전트(`prior-art-mapcheck`)는 근거 지도의 칸마다 `row`, `column`, `grounded`(참·거짓), `source_ref`(근거가 된 통과 목록 항목)를 내고, 출력 전체에 `principles_applied`를 둔다.

<!-- output: map -->
```json
{
  "cells": [
    { "row": "사례 이름", "column": "case", "grounded": true, "source_ref": "sq1#case#0" },
    { "row": "사례 이름", "column": "outcome", "grounded": true, "source_ref": "sq1#case#0" },
    { "row": "사례 이름", "column": "axes.purpose.prior", "grounded": true, "source_ref": "sq1#case#0" },
    { "row": "사례 이름", "column": "axes.mechanism.prior", "grounded": true, "source_ref": "sq1#case#0" },
    { "row": "사례 이름", "column": "axes.evaluation.prior", "grounded": true, "source_ref": "sq1#case#0" },
    { "row": "사례 이름", "column": "axes.target.prior", "grounded": false, "source_ref": "" }
  ],
  "principles_applied": [ "읽고 적용한 원칙 ID" ]
}
```

**워크플로 반환값.** 반환값은 통과 목록, 탈락 목록, 판정 불가 목록, 검증 실패 목록, 하위 질문별 커버리지 표·`search_status`·`verification_status`, `overall_status`, 질의 경계 위반 목록, 실행한 검증자 수다. 원소와 사유를 읽는 위치는 「오케스트레이터 절차」의 「반환값을 읽는 규칙」이 정한다.

**키 이름과 바깥 형식.** 워크플로와 에이전트가 주고받는 JSON 의 키는 아래와 같다. 이 표는 계약 코드 `scripts/prior_art_contract.json`을 사람이 읽도록 옮겨 적었고, 둘이 다르면 계약 코드를 따른다.

| 자료 | 형식 |
|---|---|
| 워크플로 `args`(프로토콜) | `{ question, situation, target, mode: "contrast"\|"survey", round: 1\|2, subquestions: [{ id, scope, include, exclude }], forbidden_terms: [string], researcher_count, researcher_count_basis, principles_path, intended_use, constraints: [string] }`. `round`는 첫 실행이 1, 공백 라운드가 2 다 |
| 연구자 출력 | 「연구자 출력」의 `researcher` 예시 블록의 칸이다. `evidence_map` 행은 `{ case, url, axes: { purpose, mechanism, evaluation, target }, outcome, kind, source_level, route, adoption?, bearing? }`다 |
| 종합 모드 연구자 출력 | `{ evidence_map: [행], conclusions: [{ text, refs: [string], supports? }], principles_applied }` |
| 추출 검증자 출력 | `{ url, judgments: [{ ref, access, exists, exists_note, quote, context, reason }], principles_applied }`. `ref`의 형식은 주장 참조 형식이다. 보충 출력도 같은 형식이다 |
| 판정·재판정 입력 | `{ items: [{ url, claims: [{ ref, text, quote, context, source_note }] }] }`. 판정 정의의 `judge_input` 입력 예시 블록이 이 형식이다 |
| 판정·재판정 출력 | `{ judgments: [{ url, ref, numbers_conditions, direction, scope, missing, unsure_reasons, reason }], principles_applied }` |
| 합친 인용 판정 출력 | `{ url, judgments: [{ ref, verdict, quote, reason }], principles_applied }`. `verdict`는 `supported`·`unsupported`·`unverifiable`·`verify_failed`다 |
| 지도 대조 출력 | `{ cells: [{ row, column, grounded, source_ref }], principles_applied }` |
| 워크플로 반환값 | `{ round, passed, rejected, unverifiable, verify_failed: [{ url, refs }], coverage: [{ id, cases_found, passed }], subquestion_status: [{ id, search_status, verification_status }], overall_status, query_violations: [{ id, query, rule }], verifier_count, researchers, verifiers, synthesis?, map_check? }`. `passed`·`rejected`·`unverifiable`의 원소는 `{ ref, urls }`이고, `verifiers`의 원소는 `{ url, subquestions, output, stages }`다. `verifier_count`는 검증에 보낸 URL 수(`verifiers`의 길이)다. 추출이 실패한 URL 도 세고, 에이전트 호출 수는 아니며 보충·판정·재판정 실행 수도 세지 않는다. `overall_status`는 `ok`나 `not-ok`다 |

**에이전트에게 보내는 프롬프트.** 워크플로는 연구자와 검증자에게 보내는 프롬프트의 첫 줄을 `MODE: <모드>`로 쓴다. 모드 값은 연구자가 `explore`·`synthesize`, 검증 단계가 `extract`·`refetch`·`judge`·`map`이다. 추출 검증자는 추출에서 `extract`, 보충에서 `refetch`를 받는다. 판정 에이전트는 판정과 재판정에서 `judge`, 지도 대조 에이전트는 `map`을 받는다. 둘째 줄에는 `PRINCIPLES: <principles_path>`를 두고, 셋째 줄부터 모드별 입력을 json 코드 울타리 안의 `JSON.stringify(입력, null, 2)` 블록 하나로 둔다. 연구자 탐색 모드의 입력은 `{ question, situation, target, mode, subquestion, forbidden_terms, intended_use, constraints }`, 종합 모드의 입력은 `{ question, target, intended_use, constraints, passed_rows }`, 추출 모드의 입력은 `{ url, claims: [{ ref, text }] }`, 보충 모드의 입력은 `{ url, claims: [{ ref, text, missing }] }`, 판정 모드의 입력은 판정 묶음 `{ items: [{ url, claims: [{ ref, text, quote, context, source_note }] }] }`, 지도 대조 모드의 입력은 `{ evidence_map, passed }`다. 보충 입력의 `missing`은 처음 판정의 값이다. 판정 입력의 `quote`·`context`는 추출 출력(재판정이면 보충 출력)의 값이고, `source_note`는 같은 출력의 `exists_note`이며 없으면 빈 문자열이다. 추출 출력의 `reason`은 판정 입력에 넣지 않는다. 재판정의 입력도 판정 모드의 입력과 같은 형식이며, 보충한 주장만 묶는다. 판정과 재판정의 호출 label 은 `judge:<n>`·`rejudge:<n>`이고, 추출·보충은 `extract:<url>`·`refetch:<url>`, 지도 대조는 `map-check`다. `passed_rows`와 `passed`의 원소는 `{ ref, row }`다. 에이전트 정의의 모드 처리 단락은 이 첫 줄로 모드를 고른다.

**`principles_applied`가 빈 때.** 오케스트레이터는 그 사실을 보고에 적고 자동으로 다시 실행하지 않는다.

**판정 모델 교체.** 단계별 출력 형식은 판정 모델과 무관하다. 그래서 추출 검증자, 판정 에이전트, 지도 대조 에이전트 정의의 `model`만 바꾸면 단계마다 다른 모델로 바꿀 수 있다. 현재 구성은 판정 에이전트(판정과 재판정)가 Opus 5.5 에 노력 수준 medium 이고, 추출 검증자와 지도 대조 에이전트는 Haiku 5.5 에 노력 수준 high 다. 에이전트 정의는 모델 전체 ID 를 고정하며, 추출 검증자와 지도 대조 에이전트는 `claude-haiku-5-5`, 판정 에이전트는 `claude-opus-5-5` 다. 검증 측정도 이 ID 로 했다. Bedrock·Vertex 처럼 모델 ID 형식이 다른 환경이나 Opus 를 쓸 수 없는 계정에서는 사용자가 `agents/prior-art-*.md` 의 `model` 을 바꿔야 하고, 바꾼 뒤에는 다시 측정하는 것이 좋다. 판정 에이전트를 묶음마다 한 번 실행하는 것은 판정 정의 본문 같은 고정 입력을 호출마다 다시 읽는 비용을 줄이기 위해서다(spec 「Opus 일괄 판정」). 판정 전용 모델(예: Typesafe AI 의 Jev)도 쓸 수 있게 되면 같은 방식으로 바꿀 수 있다. 다만 Kim 등(ICML 2025)은 제공사가 달라도 오류 상관이 높다고 보고했으므로, 모델을 바꿔도 상관 오류가 줄어든다고 기대하지 않는다. 사내 문서를 외부 API 로 보내는 모델은 회사 승인이 필요하므로 구성에 넣기 전에 승인을 받아라.

## 인용 확인

인용 확인은 검증자와 오케스트레이터가 나눠 맡으며, 사용자가 2026-10-18에 이 분담을 정했다. 연구자가 늘어나면 오케스트레이터 혼자 인용 수십 건을 직접 열어야 하기 때문이다.

오케스트레이터는 추출 검증자가 옮긴 `quote`가 원문에 있고 주장을 뒷받침하는지 직접 열어 확인한다. 합친 출력의 `quote`가 이 값이며, 보충을 거친 주장이면 보충 구절이다. 판정 불가로 기각된 주장은 `reason`의 `판정 불가:` 항목에 칸과 이유 유형이 있다. 오케스트레이터는 이 주장을 반박된 주장으로 보고하지 않고, 구절이 주장을 뒷받침한다는 확인이 없어 기각되었다고 보고한다. 확인할 인용의 범위는 상황마다 다르다. spec 대조와 제안서 검진에서는 문서를 실제로 고치게 만들었거나 `🔴`로 올릴 발견, 그리고 사용자에게 전달할 발견이 근거로 삼은 인용 전부를 확인한다. 기존 도구 탐색, 결정 근거 탐색, 사실 확인에서는 보고의 결론 문장에 직접 쓰는 인용만 확인하고, 근거 지도의 나머지 행은 검증자 판정을 그대로 둔다.

이 절이 인용 확인 범위의 원본이다.

## 레퍼런스 프롬프트

연구자 정의의 `explore` 모드 단락은 아래 system 본문을 한 줄 그대로 싣고, 사용자 메시지의 형식은 「출력 스키마」의 「에이전트에게 보내는 프롬프트」가 정한다.

- system: "너는 선행연구 대조 검수자다. 기시감(이 설계를 누가 이미 해봤는지)과 결말(그 결과가 무엇이었는지)과 전이(그 실패 원인이 이 설계에도 있는지)를 찾아라. 선행 사례가 쓴 단순한 기준선이 있는데 이 설계가 그것과 비교조차 안 했는지, 그리고 붐빔(이미 상용화되거나 표준이 된 것을 처음부터 다시 지으려 하는지)도 함께 보라. 참신함을 채점하지 마라. 못 찾은 것은 `not_found`에 적고 독창성의 근거로 삼지 마라. 선행 사례는 목적·메커니즘·평가·적용 대상 네 축으로 대조하라. 모든 주장에 출처 URL과 그 성격을 달고 실제로 열어 확인하라. 질의에 고유명사와 경로와 사내 식별자를 넣지 마라. 체크리스트를 항목마다 따로 검토하고 그 결과를 한 번에 돌려주며, 검토한 관점을 `notes`에 적어라. 서브에이전트를 새로 열지 마라. 더 확인해야 할 것이 남으면 무엇을 왜 확인해야 하는지 `notes`에 적어라. 등급을 매기지 마라. 발견마다 이 불일치 때문에 지금 무엇이 그렇게 되어 있는지(consequence)와 그렇게 본 근거(evidence)를 적어라. 결과를 구체적으로 못 적는 것은 올리지 마라. 찾은 것이 없으면 빈 목록이 정상이다. 네 축 중 하나라도 다르면 그 차이를 적고 같은 사례로 단정하지 마라. 출처의 성격은 `citations`의 `kind`로 적고, 열지 못한 출처는 `opened`를 false 로 두어라. 입력의 `forbidden_terms`에 든 낱말도 질의에 넣지 말고, 실행한 검색어는 빠짐없이 `queries`에 적어라. 도구 호출은 20회 이하로, 인용할 출처는 약 100개 이하로 두어라. 입력의 `mode`가 `survey`이면 자기 하위 질문의 `evidence_map` 행을 채우고, `contrast`이면 `evidence_map`을 빈 배열로 두어라. 마지막 세 번의 검색에서 새 사례가 몇 건 나왔는지를 `saturation`에 적어라. 출력은 연구자 출력 JSON 하나로만 내고 앞뒤에 다른 글을 두지 마라."
