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
for S in RESEARCHER_SCHEMA EXTRACT_SCHEMA JUDGE_SCHEMA SYNTHESIS_SCHEMA MAP_SCHEMA; do
  check "$S 의 루트 type 이 object 다" "json_true \"\$FX/schemas.json\" 'd[\"$S\"][\"type\"] == \"object\"'"
done
check "모든 노드에서 required 가 properties 의 키에 든다" "schema_subset \"\$FX/schemas.json\""
# 추출 판정과 카테고리 판정의 열거 값이다. 판정 칸은 세 카테고리가 같은 열거를 쓴다.
E_EX_ENUM='(lambda p: p["access"]["enum"] == ["성공", "실패"] and p["exists"]["enum"] == ["일치", "불일치"])(d["EXTRACT_SCHEMA"]["properties"]["judgments"]["items"]["properties"])'
check "EXTRACT_SCHEMA 의 access·exists 열거가 정해진 값이다" "json_true \"\$FX/schemas.json\" \"\$E_EX_ENUM\""
# 판정 칸의 네 값과 판정 불가 이유 유형은 계약 코드 enums 가 원본이다.
E_JU_ENUM='(lambda p: all(p[k]["enum"] == C["enums"]["match"] for k in ("numbers_conditions", "direction", "scope")) and set(p["unsure_reasons"]["properties"]) == {"numbers_conditions", "direction", "scope"} and all(v["enum"] == C["enums"]["unsure"] for v in p["unsure_reasons"]["properties"].values()) and set(p["missing"]["properties"]) == {"numbers_conditions", "direction", "scope"} and all(v["type"] == "string" for v in p["missing"]["properties"].values()))(d["JUDGE_SCHEMA"]["properties"]["judgments"]["items"]["properties"])'
check "JUDGE_SCHEMA 의 판정 칸과 이유 유형 열거와 missing 칸이 정해진 값이다" "json_true \"\$FX/schemas.json\" \"\$E_JU_ENUM\""
check "EXTRACT_SCHEMA 의 판정이 exists_note 를 요구한다" "json_true \"\$FX/schemas.json\" '\"exists_note\" in d[\"EXTRACT_SCHEMA\"][\"properties\"][\"judgments\"][\"items\"][\"required\"]'"
check "RESEARCHER_SCHEMA 의 search_status 열거가 정해진 값이다" "json_true \"\$FX/schemas.json\" 'd[\"RESEARCHER_SCHEMA\"][\"properties\"][\"search_status\"][\"enum\"] == [\"ok\",\"no-results\",\"failed\",\"not-attempted\"]'"
check "RESEARCHER_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"RESEARCHER_SCHEMA\"][\"required\"]) == {\"search_status\",\"queries\",\"issues\"}'"
check "EXTRACT_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"EXTRACT_SCHEMA\"][\"required\"]) == {\"url\",\"judgments\",\"principles_applied\"}'"
check "JUDGE_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"JUDGE_SCHEMA\"][\"required\"]) == {\"judgments\",\"principles_applied\"}'"
check "VERIFIER_SCHEMA 가 없다" "json_true \"\$FX/schemas.json\" '\"VERIFIER_SCHEMA\" not in d'"
check "SYNTHESIS_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"SYNTHESIS_SCHEMA\"][\"required\"]) == {\"evidence_map\",\"conclusions\",\"principles_applied\"}'"
check "MAP_SCHEMA 루트 required 가 표와 같다" "json_true \"\$FX/schemas.json\" 'set(d[\"MAP_SCHEMA\"][\"required\"]) == {\"cells\",\"principles_applied\"}'"

echo "[시험 도구 자체]"
check "알 수 없는 함수 이름은 종료 코드 2 다" "printf '[]' | harn fn nosuch >/dev/null 2>&1; [ \$? -eq 2 ]"
check "깨진 JSON 입력의 run 은 종료 코드 2 다" "printf '{broken' | harn run >/dev/null 2>&1; [ \$? -eq 2 ]"
cat > "$FX/miss_in.json" <<'EOF'
{"args": {"question": "Q?", "situation": "S", "target": "T", "mode": "contrast", "round": 1,
  "subquestions": [{"id": "S1", "scope": "a", "include": [], "exclude": []}, {"id": "S2", "scope": "b", "include": [], "exclude": []}],
  "forbidden_terms": [], "researcher_count": 2, "researcher_count_basis": "x", "principles_path": "D:/x/agent-principles.md"},
 "responses": {"research:S1": {"search_status": "ok", "queries": [], "issues": []}}}
EOF
check "응답표에 없는 label 을 부르면 종료 코드 1 이고 표준 오류에 그 label 이 있다" "harn run < \"\$FX/miss_in.json\" > /dev/null 2> \"\$FX/miss_err.txt\"; [ \$? -eq 1 ] && grep -qF 'research:S2' \"\$FX/miss_err.txt\""

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
      "Claude Code \"/deep-research\" skill",
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
    {"ref": "T#13", "urls": ["https://u1", "https://u2"], "text": "x"},
    {"ref": "T#14", "urls": ["https://u1", "https://u3"], "text": "x"},
    {"ref": "T#11", "urls": ["https://u6"], "text": "x"},
    {"ref": "T#12", "urls": ["https://u1"], "text": "x", "row": {"case": "  ", "axes": {"purpose": {"prior": "p2", "same": true, "note": "n"}, "mechanism": {"prior": "m2", "same": false, "note": "n"}, "evaluation": {"prior": "e2", "same": false, "note": "n"}, "target": {"prior": "t2", "same": true, "note": "n"}}}}
  ],
  [
    {"url": "https://u1", "subquestions": ["T"], "output": {"url": "https://u1", "principles_applied": [], "judgments": [
      {"ref": "T#1", "verdict": "supported", "quote": "q", "reason": "r"},
      {"ref": "T#2", "verdict": "unsupported", "quote": "", "reason": "r"},
      {"ref": "T#3", "verdict": "unverifiable", "quote": "", "reason": "r"},
      {"ref": "T#5", "verdict": "unsupported", "quote": "", "reason": "r"},
      {"ref": "T#6", "verdict": "supported", "quote": "q", "reason": "r"},
      {"ref": "T#13", "verdict": "unverifiable", "quote": "", "reason": "r"},
      {"ref": "T#14", "verdict": "unverifiable", "quote": "", "reason": "r"}]}},
    {"url": "https://u2", "subquestions": ["T"], "output": {"url": "https://u2", "principles_applied": [], "judgments": [
      {"ref": "T#1", "verdict": "unsupported", "quote": "", "reason": "r"},
      {"ref": "T#13", "verdict": "unsupported", "quote": "", "reason": "r"}]}},
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
    {"ref": "T#13", "urls": ["https://u1", "https://u2"]},
    {"ref": "T#12", "urls": ["https://u1"]}
  ],
  "unverifiable": [{"ref": "T#3", "urls": ["https://u1"]}],
  "verify_failed": [
    {"url": "https://u3", "refs": ["T#5", "T#6", "T#14"]},
    {"url": "https://u4", "refs": ["T#7", "T#8"]},
    {"url": "https://u5", "refs": ["T#9"]}
  ]
}
EOF
check "classify 출력이 기대값과 같다" "harn fn classify < \"\$FX/cl_in.json\" > \"\$FX/cl_got.json\" && json_same \"\$FX/cl_got.json\" \"\$FX/cl_want.json\""
# 주장 단위 검증 실패다. X#3 은 다른 URL 에서 supported 라 통과하고, 실패한 URL 의 참조 목록에는 남는다.
cat > "$FX/cl2_in.json" <<'EOF'
[
  [
    {"ref": "X#1", "urls": ["https://v1"], "text": "x"},
    {"ref": "X#2", "urls": ["https://v1"], "text": "x"},
    {"ref": "X#3", "urls": ["https://v1", "https://v2"], "text": "x"},
    {"ref": "X#4", "urls": ["https://v1"], "text": "x"},
    {"ref": "X#5", "urls": ["https://v1"], "text": "x"}
  ],
  [
    {"url": "https://v1", "subquestions": ["X"], "output": {"url": "https://v1", "principles_applied": [], "judgments": [
      {"ref": "X#1", "verdict": "supported", "quote": "q", "reason": "r"},
      {"ref": "X#2", "verdict": "verify_failed", "quote": "q", "reason": "r"},
      {"ref": "X#3", "verdict": "verify_failed", "quote": "q", "reason": "r"},
      {"ref": "X#4", "verdict": "unsupported", "quote": "", "reason": "r"},
      {"ref": "X#5", "verdict": "unverifiable", "quote": "", "reason": "r"}]}},
    {"url": "https://v2", "subquestions": ["X"], "output": {"url": "https://v2", "principles_applied": [], "judgments": [
      {"ref": "X#3", "verdict": "supported", "quote": "q", "reason": "r"}]}}
  ]
]
EOF
cat > "$FX/cl2_want.json" <<'EOF'
{
  "passed": [{"ref": "X#1", "urls": ["https://v1"]}, {"ref": "X#3", "urls": ["https://v1", "https://v2"]}],
  "rejected": [{"ref": "X#4", "urls": ["https://v1"]}],
  "unverifiable": [{"ref": "X#5", "urls": ["https://v1"]}],
  "verify_failed": [{"url": "https://v1", "refs": ["X#2", "X#3"]}]
}
EOF
check "주장 단위 verify_failed 는 그 주장만 뺀다" "harn fn classify < \"\$FX/cl2_in.json\" > \"\$FX/cl2_got.json\" && json_same \"\$FX/cl2_got.json\" \"\$FX/cl2_want.json\""

