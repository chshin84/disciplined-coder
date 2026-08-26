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

# --- fresh-pc: 신규 PC ---
H1="$(mktemp -d)"; P1="$(mktemp -d)"
OUT="$(run "$H1" "$P1")"
K="$H1/.claude/disciplined-coder"; UC="$H1/.claude/CLAUDE.md"
echo "[fresh-pc] fresh PC"
check "principles in PC dir"          "[ -f '$K/agent-principles.md' ]"
check "domains-index in PC dir"       "[ -f '$K/domains-index.md' ]"
check "solved created in PC dir"      "[ -f '$K/solved_problems.md' ]"
check "user CLAUDE.md imports principles" "grep -qxF '@disciplined-coder/agent-principles.md' '$UC'"
check "user CLAUDE.md imports domains"    "grep -qxF '@disciplined-coder/domains-index.md' '$UC'"
check "user CLAUDE.md imports solved"     "grep -qxF '@disciplined-coder/solved_problems.md' '$UC'"
check "managed region once"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "stdout has principle marker"   "printf '%s' \"\$OUT\" | grep -qF '# 디시플린 (팀 원칙)'"
check "stdout has solved marker"      "printf '%s' \"\$OUT\" | grep -qF '해결된 문제 로그 (solved_problems)'"

# 마켓플레이스 항목의 autoUpdate 값을 읽어 출력한다($1=파일 $2=항목 이름). 없으면 none을 찍는다.
# grep으로 파일 전체를 훑으면 우리 항목에 붙었는지 남의 항목에 붙었는지 못 가리므로 항목을 지목해 읽는다.
json_autoupdate() {
  local prog='
import json,sys,io
d=json.load(io.open(sys.argv[1],encoding="utf-8"))
e=d.get("extraKnownMarketplaces")
t=(e or {}).get(sys.argv[2]) if isinstance(e,dict) else None
if t is None: t=d.get(sys.argv[2])
if not isinstance(t,dict) or "autoUpdate" not in t: print("none")
else: print("true" if t["autoUpdate"] is True else "false")
'
  if python3 -c 'import sys' >/dev/null 2>&1; then python3 -c "$prog" "$1" "$2"
  else python -c "$prog" "$1" "$2"; fi
}

# --- marketplace-autoupdate: 우리 마켓플레이스만, 키가 없을 때만 켠다 ---
MKT="$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$HERE/.claude-plugin/marketplace.json" | head -1 | cut -d'"' -f4)"
HA="$(mktemp -d)"; PA="$(mktemp -d)"; mkdir -p "$HA/.claude/plugins"
cat > "$HA/.claude/settings.json" <<EOF
{
  "theme": "dark",
  "extraKnownMarketplaces": {
    "$MKT": { "source": { "source": "github", "repo": "chshin84/disciplined-coder" } },
    "somebody-else": { "source": { "source": "github", "repo": "other/repo" } }
  },
  "hooks": { "PreToolUse": [] }
}
EOF
cat > "$HA/.claude/plugins/known_marketplaces.json" <<EOF
{ "$MKT": { "source": { "source": "github", "repo": "chshin84/disciplined-coder" } } }
EOF
run "$HA" "$PA" >/dev/null 2>&1
SET_A="$HA/.claude/settings.json"; KNOWN_A="$HA/.claude/plugins/known_marketplaces.json"
echo "[marketplace-autoupdate] 자동 갱신을 켠다"
check "우리 항목에 autoUpdate가 켜졌다"   "[ \"\$(json_autoupdate '$SET_A' \"\$MKT\")\" = 'true' ]"
check "알려진 마켓플레이스에도 켜졌다"     "[ \"\$(json_autoupdate '$KNOWN_A' \"\$MKT\")\" = 'true' ]"
check "남의 마켓플레이스는 그대로다"       "[ \"\$(json_autoupdate '$SET_A' 'somebody-else')\" = 'none' ]"
check "다른 설정이 보존된다"              "grep -qF '\"theme\"' '$SET_A' && grep -qF 'PreToolUse' '$SET_A'"
check "사본을 남긴다"                     "[ -f '$SET_A.bak' ]"
BEFORE_A="$(cat "$SET_A")"
run "$HA" "$PA" >/dev/null 2>&1
check "두 번째 실행에서 안 바뀐다"         "[ \"\$BEFORE_A\" = \"\$(cat '$SET_A')\" ]"

# 사용자가 일부러 끈 것은 사용자의 결정이라 되돌리지 않는다
HB="$(mktemp -d)"; PB="$(mktemp -d)"; mkdir -p "$HB/.claude"
cat > "$HB/.claude/settings.json" <<EOF
{ "extraKnownMarketplaces": { "$MKT": { "autoUpdate": false, "source": { "source": "github", "repo": "chshin84/disciplined-coder" } } } }
EOF
run "$HB" "$PB" >/dev/null 2>&1
check "꺼 둔 값을 되돌리지 않는다"         "[ \"\$(json_autoupdate '$HB/.claude/settings.json' \"\$MKT\")\" = 'false' ]"
check "꺼 둔 파일은 다시 쓰이지도 않는다"  "[ ! -f '$HB/.claude/settings.json.bak' ]"

# 우리 항목이 없으면 아무것도 만지지 않는다
HC="$(mktemp -d)"; PC2="$(mktemp -d)"; mkdir -p "$HC/.claude"
printf '{ "extraKnownMarketplaces": { "somebody-else": { "source": { "source": "github", "repo": "other/repo" } } } }
' > "$HC/.claude/settings.json"
BEFORE_C="$(cat "$HC/.claude/settings.json")"
run "$HC" "$PC2" >/dev/null 2>&1
check "우리 항목이 없으면 안 만진다"       "[ \"\$BEFORE_C\" = \"\$(cat '$HC/.claude/settings.json')\" ]"
check "사본도 안 만든다"                  "[ ! -f '$HC/.claude/settings.json.bak' ]"

# 깨진 JSON은 손대지 않고 스캐폴드도 죽지 않는다
HD="$(mktemp -d)"; PD="$(mktemp -d)"; mkdir -p "$HD/.claude"
printf '{ this is not json
' > "$HD/.claude/settings.json"
set +e; run "$HD" "$PD" >/dev/null 2>&1; rc_d=$?; set -e
check "깨진 설정에도 스캐폴드가 산다"      "[ $rc_d -eq 0 ]"
check "깨진 설정을 고치지 않는다"          "grep -qF 'this is not json' '$HD/.claude/settings.json'"
check "깨진 설정에도 정본은 깔린다"        "[ -f '$HD/.claude/disciplined-coder/agent-principles.md' ]"
set +e; ERR_D="$(run "$HD" "$PD" 2>&1 >/dev/null)"; set -e
check "깨진 설정을 조용히 넘기지 않는다"    "printf '%s' \"\$ERR_D\" | grep -qF 'autoUpdate 설정을 건너뛴다'"

