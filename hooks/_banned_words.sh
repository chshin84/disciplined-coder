#!/usr/bin/env bash
# 공유 헬퍼: 「금지 표현」 표를 한 번 읽어 두 파일로 낸다. 그 표는 에이전트원칙이 아니라
# korean-banned-words.md 에 있고, 그 파일은 외부 저장소의 JSON 에서 만들어 낸 생성물이다.
# 소비자는 hooks/doc_word_pretooluse.sh 다. 답을 검사하던 훅이 값 때문에 걷혀 지금은 하나이고,
# 표를 읽는 자리를 늘리지 않으려고 파싱은 계속 여기 한 벌만 둔다(SSOT).
#
# awk 한 번으로 끝낸다. 이 PC 는 윈도우라 프로세스 하나 띄우는 값이 크다. 행마다 파이프를
# 돌리는 셸 반복으로 짰다가 3MB 기록에서 한 번에 13,057밀리초가 나왔고, 같은 일을 파이썬
# 한 번으로 하면 1,108밀리초였다. 그래서 셸에서는 프로세스 수를 줄이는 쪽으로만 짠다.
#
# 표를 읽는 것은 여기 awk 하나뿐이다. 파이썬은 에이전트원칙을 다시 파싱하지 않고 여기서 낸 pairs
# 파일을 읽는다. 파서가 둘이면 표의 모양이 바뀔 때 한쪽만 따라간다.

BANNED_TABLE_HEAD='### 금지 표현'

# 표를 파일 셋으로 낸다. pairs 는 한 행에 "대체어<탭>글자<탭>글자…", tokens 는 글자만 한 줄에 하나,
# excl 은 한 행에 그 행의 제외어를 탭으로 이은 것이다(행 순서가 pairs 와 같다).
#
# 제외 칸은 schema 2 에서 생겼다. 어간을 넓히고 다른 뜻으로 쓰이는 말을 제외로 빼는 방식이라,
# 그 칸을 안 읽으면 어간만 가지고 검색해 `판정`·`시간이 걸`·`이걸`·`담당` 까지 전부 잡힌다.
# 원본 저장소가 잰 값으로 거짓 검출이 1,329건 늘고, 그 상태에서는 산출물을 거의 못 쓴다.
# 칸이 없는 옛 표에서는 excl 행이 빈 줄이 되고 동작이 전과 같다.
# 표의 행만 본다 — 절의 설명 문단에도 백틱이 있어 절 전체를 뽑으면 그 문단의 경로가 금지어가 된다.
# 첫 칸에서만 글자를 뽑아 대체어 칸에 백틱이 생겨도 금지어로 새지 않게 한다.
# 로케일을 C 로 둔다. 가르는 글자가 세로줄과 백틱뿐인데 둘 다 아스키이고, UTF-8 이어보기 바이트는
# 0x80 이상이라 한국어 안에 그 두 글자가 나타날 수 없다. 그래서 바이트로 갈라도 결과가 같다.
# C.UTF-8 로 두었을 때 이 awk 한 번이 213밀리초였고 C 로 바꾸니 크게 줄었다.
banned_parse() {  # $1=표, $2=pairs, $3=tokens, $4=excl(생략 가능), $5=scopes(생략 가능)
  local excl="${4:-/dev/null}" scopes="${5:-/dev/null}"
  LC_ALL=C awk -v h="$BANNED_TABLE_HEAD" -v pairs="$2" -v toks="$3" -v excl="$excl" -v scopes="$scopes" '
    index($0, h) == 1 { f = 1; next }
    f && /^#/ { exit }
    f && /^\| `/ {
      n = split($0, c, "|")
      if (n < 4) next
      first = c[2]; repl = c[3]
      gsub(/^[ \t]+|[ \t]+$/, "", repl)
      out = repl
      # 백틱으로 가르면 짝수 자리가 백틱 안이다. 글자 위치를 세지 않아 다국어에서 어긋나지 않는다.
      m = split(first, parts, "`")
      for (i = 2; i <= m; i += 2) {
        t = parts[i]
        if (t == "") continue
        out = out "\t" t
        print t > toks
      }
      print out > pairs
      # 제외 칸은 여섯째다. 옛 표에는 그 칸이 없어 빈 줄이 나가고, 그러면 제외가 없는 것과 같다.
      # pairs 와 같은 횟수로 한 줄씩 내보내 두 파일의 행이 맞는다.
      ex = ""
      if (n >= 6) {
        k = split(c[6], eparts, "`")
        for (i = 2; i <= k; i += 2) {
          e = eparts[i]
          if (e == "") continue
          ex = (ex == "") ? e : ex "\t" e
        }
      }
      print ex > excl
      # 적용 대상은 넷째 칸이다. 어느 행이 문서에만 걸리고 어느 행이 답변까지 걸리는지를
      # 호출자가 가릴 수 있어야 한다. 이 칸이 없으면 빈 줄이 나가고 호출자가 전부로 본다.
      sc = (n >= 4) ? c[4] : ""
      gsub(/^[ \t]+|[ \t]+$/, "", sc)
      print sc > scopes
    }
    END { close(pairs); close(toks); close(excl); close(scopes) }
  ' "$1"
}

