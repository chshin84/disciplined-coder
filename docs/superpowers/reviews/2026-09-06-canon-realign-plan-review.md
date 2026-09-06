# 2026-09-06 canon-realign 계획 리뷰

검토 대상은 `docs/superpowers/plans/2026-09-06-canon-realign.md` 하나다. 렌즈 셋을 각각 한 번씩만 돌렸다. 호출은 둘이고, `lens-grounding`과 `lens-consistency`를 한 호출이 차례로 적용했으며 자세가 반대인 `lens-adversarial`을 따로 띄웠다.

선행연구 렌즈는 붙이지 않았다. 검토 대상 경로가 `docs/superpowers/plans` 아래이므로 plan으로 갈랐고, `review-specs`가 plan에는 제안하지 않는다고 정한다.

읽기 전용은 절반만 구조로 막았다. 띄운 에이전트 종류에 `Edit`과 `Write`가 없으나 `Bash`는 있어, 나머지는 프롬프트 지시로 막았다. 세 렌즈 모두 파일을 고치지 않았다.

## 둘 이상이 함께 잡은 것

| 발견 | 잡은 렌즈 |
|---|---|
| 카파시 대체 본문이 44줄이 아니라 43줄이다 | `lens-grounding`, `lens-adversarial` |
| `test_docs_drift.sh:200` 주석이 옛 소유자를 적은 채 남는다 | `lens-grounding`, `lens-adversarial` |
| Goal-Driven Execution의 코드 울타리 삭제가 설계의 삭제 목록에 없다 | `lens-grounding`, `lens-adversarial` |
| 넛지 시험의 파일 실재 단언이 훅 출력을 안 보는 항진 단언이다 | `lens-consistency`, `lens-adversarial` |
| Task 3 Step 7의 사람 확인에 산출물 자리가 없다 | `lens-consistency`, `lens-adversarial` |
| 시험 전량 실행 명령의 소유자를 안 가리키고 스크래치패드 파일에 묶었다 | `lens-grounding`, `lens-adversarial` |
| 84행에서 한정 문장을 지우면 149행과 처분이 갈리고 READ-FLOW를 어긴다 | `lens-consistency`, `lens-adversarial` |

## 합친 지적 목록

### 계획이 가리킨 줄이 실제와 다른 것

넛지 훅의 머리주석을 "1~9행"이라 적었으나 1행은 셰뱅이고 머리주석은 2~12행이다. 적힌 대로 하면 셰뱅이 지워지고, 대체 블록이 이미 담은 「세션 키」 문단이 파일에 두 벌 남는다.

카파시 대체 본문을 44줄이라 적었으나 코드 울타리 안은 43줄이다. 세는 스크립트는 다음 `## ` 줄 직전까지를 세므로 절 뒤 빈 줄 하나가 있어야 44가 된다. 지금 절도 19~81행 63줄이고 81행이 빈 줄이다.

Task 1의 Files 목록은 `test_hooks.sh` 155행 뒤에 단언 둘을 더한다고 적고 Step 3은 156행 뒤에 셋을 더한다고 적는다. 실측으로 156행이 `session_id 없음 → 매번 안내` 줄이고 더하는 단언은 셋이다.

`run_all_tests.sh`라는 파일은 이 저장소에 없다. 시험 전량 실행 명령의 소유자는 `CLAUDE.md:13`이고 `ALL PASS` 문구의 출처도 거기이며 `scripts/test_docs_drift.sh:452`가 그 줄의 실재를 검사한다. 계획은 그것을 안 가리키고 이 세션의 스크래치패드 파일에 묶었는데, 스크래치패드는 세션마다 새 UUID로 갈리므로 다른 세션에서 실행하면 세 태스크의 마지막 확인이 모두 못 돈다.

### 계획이 만든 고아를 계획이 안 치우는 것

`scripts/test_scaffold.sh`의 402~405행 주석이 지워질 갈래 이름과 지워질 호명 방식을 둘 다 가드 바로 위에서 설명한다. 계획은 409행만 적는다.

`scripts/test_docs_drift.sh:200` 주석이 소유자를 정본이라 적는데 201·202행은 `review-docs`를 보게 바뀐다. Task 2 Step 7의 확인 대상 넷에 그 파일이 없어 이 주석은 잡히지 않는다.

