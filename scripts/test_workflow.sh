#!/usr/bin/env bash
# 탐색 워크플로를 시험 도구로 실행해 판정 함수와 실행 흐름을 검증한다. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WF="$HERE/workflows/prior-art-search.js"
HARNESS="$HERE/scripts/workflow_harness.mjs"
CONTRACT="$HERE/scripts/prior_art_contract.json"
FX="$(mktemp -d)"; trap 'rm -rf "$FX"' EXIT
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"

# harn <명령> [이름] — 시험 도구를 실행한다. 표준 입출력은 호출자가 잇는다.
harn() { node "$HARNESS" "$@"; }

# json_true <파일> '<파이썬 식>' — 파일을 읽은 값 d 에 대해 식이 참이면 0 을 돌려준다. 계약 코드는 C 로 읽을 수 있다.
json_true() {
  json_run '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    d = json.load(f)
with open(sys.argv[3], encoding="utf-8") as f:
    C = json.load(f)
sys.exit(0 if eval(sys.argv[2]) else 1)
' "$1" "$2" "$CONTRACT"
}

# json_same <파일 A> <파일 B> — 두 파일의 JSON 값이 같으면 0 을 돌려준다. true 와 1 은 다르다.
json_same() {
  json_run '
import json, sys
def norm(p):
    with open(p, encoding="utf-8") as f:
        return json.dumps(json.load(f), sort_keys=True, ensure_ascii=False)
sys.exit(0 if norm(sys.argv[1]) == norm(sys.argv[2]) else 1)
' "$1" "$2"
}

# schema_subset <파일> — 모든 노드(properties 값과 items 를 따라 내려간다)에서 required 가 properties 의 키에 들면 0.
schema_subset() {
  json_run '
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    d = json.load(f)
def ok(n):
    if not isinstance(n, dict):
        return True
    if "required" in n or "properties" in n:
        if not set(n.get("required", [])) <= set(n.get("properties", {}).keys()):
            return False
    kids = list(n.get("properties", {}).values())
    if "items" in n:
        kids.append(n["items"])
    return all(ok(k) for k in kids)
sys.exit(0 if all(ok(v) for v in d.values()) else 1)
' "$1"
}

echo "[정적 형식]"
check "node 가 있다" "command -v node >/dev/null 2>&1"
check "첫 줄이 export const meta = { 로 시작한다" "[ -f \"\$WF\" ] && head -n 1 \"\$WF\" | grep -qE '^export const meta = \{'"
check "export 로 시작하는 줄이 하나다" "[ -f \"\$WF\" ] && [ \"\$(grep -cE '^[[:space:]]*export ' \"\$WF\")\" -eq 1 ]"
check "meta 구간이 순수 리터럴이다" "[ -f \"\$WF\" ] && awk 'NR==1{print; if (\$0 ~ /^(\}|\};)\$/) exit; next} {print} /^(\}|\};)\$/{exit}' \"\$WF\" > \"\$FX/meta.txt\" && [ \"\$(wc -l < \"\$FX/meta.txt\")\" -ge 3 ] && tail -n 1 \"\$FX/meta.txt\" | grep -qE '^(\}|\};)\$' && [ \"\$(grep -cF '(' \"\$FX/meta.txt\")\" -eq 0 ] && [ \"\$(grep -cF '\${' \"\$FX/meta.txt\")\" -eq 0 ] && [ \"\$(grep -cF '...' \"\$FX/meta.txt\")\" -eq 0 ] && [ \"\$(grep -cF '\`' \"\$FX/meta.txt\")\" -eq 0 ]"
for K in "name: 'prior-art-search'" "description:" "whenToUse:" "'Research'" "'Verify'" "'Synthesize'" "'MapCheck'"; do
  check "meta 구간에 $K 가 있다" "[ -s \"\$FX/meta.txt\" ] && grep -qF \"\$K\" \"\$FX/meta.txt\""
done
for K in 'Date.now' 'Math.random' 'new Date(' 'require(' 'import '; do
  check "원문에 $K 가 없다" "[ -f \"\$WF\" ] && [ \"\$(grep -cF \"\$K\" \"\$WF\")\" -eq 0 ]"
done
check "schemas 출력을 얻는다" "printf '[]' | harn fn schemas > \"\$FX/schemas.json\""
for S in RESEARCHER_SCHEMA VERIFIER_SCHEMA SYNTHESIS_SCHEMA MAP_SCHEMA; do
  check "$S 의 루트 type 이 object 다" "json_true \"\$FX/schemas.json\" 'd[\"$S\"][\"type\"] == \"object\"'"