echo "[단계 합치기]"
# URL 마다 한 상황을 둔다. 인자는 refsByUrl, extract, judge, refetch, rejudge 차례다. judge 는 판정 묶음 출력을 splitByUrl 로 나눈 값이다.
# 이 묶음에는 정보 부족이 없으므로 보충과 재판정은 빈 객체다. 보충·재판정 상황은 아래 mg2 묶음이 다룬다.
# u5 는 quote 가 없어 판정에 가지 않으므로 judge 에 키가 없다. u9 는 판정 묶음이 실패해 judge 값이 null 이다.
# u11 은 판정 출력에서 주장 하나(M#14)가 빠졌다.
cat > "$FX/mg_in.json" <<'EOF'
[
  {"https://u1": ["M#1"], "https://u2": ["M#2", "M#3"], "https://u3": ["M#4"], "https://u4": ["M#5"],
   "https://u5": ["M#6"], "https://u6": ["M#7"], "https://u7": ["M#8"], "https://u8": ["M#9"],
   "https://u9": ["M#10"], "https://u10": ["M#11", "M#12"], "https://u11": ["M#13", "M#14"]},
  {
    "https://u1": null,
    "https://u2": {"url": "https://u2", "principles_applied": [], "judgments": [
      {"ref": "M#2", "access": "성공", "exists": "일치", "quote": "q2", "context": "", "reason": "e2"}]},
    "https://u3": {"url": "https://u3", "principles_applied": [], "judgments": [
      {"ref": "M#4", "access": "실패", "exists": "불일치", "quote": "", "context": "", "reason": "403"}]},
    "https://u4": {"url": "https://u4", "principles_applied": [], "judgments": [
      {"ref": "M#5", "access": "성공", "exists": "불일치", "quote": "q5", "context": "", "reason": "e5"}]},
    "https://u5": {"url": "https://u5", "principles_applied": [], "judgments": [
      {"ref": "M#6", "access": "성공", "exists": "일치", "quote": "", "context": "", "reason": "e6"}]},
    "https://u6": {"url": "https://u6", "principles_applied": [], "judgments": [
      {"ref": "M#7", "access": "성공", "exists": "일치", "quote": "q7", "context": "", "reason": "e7"}]},
    "https://u7": {"url": "https://u7", "principles_applied": [], "judgments": [
      {"ref": "M#8", "access": "성공", "exists": "일치", "quote": "q8", "context": "", "reason": "e8"}]},
    "https://u8": {"url": "https://u8", "principles_applied": ["NO-ASSUME"], "judgments": [
      {"ref": "M#9", "access": "성공", "exists": "일치", "quote": "q9", "context": "c9", "reason": "e9"}]},
    "https://u9": {"url": "https://u9", "principles_applied": [], "judgments": [
      {"ref": "M#10", "access": "성공", "exists": "일치", "quote": "q10", "context": "", "reason": "e10"}]},
    "https://u10": {"url": "https://u10", "principles_applied": [], "judgments": [
      {"ref": "M#11", "access": "성공", "exists": "일치", "quote": "q11", "context": "", "reason": "e11"},
      {"ref": "M#12", "access": "성공", "exists": "일치", "quote": "q12", "context": "", "reason": "e12"}]},
    "https://u11": {"url": "https://u11", "principles_applied": [], "judgments": [
      {"ref": "M#13", "access": "성공", "exists": "일치", "quote": "q13", "context": "", "reason": "e13"},
      {"ref": "M#14", "access": "성공", "exists": "일치", "quote": "q14", "context": "", "reason": "e14"}]}
  },
  {
    "https://u6": {"principles_applied": [], "judgments": [
      {"ref": "M#7", "numbers_conditions": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "j7"}]},
    "https://u7": {"principles_applied": [], "judgments": [
      {"ref": "M#8", "numbers_conditions": "일치", "direction": "불일치", "scope": "일치", "unsure_reasons": {}, "reason": "j8"}]},
    "https://u8": {"principles_applied": ["NO-ASSUME", "EVIDENCE-FIRST"], "judgments": [
      {"ref": "M#9", "numbers_conditions": "일치", "direction": "판정 불가", "scope": "일치", "unsure_reasons": {"direction": "조건 얽힘"}, "reason": "j9"}]},
    "https://u9": null,
    "https://u10": {"principles_applied": [], "judgments": [
      {"ref": "M#11", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "j11"},
      {"ref": "M#12", "numbers_conditions": "일치", "direction": "일치", "scope": "판정 불가", "unsure_reasons": {"scope": "언어 해석"}, "reason": "j12"}]},
    "https://u11": {"principles_applied": [], "judgments": [
      {"ref": "M#13", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "j13"}]}
  },
  {},
  {}
]
EOF
check "mergeStages 출력을 얻는다" "harn fn mergeStages < \"\$FX/mg_in.json\" > \"\$FX/mg_got.json\""
# v(url, ref) 는 그 URL 의 합친 출력에서 그 ref 의 verdict 다.
PY_V='(lambda v: '
PY_V_TAIL=')(lambda u, r: [j["verdict"] for j in d["outputs"]["https://" + u]["judgments"] if j["ref"] == r][0])'
check "추출 출력이 없으면 URL 검증 실패다" "json_true \"\$FX/mg_got.json\" 'd[\"outputs\"][\"https://u1\"] is None and d[\"outputs\"][\"https://u2\"] is None'"
check "access 실패는 unverifiable 이다" "json_true \"\$FX/mg_got.json\" '${PY_V}v(\"u3\", \"M#4\") == \"unverifiable\"${PY_V_TAIL}'"
check "exists 불일치는 unsupported 다" "json_true \"\$FX/mg_got.json\" '${PY_V}v(\"u4\", \"M#5\") == \"unsupported\"${PY_V_TAIL}'"
check "quote 없는 주장은 판정에 보내지 않는다: 합친 판정이 unsupported 다" "json_true \"\$FX/mg_got.json\" '${PY_V}v(\"u5\", \"M#6\") == \"unsupported\"${PY_V_TAIL}'"
check "카테고리 칸 누락은 URL 검증 실패다" "json_true \"\$FX/mg_got.json\" 'd[\"outputs\"][\"https://u6\"] is None'"
check "불일치가 하나라도 있으면 unsupported 다" "json_true \"\$FX/mg_got.json\" '${PY_V}v(\"u7\", \"M#8\") == \"unsupported\"${PY_V_TAIL}'"
check "판정 불가는 기각이고 이유가 남는다(합치기)" "json_true \"\$FX/mg_got.json\" '${PY_V}v(\"u8\", \"M#9\") == \"unsupported\" and \"조건 얽힘\" in d[\"outputs\"][\"https://u8\"][\"judgments\"][0][\"reason\"]${PY_V_TAIL}'"
check "실패한 판정 묶음의 URL 은 검증 실패다(합치기)" "json_true \"\$FX/mg_got.json\" 'd[\"outputs\"][\"https://u9\"] is None'"
check "판정 불가 주장은 기각이고 같은 URL 의 다른 주장은 남는다" "json_true \"\$FX/mg_got.json\" '${PY_V}v(\"u10\", \"M#11\") == \"supported\" and v(\"u10\", \"M#12\") == \"unsupported\"${PY_V_TAIL}'"
check "판정 출력에서 빠진 주장만 검증 실패다(합치기)" "json_true \"\$FX/mg_got.json\" '${PY_V}v(\"u11\", \"M#13\") == \"supported\" and v(\"u11\", \"M#14\") == \"verify_failed\"${PY_V_TAIL}'"
E_MG_SHAPE='(lambda o: set(o) == {"url", "judgments", "principles_applied"} and o["url"] == "https://u8" and o["judgments"][0]["quote"] == "q9" and set(o["judgments"][0]) == {"ref", "verdict", "quote", "reason"} and o["principles_applied"] == ["NO-ASSUME", "EVIDENCE-FIRST"])(d["outputs"]["https://u8"])'
check "합친 출력이 인용 판정 형식이고 quote 는 추출 값이며 principles_applied 는 단계의 합집합이다" "json_true \"\$FX/mg_got.json\" '$E_MG_SHAPE'"
E_MG_REASON='all(s in d["outputs"]["https://u8"]["judgments"][0]["reason"] for s in ("e9", "j9", "조건 얽힘"))'
check "합친 reason 이 단계별 이유를 모두 포함한다" "json_true \"\$FX/mg_got.json\" '$E_MG_REASON'"
E_MG_STAGES='list(d["stages"]) == list(d["outputs"]) and all(set(s) == {"extract", "judge", "refetch", "rejudge"} for s in d["stages"].values()) and all(s["refetch"] is None and s["rejudge"] is None for s in d["stages"].values()) and d["stages"]["https://u8"]["judge"]["judgments"][0]["reason"] == "j9" and d["stages"]["https://u9"]["judge"] is None and d["stages"]["https://u5"]["judge"] is None and d["stages"]["https://u1"]["extract"] is None'
check "stages 가 URL 마다 네 단계 원본을 보존하고 실행하지 않은 단계는 null 이다" "json_true \"\$FX/mg_got.json\" '$E_MG_STAGES'"
# 보충·재판정 차례의 묶음이다. URL 마다 한 상황을 둔다. 보충 구절은 r<번호>, 처음 구절은 q<번호> 다.
# n1 보충 뒤 재판정 일치, n2 재판정의 불일치, n3 처음 판정의 불일치와 정보 부족, n4 보충 무응답, n5 보충 access 실패,
# n6 재판정 묶음 실패, n7 재판정 정보 부족, n8 재판정 판정 불가, n9 처음 판정의 판정 불가, n10 보충 exists 불일치다.
cat > "$FX/mg2_in.json" <<'EOF'
[
  {
   "https://n1": ["N#1"],
   "https://n2": ["N#2"],
   "https://n3": ["N#3"],
   "https://n4": ["N#4", "N#5"],
   "https://n5": ["N#6", "N#7"],
   "https://n6": ["N#8", "N#9"],
   "https://n7": ["N#10", "N#11"],
   "https://n8": ["N#12"],
   "https://n9": ["N#13", "N#14"],
   "https://n10": ["N#15", "N#16"]
  },
  {
   "https://n1": {"url": "https://n1", "principles_applied": [], "judgments": [{"ref": "N#1", "access": "성공", "exists": "일치", "quote": "q1", "context": "", "reason": "e"}]},
   "https://n2": {"url": "https://n2", "principles_applied": [], "judgments": [{"ref": "N#2", "access": "성공", "exists": "일치", "quote": "q2", "context": "", "reason": "e"}]},
   "https://n3": {"url": "https://n3", "principles_applied": [], "judgments": [{"ref": "N#3", "access": "성공", "exists": "일치", "quote": "q3", "context": "", "reason": "e"}]},
   "https://n4": {"url": "https://n4", "principles_applied": [], "judgments": [{"ref": "N#4", "access": "성공", "exists": "일치", "quote": "q4", "context": "", "reason": "e"}, {"ref": "N#5", "access": "성공", "exists": "일치", "quote": "q5", "context": "", "reason": "e"}]},
   "https://n5": {"url": "https://n5", "principles_applied": [], "judgments": [{"ref": "N#6", "access": "성공", "exists": "일치", "quote": "q6", "context": "", "reason": "e"}, {"ref": "N#7", "access": "성공", "exists": "일치", "quote": "q7", "context": "", "reason": "e"}]},
   "https://n6": {"url": "https://n6", "principles_applied": [], "judgments": [{"ref": "N#8", "access": "성공", "exists": "일치", "quote": "q8", "context": "", "reason": "e"}, {"ref": "N#9", "access": "성공", "exists": "일치", "quote": "q9", "context": "", "reason": "e"}]},
   "https://n7": {"url": "https://n7", "principles_applied": [], "judgments": [{"ref": "N#10", "access": "성공", "exists": "일치", "quote": "q10", "context": "", "reason": "e"}, {"ref": "N#11", "access": "성공", "exists": "일치", "quote": "q11", "context": "", "reason": "e"}]},
   "https://n8": {"url": "https://n8", "principles_applied": [], "judgments": [{"ref": "N#12", "access": "성공", "exists": "일치", "quote": "q12", "context": "", "reason": "e"}]},
   "https://n9": {"url": "https://n9", "principles_applied": [], "judgments": [{"ref": "N#13", "access": "성공", "exists": "일치", "quote": "q13", "context": "", "reason": "e"}, {"ref": "N#14", "access": "성공", "exists": "일치", "quote": "q14", "context": "", "reason": "e"}]},
   "https://n10": {"url": "https://n10", "principles_applied": [], "judgments": [{"ref": "N#15", "access": "성공", "exists": "일치", "quote": "q15", "context": "", "reason": "e"}, {"ref": "N#16", "access": "성공", "exists": "일치", "quote": "q16", "context": "", "reason": "e"}]}
  },
  {
   "https://n1": {"principles_applied": [], "judgments": [{"ref": "N#1", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n2": {"principles_applied": [], "judgments": [{"ref": "N#2", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n3": {"principles_applied": [], "judgments": [{"ref": "N#3", "numbers_conditions": "정보 부족", "direction": "불일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n4": {"principles_applied": [], "judgments": [{"ref": "N#4", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}, {"ref": "N#5", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n5": {"principles_applied": [], "judgments": [{"ref": "N#6", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}, {"ref": "N#7", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n6": {"principles_applied": [], "judgments": [{"ref": "N#8", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}, {"ref": "N#9", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n7": {"principles_applied": [], "judgments": [{"ref": "N#10", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}, {"ref": "N#11", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n8": {"principles_applied": [], "judgments": [{"ref": "N#12", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n9": {"principles_applied": [], "judgments": [{"ref": "N#13", "numbers_conditions": "일치", "direction": "판정 불가", "scope": "일치", "missing": {}, "unsure_reasons": {"direction": "조건 얽힘"}, "reason": "j"}, {"ref": "N#14", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n10": {"principles_applied": [], "judgments": [{"ref": "N#15", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}, {"ref": "N#16", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]}
  },
  {
   "https://n1": {"url": "https://n1", "principles_applied": [], "judgments": [{"ref": "N#1", "access": "성공", "exists": "일치", "quote": "r1", "context": "", "reason": "rf1"}]},
   "https://n2": {"url": "https://n2", "principles_applied": [], "judgments": [{"ref": "N#2", "access": "성공", "exists": "일치", "quote": "r2", "context": "", "reason": "e"}]},
   "https://n3": {"url": "https://n3", "principles_applied": [], "judgments": [{"ref": "N#3", "access": "성공", "exists": "일치", "quote": "r3", "context": "", "reason": "e"}]},
   "https://n4": null,
   "https://n5": {"url": "https://n5", "principles_applied": [], "judgments": [{"ref": "N#6", "access": "실패", "exists": "일치", "quote": "r6", "context": "", "reason": "e"}]},
   "https://n6": {"url": "https://n6", "principles_applied": [], "judgments": [{"ref": "N#8", "access": "성공", "exists": "일치", "quote": "r8", "context": "", "reason": "e"}]},
   "https://n7": {"url": "https://n7", "principles_applied": [], "judgments": [{"ref": "N#10", "access": "성공", "exists": "일치", "quote": "r10", "context": "", "reason": "e"}]},
   "https://n8": {"url": "https://n8", "principles_applied": [], "judgments": [{"ref": "N#12", "access": "성공", "exists": "일치", "quote": "r12", "context": "", "reason": "e"}]},
   "https://n10": {"url": "https://n10", "principles_applied": [], "judgments": [{"ref": "N#15", "access": "성공", "exists": "불일치", "quote": "r15", "context": "", "reason": "e"}]}
  },
  {
   "https://n1": {"principles_applied": [], "judgments": [{"ref": "N#1", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "rj1"}]},
   "https://n2": {"principles_applied": [], "judgments": [{"ref": "N#2", "numbers_conditions": "일치", "direction": "불일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n3": {"principles_applied": [], "judgments": [{"ref": "N#3", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n6": null,
   "https://n7": {"principles_applied": [], "judgments": [{"ref": "N#10", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "j"}]},
   "https://n8": {"principles_applied": [], "judgments": [{"ref": "N#12", "numbers_conditions": "일치", "direction": "일치", "scope": "판정 불가", "missing": {}, "unsure_reasons": {"scope": "언어 해석"}, "reason": "j"}]}
  }
]
EOF
check "보충 묶음의 mergeStages 출력을 얻는다" "harn fn mergeStages < \"\$FX/mg2_in.json\" > \"\$FX/mg2_got.json\""
PY_V2='(lambda v: '
PY_V2_TAIL=')(lambda u, r: [j for j in d["outputs"]["https://" + u]["judgments"] if j["ref"] == r][0])'
v2() { json_true "$FX/mg2_got.json" "${PY_V2}$1${PY_V2_TAIL}"; }
check "보충 뒤 재판정이 일치면 supported 다" "v2 'v(\"n1\", \"N#1\")[\"verdict\"] == \"supported\"'"
check "합친 출력의 quote 는 보충 구절이다" "v2 'v(\"n1\", \"N#1\")[\"quote\"] == \"r1\" and all(s in v(\"n1\", \"N#1\")[\"reason\"] for s in (\"rf1\", \"rj1\"))'"
check "재판정은 그 주장의 칸을 모두 대체한다" "v2 'v(\"n2\", \"N#2\")[\"verdict\"] == \"unsupported\"'"
check "처음 판정에 불일치가 있으면 보충 결과와 무관하게 unsupported 다" "v2 'v(\"n3\", \"N#3\")[\"verdict\"] == \"unsupported\" and v(\"n3\", \"N#3\")[\"quote\"] == \"q3\"'"
check "보충 실패는 그 주장만 검증 실패다" "v2 'v(\"n4\", \"N#4\")[\"verdict\"] == \"verify_failed\" and v(\"n4\", \"N#5\")[\"verdict\"] == \"supported\"'"
check "보충 출력의 access 실패는 그 주장만 검증 실패다" "v2 'v(\"n5\", \"N#6\")[\"verdict\"] == \"verify_failed\" and v(\"n5\", \"N#7\")[\"verdict\"] == \"supported\"'"
check "보충 출력의 exists 불일치는 그 주장만 검증 실패다" "v2 'v(\"n10\", \"N#15\")[\"verdict\"] == \"verify_failed\" and v(\"n10\", \"N#16\")[\"verdict\"] == \"supported\"'"
check "재판정 실패는 그 주장만 검증 실패다" "v2 'v(\"n6\", \"N#8\")[\"verdict\"] == \"verify_failed\" and v(\"n6\", \"N#9\")[\"verdict\"] == \"supported\"'"
check "재판정도 정보 부족이면 그 주장만 검증 실패다(합치기)" "v2 'v(\"n7\", \"N#10\")[\"verdict\"] == \"verify_failed\" and v(\"n7\", \"N#11\")[\"verdict\"] == \"supported\"'"
check "재판정의 판정 불가도 기각이고 이유가 남는다" "v2 'v(\"n8\", \"N#12\")[\"verdict\"] == \"unsupported\" and v(\"n8\", \"N#12\")[\"quote\"] == \"r12\" and \"언어 해석\" in v(\"n8\", \"N#12\")[\"reason\"]'"
check "처음 판정의 판정 불가는 보충 없이 기각이다" "v2 'v(\"n9\", \"N#13\")[\"verdict\"] == \"unsupported\" and \"조건 얽힘\" in v(\"n9\", \"N#13\")[\"reason\"] and v(\"n9\", \"N#14\")[\"verdict\"] == \"supported\"'"
E_MG2_STG='d["stages"]["https://n1"]["refetch"]["judgments"][0]["quote"] == "r1" and d["stages"]["https://n1"]["rejudge"]["judgments"][0]["reason"] == "rj1" and d["stages"]["https://n4"]["refetch"] is None and d["stages"]["https://n9"]["rejudge"] is None'
check "stages 가 보충과 재판정 원본을 보존한다" "json_true \"\$FX/mg2_got.json\" '$E_MG2_STG'"

echo "[판정 묶음]"
# mkclaims <파일> <URL=개수 ...> — URL 마다 주장 n 개를 둔 claimsByUrl 과 묶음 크기 20 을 batchClaims 인자로 쓴다.
mkclaims() {
  local out="$1"; shift
  json_run '
import json, sys
by = {}
for spec in sys.argv[2:]:
    url, n = spec.rsplit("=", 1)
    by[url] = [{"ref": url + "#" + str(i), "text": "t"} for i in range(int(n))]
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump([by, 20], f)
' "$out" "$@"
}
# 묶음마다 (URL, 주장 수) 목록으로 줄여 본다. 주장은 입력 차례 그대로여야 한다.
E_BC_KEEP='all(it["claims"] == [{"ref": it["url"] + "#" + str(i), "text": "t"} for i in range(len(it["claims"]))] for b in d for it in b["items"]) and all(set(b) == {"items"} and set(it) == {"url", "claims"} for b in d for it in b["items"])'
bc_shape() { json_true "$1" "[[(it[\"url\"], len(it[\"claims\"])) for it in b[\"items\"]] for b in d] == $2 and $E_BC_KEEP"; }
mkclaims "$FX/bc1_in.json" https://u1=10 https://u2=8 https://u3=7
check "묶음은 주장 20개 이하이고 URL 을 나누지 않는다" "harn fn batchClaims < \"\$FX/bc1_in.json\" > \"\$FX/bc1_got.json\" && bc_shape \"\$FX/bc1_got.json\" '[[(\"https://u1\", 10), (\"https://u2\", 8)], [(\"https://u3\", 7)]]'"
mkclaims "$FX/bc2_in.json" https://u1=3 https://u2=22 https://u3=2
check "20개를 넘는 URL 은 홀로 묶음이 된다" "harn fn batchClaims < \"\$FX/bc2_in.json\" > \"\$FX/bc2_got.json\" && bc_shape \"\$FX/bc2_got.json\" '[[(\"https://u1\", 3)], [(\"https://u2\", 22)], [(\"https://u3\", 2)]]'"
mkclaims "$FX/bc3_in.json" https://u1=0 https://u2=2 https://u3=0
mkclaims "$FX/bc4_in.json"
check "주장 없는 URL 은 묶음에 넣지 않는다" "harn fn batchClaims < \"\$FX/bc3_in.json\" > \"\$FX/bc3_got.json\" && bc_shape \"\$FX/bc3_got.json\" '[[(\"https://u2\", 2)]]' && harn fn batchClaims < \"\$FX/bc4_in.json\" > \"\$FX/bc4_got.json\" && json_true \"\$FX/bc4_got.json\" 'd == []'"
# 묶음 출력 나누기. 첫 묶음 출력에는 입력에 없던 ref(rX), 입력에 없던 URL(z), 다른 URL 의 ref(b 의 r1)가 섞여 있다.
# 둘째 묶음은 응답이 없고, 셋째 묶음은 judgments 가 배열이 아니다.
cat > "$FX/sp_in.json" <<'EOF'
[
  [{"principles_applied": ["P"], "judgments": [
     {"url": "https://a", "ref": "r1", "reason": "a1"},
     {"url": "https://a", "ref": "rX", "reason": "x"},
     {"url": "https://z", "ref": "r1", "reason": "x"},
     {"url": "https://b", "ref": "r1", "reason": "x"},
     {"ref": "r2", "reason": "x"},
     {"url": "https://b", "ref": "r2", "reason": "b2"}]},
   null,
   {"principles_applied": [], "judgments": "x"}],
  [{"items": [{"url": "https://a", "claims": [{"ref": "r1"}]}, {"url": "https://b", "claims": [{"ref": "r2"}]}]},
   {"items": [{"url": "https://c", "claims": [{"ref": "r3"}]}]},
   {"items": [{"url": "https://e", "claims": [{"ref": "r4"}]}]}]
]
EOF
cat > "$FX/sp_want.json" <<'EOF'
{"https://a": {"judgments": [{"url": "https://a", "ref": "r1", "reason": "a1"}], "principles_applied": ["P"]},
 "https://b": {"judgments": [{"url": "https://b", "ref": "r2", "reason": "b2"}], "principles_applied": ["P"]},
 "https://c": null,
 "https://e": null}
EOF
check "입력에 없던 판정은 쓰지 않는다" "harn fn splitByUrl < \"\$FX/sp_in.json\" > \"\$FX/sp_got.json\" && json_same \"\$FX/sp_got.json\" \"\$FX/sp_want.json\""

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

# 실행 흐름 묶음이 공유하는 입력 조각이다. 응답표만 시험마다 다르다.
cat > "$FX/args_c.json" <<'EOF'
{"question": "Q?", "situation": "Sit", "target": "Tgt", "mode": "contrast", "round": 1,
 "subquestions": [{"id": "S1", "scope": "a", "include": ["i"], "exclude": []}, {"id": "S2", "scope": "b", "include": [], "exclude": ["e"]}],
 "forbidden_terms": ["Acme"], "researcher_count": 2, "researcher_count_basis": "x", "principles_path": "D:/x/agent-principles.md"}
EOF
cat > "$FX/row.json" <<'EOF'
{"case": "C0", "url": "https://a", "outcome": "O0", "axes": {
  "purpose": {"prior": "p0", "same": true, "note": "n"}, "mechanism": {"prior": "m0", "same": false, "note": "n"},
  "evaluation": {"prior": "e0", "same": false, "note": "n"}, "target": {"prior": "t0", "same": true, "note": "n"}}}
EOF
# mkin <응답표 파일> <출력 파일> — 응답표 파일의 "@mode" 값을 args 의 mode 로 쓰고 "@ROW@" 문자열을 row.json 의 값으로 바꿔 run 입력을 만든다.
mkin() {
  json_run '
import json, sys
def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)
resp, row, args = load(sys.argv[1]), load(sys.argv[2]), load(sys.argv[3])
args["mode"] = resp.pop("@mode")
def sub(v):
    if v == "@ROW@":
        return row
    if isinstance(v, list):
        return [sub(x) for x in v]
    if isinstance(v, dict):
        return {k: sub(x) for k, x in v.items()}
    return v
with open(sys.argv[4], "w", encoding="utf-8") as f:
    json.dump({"args": args, "responses": sub(resp["responses"])}, f, ensure_ascii=False)
' "$1" "$FX/row.json" "$FX/args_c.json" "$2"
}
# 종합 프롬프트의 기대 row 는 고정 파일에서 읽는다. 한 줄로 줄여 파이썬 식에 넣는다.
PYQ="'"
ROW_LINE="$(tr -d '\n' < "$FX/row.json")"
# 프롬프트를 줄로 나눠 형식을 확인하고 JSON 블록을 읽는 파이썬 식 조각이다. json_true 가 eval 을 쓰므로 식 하나여야 한다.
# call(라벨)은 그 라벨의 호출 목록이고, block(호출, 모드)은 줄 형식이 맞을 때만 셋째 줄 이후의 JSON 값이며 틀리면 None 이다.
PY_CALL='lambda l: [c for c in d["calls"] if c["label"] == l]'
PY_BLOCK='lambda c, mode: (lambda ls: json.loads("\n".join(ls[3:-1])) if (ls[0] == "MODE: " + mode and ls[1] == "PRINCIPLES: D:/x/agent-principles.md" and ls[2] == "```json" and ls[-1] == "```") else None)(c["prompt"].split("\n"))'
PY_WRAP_HEAD='(lambda call, block: '
PY_WRAP_TAIL=")($PY_CALL, $PY_BLOCK)"

echo "[실행 흐름: contrast]"
cat > "$FX/rc_resp.json" <<'EOF'
{"@mode": "contrast", "responses": {
  "research:S1": {"search_status": "ok", "queries": ["Acme agent", "prior art"], "issues": [{"prior_claim": "claim A", "citations": [{"url": "https://a"}]}]},
  "research:S2": {"search_status": "ok", "queries": ["x"], "issues": [{"prior_claim": "claim B", "citations": [{"url": "https://a"}, {"url": "https://b"}]}]},
  "extract:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"},
    {"ref": "S2#issue#0", "access": "성공", "exists": "일치", "quote": "q", "context": "c", "reason": "r"}]},
  "judge:1": {"principles_applied": [], "judgments": [
    {"url": "https://a", "ref": "S1#issue#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "r"},
    {"url": "https://a", "ref": "S2#issue#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "r"}]},
  "extract:https://b": {"url": "https://b", "principles_applied": [], "judgments": [
    {"ref": "S2#issue#0", "access": "성공", "exists": "일치", "quote": "", "context": "", "reason": "r"}]}}}
EOF
check "contrast 실행이 끝나고 출력을 얻는다" "mkin \"\$FX/rc_resp.json\" \"\$FX/rc_in.json\" && harn run < \"\$FX/rc_in.json\" > \"\$FX/rc_out.json\""
E_RC_RES='len([c for c in d["calls"] if c["label"].startswith("research:")]) == 2 and all(c["agentType"] == "disciplined-coder:prior-art-researcher" and c["phase"] == "Research" for c in d["calls"] if c["label"].startswith("research:"))'
check "연구자 호출의 agentType 과 phase 가 정해진 값이다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_RES\""
# 검증 단계의 label 접두사마다 호출 label 목록과 agentType 을 본다.
E_RC_VER='(lambda by: by("extract:") == (["extract:https://a", "extract:https://b"], {"disciplined-coder:prior-art-verifier"}) and by("judge:") == (["judge:1"], {"disciplined-coder:prior-art-judge"}))(lambda p: ([c["label"] for c in d["calls"] if c["label"].startswith(p)], {c["agentType"] for c in d["calls"] if c["label"].startswith(p)})) and all(c["phase"] == "Verify" for c in d["calls"] if c["label"].split(":")[0] in ("extract", "judge")) and d["result"]["verifier_count"] == 2'
check "검증 단계 호출의 agentType 과 phase 가 정해진 값이고 verifier_count 가 URL 수와 같다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_VER\""
E_RC_EXP="$PY_WRAP_HEAD"'all(
  (lambda b, sq: set(b) == {"question", "situation", "target", "mode", "subquestion", "forbidden_terms"}
    and b["question"] == "Q?" and b["situation"] == "Sit" and b["target"] == "Tgt" and b["mode"] == "contrast"
    and b["forbidden_terms"] == ["Acme"] and b["subquestion"] == sq)(block(call("research:" + sq["id"])[0], "explore"), sq)
  for sq in [{"id": "S1", "scope": "a", "include": ["i"], "exclude": []}, {"id": "S2", "scope": "b", "include": [], "exclude": ["e"]}])'"$PY_WRAP_TAIL"
check "탐색 프롬프트의 줄 형식과 JSON 블록이 정해진 대로다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_EXP\""
E_RC_EXT="$PY_WRAP_HEAD"'(lambda b, b2: set(b) == {"url", "claims"} and b["url"] == "https://a" and [x["ref"] for x in b["claims"]] == ["S1#issue#0", "S2#issue#0"] and all(set(x) == {"ref", "text"} for x in b["claims"]) and set(b2) == {"url", "claims"})(block(call("extract:https://a")[0], "extract"), block(call("extract:https://b")[0], "extract"))'"$PY_WRAP_TAIL"
check "추출 프롬프트가 MODE: extract 와 { url, claims } 블록이다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_EXT\""
E_RC_JUD="$PY_WRAP_HEAD"'(lambda b: set(b) == set(C["judge_input"]) and [it["url"] for it in b["items"]] == ["https://a"] and set(b["items"][0]) == set(C["judge_input"]["items"][0]) and [x["ref"] for x in b["items"][0]["claims"]] == ["S1#issue#0", "S2#issue#0"] and all(set(x) == set(C["judge_input"]["items"][0]["claims"][0]) for x in b["items"][0]["claims"]) and b["items"][0]["claims"][1]["quote"] == "q" and b["items"][0]["claims"][1]["context"] == "c" and b["items"][0]["claims"][1]["text"] == "claim B")(block(call("judge:1")[0], "judge"))'"$PY_WRAP_TAIL"
check "판정 프롬프트가 MODE: judge 와 추출 quote·context·source_note 를 붙인 { items: [{ url, claims }] } 블록이다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_JUD\""
E_RC_NOQ="$PY_WRAP_HEAD"'all(it["url"] != "https://b" for c in d["calls"] if c["label"].startswith("judge:") for it in block(c, "judge")["items"]) and d["result"]["verifiers"][1]["output"]["judgments"][0]["verdict"] == "unsupported"'"$PY_WRAP_TAIL"
check "quote 없는 주장은 판정에 보내지 않는다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_NOQ\""
E_RC_STG='all(set(v) == set(C["result"]["verifiers"][0]) and set(v["stages"]) == set(C["result"]["verifiers"][0]["stages"]) for v in d["result"]["verifiers"]) and [j["ref"] for j in d["result"]["verifiers"][0]["stages"]["judge"]["judgments"]] == ["S1#issue#0", "S2#issue#0"] and d["result"]["verifiers"][1]["stages"]["judge"] is None'
check "verifiers 원소가 계약 코드의 키와 stages 를 보유하고 stages 의 judge 는 그 URL 의 판정만 포함한다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_STG\""
E_RC_NOSYN='not any(c["label"] in ("synthesize", "map-check") for c in d["calls"])'
check "contrast 에서 synthesize 와 map-check 호출이 없다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_NOSYN\""
E_RC_NOOPT='all("model" not in c and "effort" not in c for c in d["calls"])'
check "어느 호출에도 model 과 effort 가 없다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_NOOPT\""
E_RC_KEYS='list(d["result"].keys()) == [k for k in C["result"] if not k.startswith("?")]'
check "반환값의 키 차례가 계약 코드 result 에서 ? 키를 뺀 것과 같다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_KEYS\""
check "round 가 args.round 와 같다" "json_true \"\$FX/rc_out.json\" 'd[\"result\"][\"round\"] == 1'"
E_RC_VIOL='d["result"]["query_violations"] == [{"id": "S1", "query": "Acme agent", "rule": "forbidden-term"}]'
check "금지어가 든 검색어가 query_violations 에 든다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_VIOL\""
E_RC_PASS='d["result"]["passed"] == [{"ref": "S1#issue#0", "urls": ["https://a"]}, {"ref": "S2#issue#0", "urls": ["https://a", "https://b"]}] and d["result"]["rejected"] == [] and d["result"]["overall_status"] == "ok" and d["result"]["verify_failed"] == []'
check "통과 판정과 overall_status 가 검증 판정을 따른다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_PASS\""
E_RC_LISTS='[r["id"] for r in d["result"]["researchers"]] == ["S1", "S2"] and [(v["url"], v["subquestions"]) for v in d["result"]["verifiers"]] == [("https://a", ["S1", "S2"]), ("https://b", ["S2"])] and d["result"]["verifiers"][1]["output"]["url"] == "https://b"'
check "researchers 와 verifiers 가 하위 질문 차례와 URL 묶음 차례의 원소다" "json_true \"\$FX/rc_out.json\" \"\$E_RC_LISTS\""

echo "[실행 흐름: survey]"
cat > "$FX/rs_resp.json" <<'EOF'
{"@mode": "survey", "responses": {
  "research:S1": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "claim A", "citations": [{"url": "https://a"}]}], "evidence_map": ["@ROW@"]},
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "claim B", "citations": [{"url": "https://b"}]}]},
  "extract:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"}, {"ref": "S1#case#0", "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"}]},
  "judge:1": {"principles_applied": [], "judgments": [
    {"url": "https://a", "ref": "S1#issue#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "r"}, {"url": "https://a", "ref": "S1#case#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "r"}]},
  "extract:https://b": {"url": "https://b", "principles_applied": [], "judgments": [
    {"ref": "S2#issue#0", "access": "성공", "exists": "불일치", "quote": "q", "context": "", "reason": "r"}]},
  "synthesize": {"evidence_map": ["@ROW@"], "conclusions": [{"text": "c", "refs": ["S1#case#0"]}], "principles_applied": []},
  "map-check": {"cells": [], "principles_applied": []}}}
EOF
check "survey 실행이 끝나고 출력을 얻는다" "mkin \"\$FX/rs_resp.json\" \"\$FX/rs_in.json\" && harn run < \"\$FX/rs_in.json\" > \"\$FX/rs_out.json\""
E_RS_SYN="$PY_WRAP_HEAD"'(lambda cs, b, rows: len(cs) == 1 and cs[0]["phase"] == "Synthesize" and cs[0]["agentType"] == "disciplined-coder:prior-art-researcher" and set(b) == {"question", "target", "passed_rows"} and b["question"] == "Q?" and b["target"] == "Tgt" and b["passed_rows"] == rows)(call("synthesize"), block(call("synthesize")[0], "synthesize"), [{"ref": "S1#case#0", "row": json.loads('"$PYQ$ROW_LINE$PYQ"')}])'"$PY_WRAP_TAIL"
check "종합 호출이 하나이고 프롬프트의 passed_rows 가 통과한 근거 지도 행과 같다" "json_true \"\$FX/rs_out.json\" \"\$E_RS_SYN\""
E_RS_MAP="$PY_WRAP_HEAD"'(lambda cm, b, syn: len(cm) == 1 and cm[0]["phase"] == "MapCheck" and cm[0]["agentType"] == "disciplined-coder:prior-art-mapcheck" and set(b) == {"evidence_map", "passed"} and b["evidence_map"] == d["result"]["synthesis"]["evidence_map"] and b["passed"] == syn["passed_rows"])(call("map-check"), block(call("map-check")[0], "map"), block(call("synthesize")[0], "synthesize"))'"$PY_WRAP_TAIL"
check "지도 대조 호출이 하나이고 블록이 { evidence_map, passed } 다" "json_true \"\$FX/rs_out.json\" \"\$E_RS_MAP\""
E_RS_CNT='d["result"]["verifier_count"] == 2 and len(d["result"]["verifiers"]) == 2'
check "verifier_count 가 지도 대조 검증자를 세지 않는다" "json_true \"\$FX/rs_out.json\" \"\$E_RS_CNT\""
E_RS_JUD='[c["label"] for c in d["calls"] if c["label"].startswith("judge:")] == ["judge:1"]'
check "판정 묶음이 하나면 판정을 한 번 부른다" "json_true \"\$FX/rs_out.json\" \"\$E_RS_JUD\""
E_RS_NORF='not any(c["label"].split(":")[0] in ("refetch", "rejudge") for c in d["calls"]) and all(v["stages"]["refetch"] is None and v["stages"]["rejudge"] is None for v in d["result"]["verifiers"])'
check "정보 부족이 없으면 보충을 부르지 않는다" "json_true \"\$FX/rs_out.json\" \"\$E_RS_NORF\""
E_RS_KEYS='list(d["result"].keys()) == [k.lstrip("?") for k in C["result"]] and d["result"]["synthesis"]["conclusions"][0]["refs"] == ["S1#case#0"] and d["result"]["map_check"] == {"cells": [], "principles_applied": []}'
check "survey 반환값에 synthesis 와 map_check 가 뒤따른다" "json_true \"\$FX/rs_out.json\" \"\$E_RS_KEYS\""
# 통과 행이 없는 응답표다. 판정이 모두 unsupported 다.
cat > "$FX/rn_resp.json" <<'EOF'
{"@mode": "survey", "responses": {
  "research:S1": {"search_status": "ok", "queries": ["q"], "issues": [], "evidence_map": ["@ROW@"]},
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": []},
  "extract:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#case#0", "access": "성공", "exists": "일치", "quote": "", "context": "", "reason": "r"}]}}}
