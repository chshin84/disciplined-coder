#!/usr/bin/env bash
# PreToolUse(Write|Edit): 사용자가 요구한 산출물 문서에 금지 표현이 들어가면 거부한다.
# 목록은 korean-banned-words.md 가 담고 정본에는 포인터만 있다. 같은 규칙이 답에도 걸리지만
# 답 쪽에는 검사하는 기계가 없어, 그 목록이 정본과 함께 실려 지시로만 걸린다.
#
# 무엇을 산출물로 보는가. `.md` 가운데 아래 셋에 안 드는 것 전부다. 사람이 요구해서 만드는 보고서,
# 제안서, 인수인계, 다른 프로젝트의 README 가 여기 든다.
#   (1) 이 플러그인 저장소 자신의 문서 — 조상 폴더에 정본이 있으면 뺀다. 그 문서의 금지어를 그냥
#       두기로 사용자가 정했고, 표와 근거를 적는 문서는 그 말을 이름으로 불러야 한다.
#   (2) Claude 메모리 — 경로에 `/.claude/projects/` 가 있으면 뺀다. 나에게 남기는 쪽지이지
#       사람이 요구한 산출물이 아니고, 금지어를 목록으로 적어 둘 곳이다.
#   (3) `docs/superpowers/` 아래 — spec·plan·리뷰 기록이다. 문서 검사(test_docs_drift.sh)와
#       audit-repo-docs 의 「대상 아님」이 이미 같은 규정으로 빼는 곳이라 그것을 따른다.
#
# 코드 블록과 백틱 안은 검사하지 않는다. 파일 내용과 식별자를 인용한 것까지 잡으면 거짓 거부가
# 되어 훅을 끄게 만든다. 금지어를 문서에 적어야 할 때는 백틱으로 감싸면 지나간다.
#
# 스위치는 답변 되돌림과 같은 DISCIPLINED_CODER_REPLY_CHECK 다. 같은 규칙이라 따로 두지 않는다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && exit 0
HOOKDIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKDIR/_spec_marker.sh"    # 경로 술어(path_in_own_repo) 공유(SSOT)
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프(SSOT) 공유
. "$HOOKDIR/_banned_words.sh"   # 금지 표현 표 파싱(SSOT) 공유
INPUT="$(cat)"

FILE="$(printf '%s' "$INPUT" | bash "$HOOKDIR/_extract_path.sh" | head -n1)"
[ -n "$FILE" ] || exit 0
case "$FILE" in *.md) ;; *) exit 0 ;; esac
case "$FILE" in */.claude/projects/*) exit 0 ;; esac
case "$FILE" in */docs/superpowers/*) exit 0 ;; esac

# 이 저장소 자신의 문서이면 뺀다. 판정은 _spec_marker.sh 의 path_in_own_repo 가 소유한다 —
# Post 훅과 Stop 훅이 같은 판정을 해야 같은 파일이 도구에 따라 다르게 걸리지 않는다.
path_in_own_repo "$FILE" && exit 0

# 표는 정본이 아니라 생성물에 있다. 원본은 KiwoomAX/korean-banned-words 의 JSON 하나이고
# scripts/gen_banned_words.py 가 그것을 이 파일로 낸다. 정본에는 포인터만 남는다.
BANSRC="$HOOKDIR/../korean-banned-words.md"
if [ ! -f "$BANSRC" ]; then
  # 검사 불능은 통과가 아니다. 막지는 않고 알린다 — 여기서 막으면 편집이 통째로 멈춘다(FAIL-LOUD).
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: 금지 표현 목록을 찾지 못해 산출물을 검사하지 못했다 — $BANSRC")"
  exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PAIRS="$WORK/pairs"; TOKS="$WORK/toks"; EXCL="$WORK/excl"; RAW="$WORK/raw"
banned_parse "$BANSRC" "$PAIRS" "$TOKS" "$EXCL"
if [ ! -s "$TOKS" ]; then
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: 「금지 표현」 표에서 검색할 글자를 하나도 못 뽑아 산출물을 검사하지 못했다 — $BANSRC")"
  exit 0
fi
printf '%s' "$INPUT" > "$RAW"

# 빠른 거르기. 훅 입력에 금지어 바이트가 하나도 없으면 파이썬을 안 부른다. 다만 입력이 한국어를
# \u 로 이스케이프해 보내면 이 검색이 못 잡으므로, 그때는 거르지 않고 파이썬으로 넘어간다.
case "$INPUT" in
  *'\u'*) ;;
  *) LC_ALL=C grep -qFf "$TOKS" "$RAW" || exit 0 ;;
esac

# JSON 처리기는 파이썬 하나다. 고르는 규칙은 scripts/_json_valid.sh 가 소유한다.
. "$HOOKDIR/../scripts/_json_valid.sh"

# 쓰려는 본문만 꺼내 텍스트 파일로 둔다. 맞추는 것은 _banned_words.sh 의 banned_report 가
# 맡는다 — Post 훅도 같은 함수를 쓰므로 도구에 따라 판정이 갈리지 않는다(SSOT).
BODY="$WORK/body"
json_run '
import json, sys
try:
    o = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
ti = o.get("tool_input") or {}
# Write 는 content 로, Edit 은 new_string 으로 새 본문을 준다. 둘 다 없으면 검사할 것이 없다.
text = ti.get("content")
if not isinstance(text, str):
    text = ti.get("new_string")
if not isinstance(text, str):
    sys.exit(0)
sys.stdout.write(text)
' "$RAW" > "$BODY" 2>/dev/null || true
[ -s "$BODY" ] || exit 0
REPORT="$(banned_report "$PAIRS" "$BODY" "$EXCL")"

[ -n "$REPORT" ] || exit 0

REASON="이 문서에 「금지 표현」 목록의 말이 들어 있다. 아래를 대체어로 고쳐 다시 써라. 코드 블록과 백틱 안은 검사하지 않았으므로 걸린 것은 모두 산문에 있고, 그 말 자체를 문서에 적어야 하면 백틱으로 감싸라.

$REPORT

이 검사는 사용자가 요구한 산출물 문서에 걸린다. 이 플러그인 저장소의 문서와 Claude 메모리와 docs/superpowers/ 아래는 대상이 아니다."

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(escape_for_json "$REASON")"
exit 0
