#!/usr/bin/env bash
# scaffold.sh(PC-레벨) 검증. 계약: FAIL=0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
# 픽스처는 모두 이 뿌리 아래에 만들고 끝나면 통째로 지운다. mktemp 가 TMPDIR 을 따르므로 아래의
# mktemp 호출과 이 검사가 부르는 스크립트의 임시 파일이 모두 여기로 온다.
TEST_TMP="$(mktemp -d)"; trap 'rm -rf "$TEST_TMP"' EXIT; export TMPDIR="$TEST_TMP"
SCAFFOLD="$HERE/scripts/scaffold.sh"

pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# 이웃 관계 검사: 파일에서 pattern과 정확히 일치하는 첫 줄 '바로 다음 줄'이 빈 줄인지 확인한다.
# 전역 grep -c '^$' 카운트는 관리블록이 항상 넣는 구분 빈 줄과 뒤섞여 무조건 참이 되므로 쓰지 않는다.
blank_follows() {  # $1=file $2=exact-line-pattern
  awk -v pat="$2" 'matched && !verified { verified=1; if ($0=="") ok=1 } $0==pat { matched=1 } END { exit (ok==1 ? 0 : 1) }' "$1"
}

# PYTHONUTF8 안내는 OS 와 레지스트리를 읽어 판정하므로 픽스처마다 상태를 주입해 고정한다. run() 을
# 거치지 않고 $SCAFFOLD 를 직접 부르는 픽스처가 여럿이라 헬퍼가 아니라 파일 머리에서 내보낸다.
# 이것이 없으면 CI(ubuntu)와 변수를 넣은 윈도우 PC 와 안 넣은 PC 에서 결과가 갈린다.
: "${UTF8_STATE:=on}"
export DISCIPLINED_CODER_UTF8_STATE="$UTF8_STATE"

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
# 금지 표현 목록은 중립 이름의 공용 블록이 싣는다. 규약 원본은 KiwoomAX/korean-banned-words 의
# import-protocol.md 다. 여기는 아무것도 없는 PC 라 우리가 블록을 만들고 우리 목록을 가리킨다.
check "banlist: 공용 블록을 만든다"       "[ \$(grep -cF '# BEGIN korean-banned-words' '$UC') -eq 1 ]"
check "banlist: 블록이 우리를 가리킨다"   "sed -n '/BEGIN korean-banned-words/,/END korean-banned-words/p' '$UC' | grep -qxF '@disciplined-coder/korean-banned-words.md'"
check "banlist: 관리블록에는 목록이 없다" "! sed -n '/BEGIN disciplined-coder/,/END disciplined-coder/p' '$UC' | grep -q 'korean-banned-words'"
check "banlist: 파일도 놓인다"          "[ -f '$K/korean-banned-words.md' ]"
check "stdout has principle marker"   "printf '%s' \"\$OUT\" | grep -qF '# 디시플린코더(혹은 dc코더)'"

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
# 놓고 아무도 모르게 두면 안 된다.
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
check "깨진 설정에도 에이전트원칙은 깔린다"        "[ -f '$HD/.claude/disciplined-coder/agent-principles.md' ]"
set +e; ERR_D="$(run "$HD" "$PD" 2>/dev/null)"; set -e
check "깨진 설정을 조용히 넘기지 않는다"    "printf '%s' \"\$ERR_D\" | grep -qF 'autoUpdate 설정을 건너뛴다'"
check "읽기 실패는 읽기 실패라고 말한다"    "printf '%s' \"\$ERR_D\" | grep -qF '읽지 못했거나 내용이 JSON이 아니다'"

# 읽기는 되는데 쓰기가 안 되는 회차. 임시 자리에 폴더를 두어 새 내용을 쓰지 못하게 만든다.
# 전에는 이 갈래가 읽기 실패와 같은 문구로 나와, 사람이 멀쩡한 설정 파일을 뜯어보게 만들었다.
HE="$(mktemp -d)"; PE="$(mktemp -d)"; mkdir -p "$HE/.claude"
MKTE="$(json_run 'import json,io,sys; print(json.load(io.open(sys.argv[1],encoding="utf-8"))["name"])' "$HERE/.claude-plugin/marketplace.json")"
printf '{ "extraKnownMarketplaces": { "%s": { "source": { "source": "github", "repo": "chshin84/disciplined-coder" } } } }\n' "$MKTE" > "$HE/.claude/settings.json"
mkdir -p "$HE/.claude/settings.json.dc-tmp/막는다"
set +e; ERR_E="$(run "$HE" "$PE" 2>/dev/null)"; set -e
echo "[marketplace-autoupdate] a write failure is reported as a write failure"
check "쓰기 실패에 자리가 따로 있다"        "printf '%s' \"\$ERR_E\" | grep -qF '고쳐 쓰지 못했다'"
check "쓰기 실패를 읽기 실패로 안 부른다"   "! printf '%s' \"\$ERR_E\" | grep -qF '읽지 못했거나 내용이 JSON이 아니다'"
# 사유는 stdout 으로 나오되 "켰다" 머리말 아래 섞이지 않는다. 이 픽스처는 켠 것이 없는 갈래라
# 머리말이 아예 없어야 한다. 같은 블록에 섞어 찍으면 고친 파일 목록으로 읽힌다.
check "실패 사유가 켰다는 머리말 아래 안 섞인다" "printf '%s' \"\$ERR_E\" | grep -qF '고쳐 쓰지 못했다' && ! printf '%s' \"\$ERR_E\" | grep -qF '자동 갱신을 켰다'"
check "쓰기 실패에도 설정은 그대로다"       "grep -qF '\"source\": \"github\"' '$HE/.claude/settings.json'"
check "쓰기 실패에도 임시 파일이 안 남는다" "[ ! -e '$HE/.claude/settings.json.dc-tmp' ]"

