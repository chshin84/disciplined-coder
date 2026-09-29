#!/usr/bin/env bash
# 공유 헬퍼: 이 플러그인의 설치본이 원격 저장소보다 뒤처졌으면 새 버전으로 옮기고, 다시 켜라고
# 알린다. 소비자는 hooks/update_check_sessionstart.sh 다.
#
# 자동 갱신 플래그만으로는 모자라다. Claude Code 의 마켓플레이스 새로고침은 세션 시작 훅보다
# 2~4분 뒤에 비동기로 도착하므로, 훅이 도는 시점에는 로컬 사본도 옛 커밋이다. 그래서 설치본을
# 로컬 사본이 아니라 원격 HEAD 와 비교한다. 판정 규칙은 kw-control-tower 와 같다.
#
# - 원격 HEAD 는 curl 로 git smart HTTP 의 info/refs 를 2초 제한으로 읽는다. 실측 0.2초로
#   git ls-remote(0.6초)보다 빠르고 GitHub API 의 시간당 호출 한도가 없다.
# - 배포처가 브랜치나 태그(ref)를 지정했거나, 원격을 못 읽으면 로컬 사본의 HEAD 와 비교한다.
#   지정된 ref 를 원격 기본 브랜치와 비교하면 매 세션 불일치가 나서 갱신이 되풀이된다.
# - 같은 원격 커밋으로 갱신이 한 번 실패했으면 다시 시도하지 않고 알림만 한다. 원격에 새 커밋이
#   생기면 다시 시도한다. 기록은 update.stuck 이다.
# - 세션 사이에 자동 갱신이 설치본을 옮겼으면 알린다. 지난 세션에 본 커밋은 update.seen 이다.
#   이 세션이 새 버전으로 실행되는지는 실행 중인 CLAUDE_PLUGIN_ROOT 의 폴더 이름으로 판정한다.
#
# 옮긴 뒤에는 반드시 다시 켜라고 말한다. `claude plugin update` 의 도움말이 "restart required to
# apply" 라고 적고 있다. 실패했으면 다시 켜도 새 버전이 안 실리므로, 실패 사실과 직접 실행할 명령을
# 낸다. 첫 줄 형식은 kw-control-tower 와 같아, 두 플러그인이 한 세션에 함께 안내해도 같은 종류로
# 읽힌다. 알릴 것이 없으면 아무것도 출력하지 않는다.
. "${BASH_SOURCE[0]%/*}/_json_valid.sh"   # 파이썬 인터프리터 고르기

