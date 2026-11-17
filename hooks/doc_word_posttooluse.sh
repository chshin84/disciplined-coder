#!/usr/bin/env bash
# PostToolUse(Write|Edit|Bash|PowerShell): 다른 프로젝트의 산출물 문서(.md·.html)에 금지 표현이 있으면 Claude 에게 알린다.
# 거부하지 않는다.
#
# 대상 파일은 Write·Edit 이면 입력의 file_path 이고, Bash·PowerShell 이면 명령의 쓰기 구문이 가리키는 파일이다
# (_extract_bash_targets.sh·_extract_ps_targets.sh). 상대 경로는 훅 입력의 cwd 기준으로 푼다.
# Write 와 셸은 쓰인 뒤의 파일 전체를, Edit 은 새로 넣은 글자만 본다(아래 edit_region). 대상을 구분하는 규칙(제외: 이 저장소
# 자신의 문서, Claude 메모리, docs/superpowers/ 아래)은 _spec_marker.sh 의 path_is_banned_target 이, 맞추는 규칙은
# _banned_words.sh 의 banned_report 가 소유한다. 코드 블록과 백틱 안, HTML 의 태그·script·style 은 보지 않는다.
#
# 한계: 파이썬 같은 프로그램이 쓴 파일은 검사하지 못한다. 명령줄에 쓰기 대상이 나타나지 않기 때문이다.
# 파이썬이 없으면 본문을 추리는 단계가 실패해 알림 없이 통과한다(2026-09-30 사용자 결정). 금지어 목록 파일이
# 없으면 검사하지 못했다고 한 줄 알린다.
set -euo pipefail
# 큰 Write 입력도 한 번에 읽는다. read -d '' 는 한 바이트씩 읽어 큰 content 에서 느리다.
INPUT="$(cat)"
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"         # 훅 입력 읽기·쓰기 구문 판정·경로 풀기 공유

json_str tool_name TOOL
hook_cwd
MODE=write
case "$TOOL" in
  Bash)
    # 이 훅은 모든 셸 호출에 실행되므로 평상시 비용이 곧 이 거르기다. 쓰기 구문이 없으면 프로세스를 안 띄운다.
    MODE=shell
    hook_command
    bash_cmd_writes "$CMD" || exit 0
    . "$HOOKDIR/_extract_bash_targets.sh"
    TARGETS="$(bash_write_targets "$CMD" "$HOOK_CWD" 2>/dev/null || true)" ;;
  PowerShell)
    MODE=shell
    hook_command
    . "$HOOKDIR/_extract_ps_targets.sh"
    ps_cmd_writes "$CMD" || exit 0
    TARGETS="$(ps_write_targets "$CMD" "$HOOK_CWD" 2>/dev/null || true)" ;;
  *)
    case "$INPUT" in *'"old_string"'*) MODE=edit ;; esac
    hook_file_paths
    TARGETS="${FILE_PATHS%%$'\n'*}"   # Write·Edit 의 대상은 한 파일이다
    path_resolve TARGETS "$HOOK_CWD" ;;
esac
[ -n "$TARGETS" ] || exit 0

