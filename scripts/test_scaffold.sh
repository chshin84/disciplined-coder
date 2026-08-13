#!/usr/bin/env bash
# scaffold.sh(PC-레벨) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCAFFOLD="$HERE/scripts/scaffold.sh"

pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# 이웃 관계 검사: 파일에서 pattern과 정확히 일치하는 첫 줄 '바로 다음 줄'이 빈 줄인지 확인한다.
# 전역 grep -c '^$' 카운트는 관리블록이 항상 넣는 구분 빈 줄과 뒤섞여 무조건 참이 되므로 쓰지 않는다.
blank_follows() {  # $1=file $2=exact-line-pattern
  awk -v pat="$2" 'matched && !verified { verified=1; if ($0=="") ok=1 } $0==pat { matched=1 } END { exit (ok==1 ? 0 : 1) }' "$1"
}

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
check "stdout has principle marker"   "printf '%s' \"\$OUT\" | grep -qF '# 디시플린 (팀 원칙)'"
check "stdout has solved marker"      "printf '%s' \"\$OUT\" | grep -qF '해결된 문제 로그 (solved_problems)'"

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

# --- 케이스 7b: 깨진 관리영역 2회차 실행 — 1회차가 다음 실행의 파괴를 준비하면 안 된다 ---
ERR7b="$(run "$H7" "$P7" 2>&1 >/dev/null)" || true
echo "[case7b] malformed region 2nd run → still non-destructive"
check "2nd run: user content preserved"    "grep -qxF 'IMPORTANT user content after malformed begin' '$UC7'"
check "2nd run: pre-region note preserved" "grep -qxF 'note before' '$UC7'"
check "2nd run: single managed region"     "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC7') -eq 1 ]"

# --- 케이스 8: 정본 소스 부재 → FAIL-LOUD 경고(stderr) + 계속 진행(exit 0) ---
H8="$(mktemp -d)"; P8="$(mktemp -d)"; ED="$(mktemp -d)"   # ED = 정본 없는 빈 plugin root
set +e
ERR8="$(CLAUDE_HOME_DIR="$H8/.claude" CLAUDE_PROJECT_DIR="$P8" CLAUDE_PLUGIN_ROOT="$ED" bash "$SCAFFOLD" 2>&1 >/dev/null)"; rc8=$?
set -e
echo "[case8] missing source → FAIL-LOUD warning, exit 0"
check "missing source warns to stderr"      "printf '%s' \"\$ERR8\" | grep -qF 'WARNING: source not found'"
check "missing source still exit 0"         "[ $rc8 -eq 0 ]"

# --- 케이스 9: 홈 해석이 bash $HOME에 의존하지 않음 (CLAUDE_CONFIG_DIR 우선) ---
# AD 리다이렉트 홈(예: $HOME=U:\ 네트워크 드라이브)에서 Claude Code 실제 홈(USERPROFILE/CLAUDE_CONFIG_DIR)과
# 어긋나던 버그 회귀 방지. 임시 HOME을 줘서 실패 시에도 실제 ~/.claude를 오염시키지 않는다.
H9="$(mktemp -d)/cfg"; P9="$(mktemp -d)"; HJUNK="$(mktemp -d)"
OUT9="$(HOME="$HJUNK" CLAUDE_CONFIG_DIR="$H9" CLAUDE_PROJECT_DIR="$P9" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD")"
echo "[case9] home resolution honors CLAUDE_CONFIG_DIR, not bash \$HOME"
check "CLAUDE_CONFIG_DIR honored (KDIR)"     "[ -f '$H9/disciplined-coder/agent-principles.md' ]"
check "CLAUDE_CONFIG_DIR honored (CLAUDE.md)" "[ -f '$H9/CLAUDE.md' ]"
check "did not fall back to bash \$HOME"      "[ ! -d '$HJUNK/.claude' ]"

# --- 케이스 10: 관리 디렉터리 위생 — 구 관리파일 제거·정본/사용자데이터 보존·빈 고아 제거 ---
H10="$(mktemp -d)"; P10="$(mktemp -d)"
run "$H10" "$P10" >/dev/null
K10="$H10/.claude/disciplined-coder"
printf 'old canon\n'    > "$K10/coding-principles.md"     # 구 관리파일(STALE) → 제거
printf '내 미해결 메모\n' > "$K10/unsolved_problems.md"   # 사용자 데이터(내용 있음) → 보존 + surface
: > "$K10/orphan_empty.md"                                 # 빈 고아 → 제거
mkdir -p "$K10/rogue_dir"                                  # 하위 디렉터리 → 중단 없이 surface
set +e
ERR10="$(run "$H10" "$P10" 2>&1 >/dev/null)"; rc10=$?
set -e
echo "[case10] managed-dir hygiene (whitelist pruning)"
check "stale coding-principles pruned"  "[ ! -f '$K10/coding-principles.md' ]"
check "canon preserved"                 "[ -f '$K10/agent-principles.md' ]"
check "solved preserved"                "[ -f '$K10/solved_problems.md' ]"
check "user data (unsolved) preserved"  "[ -f '$K10/unsolved_problems.md' ]"
check "empty orphan removed"            "[ ! -f '$K10/orphan_empty.md' ]"
check "non-empty orphan surfaced"       "printf '%s' \"\$ERR10\" | grep -qF 'unsolved_problems.md'"
check "subdir does not abort scaffold"  "[ $rc10 -eq 0 ]"
check "subdir surfaced to stderr"       "printf '%s' \"\$ERR10\" | grep -qF 'rogue_dir'"
check "subdir preserved"                "[ -d '$K10/rogue_dir' ]"