done
check "모든 노드에서 required 가 properties 의 키에 든다" "schema_subset \"\$FX/schemas.json\""
check "VERIFIER_SCHEMA 의 verdict 열거가 정해진 값이다" "json_true \"\$FX/schemas.json\" 'd[\"VERIFIER_SCHEMA\"][\"properties\"][\"judgments\"][\"items\"][\"properties\"][\"verdict\"][\"enum\"] == [\"supported\",\"unsupported\",\"unverifiable\"]'"
check "RESEARCHER_SCHEMA 의 search_status 열거가 정해진 값이다" "json_true \"\$FX/schemas.json\" 'd[\"RESEARCHER_SCHEMA\"][\"properties\"][\"search_status\"][\"enum\"] == [\"ok\",\"no-results\",\"failed\",\"not-attempted\"]'"
check "RESEARCHER_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"RESEARCHER_SCHEMA\"][\"required\"]) == {\"search_status\",\"queries\",\"issues\"}'"
check "VERIFIER_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"VERIFIER_SCHEMA\"][\"required\"]) == {\"url\",\"judgments\",\"principles_applied\"}'"
check "SYNTHESIS_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"SYNTHESIS_SCHEMA\"][\"required\"]) == {\"evidence_map\",\"conclusions\",\"principles_applied\"}'"
check "MAP_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"MAP_SCHEMA\"][\"required\"]) == {\"cells\",\"principles_applied\"}'"

echo "[시험 도구 자체]"
check "알 수 없는 함수 이름은 종료 코드 2 다" "printf '[]' | harn fn nosuch >/dev/null 2>&1; [ \$? -eq 2 ]"
check "깨진 JSON 입력의 run 은 종료 코드 2 다" "printf '{broken' | harn run >/dev/null 2>&1; [ \$? -eq 2 ]"

echo "[질의 경계 검사]"
cat > "$FX/cq_in.json" <<'EOF'
[
  [
    {"id": "S1", "output": {"search_status": "ok", "issues": [], "queries": [
      "acme agent plugin",
      "see skills/agent-prior-art/SKILL.md",
      "C:\\Users\\x\\a.md notes",
      "~/.claude config",
      "cite (docs/x.md),",
      "A/B testing",
      "HTTP/1.1 caching",
      "prior art search agent",
      "Acme Beta /etc/x"
    ]}},
    {"id": "S2", "output": null}
  ],
  ["Acme", "beta", ""]
]
EOF
cat > "$FX/cq_want.json" <<'EOF'
[
  {"id": "S1", "query": "acme agent plugin", "rule": "forbidden-term"},
  {"id": "S1", "query": "see skills/agent-prior-art/SKILL.md", "rule": "path-shape"},
  {"id": "S1", "query": "C:\\Users\\x\\a.md notes", "rule": "path-shape"},
  {"id": "S1", "query": "~/.claude config", "rule": "path-shape"},
  {"id": "S1", "query": "cite (docs/x.md),", "rule": "path-shape"},
  {"id": "S1", "query": "Acme Beta /etc/x", "rule": "forbidden-term"},
  {"id": "S1", "query": "Acme Beta /etc/x", "rule": "path-shape"}
]
EOF
check "checkQueries 출력이 기대 배열과 같다" "harn fn checkQueries < \"\$FX/cq_in.json\" > \"\$FX/cq_got.json\" && json_same \"\$FX/cq_got.json\" \"\$FX/cq_want.json\""