. "$HOOKDIR/_spec_marker.sh"        # 경로 술어(path_is_banned_target) 공유

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
say() { printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$(escape_for_json "$1")"; }
BANSRC="$HOOKDIR/../korean-banned-words.md"
if [ ! -f "$BANSRC" ]; then
  say "disciplined-coder: 금지어 목록이 없어 검사하지 못했다(\`$BANSRC\`)."
  exit 0
fi

. "$HOOKDIR/_banned_words.sh"            # 표 파싱과 본문 맞추기 공유
. "$HOOKDIR/../scripts/_json_valid.sh"   # 파이썬 인터프리터 고르기

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PAIRS="$WORK/pairs"; TOKS="$WORK/toks"; EXCL="$WORK/excl"
banned_parse "$BANSRC" "$PAIRS" "$TOKS" "$EXCL"
[ -s "$TOKS" ] || exit 0

# Edit 은 파일 전체를 보지 않고 new_string 이 놓인 글자만 본다. 파일의 다른 문장에 원래 있던 말까지 알리면
# 같은 파일을 고칠 때마다 같은 알림이 반복되고, Claude 가 사용자가 쓴 문장까지 고치게 된다.
# 훅 입력의 tool_response.originalFile 에 치환을 다시 적용해 쓴 뒤의 파일과 같으면, 바뀐 곳의 글자 위치를
# 구간 파일($3)에 적는다. 코드 블록·백틱·제외어 판정은 banned_report 가 파일 전체에 한 뒤 구간을 자른다.
# 원래 파일이 없거나 다시 적용한 결과가 다르면 구간을 정할 근거가 없으므로 new_string 자체를 $4 에 적는다.
# 두 파일 모두 줄 끝을 바꾸지 않고(newline="") 읽어 CRLF 파일에서도 글자 위치가 맞는다.
edit_region() {  # $1=훅 입력 파일, $2=대상 파일, $3=구간 파일, $4=new_string 파일
  json_run '
import json, sys
try:
    o = json.load(open(sys.argv[1], encoding="utf-8"))
    cur = open(sys.argv[2], encoding="utf-8", errors="replace", newline="").read()
except Exception:
    sys.exit(0)
ti = o.get("tool_input") or {}
new, old = ti.get("new_string"), ti.get("old_string")
if not isinstance(new, str) or not new:
    sys.exit(0)
allrep = bool(ti.get("replace_all"))
tr = o.get("tool_response")
orig = tr.get("originalFile") if isinstance(tr, dict) else None
spans = []
if isinstance(orig, str) and isinstance(old, str) and old and old in orig:
    pieces = orig.split(old) if allrep else orig.split(old, 1)
    doc = pieces[0]
    for piece in pieces[1:]:
        spans.append((len(doc), len(doc) + len(new)))
        doc += new + piece
    if doc != cur:
        spans = []
if spans:
    open(sys.argv[3], "w", encoding="utf-8").write("\n".join("%d %d" % s for s in spans))
else:
    open(sys.argv[4], "w", encoding="utf-8", newline="").write(new)
' "$1" "$2" "$3" "$4" 2>/dev/null || true
}

if [ "$MODE" = edit ]; then printf '%s' "$INPUT" > "$WORK/input.json"; fi

# 보고 줄은 "말 · 말 -> 대체어" 다. 파일 경로와 검출된 말을 백틱으로 감싸 알림 자체가 금지어를 산문으로
# 싣지 않게 한다.
REPORT=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 빠른 거르기. 금지어 바이트가 파일에 하나도 없으면 파이썬을 안 부른다.
  LC_ALL=C grep -qFf "$TOKS" "$FILE" || continue
  if [ "$MODE" = edit ]; then
    PYPATH="$FILE"   # 파이썬은 POSIX 형식(/d/...) 경로를 못 열므로 옮긴다
    if command -v cygpath >/dev/null 2>&1; then PYPATH="$(cygpath -m "$FILE" 2>/dev/null || printf '%s' "$FILE")"; fi
    NEWTXT="$WORK/new.${FILE##*.}"
    rm -f "$WORK/spans" "$NEWTXT"
    edit_region "$WORK/input.json" "$PYPATH" "$WORK/spans" "$NEWTXT"
    if [ -s "$WORK/spans" ]; then one="$(banned_report "$PAIRS" "$PYPATH" "$EXCL" "$WORK/spans")"
    elif [ -s "$NEWTXT" ]; then one="$(banned_report "$PAIRS" "$NEWTXT" "$EXCL")"
    else continue
    fi
  else
    one="$(banned_report "$PAIRS" "$FILE" "$EXCL")"
  fi
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

# 알림 문구는 spec(2026-11-13-v2-rebuild-design 「검사 장치」)을 따른다. 사용자 화면 알림은 내지 않는다.
case "$MODE" in
  edit)  SCOPE="Edit 로 새로 넣은 글자만 검사했다." ;;
  write) SCOPE="Write 로 쓴 파일 전체를 검사했다." ;;
  *)     SCOPE="셸 명령은 쓴 문장을 구분할 수 없어 파일 전체를 검사했다. 이번 호출에서 쓴 문장만 보고, 원래 있던 문장은 고치지 마라." ;;
esac
# Claude 가 받아야 고친다. systemMessage 는 사용자 화면에만 가므로 additionalContext 로 낸다.
say "disciplined-coder: 산출물 문서에 「금지 표현」 목록의 말이 있다. $SCOPE 문장 전체가 자연스러우면 그대로 두고, 아니면 오른쪽 대체어로 고쳐라. 코드 블록과 백틱 안은 검사하지 않았다.

$REPORT"
exit 0
