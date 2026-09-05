#!/usr/bin/env bash
# 감사 스크립트(scripts/audit_*.sh)와 회차 기록의 계약. FAIL=0.
# 스크립트는 픽스처 저장소에서 실제로 돌린다. 레포의 파일과 색인은 바꾸지 않는다.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
. "$HERE/scripts/_json_valid.sh"   # json_run — 파이썬 이름은 여기가 고른다

echo "[audit_evidence.sh — 인용 확인과 지문]"
EV="$HERE/scripts/audit_evidence.sh"
check "스크립트가 있다" "[ -f '$EV' ]"
EVT="$(mktemp -d)"
printf 'a\n어긋난 문장이 여기 있다.\nb\n' > "$EVT/doc.md"
printf 'x\n상대편 문장은 저기 있다.\ny\n' > "$EVT/other.md"
cat > "$EVT/findings.json" <<'FIXTURE'
{ "schema": 1, "findings": [
  { "id": "r#001", "file": "doc.md", "evidence": "어긋난 문장이 여기 있다.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장은 저기 있다.", "principle": "SSOT" },
  { "id": "r#002", "file": "doc.md", "evidence": "이 문장은 파일에 없다.",
    "counterpart_file": "other.md", "counterpart": "상대편 문장은 저기 있다.", "principle": "SSOT" }
] }
FIXTURE
EV_OUT="$(bash "$EV" --root "$EVT" "$EVT/findings.json" 2>/dev/null || true)"
evq() { printf '%s' "$EV_OUT" | json_run "$1"; }
check "출력이 JSON 이다"                 "printf '%s' \"\$EV_OUT\" | json_valid_stdin"
check "있는 인용을 찾았다고 적는다"       "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"findings\"][0][\"evidence_found\"] is True else 1)'"
check "없는 인용을 못 찾았다고 적는다"     "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d[\"findings\"][1][\"evidence_found\"] is False else 1)'"
check "상대편 인용도 확인한다"            "evq 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if all(f[\"counterpart_found\"] is True for f in d[\"findings\"]) else 1)'"
check "지문이 열두 자 16진수다"           "evq 'import json,sys,re; d=json.load(sys.stdin); sys.exit(0 if all(re.fullmatch(r\"[0-9a-f]{12}\", f[\"fingerprint\"]) for f in d[\"findings\"]) else 1)'"
check "같은 인용과 원칙이면 지문이 같다"   "evq 'import json,sys,hashlib; d=json.load(sys.stdin); a,b=d[\"findings\"]; sys.exit(0 if a[\"fingerprint\"]!=b[\"fingerprint\"] else 1)'"
check "출력에 CR 이 없다"                 "! printf '%s' \"\$EV_OUT\" | grep -q \$'\\r'"
rm -rf "$EVT"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
