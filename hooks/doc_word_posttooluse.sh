#!/usr/bin/env bash
# PostToolUse(Write|Edit|Bash): 다른 프로젝트의 산출물 문서에 금지 표현이 있으면 Claude 에게 알린다. 거부하지 않는다.
#
# 대상 파일은 Write·Edit 이면 입력의 file_path 이고, Bash 이면 명령의 쓰기 구문이 가리키는 파일이다.
# Write 와 Bash 는 쓰인 뒤의 파일 전체를, Edit 은 새로 넣은 글자만 본다(아래 edit_region). 대상을 가르는 규칙(제외 셋: 이 저장소 자신의 문서, Claude 메모리,
# docs/superpowers/ 아래)은 _spec_marker.sh 의 path_is_banned_target 이, 맞추는 규칙은 _banned_words.sh 의
# banned_report 가 소유한다. 코드 블록과 백틱 안은 보지 않는다.
# 파이썬이 없으면 본문을 추리는 단계가 실패해 알림 없이 통과한다(2026-09-30 사용자 결정).
set -euo pipefail
IFS= read -r -d '' INPUT || true
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"         # 훅 입력 읽기와 쓰기 구문 판정 공유

json_str tool_name TOOL
MODE=write
if [ "$TOOL" = "Bash" ]; then
  MODE=bash
  # 이 훅은 모든 Bash 호출에 실행되므로 평상시 비용이 곧 이 거르기다. 쓰기 구문이 없으면 프로세스를 안 띄운다.
  hook_command
  bash_cmd_writes "$CMD" || exit 0
  . "$HOOKDIR/_extract_bash_targets.sh"
  TARGETS="$(bash_write_targets "$CMD" 2>/dev/null || true)"
else
  case "$INPUT" in *'"old_string"'*) MODE=edit ;; esac
  hook_file_paths
  TARGETS="${FILE_PATHS%%$'\n'*}"   # Write·Edit 의 대상은 한 파일이다
fi
[ -n "$TARGETS" ] || exit 0

. "$HOOKDIR/_spec_marker.sh"        # 경로 술어(path_is_banned_target) 공유
BANSRC="$HOOKDIR/../korean-banned-words.md"
[ -f "$BANSRC" ] || exit 0   # 목록이 없으면 검사하지 못한다(알려진 한계).

# 검사할 파일을 먼저 추린다. 하나도 없으면 표 파싱까지 가지 않는다.
FILES=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  path_is_banned_target "$FILE" || continue
  [ -f "$FILE" ] || continue
  FILES="${FILES}${FILE}
"
done <<EOF
$TARGETS
EOF
[ -n "$FILES" ] || exit 0

. "$HOOKDIR/_json_escape.sh"             # JSON 문자열 이스케이프 공유
. "$HOOKDIR/_banned_words.sh"            # 표 파싱과 본문 맞추기 공유
. "$HOOKDIR/../scripts/_json_valid.sh"   # 파이썬 인터프리터 고르기

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PAIRS="$WORK/pairs"; TOKS="$WORK/toks"; EXCL="$WORK/excl"
banned_parse "$BANSRC" "$PAIRS" "$TOKS" "$EXCL"
[ -s "$TOKS" ] || exit 0