# --- project-untouched: 프로젝트 폴더 무오염 ---
echo "[project-untouched] project untouched"
check "no principles in project"      "[ ! -f '$P1/agent-principles.md' ]"
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
# 블록이 둘(관리블록과 공용 블록)이라 각 블록 앞의 구분 빈 줄로 둘까지 나온다. 이 검사가
# 막으려는 것은 실행을 거듭할 때 빈 줄이 쌓이는 것이므로 상한만 블록 수에 맞춘다.
check "blank lines bounded (<=2)"    "[ \$(grep -c '^\$' '$UC5') -le 2 ]"

# --- banlist-shared: 공용 블록 규약의 판정 절차 ---
# 규약 원본은 KiwoomAX/korean-banned-words 의 import-protocol.md 다. 목록을 싣는 플러그인이
# 둘이라 각자 자기 마커 블록에 두면 두 벌이 실리고 결과가 도는 차례에 따라 갈린다. 아래가
# 판정 절차의 줄기를 하나씩 확인한다. 우리 판은 생성물에서 읽어 쓴다 — 숫자를 박으면 목록이
# 갱신될 때마다 이 검사가 거짓으로 통과한다.
BANV="$(head -20 "$HERE/korean-banned-words.md" | grep -o 'schema [0-9]*, [0-9][0-9-]*' | head -1)"
ban_fixture() {  # $1=HOME $2=판 표시 줄 → 그 목록을 깔고 공용 블록이 그것을 가리키게 한다
  mkdir -p "$1/.claude/other"
  printf '# 목록\n\n생성물\n\n원본\n방법\n%s\n' "$2" > "$1/.claude/other/korean-banned-words.md"
  printf '# BEGIN korean-banned-words (shared — do not edit)\n@other/korean-banned-words.md\n# END korean-banned-words (shared — do not edit)\n' > "$1/.claude/CLAUDE.md"
}

H22="$(mktemp -d)"; P22="$(mktemp -d)"; mkdir -p "$H22/.claude"
ban_fixture "$H22" '<!-- 원본 판: schema 99, 2099-01-01, aaaaaaaaaaaa -->'
run "$H22" "$P22" >/dev/null
UC22="$H22/.claude/CLAUDE.md"
echo "[banlist-shared] 상대가 더 최신이면 안 건드린다"
check "남의 줄이 그대로다"            "grep -qxF '@other/korean-banned-words.md' '$UC22'"
check "우리 줄을 안 넣는다"           "! grep -qF '@disciplined-coder/korean-banned-words.md' '$UC22'"
check "파일은 그래도 놓는다"          "[ -f '$H22/.claude/disciplined-coder/korean-banned-words.md' ]"

H23="$(mktemp -d)"; P23="$(mktemp -d)"; mkdir -p "$H23/.claude"
ban_fixture "$H23" '<!-- 원본 판: schema 0, 2000-01-01, aaaaaaaaaaaa -->'
OUT23="$(run "$H23" "$P23")"
UC23="$H23/.claude/CLAUDE.md"
echo "[banlist-shared] 상대가 낡으면 우리 것으로 바꾼다"
check "우리 줄로 바뀐다"              "sed -n '/BEGIN korean-banned-words/,/END korean-banned-words/p' '$UC23' | grep -qxF '@disciplined-coder/korean-banned-words.md'"
check "남의 줄이 사라진다"            "! grep -qF '@other/korean-banned-words.md' '$UC23'"
check "블록이 하나뿐이다"             "[ \$(grep -cF '# BEGIN korean-banned-words' '$UC23') -eq 1 ]"
check "바꿨다고 알린다"               "printf '%s' \"\$OUT23\" | grep -qF '공용 금지 표현 블록을 고쳤다'"

H24="$(mktemp -d)"; P24="$(mktemp -d)"; mkdir -p "$H24/.claude"
printf '# BEGIN korean-banned-words (shared — do not edit)\n@gone/korean-banned-words.md\n# END korean-banned-words (shared — do not edit)\n' > "$H24/.claude/CLAUDE.md"
run "$H24" "$P24" >/dev/null
UC24="$H24/.claude/CLAUDE.md"
echo "[banlist-shared] 없는 파일을 가리키면 우리 것으로 바꾼다"
check "우리 줄로 바뀐다"              "sed -n '/BEGIN korean-banned-words/,/END korean-banned-words/p' '$UC24' | grep -qxF '@disciplined-coder/korean-banned-words.md'"

H25="$(mktemp -d)"; P25="$(mktemp -d)"; mkdir -p "$H25/.claude"
ban_fixture "$H25" "<!-- 원본 판: $BANV, ffffffffffff -->"
OUT25="$(run "$H25" "$P25")"
UC25="$H25/.claude/CLAUDE.md"
echo "[banlist-shared] 판이 같고 내용이 다르면 그대로 두고 알린다"
check "남의 줄이 그대로다"            "grep -qxF '@other/korean-banned-words.md' '$UC25'"
check "판단 불가를 알린다"            "printf '%s' \"\$OUT25\" | grep -qF '판은 같은데 내용이 다르다'"

