#!/usr/bin/env bash
# PostToolUse(Write|Edit): spec/plan 작성 감지 → 미리뷰면 PREP+렌즈 리뷰 지시(비블로킹).
# 렌즈 구성은 호출자 스킬(domain-spec-review)이 SSOT다 — 개수를 여기 박지 않는다.
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
  if [ -f "$FILE" ] && marker_is_terminal "$FILE"; then continue; fi
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
base="$(basename "$match")"
msg="📋 spec/plan(${base}) 작성됨 — 진행 전 반드시 disciplined-coder domain-spec-review 스킬로 PREP+독립 렌즈 리뷰를 수행하라(어느 렌즈를 돌릴지는 그 스킬이 정한다). 리뷰와 처분 분류가 끝나면 개선보다 앞서 문서 마지막 줄에 spec-review 마커를 먼저 남기고(passed 또는 escalated, HTML 주석) 그다음 개선을 반영하라."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