# --- project-untouched: 프로젝트 폴더 무오염 ---
echo "[project-untouched] project untouched"
check "no principles in project"      "[ ! -f '$P1/agent-principles.md' ]"
check "no solved in project"          "[ ! -f '$P1/solved_problems.md' ]"
check "no CLAUDE.md in project"       "[ ! -f '$P1/CLAUDE.md' ]"

# --- idempotency: 멱등성 (3회) ---
run "$H1" "$P1" >/dev/null; run "$H1" "$P1" >/dev/null
echo "[idempotency] idempotency"
check "still one region"              "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "principles import not dup"     "[ \$(grep -cxF '@disciplined-coder/agent-principles.md' '$UC') -eq 1 ]"

# --- solved-preserved: solved 누적 보존 ---
echo "[solved-preserved] solved preserved"
printf '\n- 기존 항목 보존 확인\n' >> "$K/solved_problems.md"
run "$H1" "$P1" >/dev/null
check "solved entry preserved"        "grep -qF '기존 항목 보존 확인' '$K/solved_problems.md'"

# --- user-content-preserved: 기존 user CLAUDE.md 내용 보존 + 블랭크 비누적 ---
H5="$(mktemp -d)"; P5="$(mktemp -d)"
mkdir -p "$H5/.claude"; printf 'my personal global note\n' > "$H5/.claude/CLAUDE.md"
for _ in 1 2 3; do run "$H5" "$P5" >/dev/null; done
UC5="$H5/.claude/CLAUDE.md"
echo "[user-content-preserved] preserve user content + no blank accumulation"
check "personal note preserved"      "grep -qxF 'my personal global note' '$UC5'"
check "one region after 3 runs"      "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC5') -eq 1 ]"
check "blank lines bounded (<=1)"    "[ \$(grep -c '^\$' '$UC5') -le 1 ]"

# --- crlf-region: CRLF 관리영역 인식 ---
H6="$(mktemp -d)"; P6="$(mktemp -d)"; mkdir -p "$H6/.claude"
printf 'note\r\n# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/agent-principles.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H6/.claude/CLAUDE.md"
run "$H6" "$P6" >/dev/null
echo "[crlf-region] CRLF region recognized"
check "CRLF region not duplicated"   "[ \$(grep -cF '# BEGIN disciplined-coder' '$H6/.claude/CLAUDE.md') -eq 1 ]"

# --- malformed-region: 깨진 관리영역(BEGIN 있고 END 없음) → 비파괴 스킵(strip 안 함) ---
H7="$(mktemp -d)"; P7="$(mktemp -d)"; mkdir -p "$H7/.claude"
{ printf 'note before\n'; printf '# BEGIN disciplined-coder (managed — do not edit)\n'; \
  printf '@disciplined-coder/agent-principles.md\n'; printf 'IMPORTANT user content after malformed begin\n'; } > "$H7/.claude/CLAUDE.md"
ERR7="$(run "$H7" "$P7" 2>&1 >/dev/null)" || true
UC7="$H7/.claude/CLAUDE.md"
echo "[malformed-region] malformed region (BEGIN w/o END) → non-destructive"
check "malformed: user content preserved"  "grep -qxF 'IMPORTANT user content after malformed begin' '$UC7'"
check "malformed: pre-region note preserved" "grep -qxF 'note before' '$UC7'"
check "malformed: warns BEGIN without END"  "printf '%s' \"\$ERR7\" | grep -qF 'BEGIN but no END'"
check "malformed: complete region appended" "[ \$(grep -cF '# END disciplined-coder' '$UC7') -ge 1 ]"

# --- malformed-region-rerun: 깨진 관리영역 2회차 실행 — 1회차가 다음 실행의 파괴를 준비하면 안 된다 ---
ERR7b="$(run "$H7" "$P7" 2>&1 >/dev/null)" || true
echo "[malformed-region-rerun] malformed region 2nd run → still non-destructive"
check "2nd run: user content preserved"    "grep -qxF 'IMPORTANT user content after malformed begin' '$UC7'"
check "2nd run: pre-region note preserved" "grep -qxF 'note before' '$UC7'"
check "2nd run: single managed region"     "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC7') -eq 1 ]"

# --- missing-canon: 정본 소스 부재 → FAIL-LOUD 경고(stderr) + 계속 진행(exit 0) ---
H8="$(mktemp -d)"; P8="$(mktemp -d)"; ED="$(mktemp -d)"   # ED = 정본 없는 빈 plugin root
set +e
ERR8="$(CLAUDE_HOME_DIR="$H8/.claude" CLAUDE_PROJECT_DIR="$P8" CLAUDE_PLUGIN_ROOT="$ED" bash "$SCAFFOLD" 2>&1 >/dev/null)"; rc8=$?
set -e
echo "[missing-canon] missing source → FAIL-LOUD warning, exit 0"
check "missing source warns to stderr"      "printf '%s' \"\$ERR8\" | grep -qF 'WARNING: source not found'"
check "missing source still exit 0"         "[ $rc8 -eq 0 ]"

# --- home-resolution: 홈 해석이 bash $HOME에 의존하지 않음 (CLAUDE_CONFIG_DIR 우선) ---
# AD 리다이렉트 홈(예: $HOME=U:\ 네트워크 드라이브)에서 Claude Code 실제 홈(USERPROFILE/CLAUDE_CONFIG_DIR)과
# 어긋나던 버그 회귀 방지. 임시 HOME을 줘서 실패 시에도 실제 ~/.claude를 오염시키지 않는다.
H9="$(mktemp -d)/cfg"; P9="$(mktemp -d)"; HJUNK="$(mktemp -d)"
OUT9="$(HOME="$HJUNK" CLAUDE_CONFIG_DIR="$H9" CLAUDE_PROJECT_DIR="$P9" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD")"
echo "[home-resolution] home resolution honors CLAUDE_CONFIG_DIR, not bash \$HOME"
check "CLAUDE_CONFIG_DIR honored (KDIR)"     "[ -f '$H9/disciplined-coder/agent-principles.md' ]"
check "CLAUDE_CONFIG_DIR honored (CLAUDE.md)" "[ -f '$H9/CLAUDE.md' ]"
check "did not fall back to bash \$HOME"      "[ ! -d '$HJUNK/.claude' ]"