EOF
E_RN='not any(c["label"] in ("synthesize", "map-check") for c in d["calls"]) and d["result"]["synthesis"] is None and d["result"]["map_check"] is None'
check "통과 행이 없으면 종합과 지도 대조를 부르지 않고 두 키가 null 이다" "mkin \"\$FX/rn_resp.json\" \"\$FX/rn_in.json\" && harn run < \"\$FX/rn_in.json\" > \"\$FX/rn_out.json\" && json_true \"\$FX/rn_out.json\" \"\$E_RN\""
# 종합 응답이 null 인 응답표다.
cat > "$FX/rz_resp.json" <<'EOF'
{"@mode": "survey", "responses": {
  "research:S1": {"search_status": "ok", "queries": ["q"], "issues": [], "evidence_map": ["@ROW@"]},
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": []},
  "extract:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#case#0", "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"}]},
  "judge:1": {"principles_applied": [], "judgments": [
    {"url": "https://a", "ref": "S1#case#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "r"}]},
  "synthesize": null}}
EOF
E_RZ='len([c for c in d["calls"] if c["label"] == "synthesize"]) == 1 and not any(c["label"] == "map-check" for c in d["calls"]) and d["result"]["synthesis"] is None and d["result"]["map_check"] is None'
check "종합 응답이 null 이면 지도 대조를 부르지 않고 map_check 가 null 이다" "mkin \"\$FX/rz_resp.json\" \"\$FX/rz_in.json\" && harn run < \"\$FX/rz_in.json\" > \"\$FX/rz_out.json\" && json_true \"\$FX/rz_out.json\" \"\$E_RZ\""

echo "[실행 흐름: 보충과 재판정]"
# 주장은 A(S1#issue#0, a), C(S1#issue#1, c), F(S1#issue#2, e), G(S1#issue#3, e), B(S2#issue#0, a), D(S2#issue#1, d), E(S2#issue#2, d) 다.
# A 는 정보 부족으로 보충·재판정을 거쳐 판정 불가가 남는다. C 는 불일치와 정보 부족이 함께 있다. D 는 보충이 응답하지 않는다.
# F 는 재판정에도 정보 부족이다. 주장이 일곱이므로 판정과 재판정은 묶음 하나다.
cat > "$FX/rr_resp.json" <<'EOF'
{"@mode": "contrast", "responses": {
  "research:S1": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "claim A", "citations": [{"url": "https://a"}]}, {"prior_claim": "claim C", "citations": [{"url": "https://c"}]}, {"prior_claim": "claim F", "citations": [{"url": "https://e"}]}, {"prior_claim": "claim G", "citations": [{"url": "https://e"}]}]},
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "claim B", "citations": [{"url": "https://a"}]}, {"prior_claim": "claim D", "citations": [{"url": "https://d"}]}, {"prior_claim": "claim E", "citations": [{"url": "https://d"}]}]},
  "extract:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "N-A", "quote": "qa", "context": "ca", "reason": "RSECRET"},
    {"ref": "S2#issue#0", "access": "성공", "exists": "일치", "quote": "qb", "context": "", "reason": "RSECRET"}]},
  "extract:https://c": {"url": "https://c", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#1", "access": "성공", "exists": "일치", "exists_note": "N-C", "quote": "qc", "context": "", "reason": "r"}]},
  "extract:https://e": {"url": "https://e", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#2", "access": "성공", "exists": "일치", "exists_note": "N-F", "quote": "qf", "context": "", "reason": "r"},
    {"ref": "S1#issue#3", "access": "성공", "exists": "일치", "exists_note": "N-G", "quote": "qg", "context": "", "reason": "r"}]},
  "extract:https://d": {"url": "https://d", "principles_applied": [], "judgments": [
    {"ref": "S2#issue#1", "access": "성공", "exists": "일치", "exists_note": "N-D", "quote": "qd", "context": "", "reason": "r"},
    {"ref": "S2#issue#2", "access": "성공", "exists": "일치", "exists_note": "N-E", "quote": "qe", "context": "", "reason": "r"}]},
  "judge:1": {"principles_applied": [], "judgments": [
    {"url": "https://a", "ref": "S1#issue#0", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "r"},
    {"url": "https://a", "ref": "S2#issue#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"},
    {"url": "https://c", "ref": "S1#issue#1", "numbers_conditions": "정보 부족", "direction": "불일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "r"},
    {"url": "https://e", "ref": "S1#issue#2", "numbers_conditions": "일치", "direction": "정보 부족", "scope": "일치", "missing": {"direction": "결론 문장"}, "unsure_reasons": {}, "reason": "r"},
    {"url": "https://e", "ref": "S1#issue#3", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"},
    {"url": "https://d", "ref": "S2#issue#1", "numbers_conditions": "일치", "direction": "정보 부족", "scope": "일치", "missing": {"direction": "결론 문장"}, "unsure_reasons": {}, "reason": "r"},
    {"url": "https://d", "ref": "S2#issue#2", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"}]},
  "refetch:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "N2", "quote": "q2", "context": "c2", "reason": "RSECRET2"}]},
  "refetch:https://e": {"url": "https://e", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#2", "access": "성공", "exists": "일치", "exists_note": "N-F2", "quote": "qf2", "context": "", "reason": "r"}]},
  "refetch:https://d": null,
  "rejudge:1": {"principles_applied": [], "judgments": [
    {"url": "https://a", "ref": "S1#issue#0", "numbers_conditions": "일치", "direction": "일치", "scope": "판정 불가", "missing": {}, "unsure_reasons": {"scope": "언어 해석"}, "reason": "r"},
    {"url": "https://e", "ref": "S1#issue#2", "numbers_conditions": "일치", "direction": "정보 부족", "scope": "일치", "missing": {"direction": "결론 문장"}, "unsure_reasons": {}, "reason": "r"}]}}}
EOF
check "보충이 섞인 실행이 끝나고 출력을 얻는다" "mkin \"\$FX/rr_resp.json\" \"\$FX/rr_in.json\" && harn run < \"\$FX/rr_in.json\" > \"\$FX/rr_out.json\""
# item(호출, url) 은 그 호출 블록의 items 에서 그 URL 의 원소다.
PY_ITEM='lambda b, u: [it for it in b["items"] if it["url"] == u][0]'
E_RR_SRC="$PY_WRAP_HEAD"'(lambda item: (lambda b: [x["source_note"] for x in item(b, "https://a")["claims"]] == ["N-A", ""] and all("reason" not in x for it in b["items"] for x in it["claims"]) and "RSECRET" not in json.dumps(b, ensure_ascii=False))(block(call("judge:1")[0], "judge")))('"$PY_ITEM"')'"$PY_WRAP_TAIL"
check "판정 입력에 source_note 가 있다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_SRC\""
E_RR_NONOTE="$PY_WRAP_HEAD"'[it for it in block(call("judge:1")[0], "judge")["items"] if it["url"] == "https://a"][0]["claims"][1]["source_note"] == ""'"$PY_WRAP_TAIL"
check "exists_note 없는 추출은 빈 source_note 다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_NONOTE\""
E_RR_RF="$PY_WRAP_HEAD"'(lambda rf: call("refetch:https://a")[0]["agentType"] == "disciplined-coder:prior-art-verifier" and all(c["phase"] == "Verify" for c in d["calls"] if c["label"].split(":")[0] in ("refetch", "rejudge")) and rf == {"url": "https://a", "claims": [{"ref": "S1#issue#0", "text": "claim A", "missing": {"numbers_conditions": "세션 수"}}]} and set(rf) == set(C["refetch"]) and set(rf["claims"][0]) == set(C["refetch"]["claims"][0]))(block(call("refetch:https://a")[0], "refetch"))'"$PY_WRAP_TAIL"
check "정보 부족은 보충으로 보낸다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_RF\""
E_RR_RJ="$PY_WRAP_HEAD"'[c["label"] for c in d["calls"] if c["label"].startswith("rejudge:")] == ["rejudge:1"] and [c["agentType"] for c in call("rejudge:1")] == ["disciplined-coder:prior-art-judge"] and block(call("rejudge:1")[0], "judge") == {"items": [{"url": "https://a", "claims": [{"ref": "S1#issue#0", "text": "claim A", "quote": "q2", "context": "c2", "source_note": "N2"}]}, {"url": "https://e", "claims": [{"ref": "S1#issue#2", "text": "claim F", "quote": "qf2", "context": "", "source_note": "N-F2"}]}]}'"$PY_WRAP_TAIL"
check "재판정은 보충한 주장만 묶어 부른다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_RJ\""
E_RR_MIS='not any(c["label"] == "refetch:https://c" for c in d["calls"]) and {"ref": "S1#issue#1", "urls": ["https://c"]} in d["result"]["rejected"] and [j["verdict"] for j in d["result"]["verifiers"][1]["output"]["judgments"]] == ["unsupported"]'
check "불일치가 있으면 보충하지 않는다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_MIS\""
E_RR_FAIL='{"url": "https://d", "refs": ["S2#issue#1"]} in d["result"]["verify_failed"] and {"ref": "S2#issue#2", "urls": ["https://d"]} in d["result"]["passed"]'
check "보충이 응답하지 않으면 그 주장만 검증 실패다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_FAIL\""
E_RR_UNS='(lambda j: j["verdict"] == "unsupported" and "언어 해석" in j["reason"])([j for j in d["result"]["verifiers"][0]["output"]["judgments"] if j["ref"] == "S1#issue#0"][0]) and {"ref": "S1#issue#0", "urls": ["https://a"]} in d["result"]["rejected"]'
check "판정 불가는 기각이고 이유가 남는다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_UNS\""
E_RR_NI='{"url": "https://e", "refs": ["S1#issue#2"]} in d["result"]["verify_failed"] and {"ref": "S1#issue#3", "urls": ["https://e"]} in d["result"]["passed"]'
check "재판정도 정보 부족이면 그 주장만 검증 실패다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_NI\""
E_RR_NOESC='not any(c["label"].startswith("escalate:") for c in d["calls"]) and all(c["agentType"] != "disciplined-coder:prior-art-judge-escalation" for c in d["calls"])'
check "상향 호출이 없다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_NOESC\""
E_RR_Q='(lambda o: [(j["ref"], j["verdict"], j["quote"]) for j in o["judgments"]] == [("S1#issue#0", "unsupported", "q2"), ("S2#issue#0", "supported", "qb")])(d["result"]["verifiers"][0]["output"])'
check "합친 출력의 quote 는 보충 구절이다(실행 흐름)" "json_true \"\$FX/rr_out.json\" \"\$E_RR_Q\""
E_RR_ORDER='(lambda ls: ls == sorted(ls, key=["research", "extract", "judge", "refetch", "rejudge"].index))([c["label"].split(":")[0] for c in d["calls"]])'
check "검증 단계가 추출, 판정, 보충, 재판정 차례로 실행된다" "json_true \"\$FX/rr_out.json\" \"\$E_RR_ORDER\""
# 보충이 모두 실패한 응답표다. 재판정할 주장이 없다.
cat > "$FX/rq_resp.json" <<'EOF'
{"@mode": "contrast", "responses": {
  "research:S1": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "claim D", "citations": [{"url": "https://d"}]}]},
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": []},
  "extract:https://d": {"url": "https://d", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "N-D", "quote": "qd", "context": "", "reason": "r"}]},
  "judge:1": {"principles_applied": [], "judgments": [
    {"url": "https://d", "ref": "S1#issue#0", "numbers_conditions": "일치", "direction": "정보 부족", "scope": "일치", "missing": {"direction": "결론 문장"}, "unsure_reasons": {}, "reason": "r"}]},
  "refetch:https://d": null}}
