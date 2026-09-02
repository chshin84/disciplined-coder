#!/usr/bin/env bash
# PreToolUse(Write|Edit): 대상 파일이 있고 쓰기 불가이면 거부하고 사유를 낸다.
# 경로·저장소·HEAD는 보지 않는다 — 읽기 전용이라는 속성은 그 파일을 만든 쪽의 의도라 어느 프로젝트에서든
# 같은 뜻이다. 끄는 스위치를 두지 않는다(DISCIPLINED_CODER_REVIEW_GATE 도 미치지 않는다). 풀려면 속성을
# 풀면 되고 그 길은 셸이다. Write 는 훅 없이도 EPERM 으로 막히므로 이 훅의 몫은 왜 막혔는지 말하는 것이다.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  [ -e "$FILE" ] || continue            # 없는 파일은 새로 만드는 것이라 막을 속성이 없다
  [ -w "$FILE" ] && continue            # 쓸 수 있으면 훅의 일이 아니다
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0
reason="읽기 전용 파일은 고치지 않는다. 속성을 세운 쪽에 뜻이 있다 — 감사 기록이면 고치지 말고 새 기록을 더한다. 파일: $match"
esc="$(escape_for_json "$reason")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$esc"
exit 0