# --- 케이스 12: 오답노트 처분 모드 (issue-mode) ---
IM="$HERE/scripts/issue-mode.sh"
H12="$(mktemp -d)"; P12="$(mktemp -d)"; K12="$H12/.claude/disciplined-coder"
echo "[case12] issue-mode default + inject + toggle"
# 12a) 부재 → surface 결정론적 생성 + 모드 주입 + 첫설치 안내
OUT12a="$(run "$H12" "$P12")"
check "issue-mode created = surface"      "[ \"\$(cat '$K12/issue-mode')\" = surface ]"
check "mode line injected (surface)"      "printf '%s' \"\$OUT12a\" | grep -qF '처분 모드: surface'"
check "first-install note injected"       "printf '%s' \"\$OUT12a\" | grep -qF '시작했다'"
# 12b) 2회차 → 안내 미반복 + issue-mode 위생 무경고(화이트리스트)
ERR12b="$(run "$H12" "$P12" 2>&1 >/dev/null)" || true
OUT12b="$(run "$H12" "$P12")"
check "note not repeated (config exists)" "! printf '%s' \"\$OUT12b\" | grep -qF '시작했다'"
check "issue-mode not hygiene-flagged"    "! printf '%s' \"\$ERR12b\" | grep -qF '비관리 파일'"
# 12c) issues 모드 → issues 주입
printf 'issues\n' > "$K12/issue-mode"
OUT12c="$(run "$H12" "$P12")"
check "issues mode injected"              "printf '%s' \"\$OUT12c\" | grep -qF '처분 모드: issues'"
# 12d) 불명값 → surface 폴백 + 경고
printf 'xyz\n' > "$K12/issue-mode"
ERR12d="$(run "$H12" "$P12" 2>&1 >/dev/null)" || true
OUT12d="$(run "$H12" "$P12")"
check "unknown value warns"               "printf '%s' \"\$ERR12d\" | grep -qF '불명값'"
check "unknown falls back to surface"     "printf '%s' \"\$OUT12d\" | grep -qF '처분 모드: surface'"
# 12e) /issue-mode set/show/reject/자기완결
HC="$(mktemp -d)/cfg"
CLAUDE_HOME_DIR="$HC" bash "$IM" issues >/dev/null
check "/issue-mode issues writes config"  "[ \"\$(cat '$HC/disciplined-coder/issue-mode')\" = issues ]"
check "/issue-mode (no arg) shows mode"   "CLAUDE_HOME_DIR='$HC' bash '$IM' | grep -qF issues"
CLAUDE_HOME_DIR="$HC" bash "$IM" surface >/dev/null
check "/issue-mode surface writes config" "[ \"\$(cat '$HC/disciplined-coder/issue-mode')\" = surface ]"
set +e; CLAUDE_HOME_DIR="$HC" bash "$IM" bogus >/dev/null 2>&1; rc12=$?; set -e
check "/issue-mode rejects invalid arg"   "[ $rc12 -ne 0 ]"
HF="$(mktemp -d)/fresh"
CLAUDE_HOME_DIR="$HF" bash "$IM" issues >/dev/null
check "/issue-mode self-contained mkdir"  "[ -f '$HF/disciplined-coder/issue-mode' ]"

