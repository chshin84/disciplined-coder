#!/usr/bin/env bash
# 공유 헬퍼: 이 플러그인의 마켓플레이스 항목에 autoUpdate를 채워 넣는다(멱등).
# 사용자가 손으로 켜지 않아도 깃허브의 갱신이 자동으로 따라오게 하려는 것이다.
# 규칙 넷을 지킨다.
#   1) 우리 마켓플레이스 이름의 항목만 만진다. 남의 마켓플레이스는 건드리지 않는다.
#   2) autoUpdate 키가 아예 없을 때만 채운다. 사용자가 false로 둔 것은 사용자의 결정이라 그대로 둔다.
#   3) 사본을 남기고, 새로 쓴 파일을 다시 파싱해 유효할 때만 제자리에 놓는다(FAIL-LOUD).
#   4) 못 고친 회차는 그 까닭을 갈라 알린다. 설정을 못 읽은 것과 파이썬이 없는 것은 다른 일이다.
#      JSON을 다루는 데 파이썬만 쓴다 — 노드 폴백을 두면 한 번도 안 도는 사본이 하나 더 생긴다(`SIMPLE`).
# 값을 채우면 파일 전체가 두 칸 들여쓰기로 다시 찍힌다 — 내용은 그대로이나 서식은 바뀔 수 있어
# 사본(.bak)을 남기고 바뀐 경로를 호출자가 사용자에게 알린다.
# 소비자는 scaffold.sh다.
#
# 종료코드를 나눠 쓰는 까닭: 파이썬은 파싱에 실패해도 1로 끝난다. '고칠 것이 없다'를 1로 두면
# 깨진 설정이 정상 회차와 같은 값으로 들어와 경고가 죽는다. 그래서 '고칠 것이 없다'를 10으로 옮겼다.
#   0=고쳤다  10=고칠 것이 없다  3=marketplace.json에 name이 없다  4=파이썬이 없다  그 밖=읽기·파싱 실패

# $1=설정 홈(~/.claude), $2=플러그인 루트. 바뀐 파일이 있으면 그 경로를 한 줄씩 출력한다.
ensure_marketplace_autoupdate() {
  local home="$1" root="$2" mkt_json="$2/.claude-plugin/marketplace.json" f rc
  if [ ! -f "$mkt_json" ]; then
    echo "[disciplined-coder] WARNING: autoUpdate 설정을 건너뛴다 — marketplace.json을 못 찾았다($mkt_json)" >&2
    return 0
  fi
  for f in "$home/settings.json" "$home/plugins/known_marketplaces.json"; do
    [ -f "$f" ] || continue
    _autoupdate_patch "$f" "$mkt_json"; rc=$?
    case "$rc" in
      0|10) ;;
      3) echo "[disciplined-coder] WARNING: autoUpdate 설정을 건너뛴다 — marketplace.json에 name이 없다" >&2 ;;
      4) echo "[disciplined-coder] WARNING: autoUpdate 설정을 건너뛴다 — 파이썬이 없어 JSON을 다룰 수 없다" >&2 ;;
      *) echo "[disciplined-coder] WARNING: autoUpdate 설정을 건너뛴다 — $f 를 읽지 못했거나 내용이 JSON이 아니다" >&2 ;;
    esac
  done
}

# $1=고칠 파일, $2=marketplace.json. 고쳤으면 경로를 출력하고 0. 위 종료코드 표를 따른다.
_autoupdate_patch() {
  local f="$1" mkt="$2" tmp="$1.dc-tmp" rc
  local prog='
import json,sys,io
f,mktf=sys.argv[1],sys.argv[2]
name=json.load(io.open(mktf,encoding="utf-8")).get("name")
if not name: sys.exit(3)
d=json.load(io.open(f,encoding="utf-8"))
def pick(o):
    e=o.get("extraKnownMarketplaces")
    if isinstance(e,dict) and name in e and isinstance(e[name],dict): return e[name]
    if name in o and isinstance(o[name],dict) and "source" in o[name]: return o[name]
    return None
t=pick(d)
if t is None or "autoUpdate" in t: sys.exit(10)
t["autoUpdate"]=True
io.open(f+".dc-tmp","w",encoding="utf-8",newline="\n").write(json.dumps(d,ensure_ascii=False,indent=2)+"\n")
json.load(io.open(f+".dc-tmp",encoding="utf-8"))
sys.exit(0)
'
  if python3 -c 'import sys' >/dev/null 2>&1; then
    python3 -c "$prog" "$f" "$mkt" >/dev/null 2>&1; rc=$?
  elif python -c 'import sys' >/dev/null 2>&1; then
    python -c "$prog" "$f" "$mkt" >/dev/null 2>&1; rc=$?
  else
    return 4
  fi
  if [ "$rc" -ne 0 ]; then rm -f "$tmp"; return "$rc"; fi
  [ -s "$tmp" ] || { rm -f "$tmp"; return 1; }
  cp "$f" "$f.bak" || { rm -f "$tmp"; return 1; }
  mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }
  echo "$f"
}
