#!/usr/bin/env bash
# 공유: 훅 입력 JSON 을 셸 파라미터 확장만으로 읽는다. 소비자는 이 파일을 source 하는 훅이다.
# 외부 명령을 띄우지 않는다. 훅은 Write·Edit·Bash 마다 돌아 프로세스 하나가 곧 매 호출의 값이다.
# 읽는 입력은 호출자의 $INPUT 이다. 값은 찍지 않고 변수에 담는다 — `$( )` 는 외부 명령이 없어도
# 서브셸을 하나 만든다. jq 에 기대지 않는다.

json_str() {  # $1=필드 이름, $2=담을 변수 이름. 첫 따옴표에서 끊고 이스케이프는 되돌리지 않는다.
  local rest
  printf -v "$2" '%s' ''
  case "$INPUT" in
    *"\"$1\""*) rest="${INPUT#*\"$1\"}" ;;
    *) return 0 ;;
  esac
  rest="${rest#*:}"
  case "$rest" in
    *'"'*) rest="${rest#*\"}" ;;
    *) return 0 ;;
  esac
  printf -v "$2" '%s' "${rest%%\"*}"
}

slash_norm() {  # $1=변수 이름. 역슬래시를 슬래시로 바꾸고 이어진 슬래시를 하나로 줄인다(tr -s '\\' '/').
  # 지역 변수 이름을 호출자와 겹치지 않게 짓는다. 겹치면 printf -v 가 호출자가 아니라 여기 것을 고친다.
  local _sn_v="${!1}" _sn_one='/' _sn_two='//'
  _sn_v="${_sn_v//\\//}"
  while [[ $_sn_v == *"$_sn_two"* ]]; do _sn_v="${_sn_v//"$_sn_two"/$_sn_one}"; done
  printf -v "$1" '%s' "$_sn_v"
}

# Write·Edit 의 file_path 값을 모두 FILE_PATHS 에 담는다(한 줄에 하나, 슬래시 정규화, 중복 제거).
# 값은 다음 따옴표까지다. 경로에 큰따옴표가 들 일이 없어 이스케이프를 풀지 않는다.
hook_file_paths() {
  local rest="$INPUT" v
  FILE_PATHS=""
  while [[ $rest == *'"file_path"'* ]]; do
    rest="${rest#*\"file_path\"}"
    v="${rest#"${rest%%[![:space:]]*}"}"
    [[ $v == :* ]] || continue
    v="${v#:}"; v="${v#"${v%%[![:space:]]*}"}"
    [[ $v == \"*\"* ]] || continue
    v="${v#\"}"; v="${v%%\"*}"
    slash_norm v
    [[ -n ${v//[[:space:]]/} ]] || continue
    case $'\n'"$FILE_PATHS" in *$'\n'"$v"$'\n'*) continue ;; esac
    FILE_PATHS+="$v"$'\n'
  done
}

# Bash 의 tool_input.command 값을 CMD 에 담는다. 명령에는 큰따옴표가 흔해 첫 따옴표에서 끊으면 뒤가
# 사라진다. 그래서 \\ 와 \" 를 먼저 다른 글자로 치운 뒤 끝 따옴표를 찾고, \n·\t·\r·\/ 를 되돌린다.
# \uXXXX 는 그대로 둔다. 쓰기 구문 판정에는 영향이 없다.
hook_command() {
  local rest a=$'\001' b=$'\002' q='"' bs='\'
  CMD=""
  [[ $INPUT == *'"command"'* ]] || return 0
  rest="${INPUT#*\"command\"}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  [[ $rest == :* ]] || return 0
  rest="${rest#:}"; rest="${rest#"${rest%%[![:space:]]*}"}"
  [[ $rest == \"* ]] || return 0
  rest="${rest#\"}"
  rest="${rest//\\\\/$a}"
  rest="${rest//\\\"/$b}"
  rest="${rest%%\"*}"
  rest="${rest//\\n/$'\n'}"; rest="${rest//\\t/$'\t'}"; rest="${rest//\\r/$'\r'}"; rest="${rest//\\\//\/}"
  rest="${rest//$b/$q}"; rest="${rest//$a/$bs}"
  CMD="$rest"
}

# 셸 명령에 파일을 쓰는 구문이 있는가. 대상 뽑기(_extract_bash_targets.sh) 앞의 거르기라 넓게 두되
# 낱말 경계로 본다 — `passed`·`used` 속의 sed 와 `2>/dev/null` 이 걸리면 거의 모든 셸 호출이 지나간다.
# 명령어 자리는 줄 처음이거나 구분자(; & | ( 개행) 뒤다. sed 와 tee 는 xargs 뒤에도 오므로 낱말이면 된다.
# 재지향은 > 와 >> 이되, 앞에 숫자나 & 가 붙은 것(2> &>)과 >&2 와 >/dev/null 은 파일에 쓰지 않는다.
bash_cmd_writes() {  # $1=명령 → 쓰기 구문이 있으면 0
  local c rest pre post
  c=";${1//[$'\n\t']/ }"
  c="${c//[&|()]/;}"
  while [[ $c == *'; '* ]]; do c="${c//; /;}"; done
  case "$c" in
    *[\;\ ]sed\ -i*|*[\;\ ]sed\ *\ -i*|*[\;\ ]tee\ *|*\;cp\ *|*\;mv\ *|*\;git\ mv\ *) return 0 ;;
  esac
  rest="$1"
  while [[ $rest == *'>'* ]]; do
    pre="${rest%%>*}"; post="${rest#*>}"
    [[ $post == '>'* ]] && post="${post#>}"
    rest="$post"
    case "$pre" in *[0-9\&]) continue ;; esac
    post="${post#"${post%%[![:space:]]*}"}"
    case "$post" in
      ''|'&'*|/dev/null|/dev/null[\ \;\|\&\)]*) continue ;;
    esac
    return 0
  done
  return 1
}
