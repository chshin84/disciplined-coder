# 2026-10-18 plan 리뷰 — 선행연구 에이전트 탐색 워크플로

대상은 `docs/superpowers/plans/2026-10-18-prior-art-agent-workflow.md`다. 경로가 `docs/superpowers/plans` 아래라 plan 으로 판정했다. 짝 spec 은 하부 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-specworkflow-design.md`다. 렌즈를 한 번씩만 실행했다. 렌즈마다 general-purpose 서브에이전트 하나를 썼고, 읽기 전용은 프롬프트로만 지시했다. 고친 파일을 보고한 렌즈는 없다. 원본 JSON 은 같은 이름 폴더에 있고, 길이 때문에 칸 일부를 요약해 저장했다.

## 선행연구 에이전트의 제안

제안하지 않았다. 대상이 plan 이라 `review-specs`가 제안을 두지 않고, 이 리뷰를 실행한 세션은 사용자에게 묻지 못하는 서브 세션이다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| `rejected` 원소에 계약 밖 `reason` 키를 붙인다 | consistency, grounding, adversarial |
| `set -e` 아래에서 `awk`·시험 도구를 단언 밖에서 실행하면 스크립트가 요약 줄 없이 끝나고, 실패 확인 단계의 기대 결과가 성립하지 않는다 | consistency, grounding, adversarial, fit(notes) |
| 빈 `meta` 구간에서 부재 단언이 항진 PASS 가 된다 | adversarial |
| `json_same`이 파이썬 `==`이면 `true`와 `1`을 같다고 본다 | adversarial |
| 가짜 `agent`의 스키마 검사가 `properties` 없이 `required`만 있는 노드를 보지 않는다 | consistency, adversarial |
| `classify`의 판정 사전이 `ref`당 하나면 다중 URL 판정이 덮어쓰인다 | adversarial, grounding(notes) |
| `classify`가 '보낸 참조'에서 선행 서술 결측 항목을 빼라는 지시가 없다 | adversarial |
| `url` 키가 없거나 `null`인 인용의 처리와 시험 입력이 없다 | consistency, adversarial |
| `evidence_map`이 없는 연구자 출력을 시험 입력이 고정하지 않는다 | consistency |
| `meta.description`을 어느 태스크도 만들거나 확인하지 않는다 | consistency |
| 하위 질문이 빈 프로토콜에서 `overall_status`가 공허하게 `ok`다 | adversarial |
| 응답표 누락 단언이 종료 코드만 보아 다른 예외와 구별하지 못한다 | adversarial |
| `lacksPrior`가 하부 명세의 판정 함수 목록 밖이고, Task 1 골격에 선언이 없다 | consistency, fit, grounding(notes) |
| 경로 형태 정규식의 확장자 둘째 글자 이후를 영숫자로 좁혔다 | grounding |
| `forbidden-term`이 먼저라는 원소 차례와 종료 코드 2 의 범위가 내부 규칙 목록에 없다 | grounding, consistency(notes) |
| Task 3 Step 4 의 명령이 `SKIP: agents`를 출력하지 않고, validate 의 변경 전 경고 기준이 없다 | fit, grounding |
| 실패 확인 단계가 「묶음 FAIL 수 세기」 명령을 가리키지 않는다 | consistency |
| Interfaces 가 `$FX`와 응답표 키 규칙을 주지 않는다 | fit |
| '계약 테스트'가 두 스크립트를 함께 가리킨다 | fit |
| 제목이 없는 단계에서 `phase()`를 무엇으로 부를지 정하지 않았다 | grounding(notes) |
| 개수 예고와 개수 참조, 주체 생략, 긴 불릿, 말끝 혼재, 한 문장 여러 개념 | fit |

## 커버리지 공백

렌즈 네 개가 모두 실행되었다. `lens-fit`의 `doc_type`은 '설계' 행으로 채워졌다. 하부 명세와 계약 코드의 내용 대조는 `lens-fit` 범위 밖이라 그 렌즈는 열지 않았고, 다른 렌즈 셋이 열었다.