# 문서 여럿을 한 번에 훑어 "금지어<탭>걸린 파일들" 줄을 낸다. 제외 칸을 적용한 뒤에 찾는다.
# 검사 스크립트가 쓰던 자기 파서를 없애려고 둔다 — 파서가 둘이면 표의 모양이 바뀔 때 한쪽만
# 따라가고, schema 2 가 실제로 그 일을 일으켰다.
# 파이썬을 한 번만 부른다. 낱말마다 문서마다 grep 을 돌리면 40×25 번이 된다.
banned_scan() {  # $1=pairs, $2=excl, $3=scopes, $4=고를 적용 대상(빈 값이면 전부), $5=파일 목록 파일
  json_run '
import re, sys

pairs_path, excl_path, scopes_path, want, files_path = sys.argv[1:6]

rows = []
for line in open(pairs_path, encoding="utf-8"):
    parts = line.rstrip("\n").split("\t")
    rows.append(parts[1:] if len(parts) >= 2 else [])

def read_lines(p):
    try:
        return [l.rstrip("\n") for l in open(p, encoding="utf-8")]
    except Exception:
        return []

excls = [[e for e in l.split("\t") if e] for l in read_lines(excl_path)]
scopes = read_lines(scopes_path)

docs = []
for f in read_lines(files_path):
    if not f:
        continue
    try:
        raw = open(f, encoding="utf-8", errors="replace").read()
    except Exception:
        continue
    # 코드 블록과 백틱 안은 걷는다. banned_report 와 같은 규칙이어야 같은 문장이 통로에 따라
    # 다르게 판정되지 않는다. 목록 파일이 인용은 검사 대상이 아니라고 규정한다.
    body = re.sub(r"```.*?```", " ", raw, flags=re.S)
    body = re.sub(r"`[^`]*`", " ", body)
    docs.append((f, body))

def masked(b, exclusions):
    for e in sorted(exclusions, key=len, reverse=True):
        b = b.replace(e, " " * len(e))
    return b

for i, words in enumerate(rows):
    if want and (i >= len(scopes) or want not in scopes[i]):
        continue
    ex = excls[i] if i < len(excls) else []
    for w in words:
        if not w:
            continue
        hits = [f for f, body in docs if w in masked(body, ex)]
        print(w + "\t" + " ".join(hits))
' "$1" "$2" "$3" "$4" "$5" 2>/dev/null | tr -d '\r' || true
}

# 본문에서 금지 표현을 찾아 "걸린 말 · 걸린 말 -> 대체어" 줄들을 낸다. 못 찾으면 아무것도 안 낸다.
# 맞추는 곳을 여기 하나로 둔다. Pre 는 쓰려는 내용을, Post 는 이미 쓰인 파일을 넘기는데, 맞추는
# 규칙이 둘이면 같은 문장이 도구에 따라 다르게 판정된다.
#
# 코드 블록과 백틱 안은 걷어 낸다. 파일 내용과 식별자를 인용한 것까지 잡으면 거짓 판정이 되어
# 훅을 끄게 만든다. 금지어를 문서에 적어야 할 때는 백틱으로 감싸면 지나간다.
banned_report() {  # $1=pairs 경로, $2=검사할 텍스트 파일, $3=excl 경로(생략 가능) → 보고 줄들
  json_run '
import re, sys

pairs_path, text_path = sys.argv[1], sys.argv[2]
excl_path = sys.argv[3] if len(sys.argv) > 3 else None

rows = []
for line in open(pairs_path, encoding="utf-8"):
    parts = line.rstrip("\n").split("\t")
    if len(parts) >= 2:
        rows.append((parts[1:], parts[0]))

# 제외 목록은 행 순서가 pairs 와 같다. 파일이 없거나 짧으면 그 행은 제외가 없는 것으로 본다.
excls = []
if excl_path:
    try:
        for line in open(excl_path, encoding="utf-8"):
            excls.append([e for e in line.rstrip("\n").split("\t") if e])
    except Exception:
        excls = []

try:
    text = open(text_path, encoding="utf-8").read()
except Exception:
    sys.exit(0)

body = re.sub(r"```.*?```", " ", text, flags=re.S)
body = re.sub(r"`[^`]*`", " ", body)

def masked(b, exclusions):
    """제외어가 놓인 곳을 같은 길이의 공백으로 덮는다. 그 안에서 잡힌 것은 세지 않는다는 뜻이다.
    위치를 세는 대신 덮어 두면 겹치는 제외어도 한 번에 처리되고 글자 수를 안 센다."""
    if not exclusions:
        return b
    # 긴 것부터 덮는다. 짧은 것이 먼저 덮으면 그것을 품은 긴 제외어가 더는 안 맞는다.
    for e in sorted(exclusions, key=len, reverse=True):
        b = b.replace(e, " " * len(e))
    return b

for i, (words, repl) in enumerate(rows):
    ex = excls[i] if i < len(excls) else []
    target = masked(body, ex)
    found = [w for w in words if w and w in target]
    if found:
        print(" · ".join(found) + " -> " + repl)
' "$1" "$2" ${3:+"$3"} 2>/dev/null | tr -d '\r' || true
}
