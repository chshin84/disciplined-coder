#!/usr/bin/env bash
# PostToolUse(Bash): 셸로 고친 산출물 문서에 금지 표현이 들어가면 알린다.
#
# Pre 훅(doc_word_pretooluse.sh)이 Write·Edit 를 막는데, 셸로 고치면 그 훅이 안 돈다.
# 2026-09-21 에 한 세션이 `sed -i` 로 문서 열한 개를 고치는 동안 그 검사가 한 번도 안 걸렸다.
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
HOOKDIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKDIR/_json_escape.sh"        # JSON 문자열 이스케이프(SSOT) 공유
. "$HOOKDIR/_banned_words.sh"       # 표 파싱과 본문 맞추기(SSOT) 공유
. "$HOOKDIR/../scripts/_json_valid.sh"   # 파이썬 인터프리터 고르기(SSOT)
INPUT="$(cat)"

BANSRC="$HOOKDIR/../korean-banned-words.md"
[ -f "$BANSRC" ] || exit 0   # 목록이 없다는 사실은 Pre 훅이 이미 알린다. 여기서 두 번 알리지 않는다.

TARGETS="$(printf '%s' "$INPUT" | bash "$HOOKDIR/_extract_bash_targets.sh" 2>/dev/null || true)"
[ -n "$TARGETS" ] || exit 0

# 검사할 파일을 먼저 추린다. 하나도 없으면 표 파싱까지 가지 않는다 — 셸 명령마다 치르는 값이다.
FILES=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) ;; *) continue ;; esac
  case "$FILE" in */.claude/projects/*) continue ;; esac
  case "$FILE" in */docs/superpowers/*|docs/superpowers/*) continue ;; esac
  [ -f "$FILE" ] || continue
  # 조상 폴더에 정본이 있으면 이 플러그인 저장소 자신의 문서다. Pre 훅과 같은 판정이다.
  _d="${FILE%/*}"; [ "$_d" = "$FILE" ] && _d="."
  _prev=""; _own=0
  while [ -n "$_d" ] && [ "$_d" != "$_prev" ]; do
    if [ -f "$_d/agent-principles.md" ]; then _own=1; break; fi
    _prev="$_d"; _d="${_d%/*}"
  done
  [ "$_own" -eq 1 ] && continue
  FILES="${FILES}${FILE}
"
done <<EOF
$TARGETS
EOF
[ -n "$FILES" ] || exit 0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PAIRS="$WORK/pairs"; TOKS="$WORK/toks"
banned_parse "$BANSRC" "$PAIRS" "$TOKS"
[ -s "$TOKS" ] || exit 0   # 검사 불능은 Pre 훅이 알린다.

REPORT=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 빠른 거르기. 금지어 바이트가 파일에 하나도 없으면 파이썬을 안 부른다.
  LC_ALL=C grep -qFf "$TOKS" "$FILE" || continue
  one="$(banned_report "$PAIRS" "$FILE")"
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
printf '{"systemMessage":"%s"}\n' "$(escape_for_json "$MSG")"
exit 0
