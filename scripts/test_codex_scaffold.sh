#!/usr/bin/env bash
# codex-scaffold.sh(Codex 셋업) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$HERE/scripts/codex-scaffold.sh"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
run() { CODEX_HOME_DIR="$1/.codex" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD"; }

# --- 케이스 1: 신규 PC ---
H1="$(mktemp -d)"
OUT="$(run "$H1")"
K="$H1/.codex/disciplined-coder"; AG="$H1/.codex/AGENTS.md"
echo "[case1] fresh codex home"
check "principles in codex dir"     "[ -f '$K/agent-principles.md' ]"
check "domains-index in codex dir"  "[ -f '$K/domains-index.md' ]"
check "solved created"              "[ -f '$K/solved_problems.md' ]"
check "unsolved created"            "[ -f '$K/unsolved_problems.md' ]"
check "AGENTS.md has managed begin" "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"
check "AGENTS.md inlines principles" "grep -qF '디시플린' '$AG'"
check "stdout injects principles"   "printf '%s' \"\$OUT\" | grep -qF '디시플린'"

# --- 케이스 2: 멱등성(3회) ---
run "$H1" >/dev/null; run "$H1" >/dev/null
echo "[case2] idempotency"
check "still one managed region"    "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"

# --- 케이스 3: 기존 AGENTS.md 내용 보존 + 블랭크 비누적 ---
H3="$(mktemp -d)"; mkdir -p "$H3/.codex"; printf 'my codex note\n' > "$H3/.codex/AGENTS.md"
for _ in 1 2 3; do run "$H3" >/dev/null; done
AG3="$H3/.codex/AGENTS.md"
echo "[case3] preserve user content"
check "user note preserved"         "grep -qxF 'my codex note' '$AG3'"
check "one region after 3 runs"     "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG3') -eq 1 ]"

# --- 케이스 4: solved 누적 보존 ---
echo "[case4] solved preserved"
printf '\n- codex 보존 확인\n' >> "$K/solved_problems.md"
run "$H1" >/dev/null
check "solved entry preserved"      "grep -qF 'codex 보존 확인' '$K/solved_problems.md'"

# --- 케이스 5: CRLF 관리영역 인식(중복 안 됨) ---
H5="$(mktemp -d)"; mkdir -p "$H5/.codex"
printf 'note\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@old\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H5/.codex/AGENTS.md"
run "$H5" >/dev/null
echo "[case5] CRLF region recognized"
check "CRLF region not duplicated"  "[ \$(grep -cF '# BEGIN disciplined-coder' '$H5/.codex/AGENTS.md') -eq 1 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
