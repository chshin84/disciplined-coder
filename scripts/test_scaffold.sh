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
check "user CLAUDE.md imports principles" "grep -qxF '@disciplined-coder/agent-principles.md' '$UC'"
check "managed region once"           "[ \$(grep -cF '# BEGIN disciplined-coder' '$UC') -eq 1 ]"
check "stdout has principle marker"   "printf '%s' \"\$OUT\" | grep -qF '# 디시플린 (팀 원칙)'"

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
  json_run "$prog" "$1" "$2"
}
. "$HERE/scripts/_json_valid.sh"   # 인터프리터 고르기는 한 곳(json_run)이 한다

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
OUT_A="$(run "$HA" "$PA" 2>/dev/null)"
SET_A="$HA/.claude/settings.json"; KNOWN_A="$HA/.claude/plugins/known_marketplaces.json"
echo "[marketplace-autoupdate] 자동 갱신을 켠다"
# 켰다는 사실은 stderr 가 아니라 stdout 으로 알린다 — SessionStart 의 stderr 는 사용자에게 닿지 않고,
# 옛 관리블록을 걷어낸 알림(pointer_note)이 이미 쓰는 통로가 stdout 이다. 사용자 설정 파일을 고쳐
# 놓고 아무도 모르게 두면 안 된다(FAIL-LOUD).
check "켰다는 알림이 stdout 으로 나간다"  "printf '%s' \"\$OUT_A\" | grep -qF '자동 갱신을 켰'"
check "알림에 고친 파일 경로가 있다"       "printf '%s' \"\$OUT_A\" | grep -qF 'settings.json'"
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
check "읽기 실패는 읽기 실패라고 말한다"    "printf '%s' \"\$ERR_D\" | grep -qF '읽지 못했거나 내용이 JSON이 아니다'"

# 읽기는 되는데 쓰기가 안 되는 회차. 임시 자리에 폴더를 두어 새 내용을 쓰지 못하게 만든다.
# 전에는 이 갈래가 읽기 실패와 같은 문구로 나와, 사람이 멀쩡한 설정 파일을 뜯어보게 만들었다.
HE="$(mktemp -d)"; PE="$(mktemp -d)"; mkdir -p "$HE/.claude"
MKTE="$(json_run 'import json,io,sys; print(json.load(io.open(sys.argv[1],encoding="utf-8"))["name"])' "$HERE/.claude-plugin/marketplace.json")"
printf '{ "extraKnownMarketplaces": { "%s": { "source": { "source": "github", "repo": "chshin84/disciplined-coder" } } } }\n' "$MKTE" > "$HE/.claude/settings.json"
mkdir -p "$HE/.claude/settings.json.dc-tmp/막는다"
set +e; ERR_E="$(run "$HE" "$PE" 2>&1 >/dev/null)"; set -e
echo "[marketplace-autoupdate] a write failure is reported as a write failure"
check "쓰기 실패에 자리가 따로 있다"        "printf '%s' \"\$ERR_E\" | grep -qF '고쳐 쓰지 못했다'"
check "쓰기 실패를 읽기 실패로 안 부른다"   "! printf '%s' \"\$ERR_E\" | grep -qF '읽지 못했거나 내용이 JSON이 아니다'"
check "쓰기 실패에도 설정은 그대로다"       "grep -qF '\"source\": \"github\"' '$HE/.claude/settings.json'"
check "쓰기 실패에도 임시 파일이 안 남는다" "[ ! -e '$HE/.claude/settings.json.dc-tmp' ]"

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

# --- user-content-preserved: 기존 user CLAUDE.md 내용 보존 + 블랭크 비누적 ---
H5="$(mktemp -d)"; P5="$(mktemp -d)"
mkdir -p "$H5/.claude"; printf 'my personal global note
' > "$H5/.claude/CLAUDE.md"
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

