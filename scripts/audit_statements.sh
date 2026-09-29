#!/usr/bin/env bash
# 문서별 렌즈 호출이 돌려준 statements 를 이름표별로 모은다. 거르지 않는다 — 갈리는 짝을 고르는
# 판단은 세션이 한다. 이름표 대부분이 둘 이상 문서의 진술이라 거르기가 값을 못 낸다. 묶는 계산은
# 세션이 회차마다 다시 쓰지 않도록 여기 둔다.
# 어느 문서의 진술인지는 원본의 target 칸이 진다(aggregating-lenses 계약).
# 사용: audit_statements.sh <렌즈 원본 JSON…>   (결과 JSON 을 stdout 으로 낸다)
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다
[ "$#" -gt 0 ] || { echo "사용: audit_statements.sh <렌즈 원본 JSON…>" >&2; exit 2; }
json_run '
import json, sys
sys.stdout.reconfigure(encoding="utf-8", newline=chr(10))
topics = {}
for p in sys.argv[1:]:
    d = json.load(open(p, encoding="utf-8"))
    target = d.get("target", "")
    for s in d.get("statements", []):
        topics.setdefault(s.get("topic", ""), []).append(
            {"file": target, "statement": s.get("statement", ""), "evidence": s.get("evidence", "")})
out = {"topics": {k: topics[k] for k in sorted(topics)}}
json.dump(out, sys.stdout, ensure_ascii=False, indent=1)
' "$@"
