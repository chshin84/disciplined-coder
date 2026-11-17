#!/usr/bin/env bash
# 공유: 훅 입력 JSON 을 셸 파라미터 확장만으로 읽는다. 소비자는 이 파일을 source 하는 훅이다.
# 외부 명령을 띄우지 않는다. 훅은 Write·Edit·Bash·PowerShell 마다 돌아 프로세스 하나가 곧 매 호출의 값이다.
# 읽는 입력은 호출자의 $INPUT 이다. 값은 찍지 않고 변수에 담는다 — `$( )` 는 외부 명령이 없어도
# 서브셸을 하나 만든다. jq 에 기대지 않는다.
# 입력이 작은 훅(Bash 전용·SessionStart·Stop)은 stdin 을 `IFS= read -r -d '' INPUT || true` 로 읽는다.
# Write·Edit 를 받는 훅은 `$(cat)` 을 유지한다 — read 는 한 바이트씩 읽어 큰 content 에서 cat 보다 느리다.

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
  # UNC(//server/share)는 앞머리 두 슬래시가 경로의 일부다. 하나로 줄이면 Git Bash 가 다른 경로로 풀어
  # 있는 파일을 없는 파일로 판정한다. 그래서 앞머리만 한 글자 되살린다.
  local _sn_v="${!1}" _sn_one='/' _sn_two='//' _sn_lead=''
  _sn_v="${_sn_v//\\//}"
  [[ $_sn_v == //* ]] && _sn_lead='/'
  while [[ $_sn_v == *"$_sn_two"* ]]; do _sn_v="${_sn_v//"$_sn_two"/$_sn_one}"; done
  printf -v "$1" '%s' "$_sn_lead$_sn_v"
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


# 훅 입력의 cwd 를 HOOK_CWD 에 담는다(슬래시 정규화). 셸 명령과 Write·Edit 의 상대 경로를 풀 기준이다.
# 훅 프로세스의 현재 폴더는 세션의 작업 폴더와 다를 수 있다. cwd 가 없으면 빈 값이고, 그때 상대 경로는
# 현재 폴더 기준으로 남는다.
hook_cwd() {
  json_str cwd HOOK_CWD
  slash_norm HOOK_CWD
}

# 상대 경로를 기준 폴더 아래로 옮긴다. 절대 경로(/…, D:…, //서버)와 기준 폴더가 빈 값이면 그대로다.
path_resolve() {  # $1=변수 이름, $2=기준 폴더
  local _pr_v="${!1}"
  slash_norm _pr_v
  case "$_pr_v" in
    /*|[A-Za-z]:*) ;;
    *) if [ -n "${2:-}" ]; then _pr_v="${2%/}/${_pr_v#./}"; fi ;;
  esac
  printf -v "$1" '%s' "$_pr_v"
}

# 따옴표 안의 글자를 Q 한 글자로 바꿔 UNQ 에 담는다. 따옴표 안의 > 와 명령 이름은 셸 구문이 아니다
# (`git commit -m "a > b.md"`). 짝이 없는 따옴표부터 끝까지는 그대로 둔다. 따옴표 안의 이스케이프는
# 풀지 않는다 — 거르기라 넓게 지나가도 대상 뽑기가 한 번 더 가른다.
cmd_unquote() {  # $1=명령 → UNQ
  local s="$1" pre q d='"' sq="'"
  UNQ=""
  while :; do
    pre="${s%%[$d$sq]*}"
    if [ "${#pre}" -eq "${#s}" ]; then UNQ+="$s"; return 0; fi
    q="${s:${#pre}:1}"; s="${s:$((${#pre}+1))}"
    case "$s" in
      *"$q"*) UNQ+="${pre}Q"; s="${s#*"$q"}" ;;
      *) UNQ+="$pre$q$s"; return 0 ;;
    esac
  done
}

# 따옴표를 걷은 명령에 파일로 가는 재지향이 있는가. >·>>·>|·1>·&>·*> 는 쓰기다. 1 이 아닌 번호(2>)와
# 복제(>&2·2>&1), /dev/null·$null 은 파일에 쓰지 않는다. bash 와 PowerShell 이 같은 판정을 쓴다.
cmd_redirect_writes() {  # $1=따옴표를 걷은 명령 → 파일 재지향이 있으면 0
  local rest="$1" pre post w
  while [[ $rest == *'>'* ]]; do
    pre="${rest%%>*}"; post="${rest#*>}"
    [[ $post == '>'* ]] && post="${post#>}"
    [[ $post == '|'* ]] && post="${post#|}"
    rest="$post"
    w="${pre##*[[:space:]\;\&\|\(]}"
    if [[ -n $w && $w != *[!0-9]* ]]; then [ "$w" = 1 ] || continue; fi
    post="${post#"${post%%[![:space:]]*}"}"
    case "$post" in
      ''|'&'*|/dev/null|/dev/null[\ \;\|\&\)]*|'$null'|'$null'[\ \;\|\)]*) continue ;;
    esac
    return 0
  done
  return 1
}

# 셸 명령에 파일을 쓰는 구문이 있는가. 대상 뽑기(_extract_bash_targets.sh) 앞의 거르기라 넓게 두되
# 낱말 경계로 본다 — `passed`·`used` 속의 sed 와 `2>/dev/null` 이 걸리면 거의 모든 셸 호출이 지나간다.
# 명령어 자리는 줄 처음이거나 구분자(; & | ( 개행) 뒤다. sed 와 tee 는 xargs 뒤에도 오므로 낱말이면 된다.
bash_cmd_writes() {  # $1=명령 → 쓰기 구문이 있으면 0
  local c
  cmd_unquote "$1"
  c=";${UNQ//[$'\n\t']/ }"
  c="${c//[&|()]/;}"
  while [[ $c == *'; '* ]]; do c="${c//; /;}"; done
  case "$c" in
    *[\;\ ]sed\ -i*|*[\;\ ]sed\ *\ -i*|*[\;\ ]sed\ --in-place*|*[\;\ ]tee\ *|*\;cp\ *|*\;mv\ *|*\;git\ mv\ *) return 0 ;;
  esac
  cmd_redirect_writes "$UNQ"
}

# 셸 대상 뽑기(_extract_bash_targets.sh·_extract_ps_targets.sh)가 낸 줄을 경로로 푼다. 보통 줄은 경로 하나다.
# "@c<탭>목적지<탭>원본…" 은 cp·mv 줄이라 목적지가 폴더이면 원본 이름을 붙이고, "@d<탭>폴더<탭>원본…" 은
# 목적지가 폴더로 정해진 줄(cp -t)이다. 상대 경로는 기준 폴더 아래로 옮기고, 같은 경로는 한 번만 낸다.
targets_resolve() {  # $1=기준 폴더, stdin=뽑은 줄 → 경로를 한 줄에 하나
  local line k dst rest s b p seen=$'\n'
  local -a srcs
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      @[cd]$'\t'*)
        k="${line:1:1}"; line="${line:3}"
        dst="${line%%$'\t'*}"; rest=""
        [[ $line == *$'\t'* ]] && rest="${line#*$'\t'}"
        path_resolve dst "${1:-}"
        if [ "$k" = d ] || [ -d "$dst" ]; then
          IFS=$'\t' read -r -a srcs <<< "$rest"
          for s in ${srcs+"${srcs[@]}"}; do
            slash_norm s; s="${s%/}"; b="${s##*/}"
            [ -n "$b" ] || continue
            p="${dst%/}/$b"
            case "$seen" in *$'\n'"$p"$'\n'*) ;; *) seen+="$p"$'\n'; printf '%s\n' "$p" ;; esac
          done
          continue
        fi
        p="$dst" ;;
      *) p="$line"; path_resolve p "${1:-}" ;;
    esac
    case "$seen" in *$'\n'"$p"$'\n'*) ;; *) seen+="$p"$'\n'; printf '%s\n' "$p" ;; esac
  done
}