echo "[URL 묶기]"
cat > "$FX/gu_in.json" <<'EOF'
[[
  {"id": "S1", "output": {"search_status": "ok", "queries": [],
    "issues": [
      {"prior_claim": "claim A", "citations": [{"url": "https://a"}, {"url": "https://a"}, {"url": "https://b"}]},
      {"prior_claim": "derived claim", "citations": [{"kind": "derived", "url": ""}, {"kind": "derived"}]}
    ],
    "evidence_map": [
      {"case": "C0", "url": "https://a", "outcome": "O0", "axes": {
        "purpose": {"prior": "p0", "same": true, "note": "n"},
        "mechanism": {"prior": "m0", "same": false, "note": "n"},
        "evaluation": {"prior": "e0", "same": false, "note": "n"},
        "target": {"prior": "t0", "same": true, "note": "n"}}},
      {"case": "C1", "url": "", "outcome": "O1", "axes": {
        "purpose": {"prior": "p1", "same": true, "note": "n"},
        "mechanism": {"prior": "m1", "same": false, "note": "n"},
        "evaluation": {"prior": "e1", "same": false, "note": "n"},
        "target": {"prior": "t1", "same": true, "note": "n"}}},
      {"case": "  ", "url": "https://a", "outcome": "O2", "axes": {"purpose": {"prior": "p2", "same": true, "note": "n"}, "mechanism": {"prior": "m2", "same": false, "note": "n"}, "evaluation": {"prior": "e2", "same": false, "note": "n"}, "target": {"prior": "t2", "same": true, "note": "n"}}},
      {"case": "C3", "url": "https://a", "outcome": "O3", "axes": {"purpose": {"prior": "  ", "same": true, "note": "n"}, "mechanism": {"prior": "  ", "same": false, "note": "n"}, "evaluation": {"prior": "  ", "same": false, "note": "n"}, "target": {"prior": "  ", "same": true, "note": "n"}}}
    ]}},
  {"id": "S2", "output": {"search_status": "ok", "queries": [],
    "issues": [
      {"prior_claim": "claim B", "citations": [{"url": "https://a"}]},
      {"prior_claim": "  ", "citations": [{"url": "https://c"}]}
    ]}},
  {"id": "S3", "output": null}
]]
EOF
cat > "$FX/gu_want.json" <<'EOF'
{
  "items": [
    {"ref": "S1#issue#0", "urls": ["https://a", "https://b"], "text": "claim A"},
    {"ref": "S1#issue#1", "urls": [], "text": "derived claim"},
    {"ref": "S1#case#0", "urls": ["https://a"],
     "text": "{\"case\":\"C0\",\"outcome\":\"O0\",\"prior\":{\"purpose\":\"p0\",\"mechanism\":\"m0\",\"evaluation\":\"e0\",\"target\":\"t0\"}}",
     "row": {"case": "C0", "url": "https://a", "outcome": "O0", "axes": {
        "purpose": {"prior": "p0", "same": true, "note": "n"},
        "mechanism": {"prior": "m0", "same": false, "note": "n"},
        "evaluation": {"prior": "e0", "same": false, "note": "n"},
        "target": {"prior": "t0", "same": true, "note": "n"}}}},
    {"ref": "S1#case#1", "urls": [],
     "text": "{\"case\":\"C1\",\"outcome\":\"O1\",\"prior\":{\"purpose\":\"p1\",\"mechanism\":\"m1\",\"evaluation\":\"e1\",\"target\":\"t1\"}}",
     "row": {"case": "C1", "url": "", "outcome": "O1", "axes": {
        "purpose": {"prior": "p1", "same": true, "note": "n"},
        "mechanism": {"prior": "m1", "same": false, "note": "n"},
        "evaluation": {"prior": "e1", "same": false, "note": "n"},
        "target": {"prior": "t1", "same": true, "note": "n"}}}},
    {"ref": "S1#case#2", "urls": ["https://a"],
     "text": "{\"case\":\"  \",\"outcome\":\"O2\",\"prior\":{\"purpose\":\"p2\",\"mechanism\":\"m2\",\"evaluation\":\"e2\",\"target\":\"t2\"}}",
     "row": {"case": "  ", "url": "https://a", "outcome": "O2", "axes": {"purpose": {"prior": "p2", "same": true, "note": "n"}, "mechanism": {"prior": "m2", "same": false, "note": "n"}, "evaluation": {"prior": "e2", "same": false, "note": "n"}, "target": {"prior": "t2", "same": true, "note": "n"}}}},
    {"ref": "S1#case#3", "urls": ["https://a"],
     "text": "{\"case\":\"C3\",\"outcome\":\"O3\",\"prior\":{\"purpose\":\"  \",\"mechanism\":\"  \",\"evaluation\":\"  \",\"target\":\"  \"}}",
     "row": {"case": "C3", "url": "https://a", "outcome": "O3", "axes": {"purpose": {"prior": "  ", "same": true, "note": "n"}, "mechanism": {"prior": "  ", "same": false, "note": "n"}, "evaluation": {"prior": "  ", "same": false, "note": "n"}, "target": {"prior": "  ", "same": true, "note": "n"}}}},
    {"ref": "S2#issue#0", "urls": ["https://a"], "text": "claim B"},
    {"ref": "S2#issue#1", "urls": ["https://c"], "text": "  "}
  ],
  "groups": [
    {"url": "https://a", "subquestions": ["S1", "S2"], "claims": [
      {"ref": "S1#issue#0", "text": "claim A"},
      {"ref": "S1#case#0", "text": "{\"case\":\"C0\",\"outcome\":\"O0\",\"prior\":{\"purpose\":\"p0\",\"mechanism\":\"m0\",\"evaluation\":\"e0\",\"target\":\"t0\"}}"},
      {"ref": "S2#issue#0", "text": "claim B"}]},
    {"url": "https://b", "subquestions": ["S1"], "claims": [{"ref": "S1#issue#0", "text": "claim A"}]}
  ]
}
EOF
check "groupByUrl 출력이 기대 {items, groups}와 같다" "harn fn groupByUrl < \"\$FX/gu_in.json\" > \"\$FX/gu_got.json\" && json_same \"\$FX/gu_got.json\" \"\$FX/gu_want.json\""