# USERPROFILE 갈래: CLAUDE_CONFIG_DIR도 CLAUDE_HOME_DIR도 없을 때 bash $HOME이 아니라 USERPROFILE을 따른다.
# 우선순위를 바꿔도 초록이던 구멍이라 이 갈래만 따로 밟는다. Windows 형식 경로는 cygpath가 있어야 만든다.
if command -v cygpath >/dev/null 2>&1; then
  H9B="$(mktemp -d)"; P9B="$(mktemp -d)"; HJUNK2="$(mktemp -d)"
  ( HOME="$HJUNK2" USERPROFILE="$(cygpath -w "$H9B")" CLAUDE_CONFIG_DIR= CLAUDE_HOME_DIR= CLAUDE_PROJECT_DIR="$P9B" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" >/dev/null 2>&1 ) || true
  echo "[home-resolution] USERPROFILE beats bash \$HOME when no override is set"
  check "USERPROFILE honored (KDIR)"            "[ -f '$H9B/.claude/disciplined-coder/agent-principles.md' ]"
  check "USERPROFILE: did not touch bash \$HOME" "[ ! -d '$HJUNK2/.claude' ]"
else
  echo "  (skip) cygpath 없음 — USERPROFILE 갈래 검사를 건너뛴다"
fi

# 프로젝트 폴더가 전역 설정 폴더 자신이면(작업 폴더가 ~/.claude) 프로젝트 CLAUDE.md와 전역 CLAUDE.md가
# 같은 파일이다. 문자열로만 견주던 판본은 Windows 형식과 POSIX 형식을 다른 파일로 보아 매 세션 전역
# 관리블록을 걷어냈다가 다시 넣고 사본을 하나씩 쌓았다.
if command -v cygpath >/dev/null 2>&1; then
  H24="$(mktemp -d)"; mkdir -p "$H24/.claude"; P24="$(cygpath -w "$H24/.claude")"
  CLAUDE_HOME_DIR="$H24/.claude" CLAUDE_PROJECT_DIR="$P24" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" >/dev/null 2>&1 || true
  OUT24="$(CLAUDE_HOME_DIR="$H24/.claude" CLAUDE_PROJECT_DIR="$P24" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" 2>/dev/null)"
  echo "[same-file] a project CLAUDE.md that is the global CLAUDE.md is left alone"
  check "같은 파일: 걷어냈다는 알림이 없다"  "! printf '%s' \"\$OUT24\" | grep -qF '옛 관리블록'"
  check "같은 파일: 사본을 쌓지 않는다"      "! ls '$H24/.claude/disciplined-coder/backups' 2>/dev/null | grep -q '^CLAUDE.md'"
  check "같은 파일: 관리블록이 하나다"       "[ \$(grep -cF '# BEGIN disciplined-coder' '$H24/.claude/CLAUDE.md') -eq 1 ]"
