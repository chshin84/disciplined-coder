#!/usr/bin/env bash
# 선행연구 에이전트의 계약 코드(scripts/prior_art_contract.json)를 워크플로의 스키마 상수와
# 에이전트 정의의 출력 예시에 대조한다. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACT="$HERE/scripts/prior_art_contract.json"
FX="$(mktemp -d)"; trap 'rm -rf "$FX"' EXIT
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"

# contract_check <자료 이름> <스키마 파일|-> <예시 파일|->
# 계약 코드의 그 자료가 요구하는 키가 스키마와 예시에 있는지 본다. 빠진 키마다 schema:<경로> 또는
# example:<경로> 한 줄을 낸다. 0=빠진 키 없음, 1=있음, 2=대조 불능(error:<사유>).
contract_check() {
  json_run '
import json, sys
name, schema_f, example_f, contract_f = sys.argv[1:5]

def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)

def opt(k):
    return k[1:] if k.startswith("?") else k

def descendants(spec, prefix):
    # 요구 키 아래의 모든 경로를 늘어놓는다.
    out = []
    for k, v in spec.items():
        p = prefix + opt(k)
        out.append(p)
        if isinstance(v, dict):
            out += descendants(v, p + ".")
        elif isinstance(v, list):
            out += descendants(v[0], p + "[].")
    return out

def below(v):
    # 값이 객체나 배열이면 그 아래 경로 접두사와 하위 요구를 돌려준다.
    if isinstance(v, dict):
        return ".", v
    if isinstance(v, list):
        return "[].", v[0]
    return None, None

def walk_schema(spec, node, prefix, miss):
    props = node.get("properties", {}) if isinstance(node, dict) else {}
    req = node.get("required", []) if isinstance(node, dict) else []
    for k, v in spec.items():
        key, optional = opt(k), k.startswith("?")
        p = prefix + key
        if key not in props or (not optional and key not in req):
            miss.append("schema:" + p)
            sep, sub = below(v)
            if sub is not None:
                miss += ["schema:" + p + sep + d for d in descendants(sub, "")]
            continue
        child = props[key]
        if isinstance(v, dict):
            walk_schema(v, child, p + ".", miss)
        elif isinstance(v, list):
            items = child.get("items") if isinstance(child, dict) else None
            if not isinstance(items, dict) or "properties" not in items:
                miss += ["schema:" + p + "[]." + d for d in descendants(v[0], "")]
            else:
                walk_schema(v[0], items, p + "[].", miss)

def walk_example(spec, node, prefix, miss):
    for k, v in spec.items():
        key, optional = opt(k), k.startswith("?")
        p = prefix + key
        if not isinstance(node, dict) or key not in node:
            if not optional:
                miss.append("example:" + p)
            continue
        child = node[key]
        if isinstance(v, dict):
            walk_example(v, child, p + ".", miss)
        elif isinstance(v, list):
            if not isinstance(child, list) or not child:
                miss += ["example:" + p + "[]." + d for d in descendants(v[0], "")]
            else:
                for el in child:
                    walk_example(v[0], el, p + "[].", miss)

try:
    spec = load(contract_f).get(name)
    if not isinstance(spec, dict) or not spec:
        print("error:no-spec"); sys.exit(2)
    miss = []
    if schema_f != "-":
        walk_schema(spec, load(schema_f), "", miss)
    if example_f != "-":
        walk_example(spec, load(example_f), "", miss)
except (OSError, ValueError) as e:
    print("error:" + type(e).__name__); sys.exit(2)
for m in dict.fromkeys(miss):
    print(m)
sys.exit(1 if miss else 0)
' "$1" "$2" "$3" "$CONTRACT"
}

# extract_block <자료 이름> <정의 파일>
# `<!-- output: <자료 이름> -->` 다음의 json 코드 울타리 블록을 꺼내 JSON 으로 출력한다.
extract_block() {
  json_run '
import json, sys
name, path = sys.argv[1:3]
try:
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()
except OSError:
    print("error:no-marker"); sys.exit(1)
marker = "<!-- output: " + name + " -->"
idx = [i for i, l in enumerate(lines) if l.strip() == marker]
if not idx:
    print("error:no-marker"); sys.exit(1)
i = idx[0] + 1
while i < len(lines) and not lines[i].startswith("```json"):
    if lines[i].startswith("<!-- output:"):
        i = len(lines)
    else:
        i += 1
if i >= len(lines):
    print("error:no-block"); sys.exit(1)
body = []
i += 1
while i < len(lines) and not lines[i].startswith("```"):
    body.append(lines[i]); i += 1
if i >= len(lines):
    print("error:no-block"); sys.exit(1)
try:
    print(json.dumps(json.loads("\n".join(body)), ensure_ascii=False))
except ValueError:
    print("error:parse"); sys.exit(1)
' "$1" "$2"
}

# contract_check_example <자료 이름> <정의 파일>
# 정의 파일에서 예시 블록을 꺼내 대조한다. 추출이 실패하면 사유 줄(error:...)을 로그에 남기고 1 로 끝난다.
contract_check_example() {
  local out="$FX/ex_$1.json"
  if extract_block "$1" "$2" > "$out"; then
    contract_check "$1" - "$out"
  else
    cat "$out"; return 1
  fi
}