EOF
E_RQ='not any(c["label"].startswith("rejudge:") for c in d["calls"]) and d["result"]["verify_failed"] == [{"url": "https://d", "refs": ["S1#issue#0"]}] and d["result"]["verifiers"][0]["stages"]["rejudge"] is None'
check "보충이 없으면 재판정을 부르지 않는다" "mkin \"\$FX/rq_resp.json\" \"\$FX/rq_in.json\" && harn run < \"\$FX/rq_in.json\" > \"\$FX/rq_out.json\" && json_true \"\$FX/rq_out.json\" \"\$E_RQ\""
# 재판정 묶음이 응답하지 않는 응답표다. A1 만 보충했다.
cat > "$FX/rj_resp.json" <<'EOF'
{"@mode": "contrast", "responses": {
  "research:S1": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "claim A1", "citations": [{"url": "https://a"}]}, {"prior_claim": "claim A2", "citations": [{"url": "https://a"}]}]},
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": []},
  "extract:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "N", "quote": "q1", "context": "", "reason": "r"},
    {"ref": "S1#issue#1", "access": "성공", "exists": "일치", "exists_note": "N", "quote": "q2", "context": "", "reason": "r"}]},
  "judge:1": {"principles_applied": [], "judgments": [
    {"url": "https://a", "ref": "S1#issue#0", "numbers_conditions": "정보 부족", "direction": "일치", "scope": "일치", "missing": {"numbers_conditions": "세션 수"}, "unsure_reasons": {}, "reason": "r"},
    {"url": "https://a", "ref": "S1#issue#1", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"}]},
  "refetch:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S1#issue#0", "access": "성공", "exists": "일치", "exists_note": "N", "quote": "r1", "context": "", "reason": "r"}]},
  "rejudge:1": null}}