H26="$(mktemp -d)"; P26="$(mktemp -d)"; mkdir -p "$H26/.claude"
printf '# 내 설정\n\n@somewhere/korean-banned-words.md\n' > "$H26/.claude/CLAUDE.md"
OUT26="$(run "$H26" "$P26")"
UC26="$H26/.claude/CLAUDE.md"
# 사용자가 손으로 적은 줄이다. 마커 블록 안이 아니므로 지울 쪽도 고칠 쪽도 없다. 이것 때문에
# 기다리면 공용 블록이 영영 안 생기므로, 블록은 만들고 그 줄은 지우지 않고 알리기만 한다.
echo "[banlist-shared] 사용자가 적은 줄은 기다림의 근거가 아니다"
check "남의 줄을 안 지운다"           "grep -qxF '@somewhere/korean-banned-words.md' '$UC26'"
check "공용 블록을 만든다"            "[ \$(grep -cF '# BEGIN korean-banned-words' '$UC26') -eq 1 ]"
check "바깥 줄을 알린다"              "printf '%s' \"\$OUT26\" | grep -qF '블록 바깥에 목록을 싣는 줄이 있다'"

# --- banlist-transition: 남의 마커 블록 안의 줄일 때만 비킨다 ---
# 상대 플러그인이 아직 자기 블록에서 목록을 싣는 전환 구간이다. 여기서 공용 블록을 만들면 목록이
# 두 벌 실려, 이 규약이 없애려던 상태가 채택이 끝날 때까지 계속된다.
H27="$(mktemp -d)"; P27="$(mktemp -d)"; mkdir -p "$H27/.claude"
printf '# BEGIN AX 설치 (자동 생성 영역)\n@kw-ax/korean-banned-words.md\n# END AX 설치\n' > "$H27/.claude/CLAUDE.md"
OUT27="$(run "$H27" "$P27")"
UC27="$H27/.claude/CLAUDE.md"
echo "[banlist-transition] 남의 블록 안의 줄이면 비킨다"
check "공용 블록을 안 만든다"         "[ \$(grep -cF '# BEGIN korean-banned-words' '$UC27') -eq 0 ]"
check "목록이 한 벌만 실린다"         "[ \$(grep -c '^@.*korean-banned-words' '$UC27') -eq 1 ]"
check "남의 줄을 안 지운다"           "grep -qxF '@kw-ax/korean-banned-words.md' '$UC27'"
check "기다린다고 알린다"             "printf '%s' \"\$OUT27\" | grep -qF '공용 블록을 만들지 않았다'"
check "에이전트원칙 줄은 그대로 쓴다"         "grep -qxF '@disciplined-coder/agent-principles.md' '$UC27'"

# --- banlist-orphan: 끝나는 짝이 없는 BEGIN 은 블록을 열지 않는다 ---
# 고아 BEGIN 을 열린 채로 두면 그 뒤의 모든 줄이 남의 블록 안으로 보여, 사용자가 적은 줄까지
# 기다림의 근거가 되어 공용 블록이 영영 안 생긴다. 이 저장소는 고아 BEGIN 을 이미 겪었다.
H28="$(mktemp -d)"; P28="$(mktemp -d)"; mkdir -p "$H28/.claude"
printf '# BEGIN 남의 블록\n무언가\n\n@somewhere/korean-banned-words.md\n' > "$H28/.claude/CLAUDE.md"
OUT28="$(run "$H28" "$P28")"
UC28="$H28/.claude/CLAUDE.md"
echo "[banlist-orphan] 고아 BEGIN 은 블록으로 세지 않는다"
check "공용 블록을 만든다"            "[ \$(grep -cF '# BEGIN korean-banned-words' '$UC28') -eq 1 ]"
check "사용자 줄로 보아 알린다"       "printf '%s' \"\$OUT28\" | grep -qF '블록 바깥에 목록을 싣는 줄이 있다'"
check "기다린다고 알리지 않는다"      "! printf '%s' \"\$OUT28\" | grep -qF '공용 블록을 만들지 않았다'"
check "남의 줄을 안 지운다"           "grep -qxF '@somewhere/korean-banned-words.md' '$UC28'"
check "에이전트원칙 줄은 그대로 쓴다"         "grep -qxF '@disciplined-coder/agent-principles.md' '$UC28'"
# 관리블록은 에이전트원칙 줄 하나뿐이어야 한다. 목록이 거기 남으면 공용 블록과 합쳐 두 벌이 실린다.
check "관리블록에 군더더기가 안 남는다" "[ \$(sed -n '/BEGIN disciplined-coder/,/END disciplined-coder/p' '$UC28' | wc -l) -eq 3 ]"

# 멱등. 바꾼 PC 를 두 번 더 돌려도 블록은 하나이고 가리키는 곳이 그대로다.
run "$H23" "$P23" >/dev/null; run "$H23" "$P23" >/dev/null
echo "[banlist-shared] 여러 번 돌려도 같다"
check "블록이 여전히 하나다"          "[ \$(grep -cF '# BEGIN korean-banned-words' '$UC23') -eq 1 ]"
check "가리키는 곳이 그대로다"        "sed -n '/BEGIN korean-banned-words/,/END korean-banned-words/p' '$UC23' | grep -qxF '@disciplined-coder/korean-banned-words.md'"

