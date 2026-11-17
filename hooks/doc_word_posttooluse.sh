#!/usr/bin/env bash
# PostToolUse(Write|Edit|Bash): 다른 프로젝트의 산출물 문서에 금지 표현이 있으면 Claude 에게 알린다. 거부하지 않는다.
#
# 대상 파일은 Write·Edit 이면 입력의 file_path 이고, Bash 이면 명령의 쓰기 구문이 가리키는 파일이다.
# 쓰인 뒤의 파일 전체를 본다. 대상을 가르는 규칙(제외 셋: 이 저장소 자신의 문서, Claude 메모리,
# docs/superpowers/ 아래)은 _spec_marker.sh 의 path_is_banned_target 이, 맞추는 규칙은 _banned_words.sh 의
# banned_report 가 소유한다. 코드 블록과 백틱 안은 보지 않는다.
# 파이썬이 없으면 본문을 추리는 단계가 실패해 알림 없이 통과한다(2026-09-30 사용자 결정).
set -euo pipefail
IFS= read -r -d '' INPUT || true
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"         # 훅 입력 읽기와 쓰기 구문 판정 공유

json_str tool_name TOOL
if [ "$TOOL" = "Bash" ]; then
  # 이 훅은 모든 Bash 호출에 실행되므로 평상시 비용이 곧 이 거르기다. 쓰기 구문이 없으면 프로세스를 안 띄운다.
  hook_command
  bash_cmd_writes "$CMD" || exit 0
  . "$HOOKDIR/_extract_bash_targets.sh"
  TARGETS="$(bash_write_targets "$CMD" 2>/dev/null || true)"
else
  hook_file_paths
  TARGETS="$FILE_PATHS"
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

# 보고 줄은 "말 · 말 -> 대체어" 다. 검출된 말을 백틱으로 감싸 알림 자체가 금지어를 산문으로 싣지 않게 한다.
REPORT=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 빠른 거르기. 금지어 바이트가 파일에 하나도 없으면 파이썬을 안 부른다.
  LC_ALL=C grep -qFf "$TOKS" "$FILE" || continue
  one="$(banned_report "$PAIRS" "$FILE" "$EXCL")"
  [ -n "$one" ] || continue
  REPORT="${REPORT}${FILE}
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

MSG="disciplined-coder: 산출물 문서에 「금지 표현」 목록의 말이 있다. 아래 파일의 산문에서 왼쪽 말을 오른쪽 대체어로 고쳐라. 코드 블록과 백틱 안은 검사하지 않았다.

$REPORT"
# Claude 가 받아야 고친다. systemMessage 는 사용자 화면에만 가므로 additionalContext 로 낸다.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$(escape_for_json "$MSG")"
exit 0
