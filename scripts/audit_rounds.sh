#!/usr/bin/env bash
# 회차 사이의 계산. 판단은 하지 않는다 — 앞선 회차 발견의 인용이 지금도 파일에 있으면 잔존이고
# 없으면 해소다. 문장만 바뀌고 문제가 남은 것은 해소로 잘못 세는데, 그것은 이번 회차의 렌즈가
# 새 발견으로 잡는다. 재현되는 오차를 택하고 재현 안 되는 판단을 버린다.
#   audit_rounds.sh diff    [--root DIR] <앞선 findings.json> <이번 findings.json>
#   audit_rounds.sh metrics [--root DIR] --tokens N --seconds N <이번 findings.json> [앞선 diff.json]
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
CMD="${1:-}"; [ "$#" -gt 0 ] && shift
ROOT="$HERE"; TOKENS=0; SECS=0; A=""; B=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --tokens) TOKENS="$2"; shift 2 ;;
    --seconds) SECS="$2"; shift 2 ;;
    *) if [ -z "$A" ]; then A="$1"; else B="$1"; fi; shift ;;
  esac
done
case "$CMD" in
  diff)
    [ -n "$A" ] && [ -n "$B" ] || { echo "사용: audit_rounds.sh diff [--root DIR] <앞선 findings.json> <이번 findings.json>" >&2; exit 2; }
    json_run '
import json, os, re, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
root, prior_p, cur_p = sys.argv[1], sys.argv[2], sys.argv[3]
def norm(s): return re.sub(r"\s+", " ", s or "").strip()
cache = {}
def text(p):
    p = (p or "").split(":")[0]
    if not p: return None
    if p not in cache:
        try: cache[p] = norm(open(os.path.join(root, p), encoding="utf-8").read())
        except Exception: cache[p] = None
    return cache[p]
prior = json.load(open(prior_p, encoding="utf-8"))
cur = json.load(open(cur_p, encoding="utf-8"))
cur_fp = {}
for f in cur.get("findings", []):
    cur_fp.setdefault(f.get("fingerprint"), f.get("id"))
items = []
for f in prior.get("findings", []):
    if f.get("status") == "rejected": continue
    ev, cp = norm(f.get("evidence")), norm(f.get("counterpart"))
    t1, t2 = text(f.get("file")), text(f.get("counterpart_file"))
    alive = bool(ev) and t1 is not None and ev in t1 and bool(cp) and t2 is not None and cp in t2
    items.append({"prior_id": f.get("id"), "fingerprint": f.get("fingerprint"), "title": f.get("title"),
                  "file": f.get("file"), "verdict": "잔존" if alive else "해소",
                  "matched_id": cur_fp.get(f.get("fingerprint"))})
seen = set(i["fingerprint"] for i in items)
new_ids = [f.get("id") for f in cur.get("findings", []) if f.get("fingerprint") not in seen]
json.dump({"schema": 1, "no_prior_round": False, "items": items, "new_ids": new_ids}, sys.stdout, ensure_ascii=False, indent=1)
' "$ROOT" "$A" "$B"
    ;;
  metrics)
    [ -n "$A" ] || { echo "사용: audit_rounds.sh metrics --tokens N --seconds N <이번 findings.json> [앞선 diff.json]" >&2; exit 2; }
    json_run '
import json, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
cur_p, tokens, secs = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
prior_diff = sys.argv[4] if len(sys.argv) > 4 else ""
cur = json.load(open(cur_p, encoding="utf-8"))
by = {}
for f in cur.get("findings", []):
    for lens in [x.strip() for x in str(f.get("lens", "")).split(",") if x.strip()]:
        d = by.setdefault(lens, {"raised": 0, "confirmed": 0})
        d["raised"] += 1
        if f.get("status") == "confirmed": d["confirmed"] += 1
confirmed = sum(1 for f in cur.get("findings", []) if f.get("status") == "confirmed")
out = {"by_lens": by, "confirmed": confirmed, "tokens": tokens, "seconds": secs,
       "tokens_per_confirmed": (tokens // confirmed) if confirmed else None, "resolved_rate": None}
if prior_diff:
    items = json.load(open(prior_diff, encoding="utf-8")).get("items", [])
    if items:
        out["resolved_rate"] = round(sum(1 for i in items if i.get("verdict") == "해소") / len(items), 3)
json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
' "$A" "$TOKENS" "$SECS" ${B:+"$B"}
    ;;
  *)
    echo "사용: audit_rounds.sh diff|metrics ..." >&2; exit 2 ;;
esac