# --- 케이스 13: README 커맨드 절 ↔ commands/ 디렉터리 드리프트 가드 (SSOT — 열거는 사용 절 한 곳) ---
# 파일 전체가 아니라 '### 커맨드' 절만 검사한다 — 커맨드명이 다른 문단에 등장해
# 목록 누락이 vacuous 통과하는 것을 막는다.
CMD_SECTION="$(awk '/^### 커맨드/{f=1} f&&/^## /{exit} f' "$HERE/README.md")"
echo "[case13] README commands section covers commands/ dir"
for c in "$HERE"/commands/*.md; do
  n="/$(basename "$c" .md)"
  check "README commands section lists $n" "printf '%s' \"\$CMD_SECTION\" | grep -qF -- '$n'"
done

# --- 케이스 14: ultracode 검증 모드 (ultracode-review) — spec 2026-07-03 ---
UR="$HERE/scripts/ultracode-review.sh"
H14="$(mktemp -d)"; P14="$(mktemp -d)"; K14="$H14/.claude/disciplined-coder"
echo "[case14] ultracode-review default + inject + toggle"
# 14a) 부재 → discretion 결정론 생성 + 모드 주입 + 첫설치 안내 + issue-mode와 공존(변수 분리)
OUT14a="$(run "$H14" "$P14")"
check "ultracode-review created = discretion" "[ \"\$(cat '$K14/ultracode-review')\" = discretion ]"
check "ucr mode line injected (discretion)"   "printf '%s' \"\$OUT14a\" | grep -qF '검증 모드: discretion'"
check "ucr first-install note injected"       "printf '%s' \"\$OUT14a\" | grep -qF 'ultracode 검증 모드를 discretion'"
check "both toggles injected (issue-mode too)" "printf '%s' \"\$OUT14a\" | grep -qF '처분 모드: surface'"
# 14b) 2회차 → 안내 미반복 + 위생 무경고(화이트리스트)
ERR14b="$(run "$H14" "$P14" 2>&1 >/dev/null)" || true
OUT14b="$(run "$H14" "$P14")"
check "ucr note not repeated"                 "! printf '%s' \"\$OUT14b\" | grep -qF 'ultracode 검증 모드를 discretion'"
check "ucr file not hygiene-flagged"          "! printf '%s' \"\$ERR14b\" | grep -qF '비관리 파일'"
# 14c) required → required 주입
printf 'required\n' > "$K14/ultracode-review"
OUT14c="$(run "$H14" "$P14")"
check "required mode injected"                "printf '%s' \"\$OUT14c\" | grep -qF '검증 모드: required'"
# 14d) 불명값 → discretion 폴백 + 경고
printf 'zzz\n' > "$K14/ultracode-review"
ERR14d="$(run "$H14" "$P14" 2>&1 >/dev/null)" || true
OUT14d="$(run "$H14" "$P14")"
check "ucr unknown value warns"               "printf '%s' \"\$ERR14d\" | grep -qF '불명값'"
check "ucr unknown falls back to discretion"  "printf '%s' \"\$OUT14d\" | grep -qF '검증 모드: discretion'"
# 14e) /ultracode-review set/show/reject/자기완결 — issue-mode 12e 미러
HC14="$(mktemp -d)/cfg"
CLAUDE_HOME_DIR="$HC14" bash "$UR" required >/dev/null
check "/ultracode-review required writes"     "[ \"\$(cat '$HC14/disciplined-coder/ultracode-review')\" = required ]"
check "/ultracode-review (no arg) shows mode" "CLAUDE_HOME_DIR='$HC14' bash '$UR' | grep -qF required"
CLAUDE_HOME_DIR="$HC14" bash "$UR" discretion >/dev/null
check "/ultracode-review discretion writes"   "[ \"\$(cat '$HC14/disciplined-coder/ultracode-review')\" = discretion ]"
set +e; CLAUDE_HOME_DIR="$HC14" bash "$UR" bogus >/dev/null 2>&1; rc14=$?; set -e
check "/ultracode-review rejects invalid arg" "[ $rc14 -ne 0 ]"
HF14="$(mktemp -d)/fresh"
CLAUDE_HOME_DIR="$HF14" bash "$UR" required >/dev/null
check "/ultracode-review self-contained mkdir" "[ -f '$HF14/disciplined-coder/ultracode-review' ]"

# --- 케이스 15: 검증 레이어 표에 워크플로 검증 행 존재(정본 계약 가드 — spec 검증 기준) ---
# 파일 전역 grep이 아니라 트리거 문자열이 있는 '그 행 한 줄'을 뽑아 검사한다 — 호출자 열(reviewer-*)과
# 강제 방식 열이 같은 행에 있음을 보장한다(다른 행·다른 파일의 문자열로 vacuous 통과 방지).
WF_ROW="$(grep -F '멀티에이전트 워크플로 작성·실행' "$HERE/agent-principles.md" || true)"
echo "[case15] principles table has workflow verification row"
check "row exists (trigger)"       "[ -n \"\$WF_ROW\" ]"
check "row caller = reviewer-*"    "printf '%s' \"\$WF_ROW\" | grep -qF 'reviewer-*'"
check "row enforcement = toggle"   "printf '%s' \"\$WF_ROW\" | grep -qF 'ultracode 검증 모드'"

# --- 케이스 18: 손상된 관리영역 자기 치유 (실측 ~/.claude/CLAUDE.md 모양 재현) ---
# 고아 무해화 주석이 여는 마커 자리를 대신한 반복 블록 + 짝 없는 END + 사용자 줄.
# 계약: 관리영역 1개, 고아 주석 0, 짝 없는 마커 0, 사용자 줄 보존, 본문 줄은 삭제 대상 아님.
H18="$(mktemp -d)"; P18="$(mktemp -d)"; mkdir -p "$H18/.claude"
{ printf '\n\n'
  printf '# END disciplined-coder (managed — do not edit)\n\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n\n'
  printf '# (disciplined-coder: orphan BEGIN neutralized — END missing)\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n\n'
  printf 'MY OWN GLOBAL NOTE\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$H18/.claude/CLAUDE.md"
run "$H18" "$P18" >/dev/null
UC18="$H18/.claude/CLAUDE.md"
echo "[case18] corrupted region self-heals"
check "one BEGIN after heal"          "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC18') -eq 1 ]"
check "one END after heal"            "[ \$(grep -cF '# END disciplined-coder' '$UC18') -eq 1 ]"
check "no orphan marker left"         "! grep -qF 'orphan BEGIN neutralized' '$UC18'"
check "user note preserved"           "grep -qxF 'MY OWN GLOBAL NOTE' '$UC18'"
run "$H18" "$P18" >/dev/null
check "still one BEGIN (idempotent)"  "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC18') -eq 1 ]"
check "user note still there"         "grep -qxF 'MY OWN GLOBAL NOTE' '$UC18'"

# --- 케이스 19: 고아 여는 마커 뒤 본문은 한 줄도 지우지 않는다 (빈 줄 포함) ---
H19="$(mktemp -d)"; P19="$(mktemp -d)"; mkdir -p "$H19/.claude"
{ printf 'head note\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf 'para one\n'
  printf '\n'
  printf 'para two\n'
} > "$H19/.claude/CLAUDE.md"
ERR19="$(run "$H19" "$P19" 2>&1 >/dev/null)" || true
UC19="$H19/.claude/CLAUDE.md"
echo "[case19] orphan opener drops only its own line"
check "orphan: head preserved"        "grep -qxF 'head note' '$UC19'"
check "orphan: para one preserved"    "grep -qxF 'para one' '$UC19'"
check "orphan: para two preserved"    "grep -qxF 'para two' '$UC19'"
check "orphan: blank line right after para one preserved" "blank_follows '$UC19' 'para one'"
check "orphan: warns BEGIN w/o END"   "printf '%s' \"\$ERR19\" | grep -qF 'BEGIN but no END'"
check "orphan: marker line gone"      "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC19') -eq 1 ]"

# --- 케이스 20: 정본 stdout 덤프는 첫 설치 세션에만 (이중 주입 회귀 가드) ---
H20="$(mktemp -d)"; P20="$(mktemp -d)"
OUT20a="$(run "$H20" "$P20")"
OUT20b="$(run "$H20" "$P20")"
echo "[case20] canon dumped on first run only"
check "1st run dumps principles"      "printf '%s' \"\$OUT20a\" | grep -qF '# 디시플린 (팀 원칙)'"
check "1st run dumps solved"          "printf '%s' \"\$OUT20a\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "2nd run omits principles"      "! printf '%s' \"\$OUT20b\" | grep -qF '# 디시플린 (팀 원칙)'"
check "2nd run omits solved"          "! printf '%s' \"\$OUT20b\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "2nd run keeps issue mode line" "printf '%s' \"\$OUT20b\" | grep -qF '처분 모드:'"
check "2nd run keeps ucr mode line"   "printf '%s' \"\$OUT20b\" | grep -qF '검증 모드:'"

# --- 케이스 21: CRLF 관리영역에서도 재주입하지 않는다 (had_import의 CR 내성) ---
H21="$(mktemp -d)"; P21="$(mktemp -d)"; mkdir -p "$H21/.claude"
printf '# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/agent-principles.md\r\n@disciplined-coder/domains-index.md\r\n@disciplined-coder/solved_problems.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H21/.claude/CLAUDE.md"
OUT21="$(run "$H21" "$P21")"
echo "[case21] CRLF import line still counts as present"
check "CRLF: no canon re-dump"        "! printf '%s' \"\$OUT21\" | grep -qF '# 디시플린 (팀 원칙)'"
check "CRLF: no solved re-dump"       "! printf '%s' \"\$OUT21\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "CRLF: mode line still sent"    "printf '%s' \"\$OUT21\" | grep -qF '처분 모드:'"

# --- 케이스 16: 병렬 오케스트레이션 넛지(정본 계약 가드) ---
# 병렬 오케스트레이션 헤딩부터 다음 '### ' 또는 '## '까지의 블록만 뽑아 그 안에서 검사한다
# (vacuous 통과 방지).
PO_BLOCK="$(awk '/^### 병렬 오케스트레이션/{f=1} f&&/^### /&&!/^### 병렬 오케스트레이션/{exit} f&&/^## /&&!/^### /{exit} f' "$HERE/agent-principles.md")"
echo "[case16] principles 병렬 오케스트레이션 nested-orchestration nudge"
check "병렬 오케스트레이션 heading exists"      "printf '%s' \"\$PO_BLOCK\" | grep -qF '### 병렬 오케스트레이션'"
check "병렬 오케스트레이션 points to skill (SSOT)" "printf '%s' \"\$PO_BLOCK\" | grep -qF 'nested-orchestration'"
check "병렬 오케스트레이션 routes single-task to 2층" "printf '%s' \"\$PO_BLOCK\" | grep -qF 'dispatching-parallel-agents'"

# --- 케이스 17: nested-orchestration 스킬 존재 + 핵심 절(정본 계약 가드) ---
# 단일 목적 파일이라 파일 전역 존재 검사로 충분하다(섹션 경합 없음 — Global Constraint 참조).
NO_SKILL="$HERE/skills/nested-orchestration/SKILL.md"
echo "[case17] nested-orchestration skill present + structured"
check "skill file exists"             "[ -f '$NO_SKILL' ]"
check "frontmatter name correct"      "grep -qE '^name: *nested-orchestration' '$NO_SKILL'"
check "has routing (2층 위임)"         "grep -qF 'dispatching-parallel-agents' '$NO_SKILL'"
check "has L2 template ownership blk"  "grep -qF '구간 소유권(엄수)' '$NO_SKILL'"
check "has output contract blk"        "grep -qF '산출 계약' '$NO_SKILL'"
check "points to SDD (no reimpl)"      "grep -qF 'subagent-driven-development' '$NO_SKILL'"

# --- 케이스 22: 인접 여는 마커 가드 — 첫 BEGIN이 뒤쪽 닫는 마커까지 훑어 사용자 줄을 삼키면 안 된다 ---
# 모양: 여는마커 / 사용자줄 / 여는마커 / 본문 / 닫는마커. _managed_block.sh 내부 while 루프의
# "다음 여는 마커를 만나면 멈춘다" 가드가 없으면, 첫 BEGIN(고아)이 END 탐색을 두 번째 BEGIN 너머까지
# 계속해 사이에 낀 사용자 줄까지 완결 영역으로 오판해 통째로 삭제한다.
H22="$(mktemp -d)"; P22="$(mktemp -d)"; mkdir -p "$H22/.claude"
{ printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf 'USER LINE BETWEEN TWO OPENERS\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$H22/.claude/CLAUDE.md"
run "$H22" "$P22" >/dev/null
UC22="$H22/.claude/CLAUDE.md"
echo "[case22] adjacent opening-marker guard: inner scan must not skip past a second opener"
check "user line between two openers preserved" "grep -qxF 'USER LINE BETWEEN TWO OPENERS' '$UC22'"
check "single managed region after run"         "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC22') -eq 1 ]"

# --- canon-sections: 절차 절을 번호가 아니라 이름으로 부른다 (CLEAR-COMM) ---
# 번호는 항목을 지우거나 끼워 넣는 순간 가리키는 대상이 달라져 조용히 어긋난다. 제목에 이미 이름이
# 있으므로 그 이름으로 부르고, 옛 서수 제목이 되살아나지 않는지 함께 본다.
CANON="$HERE/agent-principles.md"
echo "[canon-sections] procedure sections are named, not numbered"
for s in "검증 레이어" "설계 입력" "오답노트" "문서·상태 위생" "병렬 오케스트레이션"; do
  check "canon: section '$s' present"      "grep -qF '### $s' '$CANON'"
done
# 한글 탐지는 반드시 UTF-8 로케일에서 한다. 기본 C 로케일의 grep은 대괄호 범위를 바이트로 대조해
# 한글을 문자 단위로 매치하지 못하고, 그러면 옛 서수 제목이 되살아나도 이 검사가 잡지 못한다.
check "canon: no ordinal sections left"    "! LC_ALL=C.UTF-8 grep -qE '^### [가나다라마]\.' '$CANON'"

# --- section-refs: 옛 절 참조가 남지 않았다 (git 추적 파일, 스펙 아카이브 제외) ---
# 절을 한글 순서 기호로 가리키던 옛 참조는 어디에도 남으면 안 된다. 이름이 바뀌었기 때문이다.
# 이 검사도 위와 같은 로케일 함정을 밟으므로 반드시 UTF-8 로케일에서 돌린다.
# 이 주석 자체가 검색 패턴과 겹치지 않게 쓴다 — 겹치면 검사가 스스로를 잡아 영원히 FAIL한다.
echo "[section-refs] no dangling ordinal references"
STALE="$(cd "$HERE" && export LC_ALL=C.UTF-8 && git ls-files -z | xargs -0 grep -l '§[가나다라마]\|절차 [가나다라마]' 2>/dev/null | grep -v '^docs/superpowers/' || true)"
check "refs: none dangling"                "[ -z \"\$STALE\" ]"

# --- reach-claims: 무조건적 도달 단정과 @import 오해 표현이 남지 않았다 ---
# 정확 문자열 하나만 보면 나머지가 거짓인 채로 초록이 되므로 실측한 표현을 배열로 모두 검사한다.
# 이 배열이 금지 표현군의 정본이다(스펙의 표는 당시 기록일 뿐 대조 대상이 아니다).
# 패턴에 백틱이 들어가므로 반드시 작은따옴표 배열로 두고 grep -qF -- 로 넘긴다.
REACH_DOCS=("$HERE/README.md" "$HERE/docs/DESIGN-NOTES.md")
REACH_BANNED=(
  '모든 프로젝트와 서브에이전트에 걸쳐'
  '메인 + 모든 서브에이전트 도달'
  '모든 세션·서브에이전트가 같은 디시플린'
  '메인과 서브에이전트 모두에 도달한다'
  '메인 세션과 모든 서브에이전트가'
  '모든 서브에이전트에 전달된다'
  '모든 서브에이전트가 그 오답노트를'
  '매 요청 실어 나른다'
  '매 요청 정본을 실어 준다'
  '새 세션에서만 실행'
)
echo "[reach-claims] no unconditional reach claims remain"
for d in "${REACH_DOCS[@]}"; do
  for p in "${REACH_BANNED[@]}"; do
    check "$(basename "$d"): banned '$p' absent"  "! grep -qF -- '$p' '$d'"
  done
done

# --- reach-facts: 실측 표와 그 대응이 실제로 들어갔다 (지우기만 해도 통과하지 않게 짝을 맞춘다) ---
DN="$HERE/docs/DESIGN-NOTES.md"
echo "[reach-facts] measured table and its consequences are present"
# 두 문자열이 파일 어딘가에 각각 있는지 보면 항진이 된다 — Explore 행을 뒤집어도 옆 행의 문자열이 참을 만든다.
# 그래서 그 행 한 줄을 먼저 뽑고 그 줄 안에서 확인한다(이 파일의 다른 절이 쓰는 방식과 같게).
EXPLORE_ROW="$(grep -F '| `Explore` |' "$DN" || true)"
PLAN_ROW="$(grep -F '| `Plan` |' "$DN" || true)"
check "DESIGN-NOTES: Explore 행을 찾았다"   "[ -n \"\$EXPLORE_ROW\" ]"
check "DESIGN-NOTES: Explore 미도달"        "printf '%s' \"\$EXPLORE_ROW\" | grep -qF '실리지 않는다'"
check "DESIGN-NOTES: Explore 행에 도달 주장 없음" "! printf '%s' \"\$EXPLORE_ROW\" | grep -qE '(^|[^지])실린다'"
check "DESIGN-NOTES: Plan 행 존재"          "[ -n \"\$PLAN_ROW\" ]"
check "DESIGN-NOTES: Plan 미도달"           "printf '%s' \"\$PLAN_ROW\" | grep -qF '실리지 않는다'"
check "DESIGN-NOTES: 재현 절차 존재"        "grep -qF '재현 절차' '$DN'"
# 측정 맥락은 한 줄에 날짜와 런타임 이름이 함께 있어야 한다 — 파일 전역 grep 두 번은 서로를 보증하지 못한다.
check "DESIGN-NOTES: 측정 맥락 한 줄에"     "grep -qE '실측 \(.*Claude Code' '$DN'"
check "DESIGN-NOTES: 옛 근거 문장 제거"     "! grep -qF '공식 문서의 서브에이전트 메모리 로딩 규칙' '$DN'"
check "DESIGN-NOTES: 갱신 시점 항목"        "grep -qF '리로드가 아니라 새 세션' '$DN'"
check "DESIGN-NOTES: 훅 계기는 matcher 정본" "grep -qF 'matcher가 정본' '$DN'"
check "DESIGN-NOTES: 리뷰어 경로 관례"      "grep -qF '실행 시점에 도출한 관리 디렉터리' '$DN'"
check "README: 갈림을 요약하고 링크"        "grep -qF '종류에 따라 갈린다' '$HERE/README.md' && grep -qF 'docs/DESIGN-NOTES.md' '$HERE/README.md'"
check "canon: 옛 도달 전제 제거"            "! grep -qF '서브에이전트도 이 글을 읽으므로' '$CANON'"
check "canon: 도달을 전제하지 않는다"       "grep -qF '도달을 전제하지 않는다' '$CANON'"

# --- reviewer-contract: 읽기 전용 리뷰어를 띄우는 호출자 셋이 같은 계약을 규정한다 ---
echo "[reviewer-contract] callers inject canon path and require principles_applied"
for s in domain-spec-review domain-docs nested-orchestration; do
  F="$HERE/skills/$s/SKILL.md"
  check "$s: 메모리 미가정"                 "grep -qF '메모리 계층을 받는다고 가정하지 마라' '$F'"
  check "$s: 경로를 실행 시점에 도출"       "grep -qF '실행 시점에 도출' '$F'"
  check "$s: principles_applied 요구"       "grep -qF 'principles_applied' '$F'"
  # Codex 패리티: Claude 전용 에이전트 종류 이름과 관리 디렉터리 절대 경로를 박지 않는다.
  check "$s: Claude 전용 종류 이름 없음"    "! grep -qF 'Explore' '$F'"
  check "$s: 관리 디렉터리 절대경로 없음"   "! grep -qF '~/.claude/disciplined-coder/' '$F'"
done
# 렌즈 목록은 손으로 적지 않고 디렉터리에서 도출한다 — 렌즈를 더해도 사람이 목록을 맞출 필요가 없다(SSOT).
for D in "$HERE"/skills/reviewer-*/; do
  l="$(basename "$D" | sed 's/^reviewer-//')"
  F="$D/SKILL.md"
  check "reviewer-$l: SKILL.md 존재"        "[ -f '$F' ]"
  check "reviewer-$l: principles_applied"   "grep -qF 'principles_applied' '$F'"
  check "reviewer-$l: 제품 구현 제외 단서"  "grep -qF '제품 런타임 구현에는 요구하지 않는다' '$F'"
