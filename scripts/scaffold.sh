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

# 2) solved/unsolved 누적 파일: 없을 때만 생성.
if [ ! -f "$KDIR/solved_problems.md" ]; then
  cat > "$KDIR/solved_problems.md" <<'EOF'
# 해결된 문제 로그 (solved_problems) — PC 전역

작업 중 발견·해결된 문제. 각 항목: 문제 → 원인 → 해결. 등록·이동은 메인 세션이 수행.
일반화 가능한 항목은 디시플린(agent-principles.md)으로 승격하고 여기서는 제거(SSOT).
EOF
  created="$created solved_problems.md"
fi
if [ ! -f "$KDIR/unsolved_problems.md" ]; then
  cat > "$KDIR/unsolved_problems.md" <<'EOF'
# 미해결 / 대기 문제 (unsolved_problems) — PC 전역

> ⚠️ 🔴 항목은 사용자 결정 대기 — 어떤 에이전트도 자율 구현·수정 금지. 참고만.
등록은 검증/리뷰 종료 시, solved 이동은 테스트 통과 시 — 메인 세션이 수행.
범례: 🔴 결정 필요 · 🟡 구현 대기 · 🔵 향후.

## 🔴 결정 필요

## 🟡 구현 대기

## 🔵 향후 / 선택
EOF
  created="$created unsolved_problems.md"
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
  # unsolved는 미주입(백로그). 스킬(domain-*/reviewer-*)은 플러그인에서 온디맨드 — 복사/주입 안 함.
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
