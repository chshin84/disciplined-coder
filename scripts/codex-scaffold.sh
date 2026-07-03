#!/usr/bin/env bash
# Idempotent. Codex SessionStart마다 실행. 지식을 ~/.codex/disciplined-coder에 두고
# ~/.codex/AGENTS.md 관리블록에 정본을 인라인(Codex는 @import 미지원). 프로젝트 폴더는 안 건드린다.
# scaffold.sh(Claude)의 Codex 쌍둥이 — 정본 소스 동일(PLUGIN_ROOT의 agent-principles.md 등).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Codex 홈 해석 — scaffold.sh와 같은 공유 헬퍼(SSOT). 런타임만 codex로(홈은 ~/.codex).
. "$(dirname "$0")/_resolve_home.sh"
. "$(dirname "$0")/_scaffold_common.sh"
CODEX_HOME="$(resolve_home codex)"
KDIR="$CODEX_HOME/disciplined-coder"
AG="$CODEX_HOME/AGENTS.md"
mkdir -p "$KDIR"
created=""

# 1) 정본(static) 복사·갱신: principles, domains-index. src==dst면 생략.
for f in agent-principles.md domains-index.md; do
  src="$PLUGIN_ROOT/$f"; dst="$KDIR/$f"
  if [ -f "$src" ]; then
    if [ "$src" = "$dst" ] || { [ -e "$dst" ] && [ "$src" -ef "$dst" ]; }; then :; else cp "$src" "$dst"; fi
  else
    echo "[disciplined-coder] WARNING: source not found at $src" >&2
  fi
done

# 1b) 관리 디렉터리 위생(멱등) — 정책 정본은 _scaffold_common.sh(scaffold.sh와 패리티).
scaffold_hygiene "$KDIR"

# 2) solved 누적 파일(append-only 오답노트): 없을 때만 생성 — 템플릿 정본은 _scaffold_common.sh.
#    (이슈·백로그 트래킹은 안 한다 — 범위 밖.)
if scaffold_ensure_solved "$KDIR"; then created="$created solved_problems.md"; fi

# 2b) 오답노트 처분 모드(scaffold.sh와 동일 정책) — 판정 정본은 _scaffold_common.sh.
scaffold_resolve_issue_mode "$KDIR"
# (의도적 비대칭) ultracode 검증 모드는 여기서 다루지 않는다 — Codex에는 Workflow 도구가 없어
# 주입이 무동작이다. 공유 화이트리스트 덕에 파일이 생겨도 위생 오탐은 없다(spec 2026-07-03).

# 3) ~/.codex/AGENTS.md 관리블록 재생성(멱등, CRLF 내성). @import 미지원 → 정본 본문 인라인.
. "$(dirname "$0")/_managed_block.sh"
# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT).
{
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; printf '\n'; fi
  done
} | managed_block_inject "$AG" "$MANAGED_BEGIN" "$MANAGED_END"

# 4) 세션 주입용 stdout: principles + domains-index + solved 본문(session-start-codex가 캡처해 additionalContext로).
#    AGENTS.md 인라인(섹션 3)은 principles+domains만(안정적). 자주 커지는 solved는 주입 경로로(spec 3.5).
for f in agent-principles.md domains-index.md solved_problems.md; do
  if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
done
printf '%s\n' "$mode_line"
if [ -n "$mode_note" ]; then printf '%s\n' "$mode_note"; fi

# 5) 보고(진단은 stderr — stdout은 주입 본문 전용).
if [ -n "$created" ]; then echo "[disciplined-coder] Codex knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