# --- install-current: 설치본이 사본보다 뒤처지면 옮기고 다시 켜라고 알린다 ---
# 자동 갱신 플래그만으로는 모자라다. 사본을 받아 놓고도 설치본을 안 옮기는 것이 이 PC 에서 실제로
# 있었다. 훅은 깔려 있는 판으로만 도므로, 이 확인이 없으면 옛 판이 조용히 돈다.
# claude 를 실제로 부르지 않도록 스텁을 주입한다. 스텁은 받은 인자를 파일에 적어 두어, 무엇을
# 실행했는지 단언할 수 있게 한다.
cur_fixture() {  # $1=HOME $2=설치본 커밋 $3=스텁 종료 코드 → 사본의 HEAD 를 출력한다
  mkdir -p "$1/.claude/plugins/marketplaces/chshin-tools"
  printf '{ "version": 2, "plugins": { "disciplined-coder@chshin-tools": [ { "scope": "user", "gitCommitSha": "%s" } ] } }\n' "$2" > "$1/.claude/plugins/installed_plugins.json"
  git init -q "$1/.claude/plugins/marketplaces/chshin-tools"
  git -C "$1/.claude/plugins/marketplaces/chshin-tools" -c user.email=t@t -c user.name=t commit -q --allow-empty -m x
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >> "%s/args.txt"\nexit %s\n' "$1" "$3" > "$1/claude-stub"
  chmod +x "$1/claude-stub"
  git -C "$1/.claude/plugins/marketplaces/chshin-tools" rev-parse HEAD
}

H30="$(mktemp -d)"; P30="$(mktemp -d)"; mkdir -p "$H30/.claude"
cur_fixture "$H30" "0000000000000000000000000000000000000000" 0 > /dev/null
export DISCIPLINED_CODER_CLAUDE_BIN="$H30/claude-stub"
OUT30="$(run "$H30" "$P30")"
unset DISCIPLINED_CODER_CLAUDE_BIN
echo "[install-current] 뒤처지면 옮기고 다시 켜라고 알린다"
check "갱신을 실행한다"              "grep -qF 'plugin update disciplined-coder@chshin-tools' '$H30/args.txt'"
check "다시 켜라고 알린다"           "printf '%s' \"\$OUT30\" | grep -qF '다시 켜야 새 판이 실린다'"

H31="$(mktemp -d)"; P31="$(mktemp -d)"; mkdir -p "$H31/.claude"
cur_fixture "$H31" "0000000000000000000000000000000000000000" 7 > /dev/null
export DISCIPLINED_CODER_CLAUDE_BIN="$H31/claude-stub"
OUT31="$(run "$H31" "$P31")"
unset DISCIPLINED_CODER_CLAUDE_BIN
echo "[install-current] 못 옮기면 사유와 직접 실행할 명령을 보인다"
check "조용히 넘기지 않는다"         "printf '%s' \"\$OUT31\" | grep -qF '옮기지 못했다'"
check "직접 실행할 명령을 보인다"    "printf '%s' \"\$OUT31\" | grep -qF 'plugin update disciplined-coder@chshin-tools'"

H32="$(mktemp -d)"; P32="$(mktemp -d)"; mkdir -p "$H32/.claude"
CUR_HEAD="$(cur_fixture "$H32" "dummy" 0)"
printf '{ "version": 2, "plugins": { "disciplined-coder@chshin-tools": [ { "scope": "user", "gitCommitSha": "%s" } ] } }\n' "$CUR_HEAD" > "$H32/.claude/plugins/installed_plugins.json"
export DISCIPLINED_CODER_CLAUDE_BIN="$H32/claude-stub"
OUT32="$(run "$H32" "$P32")"
unset DISCIPLINED_CODER_CLAUDE_BIN
echo "[install-current] 최신이면 조용하다"
check "갱신을 실행하지 않는다"       "[ ! -f '$H32/args.txt' ]"
check "아무 말도 안 한다"            "! printf '%s' \"\$OUT32\" | grep -qF '설치본이 사본보다'"

H33="$(mktemp -d)"; P33="$(mktemp -d)"; mkdir -p "$H33/.claude/plugins"
printf '{ "version": 2, "plugins": { "superpowers@claude-plugins-official": [ { "scope": "user" } ] } }\n' > "$H33/.claude/plugins/installed_plugins.json"
OUT33="$(run "$H33" "$P33")"
echo "[install-current] 우리 설치 기록이 없으면 건너뛴다"
check "아무 말도 안 한다"            "! printf '%s' \"\$OUT33\" | grep -qF '설치본이 사본보다'"

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

# --- missing-canon: 에이전트원칙 소스 부재 → 경고(stderr) + 계속 진행(exit 0) ---
H8="$(mktemp -d)"; P8="$(mktemp -d)"; ED="$(mktemp -d)"   # ED = 에이전트원칙 없는 빈 plugin root
set +e
ERR8="$(CLAUDE_HOME_DIR="$H8/.claude" CLAUDE_PROJECT_DIR="$P8" CLAUDE_PLUGIN_ROOT="$ED" bash "$SCAFFOLD" 2>/dev/null)"; rc8=$?
set -e
echo "[missing-canon] missing source → warning, exit 0"
check "missing source warns to stdout"      "printf '%s' \"\$ERR8\" | grep -qF 'WARNING: source not found'"
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
  HSF="$(mktemp -d)"; mkdir -p "$HSF/.claude"; PSF="$(cygpath -w "$HSF/.claude")"
  CLAUDE_HOME_DIR="$HSF/.claude" CLAUDE_PROJECT_DIR="$PSF" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" >/dev/null 2>&1 || true
  OUTSF="$(CLAUDE_HOME_DIR="$HSF/.claude" CLAUDE_PROJECT_DIR="$PSF" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" 2>/dev/null)"
  echo "[same-file] a project CLAUDE.md that is the global CLAUDE.md is left alone"
  check "같은 파일: 걷어냈다는 알림이 없다"  "! printf '%s' \"\$OUTSF\" | grep -qF '옛 관리블록'"
  check "같은 파일: 사본을 쌓지 않는다"      "! ls '$HSF/.claude/disciplined-coder/backups' 2>/dev/null | grep -q '^CLAUDE.md'"
  check "같은 파일: 관리블록이 하나다"       "[ \$(grep -cF '# BEGIN disciplined-coder' '$HSF/.claude/CLAUDE.md') -eq 1 ]"
