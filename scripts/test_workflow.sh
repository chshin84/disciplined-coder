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
check "미구현 함수의 예외는 종료 코드 1 이다" "printf '[[],[]]' | harn fn checkQueries >/dev/null 2>&1; [ \$? -eq 1 ]"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
