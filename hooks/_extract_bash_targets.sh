#!/usr/bin/env bash
# 공유: Bash 툴 입력 JSON 에서 "쓰기 대상이 된 파일 경로"를 뽑는다(한 줄에 하나, 중복 제거).
# 소비자는 Bash 로 고친 파일을 보는 훅이다. `_hook_input.sh` 의 hook_file_paths 가 Write·Edit 의
# file_path 를, 이 파일이 Bash 명령의 대상을 맡는다. 명령 문자열을 꺼내는 것은 `_extract_command.sh` 가 한다.
#
# 뽑는 것은 쓰기 구문의 대상뿐이다. 읽기만 하는 인자는 뽑지 않는다 — `cat a.md` 에 넛지가 뜨면
# 읽을 때마다 무시해야 할 알림이 붙고, 그것을 무시하다 보면 진짜 쓰기에서도 흘려보낸다.
#
#   sed -i … FILE…      리다이렉션 > FILE / >> FILE      tee [-a] FILE…
#   cp SRC… DST         mv SRC… DST                      git mv SRC… DST
#
# 못 뽑는 것이 있고 그것을 숨기지 않는다. 파이썬 스크립트가 내부에서 여는 파일, `git checkout`
# 처럼 명령줄에 대상이 안 나타나는 복원, 변수로 받은 경로, 공백이 든 경로다. 그 구멍은 Stop 에서
# git 으로 바뀐 파일을 보는 겹이 덮는다. 여기서 추측해 넓히지 않는다 — 틀린 경로를 뽑으면
# 엉뚱한 파일에 알림이 뜨고, 그러면 훅 전체의 신뢰가 떨어진다.
#
# 값을 아끼려고 두 단계로 둔다. 쓰기 구문이 없으면 awk 를 안 띄우고 끝낸다. 세션의 대부분은
# `ls`·`git status`·`grep` 이고 그것들이 여기서 바로 빠진다. 판정은 _hook_input.sh 의
# bash_cmd_writes 가 소유하고, 이 파일을 부르는 훅 둘이 같은 판정으로 먼저 거른다.
set -euo pipefail
DIR="${BASH_SOURCE[0]%/*}"; [ "$DIR" != "${BASH_SOURCE[0]}" ] || DIR=.
. "$DIR/_hook_input.sh"   # 쓰기 구문 판정(bash_cmd_writes) 공유
INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | bash "$DIR/_extract_command.sh" 2>/dev/null || true)"
[ -n "$CMD" ] || exit 0
bash_cmd_writes "$CMD" || exit 0

printf '%s' "$CMD" | LC_ALL=C awk '
# 따옴표는 걷되 안쪽을 다시 가르지 않는다. 공백이 든 경로는 못 뽑는 것으로 둔다(위 주석).
function unq(s) {
  gsub(/^["\x27]+/, "", s); gsub(/["\x27]+$/, "", s)
  return s
}
function emit(p) {
  p = unq(p)
  if (p == "" || p ~ /^-/) return
  if (!(p in seen)) { seen[p] = 1; print p }
}
{
  n = split($0, t, /[ \t\n]+/)
  mode = ""; sed_inplace = 0; sed_script_seen = 0; last = ""; collect = 0
  for (i = 1; i <= n; i++) {
    w = t[i]
    if (w == "") continue
    # 명령 구분자를 만나면 상태를 비운다. 앞 명령의 방식이 뒤 명령에 새면 안 된다.
    if (w == ";" || w == "&&" || w == "||" || w == "|") {
      if (collect && last != "") emit(last)
      mode = ""; sed_inplace = 0; sed_script_seen = 0; last = ""; collect = 0
      continue
    }
    # 리다이렉션은 어느 명령에서나 대상이다. `> f` 와 `>f` 를 함께 받는다.
    if (w == ">" || w == ">>") { if (i < n) { emit(t[i+1]); i++ }; continue }
    if (w ~ /^>>?[^>]/) { sub(/^>>?/, "", w); emit(w); continue }
    if (mode == "") {
      if (w == "sed")  { mode = "sed";  continue }
      if (w == "tee")  { mode = "tee";  continue }
      if (w == "cp" || w == "mv") { mode = "last"; collect = 1; continue }
      if (w == "git")  { mode = "git";  continue }
      continue
    }
    if (mode == "git") {
      if (w == "mv") { mode = "last"; collect = 1 } else { mode = "" }
      continue
    }
    if (mode == "sed") {
      if (w ~ /^-/) { if (w ~ /^-i/) sed_inplace = 1; continue }
      # -e 없이 부르면 첫 비옵션 낱말이 치환식이고 그 뒤가 파일이다.
      if (!sed_script_seen) { sed_script_seen = 1; continue }
      if (sed_inplace) emit(w)
      continue
    }
    if (mode == "tee") { emit(w); continue }
    if (mode == "last") { if (w !~ /^-/) last = w; continue }
  }
  if (collect && last != "") emit(last)
}
'