fi

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
CMD_SECTION="$(awk '/^## 커맨드/{f=1} f&&/^## /&&!/^## 커맨드/{exit} f' "$HERE/README.md")"
echo "[readme-commands-drift] README commands section covers commands/ dir"
for c in "$HERE"/commands/*.md; do
  n="/$(basename "$c" .md)"
  check "README commands section lists $n" "printf '%s' \"\$CMD_SECTION\" | grep -qF -- '$n'"
done

# --- workflow-verification-row: 검증 레이어 표에 워크플로 검증 행 존재(정본 계약 가드 — spec 검증 기준) ---
# 파일 전역 grep이 아니라 트리거 문자열이 있는 '그 행 한 줄'을 뽑아 검사한다 — 호출자 열(lens-*)과
# 강제 방식 열이 같은 행에 있음을 보장한다(다른 행·다른 파일의 문자열로 vacuous 통과 방지).
WF_BLOCK="$(awk '/^## 검증/{f=1} f&&/^## /&&!/^## 검증/{exit} f' "$HERE/agent-principles.md")"
echo "[workflow-verification] 검증 절이 렌즈와 기록을 요구한다"
check "검증 절이 잡힌다"           "[ -n \"\$WF_BLOCK\" ]"
check "렌즈 호출자를 가리킨다"     "printf '%s' \"\$WF_BLOCK\" | grep -qF 'lens-*'"
check "검증 기록은 호출자 스킬이 요구한다" "grep -qF 'docs/superpowers/reviews' \"$HERE/skills/domain-spec-review/SKILL.md\""
check "사라진 토글이 남아 있지 않다" "! printf '%s' \"\$WF_BLOCK\" | grep -qF 'ultracode 검증 모드'"

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
check "2nd run omits principles"      "! printf '%s' \"\$OUT20b\" | grep -qF '# 디시플린 (팀 원칙)'"
# 토글이 사라져 2회차에는 보낼 것이 없다. 빈 문자열을 단언해 두면 무엇이 새로 새어 나와도 실패한다
# — 부정 단언만 남기면 스크립트가 아무것도 못 내도 통과하는 vacuous 구멍이 생긴다.
check "2nd run sends nothing"         "[ -z \"\$OUT20b\" ]"

# --- crlf-import-line: CRLF 관리영역에서도 재주입하지 않는다 (had_import의 CR 내성) ---
H21="$(mktemp -d)"; P21="$(mktemp -d)"; mkdir -p "$H21/.claude/plugins"
# 이 홈은 정본 사본이 없어 "새로 깐 세션"으로 보이므로 카파시 넛지가 뜬다. 여기서 보려는 것은 CRLF 배선
# 인식뿐이라 설치 기록을 넣어 넛지를 잠재우고, "아무것도 안 보낸다" 단언은 그대로 둔다.
printf '{ "version": 2, "plugins": { "andrej-karpathy-skills@karpathy-skills": [ { "scope": "user" } ] } }
' > "$H21/.claude/plugins/installed_plugins.json"
printf '# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/agent-principles.md\r\n@disciplined-coder/domains-index.md\r\n@disciplined-coder/solved_problems.md\r\n# END disciplined-coder (managed — do not edit)\r\n' > "$H21/.claude/CLAUDE.md"
OUT21="$(run "$H21" "$P21")"
echo "[crlf-import-line] CRLF import line still counts as present"
check "CRLF: no canon re-dump"        "! printf '%s' \"\$OUT21\" | grep -qF '# 디시플린 (팀 원칙)'"
check "CRLF: sends nothing"           "[ -z \"\$OUT21\" ]"

# --- parallel-orchestration-nudge: 병렬 오케스트레이션 넛지(정본 계약 가드) ---
# 병렬 오케스트레이션 헤딩부터 다음 '### ' 또는 '## '까지의 블록만 뽑아 그 안에서 검사한다
# (vacuous 통과 방지).
PO_BLOCK="$(awk '/^## 병렬 오케스트레이션/{f=1} f&&/^## /&&!/^## 병렬 오케스트레이션/{exit} f' "$HERE/agent-principles.md")"
echo "[parallel-orchestration-nudge] principles 병렬 오케스트레이션 nested-orchestration nudge"
check "병렬 오케스트레이션 heading exists"      "printf '%s' \"\$PO_BLOCK\" | grep -qF '## 병렬 오케스트레이션'"
check "병렬 오케스트레이션 points to skill (SSOT)" "printf '%s' \"\$PO_BLOCK\" | grep -qF 'nested-orchestration'"
check "일이 하나뿐이면 낭비라고 적는다"       "printf '%s' \"\$PO_BLOCK\" | grep -qF '일이 하나뿐이면'"

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
for s in "원칙" "검증" "미해결의 처분" "병렬 오케스트레이션" "이 파일의 취급"; do
  check "canon: section '$s' present"      "grep -qE '^## $s\$' '$CANON'"
done
# 한글 탐지는 반드시 UTF-8 로케일에서 한다. 기본 C 로케일의 grep은 대괄호 범위를 바이트로 대조해
# 한글을 문자 단위로 매치하지 못하고, 그러면 옛 서수 제목이 되살아나도 이 검사가 잡지 못한다.
check "canon: no ordinal sections left"    "! LC_ALL=C.UTF-8 grep -qE '^### [가나다라마]\.' '$CANON'"

# --- karpathy-split: 정본에는 대화 규칙만 남고, 코드 규칙은 domain-coding, 문서 규칙은 domain-writing에 있다 ---
# 기준은 "파일을 하나도 건드리지 않은 답 한 번으로도 어길 수 있으면 정본에 남는다"이다. 산출물이 있어야만
# 어기는 규칙은 스킬로 갔고, 스킬은 훅이 열게 한다(코드 넛지는 test_hooks.sh가 본다).
echo "[karpathy-split] conversation rules stay in the canon; code and document rules live in skills"
# 제목 검사는 줄 전체를 앵커로 잡는다. `grep -F '## Think Before Acting'` 은 `### Think Before Acting` 을
# 부분 문자열로 맞혀 절이 안 올라가도 초록이 된다.
check "canon: Think Before Acting is a top-level section" "grep -qE '^## Think Before Acting$' '$CANON'"
check "canon: Think Before Acting is not a subsection"    "! grep -qE '^### Think Before Acting$' '$CANON'"
check "canon: no Tradeoff line"                      "! grep -qF '**Tradeoff:**' '$CANON'"
for h in "Simplicity First" "Surgical Changes" "Goal-Driven Execution"; do
  check "canon: no '$h' section"                     "! grep -qF '### $h' '$CANON'"
done
check "canon: subagent fleet rule stays"             "grep -qF \"Don't launch a fleet of subagents for what one call can do\" '$CANON'"
check "canon: fact-vs-judgment paragraph stays"      "grep -qF '사실과 판단은 다르다' '$CANON'"
check "canon: hygiene section gone"                  "! grep -qF '## 문서와 상태의 위생' '$CANON'"
check "canon: local-first convention gone"           "! grep -qF 'LOCAL-FIRST' '$CANON'"
for id in FAIL-LOUD KO-SYNTAX NAME-ITEMS PLAIN-KO PROSE-FORM READ-FLOW REVERSIBLE SECRETS; do
  check "canon: clause $id stays"                    "grep -qF '**\`$id\`' '$CANON'"
done
# 조항 이름은 정본에서도 살아 있는 문서에서도 되살아나면 안 된다. CLAUDE.md 도 함께 본다.
for id in ASK-FORK MEASURE-FIRST SIMPLE SURGICAL TDD EXPLAIN-STRUCTURE EXPLICIT FOCUSED IDEMPOTENT SSOT; do
  check "canon: old clause $id removed"              "! grep -qF '**\`$id\`' '$CANON'"
  check "live docs: no reference to $id"             "! grep -rqF '\`$id\`' '$HERE/skills' '$HERE/README.md' '$HERE/CLAUDE.md' '$HERE/scripts/scaffold.sh'"
done

DC="$HERE/skills/domain-coding/SKILL.md"
echo "[domain-coding] code rules live in one English skill"
check "domain-coding exists"                          "[ -f '$DC' ]"
for h in "Simplicity First" "Surgical Changes" "Goal-Driven Execution" "Do one thing well" "Single source of truth" "Idempotence" "Explicit is better than implicit" "Describe the change, not the diff"; do
  check "domain-coding: section '$h'"                 "grep -qE '^### $h\$' '$DC'"
done
for h in "Karpathy guidelines" "Principles" "Local first" "Reach"; do
  check "domain-coding: section '$h'"                 "grep -qE '^## $h\$' '$DC'"
done
check "domain-coding: Tradeoff line"                  "grep -qF '**Tradeoff:**' '$DC'"
check "domain-coding: never claim done"               "grep -qF 'Never claim \"done\" without execution evidence' '$DC'"
check "domain-coding: frontmatter name"               "grep -qF 'name: domain-coding' '$DC'"

DW="$HERE/skills/domain-writing/SKILL.md"
echo "[domain-writing] document-side karpathy rules live in one short English skill"
check "domain-writing exists"                         "[ -f '$DW' ]"
for h in "Simplicity First" "Surgical Changes" "Goal-Driven Execution" "Reach"; do
  check "domain-writing: section '$h'"                "grep -qE '^## $h\$' '$DW'"
done
check "domain-writing: frontmatter name"              "grep -qF 'name: domain-writing' '$DW'"

# --- standing-consent: 렌즈 호출에 대한 상시 허가가 정본에 있다 ---
# 세션 기본 지침이 "사용자가 요청하지 않으면 서브에이전트를 부르지 마라"로 들어오는 환경이 있다.
# 그 문구는 조건부라 사용자 지침으로 상시 허가를 남기면 열린다. 정본은 @import로 실리므로 이 한
# 문장이 있으면 검진이 돈다.
# 파일 전역 grep이 아니라 '검증 레이어' 절만 뽑아 그 안에서 본다 — 허가 문장과 범위를 좁히는 문장이
# 서로 떨어져 나가도 각각 어딘가에 남아 있으면 통과해 버리는 항진을 막는다(이 파일의 다른 절과 같은 방식).
SC_BLOCK="$(awk '/^## 검증/{f=1} f&&/^## /&&!/^## 검증/{exit} f' "$CANON")"
# 백틱이 든 패턴은 작은따옴표 변수에 담아 grep -qF -- 로 넘긴다 — 큰따옴표 안에 두면 eval을 지나며
# 명령 치환으로 실행되어, 검사가 엉뚱한 문자열을 찾으면서도 초록으로 남는다.
CONSENT='렌즈 호출은 사용자가 상시 허용한 것으로 본다'
SC_SCOPE='허가는 `lens-*` 호출에만 미친다'
echo "[standing-consent] lens calls carry the user's standing consent"
check "검증 절이 잡힌다"                   "[ -n \"\$SC_BLOCK\" ]"
check "canon: 상시 허가 문장"              "printf '%s' \"\$SC_BLOCK\" | grep -qF -- '$CONSENT'"
check "canon: 허가 범위 한정"              "printf '%s' \"\$SC_BLOCK\" | grep -qF -- \"\$SC_SCOPE\""
# 선행연구 렌즈는 이름을 대서 예외로 못 박아야 한다. 이름이 lens-*라 허가에 들면서 동시에 웹에
# 나가는 유일한 렌즈라, 뭉뚱그린 말로 제외하면 같은 렌즈를 열고 닫는 문장이 된다. 그 상태에서는
# 렌즈를 범위 밖으로 판단해 조용히 건너뛰게 되고, '막히면 알린다'는 안전장치도 발동하지 않는다.
check "canon: 선행연구 렌즈를 이름으로 예외" "printf '%s' \"\$SC_BLOCK\" | grep -qF -- 'lens-prior-art'"
check "canon: 뭉뚱그린 심층조사 표현 없음"   "! printf '%s' \"\$SC_BLOCK\" | grep -qF -- '심층조사'"
# 정본이 곧 주입 경로이므로, 갓 설치한 PC의 관리 디렉터리 사본에도 그 문장이 실려야 한다.
check "설치본에도 상시 허가 문장"          "grep -qF -- '$CONSENT' '$K/agent-principles.md'"

# --- question-tool: 갈림길은 질문 도구로 묻는다 (상시 로드 규칙) ---
# 이 규칙이 리뷰 스킬 한 곳에만 있으면 그 스킬을 열지 않은 세션에는 닿지 않는다. 실제로 문서 검진
# 세션이 다시 돌릴지를 평문으로 물어 선택 대화창이 뜨지 않았다. 묻는 방식은 특정 절차의 성질이 아니라
# 소통 규칙이므로 상시 로드되는 항목에 두고, 리뷰 스킬은 그것을 가리키기만 한다(SSOT).
SR="$HERE/skills/domain-spec-review/SKILL.md"
SR_ASK="$(grep -F '물을 때는' "$SR" || true)"
echo "[question-tool] the fork-in-the-road question rule is always loaded"
check "canon: 선택지 질문 규칙"             "grep -qF -- 'ask - as a question with options, never in plain prose' '$CANON'"
check "spec-review: 묻는 방식 줄이 있다"    "[ -n \"\$SR_ASK\" ]"
check "spec-review: 규칙을 재정의 말고 인용" "printf '%s' \"\$SR_ASK\" | grep -qF -- 'Think Before Acting'"

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
REACH_DOCS=("$HERE/README.md")
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

check "canon: 옛 도달 전제 제거"            "! grep -qF '서브에이전트도 이 글을 읽으므로' '$CANON'"
check "canon: 실린다고 가정하지 않는다"     "grep -qF '이 문서가 실린다고 가정하지 않는다' '$CANON'"

# --- lens-contract: 읽기 전용 렌즈를 띄우는 호출자 셋이 같은 계약에 닿는다 ---
# 전에는 셋이 규율 넷을 각자 적고 이 검사가 그 사본들을 맞춰 세웠다. 사본이라 갈라졌다 — 한 곳에서
# 재시도 금지 항목만 빠져 그 경로가 금지된 재시도를 허용한 채 오래 남았고, DESIGN-NOTES 쪽은 넷 중
# 둘만 갖고 있었다. 지금은 `domain-docs`가 규율을 소유하고 나머지는 가리키기만 한다(`SSOT`).
# 소유자가 규율을 갖는지와 다른 문서가 베끼지 않는지는 `test_docs_drift.sh`가 본다. 여기서는 호출자
# 셋이 그 소유자에 닿는지와 런타임 중립만 본다.
echo "[lens-contract] callers reach the canon-path rules and stay runtime-neutral"
for s in domain-spec-review domain-docs nested-orchestration; do
  F="$HERE/skills/$s/SKILL.md"
  check "$s: 정본 알리는 법에 닿는다"       "grep -qF '렌즈에게 정본을 알리는 법' '$F'"
  # 런타임 중립: 특정 에이전트 종류 이름과 관리 디렉터리 절대 경로를 박지 않는다.
  check "$s: Claude 전용 종류 이름 없음"    "! grep -qF 'Explore' '$F'"
  check "$s: 관리 디렉터리 절대경로 없음"   "! grep -qF '~/.claude/disciplined-coder/' '$F'"
done
# 렌즈 목록은 손으로 적지 않고 디렉터리에서 도출한다 — 렌즈를 더해도 사람이 목록을 맞출 필요가 없다(SSOT).
for D in "$HERE"/skills/lens-*/; do
  l="$(basename "$D" | sed 's/^lens-//')"
  F="$D/SKILL.md"
  check "lens-$l: SKILL.md 존재"        "[ -f '$F' ]"
  check "lens-$l: principles_applied"   "grep -qF 'principles_applied' '$F'"
  # 렌즈는 이 필드가 언제 필요한지를 스스로 규정하지 않고 정본으로 넘긴다. 예전에는 일곱 파일이
  # 같은 문단을 복제해 지켰는데, 그 사이 정본의 스키마 블록이 이 필드를 무조건 필수로 보이게 적어
  # 필수 여부가 두 곳에서 갈렸다. 지금은 정본 한 곳만 규정하고 렌즈는 가리키기만 한다(`SSOT`).
  PA_POINTER='`meta-aggregate`의 리뷰 산출물 계약이 정한다'
  check "lens-$l: 규칙을 정본으로 넘긴다" "grep -qF -- \"\$PA_POINTER\" '$F'"
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

