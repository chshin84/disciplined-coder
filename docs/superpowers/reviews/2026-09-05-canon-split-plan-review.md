# 정본 분리 구현 계획 리뷰 — 1회차

검토 대상은 `docs/superpowers/plans/2026-09-05-canon-split.md`이고 짝 문서는 `docs/superpowers/specs/2026-09-05-canon-split-design.md`다. 렌즈 원본은 같은 이름의 폴더에 `lens-grounding-1.json`·`lens-consistency-1.json`·`lens-adversarial-1.json`으로 있다. 렌즈를 한 번씩만 돌렸다. grounding과 consistency는 한 호출이 문서를 한 번 읽고 차례로 적용했고, adversarial은 따로 띄웠다.

앞선 시도 한 번은 세션 한도(HTTP 429)로 두 호출 모두 중단됐고, 모델을 바꾼 뒤 같은 프롬프트로 다시 돌렸다. 중단된 호출의 산출물은 없다.

선행연구 렌즈는 제안하지 않았다. 경로가 `plans/`라 plan이고, plan에는 제안하지 않는다는 규칙이 있다.

## 합친 목록

같은 곳을 둘 이상의 렌즈가 잡은 것은 한 항목으로 합쳤다. 근거 확인은 상대편 문장을 파일에서 열어 했고, 실행되는 검사 둘은 직접 돌려 봤다.

| 번호 | 렌즈 | 짚은 곳 | 지적 | 근거 확인 |
|---|---|---|---|---|
| 1 | adversarial·grounding | Task 1 Step 1의 절 승격 검사와 Step 2의 Expected | `grep -qF '## Think Before Acting'`이 지금 정본의 `### Think Before Acting`을 부분 문자열로 이미 맞혀, 빨간지 확인하는 걸음이 성립하지 않고 절 승격을 빠뜨려도 안 잡힌다 | 직접 돌려 지금도 맞는 것을 확인했다 |
| 2 | grounding | Task 1 Step 3의 마지막 `rep()` | 파이썬 큰따옴표 문자열 안에서 백슬래시 둘과 따옴표가 문자열을 조기에 닫아 스크립트가 문법 오류로 한 줄도 안 돈다 | 계획 본문의 그 줄을 확인했다 |
| 3 | grounding | Task 1 Step 2의 Expected | 새 검사 `canon: subagent fleet rule stays`가 그 시점에 반드시 빨간데 목록에 없다 | 정본에 그 영어 문장이 없고 다른 문장이 있는 것을 확인했다 |
| 4 | grounding | Task 4 Step 2의 Expected | 기존 「스킬 등재」 가드가 `domain-writing`을 아무도 안 부른다고 잡는데, Expected는 그 스크립트가 초록이라고 적는다 | 그 가드가 스킬 이름을 정본이나 다른 스킬에서 찾는 것을 확인했다 |
| 5 | adversarial·consistency | Task 5 Step 1의 README 검사와 Step 5의 Expected | Task 5가 테스트 스위트를 빨간 채로 끝내도록 설계되어 있고, 실행자가 그 태스크 안에서 초록으로 만들 길이 없다 | `test_hooks.sh`가 마지막에 FAIL=0을 종료 코드로 내는 것을 확인했다 |
| 6 | adversarial | Task 5 Step 3의 표시 파일 분기 | 표시 파일의 수명이 맥락의 수명이 아니라, 재개한 세션에서 스킬이 안 실렸는데도 넛지가 조용히 빠진다. 지우는 걸음도 없다 | `hooks.json`이 SessionStart를 `startup|resume|clear`에 거는 것을 확인했다 |
| 7 | adversarial | Task 4·6의 `rw()` 함수 | 파일마다 곧바로 쓰므로 중간에 멈추면 절반만 고쳐지고 다시 돌릴 수도 없다 | 계획의 그 함수와 정본의 멱등성 조항을 대조했다 |
| 8 | adversarial | Task 4 Step 4 | 새 스킬 둘이 커밋 전까지 미추적이라 금지 표현 검사가 훑지 않은 채 "ALL PASS"가 난다 | `test_docs_drift.sh`가 `git ls-files`로 대상을 뽑는 것을 확인했다 |
| 9 | consistency | Task 6 Step 3의 README 치환 | 「넛지 넷」이라는 이름을 단 항목이 셋만 열거하고 넷째는 다음 항목에 따로 있다 | 계획의 치환 문자열에서 확인했다 |
| 10 | consistency | Task 1 Step 1의 canon-sections 치환 | spec은 여섯 절로 맞추라는데 목록에 다섯만 적어 「이 파일의 취급」에 존재 검사가 없다 | 계획의 Interfaces와 치환 문자열이 어긋나는 것을 확인했다 |
| 11 | consistency | Task 2 Interfaces의 Produces | Task 4가 부르는 `domain-coding`의 Simplicity First가 Produces 목록에 없다 | 두 태스크의 문장을 대조했다 |
| 12 | consistency | Task 5 Interfaces의 Produces | Task 6이 소비한다고 적은 훅 이름 「코드 넛지」를 Task 5가 만들지 않는다 | 두 태스크의 Interfaces를 대조했다 |
| 13 | adversarial | 두 스킬의 Reach 절과 nested-orchestration의 새 문장 | 같은 지시를 세 문서가 각자 적는데 드리프트 검사가 셋 다 못 잡는다 | 그 검사의 앵커가 한국어 한 문장인 것을 확인했다 |

거른 것은 없다. 열셋 모두 상대편 문장이 실제로 있었고 결과가 계획에서 따라 나왔다.

## 상충과 공백

렌즈끼리 반대로 말한 곳은 없다. 1번과 5번은 두 렌즈가 같은 방향으로 짚었다.

6번의 판정에는 재개한 세션이 같은 `session_id`를 다시 받는지가 필요한데, 훅 문서는 그것을 정하지 않고 이 PC의 전사 파일 34개 측정으로도 갈리지 않았다. 모든 전사가 파일 이름과 같은 아이디 하나만 담아, 재개가 같은 아이디로 이어 붙는지 새 파일을 여는지 구별되지 않는다. 그래서 두 갈래 어느 쪽이든 맞는 처방을 골랐다. SessionStart에서 그 세션의 표시 파일을 지우면, 아이디가 새로 나는 경우에는 없는 파일을 지우는 무해한 동작이고 아이디가 재사용되는 경우에는 넛지가 제대로 다시 걸린다. 지우는 걸음이 없다는 지적도 함께 풀린다.

grounding이 확인하지 못한 것 하나는 카파시 원문과의 대조다. 그 플러그인 캐시가 워크트리 밖에 있어 렌즈가 열지 못했다. 메인 세션이 spec 리뷰 회차에서 이미 대조했고, Simplicity First와 Surgical Changes가 글자까지 같고 Goal-Driven Execution만 한 문장 늘었다는 것이 그때의 결과다.

consistency가 발견으로 올리지 않고 적어 둔 것 하나는 개수 표현이다. spec의 「테스트」는 코드 넛지 여덟 경우를 적는데 계획은 검사 열셋을 넣는다. 늘어난 다섯이 spec의 다른 문장에서 도출되므로 어긋남이 아니다.
