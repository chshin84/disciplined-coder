#!/usr/bin/env bash
# 공유 헬퍼: 「금지 표현」 표를 한 번 읽어 두 파일로 낸다. 그 표는 정본이 아니라
# korean-banned-words.md 에 있고, 그 파일은 외부 저장소의 JSON 에서 만들어 낸 생성물이다.
# 소비자는 hooks/doc_word_pretooluse.sh 다. 답을 검사하던 훅이 값 때문에 걷혀 지금은 하나이고,
# 표를 읽는 자리를 늘리지 않으려고 파싱은 계속 여기 한 벌만 둔다(SSOT).
#
# awk 한 번으로 끝낸다. 이 PC 는 윈도우라 프로세스 하나 띄우는 값이 크다. 행마다 파이프를
# 돌리는 셸 반복으로 짰다가 3MB 기록에서 한 번에 13,057밀리초가 나왔고, 같은 일을 파이썬
# 한 번으로 하면 1,108밀리초였다. 그래서 셸에서는 프로세스 수를 줄이는 쪽으로만 짠다.
#
# 표를 읽는 것은 여기 awk 하나뿐이다. 파이썬은 정본을 다시 파싱하지 않고 여기서 낸 pairs
# 파일을 읽는다. 파서가 둘이면 표의 모양이 바뀔 때 한쪽만 따라간다.

BANNED_TABLE_HEAD='### 금지 표현'

# 표를 파일 둘로 낸다. pairs 는 한 행에 "대체어<탭>글자<탭>글자…", tokens 는 글자만 한 줄에 하나.
# 표의 행만 본다 — 절의 설명 문단에도 백틱이 있어 절 전체를 뽑으면 그 문단의 경로가 금지어가 된다.
# 첫 칸에서만 글자를 뽑아 대체어 칸에 백틱이 생겨도 금지어로 새지 않게 한다.
# 로케일을 C 로 둔다. 가르는 글자가 세로줄과 백틱뿐인데 둘 다 아스키이고, UTF-8 이어보기 바이트는
# 0x80 이상이라 한국어 안에 그 두 글자가 나타날 수 없다. 그래서 바이트로 갈라도 결과가 같다.
# C.UTF-8 로 두었을 때 이 awk 한 번이 213밀리초였고 C 로 바꾸니 크게 줄었다.
banned_parse() {  # $1=표가 든 파일 경로, $2=pairs 낼 곳, $3=tokens 낼 곳
  LC_ALL=C awk -v h="$BANNED_TABLE_HEAD" -v pairs="$2" -v toks="$3" '
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
    }
    END { close(pairs); close(toks) }
  ' "$1"
}

# 본문에서 금지 표현을 찾아 "걸린 말 · 걸린 말 -> 대체어" 줄들을 낸다. 못 찾으면 아무것도 안 낸다.
# 맞추는 곳을 여기 하나로 둔다. Pre 는 쓰려는 내용을, Post 는 이미 쓰인 파일을 넘기는데, 맞추는
# 규칙이 둘이면 같은 문장이 도구에 따라 다르게 판정된다.
#
# 코드 블록과 백틱 안은 걷어 낸다. 파일 내용과 식별자를 인용한 것까지 잡으면 거짓 판정이 되어
# 훅을 끄게 만든다. 금지어를 문서에 적어야 할 때는 백틱으로 감싸면 지나간다.
banned_report() {  # $1=pairs 경로, $2=검사할 텍스트 파일 → 보고 줄들
  json_run '
import re, sys

pairs_path, text_path = sys.argv[1], sys.argv[2]

rows = []
for line in open(pairs_path, encoding="utf-8"):
    parts = line.rstrip("\n").split("\t")
    if len(parts) >= 2:
        rows.append((parts[1:], parts[0]))

try:
    text = open(text_path, encoding="utf-8").read()
except Exception:
    sys.exit(0)

body = re.sub(r"```.*?```", " ", text, flags=re.S)
body = re.sub(r"`[^`]*`", " ", body)

for words, repl in rows:
    found = [w for w in words if w and w in body]
    if found:
        print(" · ".join(found) + " -> " + repl)
' "$1" "$2" 2>/dev/null | tr -d '\r' || true
}
