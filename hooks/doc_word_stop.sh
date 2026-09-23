#!/usr/bin/env bash
# Stop: 커밋되지 않은 산출물 문서에 금지 표현이 남았으면 사용자에게 알린다(비블로킹).
# 이 턴에 바뀐 것만 가려 보지 않는다. 커밋 전 문서는 턴마다 다시 알린다.
#
# 앞의 두 훅은 도구를 본다. Pre 는 Write·Edit 의 내용을 보고 막고, Post 는 셸 명령에서 뽑은
# 대상을 본다. 그래서 명령줄에 대상이 안 나타나면 둘 다 못 본다 — 파이썬 스크립트가 내부에서
# 여는 파일, `git checkout`·`revert`·`apply` 같은 복원, 변수로 받은 경로다.
#
# 여기는 도구를 묻지 않고 결과만 본다. git 이 "이 파일이 바뀌었다"고 말하면 무엇이 바꿨는지와
# 무관하게 검사한다. 그래서 앞 두 겹이 놓친 것을 덮는다. 대신 git 이 추적하지 않는 곳은 못 본다 —
# 그쪽은 Post 겹이 맡는다. 두 겹이 서로의 사각을 덮는 구조이고 어느 하나로는 다 못 막는다.
#
# 막지 않는다. 턴이 끝나는 것을 막으면 고치지 못하는 상황에서 빠져나갈 길이 없고, 이 검사는
# 이미 쓰인 뒤라 막아도 되돌릴 것이 없다. 알리는 것으로 끝낸다. 막지 않으면 Claude 에게
# 닿는 통로가 없으므로 알림은 사용자에게 하는 말로 쓴다.
#
# 대상을 가르는 규칙과 맞추는 규칙은 Pre·Post 훅과 같은 곳에서 온다. 제외 셋(이 저장소 자신의
# 문서, Claude 메모리, docs/superpowers/ 아래)도 같다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && exit 0
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"         # 훅 입력 읽기(json_str·slash_norm) 공유
. "$HOOKDIR/_spec_marker.sh"        # 경로 술어(path_is_banned_target) 공유
. "$HOOKDIR/_json_escape.sh"        # JSON 문자열 이스케이프 공유
. "$HOOKDIR/_stop_preamble.sh"      # 루프가드·cwd·저장소 루트 이동 공유
INPUT="$(cat)"

BANSRC="$HOOKDIR/../korean-banned-words.md"
[ -f "$BANSRC" ] || exit 0   # 목록이 없다는 사실은 Pre 훅이 Write·Edit 로 .md 를 쓸 때만 알린다.
#                              셸로만 쓰는 세션에서는 아무도 알리지 않는다(알려진 한계).

stop_enter_repo "바뀐 문서의 금지 표현을 검사하지 못했다"

# 검사할 파일을 먼저 추린다. 하나도 없으면 표 파싱까지 가지 않는다 — 매 턴 치르는 값이다.
# -z 로 NUL 종료 raw 경로를 받는다. 공백과 비아스키가 든 경로가 그래야 안 깨진다.
FILES=""
while IFS= read -r -d '' entry; do
  f="${entry:3}"
  [ -n "$f" ] || continue
  path_is_banned_target "$f" || continue   # 제외 규칙은 _spec_marker.sh 가 소유한다.
  [ -f "$f" ] || continue
  FILES="${FILES}${f}
"
done < <(git status -z --no-renames --untracked-files=all 2>/dev/null || true)
[ -n "$FILES" ] || exit 0

. "$HOOKDIR/_banned_words.sh"            # 표 파싱과 본문 맞추기 공유
. "$HOOKDIR/../scripts/_json_valid.sh"   # 파이썬 인터프리터 고르기
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PAIRS="$WORK/pairs"; TOKS="$WORK/toks"; EXCL="$WORK/excl"
banned_parse "$BANSRC" "$PAIRS" "$TOKS" "$EXCL"
[ -s "$TOKS" ] || exit 0   # 검사 불능은 Pre 훅이 알린다.

REPORT=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  LC_ALL=C grep -qFf "$TOKS" "$f" || continue   # 빠른 거르기 — 파이썬을 아낀다
  one="$(banned_report "$PAIRS" "$f" "$EXCL")"
  [ -n "$one" ] || continue
  REPORT="${REPORT}${f}
${one}
"
done <<EOF
$FILES
EOF
[ -n "$REPORT" ] || exit 0

MSG="disciplined-coder: 커밋되지 않은 산출물 문서에 「금지 표현」 목록의 말이 남아 있다. 아래는 파일마다 검출한 말과 그 대체어다. 어느 도구가 고쳤는지와 무관하게 git 이 바뀌었다고 알린 파일을 본 결과이고, 코드 블록과 백틱 안은 검사하지 않았다. 이 알림은 사용자에게만 보이므로 고치려면 Claude 에게 요청한다.

$REPORT"
printf '{"systemMessage":"%s"}\n' "$(escape_for_json "$MSG")"
exit 0