done
check "meta-aggregate: 집계 대상 아님 명시" "grep -qF '집계 대상이 아니다' '$HERE/skills/meta-aggregate/SKILL.md'"

# --- 동시 진입: 창을 여럿 열면 SessionStart가 같은 ~/.claude/CLAUDE.md를 동시에 고친다 ---
# 락이 없던 판본은 사용자 본문을 통째로 잃고 관리블록을 여러 벌 남겼다(실측: 사용자 2줄 → 0줄, 블록 6~11개).
# 순차 멱등성 테스트는 이 경로를 구조적으로 밟지 못하므로 별도로 동시 실행한다.
CT="$(mktemp -d)"; CU="$CT/CLAUDE.md"
printf 'user line one\n\nuser line two\n' > "$CU"
for i in 1 2 3 4 5 6 7 8 9 10; do
  ( . "$HERE/scripts/_managed_block.sh"; printf 'body-%s\n' "$i" | managed_block_inject "$CU" "# BEGIN t" "# END t" ) &
done
wait
check "동시 주입: 사용자 본문 두 줄 보존"   "[ \"\$(grep -c '^user line' '$CU')\" = 2 ]"
check "동시 주입: 관리블록이 정확히 하나"   "[ \"\$(grep -c '^# BEGIN t\$' '$CU')\" = 1 ]"
check "동시 주입: 닫는 마커도 하나"         "[ \"\$(grep -c '^# END t\$' '$CU')\" = 1 ]"
check "동시 주입: 임시 파일 잔여 없음"      "[ -z \"\$(ls '$CT' | grep -v '^CLAUDE.md\$')\" ]"

