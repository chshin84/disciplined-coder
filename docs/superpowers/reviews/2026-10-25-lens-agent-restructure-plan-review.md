# 렌즈 에이전트 전환 plan 리뷰 기록

대상은 `docs/superpowers/plans/2026-10-25-lens-agent-restructure.md` 이다. 경로가 `docs/superpowers/plans` 아래이므로 plan 으로 구분했다. 렌즈 원본은 같은 이름의 폴더에 있다(`lens-grounding-1.json`, `lens-consistency-1.json`, `lens-adversarial-1.json`, `lens-fit-1.json`).

렌즈를 한 번씩만 실행했다.

plan 이므로 선행연구 에이전트는 제안하지 않았다.

## 합친 지적

| 번호 | 지적 | 잡은 렌즈 |
|---|---|---|
| 1 | Task 3 의 agent() 판정 규칙이 `workflows/prior-art-search.js` 15행 주석의 `agent()` 를 호출로 읽어 현행 파일에서 실패하고, 픽스처의 "첫 호출"도 그 주석을 가리킨다 | grounding, adversarial |
| 2 | agentType 판정이 낱말 포함이라 주석·문자열 속 낱말에 속고, 펼친 객체 인자는 오탐이 된다 | adversarial |
| 3 | 사유 값 `not-one-line` 이 Step 3 규칙으로 만들어지는 경로가 없다 | consistency |
| 4 | 결정 기록이 가정으로 둔 "agentType 없는 agent() 는 Agent 를 물려받는 기본 에이전트로 실행된다"를 확인하는 단계가 없다 | consistency |
| 5 | `lens-consistency` 계약에 감사 전용 값(`duplication`, `narrowed`, `pairs`)이 남아 감사를 지운 정의에 강제된다 | consistency, grounding |
| 6 | 계약 대조식이 최상위 칸과 `issues` 하위 칸을 한 집합으로 계산해 `suggestions` 만 내는 readability 예시가 통과할 수 없고, `suggestions` 하위 칸은 검사되지 않는다 | consistency, grounding |
| 7 | 「공통 계약의 예외」의 집계 제외 규칙과 `purpose` 원본 확인 규칙을 옮길 곳이 없다 | consistency |
| 8 | aggregating-lenses 「리뷰 산출물 계약」의 산문 규칙(상대편 없으면 발견 아님, 현재 상태만 적기, 등급 금지, 줄 번호 금지 등)을 옮길 곳이 없고, 정의가 복사할 포인터의 새 위치도 없다 | adversarial |
| 9 | 런타임 전용 결정과 재시도를 review-llm-calls 로 옮기는 단계가 없다 | consistency |
| 10 | `lens-adversarial-claim` 인용 확인을 상시 절차로 스킬에 적는 단계가 없다 | consistency |
| 11 | review-docs 가 제안서·보고서 검진 때 `lens-adversarial-claim` 을 제안하는 발동 조건을 적는 단계가 없다 | consistency |
| 12 | Playwright 시험이 실패했을 때 readability 를 글 검토 에이전트로 남기는 분기가 Task 2·4·7 에 없다 | consistency |
| 13 | Task 4 가 미룬 원칙 경량화 반영을 Task 5 가 하지 않아, 채택 비교가 반영 전 정의로 실행된다 | consistency, adversarial, fit |
| 14 | 정의별 tools 값을 검사하지 않아 claim 정의에 WebSearch 가 빠져도 통과한다 | consistency |
| 15 | 「따로 실행할 때와 묶을 때」 제목을 바꿀 때 그 제목을 가리키는 곳(review-specs:51 등)을 확인하는 단계가 없다 | consistency |
| 16 | `review-docs` 「기록 파일 이름 규칙」 제목 유지 조건과 확인이 없다 | consistency |
| 17 | plan 의 구현 단계가 spec 본문(비목표 줄)을 고치게 해 범위가 넓어졌다 | consistency |
| 18 | 스킬과 에이전트가 함께 있는 구간을 spec 은 3~5단계, plan 은 3~7단계로 적는다 | consistency, fit |
| 19 | 시험 명령에 권한 플래그가 없어 헤드리스 실행의 MCP 도구 거부가 "적을 수 없다"로 잘못 판정될 수 있다 | adversarial |
| 20 | `@agent-` 언급이 `claude -p` 에서도 같은 경로로 처리된다는 근거가 없다 | adversarial |
| 21 | 설치된 같은 이름 플러그인이 함께 적재되면 같은 이름 시험의 결과를 해석할 수 없는데, 그때의 판정이 없다 | adversarial |
| 22 | CLAUDE.md 상속 시험에서 메인 세션이 프롬프트에 원칙을 넣으면 상속으로 잘못 판정된다 | adversarial |
| 23 | 시험 1과 시험 5 가 같은 에이전트·대상을 두 번 실행한다 | adversarial |
| 24 | stream-json 에서 받은 도구·턴 수·effort 를 읽을 수 있다는 전제에 근거가 없다 | grounding |
| 25 | 모든 작업이 바로 커밋해 "커밋은 사용자 요청 시에만" 지시와 상충한다 | adversarial |
| 26 | Task 8 이 aggregating-lenses 를 지우면 Task 2 의 계약 대조 검사가 원본을 잃는다 | grounding |
| 27 | Task 8 의 결함 주입이 옮긴 렌즈 스키마 검사의 성질을 겨누지 않는다 | adversarial |
| 28 | `scripts/scaffold.sh:231` 과 `scripts/_test_check.sh:3` 의 감사 언급이 Task 8 목록에 없다 | adversarial |
| 29 | `test_docs_drift.sh` 284·872행은 렌즈 목록이 아니라 호출자 목록이고, 표에서 도출하면 nested-orchestration 이 빠진다 | grounding |
| 30 | Task 9 가 fit 비율 하나를 재려고 렌즈 차수 전체를 실행하고, 미달 시 처리가 없다 | adversarial |
| 31 | 검증자 재사용을 다시 묻는 기준("실패가 많으면")이 없다 | adversarial, fit |
| 32 | Task 10 시험 단위에 `ids` 파일이 없어 조항 ID 가 폴더 이름이 된다 | grounding |
| 33 | 계약에 `target` 칸이 없어 review-docs 의 대상 구분 규칙과 상충한다 | grounding |
| 34 | 커밋 단계에 `git add` 가 없다 | fit |
| 35 | Task 1 Step 2 에 시험별 요청 문자열과 통과 출력이 없다 | fit |
| 36 | 한 Step 에 행동이 여럿이다(Task 3 Step 5, Task 8 Step 2, Task 5 Step 1 등) | fit |
| 37 | Task 5·6 의 에이전트 실행 Step 에 실행 형식이 없다 | fit |
| 38 | 리뷰 초점 2 를 고정하는 검사가 Task 4 에 없다 | fit |
| 39 | Task 9 테스트 Step 에 테스트 이름·단언이 없고 조사 기록 경로가 없다 | fit |
| 40 | 문체: Step 지시를 평서형으로 적음, 평서형 부정문, 목록 앞 개수와 개수로 가리키기, 문장 중간 관형절, 네 문장 넘는 단락, 라벨 불릿, 주체 없는 문장 | fit |

## 커버리지

네 렌즈 모두 지적을 냈다. 둘 이상의 렌즈가 함께 잡은 항목은 1, 5, 6, 13, 18, 31 이다. 아래 사항은 `notes` 에만 적혔다. consistency 는 spec 에도 aggregating-lenses 「출력 스키마」 절의 처분 행이 없다고 적었고, Task 5 의 토큰 기준값을 어디서 읽는지 plan 이 적지 않았다고 적었다. adversarial 은 Task 5 의 비용(대상 둘에 렌즈 넷, 약 98만 토큰)을 채택 관문이라 과하지 않다고 판단했다. grounding 은 결정 기록의 "agent() 호출 여덟 곳"이 다른 브랜치 기준이고 이 워크트리에는 일곱 곳이라고 적었다.