# --- 낡은 락 빼앗기: 빼앗는 갈래도 한 번에 하나만 들어간다 ---
# 위 동시 진입 테스트는 락이 정상으로 도는 경로만 밟는다. 죽은 프로세스가 남긴 락을 빼앗는 갈래는
# 10초를 기다려야 열리므로 그 테스트가 구조적으로 못 밟는다. 그 갈래는 지우고 다시 잡는 두 걸음이
# 갈라져 있어 여럿이 함께 들어갔고, 결과 파일만 보면 고아 마커 복구가 손상을 덮어 초록으로 보였다.
# 그래서 결과가 아니라 임계 구역 출입 자체를 확인한다 — 들어가며 IN, 나가며 OUT을 적고 IN이 연달아
# 나오는지 본다. 잡은 시각을 한참 전으로 적은 락을 심어, 여섯이 동시에 빼앗으려 들게 만든다.
LT="$(mktemp -d)"; LW="$LT/witness"; LK="$LT/x.lock"; LN=6
: > "$LW"
mkdir "$LK"; printf '%s\n' "$(( $(date +%s) - 600 ))" > "$LK/heldsince"
for i in $(seq 1 "$LN"); do
  ( . "$HERE/scripts/_managed_block.sh"
    ltok="$(managed_block_lock "$LK")" || exit 1
    printf 'IN\n' >> "$LW"; sleep 0.3; printf 'OUT\n' >> "$LW"
    managed_block_unlock "$LK" "$ltok" ) 2>/dev/null &