# --- 매니페스트 version 계약 ---
# Claude 매니페스트는 version을 비워 커밋 SHA 기반 자동 업데이트를 유지한다(domain-plugin·DESIGN-NOTES).
# 값을 넣으면 버전 문자열 비교로 전환돼 값을 올리지 않는 한 새 커밋이 배포되지 않는다. 한 번 넣었다
# 되돌린 이력이 있어 사람 기억에 맡기지 않고 테스트로 고정한다. Codex 매니페스트는 반대로 version을 갖는다.
check "Claude 매니페스트에 version 없음"  "! grep -qE '\"version\"[[:space:]]*:' '$HERE/.claude-plugin/plugin.json'"
check "Codex 매니페스트에 version 있음"   "grep -qE '\"version\"[[:space:]]*:' '$HERE/.codex-plugin/plugin.json'"

# --- solved-rules: 형식 규칙이 낡았으면 알리기만 한다 (읽기 전용 넛지) ---
# 픽스처는 상수(SCAFFOLD_SOLVED_RULES)에서 만들지 않고 리터럴로 적는다 — 상수에서 만들면 상수에 오타가
# 나도 검사가 초록으로 남는 항진 검사가 된다. 옛 로그 픽스처는 실측된 PC 전역 로그의 머리말 모양이다.
NUDGE='형식 규칙 서술이 현행과 다르다'
LOGTITLE='해결된 문제 로그 (solved_problems)'

