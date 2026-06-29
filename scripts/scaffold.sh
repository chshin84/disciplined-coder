#!/usr/bin/env bash
# Idempotent. SessionStart마다 실행. 지식을 PC(~/.claude/disciplined-coder)에 두고
# ~/.claude/CLAUDE.md 관리블록이 @import. 프로젝트 폴더는 건드리지 않는다.
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CLAUDE_HOME="${CLAUDE_HOME_DIR:-$HOME/.claude}"   # 테스트는 CLAUDE_HOME_DIR로 오버라이드
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

# 1b) 구 파일명 정리(멱등): 이전 버전이 남긴 coding-principles.md orphan 제거.
[ -f "$KDIR/coding-principles.md" ] && rm -f "$KDIR/coding-principles.md" || true

# 2) solved 누적 파일(append-only 오답노트): 없을 때만 생성. (이슈·백로그 트래킹은 안 한다 — 범위 밖.)
if [ ! -f "$KDIR/solved_problems.md" ]; then
  cat > "$KDIR/solved_problems.md" <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역 · append-only 오답노트

완결된 문제의 교훈 모음 — 차후 비슷한 작업에서 recall해 참고한다. 각 항목: 문제 → 원인 → 해결.
**완결 후 등록하는 기록이라 '상태'가 아니다** — "문서에 상태 금지"의 예외(append-only, 과거를 지우지 않는다).
일반화 가능한 항목은 디시플린(agent-principles.md)으로 승격하고 여기서는 제거(SSOT). 메인 세션만 기록.
EOF
  created="$created solved_problems.md"
fi

# 3) ~/.claude/CLAUDE.md 관리블록 재생성(멱등, CRLF 내성). 상대 @import(= ~/.claude 기준).
touch "$UC"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
if grep -qF "$BEGIN_MARK" "$UC" && grep -qF "$END_MARK" "$UC"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '{ l=$0; sub(/\r$/,"",l) } l==b{skip=1} skip==0{print} l==e{skip=0}' "$UC" > "$UC.tmp"
elif grep -qF "$BEGIN_MARK" "$UC"; then
  echo "[disciplined-coder] WARNING: ~/.claude/CLAUDE.md has BEGIN but no END — skipping strip" >&2
  cp "$UC" "$UC.tmp"
else
  cp "$UC" "$UC.tmp"
fi
awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$UC.tmp" > "$UC" && rm -f "$UC.tmp"
{
  if [ -s "$UC" ]; then printf '\n'; fi
  printf '%s\n' "$BEGIN_MARK"
  # 스킬(domain-*/reviewer-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
  printf '@disciplined-coder/agent-principles.md\n@disciplined-coder/domains-index.md\n@disciplined-coder/solved_problems.md\n'
  printf '%s\n' "$END_MARK"
} >> "$UC"

# 4) 첫 세션 도달 보강: principles + domains-index를 stdout으로.
for f in agent-principles.md domains-index.md; do
  if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
done

# 5) 보고
if [ -n "$created" ]; then echo "[disciplined-coder] PC knowledge initialized:$created (at $KDIR)"; fi
exit 0
