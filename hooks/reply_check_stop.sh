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
set -euo pipefail
[ "${DISCIPLINED_CODER_REPLY_CHECK:-on}" = "off" ] && exit 0
HOOKDIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKDIR/_json_escape.sh"    # JSON 문자열 이스케이프(SSOT) 공유
INPUT="$(cat)"
case "$INPUT" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;; esac

# 정본이 목록의 소유자다. 훅 폴더의 부모가 플러그인 루트이고 거기 정본이 있다.
CANON="$HOOKDIR/../agent-principles.md"
if [ ! -f "$CANON" ]; then
  # 검사 불능은 통과가 아니다. 조용히 넘어가면 목록이 사라진 것을 알아챌 방법이 없다(FAIL-LOUD).
  printf '{"systemMessage":"%s"}\n' "$(escape_for_json "disciplined-coder: 정본을 찾지 못해 답변의 금지 표현을 검사하지 못했다 — $CANON")"
  exit 0
fi

# 대화 기록 경로. 없으면 검사할 대상이 없으므로 조용히 통과한다(알려진 한계).
TRANSCRIPT="$(printf '%s' "$INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
TRANSCRIPT="$(printf '%s' "$TRANSCRIPT" | sed 's/\\\\/\//g')"
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

# JSON 처리기는 파이썬 하나다. 고르는 규칙은 scripts/_json_valid.sh 가 소유한다.
. "$HOOKDIR/../scripts/_json_valid.sh"

# 정본의 표에서 금지어와 대체어를 뽑고, 기록에서 마지막 답을 뽑아, 걸린 것만 한 줄씩 낸다.
# 답에서 코드 블록과 백틱 안은 지우고 검사한다 — 파일 내용과 식별자를 인용한 것까지 잡으면
# 거짓 지적이 되어 훅을 끄게 만든다.
REPORT="$(json_run '
import json, re, sys

canon_path, transcript_path = sys.argv[1], sys.argv[2]

rows = []
in_table = False
for line in open(canon_path, encoding="utf-8"):
    if line.startswith("### 금지 표현"):
        in_table = True
        continue
    if in_table and line.startswith("#"):
        break
    if in_table and line.startswith("| `"):
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        words = [w.strip("` ") for w in re.findall(r"`[^`]+`", cells[0])]
        rows.append((words, cells[1]))

last = ""
for line in open(transcript_path, encoding="utf-8"):
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

hits = []
for words, repl in rows:
    found = [w for w in words if w and w in body]
    if found:
        hits.append(" · ".join(found) + " -> " + repl)
for h in hits:
    print(h)
' "$CANON" "$TRANSCRIPT" 2>/dev/null | tr -d '\r' || true)"

[ -n "$REPORT" ] || exit 0

REASON="방금 쓴 답에 정본 「금지 표현」 표의 말이 남아 있다. 아래를 대체어로 고쳐 그 답을 다시 써라. 코드 블록과 백틱 안은 검사하지 않았으므로 걸린 것은 모두 산문에 있다.

$REPORT

고칠 때 UNPACK 도 함께 본다. 저장소 안에서만 통하는 이름을 부연 없이 썼는지, 선택지 앞에 배경을 산문으로 적었는지 확인한다."

printf '{"decision":"block","reason":"%s"}\n' "$(escape_for_json "$REASON")"
exit 0
