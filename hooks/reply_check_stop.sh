#!/usr/bin/env bash
# Stop: 사용자에게 보낼 마지막 답에 정본의 금지 표현이 남았으면 알리고 고치게 한다.
# 넛지가 아니라 되돌림이다 — decision:block 으로 그 답을 고쳐 다시 내보내게 한다.
#
# 왜 문서 검사(test_docs_drift.sh)로 갈음할 수 없나. 그 검사는 저장소의 .md 파일만 훑고 대화에는
# 안 걸린다. 사용자가 읽는 것은 답이고, 지금까지 답에는 아무 장치가 없었다. 정본은 "문자열 검색으로
# 거른 뒤 내보낸다"고 정하는데 그 검색을 하는 곳이 없었다.
#
# 루프가드는 stop_hook_active 하나다. 한 번 되돌린 뒤의 Stop 에서는 그 값이 참이라 조용히 통과한다.
# 그래서 한 답에 한 번만 걸리고, 고친 답이 또 걸려도 다시 막지 않는다.
#
# 이 훅은 답마다 도므로 값을 재고 짰다. 이 PC 에서 프로세스 하나를 띄우는 값이 빈 프로세스 8밀리초,
# grep 과 awk 45밀리초, 파이썬 71밀리초다. 그래서 셸에서 파이프를 반복하지 않고 프로세스 수를
# 줄이는 쪽으로만 짠다(행마다 파이프를 돌리는 판이 3MB 기록에서 13초가 나왔다). 경로를 뽑는 것도
# sed 대신 셸 문자열 연산으로 한다. 임시 파일은 한 폴더에 몰아 mktemp 를 한 번만 부른다.
# 먼저 기록의 꼬리를 grep 한 번으로 훑어 금지어가 하나도 없으면 파이썬을 아예 안 부른다.
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && exit 0
HOOKDIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프(SSOT) 공유
. "$HOOKDIR/_banned_words.sh"   # 정본 표 파싱(SSOT) 공유
INPUT="$(cat)"
case "$INPUT" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac

# 정본이 목록의 소유자다. 훅 폴더의 부모가 플러그인 루트이고 거기 정본이 있다.
CANON="$HOOKDIR/../agent-principles.md"
if [ ! -f "$CANON" ]; then
  # 검사 불능은 통과가 아니다. 조용히 넘어가면 목록이 사라진 것을 알아챌 방법이 없다(FAIL-LOUD).
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: 정본을 찾지 못해 답변의 금지 표현을 검사하지 못했다 — $CANON")"
  exit 0
fi

# 대화 기록 경로를 셸 문자열 연산으로 뽑는다. 값 안에 큰따옴표가 없는 경로라 이것으로 충분하고,
# sed 두 번을 아낀다. 없으면 검사할 대상이 없으므로 조용히 통과한다(알려진 한계).
case "$INPUT" in *'"transcript_path"'*) ;; *) exit 0 ;; esac
_rest="${INPUT#*\"transcript_path\"}"
_rest="${_rest#*\"}"
TRANSCRIPT="${_rest%%\"*}"
TRANSCRIPT="${TRANSCRIPT//\\\\//}"
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PAIRS="$WORK/pairs"; TOKS="$WORK/toks"; TAIL="$WORK/tail"
banned_parse "$CANON" "$PAIRS" "$TOKS"
if [ ! -s "$TOKS" ]; then
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: 정본의 「금지 표현」 표에서 검색할 글자를 하나도 못 뽑아 답변을 검사하지 못했다 — $CANON")"
  exit 0
fi

# 기록의 꼬리만 본다. 마지막 답은 파일 끝에 있고, 통째로 읽으면 세션이 길어질수록 값이 늘어난다.
# 첫 줄은 잘렸을 수 있는데 아래 파이썬이 파싱 안 되는 줄을 건너뛰므로 따로 다루지 않는다.
# 마지막 답이 이 크기를 넘으면 앞부분을 못 본다. 알려진 한계이고 실제 답은 이보다 훨씬 작다.
tail -c 200000 "$TRANSCRIPT" > "$TAIL" 2>/dev/null || cp "$TRANSCRIPT" "$TAIL"

# 빠른 거르기. 꼬리 어디에도 금지어가 없으면 마지막 답에도 없으므로 파이썬을 안 부른다.
# 도구 결과에 그 글자가 있어 여기서 걸려도 아래 정밀 검사가 걸러내므로 거짓 지적은 안 나간다.
# 로케일을 C 로 둔다. -F 는 고정 문자열이라 바이트로 견주어도 UTF-8 결과가 같고, C.UTF-8 로
# 두었을 때 200KB 에 207밀리초가 들던 것이 크게 줄었다.
LC_ALL=C grep -qFf "$TOKS" "$TAIL" || exit 0

# JSON 처리기는 파이썬 하나다. 고르는 규칙은 scripts/_json_valid.sh 가 소유한다.
. "$HOOKDIR/../scripts/_json_valid.sh"

# 마지막 답의 산문만 보고 걸린 것을 "글자 -> 대체어" 로 낸다. 코드 블록과 백틱 안은 지운다 —
# 파일 내용과 식별자를 인용한 것까지 잡으면 거짓 지적이 되어 훅을 끄게 만든다.
REPORT="$(json_run '
import json, re, sys

pairs_path, src = sys.argv[1], sys.argv[2]

rows = []
for line in open(pairs_path, encoding="utf-8"):
    parts = line.rstrip("\n").split("\t")
    if len(parts) >= 2:
        rows.append((parts[1:], parts[0]))

last = ""
for line in open(src, encoding="utf-8"):
    try:
        o = json.loads(line)
    except Exception:
        continue
    if o.get("type") != "assistant" or o.get("isSidechain"):
        continue
    content = (o.get("message") or {}).get("content")
    if not isinstance(content, list):
        continue
    text = "".join(p.get("text", "") for p in content
                   if isinstance(p, dict) and p.get("type") == "text")
    if text.strip():
        last = text

body = re.sub(r"```.*?```", " ", last, flags=re.S)
body = re.sub(r"`[^`]*`", " ", body)

for words, repl in rows:
    found = [w for w in words if w and w in body]
    if found:
        print(" · ".join(found) + " -> " + repl)
' "$PAIRS" "$TAIL" 2>/dev/null | tr -d '\r' || true)"

[ -n "$REPORT" ] || exit 0

REASON="방금 쓴 답에 정본 「금지 표현」 표의 말이 남아 있다. 아래를 대체어로 고쳐 그 답을 다시 써라. 코드 블록과 백틱 안은 검사하지 않았으므로 걸린 것은 모두 산문에 있다.

$REPORT

고칠 때 UNPACK 도 함께 본다. 저장소 안에서만 통하는 이름을 부연 없이 썼는지, 선택지 앞에 배경을 산문으로 적었는지 확인한다."

printf '{"decision":"block","reason":"%s"}\n' "$(escape_for_json "$REASON")"
exit 0
