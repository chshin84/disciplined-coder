#!/usr/bin/env bash
# scaffold.sh(PC-레벨) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$HERE/scripts/scaffold.sh"

pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

run() {  # $1=HOME dir, $2=project dir  → echoes scaffold stdout
  CLAUDE_HOME_DIR="$1/.claude" CLAUDE_PROJECT_DIR="$2" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD"
}

# --- 케이스 1: 신규 PC ---
H1="$(mktemp -d)"; P1="$(mktemp -d)"
OUT="$(run "$H1" "$P1")"
K="$H1/.claude/disciplined-coder"; UC="$H1/.claude/CLAUDE.md"
echo "[case1] fresh PC"
check "principles in PC dir"          "[ -f '$K/coding-principles.md' ]"
check "domains-index in PC dir"       "[ -f '$K/domains-index.md' ]"
check "solved created in PC dir"      "[ -f '$K/solved_problems.md' ]"
check "unsolved created in PC dir"    "[ -f '$K/unsolved_problems.md' ]"
check "user CLAUDE.md imports principles" "grep -qxF '@disciplined-coder/coding-principles.md' '$UC'"
check "user CLAUDE.md imports domains"    "grep -qxF '@disciplined-coder/domains-index.md' '$UC'"
check "user CLAUDE.md imports solved"     "grep -qxF '@disciplined-coder/solved_problems.md' '$UC'"
check "user CLAUDE.md does NOT import unsolved" "! grep -qxF '@disciplined-coder/unsolved_problems.md' '$UC'"
check "managed region once"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "stdout has principle marker"   "printf '%s' \"\$OUT\" | grep -qF '코딩 디시플린'"

# --- 케이스 2: 프로젝트 폴더 무오염 ---
echo "[case2] project untouched"
check "no principles in project"      "[ ! -f '$P1/coding-principles.md' ]"
check "no solved in project"          "[ ! -f '$P1/solved_problems.md' ]"
check "no CLAUDE.md in project"       "[ ! -f '$P1/CLAUDE.md' ]"

# --- 케이스 3: 멱등성 (3회) ---
run "$H1" "$P1" >/dev/null; run "$H1" "$P1" >/dev/null
echo "[case3] idempotency"
check "still one region"              "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "principles import not dup"     "[ \$(grep -cxF '@disciplined-coder/coding-principles.md' '$UC') -eq 1 ]"

# --- 케이스 4: solved 누적 보존 ---
echo "[case4] solved preserved"
printf '\n- 기존 항목 보존 확인\n' >> "$K/solved_problems.md"
run "$H1" "$P1" >/dev/null
check "solved entry preserved"        "grep -qF '기존 항목 보존 확인' '$K/solved_problems.md'"

# --- 케이스 5: 기존 user CLAUDE.md 내용 보존 + 블랭크 비누적 ---
H5="$(mktemp -d)"; P5="$(mktemp -d)"
mkdir -p "$H5/.claude"; printf 'my personal global note\n' > "$H5/.claude/CLAUDE.md"
for _ in 1 2 3; do run "$H5" "$P5" >/dev/null; done
UC5="$H5/.claude/CLAUDE.md"
echo "[case5] preserve user content + no blank accumulation"
check "personal note preserved"      "grep -qxF 'my personal global note' '$UC5'"
check "one region after 3 runs"      "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC5') -eq 1 ]"
check "blank lines bounded (<=1)"    "[ \$(grep -c '^\$' '$UC5') -le 1 ]"

# --- 케이스 6: CRLF 관리영역 인식 ---
H6="$(mktemp -d)"; P6="$(mktemp -d)"; mkdir -p "$H6/.claude"
printf 'note\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/coding-principles.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H6/.claude/CLAUDE.md"
run "$H6" "$P6" >/dev/null
echo "[case6] CRLF region recognized"
check "CRLF region not duplicated"   "[ \$(grep -cF '# BEGIN disciplined-coder' '$H6/.claude/CLAUDE.md') -eq 1 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