done
wait
echo "[stale-lock] stealing a stale lock still admits one writer at a time"
check "낡은 락 빼앗기: 모두 들어갔다"          "[ \"\$(grep -c '^IN\$' '$LW')\" = '$LN' ]"
check "낡은 락 빼앗기: 겹쳐 들어가지 않았다"   "awk '\$0==\"IN\" && prev==\"IN\" { bad=1 } { prev=\$0 } END { exit bad?1:0 }' '$LW'"
check "낡은 락 빼앗기: 락이 남지 않는다"       "[ ! -e '$LK' ]"
check "낡은 락 빼앗기: 치운 락도 남지 않는다"  "[ -z \"\$(ls '$LT' | grep -v '^witness\$')\" ]"
# 락을 잡는 곳이 둘이라 한쪽만 고치면 다른 쪽에 옛 갈래가 남는다 — 잡는 코드는 헬퍼 한 곳에만 둔다.
check "락을 만드는 곳이 헬퍼 한 곳뿐이다"      "[ \"\$(grep -c 'mkdir \"\$lock\"' '$HERE/scripts/_managed_block.sh')\" = 1 ]"
check "호출자 둘 다 헬퍼를 거친다"             "[ \"\$(grep -c 'managed_block_lock \"\$lock\"' '$HERE/scripts/_managed_block.sh')\" = 2 ]"
check "빼앗기를 문지기 안에서 한다"            "grep -qF 'gate' '$HERE/scripts/_managed_block.sh'"

