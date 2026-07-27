#!/usr/bin/env bash
# codex-scaffold.sh(Codex 셋업) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$HERE/scripts/codex-scaffold.sh"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
run() { CODEX_HOME_DIR="$1/.codex" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD"; }

# 이웃 관계 검사: 파일에서 pattern과 정확히 일치하는 첫 줄 '바로 다음 줄'이 빈 줄인지 확인한다.
# 전역 빈 줄 카운트는 관리블록이 항상 넣는 구분 빈 줄과 뒤섞여 무조건 참이 되므로 쓰지 않는다.
blank_follows() {  # $1=file $2=exact-line-pattern
  awk -v pat="$2" 'matched && !verified { verified=1; if ($0=="") ok=1 } $0==pat { matched=1 } END { exit (ok==1 ? 0 : 1) }' "$1"
}

# JSON 유효성 검사기 — stdin의 JSON을 파싱한다. python3가 존재해도 실행 불능인 머신
# (Windows Store 스텁 등)이 있으므로 프로브는 존재 확인이 아니라 실제 실행으로 한다.
# 폴백 체인: python3 → python → node. 셋 다 없으면 FAIL(조용한 SKIP 금지 — FAIL-LOUD).
json_valid_stdin() {
  if python3 -c 'import sys' >/dev/null 2>&1; then
    python3 -c 'import json,sys; json.load(sys.stdin)'
  elif python -c 'import sys' >/dev/null 2>&1; then
    python -c 'import json,sys; json.load(sys.stdin)'
  elif command -v node >/dev/null 2>&1; then
    node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{JSON.parse(d)})'
  else
    echo "  (json_valid_stdin: python3/python/node 모두 없음 — 검증 불능은 FAIL로 계상)" >&2
    return 1
  fi
}

# --- 케이스 1: 신규 PC ---
H1="$(mktemp -d)"
OUT="$(run "$H1")"
K="$H1/.codex/disciplined-coder"; AG="$H1/.codex/AGENTS.md"
echo "[case1] fresh codex home"
check "principles in codex dir"     "[ -f '$K/agent-principles.md' ]"
check "domains-index in codex dir"  "[ -f '$K/domains-index.md' ]"
check "solved created"              "[ -f '$K/solved_problems.md' ]"
check "AGENTS.md has managed begin" "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"
check "AGENTS.md inlines principles" "grep -qF '# Discipline (Team Principles)' '$AG'"
check "stdout injects principles"   "printf '%s' \"\$OUT\" | grep -qF '# Discipline (Team Principles)'"

# --- 케이스 2: 멱등성(3회) ---
run "$H1" >/dev/null; run "$H1" >/dev/null
echo "[case2] idempotency"
check "still one managed region"    "[ \$(grep -cF '# BEGIN disciplined-coder' '$AG') -eq 1 ]"

# --- 케이스 3: 기존 AGENTS.md 내용 보존 + 블랭크 비누적 (문단 사이 빈 줄 포함) ---
# 픽스처가 한 줄짜리면 빈 줄 삭제 회귀를 구조적으로 통과시키므로, 문단 둘 사이에 빈 줄을 끼운다
# (design spec 2026-07-27 테스트 절 — codex-scaffold.sh 경로도 scaffold.sh와 같은 것을 검증).
H3="$(mktemp -d)"; mkdir -p "$H3/.codex"
printf 'para one\n\npara two\n' > "$H3/.codex/AGENTS.md"
for _ in 1 2 3; do run "$H3" >/dev/null; done
AG3="$H3/.codex/AGENTS.md"
echo "[case3] preserve user content (blank line between paragraphs)"
check "para one preserved"          "grep -qxF 'para one' '$AG3'"
check "para two preserved"          "grep -qxF 'para two' '$AG3'"
check "blank line right after para one preserved" "blank_follows '$AG3' 'para one'"
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

# --- 케이스 6: 홈 해석이 bash $HOME에 의존하지 않음 (CODEX_HOME env 우선) ---
H6C="$(mktemp -d)/ch"; HJUNK="$(mktemp -d)"
OUT6="$(HOME="$HJUNK" CODEX_HOME="$H6C" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD")"
echo "[case6] home resolution honors CODEX_HOME, not bash \$HOME"
check "CODEX_HOME honored (KDIR)"    "[ -f '$H6C/disciplined-coder/agent-principles.md' ]"
check "did not fall back to bash \$HOME" "[ ! -d '$HJUNK/.codex' ]"

