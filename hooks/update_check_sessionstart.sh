#!/usr/bin/env bash
# SessionStart(startup|resume|clear): 설치본이 원격보다 뒤처졌으면 새 버전으로 옮기고, 사용자에게 다시
# 켜라고 요구한다. 비교와 갱신 규칙은 scripts/_ensure_current.sh 가 소유한다.
# scaffold.sh 에서 떼어 낸 이유는 출력 형식이다. scaffold 의 평문 stdout 은 Claude 의 맥락에만 들어가
# 사용자 화면에 안 보인다. 여기서는 JSON 한 줄로 내어, systemMessage 로 사용자 화면에 띄우고
# additionalContext 로 Claude 가 첫 답에서 다시 켜라고 요구하게 한다. 최신이면 아무것도 출력하지 않는다.
set -uo pipefail
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
SDIR="$DIR/../scripts"
. "$SDIR/_resolve_home.sh"
. "$SDIR/_ensure_current.sh"
. "$DIR/_json_escape.sh"

MSG="$(ensure_install_current "$(resolve_home claude 2>/dev/null)")"
[ -n "$MSG" ] || exit 0
# 다시 켜야 하면 재시작을 요구하게 하고, 옮기지 못했으면 적힌 명령을 대신 실행할지 묻게 한다.
CTX="$MSG
이 알림을 사용자의 첫 요청에 답하기 전에 먼저 전하라."
case "$MSG" in *"다시 켜야"*) CTX="$CTX 클로드 코드를 다시 켜 달라고 요구하라." ;; esac
case "$MSG" in *"직접 실행하라"*) CTX="$CTX 적힌 명령을 대신 실행할지 물어라." ;; esac
printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
  "$(escape_for_json "$MSG")" "$(escape_for_json "$CTX")"
exit 0
