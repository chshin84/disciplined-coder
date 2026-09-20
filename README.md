# disciplined-coder

팀 엔지니어링 원칙을 모든 Claude Code 세션에 자동으로 실어 주는 플러그인이다. 작업 폴더에 원칙 사본은 생기지 않는다.

## 설치

스코프는 user여야 모든 프로젝트에서 hook이 실행된다. Windows는 [Git Bash](https://git-scm.com/downloads)와 [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows)을 먼저 설치한다. hook이 `bash`로 스크립트를 실행하고, 환경 변수를 넣는 단계가 `pwsh`를 부르기 때문이다. 윈도우에 기본으로 있는 5.1(`powershell`)로 물러서지 않는다. 마켓플레이스 자동 갱신에는 파이썬이 필요하다.

```text
/plugin marketplace add chshin84/disciplined-coder
/plugin install disciplined-coder@chshin-tools
```

## 동작 확인과 복구

새 세션을 한 번 열면 셋업이 끝난다. 세션 시작 알림에 `ERROR` 나 `WARNING` 줄이 없으면 정상이다. 정상 회차에도 정본 전문과 자동 갱신 알림과 설치 권유가 stdout 으로 나가므로, '출력이 없으면 정상'이 아니라 '오류 줄이 없으면 정상'이다. 확인은 `/show-principles` 로 하고 원칙 목록이 나오면 된다.

목록이 안 나오면 원인은 셋 가운데 하나다.

- **스코프** — 플러그인 스코프가 user가 아니어서 hook이 안 돌았다. 설치 때 스코프를 따로 준 적이 없으면 이 원인이 아니다(기본값이 user다). 터미널에서 `claude plugin install disciplined-coder@chshin-tools --scope user`로 다시 설치한다.
- **셋업 오류** — 세션 시작 알림에 `ERROR`가 찍혔다. 정본 복사 실패나 `@import` 배선 실패이고, 뒤의 것은 그 세션에 원칙이 실리지 않는다. `/setup-discipline`으로 다시 실행하고, 다시 `ERROR`가 찍히면 그 메시지를 이슈로 올린다.
- **설정 홈 불일치** — 셋업이 쓴 설정 홈과 지금 세션이 읽는 설정 홈이 다르다. 회사 PC의 홈 리다이렉트로 bash의 `$HOME`과 Windows의 `USERPROFILE`이 다를 때 생긴다. 실제 홈을 아래로 확인하고 `/setup-discipline`으로 다시 실행한다.

```bash
for d in "${CLAUDE_CONFIG_DIR:-}" "${USERPROFILE:+$USERPROFILE/.claude}" "$HOME/.claude"; do
  [ -n "$d" ] || continue
  [ -d "$d/disciplined-coder" ] && echo "셋업됨: $d" || echo "셋업 안 됨: $d"; break
done
```

## 커맨드

커맨드는 셸이 아닌 클로드 코드 안에서 슬래시로 부른다.

```text
/show-principles     # 적용 중인 원칙 보기
/setup-discipline    # 전역 셋업 재실행(멱등)
```

## 프로젝트 폴더에 생기는 파일

새로 생기는 파일은 없다. 원칙은 `agent-principles.md` 한 곳에 둔다. 그 정본이 원칙과 Karpathy guidelines(산출물이면 무엇에나 거는 지침)와 한국어로 쓸 때와 문서를 쓰고 관리할 때와 코딩할 때의 규칙을 갖는다. 절차와 산출물 한 종류에만 걸리는 규칙은 `skills/` 아래 스킬로 둔다. SessionStart hook이 원칙을 `~/.claude/disciplined-coder/`에 셋업하고, `~/.claude/CLAUDE.md`의 관리블록이 `@import`로 주입한다. 금지 표현 목록은 그 관리블록이 아니라 중립 이름의 공용 블록이 `@import` 한다. 규약은 KiwoomAX/korean-banned-words 의 `import-protocol.md`가 소유하고 사내 `kw-control-tower`도 같은 블록을 쓴다. 블록이 가리키는 목록이 우리 것보다 낡았을 때만 바꾸고, 판이 같은데 내용이 다르면 어느 쪽이 새것인지 알 수 없으므로 그대로 두고 알린다.

이 플러그인이 프로젝트 파일을 고치는 예외는 하나이고 그 조건은 여기가 정한다. 그 레포 `CLAUDE.md`에 관리블록이 남아 있고 그 블록을 만든 기능이 없어졌으면, 사본을 전역 백업에 복사한 뒤 제거한다. 조건이 하나 더 붙는다. 그 파일이 전역 `~/.claude/CLAUDE.md`와 같은 파일이면 건드리지 않는다 — 그것은 이 훅이 매 세션 다시 만드는 정상 블록이다. 같은 파일인지는 경로 문자열 대신 `-ef`로 본다. 작업 폴더가 `~/.claude`이면 윈도우 형식 경로와 POSIX 형식 경로가 같은 파일을 가리키는데 문자열로 견주면 다른 파일로 보인다. 그때의 잠금 대기 시간은 `scripts/_managed_block.sh`의 상수가 정한다.

## 하드 게이트와 넛지와 전역 설정 수정

이 플러그인이 세션에 무엇을 걸고 무엇을 막는지가 여기 있다. 이 목록은 여기가 소유한다. 배선은 둘이다. `hooks/hooks.json`은 이 플러그인이 어디서나 거는 훅이고, `.claude/settings.json`은 이 저장소에서만 도는 프로젝트 훅이다. 걸린 것은 아래가 전부이고 매 대화마다 도는 것은 하나도 없다. 답에 남은 금지 표현을 잡는 Stop 훅을 만들었다가 걷어냈는데, 실제 대화 기록으로 측정하니 답 하나에 1,021밀리초가 들었기 때문이다.

| 이벤트 | 스크립트 | 하는 일 |
|---|---|---|
| SessionStart | `scripts/scaffold.sh` | 정본 사본과 `@import` 배선을 만들고 알린다 |
| SessionStart | `scripts/_ensure_current.sh` | 설치본이 마켓플레이스 사본보다 뒤처지면 새 판으로 옮기고 다시 켜라고 알린다 |
| SessionStart | `scripts/seal_reviews.sh` | 커밋된 감사 기록을 읽기 전용으로 봉인한다(이 저장소의 프로젝트 훅) |
| SessionStart | `hooks/rules_nudge_sessionstart.sh` | 이 세션의 규칙 넛지 표시를 지워 다시 알리게 한다 |
| PreToolUse | `hooks/readonly_pretooluse.sh` | 읽기 전용 파일에 걸린 Write 와 Edit 을 사유와 함께 거부한다 |
| PreToolUse | `hooks/doc_format_pretooluse.sh` | 새 `.md` 에 문서 양식 넛지를 띄운다 |
| PreToolUse | `hooks/doc_word_pretooluse.sh` | 산출물 `.md` 에 금지 표현이 들어가면 거부한다 |
| PreToolUse | `hooks/rules_nudge_pretooluse.sh` | 세션의 첫 파일 편집 전에 정본 사본의 절대경로와 `domain-korean` 을 알린다 |
| PreToolUse | `hooks/python3_guard_pretooluse.sh` | 윈도우에서 `python3` 이 스토어 안내판으로 풀릴 때 그 Bash 명령을 거부한다 |
| PostToolUse | `hooks/spec_review_posttooluse.sh` | 새 spec·plan 을 감지해 리뷰를 지시한다 |
| PostToolUse | `hooks/doc_review_posttooluse.sh` | 산출물과 그 폴더의 마크다운에 검진 넛지를 띄운다. `Bash` 로 고친 것도 본다 |
| PostToolUse | `hooks/doc_word_posttooluse.sh` | 셸로 고친 산출물 `.md` 에 금지 표현이 남으면 알린다. 쓰인 뒤라 막지는 못한다 |
| Stop | `hooks/spec_review_stop.sh` | 미리뷰 spec·plan 이 남은 채 턴이 끝나는 것을 막는다 |
| Stop | `hooks/doc_word_stop.sh` | 이 턴에 `git` 으로 바뀐 산출물 `.md` 에 금지 표현이 남으면 알린다. 막지는 않는다 |

봉인 시점은 둘이다. 커밋된 기록은 세션 시작에 `seal_reviews.sh` 가 봉인하고, 회차 기록은 회차 끝에 호출자가 같은 스크립트를 파일 인자와 함께 불러 봉인한다.

### 막는 것 넷

여기 넷만 실제로 작업을 막는다. 나머지는 알리기만 한다.

- **Stop 하드 게이트** — `docs/superpowers/specs/`나 `docs/superpowers/plans/`에 새 `.md`가 생긴 채 턴을 끝내려 하면 막고 `review-specs` 수행을 지시한다. 문서 마지막 줄에 `<!-- spec-review: passed -->` 마커(🔴가 있으면 `<!-- spec-review: escalated -->`)가 남으면 풀린다. 차단은 턴에 한 번이라 두 번째 종료 시도는 통과한다.
- **산출물 차단** — 사용자가 요구한 산출물 `.md`에 「금지 표현」 목록의 말이 있으면 거부하고 무엇을 무엇으로 고칠지 보인다. 목록은 `korean-banned-words.md`에 있고 KiwoomAX/korean-banned-words 에서 받아 온 생성물이라 손으로 고치지 않는다. 셋은 대상에서 뺀다. 이 플러그인 저장소 자신의 문서와 Claude 메모리(`/.claude/projects/` 아래)와 `docs/superpowers/` 아래다. 코드 블록과 백틱 안은 검사하지 않으므로 그 말 자체를 적어야 하면 백틱으로 감싼다. 거부는 `Write`와 `Edit`에만 걸린다. 셸로 고치면 무엇이 쓰일지 미리 알 수 없어 막지 못하고, 쓰인 뒤에 `doc_word_posttooluse.sh`가 알리며 턴이 끝날 때 `doc_word_stop.sh`가 `git`으로 바뀐 파일을 한 번 더 본다.
- **읽기 전용 차단** — 읽기 전용 속성이 선 파일에 `Write`나 `Edit`을 하려 하면 거부하고 사유를 보인다. 어느 프로젝트의 어느 파일이든 속성만 본다. 풀려면 속성을 풀면 된다.
- **`python3` 차단** — 윈도우에서 `python3`이 스토어 안내판(`AppInstallerPythonRedirector.exe`)으로 풀릴 때만 그 Bash 명령을 거부하고 `python`이나 `py -3`을 쓰라고 알린다. 맥과 리눅스에서는 걸리지 않는다.

### 알리기만 하는 것 넷

spec이나 plan을 쓰면 리뷰를 지시하고, 새 `.md`를 만들면 정본의 「문서를 쓰고 관리할 때」로 타입과 수명을 가리게 하며 README라면 `domain-readme`를 함께 가리키고, `.pptx`·`.xlsx`·`.docx`·`.pdf` 산출물이나 그런 파일이 이미 있는 폴더의 `.md`를 고치면 `review-docs`의 검진을 권한다. 저장소에 커밋되는 작업 문서에는 뜨지 않는다 — 남에게 전달될 문서인지는 경로로 알 수 없어 대화 맥락으로 판단한다. 그리고 세션에서 파일을 처음 건드리기 전에 정본 사본의 절대경로와 `domain-korean.md`의 절대경로를 한 번 알린다. 정본은 `@import`로 상시 실리지만 서브에이전트에는 안 실리기 때문이다. 리뷰 기록에는 뜨지 않는다.

### 세션 시작에 하는 것 셋

새 세션을 열 때마다 이 셋이 돈다. 모두 알리고 지나가며 되돌릴 수 있다.

- 정본 사본과 `@import` 배선을 만들고 알린다. 다른 곳이 금지 표현 목록을 이미 싣고 있으면 그 줄은 건너뛴다.
- superpowers 가 이 PC에 없으면 설치 명령으로 알린다. 대신 깔지는 않는다. `~/.claude/disciplined-coder/plugin-notice.skip` 에 이름을 한 줄 적으면 조용해진다. 카파시(Andrej Karpathy)의 `andrej-karpathy-skills` 는 이 목록에 없다. 정본의 「Karpathy guidelines」 절이 그 네 절을 코드에서 산출물로 일반화해 줄여 담고 있어, 함께 깔면 비슷하지만 어긋나는 지침이 두 벌 실린다.
- 윈도우이고 사용자 환경 변수 `PYTHONUTF8` 이 비어 있으면 값 `1` 을 넣고 넣었다고 알린다. 값이 `0` 이면 일부러 끈 것으로 보고 손대지 않는다.

### 끄는 법

게이트와 넛지 다섯은 `DISCIPLINED_CODER_REVIEW_GATE=off` 하나로 다 꺼진다. 산출물 차단은 그 변수와 무관하고 `DISCIPLINED_CODER_REPLY_CHECK=off` 로 끈다 — 금지 표현 목록을 고치다가 그 목록이 검사 대상에 걸리는 일을 피하려고 통로를 나눠 두었다. 읽기 전용 차단과 `python3` 차단과 세션 시작의 셋은 어느 변수에도 안 걸린다. 그 변수는 hook이 프로세스 환경에서 읽으므로 Claude Code를 여는 셸에 두거나 `~/.claude/settings.json`의 `env`에 적는다. 전역 설정 수정은 남겨 둔 사본(`.bak`)으로 되돌릴 수 있다.

## 주의

아래 셋은 이 플러그인을 쓰다가 갖기 쉬운 오해다.

- **CLAUDE.md의 한계** — CLAUDE.md는 가이드이지 강제가 아니다. 파일 수정을 실제로 막으려면 `PreToolUse` hook을 설정한다.
- **서브에이전트와 원칙** — 서브에이전트에 원칙이 실린다고 믿지 않는다. 렌즈에는 원칙 파일의 경로를 넣는다. 어느 경로인지는 `skills/dispatching-lenses/SKILL.md`가 정한다.
- **병렬 오케스트레이션의 전제** — superpowers 플러그인이 함께 필요하다. 없으면 세션 시작 알림이 설치 명령을 보인다.

## 더 읽기

정본은 [`agent-principles.md`](agent-principles.md)이고 상세는 `skills/` 아래 각 스킬이 소유한다. 이슈는 [저장소](https://github.com/chshin84/disciplined-coder)에 올린다. 라이선스는 플러그인 매니페스트가 `UNLICENSED` 로 선언한다.