# --- managed-dir-hygiene: 관리 디렉터리 위생 — 구 관리파일 제거·정본/사용자데이터 보존·빈 고아 제거 ---
H10="$(mktemp -d)"; P10="$(mktemp -d)"
run "$H10" "$P10" >/dev/null
K10="$H10/.claude/disciplined-coder"
printf 'old canon\n'    > "$K10/coding-principles.md"     # 구 관리파일(STALE) → 제거
printf '내 개인 메모\n'   > "$K10/my_notes.md"             # 정체 모를 사용자 파일(내용 있음) → 보존 + surface
: > "$K10/orphan_empty.md"                                 # 빈 고아 → 제거
mkdir -p "$K10/rogue_dir"                                  # 하위 디렉터리 → 중단 없이 surface
set +e
ERR10="$(run "$H10" "$P10" 2>&1 >/dev/null)"; rc10=$?
set -e
echo "[managed-dir-hygiene] managed-dir hygiene (whitelist pruning)"
check "stale coding-principles pruned"  "[ ! -f '$K10/coding-principles.md' ]"
check "canon preserved"                 "[ -f '$K10/agent-principles.md' ]"
check "solved preserved"                "[ -f '$K10/solved_problems.md' ]"
check "unknown user file preserved"     "[ -f '$K10/my_notes.md' ]"
check "empty orphan removed"            "[ ! -f '$K10/orphan_empty.md' ]"
check "non-empty orphan surfaced"       "printf '%s' \"\$ERR10\" | grep -qF 'my_notes.md'"
check "subdir does not abort scaffold"  "[ $rc10 -eq 0 ]"
check "subdir surfaced to stderr"       "printf '%s' \"\$ERR10\" | grep -qF 'rogue_dir'"
check "subdir preserved"                "[ -d '$K10/rogue_dir' ]"

# --- toggles-removed: 토글 둘(issue-mode·ultracode-review)을 없애고 동작을 하나로 고정했다 ---
# 모르면 안 쓰게 되는 설정이라 없앴다. 처분은 surface로 고정하고, ultracode 검증은 정본 원칙만 남겼다.
# 이미 만들어진 상태 파일은 STALE로 지운다 — 화이트리스트에서 빼기만 하면 매 세션 경고가 남는다.
H12="$(mktemp -d)"; P12="$(mktemp -d)"; K12="$H12/.claude/disciplined-coder"
echo "[toggles-removed] 토글 커맨드·스크립트·모드 주입이 모두 사라졌다"
check "issue-mode 스크립트가 없다"           "[ ! -f '$HERE/scripts/issue-mode.sh' ]"
check "ultracode-review 스크립트가 없다"     "[ ! -f '$HERE/scripts/ultracode-review.sh' ]"
check "issue-mode 커맨드가 없다"             "[ ! -f '$HERE/commands/issue-mode.md' ]"
check "ultracode-review 커맨드가 없다"       "[ ! -f '$HERE/commands/ultracode-review.md' ]"
OUT12a="$(run "$H12" "$P12")"
check "처분 모드 줄을 주입하지 않는다"       "! printf '%s' \"\$OUT12a\" | grep -qF '처분 모드'"
check "검증 모드 줄을 주입하지 않는다"       "! printf '%s' \"\$OUT12a\" | grep -qF '검증 모드'"
check "issue-mode 파일을 만들지 않는다"      "[ ! -f '$K12/issue-mode' ]"
check "ultracode-review 파일을 만들지 않는다" "[ ! -f '$K12/ultracode-review' ]"
printf 'issues\n' > "$K12/issue-mode"; printf 'required\n' > "$K12/ultracode-review"
ERR12b="$(run "$H12" "$P12" 2>&1 >/dev/null)" || true
check "잔존 issue-mode 를 지운다"            "[ ! -f '$K12/issue-mode' ]"
check "잔존 ultracode-review 를 지운다"      "[ ! -f '$K12/ultracode-review' ]"
check "잔존 파일에 경고를 남기지 않는다"     "! printf '%s' \"\$ERR12b\" | grep -qF '비관리 파일'"