fi

# --- managed-dir-hygiene: 관리 디렉터리 위생 — 구 관리파일 제거·에이전트원칙/사용자데이터 보존·빈 고아 제거 ---
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

# --- stale-toggle-files: 없앤 토글이 남긴 상태 파일은 STALE로 지운다 ---
# 화이트리스트에서 빼기만 하면 매 세션 경고가 남는다.
H12="$(mktemp -d)"; P12="$(mktemp -d)"; K12="$H12/.claude/disciplined-coder"
run "$H12" "$P12" >/dev/null
printf 'issues\n' > "$K12/issue-mode"; printf 'required\n' > "$K12/ultracode-review"
ERR12b="$(run "$H12" "$P12" 2>&1 >/dev/null)" || true
echo "[stale-toggle-files] 남은 토글 상태 파일을 지운다"
check "잔존 issue-mode 를 지운다"            "[ ! -f '$K12/issue-mode' ]"
check "잔존 ultracode-review 를 지운다"      "[ ! -f '$K12/ultracode-review' ]"
check "잔존 파일에 경고를 남기지 않는다"     "! printf '%s' \"\$ERR12b\" | grep -qF '비관리 파일'"

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

# --- canon-first-run-only: 에이전트원칙 stdout 덤프는 첫 설치 세션에만 (이중 주입 회귀 가드) ---
H20="$(mktemp -d)"; P20="$(mktemp -d)"; mkdir -p "$H20/.claude/plugins"
# 여기서 보려는 것은 에이전트원칙 덤프가 첫 회차에만 나오는지다. 함께 쓰는 플러그인 알림이 섞이면
# "2회차에 아무것도 안 보낸다" 단언이 그 알림 때문에 실패하므로 설치 기록을 넣어 잠재운다.
printf '{ "version": 2, "plugins": { "superpowers@claude-plugins-official": [ { "scope": "user" } ] } }
' > "$H20/.claude/plugins/installed_plugins.json"
OUT20a="$(run "$H20" "$P20")"
OUT20b="$(run "$H20" "$P20")"
echo "[canon-first-run-only] canon dumped on first run only"
check "1st run dumps principles"      "printf '%s' \"\$OUT20a\" | grep -qF '# 디시플린코더(혹은 dc코더)'"
check "2nd run omits principles"      "! printf '%s' \"\$OUT20b\" | grep -qF '# 디시플린코더(혹은 dc코더)'"
# 토글이 사라져 2회차에는 보낼 것이 없다. 빈 문자열을 단언해 두면 무엇이 새로 새어 나와도 실패한다
# — 부정 단언만 남기면 스크립트가 아무것도 못 내도 통과하는 vacuous 구멍이 생긴다.
check "2nd run sends nothing"         "[ -z \"\$OUT20b\" ]"

# --- crlf-import-line: CRLF 관리영역에서도 재주입하지 않는다 (had_import의 CR 내성) ---
H21="$(mktemp -d)"; P21="$(mktemp -d)"; mkdir -p "$H21/.claude/plugins"
# 여기서 보려는 것은 CRLF 배선 인식뿐이라 함께 쓰는 플러그인 둘의 설치 기록을 넣어 그 알림을
# 잠재우고, "아무것도 안 보낸다" 단언은 그대로 둔다.
printf '{ "version": 2, "plugins": { "superpowers@claude-plugins-official": [ { "scope": "user" } ] } }
' > "$H21/.claude/plugins/installed_plugins.json"
printf '# BEGIN disciplined-coder (managed — do not edit)\r\n@disciplined-coder/agent-principles.md\r\n@disciplined-coder/domains-index.md\r\n@disciplined-coder/solved_problems.md\r\n# END disciplined-coder (managed — do not edit)\r\n# BEGIN korean-banned-words (shared — do not edit)\r\n@disciplined-coder/korean-banned-words.md\r\n# END korean-banned-words (shared — do not edit)\r\n' > "$H21/.claude/CLAUDE.md"
OUT21="$(run "$H21" "$P21")"
echo "[crlf-import-line] CRLF import line still counts as present"
check "CRLF: no canon re-dump"        "! printf '%s' \"\$OUT21\" | grep -qF '# 디시플린코더(혹은 dc코더)'"
check "CRLF: sends nothing"           "[ -z \"\$OUT21\" ]"