# 픽스처. 파일 경로는 json_run 에 인자로만 넘긴다.
cat > "$FX/ok_schema.json" <<'J'
{"type":"object","required":["url","judgments","principles_applied"],"properties":{"url":{},"principles_applied":{},
 "judgments":{"type":"array","items":{"type":"object","required":["ref","verdict","quote","reason"],
  "properties":{"ref":{},"verdict":{},"quote":{},"reason":{}}}}}}
J
cat > "$FX/no_required_schema.json" <<'J'
{"type":"object","required":["url","judgments","principles_applied"],"properties":{"url":{},"principles_applied":{},
 "judgments":{"type":"array","items":{"type":"object","required":["ref","verdict","reason"],
  "properties":{"ref":{},"verdict":{},"quote":{},"reason":{}}}}}}
J
cat > "$FX/ok_example.json" <<'J'
{"url":"u","principles_applied":[],"judgments":[{"ref":"r","verdict":"v","quote":"q","reason":"x"}]}
J
cat > "$FX/missing_quote.json" <<'J'
{"url":"u","principles_applied":[],"judgments":[{"ref":"r","verdict":"v","reason":"x"}]}
J
cat > "$FX/r_no_prior_claim.json" <<'J'
{"search_status":"s","queries":[],"issues":[{"citations":[]}]}
J
cat > "$FX/r_empty_issues.json" <<'J'
{"search_status":"s","queries":[],"issues":[]}
J
printf '<!-- output: researcher -->\n```json\n{ 깨짐\n```\n' > "$FX/broken_def.md"
printf '<!-- output: researcher -->\n본문만 있다\n' > "$FX/marker_only_def.md"
printf '```json\n{}\n```\n' > "$FX/no_marker_def.md"

echo "[계약 테스트 자체]"
check "맞는 스키마·예시는 통과한다"     "contract_check verifier \"\$FX/ok_schema.json\" \"\$FX/ok_example.json\" >/dev/null"
check "빠진 키를 알린다"                "contract_check verifier - \"\$FX/missing_quote.json\" | grep -qx 'example:judgments\[\]\.quote'"
check "required 누락을 알린다"          "contract_check verifier \"\$FX/no_required_schema.json\" - | grep -qx 'schema:judgments\[\]\.quote'"
check "배열 원소의 빠진 키를 알린다"     "contract_check researcher - \"\$FX/r_no_prior_claim.json\" | grep -qx 'example:issues\[\]\.prior_claim'"
check "빈 배열 예시를 알린다"           "contract_check researcher - \"\$FX/r_empty_issues.json\" | grep -qx 'example:issues\[\]\.prior_claim'"
check "없는 자료 이름은 오류다"          "contract_check nosuch - \"\$FX/ok_example.json\" | grep -q '^error:'"
check "깨진 블록을 알린다"              "extract_block researcher \"\$FX/broken_def.md\" | grep -qx 'error:parse'"
check "표지 뒤 블록 없음을 알린다"       "extract_block researcher \"\$FX/marker_only_def.md\" | grep -qx 'error:no-block'"
check "표지 없음을 알린다"              "extract_block researcher \"\$FX/no_marker_def.md\" | grep -qx 'error:no-marker'"

echo "[계약 대조]"
check "계약 코드가 JSON 으로 읽힌다" "json_valid_stdin < \"\$CONTRACT\""
WF="$HERE/workflows/prior-art-search.js"
HARNESS="$HERE/scripts/workflow_harness.mjs"
if [ ! -f "$WF" ]; then
  echo "  SKIP: workflow — 워크플로 스크립트가 없다"
else
  check "node 가 있다" "command -v node >/dev/null"
  SCHEMAS="$FX/schemas.json"
  check "시험 도구가 스키마 상수 네 개를 낸다" \
    "printf '[]' | node \"\$HARNESS\" fn schemas > \"\$SCHEMAS\" && json_run 'import json,sys; d=json.load(open(sys.argv[1],encoding=\"utf-8\")); sys.exit(0 if all(k in d for k in (\"RESEARCHER_SCHEMA\",\"VERIFIER_SCHEMA\",\"SYNTHESIS_SCHEMA\",\"MAP_SCHEMA\")) else 1)' \"\$SCHEMAS\""
  for pair in researcher:RESEARCHER_SCHEMA verifier:VERIFIER_SCHEMA synthesis:SYNTHESIS_SCHEMA map:MAP_SCHEMA; do
    name="${pair%%:*}"; const="${pair##*:}"
    json_run 'import json,sys; json.dump(json.load(open(sys.argv[1],encoding="utf-8"))[sys.argv[2]], open(sys.argv[3],"w",encoding="utf-8"))' "$SCHEMAS" "$const" "$FX/schema_$name.json" 2>/dev/null || true
    check "스키마 $const 가 계약 코드와 맞는다" "contract_check $name \"\$FX/schema_$name.json\" -"
  done
fi
RD="$HERE/agents/prior-art-researcher.md"
VD="$HERE/agents/prior-art-verifier.md"
if [ ! -f "$RD" ] && [ ! -f "$VD" ]; then
  echo "  SKIP: agents — 에이전트 정의가 없다"
else
  check "에이전트 정의 두 파일이 있다" "[ -f \"\$RD\" ] && [ -f \"\$VD\" ]"
  for pair in researcher:RD synthesis:RD verifier:VD map:VD; do
    name="${pair%%:*}"; def="${pair##*:}"; file="${!def}"
    check "예시 $name 이 계약 코드와 맞는다" \
      "contract_check_example $name \"$file\""
  done
fi

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