# --- 케이스 7: 오답노트 처분 모드 미러(codex 자기 홈) ---
H7="$(mktemp -d)"; K7="$H7/.codex/disciplined-coder"
echo "[case7] issue-mode mirror"
OUT7a="$(run "$H7")"
check "issue-mode created = surface"   "[ \"\$(cat '$K7/issue-mode')\" = surface ]"
check "mode line injected (surface)"   "printf '%s' \"\$OUT7a\" | grep -qF '처분 모드: surface'"
check "first-install note injected"    "printf '%s' \"\$OUT7a\" | grep -qF '시작했다'"
printf 'issues\n' > "$K7/issue-mode"
OUT7b="$(run "$H7")"
check "issues mode injected"           "printf '%s' \"\$OUT7b\" | grep -qF '처분 모드: issues'"
ERR7="$(run "$H7" 2>&1 >/dev/null)" || true
check "issue-mode not hygiene-flagged" "! printf '%s' \"\$ERR7\" | grep -qF '비관리 파일'"

# --- 케이스 8: 관리 디렉터리 위생 — 하위 디렉터리에서 중단되지 않는다 ---
mkdir -p "$K/rogue_dir"
set +e
ERR8c="$(run "$H1" 2>&1 >/dev/null)"; rc8c=$?
set -e
echo "[case8] hygiene: subdir must not abort"
check "subdir does not abort codex scaffold" "[ $rc8c -eq 0 ]"
check "subdir surfaced to stderr"            "printf '%s' \"\$ERR8c\" | grep -qF 'rogue_dir'"
# 의도적 비대칭(spec 2026-07-03): Codex에는 Workflow 도구가 없어 ultracode-review를 미러하지 않는다.
check "ultracode-review not mirrored to codex" "[ ! -f '$K/ultracode-review' ]"

echo "[manifest + session hook]"
SS="$HERE/hooks/session-start-codex"
check "session-start-codex emits additionalContext" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | grep -q additionalContext"
check "session-start-codex warns about trust review" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | grep -qF '신뢰'"
check "session-start-codex stdout is valid JSON" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$HERE\" bash '$SS' | json_valid_stdin"
check ".codex-plugin manifest is valid JSON" "json_valid_stdin < '$HERE/.codex-plugin/plugin.json'"
check "hooks-codex.json is valid JSON"       "json_valid_stdin < '$HERE/hooks/hooks-codex.json'"
check "hooks-codex wires apply_patch matcher" "grep -qF 'apply_patch' '$HERE/hooks/hooks-codex.json'"
check "manifest points skills + codex hooks"  "grep -qF 'hooks-codex.json' '$HERE/.codex-plugin/plugin.json'"
# FAIL-LOUD: scaffold의 stderr 진단이 훅에서 삼켜지면 안 된다.
EDIR="$(mktemp -d)"   # 정본 없는 plugin root → scaffold가 WARNING을 stderr로 낸다
check "session hook relays scaffold stderr" "CODEX_HOME_DIR=\"$(mktemp -d)/.codex\" CLAUDE_PLUGIN_ROOT=\"$EDIR\" bash '$SS' 2>&1 >/dev/null | grep -qF 'WARNING'"
# 실패 시 원인 문자열이 주입 컨텍스트에 포함되고, 출력은 여전히 유효한 JSON이어야 한다.
TF="$(mktemp)"        # 파일 아래 경로 → mkdir -p 실패 → scaffold 비정상 종료
OUTF="$(CODEX_HOME_DIR="$TF/.codex" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SS" 2>/dev/null)"
check "session hook surfaces failure cause"    "printf '%s' \"\$OUTF\" | grep -qF 'scaffold error:'"
check "failure output is still valid JSON"     "printf '%s' \"\$OUTF\" | json_valid_stdin"

# --- 케이스 9: 이중 주입 회귀 가드 — 2회차 stdout은 AGENTS.md 인라인분(principles+domains)을 재전송하지 않는다 ---
# 배경: 섹션 3(AGENTS.md 인라인)과 섹션 4(stdout 주입)가 같은 두 파일을 중복 전송하던 결함의 회귀 가드.
# had_inline 판정 덕에 첫 설치 세션만 stdout에도 실리고, 그 다음부터는 인라인(AGENTS.md)에만 남는다.
H9="$(mktemp -d)"; K9="$H9/.codex/disciplined-coder"; AG9="$H9/.codex/AGENTS.md"
OUT9a="$(run "$H9")"
OUT9b="$(run "$H9")"
echo "[case9] no duplicate injection after first install"
check "first run stdout has principles"       "printf '%s' \"\$OUT9a\" | grep -qF '# Discipline (Team Principles)'"
check "second run stdout lacks principles"    "! printf '%s' \"\$OUT9b\" | grep -qF '# Discipline (Team Principles)'"
check "second run stdout lacks domains-index" "! printf '%s' \"\$OUT9b\" | grep -qF '# Domain Reference Index'"
check "second run stdout still has solved"    "printf '%s' \"\$OUT9b\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "second run stdout still has mode line" "printf '%s' \"\$OUT9b\" | grep -qF '처분 모드:'"
check "AGENTS.md still inlines principles after 2nd run" "grep -qF '# Discipline (Team Principles)' '$AG9'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