메모리 `karpathy-upstream-watch`에 낡은 진술이 셋인데 계획은 한 문자열만 지목한다. 그 파일 8행이 정본의 절 이름을 「Think Before Acting」이라 적는데 실제 절 이름은 「Karpathy guidelines」이고 하위 절이 넷이다.

### 가드가 값을 못 하는 것

Task 1 Step 3이 더하는 단언 `[ -f '$NH/disciplined-coder/agent-principles.md' ]`는 두 줄 위 픽스처가 방금 만든 파일을 보므로 훅이 무엇을 내든 참이다. `scripts/test_assertions.sh`가 스스로 "이 검사를 초록으로 만들려고 형식적인 단언을 붙이지 마라"고 적는다. 훅이 실제로 낸 경로를 뽑아 대조하는 방식은 `test_hooks.sh:183~185`에 이미 있다.

`scripts/count_karpathy.py`가 어느 `test_*.sh`에도 `.github/workflows/ci.yml`에도 안 걸린다. CI와 계획의 러너 둘 다 `scripts/test_*.sh`만 돈다. 카파시 절이 다시 늘어도 잡는 것이 없고, 한 번 쓰고 아무도 안 부르는 파일이 남는다.

정본에서 기록 이름 문단을 뺀 것이 유지되는지를 지키는 상시 단언이 없다. 옮기기 전에는 `test_docs_drift.sh:201`이 정본이 그 규칙을 갖는 것을 매번 붙잡았다. 옮긴 뒤 지켜야 할 사실은 "정본에 그 문단이 없다"인데 그것을 보는 것은 Task 2 Step 7의 일회성 grep뿐이다.

정본에 새로 남기는 한 줄을 요구하는 단언도 없다.

Task 1에 "「대화할 때」를 가리키는 곳이 없다"를 확인하는 걸음도 가드도 없다. Task 2와 Task 3은 같은 종류의 확인을 grep 걸음으로 두는데 Task 1만 없다. 그 이름을 부르는 살아 있는 파일은 셋이고 Step 7이 둘을 손으로 고치라고만 적는다.

Task 3 Step 7은 기계로 못 하는 유일한 걸음인데 결과를 어디에 남기는지가 안 정해져 있다. Step 8·9·10이 Step 7과 무관하게 통과하므로 걸음을 건너뛰어도 커밋이 그대로 난다.

### 훅 변경의 실패 모드

훅이 실제 세션에서 가리키는 경로가 없을 수 있다. `CLAUDE_HOME_DIR`를 안 주는 세션에서 훅은 `<홈>/.claude/disciplined-coder/agent-principles.md`를 가리키는데, 그 파일은 `scaffold.sh`의 복사가 성공한 뒤에만 있고 복사 실패는 scaffold가 `exit 1`로 끝날 뿐 세션을 멈추지 않는다. 존재를 확인하는 곳이 픽스처 안뿐이다.

훅이 `hooks/` 밖에 처음으로 의존하게 되는데 `set -euo pipefail` 아래에서 그 source가 실패하면 넛지가 아무 말 없이 사라진다. 이 훅은 스스로 "조용히 빠지지 않는다"를 계약으로 적었다.

### 카파시 재작성이 설계와 갈리는 것

`The test: every changed line traces directly to the request.`가 지금은 빈 줄을 사이에 두고 Surgical Changes 절 전체의 판정 기준으로 서 있는데, 새 본문에서는 `When your change leaves orphans:` 아래 불릿이 되어 고아를 지울 때만 걸리는 규칙으로 읽힌다.

`For multi-step work, state the plan:`과 그 아래 코드 울타리를 지우고 산문 한 줄로 바꾸는 것은 설계의 삭제 목록 넷에 없는 다섯째 삭제다.

굵은 요약 `**Don't assume. Don't hide confusion. Surface tradeoffs.**`를 지우면서 `Surface tradeoffs`에 해당하는 지시가 새 본문 어디에도 안 남는다. 설계의 실패 유형 스물넷 표에도 그 항목이 없어 아래 문턱이 이 손실을 못 잡는다.

### 정본이 자기 조항을 어기게 되는 것