# --- 락에 주인이 있다: 빼앗긴 옛 주인이 새 주인의 락을 지우지 않는다 ---
# 전에는 푸는 쪽이 경로만 보고 지웠다. 그래서 낡았다고 락을 빼앗긴 프로세스가 제 일을 마치며
# unlock을 부르면 그새 새로 들어온 쪽의 락이 사라져 임계 구역에 둘이 함께 들어갔다.
echo "[lock-owner] a preempted holder must not delete the new holder's lock"
OT="$(mktemp -d)"; OL="$OT/o.lock"
OWN_TOK1="$( . "$HERE/scripts/_managed_block.sh"; managed_block_lock "$OL" )"
rm -rf "$OL"   # 빼앗김
OWN_TOK2="$( . "$HERE/scripts/_managed_block.sh"; managed_block_lock "$OL" )"
( . "$HERE/scripts/_managed_block.sh"; managed_block_unlock "$OL" "$OWN_TOK1" )   # 옛 주인이 푼다
check "락에 주인 토큰이 적힌다"                "[ -s '$OL/owner' ]"
check "두 토큰이 서로 다르다"                  "[ \"\$OWN_TOK1\" != \"\$OWN_TOK2\" ]"
check "옛 주인이 새 주인의 락을 안 지운다"     "[ -d '$OL' ]"
( . "$HERE/scripts/_managed_block.sh"; managed_block_unlock "$OL" "$OWN_TOK2" )
check "제 주인은 푼다"                         "[ ! -e '$OL' ]"
# 토큰을 안 주면 아무것도 하지 않는다 — 주인인지 알 수 없는 락을 지우는 것이 막으려는 그 일이다.
NT="$(mktemp -d)"; NL="$NT/n.lock"; mkdir "$NL"; date +%s > "$NL/heldsince"; echo other > "$NL/owner"
( . "$HERE/scripts/_managed_block.sh"; managed_block_unlock "$NL" )
check "토큰 없이 부르면 안 지운다"             "[ -d '$NL' ]"

# --- 락을 못 잡으면 멈추지 않고 물러난다 ---
# 홈에 쓸 수 없거나 남이 계속 잡고 있으면 이 반복문이 끝나지 않았다. SessionStart 훅 안에서 도므로
# 세션 시작이 멈춘 채 끝나지 않고 사용자에게는 원인도 안 떴다. 사유를 알리고 실패로 돌아와야 한다.
echo "[lock-timeout] an unobtainable lock must fail loudly instead of hanging"
TT="$(mktemp -d)"; TF="$TT/CLAUDE.md"; printf 'keep\n' > "$TF"
mkdir "$TF.lock"; date +%s > "$TF.lock/heldsince"; echo someone-else > "$TF.lock/owner"
TERR="$TT/err"; TRC=0
( . "$HERE/scripts/_managed_block.sh"
  MANAGED_LOCK_TOTAL_TICKS=5
  printf 'body\n' | managed_block_inject "$TF" "# B" "# E" ) 2>"$TERR" || TRC=$?
check "락을 못 잡으면 실패로 돌아온다"         "[ '$TRC' -ne 0 ]"
check "못 잡은 사유를 알린다"                  "grep -qF '락을 잡지 못했다' '$TERR'"
check "못 잡으면 파일을 안 고친다"             "[ \"\$(cat '$TF')\" = 'keep' ]"
check "남의 락을 안 건드린다"                  "[ -d '$TF.lock' ]"
# 부모 디렉터리가 없어 mkdir이 늘 실패하는 경우도 같은 길로 나온다.
NOPAR="$TT/없는폴더/x.lock"; PRC=0
( . "$HERE/scripts/_managed_block.sh"; MANAGED_LOCK_TOTAL_TICKS=5; managed_block_lock "$NOPAR" ) >/dev/null 2>&1 || PRC=$?
check "부모 폴더가 없어도 물러난다"            "[ '$PRC' -ne 0 ]"
# 상한 자체가 코드에 있는지 본다 — 지우면 다시 영원히 돈다.
check "총 대기 상한이 코드에 있다"             "grep -qF 'MANAGED_LOCK_TOTAL_TICKS' '$HERE/scripts/_managed_block.sh'"

