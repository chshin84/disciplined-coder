# 2026-10-18 plan 리뷰 — 선행연구 에이전트

대상은 `docs/superpowers/plans/2026-10-18-prior-art-agent.md`다. 경로가 `docs/superpowers/plans` 아래라 plan 으로 판정했다. 짝 spec 은 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`(3차 리뷰 반영판)이며 `lens-consistency`와 `lens-adversarial`에 함께 넣었다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다.

## 선행연구 에이전트의 제안

제안하지 않았다. 대상이 plan 이라 `review-specs`가 제안을 두지 않는다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| Task 4 완료 검사의 예외가 좁아, plan 이 만드는 넛지 훅 주제어·시험 문자열·검사 문자열·스킬 본문 때문에 검사가 항상 FAIL 한다 | adversarial, consistency, grounding |
| plan 의 완료 검사 예외가 spec 의 완료 조건 예외와 다르고, 그 차이를 spec 에 밝히지 않았다 | grounding, consistency(notes) |
| domain-discipline 의 삭제 표시를 '문장 옆'에 적으면 줄 단위 예외 필터와 줄이 다를 수 있다 | consistency |
| 「가드」를 글자 그대로 옮기면 `lens-derived`가 남아 `kind` 열거 `derived`와 충돌한다 | consistency, grounding |
| `json_valid` 함수가 없다. 실제 이름은 `json_valid_stdin`이다 | adversarial, consistency, grounding |
| 훅이 `json_str`을 쓰려면 stdin 을 `INPUT`에 담는 단계가 필요하고, `json_str`은 첫 따옴표에서 끊겨 따옴표가 든 메시지를 놓친다 | adversarial, grounding |
| `agentType`·`phase` 옵션을 실측 없이 단정했고, 플러그인 에이전트 해석을 확인하는 단계가 없다 | consistency, grounding, adversarial(notes) |
| sub-session-protocol 60행에는 바꿀 구절이 없고, 114행 `렌즈 그룹 판정` 행이 빠졌다 | consistency, grounding |
| review-specs 의 '통상과 최대한 중 고르기'를 프로토콜 승인으로 바꾸는 처리가 없다 | consistency |
| `VERIFIER_SCHEMA`의 `ref` 형식이 정해지지 않아 하위 질문 ID 로 되돌리는 규칙이 없다 | consistency |
| 탐색 모드 `cases`와 spec 의 `evidence_map` 칸 구성이 다르다 | consistency |
| `classify`가 판정이 없는 항목(검증자 null)의 행선지를 정하지 않는다 | consistency |
| 시험 도구 출력 형식이 정해지지 않아 `grep -c` 단언과 한 줄 출력 전제 단언이 서로 다르다 | adversarial |
| 부정 단언 `! run … | grep -q`가 실행 오류도 PASS 로 센다 | adversarial |
| 시험 도구가 export 를 모두 떼고, `--fn`이 감싼 본문 안 함수를 꺼내는 방법이 없다 | adversarial |
| 레퍼런스 프롬프트 추출이 비면 `grep -qF ""`가 항상 PASS 한다 | adversarial |
| Task 2·3 커밋 시점에 「스킬 등재」 검사가 FAIL 하는데 묶음만 보아 놓친다 | adversarial, consistency(notes) |
| 묶음 FAIL 수를 `-A40`·`-A20` 창 크기로 세어 개수를 박았다 | fit |
| 작업 브랜치를 만드는 단계가 없어 커밋이 main 에 들어간다 | adversarial |
| spec 과 plan 을 커밋하는 단계가 없다 | adversarial |
| 기준선 판정과 Haiku 재판정을 실행하는 방법이 없고, Haiku 조건이 연구자 출력을 재사용한다는 점과 기준선 에이전트 종류가 빠졌다 | adversarial, consistency |
| `--plugin-dir` 새 세션에 메시지를 입력하는 주체가 없다 | adversarial |
| 토큰 사용량을 모든 실행 뒤에야 확인한다 | adversarial |
| 발동 시험이 실패하면 목록을 고치는 경로가 없다 | consistency |
| Task 5 Step 6 에 보고·승인·커밋이, Task 3 Step 5 에 두 Run 이 섞였다 | fit |
| 기록 파일 경로에 날짜 자리표시자가 있다 | fit |
| 기호식 조건(≥, ≤, →, ∈), 목록 말끝 불일치, 표 열 말끝 불일치, 개수 예고, '시험'·'계약 테스트' 혼용, 판단 주체 생략 | fit |

## 커버리지 공백

렌즈 네 개가 모두 실행되었다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다.
