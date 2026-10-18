# 에이전트원칙 개편 plan 2차 리뷰 — 2026-10-18

대상은 `docs/superpowers/plans/2026-10-18-principles-positive-restructure.md` 다. 1차 리뷰(`2026-10-18-principles-positive-restructure-plan-review.md`)를 반영한 뒤 사용자가 바뀐 Task 만 다시 리뷰하기로 정했다. 그래서 메인 세션은 「용어」, 「Global Constraints」, Task 1·3·4, 「측정 절차」, Task 8 을 대상으로 consistency 렌즈와 adversarial 렌즈만 한 번씩 실행했다. plan 이므로 선행연구 렌즈는 제안하지 않았다. 렌즈별 원본은 같은 이름의 폴더에 있다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 해시 대조는 훅이 쓴 뒤의 파일만 보므로, import 줄이 이미 있는 설정 폴더에서는 첫 세션이 직전 조건의 사본을 싣는다. 조건마다 새 설정 폴더가 필요하다 | adversarial |
| 실제 설정 홈을 쓰는 경로에서는 측정 중 사용자의 다른 창이 사본을 덮어써 조건이 바뀌어도 탐지되지 않는다 | adversarial |
| plugin-eval 경로에 자동 갱신 끄기가 없어 갱신 훅이 실제 설정을 바꾸고 응답에 알림을 넣는다 | adversarial |
| 자동 복원은 다른 창의 정상 변경을 확인 없이 덮어쓴다. 탐지하면 멈추고 묻는 편이 짧고 안전하다 | adversarial |
| trap 정리가 설정 대조, worktree 등록 해제, 강제 종료를 놓친다 | adversarial |
| 옛 사본을 '원본과 같을 때만' 지우는 조건은 업그레이드 경로에서 참이 되지 않는다 | consistency, adversarial |
| 옛 사본을 지울 때 다른 플러그인 블록이 그 파일을 import 하는지 보지 않는다 | adversarial |
| 표 밖 지시를 그대로 옮기면 금지어 글자가 지시형 트랙에 들어가고, 옮길 범위가 정해지지 않았다 | adversarial |
| `banned_guide` 의 문형과 시험 문자열이 다르고, 문장형 대체어는 문형에 넣으면 비문이 된다 | consistency, adversarial |
| 지시형 트랙 생성이 실패할 때의 처리와 원자적 쓰기가 없다 | adversarial |
| 단계 Task 가 여러 커밋이 되면 '단계 커밋만 revert'가 일부만 되돌린다 | adversarial |
| probe 과제를 커밋하는지가 Task 1 안에서 다르다 | consistency |
| eval 폴더 경로가 Task 1 의 Produces 에 없다 | consistency |
| claude-p 경로에서 판정을 누가 어떤 모델로 하는지 없다 | consistency |
| `result.json` 의 형식이 정해지지 않았다 | consistency |
| baseline 행의 위반 합계와 금지어 횟수를 내는 명령이 없다 | consistency |
| Task 8 의 기준 원칙 대비 확인이 Global Constraints 의 '직전 상태 대비로 판정'과 부딪친다 | consistency |
| `eval_compare.sh` 가 `kind` 행과 `conflict:*` 합산 행을 내지 않는다 | consistency |
| 조건 혼선 검사가 `agent-principles.md` 만 보므로 단계 4 조건을 구분하지 못한다 | consistency |
| 분량 기록이 원칙 파일만 보고 세션에 실리는 전체 분량을 보지 않는다 | consistency |
| `korean-banned-words.md` 머리의 사본 설명과 칸 설명을 고칠 대상에 넣지 않았다 | consistency |
| `test_scaffold.sh` 의 기존 검사(목록 파일이 놓이고 첫 세션에 실린다)가 새 동작과 반대다. 픽스처 시험에 `악화` 판정이 없다 | consistency(notes) |

## 커버리지 공백

이번 차수는 바뀐 Task 만 대상으로 삼았으므로 grounding·fit 렌즈를 실행하지 않았다.
