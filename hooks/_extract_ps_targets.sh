#!/usr/bin/env bash
# 공유: PowerShell 툴 입력에서 "쓰기 대상이 된 파일 경로"를 뽑는다(한 줄에 하나, 중복 제거).
# 소비자는 셸로 고친 파일을 보는 훅(doc_word_posttooluse.sh·readonly_pretooluse.sh)이다. Bash 명령은
# `_extract_bash_targets.sh` 가 맡는다. 명령 문자열은 Bash 와 같은 키(tool_input.command)에 있어
# `_hook_input.sh` 의 hook_command 가 꺼낸다. 이 파일은 `_hook_input.sh` 를 먼저 싣는 쪽에서 source 한다.
#
#   Set-Content·Add-Content·Out-File 의 -Path·-LiteralPath·-FilePath 와 첫 위치 인자
#   Copy-Item·Move-Item(별칭 cp·copy·cpi·mv·move·mi)의 -Destination 과 둘째 위치 인자
#   재지향 > FILE · >> FILE · 1> FILE · *> FILE
#
# 명령 이름과 매개변수 이름은 대소문자를 가리지 않는다. 매개변수 이름의 줄임(-Pa)과 변수로 받은 경로($p)는
# 뽑지 않는다 — 추측한 경로로 엉뚱한 파일에 알리지 않기 위해서다. 읽기 명령(Get-Content 등)은 뽑지 않는다.
# 두 단계 구조는 Bash 와 같다. ps_cmd_writes 로 먼저 거르고 지나간 명령만 awk 로 가른다.

ps_cmd_writes() {  # $1=명령 → 쓰기 구문이 있으면 0
  local c
  cmd_unquote "$1"
  c=";${UNQ,,}"
  c="${c//[$'\n\t|(){}']/;}"
  while [[ $c == *'; '* ]]; do c="${c//; /;}"; done
  case "$c" in
    *set-content*|*add-content*|*out-file*|*copy-item*|*move-item*) return 0 ;;
    *\;cp\ *|*\;copy\ *|*\;cpi\ *|*\;mv\ *|*\;move\ *|*\;mi\ *|*\;ac\ *) return 0 ;;
  esac
  cmd_redirect_writes "$UNQ"
}

PS_TARGETS_AWK='
function push(t, k) { nt++; tok[nt] = t; kind[nt] = k }
function flush() { if (inw) { push(cur, "w"); cur = ""; inw = 0 } }
function usable(p) { return p != "" && p !~ /^[$(@{]/ }
function emit(p) { if (usable(p)) print p }
function reset() { cmd = ""; np = 0; pth = ""; dst = "" }
function finish(   cls) {
  cls = class(cmd)
  if (cls == "content") { if (pth == "" && np >= 1) pth = pos[1]; emit(pth) }
  if (cls == "copy") {
    if (pth == "" && np >= 1) { pth = pos[1]; if (dst == "" && np >= 2) dst = pos[2] }
    else if (dst == "" && np >= 1) dst = pos[1]
    if (usable(dst)) print "@c\t" dst (usable(pth) ? "\t" pth : "")
  }
  reset()
}
function class(c) {
  if (c == "set-content" || c == "add-content" || c == "out-file" || c == "ac") return "content"
  if (c == "copy-item" || c == "move-item" || c == "cp" || c == "copy" || c == "cpi" || c == "mv" || c == "move" || c == "mi") return "copy"
  return ""
}
{ src = src (NR > 1 ? "\n" : "") $0 }
END {
  n = length(src); q = ""; cur = ""; inw = 0; nt = 0
  for (i = 1; i <= n; i++) {
    ch = substr(src, i, 1)
    if (q != "") {
      if (ch == q) { if (substr(src, i + 1, 1) == q) { i++; cur = cur ch } else q = "" }
      else if (ch == "`" && q == "\"" && i < n) { i++; cur = cur substr(src, i, 1) }
      else cur = cur ch
      continue
    }
    if (ch == "\"" || ch == "\047") { q = ch; inw = 1; continue }
    if (ch == "`" && i < n) { i++; c2 = substr(src, i, 1); if (c2 != "\n") { cur = cur c2; inw = 1 }; continue }
    if (ch == " " || ch == "\t" || ch == "\r") { flush(); continue }
    if (ch == "\n" || ch == ";" || ch == "|" || ch == "(" || ch == ")" || ch == "{" || ch == "}") { flush(); push(";", "o"); continue }
    if (ch == "&" && substr(src, i + 1, 1) == "&") { i++; flush(); push(";", "o"); continue }
    if (ch == ">") {
      fd = (inw && (cur ~ /^[0-9]$/ || cur == "*")) ? cur : ""
      if (fd != "") { cur = ""; inw = 0 } else flush()
      if (substr(src, i + 1, 1) == ">") i++
      if (substr(src, i + 1, 1) == "&") { i++; push("skip", "o"); continue }
      push((fd == "" || fd == "1" || fd == "*") ? ">" : "skip", "o"); continue
    }
    cur = cur ch; inw = 1
  }
  flush()
  reset()
  for (k = 1; k <= nt; k++) {
    w = tok[k]
    if (kind[k] == "o") {
      if (w == ";") { finish(); continue }
      if (w == ">") { if (k < nt && kind[k + 1] == "w" && tolower(tok[k + 1]) != "$null") { emit(tok[k + 1]) }; if (kind[k + 1] == "w") k++; continue }
      if (k < nt && kind[k + 1] == "w") k++
      continue
    }
    if (cmd == "") { cmd = tolower(w); continue }
    if (class(cmd) == "") continue
    if (w ~ /^-[A-Za-z]/) {
      val = ""; has = 0; c = index(w, ":")
      if (c) { val = substr(w, c + 1); name = tolower(substr(w, 2, c - 2)); has = 1 } else name = tolower(substr(w, 2))
      if (name ~ /^(force|nonewline|passthru|whatif|confirm|append|noclobber|asbytestream|recurse|container|verbose|debug|usetransaction)$/) continue
      if (!has && k < nt && kind[k + 1] == "w") { val = tok[k + 1]; k++ }
      if (name == "path" || name == "literalpath" || name == "lp" || name == "pspath" || name == "filepath") pth = val
      else if (name == "destination") dst = val
      continue
    }
    pos[++np] = w
  }
  finish()
}
'
ps_write_targets() {  # $1=명령, $2=상대 경로의 기준 폴더(생략 가능) → 쓰기 대상 경로를 한 줄에 하나 낸다
  printf '%s' "$1" | LC_ALL=C awk "$PS_TARGETS_AWK" | targets_resolve "${2:-}"
}
