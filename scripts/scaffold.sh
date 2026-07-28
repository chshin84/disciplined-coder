#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 지식을 PC(~/.claude/disciplined-coder)에 두고
# ~/.claude/CLAUDE.md 관리블록이 @import. 프로젝트 폴더는 건드리지 않는다.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# Claude 설정 홈 해석 — 공유 헬퍼(SSOT). 도메인 PC의 네트워크 홈 리다이렉트로 bash $HOME이
# os.homedir(USERPROFILE)과 어긋나면 조용한 누락(@import·solved)이 나므로 우선순위 해석을
# _resolve_home.sh 한 곳에 두고 issue-mode.sh·codex-scaffold.sh와 공유한다.
. "$(dirname "$0")/_resolve_home.sh"
. "$(dirname "$0")/_scaffold_common.sh"
CLAUDE_HOME="$(resolve_home claude)"
KDIR="$CLAUDE_HOME/disciplined-coder"
UC="$CLAUDE_HOME/CLAUDE.md"

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

# 1b) 관리 디렉터리 위생(멱등): 정책 정본은 _scaffold_common.sh(SCAFFOLD_WHITELIST·STALE).
#     비화이트리스트는 사용자 데이터일 수 있어 — 비었으면 제거, 내용 있으면 surface(FAIL-LOUD).
scaffold_hygiene "$KDIR"

# 2) solved 누적 파일(append-only 오답노트): 없을 때만 생성 — 템플릿 정본은 _scaffold_common.sh.
#    (이슈·백로그 트래킹은 안 한다 — 범위 밖.)
if scaffold_ensure_solved "$KDIR"; then created="$created solved_problems.md"; fi

# 2b) 오답노트 처분 모드: 판정 정본은 _scaffold_common.sh — mode_line/mode_note를 셋한다.
scaffold_resolve_issue_mode "$KDIR"

# 2c) ultracode 검증 모드: 판정 정본은 _scaffold_common.sh — ucr_mode_line/ucr_mode_note를 셋한다.
scaffold_resolve_ultracode_review "$KDIR"

# 2d) 오답노트 형식 규칙 넛지: 낡았는지 읽어 보기만 한다 — 어떤 파일에도 쓰지 않는다.
#     고치는 것은 사용자 승인을 받아 메인 세션이 한다(방법 정본은 domain-docs 스킬).
scaffold_check_solved_rules "$KDIR/solved_problems.md"

# 3) ~/.claude/CLAUDE.md 관리블록 재생성(멱등, CRLF 내성). 상대 @import(= ~/.claude 기준).
. "$(dirname "$0")/_managed_block.sh"
# 마커는 _managed_block.sh의 MANAGED_BEGIN/END(SSOT)를 쓴다.
# 스킬(domain-*/reviewer-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
# 첫 설치 판정은 반드시 주입 '전에' 한다 — 주입 후엔 항상 존재해 판정이 무의미해진다.
# -x(줄 전체 일치)를 쓰지 않는 이유: CRLF 파일에서 줄 끝 CR 때문에 영원히 거짓이 되어
# 이중 주입이 조용히 되살아난다(이 레포는 CRLF를 실재 문제로 이미 다룬다).
had_import=0
if [ -f "$UC" ] && grep -qF '@disciplined-coder/agent-principles.md' "$UC"; then had_import=1; fi
managed_block_inject "$UC" "$MANAGED_BEGIN" "$MANAGED_END" <<'EOF'
@disciplined-coder/agent-principles.md
@disciplined-coder/domains-index.md
@disciplined-coder/solved_problems.md
EOF

# 4) 첫 세션 도달 보강: CLAUDE.md는 이 훅보다 먼저 로드되므로, 블록을 방금 만든 세션은
#    @import만으로 정본에 닿지 못한다. 그 세션에만 stdout(additionalContext)으로 보강한다.
#    이후 세션은 @import 한 경로로만 로드한다 — 같은 내용을 두 번 싣지 않는다.
if [ "$had_import" -eq 0 ]; then
  for f in agent-principles.md domains-index.md solved_problems.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
  done
fi
# 토글 모드 라인은 @import 대상 파일에 없는 휘발성 상태라 매 세션 보낸다(조건 밖).
printf '%s\n' "$mode_line"
if [ -n "$mode_note" ]; then printf '%s\n' "$mode_note"; fi
printf '%s\n' "$ucr_mode_line"
if [ -n "$ucr_mode_note" ]; then printf '%s\n' "$ucr_mode_note"; fi
# 형식 규칙 넛지. 로그의 제목 줄이나 머리말 문구를 인용하지 않는다 — 인용하면 2회차 stdout에 정본
# 헤더가 되살아나 이중 주입 회귀 가드가 뒤집힌다. 원인도 단정하지 않는다(사용자가 규칙을 손봤을 수도 있다).
if [ "${solved_rules_stale:-0}" -eq 1 ]; then
  printf '🔵 disciplined-coder: %s 의 형식 규칙 서술이 현행과 다르다 — 고칠지는 사용자가 정한다(방법은 domain-docs 스킬).\n' "$KDIR/solved_problems.md"
fi

# 5) 보고
if [ -n "$created" ]; then echo "[disciplined-coder] PC knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
