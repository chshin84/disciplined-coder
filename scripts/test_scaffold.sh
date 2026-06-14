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
check "CLAUDE.md does NOT import unsolved" "! grep -qxF '@unsolved_problems.md' '$T1/CLAUDE.md'"
check "unsolved file still created"        "[ -f '$T1/unsolved_problems.md' ]"
check "managed region present once"        "[ \$(grep -cF '# BEGIN disciplined-coder' '$T1/CLAUDE.md') -eq 1 ]"
check "stdout carries a principle marker"  "printf '%s' \"\$OUT\" | grep -qF '코딩 디시플린'"
check "index copied to project"            "[ -f '$T1/advisors-index.md' ]"
check "CLAUDE.md imports index"            "grep -qxF '@advisors-index.md' '$T1/CLAUDE.md'"
check "stdout carries index marker"        "printf '%s' \"\$OUT\" | grep -qF '검증 어드바이저'"

# --- 케이스 2: 멱등성 (3회 실행해도 영역 1개) ---
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD" >/dev/null
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T1" bash "$SCAFFOLD" >/dev/null
echo "[case2] idempotency"
check "still one managed region"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$T1/CLAUDE.md') -eq 1 ]"
check "principles import not duplicated"   "[ \$(grep -cxF '@coding-principles.md' '$T1/CLAUDE.md') -eq 1 ]"
check "index import not duplicated"        "[ \$(grep -cxF '@advisors-index.md' '$T1/CLAUDE.md') -eq 1 ]"

# --- 케이스 3: 기존 CLAUDE.md 본문 보존 + 산문 충돌 무해 ---
T3="$(mktemp -d)"
printf 'preexisting line\nSee @coding-principles.md in prose.\n' > "$T3/CLAUDE.md"
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T3" bash "$SCAFFOLD" >/dev/null
echo "[case3] preserve existing content"
check "existing prose preserved"           "grep -qF 'preexisting line' '$T3/CLAUDE.md'"
check "managed region added once"          "[ \$(grep -cF '# BEGIN disciplined-coder' '$T3/CLAUDE.md') -eq 1 ]"

# --- 케이스 4: src==dst (플러그인 레포 자체) 안전 (cp same-file 비충돌) ---
T4="$(mktemp -d)"
cp "$PRINCIPLES_SRC" "$T4/coding-principles.md"
cp "$HERE/advisors-index.md" "$T4/advisors-index.md"
echo "[case4] src==dst safety"
if CLAUDE_PLUGIN_ROOT="$T4" CLAUDE_PROJECT_DIR="$T4" bash "$SCAFFOLD" >/dev/null 2>&1; then s4ok=1; else s4ok=0; fi
check "same-dir run does not crash"        "[ '$s4ok' -eq 1 ]"
check "same-dir CLAUDE.md has region"      "grep -qF '# BEGIN disciplined-coder' '$T4/CLAUDE.md'"
check "same-dir principles not truncated"  "[ -s '$T4/coding-principles.md' ]"
check "same-dir index not truncated"       "[ -s '$T4/advisors-index.md' ]"

# --- 케이스 5: 블랭크 라인 비누적 (멱등) ---
T5="$(mktemp -d)"
printf 'hello\n' > "$T5/CLAUDE.md"
for _ in 1 2 3; do CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T5" bash "$SCAFFOLD" >/dev/null; done
echo "[case5] no blank-line accumulation"
check "blank lines bounded (<=1) after 3 runs" "[ \$(grep -c '^\$' '$T5/CLAUDE.md') -le 1 ]"
check "user content preserved"              "grep -qxF 'hello' '$T5/CLAUDE.md'"

# --- 케이스 6: CRLF 관리 영역 인식(멱등) ---
T6="$(mktemp -d)"
printf 'user line\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@coding-principles.md\r\n@solved_problems.md\r\n@unsolved_problems.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$T6/CLAUDE.md"
CLAUDE_PLUGIN_ROOT="$HERE" CLAUDE_PROJECT_DIR="$T6" bash "$SCAFFOLD" >/dev/null
echo "[case6] CRLF region recognized"
check "CRLF region not duplicated"         "[ \$(grep -cF '# BEGIN disciplined-coder' '$T6/CLAUDE.md') -eq 1 ]"
check "CRLF user line preserved"           "grep -qF 'user line' '$T6/CLAUDE.md'"

echo "----"
echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