# $1=설정 홈(~/.claude). 사용자에게 보일 줄을 stdout 으로 낸다. 어느 분기에서도 0 으로 끝난다 —
# 갱신 확인이 세션 시작을 막지 않는다.
ensure_install_current() {
  local home="$1" inst out id sha url ref name dir head rc bin curl kdir seen stuck restart=0 notes="" root
  inst="$home/plugins/installed_plugins.json"
  [ -f "$inst" ] || return 0

  # 설치 기록에서 우리 항목의 커밋을, 배포처 기록에서 원격 주소와 ref 를 읽는다. 배포처 이름은
  # PC 마다 다를 수 있으므로 이름을 박지 않고 접두사로 찾는다.
  local prog='
import json,sys,io,os
d=json.load(io.open(sys.argv[1],encoding="utf-8")).get("plugins",{})
for k,v in d.items():
    if k.startswith("disciplined-coder@"):
        for e in v:
            s=e.get("gitCommitSha")
            if s:
                url=ref=""
                if os.path.isfile(sys.argv[2]):
                    src=json.load(io.open(sys.argv[2],encoding="utf-8")).get(k.split("@",1)[1],{}).get("source",{})
                    ref=src.get("ref","")
                    if src.get("source")=="github" and src.get("repo"):
                        url="https://github.com/"+src["repo"]+".git"
                    elif str(src.get("url","")).startswith("https://"):
                        url=src["url"]
                print("|".join([k,s,url,ref])); sys.exit(0)
sys.exit(1)
'
  out="$(json_run "$prog" "$inst" "$home/plugins/known_marketplaces.json" 2>/dev/null)" || return 0
  IFS='|' read -r id sha url ref <<< "$out"
  [ -n "$id" ] && [ -n "$sha" ] || return 0
  name="${id#*@}"
  dir="$home/plugins/marketplaces/$name"
  kdir="$home/disciplined-coder"; mkdir -p "$kdir"

  # 세션 사이의 자동 갱신. 처음 보는 PC 면 기록만 하고 알리지 않는다.
  seen="$(cat "$kdir/update.seen" 2>/dev/null || true)"
  if [ -n "$seen" ] && [ "$seen" != "$sha" ]; then
    root="${CLAUDE_PLUGIN_ROOT:-}"; root="${root%/}"; root="${root##*/}"; root="${root##*\\}"
    if [ -n "$root" ] && case "$sha" in "$root"*) false ;; *) true ;; esac; then
      restart=1
      notes="자동 갱신이 설치본을 옮겼다(${seen:0:7} → ${sha:0:7}). 이 세션은 옛 버전으로 실행된다."
    else
      notes="자동 갱신이 설치본을 옮겼다(${seen:0:7} → ${sha:0:7}). 이 세션에 새 버전이 적용되어 있다."
    fi
  fi
  printf '%s\n' "$sha" > "$kdir/update.seen"

  # 원격 HEAD. 시험에서 네트워크에 나가지 않도록 curl 을 주입한다.
  head=""
  if [ -z "$ref" ] && [ -n "$url" ]; then
    curl="${DISCIPLINED_CODER_CURL_BIN:-curl}"
    head="$("$curl" -s -f -m 2 "$url/info/refs?service=git-upload-pack" 2>/dev/null \
      | grep -ao '[0-9a-f]\{40\} HEAD' | head -1 | cut -c1-40)"
  fi
  [ -n "$head" ] || head="$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)"

  # 설치 기록의 값이 줄임 해시일 수 있어 양쪽으로 접두사를 비교한다.
  if [ -z "$head" ] || case "$head" in "$sha"*) true ;; *) false ;; esac \
     || case "$sha" in "$head"*) true ;; *) false ;; esac; then
    rm -f "$kdir/update.stuck"
  else
    # 시험에서 실제 명령을 실행하지 않도록 주입한다. PYTHONUTF8 상태를 주입하는 것과 같은 방식이다.
    bin="${DISCIPLINED_CODER_CLAUDE_BIN:-claude}"
    stuck="$(cat "$kdir/update.stuck" 2>/dev/null || true)"
    if [ "$stuck" = "$head" ]; then
      notes="${notes:+$notes
}설치본이 원격보다 뒤처져 있다(${sha:0:7} → ${head:0:7}). 이 커밋으로는 이미 갱신에 실패해 다시 시도하지 않았다. 직접 실행하라: $bin plugin marketplace update $name && $bin plugin update $id"
    else
      # 로컬 사본이 옛 커밋이면 plugin update 가 옮길 새 버전이 없으므로 사본부터 원격에 맞춘다.
      rc=0
      "$bin" plugin marketplace update "$name" >/dev/null 2>&1 || rc=$?
      [ "$rc" -eq 0 ] && { "$bin" plugin update "$id" >/dev/null 2>&1 || rc=$?; }
      if [ "$rc" -eq 0 ]; then
        restart=1
        rm -f "$kdir/update.stuck"
        printf '%s\n' "$head" > "$kdir/update.seen"
        notes="${notes:+$notes
}설치본을 원격에 맞춰 옮겼다(${sha:0:7} → ${head:0:7}). 클로드 코드는 켤 때 플러그인을 읽으므로 이 세션은 옛 버전으로 실행된다."
      else
        printf '%s\n' "$head" > "$kdir/update.stuck"
        notes="${notes:+$notes
}설치본이 원격보다 뒤처졌는데 옮기지 못했다(${sha:0:7} → ${head:0:7}, 종료 코드 $rc). 직접 실행하라: $bin plugin marketplace update $name && $bin plugin update $id"
      fi
    fi
  fi

  [ -n "$notes" ] || return 0
  if [ "$restart" -eq 1 ]; then echo "disciplined-coder: 다시 켜야 새 버전이 적용됩니다."
  else echo "disciplined-coder: 플러그인 버전 알림"; fi
  printf '%s\n' "$notes"
  return 0
}
