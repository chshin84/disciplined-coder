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
check "principles in PC dir"          "[ -f '$K/agent-principles.md' ]"
check "domains-index in PC dir"       "[ -f '$K/domains-index.md' ]"
check "solved created in PC dir"      "[ -f '$K/solved_problems.md' ]"
check "user CLAUDE.md imports principles" "grep -qxF '@disciplined-coder/agent-principles.md' '$UC'"
check "user CLAUDE.md imports domains"    "grep -qxF '@disciplined-coder/domains-index.md' '$UC'"
check "user CLAUDE.md imports solved"     "grep -qxF '@disciplined-coder/solved_problems.md' '$UC'"
check "managed region once"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "stdout has principle marker"   "printf '%s' \"\$OUT\" | grep -qF '디시플린'"

# --- 케이스 2: 프로젝트 폴더 무오염 ---
echo "[case2] project untouched"
check "no principles in project"      "[ ! -f '$P1/agent-principles.md' ]"
check "no solved in project"          "[ ! -f '$P1/solved_problems.md' ]"
check "no CLAUDE.md in project"       "[ ! -f '$P1/CLAUDE.md' ]"

# --- 케이스 3: 멱등성 (3회) ---
run "$H1" "$P1" >/dev/null; run "$H1" "$P1" >/dev/null
echo "[case3] idempotency"
check "still one region"              "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "principles import not dup"     "[ \$(grep -cxF '@disciplined-coder/agent-principles.md' '$UC') -eq 1 ]"

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
printf 'note\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/agent-principles.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H6/.claude/CLAUDE.md"
run "$H6" "$P6" >/dev/null
echo "[case6] CRLF region recognized"
check "CRLF region not duplicated"   "[ \$(grep -cF '# BEGIN disciplined-coder' '$H6/.claude/CLAUDE.md') -eq 1 ]"

# --- 케이스 7: 깨진 관리영역(BEGIN 있고 END 없음) → 비파괴 스킵(strip 안 함) ---
H7="$(mktemp -d)"; P7="$(mktemp -d)"; mkdir -p "$H7/.claude"
{ printf 'note before\n'; printf '# BEGIN disciplined-coder (managed — do not edit)\n'; \
  printf '@disciplined-coder/agent-principles.md\n'; printf 'IMPORTANT user content after malformed begin\n'; } > "$H7/.claude/CLAUDE.md"
ERR7="$(run "$H7" "$P7" 2>&1 >/dev/null)" || true
UC7="$H7/.claude/CLAUDE.md"
echo "[case7] malformed region (BEGIN w/o END) → non-destructive"
check "malformed: user content preserved"  "grep -qxF 'IMPORTANT user content after malformed begin' '$UC7'"
check "malformed: pre-region note preserved" "grep -qxF 'note before' '$UC7'"
check "malformed: warns BEGIN without END"  "printf '%s' \"\$ERR7\" | grep -qF 'BEGIN but no END'"
check "malformed: complete region appended" "[ \$(grep -cF '# END disciplined-coder' '$UC7') -ge 1 ]"

# --- 케이스 8: 정본 소스 부재 → FAIL-LOUD 경고(stderr) + 계속 진행(exit 0) ---
H8="$(mktemp -d)"; P8="$(mktemp -d)"; ED="$(mktemp -d)"   # ED = 정본 없는 빈 plugin root
set +e
ERR8="$(CLAUDE_HOME_DIR="$H8/.claude" CLAUDE_PROJECT_DIR="$P8" CLAUDE_PLUGIN_ROOT="$ED" bash "$SCAFFOLD" 2>&1 >/dev/null)"; rc8=$?
set -e
echo "[case8] missing source → FAIL-LOUD warning, exit 0"
check "missing source warns to stderr"      "printf '%s' \"\$ERR8\" | grep -qF 'WARNING: source not found'"
check "missing source still exit 0"         "[ $rc8 -eq 0 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
