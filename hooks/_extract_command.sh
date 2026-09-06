#!/usr/bin/env bash
# 공유: Bash 툴 입력 JSON에서 "command" 문자열 값을 꺼내 이스케이프를 되돌린다.
# 소비자는 Bash 명령을 보는 훅이다. _extract_path.sh 가 file_path 를 맡는 것과 짝을 이룬다.
# grep 한 줄로 못 뽑는 이유는 명령에 큰따옴표가 들어가기 때문이다 — `"[^"]*"` 로 끊으면 첫 \" 에서
# 잘려 뒤가 통째로 사라지고, 그러면 그 뒤에 놓인 명령어를 훅이 못 본다(FAIL-LOUD).
# 순수 awk 라 jq 에 기대지 않는다.
set -euo pipefail
awk '
{ buf = buf $0 "\n" }
END {
  k = index(buf, "\"command\"")
  if (k == 0) exit
  rest = substr(buf, k + 9)
  n = length(rest); i = 1
  while (i <= n && substr(rest, i, 1) ~ /[ \t\n\r]/) i++
  if (substr(rest, i, 1) != ":") exit
  i++
  while (i <= n && substr(rest, i, 1) ~ /[ \t\n\r]/) i++
  if (substr(rest, i, 1) != "\"") exit
  i++
  out = ""
  while (i <= n) {
    c = substr(rest, i, 1)
    if (c == "\\") {
      e = substr(rest, i + 1, 1)
      if (e == "n") out = out "\n"
      else if (e == "t") out = out "\t"
      else if (e == "r") out = out "\r"
      else if (e == "u") { i += 6; continue }   # \uXXXX 는 명령에 거의 없다 — 건너뛴다
      else out = out e
      i += 2; continue
    }
    if (c == "\"") break
    out = out c
    i++
  }
  printf "%s", out
}
'
