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

# 2b) 오답노트 형식 규칙 넛지(scaffold.sh와 동일 정책): 읽어 보기만 하고 파일은 쓰지 않는다.
#     쌍둥이 스크립트는 한쪽만 고치면 반드시 어긋나므로 같이 둔다.
scaffold_check_solved_rules "$KDIR/solved_problems.md"

# 3) ~/.codex/AGENTS.md 관리블록 재생성(멱등, CRLF 내성). @import 미지원 → 정본 본문 인라인.
. "$(dirname "$0")/_managed_block.sh"
# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT).
# 첫 설치 판정은 반드시 주입 '전에' 한다 — 주입 후엔 항상 존재해 판정이 무의미해진다.
# scaffold.sh의 had_import와 같은 역할이며, 판정 대상만 다르다(Claude는 @import 줄, Codex는 관리블록 마커).
had_inline=0
if [ -f "$AG" ] && grep -qF "$MANAGED_BEGIN" "$AG"; then had_inline=1; fi
{
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; printf '\n'; fi
  done
} | managed_block_inject "$AG" "$MANAGED_BEGIN" "$MANAGED_END"

# 4) 세션 주입용 stdout(session-start-codex가 캡처해 additionalContext로 넣는다).
#    분업 — principles+domains는 섹션 3이 AGENTS.md에 이미 인라인했으므로 여기서 다시 보내지 않는다.
#    자주 커지는 solved만 매 세션 주입 경로로 보낸다(spec 3.5). 예외는 첫 설치 세션뿐이다 —
#    AGENTS.md는 이 훅보다 먼저 로드되므로 블록을 방금 만든 세션은 인라인만으로 정본에 닿지 못한다
#    (scaffold.sh의 had_import와 같은 이유).
if [ "$had_inline" -eq 0 ]; then
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
  done
fi
if [ -f "$KDIR/solved_problems.md" ]; then cat "$KDIR/solved_problems.md"; fi
# 형식 규칙 넛지. 로그의 제목 줄이나 머리말 문구를 인용하지 않고 원인도 단정하지 않는다.
if [ "${solved_rules_stale:-0}" -eq 1 ]; then
  printf '🔵 disciplined-coder: %s 의 형식 규칙 서술이 현행과 다르다 — 고칠지는 사용자가 정한다(방법은 domain-docs 스킬).\n' "$KDIR/solved_problems.md"
fi

# 5) 보고(진단은 stderr — stdout은 주입 본문 전용).
if [ -n "$created" ]; then echo "[disciplined-coder] Codex knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
