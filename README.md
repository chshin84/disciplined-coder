# disciplined-coder

팀 엔지니어링 원칙을 모든 Claude Code 세션에 자동으로 실어 주는 플러그인이다. 작업 폴더에 원칙 사본은 생기지 않는다.

## 설치

스코프는 user여야 모든 프로젝트에서 hook이 실행된다. Windows는 [Git Bash](https://git-scm.com/downloads)를 먼저 설치한다. hook이 `bash`로 스크립트를 실행하기 때문이다. 마켓플레이스 자동 갱신에는 파이썬이 필요하다.

```text
/plugin marketplace add chshin84/disciplined-coder
/plugin install disciplined-coder@chshin-tools
```

## 동작 확인과 복구

새 세션을 한 번 열면 셋업이 끝난다. `/show-principles`로 원칙 목록이 나오면 정상이다.

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

```text
/show-principles     # 적용 중인 원칙 보기
/setup-discipline    # 전역 셋업 재실행(멱등)
```

## 프로젝트 폴더에 생기는 파일

새로 생기는 파일은 없다. 원칙은 `agent-principles.md` 한 곳에 둔다. 그 정본에는 파일 없는 답 한 번으로도 어길 수 있는 대화 규칙만 있고, 코딩 규칙은 `skills/domain-coding/SKILL.md`에, 문서의 분량과 수정 범위 규칙은 `skills/domain-writing/SKILL.md`에 있다. SessionStart hook이 원칙을 `~/.claude/disciplined-coder/`에 셋업하고, `~/.claude/CLAUDE.md`의 관리블록이 `@import`로 주입한다.

이 플러그인이 프로젝트 파일을 고치는 예외는 하나이고 그 조건은 여기가 정한다. 그 레포 `CLAUDE.md`에 관리블록이 남아 있고 그 블록을 만든 기능이 없어졌으면, 사본을 전역 백업에 복사한 뒤 제거한다. 그때의 잠금 대기 시간은 `scripts/_managed_block.sh`의 상수가 정한다.

## 하드 게이트와 넛지와 전역 설정 수정

세션에는 턴 종료를 막는 하드 게이트 하나와 읽기 전용 파일 수정을 막는 차단 하나와 넛지 셋과 전역 설정 수정 하나가 걸리고, 세션 시작에 설치 권유 하나가 뜬다. 게이트와 넛지는 환경변수 `DISCIPLINED_CODER_REVIEW_GATE=off` 하나로 넷 다 꺼지고, 읽기 전용 차단과 설치 권유는 그 변수와 무관하며, 전역 설정 수정은 남겨 둔 사본(`.bak`)으로 되돌릴 수 있다. 그 변수는 hook이 프로세스 환경에서 읽으므로 Claude Code를 여는 셸에 두거나 `~/.claude/settings.json`의 `env`에 적는다.

- **Stop 하드 게이트** — `docs/superpowers/specs/`나 `docs/superpowers/plans/`에 새 `.md`가 생긴 채 턴을 끝내려 하면 종료를 막고 `domain-spec-review` 수행을 지시한다. 문서 마지막 줄에 `<!-- spec-review: passed -->` 마커(🔴가 있으면 `<!-- spec-review: escalated -->`)가 남으면 종료 차단이 해제된다. 차단은 턴에 한 번이다. 두 번째 종료 시도는 통과하므로 리뷰를 하지 않고도 턴을 끝낼 수 있다. 상세는 `skills/domain-spec-review/SKILL.md`를 참고한다.
- **읽기 전용 차단** — 읽기 전용 속성이 선 파일에 `Write`나 `Edit`을 하려 하면 거부하고 사유를 보인다. 어느 프로젝트의 어느 파일이든 속성만 보며, 이 레포의 감사 기록은 만든 직후 `scripts/seal_reviews.sh`가 그 속성을 세운다. 풀려면 속성을 풀면 된다.
- **넛지 셋** — 차단하지 않고 안내만 한다. spec이나 plan을 쓰면 리뷰를 지시하고, 새 `.md`를 만들면 `domain-docs`의 양식을 제안하며, `.md`를 고치면 문서 검진을 권한다. 프로젝트 폴더 밖의 문서와 리뷰 기록에는 뜨지 않는다.
- **카파시 플러그인 설치 권유** — 이 플러그인을 처음 깔았거나 갱신한 첫 세션에, 카파시(Andrej Karpathy)의 코딩 지침 플러그인 `andrej-karpathy-skills`가 이 PC에 없으면 설치 명령 두 줄을 세션 시작 알림으로 보인다. 설치하지는 않으며, 무시하면 다음 갱신까지 다시 뜨지 않는다. 정본의 「Think Before Acting」 절과 `domain-coding`·`domain-writing`의 카파시 절은 그 플러그인의 네 절을 옮긴 것이고, 겹치던 조항은 정본에서 뺐다.
- **전역 설정 수정** — 첫 세션에 `~/.claude/settings.json`과 `~/.claude/plugins/known_marketplaces.json` 두 파일을 고친다. 이 마켓플레이스 항목에만 `autoUpdate: true`를 넣어 깃허브의 갱신이 자동으로 적용되게 한다. 키가 없을 때만 넣고, 사용자가 `false`로 둔 것은 그대로 두며, 사본(`.bak`)을 남기고 세션 시작 알림으로 고친 경로를 알린다. 지키는 규칙은 `skills/domain-plugin/SKILL.md`의 「사용자 설정 파일을 고칠 때 지킬 것」을 참고한다.

## 주의

- **CLAUDE.md의 한계** — CLAUDE.md는 가이드이지 강제가 아니다. 파일 수정을 실제로 막으려면 `PreToolUse` hook을 설정한다.
- **서브에이전트와 원칙** — 서브에이전트에 원칙이 실린다고 믿지 않는다. 렌즈에는 원칙 파일의 경로를 넣는다. 어느 경로인지는 `skills/domain-docs/SKILL.md`가 정한다.
- **병렬 오케스트레이션의 전제** — superpowers 플러그인이 함께 필요하다.

## 더 읽기

정본은 [`agent-principles.md`](agent-principles.md)이고 상세는 `skills/` 아래 각 스킬이 소유한다. 이슈는 [저장소](https://github.com/chshin84/disciplined-coder)에 올린다. 라이선스는 아직 정하지 않았다.
