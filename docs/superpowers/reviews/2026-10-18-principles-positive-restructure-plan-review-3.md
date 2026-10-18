# 에이전트원칙 개편 plan 3차 리뷰 — 2026-10-18

대상은 `docs/superpowers/plans/2026-10-18-principles-positive-restructure.md` 의 시험 방법 개정 부분(머리, 「용어」, 「Global Constraints」, 「Review Focus」, Task 4~10)이다. 사용자가 바뀐 부분만 다시 리뷰하기로 정했으므로 consistency 렌즈와 adversarial 렌즈만 실행했다. 렌즈를 한 번씩만 실행했다. plan 이므로 선행연구 렌즈는 제안하지 않았다. 렌즈별 원본은 같은 이름의 폴더에 있다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| 실행 키가 `prompt.md` 전체(front matter 포함)와 `criteria.md` 의 해시라, 태그나 판정 기준만 바꿔도 같은 질문을 다시 생성한다 | consistency, adversarial |
| smoke 가 실제 과제를 실행하고 기록을 버려 Task 6 이 같은 질문을 다시 실행한다 | consistency, adversarial |
| 판정만 실패한 작업을 기록하지 않으면 성공한 생성까지 반복하고, 판정 읽기 실패를 위반 아님으로 기록하면 굳는다. `run_case` 가 판정 실패를 알리는 필드가 없다 | consistency, adversarial |
| JSON 으로 온 API 오류를 오류로 보지 않으면 오류 문구가 응답으로 기록된다 | adversarial |
| 작업 폴더가 사용자 홈 아래면 상위 경로의 `.claude/CLAUDE.md` 가 실릴 수 있다 | adversarial |
| 기록 시점·동시 쓰기·손상 줄·동시 프로세스 잠금이 없다 | adversarial |
| 판정 세션이 설정 폴더 하나를 함께 쓰고, 동시 실행 수 8 은 근거가 없다 | adversarial |
| 생성 모델을 고정하지 않았다 | adversarial |
| 보고가 둘째 차례 규칙과 새 조항의 동률을 표현하지 못하고, Step 5 확인 목록에 동률이 없다 | consistency, adversarial |
| 오류 재실행에 멈출 조건이 없다 | adversarial |
| 나눈 신설 조항의 분류와 `current.md` 내용이 정해지지 않았다 | consistency |
| 질문 작성 서브에이전트가 `new.md` 로 질문을 만들면 변경안에 맞춰지고, 층마다 기준이 갈린다 | adversarial |
| Task 8 이 겹치는 문장을 합치며 시험한 원칙 문장을 고친다 | adversarial |
| Task 8 의 되돌리기 범위가 없고, 시험이 전환 뒤에 있다 | consistency, adversarial |
| Task 7 의 검사 수정 범위에 한계가 없다 | adversarial |
| 전체 비교 경로는 끊기면 모든 과제를 다시 실행한다 | adversarial |
| Task 9 의 grep 확인이 git 무시 폴더와 `scripts/scaffold.sh` 주석을 잡는다 | consistency |
| 사용자 판정 확인이 Task 8·10 에 없다 | consistency |
| 전체 비교에 적재 분량 기록이 없다 | consistency |
| `pair` 선택 필드의 픽스처가 없다 | consistency |
| `new.md` 첫 줄이 묶음 조건인지 층 조건인지 섞인다 | consistency |
| 보고의 금지어 수를 대화 답에서만 세는지 정하지 않았다 | consistency |

## 커버리지 공백

바뀐 부분만 대상으로 삼았으므로 grounding·fit 렌즈를 실행하지 않았다. 하네스가 adversarial 렌즈 보고에 설정 파일 형태의 패턴 표시를 붙였으나, 보고 안에 설정 변경 지시는 없었다.

## 메인 세션의 측정

상위 경로 적재 지적은 렌즈가 측정하지 않은 가정이었으므로 메인 세션이 같은 날 측정했다. 빈 설정 폴더와 사용자 홈 아래 임시 폴더(`/tmp`)에서 실행한 세션은 실린 지시에 `~/.claude/CLAUDE.md` 의 관리블록이 있다고 답했다. D: 드라이브 아래 폴더에서 실행한 세션은 없다고 답했다.
