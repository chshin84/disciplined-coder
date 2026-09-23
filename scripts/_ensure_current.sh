#!/usr/bin/env bash
# 공유 헬퍼: 이 플러그인의 설치본이 마켓플레이스 사본보다 뒤처졌으면 새 판으로 옮기고, 다시 켜라고
# 알린다. 소비자는 scaffold.sh 다.
#
# 자동 갱신 플래그만으로는 모자라다. 사본을 새 커밋까지 받아 놓고도 설치본을 안 옮기는 것이 이 PC
# 에서 실제로 있었다. 그 상태에서는 세션 시작 훅이 옛 판으로 돌고, 옛 판으로 도는 동안 아무도 그
# 사실을 모른다. 훅은 깔려 있는 판으로만 도므로 이 확인을 훅 안에 두는 것 말고는 방법이 없다.
#
# 견주는 두 값이 다 디스크에 있어 네트워크에 안 나간다. 같으면 아무것도 출력하지 않으므로 평상시
# 세션은 값을 안 치른다.
#
# 옮긴 뒤에 반드시 다시 켜라고 말한다. `claude plugin update` 의 도움말이 "restart required to
# apply" 라고 적고 있다. 옮겼다고만 알리면 사용자는 고쳐진 줄 알고 그 세션을 계속 쓰는데 실제로는
# 옛 판이 돈다.
. "${BASH_SOURCE[0]%/*}/_json_valid.sh"   # 파이썬 인터프리터 고르기(SSOT)

# $1=설정 홈(~/.claude). 사용자에게 보일 줄을 stdout 으로 낸다. 어느 갈래에서도 0 으로 끝난다 —
# 갱신 확인이 세션 시작을 막지 않는다.
ensure_install_current() {
  local home="$1" inst out id sha name dir head rc bin
  inst="$home/plugins/installed_plugins.json"
  [ -f "$inst" ] || return 0

  # 설치 기록에서 우리 항목의 커밋을 읽는다. 배포처 이름은 PC 마다 다를 수 있으므로 이름을 박지
  # 않고 접두사로 찾는다.
  local prog='
import json,sys,io
d=json.load(io.open(sys.argv[1],encoding="utf-8")).get("plugins",{})
for k,v in d.items():
    if k.startswith("disciplined-coder@"):
        for e in v:
            s=e.get("gitCommitSha")
            if s:
                print(k+"|"+s); sys.exit(0)
sys.exit(1)
'
  out="$(json_run "$prog" "$inst" 2>/dev/null)" || return 0
  id="${out%%|*}"; sha="${out##*|}"
  [ -n "$id" ] && [ -n "$sha" ] || return 0

  name="${id#*@}"
  dir="$home/plugins/marketplaces/$name"
  # 사본이 git 클론이 아니면 견줄 값이 없다. 어떤 배포처는 스냅샷으로 놓여 커밋을 모른다.
  [ -d "$dir/.git" ] || return 0
  head="$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)"
  [ -n "$head" ] || return 0

  # 설치 기록의 값이 줄임 해시일 수 있어 양쪽으로 접두사를 견준다.
  case "$head" in "$sha"*) return 0 ;; esac
  case "$sha" in "$head"*) return 0 ;; esac

  # 시험에서 실제 명령을 실행하지 않도록 주입한다. PYTHONUTF8 상태를 주입하는 것과 같은 방식이다.
  bin="${DISCIPLINED_CODER_CLAUDE_BIN:-claude}"
  rc=0; "$bin" plugin update "$id" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "🔵 disciplined-coder: 설치본이 사본보다 뒤처져 있어 새 판으로 옮겼다($sha → $head). 클로드 코드를 다시 켜야 새 판이 실린다 — 이 세션은 옛 판으로 돈다."
  else
    echo "🔵 disciplined-coder: 설치본이 사본보다 뒤처졌는데 옮기지 못했다($sha → $head, 종료 코드 $rc). 직접 실행하라: $bin plugin update $id"
  fi
  return 0
}