84행에서 한정 문장 "아래 넷은 한국어로 쓸 때만 걸린다"를 지우면 그 절의 첫 문장이 `domain-korean` 소유 표시가 된다. 99행도 첫 문장이 "여기서 다루지 않는다"는 제외 표시가 된다. 정본의 `READ-FLOW`는 소제목 바로 아래 첫 문장에 그 절의 결론을 적으라고 한다.

같은 꼴의 문장인 149행의 "아래 셋은 코드에만 걸린다"는 남기는데, 두 문장은 제목과의 관계가 같은 꼴이라 처분이 갈리는 근거가 설계의 한 줄뿐이다.

### 되돌림

첫째 커밋이 고치는 정본 82행은 셋째 커밋이 통째로 갈아 쓴 카파시 절 바로 다음 줄이다. 셋째가 남은 채 첫째를 `git revert`하면 손으로 풀어야 한다. 둘째 커밋은 다른 커밋과 줄이 안 겹쳐 단독으로 되돌려도 저장소가 성립한다.

메모리 갱신이 Task 3의 결과를 앞질러 적으면서 첫 커밋에 붙어 있고, git 밖이라 커밋 셋으로 가른 되돌림이 안 닿는다.

### 드리프트

`review-docs`에 새 절을 더하면 그 파일 안에 기록 파일 이름 꼴이 두 벌 남는다. 새 절은 `YYYY-MM-DD-<주제>-<종류>.md`를 소유자로 선언하는데 44행은 `YYYY-MM-DD-<문서이름>-check.md`를 따로 적는다. 절 이름도 「기록」 바로 뒤에 「기록 파일의 이름」이 붙는다.

`test_docs_drift.sh` 201행 교체가 그 파일이 이미 가진 `DOCS` 변수 대신 같은 경로를 손으로 적는다.

## 상충

렌즈끼리 상충한 판정은 없다. 세 렌즈가 카파시 대체 본문의 실패 유형 스물넷을 각자 대조했고 셋 다 스물넷이 모두 담긴다고 판정했다. 손실은 스물넷 밖에서만 났다.

## 커버리지 공백

세 렌즈 모두 시험을 실제로 돌리지 않았다. 읽기 전용이라 지금 스위트가 초록인지, Task 1 Step 4가 기대하는 빨강이 정확히 그 단언들에서만 나는지는 문자열 대조로만 판정했다. `claude plugin validate ./`도 안 돌렸다.

`lens-adversarial`은 메모리 파일을 열지 못했고 업스트림 원문과 대조하지 않았다. `lens-grounding`은 그 메모리를 열어 8행의 낡은 진술을 잡았다.

## 렌즈가 발견으로 못 올린 것 둘

`lens-grounding`이 기존 결함 하나를 `notes`에 적었다. `scripts/test_scaffold.sh:422`의 역따옴표가 이스케이프되지 않아 호출 시점에 `LOCAL-FIRST`가 명령으로 실행되고 빈 문자열로 치환된다. 실제로 검사되는 것은 `는 원칙이 아니라`뿐이다. 호출자가 재현해 확인했고, 매 실행마다 `LOCAL-FIRST: command not found`가 stderr로 나가는데 러너가 stderr를 버려 안 보였다. 계획이 만든 것이 아니다.

`lens-adversarial`이 설계 쪽 오류 하나를 `notes`에 적었다. 설계는 "정본이 SessionStart마다 전역으로 복사되어 실리므로 세션이 끊기면 어긋난 정본이 모든 프로젝트에 실린다"를 커밋 분할의 근거로 삼는데, `scripts/scaffold.sh:7`이 `CLAUDE_PLUGIN_ROOT`를 쓰므로 전역 사본의 출처는 이 워크트리가 아니라 마켓플레이스 사본이다. 호출자가 그 줄을 열어 확인했다. 절반만 끝난 워크트리 편집은 다른 프로젝트로 안 퍼지고, 퍼지는 시점은 기본 브랜치로 병합해 밀었을 때이며 그때는 `autoUpdate`가 참이라 사용자 동작 없이 퍼진다.

렌즈를 한 번씩만 돌렸으므로 두 번째 표집이 잡았을 것은 이 회차에 없다.