echo "[통과 판정]"
cat > "$FX/cl_in.json" <<'EOF'
[
  [
    {"ref": "T#1", "urls": ["https://u1", "https://u2"], "text": "x"},
    {"ref": "T#2", "urls": ["https://u1"], "text": "x"},
    {"ref": "T#3", "urls": ["https://u1"], "text": "x"},
    {"ref": "T#4", "urls": [], "text": "x"},
    {"ref": "T#5", "urls": ["https://u1", "https://u3"], "text": "x"},
    {"ref": "T#6", "urls": ["https://u1", "https://u3"], "text": "x"},
    {"ref": "T#7", "urls": ["https://u4"], "text": "x"},
    {"ref": "T#8", "urls": ["https://u4"], "text": "x"},
    {"ref": "T#9", "urls": ["https://u5"], "text": "x"},
    {"ref": "T#10", "urls": ["https://u1"], "text": ""},
    {"ref": "T#11", "urls": ["https://u6"], "text": "x"},
    {"ref": "T#12", "urls": ["https://u1"], "text": "x", "row": {"case": "  ", "axes": {"purpose": {"prior": "p2", "same": true, "note": "n"}, "mechanism": {"prior": "m2", "same": false, "note": "n"}, "evaluation": {"prior": "e2", "same": false, "note": "n"}, "target": {"prior": "t2", "same": true, "note": "n"}}}}
  ],
  [
    {"url": "https://u1", "subquestions": ["T"], "output": {"url": "https://u1", "principles_applied": [], "judgments": [
      {"ref": "T#1", "verdict": "supported", "quote": "q", "reason": "r"},
      {"ref": "T#2", "verdict": "unsupported", "quote": "", "reason": "r"},
      {"ref": "T#3", "verdict": "unverifiable", "quote": "", "reason": "r"},
      {"ref": "T#5", "verdict": "unsupported", "quote": "", "reason": "r"},
      {"ref": "T#6", "verdict": "supported", "quote": "q", "reason": "r"}]}},
    {"url": "https://u2", "subquestions": ["T"], "output": {"url": "https://u2", "principles_applied": [], "judgments": [
      {"ref": "T#1", "verdict": "unsupported", "quote": "", "reason": "r"}]}},
    {"url": "https://u3", "subquestions": ["T"], "output": null},
    {"url": "https://u4", "subquestions": ["T"], "output": {"url": "https://u4", "principles_applied": [], "judgments": [
      {"ref": "T#8", "verdict": "supported", "quote": "q", "reason": "r"}]}},
    {"url": "https://u6", "subquestions": ["T"], "output": {"url": "https://wrong", "principles_applied": [], "judgments": [
      {"ref": "T#11", "verdict": "supported", "quote": "q", "reason": "r"},
      {"ref": "S9#issue#0", "verdict": "supported", "quote": "q", "reason": "r"}]}}
  ]
]
EOF
cat > "$FX/cl_want.json" <<'EOF'
{
  "passed": [
    {"ref": "T#1", "urls": ["https://u1", "https://u2"]},
    {"ref": "T#6", "urls": ["https://u1", "https://u3"]},
    {"ref": "T#11", "urls": ["https://u6"]}
  ],
  "rejected": [
    {"ref": "T#2", "urls": ["https://u1"]},
    {"ref": "T#4", "urls": []},
    {"ref": "T#10", "urls": ["https://u1"]},
    {"ref": "T#12", "urls": ["https://u1"]}
  ],
  "unverifiable": [{"ref": "T#3", "urls": ["https://u1"]}],
  "verify_failed": [
    {"url": "https://u3", "refs": ["T#5", "T#6"]},
    {"url": "https://u4", "refs": ["T#7", "T#8"]},
    {"url": "https://u5", "refs": ["T#9"]}
  ]
}
EOF
check "classify 출력이 기대값과 같다" "harn fn classify < \"\$FX/cl_in.json\" > \"\$FX/cl_got.json\" && json_same \"\$FX/cl_got.json\" \"\$FX/cl_want.json\""

