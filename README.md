# disciplined-coder

팀 엔지니어링 원칙을 모든 Claude Code 세션에 자동으로 실어 주는 플러그인이다. 원칙 파일 하나를 모든 프로젝트에 싣고, 문서를 쓰고 고칠 때 리뷰와 검진을 안내하며, 몇 가지 위험한 편집을 막는다. 작업 폴더에 원칙 사본은 생기지 않는다.

## 설치

스코프는 user여야 모든 프로젝트에서 hook이 실행된다. Windows는 [Git Bash](https://git-scm.com/downloads)와 [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows)을 먼저 설치한다. hook이 `bash`로 스크립트를 실행하고, 환경 변수를 넣는 단계가 `pwsh`를 호출하기 때문이다. 윈도우 기본 5.1(`powershell`)로는 동작하지 않는다. 마켓플레이스 자동 갱신에는 파이썬이 필요하다.

```text
/plugin marketplace add chshin84/disciplined-coder
/plugin install disciplined-coder@chshin-tools
```

## 동작 확인과 복구

새 세션을 한 번 열면 셋업이 끝난다. 세션 시작 알림에 `ERROR`나 `WARNING` 줄이 없으면 정상이다. 정상일 때도 원칙 전문과 갱신 알림이 출력되므로 오류 줄이 있는지로 판단한다. `/show-principles`를 실행해 원칙 목록이 나오면 된다.

목록이 안 나오면 원인은 아래 중 하나다.

- **스코프** — 플러그인 스코프가 user가 아니어서 hook이 실행되지 않았다. 설치할 때 스코프를 따로 주지 않았다면 기본값이 user이므로 이 원인이 아니다. 터미널에서 `claude plugin install disciplined-coder@chshin-tools --scope user`로 다시 설치한다.
- **셋업 오류** — 세션 시작 알림에 `ERROR`가 찍혔다. 원칙 복사나 `@import` 연결이 실패한 것이고, 연결이 실패하면 그 세션에는 원칙이 실리지 않는다. `/setup-discipline`으로 다시 실행하고, 또 `ERROR`가 찍히면 그 메시지를 이슈로 올린다.
- **설정 홈 불일치** — 셋업이 쓴 설정 홈과 지금 세션이 읽는 설정 홈이 다르다. 회사 PC의 홈 리다이렉트로 bash의 `$HOME`과 Windows의 `USERPROFILE`이 다를 때 생긴다. 실제 홈을 아래로 확인하고 `/setup-discipline`으로 다시 실행한다.

```bash
for d in "${CLAUDE_CONFIG_DIR:-}" "${USERPROFILE:+$USERPROFILE/.claude}" "$HOME/.claude"; do
  [ -n "$d" ] || continue
  [ -d "$d/disciplined-coder" ] && echo "셋업됨: $d" || echo "셋업 안 됨: $d"; break
done
```

## 커맨드

커맨드는 셸이 아닌 Claude Code 안에서 슬래시로 실행한다.

```text
/show-principles     # 적용 중인 원칙 보기
/setup-discipline    # 전역 셋업 재실행(멱등)
```

## 프로젝트 폴더에 생기는 파일

새로 생기는 파일은 없다. SessionStart hook이 `agent-principles.md`를 `~/.claude/disciplined-coder/`에 복사하고, `~/.claude/CLAUDE.md`의 관리블록이 그 사본을 `@import`로 싣는다. 절차와 산출물 한 종류에만 적용되는 규칙은 `skills/` 아래 스킬로 두고 필요할 때 연다. 금지 표현 목록은 중립 이름의 공용 블록이 따로 싣는다. 그 규약은 KiwoomAX/korean-banned-words 의 `import-protocol.md`가 소유하고, 사내 `kw-control-tower`도 같은 블록을 쓴다.

이 플러그인이 프로젝트 파일을 고치는 예외는 하나이고 그 조건은 여기가 정한다. 그 레포 `CLAUDE.md`에 관리블록이 남아 있고 그 블록을 만든 기능이 없어졌으면, 사본을 전역 백업에 복사한 뒤 제거한다. 그 파일이 전역 `~/.claude/CLAUDE.md`와 같은 파일이면 건드리지 않는다. 잠금 대기 시간은 `scripts/_managed_block.sh`의 상수가 정한다.

## 하드 게이트와 넛지와 전역 설정 수정

이 플러그인이 세션에 적용하는 hook은 아래가 전부이고, 이 목록은 여기가 소유한다. 연결 파일은 둘이다. `hooks/hooks.json`은 어디서나 적용되는 hook이고, `.claude/settings.json`은 이 저장소에서만 도는 프로젝트 hook이다. 대화 답마다 도는 hook은 없다.

| 이벤트 | 스크립트 | 하는 일 | 막는가 |
|---|---|---|---|
| SessionStart | `scripts/scaffold.sh` | 원칙 사본과 `@import` 연결을 만들고 알린다 | 알림 |
| SessionStart | `scripts/_ensure_current.sh` | 설치본이 마켓플레이스 사본보다 뒤처지면 새 버전으로 옮기고 다시 켜라고 알린다 | 알림 |
| SessionStart | `scripts/seal_reviews.sh` | 커밋된 감사 기록을 읽기 전용으로 봉인한다(이 저장소의 프로젝트 hook) | 알림 |
| SessionStart | `hooks/rules_nudge_sessionstart.sh` | 이 세션의 규칙 넛지 표시를 지워 다시 알리게 한다 | 알림 |
| PreToolUse | `hooks/readonly_pretooluse.sh` | 읽기 전용 파일에 대한 Write와 Edit을 사유와 함께 거부한다 | 막음 |
| PreToolUse | `hooks/doc_format_pretooluse.sh` | 새 `.md`를 만들면 에이전트원칙의 「문서를 쓰고 관리할 때」로 타입과 수명을 가리게 하고, README면 `domain-readme`를 함께 가리킨다 | 알림 |
| PreToolUse | `hooks/doc_word_pretooluse.sh` | 산출물 `.md`에 금지 표현이 들어가면 거부한다 | 막음 |
| PreToolUse | `hooks/rules_nudge_pretooluse.sh` | 규칙 넛지. 세션의 첫 파일 편집 전에 원칙 사본과 `domain-korean.md`의 절대경로를 한 번 알린다. 서브에이전트에는 원칙이 실리지 않기 때문이다 | 알림 |
| PreToolUse | `hooks/python3_guard_pretooluse.sh` | 윈도우에서 `python3`이 스토어 안내판으로 풀릴 때 그 Bash 명령을 거부한다 | 막음 |
| PostToolUse | `hooks/spec_review_posttooluse.sh` | 새 spec·plan을 감지해 리뷰를 지시한다 | 알림 |
| PostToolUse | `hooks/doc_review_posttooluse.sh` | `.pptx`·`.xlsx`·`.docx`·`.pdf` 산출물이나 그런 파일이 있는 폴더의 `.md`를 고치면 `review-docs` 검진을 권한다. `Bash`로 고친 것도 본다 | 알림 |
| PostToolUse | `hooks/doc_word_posttooluse.sh` | 셸로 고친 산출물 `.md`에 금지 표현이 남으면 알린다 | 알림 |
| Stop | `hooks/spec_review_stop.sh` | 리뷰하지 않은 spec·plan이 남은 채 턴이 끝나는 것을 막는다 | 막음 |
| Stop | `hooks/doc_word_stop.sh` | 이 턴에 `git`으로 바뀐 산출물 `.md`에 금지 표현이 남으면 알린다 | 알림 |

검진 넛지는 저장소에 커밋되는 작업 문서와 리뷰 기록에는 뜨지 않는다. 남에게 전달될 문서인지는 경로로 알 수 없어 대화 맥락으로 판단한다.

### 막혔을 때 푸는 법

표에서 「막음」인 hook이 작업을 멈췄을 때 푸는 방법이다.

- **Stop 하드 게이트** — `docs/superpowers/specs/`나 `docs/superpowers/plans/`에 새 `.md`가 생긴 채 턴을 끝내려 하면 막고 `review-specs` 수행을 지시한다. 문서 마지막 줄에 `<!-- spec-review: passed -->` 마커(🔴가 있으면 `<!-- spec-review: escalated -->`)가 남으면 풀린다. 차단은 턴에 한 번이라 두 번째 종료 시도는 통과한다.
- **산출물 차단** — 사용자가 요구한 산출물 `.md`에 「금지 표현」 목록의 말이 있으면 거부하고 무엇을 무엇으로 고칠지 보인다. 이 플러그인 저장소의 문서, Claude 메모리(`/.claude/projects/` 아래), `docs/superpowers/` 아래는 대상이 아니다. 코드 블록과 백틱 안은 검사하지 않으므로 그 말 자체를 적어야 하면 백틱으로 감싼다. 셸로 고친 파일은 쓰기 전에 알 수 없어 막지 못하고, 쓰인 뒤와 턴이 끝날 때 알린다.
- **읽기 전용 차단** — 읽기 전용 속성이 붙은 파일에 대한 `Write`와 `Edit`을 거부한다. 어느 프로젝트의 어느 파일이든 속성만 본다. 속성을 풀면 풀린다.
- **`python3` 차단** — 윈도우에서 `python3`이 스토어 안내판(`AppInstallerPythonRedirector.exe`)으로 풀릴 때만 거부하고 `python`이나 `py -3`을 쓰라고 알린다. 맥과 리눅스에는 적용되지 않는다.

### 세션 시작에 바꾸는 전역 설정

새 세션을 열 때마다 아래를 확인하고, 바꾼 것은 알린다. 전역 설정을 바꾸기 전에 남긴 사본(`.bak`)으로 되돌릴 수 있다.

- **원칙 연결** — 원칙 사본과 `@import` 연결을 만든다. 다른 곳이 금지 표현 목록을 이미 싣고 있으면 그 줄은 건너뛴다.
- **superpowers 안내** — superpowers가 이 PC에 없으면 설치 명령을 알린다. 대신 설치하지는 않는다. `~/.claude/disciplined-coder/plugin-notice.skip`에 이름을 한 줄 적으면 알림이 멈춘다. `andrej-karpathy-skills`는 함께 설치하지 않기를 권한다. 에이전트원칙의 「원칙」 절이 같은 지침을 담고 있어, 함께 설치하면 비슷하지만 다른 지침이 두 벌 실린다.
- **`PYTHONUTF8`** — 윈도우이고 사용자 환경 변수 `PYTHONUTF8`이 비어 있으면 `1`을 넣는다. 값이 `0`이면 일부러 끈 것으로 보고 손대지 않는다.

### 끄는 법

hook은 환경 변수 두 개로 끈다.

- **`DISCIPLINED_CODER_REVIEW_GATE=off`** — `spec_review_posttooluse.sh`, `spec_review_stop.sh`, `doc_format_pretooluse.sh`, `doc_review_posttooluse.sh`, `rules_nudge_pretooluse.sh`를 끈다.
- **`DISCIPLINED_CODER_REPLY_CHECK=off`** — 금지 표현 hook(`doc_word_pretooluse.sh`, `doc_word_posttooluse.sh`, `doc_word_stop.sh`)을 끈다. 금지 표현 목록을 고칠 때 그 목록이 검사에 걸리지 않게 하려고 변수를 나눠 두었다.

읽기 전용 차단, `python3` 차단, 세션 시작의 셋업은 끄는 변수가 없다. 두 변수는 hook이 프로세스 환경에서 읽으므로 Claude Code를 여는 셸에 두거나 `~/.claude/settings.json`의 `env`에 적는다.

## 주의

이 플러그인을 쓸 때 오해하기 쉬운 점이다.

- **CLAUDE.md의 한계** — CLAUDE.md는 안내이지 강제가 아니다. 파일 수정을 실제로 막으려면 `PreToolUse` hook을 설정한다.
- **서브에이전트와 원칙** — 서브에이전트에는 원칙이 실리지 않는다. 렌즈에는 원칙 파일의 경로를 넣으며, 어느 경로인지는 `skills/dispatching-lenses/SKILL.md`가 정한다.
- **병렬 오케스트레이션의 전제** — superpowers 플러그인이 함께 필요하다. 없으면 세션 시작 알림이 설치 명령을 보인다.

## 더 읽기

에이전트원칙은 [`agent-principles.md`](agent-principles.md)이고, 상세는 `skills/` 아래 각 스킬이 소유한다. 이슈는 [저장소](https://github.com/chshin84/disciplined-coder)에 올린다. 라이선스는 플러그인 매니페스트가 `UNLICENSED`로 선언한다.