# (가) 갓 만든 로그는 신호를 내지 않는다 — 생성 템플릿이 곧 현행 규칙이어야 한다.
HR1="$(mktemp -d)"; PR1="$(mktemp -d)"
OUTR1="$(run "$HR1" "$PR1")"
echo "[solved-rules] freshly created log is not flagged"
check "fresh: 신호 없음"                 "! printf '%s' \"\$OUTR1\" | grep -qF '$NUDGE'"
OUTR1b="$(run "$HR1" "$PR1")"
check "fresh: 재실행도 신호 없음"        "! printf '%s' \"\$OUTR1b\" | grep -qF '$NUDGE'"

# (나) 형식 규칙 블록이 없는 옛 로그는 신호를 내고, 파일은 바이트 단위로 그대로다.
HR2="$(mktemp -d)"; PR2="$(mktemp -d)"; mkdir -p "$HR2/.claude/disciplined-coder"
OLDLOG="$HR2/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '작업 중 발견·해결된 문제. 각 항목: 증상/트리거 → 교훈(다음엔 이렇게 — 처방이 앞). 등록은 메인 세션이 수행.\n\n'
  printf -- '- **옛 형식 항목** → 원인: 무엇 → 해결: 무엇\n'
  printf '\n'
  printf -- '- **여러 줄 항목**\n  - 원인: 둘째 줄\n  - 해결: 셋째 줄\n'
  printf '\n'
} > "$OLDLOG"
BEFORE2="$(cksum < "$OLDLOG")"
OUTR2="$(run "$HR2" "$PR2")"
echo "[solved-rules] legacy log (no rule block) is flagged, file untouched"
check "legacy: 신호 있음"                 "printf '%s' \"\$OUTR2\" | grep -qF '$NUDGE'"
check "legacy: 파일 불변(바이트)"         "[ \"\$(cksum < '$OLDLOG')\" = '$BEFORE2' ]"
# 제목 줄 검사는 stdout 전체가 아니라 '신호 문안 그 줄'만 본다 — 첫 설치 세션은 로그 전문을 stdout으로
# 덤프하므로 전체를 보면 그 덤프의 제목 줄에 걸려, 신호와 무관한 이유로 붉어진다.
SIG2="$(printf '%s\n' "$OUTR2" | grep -F "$NUDGE" || true)"
check "legacy: 신호 문안에 제목 줄 없음"  "[ -n \"\$SIG2\" ] && ! printf '%s' \"\$SIG2\" | grep -qF '$LOGTITLE'"
check "legacy: 신호 문안에 원인 단정 없음" "! printf '%s' \"\$SIG2\" | grep -qF '플러그인 업데이트로 바뀌었다'"
check "legacy: 임시 파일 잔해 없음"       "[ -z \"\$(find '$HR2/.claude/disciplined-coder' -name '*.tmp' -o -name '*.norm' 2>/dev/null)\" ]"

