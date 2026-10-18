# 에이전트원칙 개편 plan 리뷰 — 2026-10-18

대상은 `docs/superpowers/plans/2026-10-18-principles-positive-restructure.md` 다. 경로가 `docs/superpowers/plans` 아래이므로 메인 세션은 이 문서를 plan 으로 판정했고, 그래서 선행연구 렌즈는 제안하지 않았다. 렌즈 네 개를 한 번씩만 실행했다. 렌즈별 원본은 같은 이름의 폴더에 있다.

## 합친 지적 목록

| 지적 | 잡은 렌즈 |
|---|---|
| `claude -p` 대체 경로의 `marketplace add`·`install` 에 임시 설정 폴더가 붙지 않아 실제 `~/.claude` 에 설치된다. 설정 홈 해석이 `CLAUDE_HOME_DIR` 을 먼저 본다는 점도 없다 | grounding, fit, adversarial |
| 실제 설정 오염을 해시로 탐지만 하고 사본 보관과 복원이 없다. 해시 대상에서 `settings.json`·`known_marketplaces.json`·`installed_plugins.json` 이 빠졌다 | adversarial |
| 보류용 비율 25~35%, 출력 종류 비율 ±10%p, 일치도 70% 는 근거가 없다. 과제 구성 기준을 상시 검사로 남기는 것은 과설계다 | grounding, fit, consistency, adversarial |
| 표지 문자열을 사본에 넣으면 scaffold 가 덮어쓰고, 응답 첫 줄 표지는 첫 문장 답 과제의 판정을 바꾼다. 조건 혼선은 사본 해시를 커밋의 원칙과 대조해 확인할 수 있다 | consistency, adversarial |
| 기준 커밋 `7a2d26d` 에는 `evals/principles/` 가 없어 과제 폴더의 출처가 정해지지 않았다. probe 과제가 커밋 전이라 worktree 에 없고, 이미 체크아웃된 브랜치는 다른 worktree 에 체크아웃할 수 없다 | grounding, adversarial, consistency(notes) |
| 플러그인 자동 갱신 끄기, 전역 CLAUDE.md 와 메모리를 조건마다 같게 넣기, 고정 대화를 넣는 방법이 plan 에 없다 | grounding, consistency, adversarial |
| 과제 머리에 실패 유형·충돌 쌍·후보 공백·짝 식별 필드가 없어 비교 스크립트가 유형별 위반을 낼 수 없다. '사례 묶음'이 정의되지 않았다 | consistency |
| `--tag` 가 prompt.md 머리를 읽는지 확인하지 않았다 | grounding |
| 단계 4 의 금지어 측정이 spec 과 다르다. `banned_scan` 은 횟수를 세지 않고, 비교 상대와 대상 범위가 바뀌었으며 출력 인터페이스가 없다 | grounding, consistency |
| 옛 사본 `korean-banned-words.md` 의 처리와 '잔존 알림이 나오지 않는다'는 기대가 부딪치고, 삭제라면 확인 단계가 없다 | grounding, fit |
| 생성기의 '여섯째 칸'이 awk 필드 번호와 표 칸 번호 사이에서 갈리고, '같은 파일'이 어느 파일인지 없다 | grounding |
| Task 10 의 확인 grep 이 plan·spec 자신에 걸리고, README 56·81행의 옛 절 이름을 고치는 Task 가 없다 | grounding |
| `LENS-ALLOWED` 의 단계 1 위치가 spec 표와 plan 본문에서 다르다 | grounding |
| 단계 3 이 원칙에 이유를 붙이는데, 그것을 허용하는 CLAUDE.md 개정은 Task 10 에 있다 | consistency |
| Task 7·8·9 가 기준 원칙과 비교하지 않고, 사용자 확인 표본·측정 기록·줄 수와 글자 수가 일부 단계에만 있다 | consistency |
| 측정 기록을 단계 커밋과 따로 커밋하는 순서가 없어 되돌릴 때 실패 기록이 사라진다 | adversarial |
| 극성 짝 비교의 측정 방법과 판정 기준이 없다 | fit, consistency, adversarial |
| Task 6 의 '위반이 줄고'가 어느 비교 상대 기준인지 없다 | fit |
| Task 6 Files 에 새 ID 를 올릴 `docs/domain-discipline.md` 가 없다 | consistency |
| 불변 조건의 훅 강제 검토와 EARS 형식 확인 기준이 없다 | consistency |
| 측정 규모(조건 약 11개 × 세션 약 84개)를 추정하고 묻는 단계와 중단 시 정리가 없다 | adversarial |
| 과제를 커밋하기 전에 사람이 확인하는 단계가 없고, 이름·회사명·수치는 정규식으로 잡히지 않는다 | fit, adversarial |
| 원자료 폴더를 언제 지울지 없다 | adversarial |
| Task 4 의 측정 완료 확인과 Task 10 Step 1 의 확인 방법이 없다 | fit |
| CLI 버전과 판정 모델 기본값을 출처 없이 사실로 적었다 | fit |
| `evals/principles/README.md` 가 Task 1 과 Task 4 양쪽에서 Create 다 | consistency |
| spec 의 '일곱 열 표'와 plan 의 '여섯 칸'이 다르다(spec 은 이미 '여섯째 칸'으로 고쳤으나 test_hooks 문장에 '일곱 열'이 남았다) | consistency |
| 문체: 개수 예고, 여러 문장짜리 불릿, 문서를 주체로 쓴 문장, 중간 관형절, 겹친 수식어, 풀지 않은 이름('지시형 트랙', '극성 짝'), '판정 모델'과 '판정자' 혼용, 목록 말끝 불일치 | fit |

## 커버리지 공백

`aggregating-lenses` 기준으로 아무도 보지 않은 관점은 없었다. 판정 잡음(위반 합계 차이 1 로 채택이 갈림)은 adversarial 렌즈가 notes 에 적었으나, spec 의 사용자 결정이라 plan 의 줄로 지목하지 않았다.
