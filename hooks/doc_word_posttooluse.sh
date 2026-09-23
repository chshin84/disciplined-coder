#!/usr/bin/env bash
# PostToolUse(Bash): 셸로 고친 산출물 문서에 금지 표현이 들어가면 알린다.
#
# Pre 훅(doc_word_pretooluse.sh)이 Write·Edit 를 막는데, 셸로 고치면 그 훅이 안 돈다.
#
# 여기서는 막지 못하고 쓰인 뒤에 알린다. 쓰기 전에는 무엇이 쓰일지 모르기 때문이다 —
# `sed -i 's/A/B/' x.md` 의 결과 본문은 실행해 봐야 정해진다. 그래서 강도가 도구마다 다르다.
# Write·Edit 는 거부되고 셸은 통지된다. 이것을 같게 만들 방법은 없으므로 숨기지 않고 적어 둔다.
#
# 대상을 가르는 규칙과 맞추는 규칙은 Pre 훅과 같은 곳에서 온다. 제외 셋(이 저장소 자신의 문서,
# Claude 메모리, docs/superpowers/ 아래)도 같다. 규칙이 갈리면 같은 파일이 도구에 따라 다르게
# 판정되어 어느 쪽이 맞는지 알 수 없게 된다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && exit 0
INPUT="$(cat)"

# 무엇도 하기 전에 거른다. 이 훅은 모든 Bash 호출에 걸리므로 평상시 값이 곧 이 줄이다.
# 명령만 셸 확장으로 꺼내 쓰기 구문이 있는지 본다. 판정은 _hook_input.sh 의 bash_cmd_writes 가
# 소유하고 형제 훅과 대상 뽑기가 같은 것을 쓴다. 쓰기 구문이 없으면 프로세스를 하나도 안 띄운다.
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"         # 훅 입력 읽기와 쓰기 구문 판정 공유
hook_command
bash_cmd_writes "$CMD" || exit 0

. "$HOOKDIR/_spec_marker.sh"        # 경로 술어(path_is_banned_target) 공유
. "$HOOKDIR/_json_escape.sh"        # JSON 문자열 이스케이프 공유

BANSRC="$HOOKDIR/../korean-banned-words.md"
[ -f "$BANSRC" ] || exit 0   # 목록이 없다는 사실은 Pre 훅이 Write·Edit 로 .md 를 쓸 때만 알린다.
#                              셸로만 쓰는 세션에서는 아무도 알리지 않는다(알려진 한계).

TARGETS="$(printf '%s' "$INPUT" | bash "$HOOKDIR/_extract_bash_targets.sh" 2>/dev/null || true)"
[ -n "$TARGETS" ] || exit 0

# 검사할 파일을 먼저 추린다. 하나도 없으면 표 파싱까지 가지 않는다 — 셸 명령마다 치르는 값이다.
FILES=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  path_is_banned_target "$FILE" || continue   # 제외 규칙은 _spec_marker.sh 가 소유한다.
  [ -f "$FILE" ] || continue
  FILES="${FILES}${FILE}
"
done <<EOF
$TARGETS
EOF
[ -n "$FILES" ] || exit 0

. "$HOOKDIR/_banned_words.sh"            # 표 파싱과 본문 맞추기 공유
. "$HOOKDIR/../scripts/_json_valid.sh"   # 파이썬 인터프리터 고르기

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PAIRS="$WORK/pairs"; TOKS="$WORK/toks"; EXCL="$WORK/excl"
banned_parse "$BANSRC" "$PAIRS" "$TOKS" "$EXCL"
[ -s "$TOKS" ] || exit 0   # 검사 불능은 Pre 훅이 알린다.

REPORT=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 빠른 거르기. 금지어 바이트가 파일에 하나도 없으면 파이썬을 안 부른다.
  LC_ALL=C grep -qFf "$TOKS" "$FILE" || continue
  one="$(banned_report "$PAIRS" "$FILE" "$EXCL")"
  [ -n "$one" ] || continue
  REPORT="${REPORT}${FILE}
${one}
"
done <<EOF
$FILES
EOF
[ -n "$REPORT" ] || exit 0

MSG="disciplined-coder: 셸로 고친 산출물 문서에 「금지 표현」 목록의 말이 남아 있다. 아래를 대체어로 고쳐라. 셸 편집은 쓰기 전에 막을 수 없어 쓰인 뒤에 알린다. 코드 블록과 백틱 안은 검사하지 않았다.

$REPORT"
# Claude 가 받아야 고친다. systemMessage 는 사용자 화면에만 가므로 additionalContext 로 낸다.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$(escape_for_json "$MSG")"
exit 0