EOF
E_RJ='d["result"]["verify_failed"] == [{"url": "https://a", "refs": ["S1#issue#0"]}] and d["result"]["passed"] == [{"ref": "S1#issue#1", "urls": ["https://a"]}]'
check "실패한 재판정 묶음은 보충 주장만 검증 실패다" "mkin \"\$FX/rj_resp.json\" \"\$FX/rj_in.json\" && harn run < \"\$FX/rj_in.json\" > \"\$FX/rj_out.json\" && json_true \"\$FX/rj_out.json\" \"\$E_RJ\""

echo "[실행 흐름: 판정 묶음]"
# mkbig <응답표 파일> <판정 묶음 1 처리> — S1 이 https://a 에 주장 15개, S2 가 https://b 에 주장 10개를 인용한다.
# 합이 20을 넘으므로 판정 묶음은 a 와 b 의 둘이다. 처리가 null 이면 judge:1 이 응답하지 않는다.
# 처리가 gap 이면 judge:1 출력에서 S1#issue#3 이 빠지고, 입력에 없던 URL 과 다른 URL 의 ref 판정이 섞인다.
mkbig() {
  json_run '
import json, sys
out, mode = sys.argv[1], sys.argv[2]
ok = lambda u, r: {"url": u, "ref": r, "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "missing": {}, "unsure_reasons": {}, "reason": "r"}
bad = lambda u, r: dict(ok(u, r), direction="불일치")
ex = lambda u, refs: {"url": u, "principles_applied": [], "judgments": [{"ref": r, "access": "성공", "exists": "일치", "exists_note": "N", "quote": "q", "context": "", "reason": "r"} for r in refs]}
ra = ["S1#issue#%d" % i for i in range(15)]
rb = ["S2#issue#%d" % i for i in range(10)]
j1 = {"principles_applied": [], "judgments": [ok("https://a", r) for r in ra]}
if mode == "gap":
    j1["judgments"] = [j for j in j1["judgments"] if j["ref"] != "S1#issue#3"] + [bad("https://a", "S2#issue#0"), bad("https://zz", "S1#issue#3"), bad("https://a", "S9#issue#0")]
resp = {
  "research:S1": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "a%d" % i, "citations": [{"url": "https://a"}]} for i in range(15)]},
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "b%d" % i, "citations": [{"url": "https://b"}]} for i in range(10)]},
  "extract:https://a": ex("https://a", ra),
  "extract:https://b": ex("https://b", rb),
  "judge:1": None if mode == "null" else j1,
  "judge:2": {"principles_applied": [], "judgments": [ok("https://b", r) for r in rb]},
}
with open(out, "w", encoding="utf-8") as f:
    json.dump({"@mode": "contrast", "responses": resp}, f, ensure_ascii=False)
