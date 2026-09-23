#!/usr/bin/env bash
# PostToolUse(Write|Edit): spec/plan 작성 감지 → 미리뷰면 PREP+렌즈 리뷰 지시(비블로킹).
# 렌즈 구성은 호출자 스킬(review-specs)이 SSOT다 — 개수를 여기 박지 않는다.
# 마커: 마지막 비공백 줄의 terminal HTML 주석(passed|escalated)만 인정. 경로는 _hook_input.sh 의 hook_file_paths(다중 순회).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"    # 훅 입력 읽기(hook_file_paths·slash_norm) 공유
. "$DIR/_spec_marker.sh"   # terminal 마커 판정(SSOT) 공유
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
hook_file_paths
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  path_is_specplan "$FILE" || continue
  path_in_project "$FILE" || continue   # 프로젝트 밖 spec에는 걸지 않는다
  if [ -f "$FILE" ] && marker_is_terminal "$FILE"; then continue; fi
  match="$FILE"; break
done <<EOF
$FILE_PATHS
EOF
[ -n "$match" ] || exit 0
base="${match##*/}"
msg="📋 spec/plan(${base}) 작성됨 — 진행 전 반드시 ${SPEC_REVIEW_INSTRUCTION}"
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