# --- 걷어내기가 실패하면 원본을 갈아치우지 않는다 ---
# 주입과 걷어내기는 두 awk를 거쳐 원본을 바꿔치기한다. 앞 awk의 종료 코드를 안 보면 빈 임시 파일이
# 그대로 원본을 덮어, 사용자가 손으로 적은 줄이 사라진 채 관리블록만 남고 함수는 성공으로 돌아온다.
# 대상이 git 밖의 ~/.claude/CLAUDE.md 라 사본이 없으면 되돌릴 수단이 없다.
echo "[strip-fail] a failing strip pass must not blank the user's file"
AT="$(mktemp -d)"; AF="$AT/CLAUDE.md"; ABIN="$AT/bin"; mkdir -p "$ABIN"
printf 'user keep one\nuser keep two\n' > "$AF"
REALAWK="$(command -v awk)"
{ printf '#!/usr/bin/env bash\n'
  printf 'case "$*" in *"-v b="*) exit 1 ;; esac\n'
  printf 'exec %s "$@"\n' "$REALAWK"
} > "$ABIN/awk"; chmod +x "$ABIN/awk"
ARC=0
( . "$HERE/scripts/_managed_block.sh"
  PATH="$ABIN:$PATH"
  printf 'body\n' | managed_block_inject "$AF" "# B" "# E" ) >/dev/null 2>&1 || ARC=$?
check "걷어내기 실패: 사용자 줄이 남는다"    "[ \"\$(grep -c '^user keep' '$AF')\" = 2 ]"
check "걷어내기 실패: 실패로 돌아온다"       "[ '$ARC' -ne 0 ]"
check "걷어내기 실패: 관리블록을 안 남긴다"  "! grep -qF '# B' '$AF'"
check "걷어내기 실패: 임시 파일이 안 남는다" "[ -z \"\$(ls '$AT' | grep -v -e '^CLAUDE.md$' -e '^bin$')\" ]"


# 걷어내기 쪽도 같은 길로 나온다. 이쪽은 사본을 이미 떠 둔 뒤라, 원본을 그대로 두고 물러나야
# 사본과 원본이 함께 남는다.
RRC=0
AF2="$AT/PROJ.md"; printf 'user keep one\n# B\nold\n# E\n' > "$AF2"
( . "$HERE/scripts/_managed_block.sh"
  PATH="$ABIN:$PATH"
  managed_block_remove "$AF2" "# B" "# E" "$AT/backup.bak" ) >/dev/null 2>&1 || RRC=$?
check "걷어내기 실패: 변환 실패를 4로 알린다" "[ '$RRC' = 4 ]"
check "걷어내기 실패: 원본을 그대로 둔다"     "[ \"\$(grep -c '^user keep one$' '$AF2')\" = 1 ]"
check "걷어내기 실패: 사본은 남는다"          "[ -s '$AT/backup.bak' ]"
# 호출자가 그 사유를 삼키지 않는지 본다 — 조용히 넘어가면 사용자는 옛 블록이 왜 남았는지 모른다.
check "스캐폴드가 4를 알린다"                 "grep -qF 'prc\" -eq 4' '$HERE/scripts/scaffold.sh'"


# --- 커맨드가 시키는 보고를 스크립트가 실제로 낼 수 있다 ---
# 전에는 두 스캐폴드에 값을 한 번도 안 받는 created 변수와 그것을 조건으로 삼는 보고 줄이 있었고,
# 커맨드는 그 보고를 근거로 새로 생긴 파일과 이미 있던 파일을 알리라고 지시했다. 스크립트가 그
# 사실을 안 내므로 지시를 따르려면 지어내야 했다. 죽은 변수가 되살아나면 여기서 실패한다.
echo "[setup-report] the command may only ask for facts the script actually emits"
for S in scaffold.sh; do
  check "$S: 값을 안 받는 created 가 없다" "! grep -qE '(^|[^_a-zA-Z])created' '$HERE/scripts/$S'"
done
SDC="$HERE/commands/setup-discipline.md"
check "커맨드가 스크립트 출력을 전하라 한다" "grep -qF '스크립트가 낸 출력' '$SDC'"
check "커맨드가 새 파일 목록을 안 시킨다"    "! grep -qF '새로 생성' '$SDC'"


# --- 매니페스트 version 계약 ---
# Claude 매니페스트는 version을 비워 커밋 SHA 기반 자동 업데이트를 유지한다(domain-plugin).
# 값을 넣으면 버전 문자열 비교로 전환돼 값을 올리지 않는 한 새 커밋이 배포되지 않는다. 한 번 넣었다
# 되돌린 이력이 있어 사람 기억에 맡기지 않고 테스트로 고정한다.
check "Claude 매니페스트에 version 없음"  "! grep -qE '\"version\"[[:space:]]*:' '$HERE/.claude-plugin/plugin.json'"