# (다) 불릿을 하나 지운 로그도 낡은 것으로 잡는다 — 줄 단위 grep이면 통과해 버리는 자리다.
HR3="$(mktemp -d)"; PR3="$(mktemp -d)"; mkdir -p "$HR3/.claude/disciplined-coder"
run "$HR3" "$PR3" >/dev/null
sed -i '/^- 한 항목은 세 줄을 넘기지 않는다\.$/d' "$HR3/.claude/disciplined-coder/solved_problems.md"
OUTR3="$(run "$HR3" "$PR3")"
echo "[solved-rules] a log missing one rule bullet is flagged"
check "partial: 신호 있음"                "printf '%s' \"\$OUTR3\" | grep -qF '$NUDGE'"

# (라) 스코프 문구가 달라도, 줄 끝이 CRLF여도 오탐하지 않는다.
HR4="$(mktemp -d)"; PR4="$(mktemp -d)"; mkdir -p "$HR4/.claude/disciplined-coder"
run "$HR4" "$PR4" >/dev/null
L4="$HR4/.claude/disciplined-coder/solved_problems.md"
sed -i '1s/.*/# 해결된 문제 로그 — 이 프로젝트 전용 (스코프 문구가 다르다)/' "$L4"
awk '{ printf "%s\r\n", $0 }' "$L4" > "$L4.crlf" && mv "$L4.crlf" "$L4"
OUTR4="$(run "$HR4" "$PR4")"
echo "[solved-rules] different scope prose and CRLF do not false-positive"
check "scope+CRLF: 신호 없음"             "! printf '%s' \"\$OUTR4\" | grep -qF '$NUDGE'"

