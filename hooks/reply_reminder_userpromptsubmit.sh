#!/usr/bin/env bash
# UserPromptSubmit: 사용자 메시지마다 대화 답의 형태 지시 세 줄을 추가 컨텍스트로 붙인다(비블로킹).
# 원칙은 세션 첫머리에 한 번 실려 긴 대화에서 멀어지므로, 가장 자주 지적받은 세 가지만 메시지 바로 옆에 다시 둔다.
#
# 근거(spec 2026-11-13-v2-rebuild-design 「매 턴 리마인더」): 첫 줄은 실제 메시지 29개 시험에서 조항과 함께 실어
# 20개가 나아지고 3개가 나빠진 줄(p=0.0002)이다. 둘째 줄은 사용자 판독 10쌍에서 위반 0 이던 세 줄 조건의 줄이다.
# 셋째 줄은 110턴 재판정에서 고쳐짐 3·나빠짐 0 이던 결정 질문 줄을 원칙 `ROLES` 의 묻는 조건과 같은 낱말로 고쳤다.
# 세 줄을 함께 실은 측정은 아직 없고, 3단계 검증의 v2 조건에서 측정한다. 지시를 셋보다 늘리면 리마인더끼리
# 경쟁해 효과가 줄었다는 선행 사례가 있어 세 줄로 둔다.
#
# 입력은 읽지 않는다. 메시지 내용과 무관하게 같은 글을 내며, 끄려면 DISCIPLINED_CODER_REPLY_REMINDER=off 로 둔다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_REMINDER:-on}" = "off" ] && exit 0
cat >/dev/null || true

DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유

msg="- 사용자 메시지가 지시면 실행하고 결과만, 질문이면 물은 것만 답하라.
- 이 대화에서 네가 만든 약칭·번호·파일 이름·조항 이름은 쓰지 말고, 가리키는 내용을 풀어 써라.
- 결정은 권장안대로 네가 정해 진행하고 결과에 적어라. 입력·출력의 정의, 되돌릴 수 없거나 밖으로 나가는 행동, 지시의 목적을 바꾸는 결정만 먼저 물어라."
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$(escape_for_json "$msg")"
