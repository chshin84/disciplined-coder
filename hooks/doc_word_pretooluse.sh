#!/usr/bin/env bash
# PreToolUse(Write|Edit): 사용자가 요구한 산출물 문서에 금지 표현이 들어가면 거부한다.
# 목록은 korean-banned-words.md 가 담고 에이전트원칙에는 포인터만 있다. 같은 규칙이 답에도 걸리지만
# 답 쪽에는 검사하는 기계가 없어, 그 목록이 에이전트원칙과 함께 실려 지시로만 걸린다.
#
# 무엇을 산출물로 보는가. `.md` 가운데 아래 셋에 안 드는 것 전부다. 사람이 요구해서 만드는 보고서,
# 제안서, 인수인계, 다른 프로젝트의 README 가 여기 든다.
#   (1) 이 플러그인 저장소 자신의 문서 — 조상 폴더에 agent-principles.md 가 있으면 뺀다. 판정과 그 근거인
#       사용자 결정은 _spec_marker.sh 의 path_in_own_repo 가 소유한다.
#   (2) Claude 메모리 — 경로에 `/.claude/projects/` 가 있으면 뺀다. 나에게 남기는 쪽지이지
#       사람이 요구한 산출물이 아니고, 금지어를 목록으로 적어 둘 곳이다.
#   (3) `docs/superpowers/` 아래 — spec·plan·리뷰 기록이다. 문서 검사(test_docs_drift.sh)와
#       audit-repo-docs 의 「대상 아님」이 이미 같은 규정으로 빼는 곳이라 그것을 따른다.
#
# 코드 블록과 백틱 안은 검사하지 않는다. 파일 내용과 식별자를 인용한 것까지 잡으면 거짓 거부가
# 되어 훅을 끄게 만든다. 금지어를 문서에 적어야 할 때는 백틱으로 감싸면 지나간다.
#
# 스위치는 DISCIPLINED_CODER_REPLY_CHECK 다. 답을 검사하던 훅이 걷힌 뒤에도 사용자 설정과 이어져
# 있어 이름을 그대로 둔다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && exit 0
HOOKDIR="${BASH_SOURCE[0]%/*}"; [ "$HOOKDIR" != "${BASH_SOURCE[0]}" ] || HOOKDIR=.
. "$HOOKDIR/_hook_input.sh"     # 훅 입력 읽기(hook_file_paths) 공유
. "$HOOKDIR/_spec_marker.sh"    # 경로 술어(path_is_banned_target) 공유
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프 공유
. "$HOOKDIR/_banned_words.sh"   # 금지 표현 표 파싱 공유
INPUT="$(cat)"

hook_file_paths
FILE="${FILE_PATHS%%$'\n'*}"
[ -n "$FILE" ] || exit 0
# 위 셋을 빼는 판정은 _spec_marker.sh 의 path_is_banned_target 이 소유한다 — Post 훅과 Stop 훅이
# 같은 판정을 해야 같은 파일이 도구에 따라 다르게 걸리지 않는다.
path_is_banned_target "$FILE" || exit 0

# 표는 에이전트원칙이 아니라 생성물에 있다. 원본은 KiwoomAX/korean-banned-words 의 JSON 하나이고
# scripts/gen_banned_words.py 가 그것을 이 파일로 낸다. 에이전트원칙에는 포인터만 남는다.
BANSRC="$HOOKDIR/../korean-banned-words.md"
if [ ! -f "$BANSRC" ]; then
  # 검사 불능은 통과가 아니다. 막지는 않고 알린다 — 여기서 막으면 편집이 통째로 멈춘다.
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
# 맡는다 — Post 훅도 같은 함수를 쓰므로 도구에 따라 판정이 갈리지 않는다.
#
# Edit 의 new_string 은 조각이라 코드 블록 울타리가 조각 밖에 있다. 그래서 지금 파일에 치환을
# 적용한 결과 문서에서 코드 블록과 백틱을 걷고, 새로 들어간 글자 가운데 산문으로 남은 것만 넘긴다.
# 결과 문서 전체를 판정하지 않는 것은 다른 문장에 원래 있던 말 때문에 무관한 편집이 거부되지
# 않게 하려는 것이다. 파일을 못 읽거나 old_string 이 없으면 전처럼 new_string 만 본다.
BODY="$WORK/body"; FALLBACK="$WORK/fallback"
EDITPATH=""
case "$INPUT" in
  *'"old_string"'*)
    EDITPATH="$FILE"
    if command -v cygpath >/dev/null 2>&1; then EDITPATH="$(cygpath -m "$FILE" 2>/dev/null || printf '%s' "$FILE")"; fi ;;
esac
json_run '
import json, re, sys
try:
    o = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
ti = o.get("tool_input") or {}
# Write 는 content 로 새 본문 전체를 준다.
text = ti.get("content")
if isinstance(text, str):
    sys.stdout.write(text)
    sys.exit(0)
new = ti.get("new_string")
if not isinstance(new, str):
    sys.exit(0)
old = ti.get("old_string")
cur = None
if sys.argv[2] and isinstance(old, str) and old:
    try:
        cur = open(sys.argv[2], encoding="utf-8").read()
    except Exception:
        cur = None
if cur is None or old not in cur:
    open(sys.argv[3], "w").close()
    sys.stdout.write(new)
    sys.exit(0)
# 치환을 적용하며 새 글자가 놓이는 구간을 적어 둔다.
pieces = cur.split(old) if ti.get("replace_all") else cur.split(old, 1)
doc, spans = pieces[0], []
for p in pieces[1:]:
    spans.append((len(doc), len(doc) + len(new)))
    doc += new + p
# 코드 블록과 백틱 안을 같은 길이의 공백으로 덮어 위치를 보존한다. 규칙은 banned_report 와 같다.
blank = lambda m: re.sub(r"[^\n]", " ", m.group(0))
doc = re.sub(r"```.*?```", blank, doc, flags=re.S)
doc = re.sub(r"`[^`]*`", blank, doc)
sys.stdout.write("\n".join(doc[a:b] for a, b in spans))
' "$RAW" "$EDITPATH" "$FALLBACK" > "$BODY" 2>/dev/null || true
[ -s "$BODY" ] || exit 0
REPORT="$(banned_report "$PAIRS" "$BODY" "$EXCL")"

[ -n "$REPORT" ] || exit 0

if [ -f "$FALLBACK" ]; then
  WHERE="Edit 을 지금 파일에 적용해 보지 못해 new_string 조각만 검사했다. 조각이 파일의 코드 블록 안에 들어간다면 코드 블록 경계를 보지 못해 산문으로 판정했다."
else
  WHERE="코드 블록과 백틱 안은 검사하지 않았으므로 검출된 말은 모두 산문에 있다."
fi
REASON="이 문서에 「금지 표현」 목록의 말이 들어 있다. 아래를 대체어로 고쳐 다시 써라. $WHERE 그 말 자체를 문서에 적어야 하면 백틱으로 감싸라.

$REPORT

이 검사는 사용자가 요구한 산출물 문서에 적용된다. 이 플러그인 저장소의 문서와 Claude 메모리와 docs/superpowers/ 아래는 대상이 아니다."

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$(escape_for_json "$REASON")"
exit 0