# Edit 은 파일 전체를 보지 않고 new_string 이 놓인 글자만 본다. 파일의 다른 문장에 원래 있던 말까지 알리면
# 같은 파일을 고칠 때마다 같은 알림이 반복되고, Claude 가 사용자가 쓴 문장까지 고치게 된다.
# 구간은 쓴 뒤의 파일에서 정한다. 훅 입력의 tool_response.originalFile 이 있으면 거기에 치환을 다시 적용해
# 정확한 구간을 얻고, 없으면 쓴 뒤의 파일에서 new_string 이 나오는 곳(replace_all 이면 전부, 아니면 처음
# 한 곳)을 구간으로 본다. 코드 블록과 백틱 판정은 파일 기준이고, 규칙은 banned_report 와 같다.
edit_region() {  # $1=훅 입력 파일, $2=대상 파일 → 새로 넣은 글자 중 산문으로 남은 것
  json_run '
import json, re, sys
try:
    o = json.load(open(sys.argv[1], encoding="utf-8"))
    cur = open(sys.argv[2], encoding="utf-8").read()
except Exception:
    sys.exit(0)
ti = o.get("tool_input") or {}
new, old = ti.get("new_string"), ti.get("old_string")
if not isinstance(new, str) or not new:
    sys.exit(0)
allrep = bool(ti.get("replace_all"))
orig = (o.get("tool_response") or {}).get("originalFile") if isinstance(o.get("tool_response"), dict) else None
spans = []
if isinstance(orig, str) and isinstance(old, str) and old and old in orig:
    pieces = orig.split(old) if allrep else orig.split(old, 1)
    doc = pieces[0]
    for piece in pieces[1:]:
        spans.append((len(doc), len(doc) + len(new)))
        doc += new + piece
    if doc != cur:
        spans = []
if not spans:
    i = cur.find(new)
    while i >= 0:
        spans.append((i, i + len(new)))
        if not allrep:
            break
        i = cur.find(new, i + len(new))
blank = lambda m: re.sub(r"[^\n]", " ", m.group(0))
doc = re.sub(r"```.*?```", blank, cur, flags=re.S)
doc = re.sub(r"`[^`]*`", blank, doc)
sys.stdout.write("\n".join(doc[a:b] for a, b in spans))
' "$1" "$2" 2>/dev/null || true
}

if [ "$MODE" = edit ]; then printf '%s' "$INPUT" > "$WORK/input.json"; fi

# 보고 줄은 "말 · 말 -> 대체어" 다. 파일 경로와 검출된 말을 백틱으로 감싸 알림 자체가 금지어를 산문으로
# 싣지 않게 한다.
REPORT=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 빠른 거르기. 금지어 바이트가 파일에 하나도 없으면 파이썬을 안 부른다.
  LC_ALL=C grep -qFf "$TOKS" "$FILE" || continue
  SCAN="$FILE"
  if [ "$MODE" = edit ]; then
    PYPATH="$FILE"   # 파이썬은 POSIX 형식(/d/...) 경로를 못 열므로 옮긴다
    if command -v cygpath >/dev/null 2>&1; then PYPATH="$(cygpath -m "$FILE" 2>/dev/null || printf '%s' "$FILE")"; fi
    SCAN="$WORK/region"; edit_region "$WORK/input.json" "$PYPATH" > "$SCAN"
    [ -s "$SCAN" ] || continue
  fi
  one="$(banned_report "$PAIRS" "$SCAN" "$EXCL")"
  [ -n "$one" ] || continue
  REPORT="${REPORT}\`${FILE}\`
"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    words="${line%% -> *}"; repl="${line#* -> }"
    REPORT="${REPORT}\`${words// · /\` · \`}\` -> ${repl}
"
  done <<EOF2
$one
EOF2
done <<EOF
$FILES
EOF
[ -n "$REPORT" ] || exit 0

case "$MODE" in
  edit)  SCOPE="Edit 로 새로 넣은 글자만 검사했다. 아래 말을 오른쪽 대체어로 고쳐라." ;;
  write) SCOPE="Write 로 쓴 파일 전체를 검사했다. 아래 말을 오른쪽 대체어로 고쳐라." ;;
  *)     SCOPE="셸 명령은 쓴 문장을 구분할 수 없어 파일 전체를 검사했다. 이번 호출에서 쓴 문장의 말만 오른쪽 대체어로 고치고, 원래 있던 문장의 말은 고치지 말고 사용자에게 알리기만 하라." ;;
esac
MSG="disciplined-coder: 산출물 문서에 「금지 표현」 목록의 말이 있다. $SCOPE 코드 블록과 백틱 안은 검사하지 않았다.

$REPORT"
# Claude 가 받아야 고친다. systemMessage 는 사용자 화면에만 가므로 additionalContext 로 낸다.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$(escape_for_json "$MSG")"
exit 0