# (마) 읽을 수 없는 로그를 줘도 훅 전체가 0으로 끝난다(리턴값만 보면 함수 안 실패를 놓친다).
HR5="$(mktemp -d)"; PR5="$(mktemp -d)"; mkdir -p "$HR5/.claude/disciplined-coder"
printf 'x\n' > "$HR5/.claude/disciplined-coder/solved_problems.md"
chmod 000 "$HR5/.claude/disciplined-coder/solved_problems.md" 2>/dev/null || true
set +e; run "$HR5" "$PR5" >/dev/null 2>&1; rc5=$?; set -e
chmod 644 "$HR5/.claude/disciplined-coder/solved_problems.md" 2>/dev/null || true
echo "[solved-rules] hook exits 0 even on unreadable log"
check "unreadable: exit 0"                "[ '$rc5' = '0' ]"

# (바) 위생 검사가 backups/ 를 비관리 디렉터리로 오탐하지 않는다.
HR6="$(mktemp -d)"; PR6="$(mktemp -d)"; mkdir -p "$HR6/.claude/disciplined-coder/backups"
printf 'old\n' > "$HR6/.claude/disciplined-coder/backups/solved_problems-20260728.md"
ERR6="$(CLAUDE_HOME_DIR="$HR6/.claude" CLAUDE_PROJECT_DIR="$PR6" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" 2>&1 >/dev/null)" || true
echo "[solved-rules] backups/ is whitelisted"
check "backups: 오탐 없음"                "! printf '%s' \"\$ERR6\" | grep -qF 'backups'"
check "backups: 사본 보존"                "[ -f '$HR6/.claude/disciplined-coder/backups/solved_problems-20260728.md' ]"

# (사) 정본 트리거와 domain-docs 방법이 실제로 들어갔다.
echo "[solved-rules] canon trigger and domain-docs method exist"
check "canon: 넛지 트리거 구"             "grep -qF '형식 규칙이 낡았다는 신호를 받으면' '$CANON'"
check "canon: 방법 스킬을 가리킴"         "grep -qF 'domain-docs' '$CANON'"
DD="$HERE/skills/domain-docs/SKILL.md"
check "domain-docs: 방법 절 존재"         "grep -qF '관리되는 문서의 형식 규칙이 낡았을 때' '$DD'"
check "domain-docs: 사본 경로"            "grep -qF 'backups/' '$DD'"
check "domain-docs: 항목 불가침"          "grep -qF '항목은 한 줄도 건드리지 않는다' '$DD'"
check "domain-docs: 자동 수정 금지"       "grep -qF '자동으로 고치지 않는다' '$DD'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