# --- readme-commands-drift: README 커맨드 절 ↔ commands/ 디렉터리 드리프트 가드 (SSOT — 열거는 사용 절 한 곳) ---
# 파일 전체가 아니라 '### 커맨드' 절만 검사한다 — 커맨드명이 다른 문단에 등장해
# 목록 누락이 vacuous 통과하는 것을 막는다.
CMD_SECTION="$(awk '/^### 커맨드/{f=1} f&&/^## /{exit} f' "$HERE/README.md")"
echo "[readme-commands-drift] README commands section covers commands/ dir"
for c in "$HERE"/commands/*.md; do
  n="/$(basename "$c" .md)"
  check "README commands section lists $n" "printf '%s' \"\$CMD_SECTION\" | grep -qF -- '$n'"
done

# --- workflow-verification-row: 검증 레이어 표에 워크플로 검증 행 존재(정본 계약 가드 — spec 검증 기준) ---
# 파일 전역 grep이 아니라 트리거 문자열이 있는 '그 행 한 줄'을 뽑아 검사한다 — 호출자 열(reviewer-*)과
# 강제 방식 열이 같은 행에 있음을 보장한다(다른 행·다른 파일의 문자열로 vacuous 통과 방지).
WF_ROW="$(grep -F '멀티에이전트 워크플로를 쓰거나 돌릴 때' "$HERE/agent-principles.md" || true)"
echo "[workflow-verification-row] principles table has workflow verification row"
check "row exists (trigger)"       "[ -n \"\$WF_ROW\" ]"
check "row caller = reviewer-*"    "printf '%s' \"\$WF_ROW\" | grep -qF 'reviewer-*'"
check "row enforcement = 미실행 이유 기재" "printf '%s' \"\$WF_ROW\" | grep -qF '보고서에 그 판정과 이유를 적는다'"
check "row에 사라진 토글이 남아 있지 않다" "! printf '%s' \"\$WF_ROW\" | grep -qF 'ultracode 검증 모드'"

# --- managed-region-heal: 손상된 관리영역 자기 치유 (실측 ~/.claude/CLAUDE.md 모양 재현) ---
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
echo "[managed-region-heal] corrupted region self-heals"
check "one BEGIN after heal"          "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC18') -eq 1 ]"
check "one END after heal"            "[ \$(grep -cF '# END disciplined-coder' '$UC18') -eq 1 ]"
check "no orphan marker left"         "! grep -qF 'orphan BEGIN neutralized' '$UC18'"
check "user note preserved"           "grep -qxF 'MY OWN GLOBAL NOTE' '$UC18'"
run "$H18" "$P18" >/dev/null
check "still one BEGIN (idempotent)"  "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC18') -eq 1 ]"
check "user note still there"         "grep -qxF 'MY OWN GLOBAL NOTE' '$UC18'"

# --- orphan-opener: 고아 여는 마커 뒤 본문은 한 줄도 지우지 않는다 (빈 줄 포함) ---
H19="$(mktemp -d)"; P19="$(mktemp -d)"; mkdir -p "$H19/.claude"
{ printf 'head note\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf 'para one\n'
  printf '\n'
  printf 'para two\n'
} > "$H19/.claude/CLAUDE.md"
ERR19="$(run "$H19" "$P19" 2>&1 >/dev/null)" || true
UC19="$H19/.claude/CLAUDE.md"
echo "[orphan-opener] orphan opener drops only its own line"
check "orphan: head preserved"        "grep -qxF 'head note' '$UC19'"
check "orphan: para one preserved"    "grep -qxF 'para one' '$UC19'"
check "orphan: para two preserved"    "grep -qxF 'para two' '$UC19'"
check "orphan: blank line right after para one preserved" "blank_follows '$UC19' 'para one'"
check "orphan: warns BEGIN w/o END"   "printf '%s' \"\$ERR19\" | grep -qF 'BEGIN but no END'"
check "orphan: marker line gone"      "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC19') -eq 1 ]"

# --- canon-first-run-only: 정본 stdout 덤프는 첫 설치 세션에만 (이중 주입 회귀 가드) ---
H20="$(mktemp -d)"; P20="$(mktemp -d)"
OUT20a="$(run "$H20" "$P20")"
OUT20b="$(run "$H20" "$P20")"
echo "[canon-first-run-only] canon dumped on first run only"
check "1st run dumps principles"      "printf '%s' \"\$OUT20a\" | grep -qF '# 디시플린 (팀 원칙)'"
check "1st run dumps solved"          "printf '%s' \"\$OUT20a\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "2nd run omits principles"      "! printf '%s' \"\$OUT20b\" | grep -qF '# 디시플린 (팀 원칙)'"
check "2nd run omits solved"          "! printf '%s' \"\$OUT20b\" | grep -qF '해결된 문제 로그 (solved_problems)'"
# 토글이 사라져 2회차에는 보낼 것이 없다. 빈 문자열을 단언해 두면 무엇이 새로 새어 나와도 붉어진다
# — 부정 단언만 남기면 스크립트가 아무것도 못 내도 통과하는 vacuous 구멍이 생긴다.
check "2nd run sends nothing"         "[ -z \"\$OUT20b\" ]"

# --- crlf-import-line: CRLF 관리영역에서도 재주입하지 않는다 (had_import의 CR 내성) ---
H21="$(mktemp -d)"; P21="$(mktemp -d)"; mkdir -p "$H21/.claude"
printf '# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/agent-principles.md\r\n@disciplined-coder/domains-index.md\r\n@disciplined-coder/solved_problems.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H21/.claude/CLAUDE.md"
OUT21="$(run "$H21" "$P21")"
echo "[crlf-import-line] CRLF import line still counts as present"
check "CRLF: no canon re-dump"        "! printf '%s' \"\$OUT21\" | grep -qF '# 디시플린 (팀 원칙)'"
check "CRLF: no solved re-dump"       "! printf '%s' \"\$OUT21\" | grep -qF '해결된 문제 로그 (solved_problems)'"
check "CRLF: sends nothing"           "[ -z \"\$OUT21\" ]"

# --- parallel-orchestration-nudge: 병렬 오케스트레이션 넛지(정본 계약 가드) ---
# 병렬 오케스트레이션 헤딩부터 다음 '### ' 또는 '## '까지의 블록만 뽑아 그 안에서 검사한다
# (vacuous 통과 방지).
PO_BLOCK="$(awk '/^### 병렬 오케스트레이션/{f=1} f&&/^### /&&!/^### 병렬 오케스트레이션/{exit} f&&/^## /&&!/^### /{exit} f' "$HERE/agent-principles.md")"
echo "[parallel-orchestration-nudge] principles 병렬 오케스트레이션 nested-orchestration nudge"
check "병렬 오케스트레이션 heading exists"      "printf '%s' \"\$PO_BLOCK\" | grep -qF '### 병렬 오케스트레이션'"
check "병렬 오케스트레이션 points to skill (SSOT)" "printf '%s' \"\$PO_BLOCK\" | grep -qF 'nested-orchestration'"
check "병렬 오케스트레이션 routes single-task to 2층" "printf '%s' \"\$PO_BLOCK\" | grep -qF 'dispatching-parallel-agents'"

# --- nested-orchestration-skill: nested-orchestration 스킬 존재 + 핵심 절(정본 계약 가드) ---
# 단일 목적 파일이라 파일 전역 존재 검사로 충분하다(섹션 경합 없음 — Global Constraint 참조).
NO_SKILL="$HERE/skills/nested-orchestration/SKILL.md"
echo "[nested-orchestration-skill] nested-orchestration skill present + structured"
check "skill file exists"             "[ -f '$NO_SKILL' ]"
check "frontmatter name correct"      "grep -qE '^name: *nested-orchestration' '$NO_SKILL'"
check "has routing (2층 위임)"         "grep -qF 'dispatching-parallel-agents' '$NO_SKILL'"
check "has L2 template ownership blk"  "grep -qF '구간 소유권(엄수)' '$NO_SKILL'"
check "has output contract blk"        "grep -qF '산출 계약' '$NO_SKILL'"
check "points to SDD (no reimpl)"      "grep -qF 'subagent-driven-development' '$NO_SKILL'"

# --- solved-rules-nudge: 인접 여는 마커 가드 — 첫 BEGIN이 뒤쪽 닫는 마커까지 훑어 사용자 줄을 삼키면 안 된다 ---
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
echo "[solved-rules-nudge] adjacent opening-marker guard: inner scan must not skip past a second opener"
check "user line between two openers preserved" "grep -qxF 'USER LINE BETWEEN TWO OPENERS' '$UC22'"
check "single managed region after run"         "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC22') -eq 1 ]"

# --- canon-sections: 절차 절을 번호가 아니라 이름으로 부른다 (NAME-ITEMS) ---
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

# --- standing-consent: 리뷰어 호출에 대한 상시 허가가 정본에 있다 ---
# 세션 기본 지침이 "사용자가 요청하지 않으면 서브에이전트를 부르지 마라"로 들어오는 환경이 있다.
# 그 문구는 조건부라 사용자 지침으로 상시 허가를 남기면 열린다. 정본은 @import(Claude)와 인라인
# (Codex) 양쪽으로 실리므로, 이 한 문장이 있으면 두 런타임 모두에서 검진이 돈다.
# 파일 전역 grep이 아니라 '검증 레이어' 절만 뽑아 그 안에서 본다 — 허가 문장과 범위를 좁히는 문장이
# 서로 떨어져 나가도 각각 어딘가에 남아 있으면 통과해 버리는 항진을 막는다(이 파일의 다른 절과 같은 방식).
SC_BLOCK="$(awk '/^### 검증 레이어/{f=1} f&&/^### /&&!/^### 검증 레이어/{exit} f' "$CANON")"
# 백틱이 든 패턴은 작은따옴표 변수에 담아 grep -qF -- 로 넘긴다 — 큰따옴표 안에 두면 eval을 지나며
# 명령 치환으로 실행되어, 검사가 엉뚱한 문자열을 찾으면서도 초록으로 남는다.
CONSENT='disciplined-coder의 리뷰어 서브에이전트 호출은 사용자가 상시 허용한 것으로 간주한다'
SC_SCOPE='disciplined-coder 리뷰어(`reviewer-*`) 호출에만 미친다'
echo "[standing-consent] reviewer calls carry the user's standing consent"
check "검증 레이어 절이 잡힌다"            "[ -n \"\$SC_BLOCK\" ]"
check "canon: 상시 허가 문장"              "printf '%s' \"\$SC_BLOCK\" | grep -qF -- '$CONSENT'"
check "canon: 허가 범위 한정"              "printf '%s' \"\$SC_BLOCK\" | grep -qF -- \"\$SC_SCOPE\""
check "canon: 다른 팬아웃은 제외"          "printf '%s' \"\$SC_BLOCK\" | grep -qF -- '그 밖의 서브에이전트나 병렬 팬아웃'"
# 선행연구 렌즈는 이름을 대서 예외로 못 박아야 한다. 이름이 reviewer-*라 허가에 들면서 동시에 웹에
# 나가는 유일한 렌즈라, 뭉뚱그린 말로 제외하면 같은 렌즈를 열고 닫는 문장이 된다. 그 상태에서는
# 렌즈를 범위 밖으로 판단해 조용히 건너뛰게 되고, '막히면 알린다'는 안전장치도 발동하지 않는다.
check "canon: 선행연구 렌즈를 이름으로 예외" "printf '%s' \"\$SC_BLOCK\" | grep -qF -- 'reviewer-prior-art'"
check "canon: 뭉뚱그린 심층조사 표현 없음"   "! printf '%s' \"\$SC_BLOCK\" | grep -qF -- '심층조사'"
# 정본이 곧 주입 경로이므로, 갓 설치한 PC의 관리 디렉터리 사본에도 그 문장이 실려야 한다.
check "설치본에도 상시 허가 문장"          "grep -qF -- '$CONSENT' '$K/agent-principles.md'"

# --- question-tool: 갈림길은 질문 도구로 묻는다 (상시 로드 규칙) ---
# 이 규칙이 리뷰 스킬 한 곳에만 있으면 그 스킬을 열지 않은 세션에는 닿지 않는다. 실제로 문서 검진
# 세션이 다시 돌릴지를 평문으로 물어 선택 대화창이 뜨지 않았다. 묻는 방식은 특정 절차의 성질이 아니라
# 소통 규칙이므로 상시 로드되는 항목에 두고, 리뷰 스킬은 그것을 가리키기만 한다(SSOT).
CC_LINE="$(grep -F '**`ASK-FORK`' "$CANON" || true)"
SR="$HERE/skills/domain-spec-review/SKILL.md"
SR_ASK="$(grep -F '물을 때는' "$SR" || true)"
echo "[question-tool] the fork-in-the-road question rule is always loaded"
check "ASK-FORK 항목이 잡힌다"              "[ -n \"\$CC_LINE\" ]"
check "ASK-FORK: 질문 도구 규칙"            "printf '%s' \"\$CC_LINE\" | grep -qF -- '질문 도구로 선택지를 띄운다'"
check "ASK-FORK: 평문이 안 되는 이유"       "printf '%s' \"\$CC_LINE\" | grep -qF -- '답할 자리인지'"
check "spec-review: 묻는 방식 줄이 있다"    "[ -n \"\$SR_ASK\" ]"
check "spec-review: 규칙을 재정의 말고 인용" "printf '%s' \"\$SR_ASK\" | grep -qF -- 'ASK-FORK'"

# --- canon-refresh: 이미 옛 정본을 갖고 있는 PC도 갱신을 받는다 ---
# 갓 설치한 경로만 검사하면, 정본 복사를 '없을 때만'으로 바꿔도 초록이 유지된다. 바로 이웃한 두
# 블록(오답노트 생성·머리말 동기화)이 일부러 비덮어쓰기라 통일하자며 그렇게 고치기 쉬운 자리다.
# 그 순간 이미 깔린 모든 설치가 옛 정본에 멈추는데, 새 문장이 필요한 쪽은 정확히 그 설치들이다.
HRU="$(mktemp -d)"; PRU="$(mktemp -d)"; mkdir -p "$HRU/.claude/disciplined-coder"
OLDCANON="$HRU/.claude/disciplined-coder/agent-principles.md"
printf '# 디시플린 (팀 원칙)\n\n옛 사본이라 새 문장이 없다.\n' > "$OLDCANON"
run "$HRU" "$PRU" >/dev/null
echo "[canon-refresh] an existing older canon copy is refreshed, not left behind"
check "옛 사본이 갱신된다"                 "grep -qF -- '$CONSENT' '$OLDCANON'"
check "옛 내용이 남지 않는다"              "! grep -qF '옛 사본이라 새 문장이 없다' '$OLDCANON'"

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
# 관례의 상세는 domain-docs가 소유자다. 여기서는 실측 표가 그 근거라는 연결만 남았는지 본다.
check "DESIGN-NOTES: 리뷰어 관례가 소유자를 가리킨다" "grep -qF '리뷰어에게 정본을 알리는 법' '$DN'"
check "README: 갈림을 요약하고 링크"        "grep -qF '종류에 따라 갈린다' '$HERE/README.md' && grep -qF 'docs/DESIGN-NOTES.md' '$HERE/README.md'"
check "canon: 옛 도달 전제 제거"            "! grep -qF '서브에이전트도 이 글을 읽으므로' '$CANON'"
check "canon: 도달을 전제하지 않는다"       "grep -qF '도달을 전제하지 않는다' '$CANON'"

# --- reviewer-contract: 읽기 전용 리뷰어를 띄우는 호출자 셋이 같은 계약에 닿는다 ---
# 전에는 셋이 규율 넷을 각자 적고 이 검사가 그 사본들을 맞춰 세웠다. 사본이라 갈라졌다 — 한 곳에서
# 재시도 금지 항목만 빠져 그 경로가 금지된 재시도를 허용한 채 오래 남았고, DESIGN-NOTES 쪽은 넷 중
# 둘만 갖고 있었다. 지금은 `domain-docs`가 규율을 소유하고 나머지는 가리키기만 한다(`SSOT`).
# 소유자가 규율을 갖는지와 다른 문서가 베끼지 않는지는 `test_docs_drift.sh`가 본다. 여기서는 호출자
# 셋이 그 소유자에 닿는지와 Codex 패리티만 본다.
echo "[reviewer-contract] callers reach the canon-path rules and stay runtime-neutral"
for s in domain-spec-review domain-docs nested-orchestration; do
  F="$HERE/skills/$s/SKILL.md"
  check "$s: 정본 알리는 법에 닿는다"       "grep -qF '리뷰어에게 정본을 알리는 법' '$F'"
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
  # 렌즈는 이 필드가 언제 필요한지를 스스로 규정하지 않고 정본으로 넘긴다. 예전에는 일곱 파일이
  # 같은 문단을 복제해 지켰는데, 그 사이 정본의 스키마 블록이 이 필드를 무조건 필수로 보이게 적어
  # 필수 여부가 두 곳에서 갈렸다. 지금은 정본 한 곳만 규정하고 렌즈는 가리키기만 한다(`SSOT`).
  PA_POINTER='`meta-aggregate`의 리뷰 산출물 계약이 정한다'
  check "reviewer-$l: 규칙을 정본으로 넘긴다" "grep -qF -- \"\$PA_POINTER\" '$F'"
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

# (나) 형식 규칙 블록이 없는 옛 로그는 백업을 뜨고 머리말만 갈아끼운다 — 항목은 그대로다.
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
BK2="$(find "$HR2/.claude/disciplined-coder/backups" -type f -name 'solved_problems.*' 2>/dev/null | head -1 || true)"
echo "[solved-rules] legacy log gets its header replaced, entries untouched"
check "legacy: 규칙 블록이 생겼다"        "grep -qF '증상은 굵게 한 줄로 띄운다' '$OLDLOG'"
check "legacy: 옛 규칙 문장이 사라졌다"   "! grep -qF '등록은 메인 세션이 수행' '$OLDLOG'"
check "legacy: 첫 항목 보존"              "grep -qF '옛 형식 항목' '$OLDLOG'"
check "legacy: 여러 줄 항목 보존"         "grep -qF '해결: 셋째 줄' '$OLDLOG'"
check "legacy: 백업이 생겼다"             "[ -n '$BK2' ]"
check "legacy: 백업은 손대기 전 원본"     "[ \"\$(cksum < '$BK2')\" = '$BEFORE2' ]"
check "legacy: 무엇을 했는지 알린다"      "printf '%s' \"\$OUTR2\" | grep -qF '머리말을 현행 형식으로 갱신'"
check "legacy: 임시 파일 잔해 없음"       "[ -z \"\$(find '$HR2/.claude/disciplined-coder' -maxdepth 1 -name 'solved_problems.md.*' 2>/dev/null)\" ]"
# 두 번째 실행은 이미 최신이라 아무 일도 하지 않는다(멱등) — 백업이 세션마다 쌓이면 안 된다.
AFTER2="$(cksum < "$OLDLOG")"
run "$HR2" "$PR2" >/dev/null
check "legacy: 재실행은 무변경"           "[ \"\$(cksum < '$OLDLOG')\" = \"\$AFTER2\" ]"
check "legacy: 백업이 늘지 않는다"        "[ \$(find '$HR2/.claude/disciplined-coder/backups' -type f | wc -l) -eq 1 ]"

# (다) 불릿을 하나 지운 로그도 낡은 것으로 잡아 규칙 블록을 통째로 복원한다. 남아 있던 규칙
# 불릿을 항목으로 오인해 아래에 다시 붙이면 블록이 두 벌이 되므로, 중복이 없는지도 함께 본다.
HR3="$(mktemp -d)"; PR3="$(mktemp -d)"; mkdir -p "$HR3/.claude/disciplined-coder"
run "$HR3" "$PR3" >/dev/null
LOG3="$HR3/.claude/disciplined-coder/solved_problems.md"
sed -i '/^- 한 항목은 세 줄을 넘기지 않는다\.$/d' "$LOG3"
run "$HR3" "$PR3" >/dev/null
echo "[solved-rules] a log missing one rule bullet gets the whole block restored"
check "partial: 지운 불릿 복원"            "grep -qF '한 항목은 세 줄을 넘기지 않는다' '$LOG3'"
check "partial: 규칙 불릿 중복 없음"       "[ \$(grep -cF '증상은 굵게 한 줄로 띄운다' '$LOG3') -eq 1 ]"
check "partial: 도입 문장 중복 없음"       "[ \$(grep -cF '항목을 적는 형식은 이렇다' '$LOG3') -eq 1 ]"

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
RL5="$HR5/.claude/disciplined-coder/solved_problems.md"
printf 'x\n' > "$RL5"
chmod 000 "$RL5" 2>/dev/null || true
# Windows에서는 chmod가 무시돼 파일이 그대로 읽힌다. 그 사실을 드러내지 않으면 이 검사는 그 플랫폼에서
# 항진이 된다 — 실제로 CI(Linux)에서만 붉어지고 로컬에서는 늘 초록이던 결함이 여기 숨어 있었다.
if cat "$RL5" >/dev/null 2>&1; then unreadable_effective=0; else unreadable_effective=1; fi
set +e; run "$HR5" "$PR5" >/dev/null 2>&1; rc5=$?; set -e
chmod 644 "$RL5" 2>/dev/null || true
echo "[solved-rules] hook exits 0 even on unreadable log"
check "unreadable: exit 0"                "[ '$rc5' = '0' ]"
if [ "$unreadable_effective" -eq 0 ]; then
  echo "    (참고: 이 플랫폼에서는 chmod 000이 먹지 않아 위 검사가 읽기 거부 경로를 밟지 못했다)"
fi

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
check "domain-docs: 자동 갱신 정책"       "grep -qF '머리말은 플러그인이 갈아끼운다' '$DD'"
check "domain-docs: 경계 규칙 명시"       "grep -qF '첫 구조 요소' '$DD'"

# (아) 머리말 뒤에 사람이 만든 절이 오는 로그는 그 절을 살려 둔다.
# 실측 사례(newsstore)의 모양이다 — 머리말 다음이 항목이 아니라 '## 핵심 gotchas' 절이었고,
# 그 절은 다른 문서가 서브에이전트 주입 재료로 참조한다. 경계를 항목으로만 잡으면 여기서 날아간다.
HR7="$(mktemp -d)"; PR7="$(mktemp -d)"; mkdir -p "$HR7/.claude/disciplined-coder"
LOG7="$HR7/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems)\n\n'
  printf '작업 중 발견·해결된 문제 기록. 각 항목: 문제 → 원인 → 해결.\n\n'
  printf '## 핵심 gotchas (서브에이전트 주입용 다이제스트)\n'
  printf '*반복되는 함정*만 추림.\n'
  printf -- '- **Docker-only**: 테스트는 컨테이너에서 돌린다.\n\n'
  printf '## 아카이브\n\n'
  printf -- '- **옛 항목** → 원인 → 해결\n'
} > "$LOG7"
run "$HR7" "$PR7" >/dev/null
echo "[solved-rules] a hand-written section after the header survives"
check "절 보존: gotchas 제목"             "grep -qF '## 핵심 gotchas' '$LOG7'"
check "절 보존: gotchas 본문"             "grep -qF 'Docker-only' '$LOG7'"
check "절 보존: 아카이브 절"              "grep -qF '## 아카이브' '$LOG7'"
check "절 보존: 규칙 블록이 생겼다"       "grep -qF '증상은 굵게 한 줄로 띄운다' '$LOG7'"
check "절 보존: 옛 규칙 문장 제거"        "! grep -qF '각 항목: 문제 → 원인 → 해결' '$LOG7'"

# (자) 목록도 제목도 없어 머리말의 끝을 못 찾는 로그는 손대지 않고 알리기만 한다.
# 이 안전장치가 없으면 파일 전체를 머리말로 보고 통째로 갈아엎는다.
HR8="$(mktemp -d)"; PR8="$(mktemp -d)"; mkdir -p "$HR8/.claude/disciplined-coder"
LOG8="$HR8/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그\n\n'
  printf '산문으로만 적어 둔 기록이다.\n\n'
  printf '어제 겪은 문제는 이러이러했고 이렇게 풀었다.\n'
} > "$LOG8"
BEFORE8="$(cksum < "$LOG8")"
OUTR8="$(run "$HR8" "$PR8")"
echo "[solved-rules] a log with no structural marker is refused, not guessed"
check "구조 없음: 파일 불변(바이트)"      "[ \"\$(cksum < '$LOG8')\" = '$BEFORE8' ]"
check "구조 없음: 신호 있음"              "printf '%s' \"\$OUTR8\" | grep -qF '$NUDGE'"
check "구조 없음: 백업 안 뜬다"           "[ ! -d '$HR8/.claude/disciplined-coder/backups' ] || [ -z \"\$(find '$HR8/.claude/disciplined-coder/backups' -type f)\" ]"

# (차) 프로젝트 오답노트도 같은 처리를 받고, 백업은 프로젝트가 아니라 전역에 쌓인다.
HR9="$(mktemp -d)"; PR9="$(mktemp -d)"; mkdir -p "$PR9/docs"
PLOG9="$PR9/docs/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — 이 프로젝트\n\n'
  printf '이 레포에서 겪은 문제. 각 항목: 문제 → 원인 → 해결.\n\n'
  printf -- '- **프로젝트 항목** → 원인 → 해결\n'
} > "$PLOG9"
OUTR9="$(run "$HR9" "$PR9")"
echo "[solved-rules] the opened project's log is handled too"
check "프로젝트: 규칙 블록이 생겼다"      "grep -qF '증상은 굵게 한 줄로 띄운다' '$PLOG9'"
check "프로젝트: 항목 보존"               "grep -qF '프로젝트 항목' '$PLOG9'"
check "프로젝트: 스코프 문구가 프로젝트용" "grep -qF '이 프로젝트에 한정된 교훈만 둔다' '$PLOG9'"
check "프로젝트: 백업은 전역에 쌓인다"    "[ -n \"\$(find '$HR9/.claude/disciplined-coder/backups' -type f 2>/dev/null)\" ]"
check "프로젝트: 폴더에 백업 안 남긴다"   "[ \$(find '$PR9' -type f | wc -l) -eq 1 ]"

# (카) 이름이 바뀌거나 없앤 옛 관리파일은 관리 디렉터리에서 치운다. 내용이 있으면 지우지 않고
# 백업으로 옮긴다 — 그 안에 사용자가 적어 둔 줄이 있을 수 있어서다(되돌릴 수 있게 남긴다).
HRS="$(mktemp -d)"; PRS="$(mktemp -d)"; mkdir -p "$HRS/.claude/disciplined-coder"
KS="$HRS/.claude/disciplined-coder"
printf 'old index\n' > "$KS/advisors-index.md"; printf '내 백로그 한 줄\n' > "$KS/unsolved_problems.md"
ERRS="$(CLAUDE_HOME_DIR="$HRS/.claude" CLAUDE_PROJECT_DIR="$PRS" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" 2>&1 >/dev/null)" || true
echo "[stale] renamed and retired managed files are cleared out"
check "stale: advisors-index 치움"        "[ ! -f '$KS/advisors-index.md' ]"
check "stale: unsolved_problems 치움"     "[ ! -f '$KS/unsolved_problems.md' ]"
check "stale: 잔존 경고 없음"             "! printf '%s' \"\$ERRS\" | grep -qF '비관리 파일'"
check "stale: 내용은 백업에 남는다"       "grep -rqF '내 백로그 한 줄' '$KS/backups'"

# (타) 없앤 기능이 프로젝트 CLAUDE.md에 심어 둔 옛 관리블록을 걷어낸다. 전역 블록은 건드리지 않는다.
HR11="$(mktemp -d)"; PR11="$(mktemp -d)"
{ printf '# 내 프로젝트 지침\n\n'
  printf '이 줄은 사용자 것이라 남아야 한다.\n\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '## 오답노트 (solved_problems)\n'
  printf '옛 포인터 본문.\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$PR11/CLAUDE.md"
OUTR11="$(run "$HR11" "$PR11")"
echo "[stale] the retired project pointer block is removed"
check "포인터: 블록 제거"                 "! grep -qF 'BEGIN disciplined-coder' '$PR11/CLAUDE.md'"
check "포인터: 본문도 제거"               "! grep -qF '옛 포인터 본문' '$PR11/CLAUDE.md'"
check "포인터: 사용자 줄 보존"            "grep -qF '이 줄은 사용자 것이라 남아야 한다' '$PR11/CLAUDE.md'"
check "포인터: 제거를 알린다"             "printf '%s' \"\$OUTR11\" | grep -qF '옛 관리블록'"
check "포인터: 전역 블록은 그대로"        "[ \$(grep -cF '# BEGIN disciplined-coder' '$HR11/.claude/CLAUDE.md') -eq 1 ]"
run "$HR11" "$PR11" >/dev/null
check "포인터: 재실행도 사용자 줄 보존"   "grep -qF '이 줄은 사용자 것이라 남아야 한다' '$PR11/CLAUDE.md'"

# (파) 블록을 걷어내기 전에 사본을 뜬다. 걷어내기는 마커 사이를 통째로 버리므로, 사람이 그 안에
# 끼워 넣은 줄도 함께 사라진다. 이 파일은 git 밖일 수 있어 사본이 유일한 복구 수단이다
# (오답노트 머리말과 같은 규율 — domain-docs가 정본).
HR12="$(mktemp -d)"; PR12="$(mktemp -d)"
{ printf '# 내 프로젝트 지침\n\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '## 오답노트 (solved_problems)\n'
  printf '블록 안에 사람이 끼워 넣은 줄.\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$PR12/CLAUDE.md"
OUTR12="$(run "$HR12" "$PR12")"
echo "[stale] removing the retired block leaves a copy behind"
check "포인터: 블록 안 줄이 사본에 남는다" "grep -rqF '블록 안에 사람이 끼워 넣은 줄' '$HR12/.claude/disciplined-coder/backups'"
check "포인터: 사본 경로를 알린다"        "printf '%s' \"\$OUTR12\" | grep -qF '사본:'"
check "포인터: 사본은 전역에 쌓인다"      "[ ! -d '$PR12/backups' ]"

# (하) 사본을 못 뜨면 블록을 걷어내지 않는다. 못 뜨는 채로 걷어내면 되돌릴 방법이 없기 때문이다.
# backups 자리를 파일이 막고 있으면 mkdir이 실패한다 — 권한이나 백신이 막는 PC를 흉내 낸 것이다.
HR13="$(mktemp -d)"; PR13="$(mktemp -d)"; mkdir -p "$HR13/.claude/disciplined-coder"
printf 'backups 자리를 파일이 막고 있다\n' > "$HR13/.claude/disciplined-coder/backups"
{ printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '옛 포인터 본문.\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$PR13/CLAUDE.md"
OUTR13="$(run "$HR13" "$PR13")"
echo "[stale] a block that cannot be copied is left alone"
check "사본 실패: 블록을 안 걷어낸다"     "grep -qF 'BEGIN disciplined-coder' '$PR13/CLAUDE.md'"
check "사본 실패: 사유를 알린다"          "printf '%s' \"\$OUTR13\" | grep -qF '사본을 뜨지 못해'"
check "사본 실패: 나머지 셋업은 돈다"     "[ -f '$HR13/.claude/disciplined-coder/agent-principles.md' ]"

# (거) 머리말을 못 고친 사유를 가려 알린다. 경계를 못 찾은 것과 사본을 못 뜬 것은 사람이 할 일이
# 다르다 — 앞엣것은 로그를 손봐야 하고 뒤엣것은 쓰기 권한을 풀어야 한다. 한 문구로 뭉개면
# 쓰기가 막힌 PC에서 멀쩡한 머리말을 고치려 들게 되고, 그 신호는 끄는 수단이 없다.
HR14="$(mktemp -d)"; PR14="$(mktemp -d)"; mkdir -p "$HR14/.claude/disciplined-coder"
printf 'backups 자리를 파일이 막고 있다\n' > "$HR14/.claude/disciplined-coder/backups"
LOG14="$HR14/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems)\n\n'
  printf '옛 머리말이다.\n\n'
  printf -- '- **옛 항목** → 원인 → 해결\n'
} > "$LOG14"
BEFORE14="$(cksum < "$LOG14")"
OUTR14="$(run "$HR14" "$PR14")"
echo "[solved-rules] refusing for lack of a copy says which reason it was"
check "사본 실패: 로그 불변(바이트)"      "[ \"\$(cksum < '$LOG14')\" = '$BEFORE14' ]"
check "사본 실패: 공통 신호는 그대로"     "printf '%s' \"\$OUTR14\" | grep -qF '$NUDGE'"
check "사본 실패: 사본 사유를 알린다"     "printf '%s' \"\$OUTR14\" | grep -qF '사본을 뜨지 못해'"
check "사본 실패: 경계 문구는 안 쓴다"    "! printf '%s' \"\$OUTR14\" | grep -qF '머리말의 끝을 알아볼 수 없어'"

# --- header-boundary: 굵지 않은 항목 줄을 머리말로 먹지 않는다 ---
# 경계를 '모양'으로 짐작하면(굵지 않은 최상위 불릿이면 남은 규칙 불릿이다) 지시사항형 색인 줄을
# 머리말로 삼킨다. 쪼갠 로그의 색인 줄이 정확히 그 모양이라, 이 검사가 그 손실을 막는 유일한 그물이다.
HB1="$(mktemp -d)"; PB1="$(mktemp -d)"; mkdir -p "$HB1/.claude/disciplined-coder"
LOGB1="$HB1/.claude/disciplined-coder/solved_problems.md"
{ printf '# 해결된 문제 로그 (solved_problems) — PC 전역\n\n'
  printf '옛 스코프 문단이라 머리말이 낡음으로 판정된다.\n\n'
  printf '항목을 적는 형식은 이렇다.\n\n'
  printf -- '- 증상은 굵게 한 줄로 띄운다.\n'
  printf -- '- 원인과 해결은 그 아래 들여쓰기로 내린다.\n\n'
  printf -- '- 굵지 않은 첫째 항목 줄이다.\n'
  printf -- '- 굵지 않은 둘째 항목 줄이다.\n'
} > "$LOGB1"
run "$HB1" "$PB1" >/dev/null
echo "[header-boundary] a non-bold item line is not swallowed into the header"
check "boundary: 굵지 않은 첫째 항목 보존"  "grep -qF -- '- 굵지 않은 첫째 항목 줄이다.' '$LOGB1'"
check "boundary: 굵지 않은 둘째 항목 보존"  "grep -qF -- '- 굵지 않은 둘째 항목 줄이다.' '$LOGB1'"
check "boundary: 규칙 블록이 생겼다"        "grep -qF -- '항목이 스무 개를 넘으면' '$LOGB1'"
check "boundary: 옛 스코프 문단은 사라졌다" "! grep -qF -- '옛 스코프 문단이라' '$LOGB1'"
check "boundary: 규칙 불릿이 두 벌이 아니다" "[ \"\$(grep -c -- '- 증상은 굵게 한 줄로 띄운다.' '$LOGB1' || true)\" = 1 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
