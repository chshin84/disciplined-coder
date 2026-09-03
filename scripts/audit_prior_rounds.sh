#!/usr/bin/env bash
# 대조할 앞선 회차 둘(직전 회차와 전전 회차)을 고른다 — run.json 의 executor 가 같고 completed 가 참인 폴더를 경로 정렬해 최근 둘을
# 최신부터 낸다. --stale 이면 run.json 은 있으나 completed 가 참이 아닌 폴더(끊긴 회차)를 낸다.
# 고르기를 LLM 에 두지 않는다 — 후보를 고르는 일은 LLM 밖에 둔다. run.json 이 없는 옛 기록은 회차로 세지 않는다.
# 사용: audit_prior_rounds.sh [실행체 이름] [--root 레포 경로] [--stale]
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
EXEC="self-audit"; ROOT="$HERE"; STALE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --stale) STALE=1; shift ;;
    *) EXEC="$1"; shift ;;
  esac
done
RV="$ROOT/docs/superpowers/reviews"
[ -d "$RV" ] || exit 0
json_run '
import json, os, sys
# 이 PC 의 파이썬은 줄 끝에 CR 을 붙인다. 받는 쪽이 이름 끝의 CR 까지 이름으로 읽으므로 LF 만 낸다.
sys.stdout.reconfigure(newline=chr(10))
rv, exec_name, stale = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
done, broken = [], []
for name in sorted(os.listdir(rv)):
    p = os.path.join(rv, name, "run.json")
    if not os.path.isfile(p): continue
    try:
        d = json.load(open(p, encoding="utf-8"))
    except Exception:
        broken.append(name); continue
    if d.get("executor") != exec_name: continue
    (done if d.get("completed") is True else broken).append(name)
if stale:
    for n in broken: print(n)
else:
    for n in list(reversed(done))[:2]: print(n)
' "$RV" "$EXEC" "$STALE"