' "$1" "$2"
}
mkbig "$FX/rb_resp.json" gap
check "묶음 둘인 실행이 끝나고 출력을 얻는다" "mkin \"\$FX/rb_resp.json\" \"\$FX/rb_in.json\" && harn run < \"\$FX/rb_in.json\" > \"\$FX/rb_out.json\""
E_RB_CALLS="$PY_WRAP_HEAD"'[c["label"] for c in d["calls"] if c["label"].startswith("judge:")] == ["judge:1", "judge:2"] and [[it["url"] for it in block(call(l)[0], "judge")["items"]] for l in ("judge:1", "judge:2")] == [["https://a"], ["https://b"]] and all(c["agentType"] == "disciplined-coder:prior-art-judge" and c["phase"] == "Verify" for c in d["calls"] if c["label"].startswith("judge:"))'"$PY_WRAP_TAIL"
check "판정은 묶음마다 한 번 부른다" "json_true \"\$FX/rb_out.json\" \"\$E_RB_CALLS\""
E_RB_GAP='d["result"]["verify_failed"] == [{"url": "https://a", "refs": ["S1#issue#3"]}] and len(d["result"]["passed"]) == 24 and {"ref": "S1#issue#3", "urls": ["https://a"]} not in d["result"]["passed"]'
check "빠진 주장만 검증 실패다" "json_true \"\$FX/rb_out.json\" \"\$E_RB_GAP\""
E_RB_FOREIGN='{"ref": "S2#issue#0", "urls": ["https://b"]} in d["result"]["passed"] and [j["ref"] for j in d["result"]["verifiers"][0]["stages"]["judge"]["judgments"]] == ["S1#issue#%d" % i for i in range(15) if i != 3] and all(j["url"] == "https://a" for j in d["result"]["verifiers"][0]["stages"]["judge"]["judgments"])'
check "입력에 없던 판정은 쓰지 않는다(실행 흐름)" "json_true \"\$FX/rb_out.json\" \"\$E_RB_FOREIGN\""
mkbig "$FX/rb0_resp.json" null
E_RB_NULL='d["result"]["verify_failed"] == [{"url": "https://a", "refs": ["S1#issue#%d" % i for i in range(15)]}] and d["result"]["passed"] == [{"ref": "S2#issue#%d" % i, "urls": ["https://b"]} for i in range(10)] and d["result"]["verifiers"][0]["output"] is None and d["result"]["verifiers"][0]["stages"]["judge"] is None'
check "실패한 판정 묶음의 URL 만 검증 실패다" "mkin \"\$FX/rb0_resp.json\" \"\$FX/rb0_in.json\" && harn run < \"\$FX/rb0_in.json\" > \"\$FX/rb0_out.json\" && json_true \"\$FX/rb0_out.json\" \"\$E_RB_NULL\""

