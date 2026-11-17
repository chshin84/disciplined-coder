#!/usr/bin/env bash
# PostToolUse(Write|Edit): spec/plan 작성 감지 → 마커가 없으면 리뷰 지시를 Claude 에게 준다(비블로킹).
# 지시문과 리뷰 스킬 이름은 _spec_marker.sh 의 SPEC_REVIEW_INSTRUCTION·REVIEW_SKILL 이 소유한다.
# 마커: 마지막 비공백 줄의 terminal HTML 주석(passed|escalated)만 인정. 경로는 _hook_input.sh 의 hook_file_paths(다중 순회).
set -euo pipefail
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"    # 훅 입력 읽기(hook_file_paths·slash_norm) 공유
. "$DIR/_spec_marker.sh"   # terminal 마커 판정 공유
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유
INPUT="$(cat)"
hook_file_paths
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  path_is_specplan "$FILE" || continue
  path_in_project "$FILE" || continue   # 프로젝트 밖 spec 은 대상이 아니다
  if [ -f "$FILE" ] && marker_is_terminal "$FILE"; then continue; fi
  match="$FILE"; break
done <<EOF
$FILE_PATHS
EOF
[ -n "$match" ] || exit 0
base="${match##*/}"
msg="📋 spec/plan(${base}) 작성됨 — ${SPEC_REVIEW_INSTRUCTION}"
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
