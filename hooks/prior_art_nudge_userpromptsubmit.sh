#!/usr/bin/env bash
# UserPromptSubmit: 사용자 메시지에 선행연구 주제어와 요청형 표현이 함께 있으면 researching-prior-art 스킬을
# 열라고 추가 컨텍스트로 알린다(비블로킹, 게이트 아님). 메시지마다 보며 세션당 횟수 제한은 두지 않는다.
#
# 이 파일이 주제어 목록과 요청형 목록의 원본이다. 스킬은 낱말 목록을 옮겨 적지 않고 이 파일을 가리킨다.
# 목록을 고칠 때는 이 파일만 고친다.
#
# 가정: 훅 입력의 prompt 값에 한글이 그대로 들어온다. 한글이 \uXXXX 로 이스케이프되어 오면 낱말이 맞지 않아
# 침묵한다. 입력을 해석하지 못할 때도 아무것도 내지 않고 0 으로 끝난다(FAIL-OPEN).
# 외부 명령을 실행하지 않는다. 키를 뽑는 데 json_str 을 쓰지 않는 이유는 첫 따옴표에서 끊기 때문이다.
set -euo pipefail
[ "${DISCIPLINED_CODER_PRIOR_ART_NUDGE:-on}" = "off" ] && exit 0
INPUT="$(cat)"

case "$INPUT" in *'"prompt"'*) ;; *) exit 0 ;; esac
p="${INPUT#*\"prompt\"}"

TOPICS=("선행연구" "prior art" "선행 사례" "누가 해봤" "근거를 찾" "선행연구렌즈" "lens-prior-art")
REQUESTS=("찾아" "뒤져" "조사해" "대조해" "해봐" "있나" "없나")

shopt -s nocasematch
hit_topic=0; hit_request=0
for t in "${TOPICS[@]}"; do [[ $p == *"$t"* ]] && { hit_topic=1; break; }; done
[ "$hit_topic" -eq 1 ] || exit 0
for t in "${REQUESTS[@]}"; do [[ $p == *"$t"* ]] && { hit_request=1; break; }; done
[ "$hit_request" -eq 1 ] || exit 0

DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유

msg="사용자 메시지가 선행연구를 찾아 달라는 요청으로 보인다. 그렇다면 disciplined-coder 플러그인의 researching-prior-art 스킬을 열어 그 절차대로 진행하라. 손으로 짠 워크플로나 일반 리서치로 대신하지 마라. 선행연구를 요청한 것이 아니면 이 알림을 무시하라. 넛지일 뿐 차단은 아니다."
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$(escape_for_json "$msg")"