echo "[실패 행선지]"
cat > "$FX/rf_resp.json" <<'EOF'
{"@mode": "contrast", "responses": {
  "research:S1": null,
  "research:S2": {"search_status": "ok", "queries": ["q"], "issues": [{"prior_claim": "claim B", "citations": [{"url": "https://a"}, {"url": "https://b"}]}], "evidence_map": [{"case": "C1", "url": "https://b", "outcome": "O", "axes": {
    "purpose": {"prior": "p", "same": true, "note": "n"}, "mechanism": {"prior": "m", "same": true, "note": "n"},
    "evaluation": {"prior": "e", "same": true, "note": "n"}, "target": {"prior": "t", "same": true, "note": "n"}}}]},
  "extract:https://a": {"url": "https://a", "principles_applied": [], "judgments": [
    {"ref": "S2#issue#0", "access": "성공", "exists": "일치", "quote": "q", "context": "", "reason": "r"}]},
  "judge:1": {"principles_applied": [], "judgments": [
    {"url": "https://a", "ref": "S2#issue#0", "numbers_conditions": "일치", "direction": "일치", "scope": "일치", "unsure_reasons": {}, "reason": "r"}]},
  "extract:https://b": null}}
EOF
check "실패가 섞인 실행이 끝나고 출력을 얻는다" "mkin \"\$FX/rf_resp.json\" \"\$FX/rf_in.json\" && harn run < \"\$FX/rf_in.json\" > \"\$FX/rf_out.json\""
E_RF1='d["result"]["verify_failed"] == [{"url": "https://b", "refs": ["S2#issue#0", "S2#case#0"]}]'
check "추출 출력이 null 인 URL 이 verify_failed 에 그 묶음의 참조 전부와 함께 든다" "json_true \"\$FX/rf_out.json\" \"\$E_RF1\""
E_RF2='[s for s in d["result"]["subquestion_status"] if s["id"] == "S2"][0]["verification_status"] == "partial" and d["result"]["overall_status"] == "not-ok"'
check "그 URL 을 인용한 하위 질문이 partial 이고 overall_status 가 not-ok 다" "json_true \"\$FX/rf_out.json\" \"\$E_RF2\""
E_RF3='d["result"]["verifier_count"] == 2 and d["result"]["verifiers"][1]["output"] is None'
check "verifier_count 가 null 인 검증자를 센다" "json_true \"\$FX/rf_out.json\" \"\$E_RF3\""
E_RF4='d["result"]["researchers"][0] == {"id": "S1", "output": None} and d["result"]["subquestion_status"][0]["search_status"] == "failed"'
check "연구자가 null 인 하위 질문은 failed 이고 researchers 에 output null 로 남는다" "json_true \"\$FX/rf_out.json\" \"\$E_RF4\""

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
