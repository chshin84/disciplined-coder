#!/usr/bin/env bash
# 발견의 인용이 실제 파일에 그 글자로 있는지 확인하고 지문을 붙인다. 판단은 하지 않는다.
# 인용이 없는 발견을 LLM 이 아니라 여기서 떨어뜨리는 것이 이 스크립트를 둔 이유다.
# 사용: audit_evidence.sh [--root DIR] <findings.json>   (결과 JSON 을 stdout 으로 낸다)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
ROOT="$HERE"; IN=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    *) IN="$1"; shift ;;
  esac
done
[ -n "$IN" ] || { echo "사용: audit_evidence.sh [--root DIR] <findings.json>" >&2; exit 2; }
json_run '
import json, os, re, sys, hashlib
sys.stdout.reconfigure(newline=chr(10))
root, path = sys.argv[1], sys.argv[2]
def norm(s): return re.sub(r"\s+", " ", s or "").strip()
cache = {}
def text(p):
    p = (p or "").split(":")[0]
    if not p: return None
    if p not in cache:
        try: cache[p] = norm(open(os.path.join(root, p), encoding="utf-8").read())
        except Exception: cache[p] = None
    return cache[p]
d = json.load(open(path, encoding="utf-8"))
for f in d.get("findings", []):
    ev, cp = norm(f.get("evidence")), norm(f.get("counterpart"))
    t1, t2 = text(f.get("file")), text(f.get("counterpart_file"))
    f["evidence_found"] = bool(ev) and t1 is not None and ev in t1
    f["counterpart_found"] = bool(cp) and t2 is not None and cp in t2
    f["fingerprint"] = hashlib.sha1(chr(31).join([ev, cp, f.get("principle", "")]).encode("utf-8")).hexdigest()[:12]
json.dump(d, sys.stdout, ensure_ascii=False, indent=1)
' "$ROOT" "$IN"
