# disciplined-coder

팀 엔지니어링 원칙을 모든 Claude Code 세션에 자동으로 실어 주는 플러그인이다. 작업 폴더에 원칙 사본은 생기지 않는다. 원칙은 `agent-principles.md` 한 곳에 두고, SessionStart hook이 그것을 `~/.claude/disciplined-coder/`에 셋업한 뒤 `~/.claude/CLAUDE.md`의 관리블록이 `@import`로 주입한다.

## 설치

```text
/plugin marketplace add chshin84/disciplined-coder
/plugin install disciplined-coder@chshin-tools
```

스코프는 user여야 모든 프로젝트에서 hook이 돈다. Windows는 [Git Bash](https://git-scm.com/downloads)를 먼저 깐다 — hook이 `bash`로 스크립트를 돌린다. 마켓플레이스 자동 갱신에는 파이썬이 필요하다.

## 사용

새 세션을 한 번 열면 셋업이 끝난다. `/show-principles`로 원칙 목록이 나오면 정상이다.

목록이 안 나오면 설정 홈이 어긋난 것이다 — 회사 PC는 홈 리다이렉트로 bash의 `$HOME`과 Windows의 `USERPROFILE`이 다르다. 실제 홈을 아래로 확인하고 `/setup-discipline`으로 다시 돌린다.

```bash
for d in "${CLAUDE_CONFIG_DIR:-}" "${USERPROFILE:+$USERPROFILE/.claude}" "$HOME/.claude"; do
  [ -n "$d" ] || continue
  [ -d "$d/disciplined-coder" ] && echo "완료: $d" || echo "안 됨: $d"; break
done
```

### 커맨드

```text
/show-principles     # 활성 정본 보기
/setup-discipline    # 전역 셋업 재실행(멱등)
```

## 프로젝트 폴더에 생기는 파일

새로 생기는 파일은 없다. 자동 계층이 프로젝트 파일을 고치는 예외는 하나다(여기가 그 정본이다) — 없앤 기능이 남긴 관리블록이 그 레포 `CLAUDE.md`에 있으면 사본을 전역 백업에 쌓은 뒤 걷어낸다. 잠금 대기 시간은 `scripts/_managed_block.sh`의 상수가 정한다.

## 세션에 강제하거나 고치는 것

- **Stop 하드 게이트** — `docs/superpowers/specs/`나 `docs/superpowers/plans/`에 새 `.md`가 생긴 채 턴을 끝내려 하면 종료를 막고 `domain-spec-review` 수행을 지시한다. 문서 마지막 줄에 `<!-- spec-review: passed -->` 마커(🔴가 있으면 `escalated`)가 남으면 풀린다. 끄려면 환경변수 `DISCIPLINED_CODER_REVIEW_GATE=off`를 준다. 상세는 `skills/domain-spec-review/SKILL.md`가 정본이다.
- **전역 설정 수정** — 첫 세션에 `~/.claude/settings.json`과 `~/.claude/plugins/known_marketplaces.json`의 이 마켓플레이스 항목에만 `autoUpdate: true`를 넣어 깃허브의 갱신이 자동으로 따라오게 한다. 키가 없을 때만 넣고, 사용자가 `false`로 둔 것은 그대로 두며, 사본(`.bak`)을 남기고 세션 시작 알림으로 고친 경로를 알린다. 규칙은 `scripts/_ensure_autoupdate.sh`가 정본이다.

## 주의

- **CLAUDE.md는 가이드이지 강제가 아니다** — 막으려면 `PreToolUse` hook을 건다.
- **서브에이전트에 원칙이 실린다고 믿지 않는다** — 렌즈에는 정본 경로를 넣는다.
- **병렬 오케스트레이션에는 superpowers 플러그인이 함께 필요하다.**
- **Codex에서도 쓴다**(`.codex-plugin/plugin.json`) — 레포 폴더를 마켓플레이스로 등록하고 훅을 신뢰한다.

## 더 읽기

정본은 [`agent-principles.md`](agent-principles.md)이고 상세는 `skills/` 아래 각 스킬이 갖는다. 이슈는 [저장소](https://github.com/chshin84/disciplined-coder)에 올린다. 라이선스는 아직 정하지 않았다.
