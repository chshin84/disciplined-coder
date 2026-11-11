#!/usr/bin/env bash
# UserPromptSubmit: 사용자 메시지마다 대화 답의 형태 지시 세 줄을 추가 컨텍스트로 붙인다(비블로킹).
# 원칙은 세션 첫머리에 한 번 실려 긴 대화에서 멀어지므로, 가장 자주 지적받은 세 가지만 메시지 바로 옆에 다시 둔다.
#
# 근거: 실제 세션 36건 재현 시험에서 위반이 현행 17건(3회 모두 17)에서 11건으로 줄었다. 사용자 판독 10쌍에서는
# 현행 10쌍 모두 위반, 감독자 문구 전의 세 줄 조건 0쌍 위반이었다. 지시를 셋보다 늘리면 리마인더끼리 경쟁해 효과가
# 줄었다는 선행 사례가 있어 세 줄로 둔다. 측정 기록은 docs/domain-korean.md 의 「대화 답 리마인더」 절에 있다.
#
# 입력은 읽지 않는다. 메시지 내용과 무관하게 같은 글을 내며, 끄려면 DISCIPLINED_CODER_REPLY_REMINDER=off 로 둔다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_REMINDER:-on}" = "off" ] && exit 0
cat >/dev/null || true

DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유

msg="- 사용자는 이 작업을 맡긴 감독자다. 감독자가 판단하고 승인하고 행동하는 데 쓰는 정보(결론, 바뀐 것, 정할 일, 남은 위험)를 먼저 쓰고, 그 결론에 이른 내부 과정은 사용자가 물을 때만 써라.
- 이 대화에서 네가 만든 약칭·번호·파일 이름·조항 이름은 쓰지 말고, 그것이 가리키는 내용을 풀어 써라.
- 사용자가 정할 일은 한 건만 물어라. 나머지는 몇 건이 더 있다고만 적어라."
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$(escape_for_json "$msg")"
