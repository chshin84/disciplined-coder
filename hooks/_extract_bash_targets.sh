#!/usr/bin/env bash
# 공유: Bash 툴 입력 JSON 에서 "쓰기 대상이 된 파일 경로"를 뽑는다(한 줄에 하나, 중복 제거).
# 소비자는 셸로 고친 파일을 보는 훅(doc_word_posttooluse.sh·readonly_pretooluse.sh)이다. `_hook_input.sh` 의
# hook_file_paths 가 Write·Edit 의 file_path 를, 이 파일이 Bash 명령의 대상을, `_extract_ps_targets.sh` 가
# PowerShell 명령의 대상을 맡는다. 명령 문자열을 꺼내는 것은 `_hook_input.sh` 의 hook_command 가 한다.
#
# 뽑는 것은 쓰기 구문의 대상뿐이다. 읽기만 하는 인자는 뽑지 않는다 — `cat a.md` 에 넛지가 뜨면
# 읽을 때마다 무시해야 할 알림이 붙고, 그것을 무시하다 보면 진짜 쓰기에서도 흘려보낸다.
#
#   sed -i … FILE…      재지향 > FILE · >> FILE · >| FILE · 1> FILE · &> FILE      tee [-a] FILE…
#   cp SRC… DST         mv SRC… DST       git mv SRC… DST       cp·mv -t DIR SRC…
#
# cp·mv 의 목적지가 폴더이면 원본 이름을 붙인 경로가 대상이다. 상대 경로는 훅 입력의 cwd 기준으로 푼다.
# 따옴표 안의 > 와 낱말은 구문이 아니다(`git commit -m "a > notes.md"`). 히어독 본문은 건너뛴다.
#
# 못 뽑는 것이 있고 그것을 숨기지 않는다. 파이썬 같은 프로그램이 내부에서 여는 파일, `git checkout`
# 처럼 명령줄에 대상이 안 나타나는 복원, 변수로 받은 경로다. 이 구멍을 덮는 다른 검사는 없다 — 그 파일에는
# 금지어 알림이 뜨지 않고, 읽기 전용 파일에 쓰는 것은 훅의 사유 없이 OS 권한 오류로만 막힌다. 여기서
# 추측해 넓히지 않는다 — 틀린 경로를 뽑으면 엉뚱한 파일에 알림이 뜨고, 그러면 훅 전체의 신뢰가 떨어진다.
#
# 값을 아끼려고 두 단계로 둔다. 쓰기 구문이 없으면 awk 를 안 띄우고 끝낸다. 세션의 대부분은
# `ls`·`git status`·`grep` 이고 그것들이 여기서 바로 빠진다. 판정은 _hook_input.sh 의
# bash_cmd_writes 가 소유하고, 이 파일을 source 하는 훅이 같은 판정으로 먼저 거르고 bash_write_targets 를 부른다.
# 실행 스크립트로 두면 호출마다 bash 와 파서가 한 번 더 뜬다.
#
# awk 는 입력 전체를 한 번에 낱말과 구문 기호로 가른 뒤 명령마다 대상을 낸다. 보통 줄은 경로 하나이고,
# cp·mv 는 "@c<탭>목적지<탭>원본…"·"@d<탭>폴더<탭>원본…" 줄로 내어 _hook_input.sh 의 targets_resolve 가
# 폴더인지 보고 경로를 만든다.
BASH_TARGETS_AWK='
function push(t, k) { nt++; tok[nt] = t; kind[nt] = k }
function flush() { if (inw) { push(cur, "w"); cur = ""; inw = 0 } }
function emit(p) { if (p != "" && p !~ /^-/) print p }
function reset() { mode = ""; cmdpos = 1; inplace = 0; script = 0; na = 0; tdir = "" }
function finish(   j, out) {
  if (mode == "cp") {
    if (tdir != "") { out = "@d\t" tdir; for (j = 1; j <= na; j++) out = out "\t" args[j]; print out }
    else if (na >= 2) { out = "@c\t" args[na]; for (j = 1; j < na; j++) out = out "\t" args[j]; print out }
  }
  reset()
}
{ src = src (NR > 1 ? "\n" : "") $0 }
END {
  n = length(src); q = ""; cur = ""; inw = 0; nt = 0; hd = ""
  for (i = 1; i <= n; i++) {
    ch = substr(src, i, 1)
    if (q != "") {
      if (ch == q) q = ""
      else if (ch == "\\" && q == "\"" && i < n) { i++; cur = cur substr(src, i, 1) }
      else cur = cur ch
      continue
    }
    if (ch == "\"" || ch == "\047") { q = ch; inw = 1; continue }
    if (ch == "\\" && i < n) { i++; c2 = substr(src, i, 1); if (c2 != "\n") { cur = cur c2; inw = 1 }; continue }
    if (ch == " " || ch == "\t" || ch == "\r") { flush(); continue }
    if (ch == "\n") {
      flush(); push(";", "o")
      # 히어독 본문은 명령이 아니다. 구분자 줄까지 건너뛴다.
      if (hd != "") {
        while (i < n) {
          j = index(substr(src, i + 1), "\n")
          line = (j ? substr(src, i + 1, j - 1) : substr(src, i + 1))
          i = (j ? i + j : n)
          if (hdtab) sub(/^\t+/, "", line)
          sub(/\r$/, "", line)
          if (line == hd) break
        }
        hd = ""
      }
      continue
    }
    if (ch == ";" || ch == "(" || ch == ")") { flush(); push(";", "o"); continue }
    if (ch == "|") { flush(); if (substr(src, i + 1, 1) == "|") i++; push(";", "o"); continue }
    if (ch == "&") {
      flush()
      if (substr(src, i + 1, 1) == ">") { i++; if (substr(src, i + 1, 1) == ">") i++; push(">", "o"); continue }
      if (substr(src, i + 1, 1) == "&") i++
      push(";", "o"); continue
    }
    if (ch == ">") {
      # 바로 앞 낱말이 숫자뿐이면 번호다. 1 은 표준 출력이라 쓰기이고, 다른 번호의 대상은 건너뛴다.
      fd = (inw && cur ~ /^[0-9]+$/) ? cur : ""
      if (fd != "") { cur = ""; inw = 0 } else flush()
      nx = substr(src, i + 1, 1)
      if (nx == ">" || nx == "|") { i++; nx = substr(src, i + 1, 1) }
      if (nx == "&") { i++; push("skip", "o"); continue }
      push((fd == "" || fd == "1") ? ">" : "skip", "o"); continue
    }
    if (ch == "<") {
      flush(); k = 1
      while (substr(src, i + 1, 1) == "<") { i++; k++ }
      if (k == 2) {
        hdtab = 0; if (substr(src, i + 1, 1) == "-") { i++; hdtab = 1 }
        while (substr(src, i + 1, 1) == " ") i++
        d = ""
        while (i < n) {
          c3 = substr(src, i + 1, 1)
          if (c3 ~ /[ \t\n;|&<>]/) break
          i++
          if (c3 != "\"" && c3 != "\047" && c3 != "\\") d = d c3
        }
        hd = d; continue
      }
      push("skip", "o"); continue
    }
    cur = cur ch; inw = 1
  }
  flush()
  reset()
  for (k = 1; k <= nt; k++) {
    w = tok[k]
    if (kind[k] == "o") {
      if (w == ";") { finish(); continue }
      if (w == ">") { if (k < nt && kind[k + 1] == "w") { emit(tok[k + 1]); k++ }; continue }
      if (k < nt && kind[k + 1] == "w") k++
      continue
    }
    if (mode == "") {
      # 명령어 자리는 명령의 첫 낱말이다. 환경 변수 대입과 sudo·xargs 같은 앞머리 뒤도 명령어 자리다.
      # sed 와 tee 도 명령어 자리에 올 때만 받는다. 다른 명령의 인자로 나온 낱말(grep tee x.md)을 쓰기로 보면 읽기 전용 훅이 읽기를 거부한다.
      if (cmdpos && w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
      if (cmdpos && w == "sed") { mode = "sed"; continue }
      if (cmdpos && w == "tee") { mode = "tee"; continue }
      if (cmdpos && (w == "cp" || w == "mv")) { mode = "cp"; continue }
      if (cmdpos && w == "git") { mode = "git"; continue }
      if (cmdpos && (w == "sudo" || w == "xargs" || w == "env" || w == "command" || w == "time" || w == "nice" || w == "nohup" || w == "exec")) continue
      cmdpos = 0
      continue
    }
    if (mode == "git") { if (w == "mv") mode = "cp"; else mode = "other"; continue }
    if (mode == "sed") {
      if (w == "-e" || w == "-f" || w == "--expression" || w == "--file") { script = 1; k++; continue }
      if (w ~ /^--expression=/ || w ~ /^--file=/) { script = 1; continue }
      if (w ~ /^-i/ || w ~ /^--in-place/) { inplace = 1; continue }
      if (w ~ /^-/) continue
      if (!script) { script = 1; continue }
      if (inplace) emit(w)
      continue
    }
    if (mode == "tee") { emit(w); continue }
    if (mode == "cp") {
      if (w == "-t" || w == "--target-directory") { if (k < nt && kind[k + 1] == "w") { tdir = tok[k + 1]; k++ }; continue }
      if (w ~ /^--target-directory=/) { tdir = substr(w, 20); continue }
      if (w ~ /^-t./) { tdir = substr(w, 3); continue }
      if (w == "-S" || w == "--suffix") { k++; continue }
      if (w ~ /^-/) continue
      args[++na] = w
      continue
    }
  }
  finish()
}
'
bash_write_targets() {  # $1=명령, $2=상대 경로의 기준 폴더(생략 가능) → 쓰기 대상 경로를 한 줄에 하나 낸다
  printf '%s' "$1" | LC_ALL=C awk "$BASH_TARGETS_AWK" | targets_resolve "${2:-}"
}