# --- adjacent-openers: 인접 여는 마커 가드 — 첫 BEGIN이 뒤쪽 닫는 마커까지 훑어 사용자 줄을 삼키면 안 된다 ---
# 모양: 여는마커 / 사용자줄 / 여는마커 / 본문 / 닫는마커. _managed_block.sh 내부 while 루프의
# "다음 여는 마커를 만나면 멈춘다" 가드가 없으면, 첫 BEGIN(고아)이 END 탐색을 두 번째 BEGIN 너머까지
# 계속해 사이에 낀 사용자 줄까지 완결 영역으로 오판해 통째로 삭제한다.
HAO="$(mktemp -d)"; PAO="$(mktemp -d)"; mkdir -p "$HAO/.claude"
{ printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf 'USER LINE BETWEEN TWO OPENERS\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '@disciplined-coder/agent-principles.md\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$HAO/.claude/CLAUDE.md"
run "$HAO" "$PAO" >/dev/null
UCAO="$HAO/.claude/CLAUDE.md"
echo "[adjacent-openers] adjacent opening-marker guard: inner scan must not skip past a second opener"
check "user line between two openers preserved" "grep -qxF 'USER LINE BETWEEN TWO OPENERS' '$UCAO'"
check "single managed region after run"         "[ \$(grep -cF '# BEGIN disciplined-coder' '$UCAO') -eq 1 ]"

# --- canon-installed: 갓 설치한 PC의 사본에도 상시 허가 문장이 실린다 ---
# 에이전트원칙이 곧 주입 경로이므로, 갓 설치한 PC의 관리 디렉터리 사본에도 그 문장이 실려야 한다.
CONSENT='렌즈 호출은 사용자가 상시 허용한 것으로 본다'
echo "[canon-installed] the installed canon copy carries the standing consent"
check "설치본에도 상시 허가 문장"          "grep -qF -- '$CONSENT' '$K/agent-principles.md'"

# --- canon-refresh: 이미 옛 에이전트원칙을 갖고 있는 PC도 갱신을 받는다 ---
# 갓 설치한 경로만 검사하면, 에이전트원칙 복사를 '없을 때만'으로 바꿔도 초록이 유지된다.
# 그 순간 이미 깔린 모든 설치가 옛 에이전트원칙에 멈추는데, 새 문장이 필요한 쪽은 정확히 그 설치들이다.
HRU="$(mktemp -d)"; PRU="$(mktemp -d)"; mkdir -p "$HRU/.claude/disciplined-coder"
OLDCANON="$HRU/.claude/disciplined-coder/agent-principles.md"
printf '# 디시플린 (팀 원칙)\n\n옛 사본이라 새 문장이 없다.\n' > "$OLDCANON"
run "$HRU" "$PRU" >/dev/null
echo "[canon-refresh] an existing older canon copy is refreshed, not left behind"
check "옛 사본이 갱신된다"                 "grep -qF -- '$CONSENT' '$OLDCANON'"
check "옛 내용이 남지 않는다"              "! grep -qF '옛 사본이라 새 문장이 없다' '$OLDCANON'"

# --- 동시 진입: 창을 여럿 열면 SessionStart가 같은 ~/.claude/CLAUDE.md를 동시에 고친다 ---
# 락이 없으면 사용자 본문을 통째로 잃고 관리블록이 여러 벌 남는다.
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


HRS="$(mktemp -d)"; PRS="$(mktemp -d)"; mkdir -p "$HRS/.claude/disciplined-coder"
KS="$HRS/.claude/disciplined-coder"
printf 'old index
' > "$KS/advisors-index.md"; printf '내 백로그 한 줄
' > "$KS/unsolved_problems.md"
printf '옛 이름 목록 한 줄
' > "$KS/korean-banned-words-dc.md"
ERRS="$(CLAUDE_HOME_DIR="$HRS/.claude" CLAUDE_PROJECT_DIR="$PRS" CLAUDE_PLUGIN_ROOT="$HERE" bash "$SCAFFOLD" 2>&1 >/dev/null)" || true
echo "[stale] renamed and retired managed files are cleared out"
check "stale: advisors-index 치움"        "[ ! -f '$KS/advisors-index.md' ]"
check "stale: unsolved_problems 치움"     "[ ! -f '$KS/unsolved_problems.md' ]"
check "stale: 옛 이름 목록 치움"          "[ ! -f '$KS/korean-banned-words-dc.md' ]"
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


# --- project-old-block: 없앤 기능이 프로젝트 CLAUDE.md에 심어 둔 옛 관리블록을 걷어낸다. 전역 블록은 건드리지 않는다.
HR11="$(mktemp -d)"; PR11="$(mktemp -d)"
{ printf '# 내 프로젝트 지침\n\n'
  printf '이 줄은 사용자 것이라 남아야 한다.\n\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '## 오답노트 (solved_problems)\n'
  printf '옛 포인터 본문.\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$PR11/CLAUDE.md"
OUTR11="$(run "$HR11" "$PR11")"
echo "[project-old-block] the retired project pointer block is removed"
check "포인터: 블록 제거"                 "! grep -qF 'BEGIN disciplined-coder' '$PR11/CLAUDE.md'"
check "포인터: 본문도 제거"               "! grep -qF '옛 포인터 본문' '$PR11/CLAUDE.md'"
check "포인터: 사용자 줄 보존"            "grep -qF '이 줄은 사용자 것이라 남아야 한다' '$PR11/CLAUDE.md'"
check "포인터: 제거를 알린다"             "printf '%s' \"\$OUTR11\" | grep -qF '옛 관리블록'"
check "포인터: 전역 블록은 그대로"        "[ \$(grep -cF '# BEGIN disciplined-coder' '$HR11/.claude/CLAUDE.md') -eq 1 ]"
run "$HR11" "$PR11" >/dev/null
check "포인터: 재실행도 사용자 줄 보존"   "grep -qF '이 줄은 사용자 것이라 남아야 한다' '$PR11/CLAUDE.md'"

# --- project-old-block-backup: 블록을 걷어내기 전에 사본을 뜬다. 걷어내기는 마커 사이를 통째로 버리므로, 사람이 그 안에
# 끼워 넣은 줄도 함께 사라진다. 이 파일은 git 밖일 수 있어 사본이 유일한 복구 수단이다
# (규율은 _managed_block.sh 가 소유한다).
HR12="$(mktemp -d)"; PR12="$(mktemp -d)"
{ printf '# 내 프로젝트 지침\n\n'
  printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '## 오답노트 (solved_problems)\n'
  printf '블록 안에 사람이 끼워 넣은 줄.\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$PR12/CLAUDE.md"
OUTR12="$(run "$HR12" "$PR12")"
echo "[project-old-block-backup] removing the retired block leaves a copy behind"
check "포인터: 블록 안 줄이 사본에 남는다" "grep -rqF '블록 안에 사람이 끼워 넣은 줄' '$HR12/.claude/disciplined-coder/backups'"
check "포인터: 사본 경로를 알린다"        "printf '%s' \"\$OUTR12\" | grep -qF '사본:'"
check "포인터: 사본은 전역에 쌓인다"      "[ ! -d '$PR12/backups' ]"

# --- project-old-block-nobackup: 사본을 못 뜨면 블록을 걷어내지 않는다. 못 뜨는 채로 걷어내면 되돌릴 방법이 없기 때문이다.
# backups 자리를 파일이 막고 있으면 mkdir이 실패한다 — 권한이나 백신이 막는 PC를 흉내 낸 것이다.
HR13="$(mktemp -d)"; PR13="$(mktemp -d)"; mkdir -p "$HR13/.claude/disciplined-coder"
printf 'backups 자리를 파일이 막고 있다\n' > "$HR13/.claude/disciplined-coder/backups"
{ printf '# BEGIN disciplined-coder (managed — do not edit)\n'
  printf '옛 포인터 본문.\n'
  printf '# END disciplined-coder (managed — do not edit)\n'
} > "$PR13/CLAUDE.md"
OUTR13="$(run "$HR13" "$PR13")"
echo "[project-old-block-nobackup] a block that cannot be copied is left alone"
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
# --- deps-notice: 함께 쓰는 플러그인 확인 — 매 세션, 없을 때만, 건너뛸 이름은 skip 파일이 정한다 ---
HDN1="$(mktemp -d)"; PDN1="$(mktemp -d)"
OUTDN1a="$(run "$HDN1" "$PDN1")"
OUTDN1b="$(run "$HDN1" "$PDN1")"
HDN2="$(mktemp -d)"; PDN2="$(mktemp -d)"; mkdir -p "$HDN2/.claude/plugins"
printf '{ "version": 2, "plugins": { "superpowers@claude-plugins-official": [ { "scope": "user" } ] } }
' > "$HDN2/.claude/plugins/installed_plugins.json"
OUTDN2="$(run "$HDN2" "$PDN2")"
# 건너뛰기: 첫 회차로 관리 디렉터리를 만든 뒤 이름 하나를 적고 다시 돌린다.
HDN3="$(mktemp -d)"; PDN3="$(mktemp -d)"
run "$HDN3" "$PDN3" >/dev/null
printf 'superpowers
' > "$HDN3/.claude/disciplined-coder/plugin-notice.skip"
OUTDN3="$(run "$HDN3" "$PDN3")"
# skip 은 적힌 이름만 잠재운다. 다른 이름을 적어 두고도 알림이 그대로 나오는지 따로 본다 —
# 이 단언이 없으면 skip 파일이 있기만 하면 통째로 조용해지는 구현도 초록으로 지나간다.
HDN4="$(mktemp -d)"; PDN4="$(mktemp -d)"
run "$HDN4" "$PDN4" >/dev/null
printf 'not-a-dependency
' > "$HDN4/.claude/disciplined-coder/plugin-notice.skip"
OUTDN4="$(run "$HDN4" "$PDN4")"
echo "[deps-notice] 함께 쓰는 플러그인 알림"
check "없으면 superpowers 를 알린다"       "printf '%s' \"\$OUTDN1a\" | grep -qF 'superpowers@claude-plugins-official'"
# superpowers 는 공식 마켓플레이스라 추가 명령이 없다. 목록의 '-' 가 실제로 그 줄을 뺐는지 본다.
check "superpowers 는 마켓플레이스 추가가 없다" "[ \$(printf '%s' \"\$OUTDN1a\" | grep -cF 'claude plugin marketplace add') -eq 0 ]"
check "끄는 방법을 함께 알린다"            "printf '%s' \"\$OUTDN1a\" | grep -qF 'plugin-notice.skip'"
check "둘째 세션에도 그대로 알린다"        "printf '%s' \"\$OUTDN1b\" | grep -qF 'superpowers@claude-plugins-official'"
check "깔렸으면 조용하다"                  "! printf '%s' \"\$OUTDN2\" | grep -qF 'claude plugin install'"
check "깔렸어도 셋업은 돈다"               "[ -f '$HDN2/.claude/disciplined-coder/agent-principles.md' ]"
check "skip 에 적힌 것은 안 알린다"        "! printf '%s' \"\$OUTDN3\" | grep -qF 'superpowers@claude-plugins-official'"
check "skip 에 없는 것은 그대로 알린다"    "printf '%s' \"\$OUTDN4\" | grep -qF 'superpowers@claude-plugins-official'"

echo "[notice-encoding] user-facing notices are not double-encoded"
check "notice: 공통 헬퍼에 깨진 표시 없음" "! grep -qF -- 'ð' \"$COMMON\""

# --- utf8-set: 변수가 비었을 때만 넣는다. 0 은 일부러 끈 것이라 손대지 않는다 ---
# 레지스트리를 실제로 바꾸지 않도록 상태를 주입한다. 주입이 걸려 있으면 setter 가 실제 호출을
# 건너뛰므로, 여기서 보는 것은 어느 상태에서 넣기로 판단하는가다.
HU1="$(mktemp -d)"; PU1="$(mktemp -d)"
OUTU1="$(DISCIPLINED_CODER_UTF8_STATE=unset run "$HU1" "$PU1")"
HU2="$(mktemp -d)"; PU2="$(mktemp -d)"
OUTU2="$(DISCIPLINED_CODER_UTF8_STATE=on run "$HU2" "$PU2")"
HU3="$(mktemp -d)"; PU3="$(mktemp -d)"
OUTU3="$(DISCIPLINED_CODER_UTF8_STATE=off run "$HU3" "$PU3")"
HU4="$(mktemp -d)"; PU4="$(mktemp -d)"
OUTU4="$(DISCIPLINED_CODER_UTF8_STATE=not-windows run "$HU4" "$PU4")"
echo "[utf8-set] PYTHONUTF8 은 비었을 때만 넣는다"
check "비면 넣고 넣었다고 알린다"     "printf '%s' \"\$OUTU1\" | grep -qF 'PYTHONUTF8=1 을 넣었다'"
check "끄는 방법을 함께 알린다"       "printf '%s' \"\$OUTU1\" | grep -qF '0 으로 두면'"
check "값이 있으면 조용하다"          "! printf '%s' \"\$OUTU2\" | grep -qF 'PYTHONUTF8'"
check "0 이면 손대지 않는다"          "! printf '%s' \"\$OUTU3\" | grep -qF 'PYTHONUTF8'"
check "윈도우가 아니면 조용하다"      "! printf '%s' \"\$OUTU4\" | grep -qF 'PYTHONUTF8'"

# --- handoff-lint: 남은 핸드오프를 세션 시작에 알리고, 머리의 유예 날짜가 지나지 않았으면 조용하다 ---
# CLAUDE.md 의 문서 타입 표가 이 린트를 핸드오프 타입의 강제 장치로 적는다. 글자가 아니라 동작으로 본다.
HHO="$(mktemp -d)"; PHO="$(mktemp -d)"
printf '<!-- handoff-keep-until: 2999-12-31 -->\n# 인계\n' > "$PHO/HANDOFF-later.md"
printf '<!-- handoff-keep-until: 2000-01-01 -->\n# 인계\n' > "$PHO/HANDOFF-expired.md"
printf '# 인계\n' > "$PHO/HANDOFF-plain.md"
OUTHO="$(run "$HHO" "$PHO")"
echo "[handoff-lint] 핸드오프 잔존 린트"
check "유예 날짜가 남았으면 안 알린다"   "! printf '%s' \"\$OUTHO\" | grep -qF 'HANDOFF-later.md'"
check "유예 날짜가 지났으면 알린다"      "printf '%s' \"\$OUTHO\" | grep -qF 'HANDOFF-expired.md'"
check "유예 표시가 없으면 알린다"        "printf '%s' \"\$OUTHO\" | grep -qF 'HANDOFF-plain.md'"

echo "[파이썬 고르기 — 한 프로세스에서 한 번만 찾고 윈도우는 python 이 먼저다]"
# 윈도우의 python3 은 스토어 안내판일 수 있어 먼저 부르면 실패하는 데만 프로세스를 쓴다. 맥·리눅스는
# python 이 없거나 파이썬 2 일 수 있어 python3 이 먼저다. 둘 다 부르는 이름을 기록하는 가짜로 본다 —
# 찾기 한 번과 실행 두 번이면 같은 이름이 세 번 적힌다.
PSH="$TEST_TMP/py-shim"; mkdir -p "$PSH"; PLOG="$TEST_TMP/py.log"
for pn in python python3; do printf '#!/usr/bin/env bash\necho %s >> "%s"\nexit 0\n' "$pn" "$PLOG" > "$PSH/$pn"; done
chmod +x "$PSH"/*
py_probe() {  # $1=OSTYPE → 불린 이름을 차례로
  : > "$PLOG"
  ( PATH="$PSH:$PATH"; OSTYPE="$1"; unset _JSON_PY; . "$2"; json_run x; json_run y ) >/dev/null 2>&1 || true
  tr '\n' ' ' < "$PLOG"
}
check "윈도우는 python 을 먼저 고르고 한 번만 찾는다" "[ \"\$(py_probe msys '$HERE/scripts/_json_valid.sh')\" = 'python python python ' ]"
check "맥·리눅스는 python3 을 먼저 고르고 한 번만 찾는다" "[ \"\$(py_probe linux-gnu '$HERE/scripts/_json_valid.sh')\" = 'python3 python3 python3 ' ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
