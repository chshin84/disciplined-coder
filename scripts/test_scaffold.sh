#!/usr/bin/env bash
# scaffold.sh 동작 검증. 실패 시 즉시 exit 1.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"   # 플러그인 루트 (scripts/의 부모)
SCAFFOLD="$HERE/scripts/scaffold.sh"
PRINCIPLES_SRC="$HERE/coding-principles.md"

pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# --- 케이스 1: 신규 프로젝트 ---
T1="$(mktemp -d)"
OUT="$(CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD")"
echo "[case1] fresh project"
check "principles copied to project"      "[ -f '$T1/coding-principles.md' ]"
check "CLAUDE.md imports principles"       "grep -qxF '@coding-principles.md' '$T1/CLAUDE.md'"
check "CLAUDE.md imports solved"           "grep -qxF '@solved_problems.md' '$T1/CLAUDE.md'"
check "CLAUDE.md imports unsolved"         "grep -qxF '@unsolved_problems.md' '$T1/CLAUDE.md'"
check "managed region present once"        "[ \$(grep -cF '# BEGIN disciplined-coder' '$T1/CLAUDE.md') -eq 1 ]"
check "stdout carries a principle marker"  "printf '%s' \"\$OUT\" | grep -qF '코딩 디시플린'"

# --- 케이스 2: 멱등성 (3회 실행해도 영역 1개) ---
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD" >/dev/null
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD" >/dev/null
echo "[case2] idempotency"
check "still one managed region"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$T1/CLAUDE.md') -eq 1 ]"
check "principles import not duplicated"   "[ \$(grep -cxF '@coding-principles.md' '$T1/CLAUDE.md') -eq 1 ]"

# --- 케이스 3: 기존 CLAUDE.md 본문 보존 + 산문 충돌 무해 ---
T3="$(mktemp -d)"
printf 'preexisting line\nSee @coding-principles.md in prose.\n' > "$T3/CLAUDE.md"
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T3" bash "$SCAFFOLD" >/dev/null
echo "[case3] preserve existing content"
check "existing prose preserved"           "grep -qF 'preexisting line' '$T3/CLAUDE.md'"
check "managed region added once"          "[ \$(grep -cF '# BEGIN disciplined-coder' '$T3/CLAUDE.md') -eq 1 ]"

echo "----"
echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
