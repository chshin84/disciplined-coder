#!/usr/bin/env bash
# Idempotent. Codex SessionStart마다 실행. 지식을 ~/.codex/disciplined-coder에 두고
# ~/.codex/AGENTS.md 관리블록에 정본을 인라인(Codex는 @import 미지원). 프로젝트 폴더는 안 건드린다.
# scaffold.sh(Claude)의 Codex 쌍둥이 — 정본 소스 동일(PLUGIN_ROOT의 agent-principles.md 등).
set -euo pipefail
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CODEX_HOME="${CODEX_HOME_DIR:-$HOME/.codex}"   # 테스트는 CODEX_HOME_DIR로 오버라이드
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

# 3) ~/.codex/AGENTS.md 관리블록 재생성(멱등, CRLF 내성). @import 미지원 → 정본 본문 인라인.
touch "$AG"
BEGIN_MARK="# BEGIN disciplined-coder (managed — do not edit)"
END_MARK="# END disciplined-coder (managed — do not edit)"
if grep -qF "$BEGIN_MARK" "$AG" && grep -qF "$END_MARK" "$AG"; then
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '{ l=$0; sub(/\r$/,"",l) } l==b{skip=1} skip==0{print} l==e{skip=0}' "$AG" > "$AG.tmp"
elif grep -qF "$BEGIN_MARK" "$AG"; then
  echo "[disciplined-coder] WARNING: ~/.codex/AGENTS.md has BEGIN but no END — skipping strip" >&2
  cp "$AG" "$AG.tmp"
else
  cp "$AG" "$AG.tmp"
fi
awk '{ l=$0; sub(/\r$/,"",l); if (l ~ /[^ \t]/) last=NR; line[NR]=$0 } END { for (i=1;i<=last;i++) print line[i] }' "$AG.tmp" > "$AG" && rm -f "$AG.tmp"
{
  if [ -s "$AG" ]; then printf '\n'; fi
  printf '%s\n' "$BEGIN_MARK"
  for f in agent-principles.md domains-index.md; do
    if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; printf '\n'; fi
  done
  printf '%s\n' "$END_MARK"
} >> "$AG"

# 4) 세션 주입용 stdout: principles + domains-index + solved 본문(session-start-codex가 캡처해 additionalContext로).
#    AGENTS.md 인라인(섹션 3)은 principles+domains만(안정적). 자주 커지는 solved는 주입 경로로(spec 3.5).
for f in agent-principles.md domains-index.md solved_problems.md; do
  if [ -f "$KDIR/$f" ]; then cat "$KDIR/$f"; fi
done

# 5) 보고(진단은 stderr — stdout은 주입 본문 전용).
if [ -n "$created" ]; then echo "[disciplined-coder] Codex knowledge initialized:$created (at $KDIR)" >&2; fi
exit 0