HRS="$(mktemp -d)"; PRS="$(mktemp -d)"; mkdir -p "$HRS/.claude/disciplined-coder"
KS="$HRS/.claude/disciplined-coder"
printf 'old index
' > "$KS/advisors-index.md"; printf '내 백로그 한 줄
' > "$KS/unsolved_problems.md"
ERRS="$(CLAUDE_HOME_DIR="$HRS/.claude" CLAUDE_PROJECT_DIR="$PRS" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" 2>&1 >/dev/null)" || true
echo "[stale] renamed and retired managed files are cleared out"
check "stale: advisors-index 치움"        "[ ! -f '$KS/advisors-index.md' ]"
check "stale: unsolved_problems 치움"     "[ ! -f '$KS/unsolved_problems.md' ]"
check "stale: 잔존 경고 없음"             "! printf '%s' \"\$ERRS\" | grep -qF '비관리 파일'"
check "stale: 내용은 백업에 남는다"       "grep -rqF '내 백로그 한 줄' '$KS/backups'"

# 오답노트를 폴더로 쪼갰던 PC에는 파일이 아니라 디렉터리가 남는다. 치우기 반복문이 정규 파일만
# 보던 판본은 그것을 건너뛰었고, 뒤이은 화이트리스트 반복문이 '비관리 디렉터리 잔존' 경고를 냈다.
# 스캐폴드에는 그 경고를 해소할 수단이 없어 사용자가 손으로 지울 때까지 매 세션 되풀이됐다.
HSD="$(mktemp -d)"; PSD="$(mktemp -d)"; mkdir -p "$HSD/.claude/disciplined-coder/solved_problems"
KSD="$HSD/.claude/disciplined-coder"
printf '쪼갠 오답노트 한 줄\n' > "$KSD/solved_problems/2026-01-01.md"
ERRSD="$(CLAUDE_HOME_DIR="$HSD/.claude" CLAUDE_PROJECT_DIR="$PSD" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" 2>&1 >/dev/null)" || true
echo "[stale-dir] a retired managed directory is filed away, not warned about forever"
check "stale-dir: 디렉터리를 치운다"       "[ ! -d '$KSD/solved_problems' ]"
check "stale-dir: 내용은 백업에 남는다"    "grep -rqF '쪼갠 오답노트 한 줄' '$KSD/backups'"
check "stale-dir: 해소 못 할 경고가 없다"  "! printf '%s' \"\$ERRSD\" | grep -qF '비관리 디렉터리'"


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

COMMON="$HERE/scripts/_scaffold_common.sh"

HK1="$(mktemp -d)"; KK1="$HK1/.claude/disciplined-coder"; mkdir -p "$KK1"
printf '사용자가 적어 둔 줄
' > "$KK1/coding-principles.md"
printf 'block
' > "$KK1/backups"
ERRK1="$( . "$COMMON"; scaffold_hygiene "$KK1" 2>&1 >/dev/null || true )"
echo "[stale-keep] a stale file survives when its backup cannot be written"
check "stale-keep: 내용이 든 파일이 남는다" "[ -f '$KK1/coding-principles.md' ]"
check "stale-keep: 조용히 넘어가지 않는다" "printf '%s' \"$ERRK1\" | grep -qF -- '사본으로 못 옮겨 그대로 두었다'"
# --- karpathy-nudge: 카파시 플러그인 설치 넛지 — 정본이 새로 깔리거나 갱신된 세션에, 그 플러그인이 없을 때만 ---
H30="$(mktemp -d)"; P30="$(mktemp -d)"
OUT30a="$(run "$H30" "$P30")"
OUT30b="$(run "$H30" "$P30")"
# 갱신 재현: 전역 사본을 낡게 만들면 다음 세션에 정본이 다시 복사되므로 갱신 뒤 첫 세션과 같다.
printf 'stale
' > "$H30/.claude/disciplined-coder/agent-principles.md"
OUT30c="$(run "$H30" "$P30")"
H31="$(mktemp -d)"; P31="$(mktemp -d)"; mkdir -p "$H31/.claude/plugins"
printf '{ "version": 2, "plugins": { "andrej-karpathy-skills@karpathy-skills": [ { "scope": "user" } ] } }
' > "$H31/.claude/plugins/installed_plugins.json"
OUT31="$(run "$H31" "$P31")"
echo "[karpathy-nudge] karpathy plugin install nudge on install/update sessions only"
check "fresh install: nudge names the plugin"   "printf '%s' \"\$OUT30a\" | grep -qF 'andrej-karpathy-skills@karpathy-skills'"
check "fresh install: nudge gives marketplace"  "printf '%s' \"\$OUT30a\" | grep -qF 'forrestchang/andrej-karpathy-skills'"
check "unchanged session: no nudge"             "! printf '%s' \"\$OUT30b\" | grep -qF 'karpathy'"
check "updated canon: nudge again"              "printf '%s' \"\$OUT30c\" | grep -qF 'andrej-karpathy-skills@karpathy-skills'"
check "already installed: no nudge"             "! printf '%s' \"\$OUT31\" | grep -qF 'karpathy'"
check "already installed: still scaffolds"      "[ -f '$H31/.claude/disciplined-coder/agent-principles.md' ]"

echo "[notice-encoding] user-facing notices are not double-encoded"
check "notice: 공통 헬퍼에 깨진 표시 없음" "! grep -qF -- 'ð' \"$COMMON\""

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
