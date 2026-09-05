#!/usr/bin/env bash
# PostToolUse(Write|Edit): spec/plan 작성 감지 → 미리뷰면 PREP+렌즈 리뷰 지시(비블로킹).
# 렌즈 구성은 호출자 스킬(review-specs)이 SSOT다 — 개수를 여기 박지 않는다.
# 마커: 마지막 비공백 줄의 terminal HTML 주석(passed|escalated)만 인정. 경로는 _extract_path.sh(다중 순회).
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_spec_marker.sh"   # terminal 마커 판정(SSOT) 공유
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  path_is_specplan "$FILE" || continue
  path_in_project "$FILE" || continue   # 프로젝트 밖 spec에는 걸지 않는다
  if [ -f "$FILE" ] && marker_is_terminal "$FILE"; then continue; fi
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"
msg="📋 spec/plan(${base}) 작성됨 — 진행 전 반드시 ${SPEC_REVIEW_INSTRUCTION}"
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