echo "[상태 합치기]"
cat > "$FX/ms_in.json" <<'EOF'
[
  [
    {"id": "S1", "output": {"search_status": "ok", "queries": [], "issues": []}},
    {"id": "S2", "output": {"search_status": "ok", "queries": [], "issues": []}},
    {"id": "S3", "output": null},
    {"id": "S4", "output": {"search_status": "no-results", "queries": [], "issues": []}},
    {"id": "S10", "output": {"search_status": "ok", "queries": [], "issues": []}}
  ],
  [
    {"ref": "S1#issue#0", "urls": ["https://a"], "text": "x"},
    {"ref": "S1#issue#1", "urls": ["https://a"], "text": "x"},
    {"ref": "S1#case#0", "urls": [], "text": "x"},
    {"ref": "S10#issue#0", "urls": ["https://b"], "text": "x"}
  ],
  {
    "passed": [{"ref": "S1#issue#0", "urls": ["https://a"]}],
    "rejected": [], "unverifiable": [],
    "verify_failed": [
      {"url": "https://a", "refs": ["S1#issue#1"]},
      {"url": "https://b", "refs": ["S10#issue#0"]}]
  }
]
EOF
cat > "$FX/ms_want.json" <<'EOF'
{
  "coverage": [
    {"id": "S1", "cases_found": 3, "passed": 1},
    {"id": "S2", "cases_found": 0, "passed": 0},
    {"id": "S3", "cases_found": 0, "passed": 0},
    {"id": "S4", "cases_found": 0, "passed": 0},
    {"id": "S10", "cases_found": 1, "passed": 0}
  ],
  "subquestion_status": [
    {"id": "S1", "search_status": "ok", "verification_status": "partial"},
    {"id": "S2", "search_status": "ok", "verification_status": "ok"},
    {"id": "S3", "search_status": "failed", "verification_status": "ok"},
    {"id": "S4", "search_status": "no-results", "verification_status": "ok"},
    {"id": "S10", "search_status": "ok", "verification_status": "partial"}
  ],
  "overall_status": "not-ok"
}
EOF
check "mergeStatus 출력이 기대값과 같다" "harn fn mergeStatus < \"\$FX/ms_in.json\" > \"\$FX/ms_got.json\" && json_same \"\$FX/ms_got.json\" \"\$FX/ms_want.json\""
cat > "$FX/ms2_in.json" <<'EOF'
[
  [{"id": "S2", "output": {"search_status": "ok", "queries": [], "issues": []}}],
  [],
  {"passed": [], "rejected": [], "unverifiable": [], "verify_failed": []}
]
EOF
cat > "$FX/ms2_want.json" <<'EOF'
{
  "coverage": [{"id": "S2", "cases_found": 0, "passed": 0}],
  "subquestion_status": [{"id": "S2", "search_status": "ok", "verification_status": "ok"}],
  "overall_status": "ok"
}
EOF
check "mergeStatus 는 모두 ok 이면 overall_status 가 ok 다" "harn fn mergeStatus < \"\$FX/ms2_in.json\" > \"\$FX/ms2_got.json\" && json_same \"\$FX/ms2_got.json\" \"\$FX/ms2_want.json\""

cat > "$FX/ms3_in.json" <<'EOF'
[
  [{"id": "S4", "output": {"search_status": "no-results", "queries": [], "issues": []}}],
  [],
  {"passed": [], "rejected": [], "unverifiable": [], "verify_failed": []}
]
EOF
check "mergeStatus 는 no-results 만 있어도 overall_status 가 not-ok 다" "harn fn mergeStatus < \"\$FX/ms3_in.json\" > \"\$FX/ms3_got.json\" && json_true \"\$FX/ms3_got.json\" 'd[\"overall_status\"] == \"not-ok\"'"
cat > "$FX/ms4_in.json" <<'EOF'
[
  [{"id": "S1", "output": {"search_status": "ok", "queries": [], "issues": []}}],
  [{"ref": "S1#issue#0", "urls": ["https://a"], "text": "x"}],
  {"passed": [], "rejected": [], "unverifiable": [],
   "verify_failed": [{"url": "https://a", "refs": ["S1#issue#0"]}]}
]
EOF
check "mergeStatus 는 ok 하위 질문의 검증 실패만으로도 overall_status 가 not-ok 다" "harn fn mergeStatus < \"\$FX/ms4_in.json\" > \"\$FX/ms4_got.json\" && json_true \"\$FX/ms4_got.json\" 'd[\"overall_status\"] == \"not-ok\"'"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
