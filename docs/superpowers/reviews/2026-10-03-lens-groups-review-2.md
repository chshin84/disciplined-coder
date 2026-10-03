# plan 리뷰 — 렌즈 그룹 재분류 구현 계획 (2026-10-03)

대상은 `docs/superpowers/plans/2026-10-03-lens-groups.md`(커밋 `894070a`)이고, 경로가 `docs/superpowers/plans` 아래라 plan으로 판정했다. 렌즈는 `lens-grounding`, `lens-consistency`, `lens-adversarial`, `lens-fit`을 하나씩 따로 실행했고, `lens-consistency`에는 spec을 짝 문서로 주었다. 쓰기 도구가 없는 에이전트 종류로 실행했다. 렌즈별 원본은 같은 이름의 폴더에 있다.

렌즈를 한 번씩만 실행했다.

## 선행연구 렌즈

제안하지 않았다. 대상이 plan이다.

## 합친 목록

근거로 든 파일과 줄을 열어 확인했다. 소유 선언 검사 두 가지는 `scripts/test_docs_drift.sh` 355-407행의 로직을 읽어 확인했다. 거른 지적은 없다.

| 지적 | 렌즈 |
|---|---|
| 「렌즈 그룹」 새 문안이 소유를 선언하지 않은 「실행할 때 지킬 상한」과 「목적 주입」을 '소유한다'로 가리켜 소유 선언 검사가 실패한다 | grounding, consistency, adversarial |
| `review-docs`와 `audit-repo-docs`의 readability 불릿이 「렌즈 그룹」을 부르면서 같은 줄에 `dispatching-lenses`를 적지 않아 포인터 검사가 실패한다 | grounding, consistency, adversarial |
| Task 1이 「예외 목록」을 없애는데 `audit-repo-docs` 118행 포인터는 Task 4에서 고쳐 그 사이 검사가 실패한다 | grounding, consistency |
| Task 4가 test_docs_drift.sh를 실행하지 않아 실패가 Task 6까지 드러나지 않는다 | adversarial |
| 「에이전트원칙 직접 읽기」 불릿이 「감사 대상 고르기」에 있다는 근거가 틀려 규칙이 사라진다 | grounding, consistency, adversarial |
| `lens-prior-art` 63행이 사용처를 spec 리뷰와 직접 요청으로 한정한 채 남는다 | grounding, consistency |
| 공통 규칙의 '기록 전에 승인 여부를 정한다'와 `review-specs`의 결과 전달 때 제안이 맞지 않는다 | grounding |
| 상한 산식(묶음 9개와 적대적 1개)에 readability 몫이 없고 실행 단계도 없다 | grounding, consistency, adversarial |
| `audit-repo-docs` 69행 '한 문서에 렌즈가 둘 이상이면 한 번에 실행한다'가 readability 분리와 부딪친다 | consistency |
| run.json에 '렌즈 배정 칸'이 없다 | grounding, consistency, adversarial |
| 배정 변경 차수 불릿은 한 번뿐인 전환 사실을 절차 문서와 검사에 고정한다 | adversarial |
| 앞 Task가 줄 수를 바꿔 뒤 Task의 줄 번호가 틀린다 | grounding, adversarial |
| `audit-repo-docs`의 '문서 종류에 따라 렌즈를 배정해'가 두 번 나와 Edit가 거부한다 | adversarial |
| 끊겼을 때 재개 규칙이 없고 넣기 단계가 멱등이 아니다 | adversarial |
| 전체 입력 표와 '실행하는 호출자' 칸이 호출자 소유 사실을 다시 적고, 직접 요청 시 감사의 선행연구 실행과 맞지 않는다 | adversarial |
| 옛 포인터 검사 설명이 「」 이름만 찾는다고 하지만 패턴에 「」 없는 문구가 있다 | consistency |
| 연결어미 뒤 쉼표, 다섯 문장 단락, 여러 문장 불릿, 문장 중간 관형절, 대구 두 번, 용어 불일치, 풀이 없는 이름, '갖출 것', 개수 예고 | fit |

## 커버리지 공백

렌즈 넷이 모두 결과를 돌려주었고 `principles_applied`가 빈 렌즈는 없다. 렌즈가 확인하지 못했다고 적은 것은 둘이다. 검사 스크립트를 실제로 실행한 결과와, main의 `domain-korean.md` 변경이 병합 뒤 첫 문장·대구 검사에 미치는 영향이다.
