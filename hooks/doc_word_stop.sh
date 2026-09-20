#!/usr/bin/env bash
# Stop: 이 턴에 바뀐 산출물 문서에 금지 표현이 남았으면 알린다(비블로킹).
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
# 이미 쓰인 뒤라 막아도 되돌릴 것이 없다. 알리는 것으로 끝낸다(FAIL-LOUD).
#
# 대상을 가르는 규칙과 맞추는 규칙은 Pre·Post 훅과 같은 곳에서 온다. 제외 셋(이 저장소 자신의
# 문서, Claude 메모리, docs/superpowers/ 아래)도 같다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && exit 0
HOOKDIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKDIR/_spec_marker.sh"        # 경로 술어(path_in_own_repo) 공유(SSOT)
. "$HOOKDIR/_json_escape.sh"        # JSON 문자열 이스케이프(SSOT) 공유
. "$HOOKDIR/_banned_words.sh"       # 표 파싱과 본문 맞추기(SSOT) 공유
. "$HOOKDIR/../scripts/_json_valid.sh"   # 파이썬 인터프리터 고르기(SSOT)
INPUT="$(cat)"
case "$INPUT" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac  # 루프가드
command -v git >/dev/null 2>&1 || exit 0

BANSRC="$HOOKDIR/../korean-banned-words.md"
[ -f "$BANSRC" ] || exit 0   # 목록이 없다는 사실은 Pre 훅이 알린다. 여기서 두 번 알리지 않는다.

cwd="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
cwd="$(printf '%s' "$cwd" | tr -s '\\' '/')"
if [ -n "$cwd" ]; then cd "$cwd" 2>/dev/null || exit 0; fi
# 저장소가 아니면 볼 것이 없다(FAIL-OPEN). 그 밖의 실패는 검사하지 못한 것이므로 알린다(FAIL-LOUD).
_gitout="$(git rev-parse --is-inside-work-tree 2>&1)" || {
  case "$_gitout" in *'not a git repository'*) exit 0 ;; esac
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: git 을 읽지 못해 바뀐 문서의 금지 표현을 검사하지 못했다 — $(printf '%s' "$_gitout" | head -n1)")"
  exit 0
}
# 레포 루트에서 본다. git status 가 돌려주는 경로가 루트 기준이라, 하위 폴더에서 돌면 파일을
# 하나도 못 찾고 조용히 통과한다. spec 게이트가 같은 곳에서 같은 실패를 겪었다.
_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$_root" ] || exit 0
cd "$_root" 2>/dev/null || exit 0

# 검사할 파일을 먼저 추린다. 하나도 없으면 표 파싱까지 가지 않는다 — 매 턴 치르는 값이다.
# -z 로 NUL 종료 raw 경로를 받는다. 공백과 비아스키가 든 경로가 그래야 안 깨진다.
FILES=""
while IFS= read -r -d '' entry; do
  f="${entry:3}"
  [ -n "$f" ] || continue
  case "$f" in *.md) ;; *) continue ;; esac
  case "$f" in */.claude/projects/*) continue ;; esac
  case "$f" in docs/superpowers/*|*/docs/superpowers/*) continue ;; esac
  [ -f "$f" ] || continue
  path_in_own_repo "$f" && continue   # 이 저장소 자신의 문서. 판정은 _spec_marker.sh 가 소유한다.
  FILES="${FILES}${f}
"
done < <(git status -z --no-renames 2>/dev/null || true)
[ -n "$FILES" ] || exit 0

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

MSG="disciplined-coder: 이 턴에 바뀐 산출물 문서에 「금지 표현」 목록의 말이 남아 있다. 아래를 대체어로 고쳐라. 어느 도구가 고쳤는지와 무관하게 git 으로 바뀐 파일을 본 것이라, 앞의 두 훅이 못 본 것도 여기 든다. 코드 블록과 백틱 안은 검사하지 않았다.

$REPORT"
printf '{"systemMessage":"%s"}\n' "$(escape_for_json "$MSG")"
exit 0
