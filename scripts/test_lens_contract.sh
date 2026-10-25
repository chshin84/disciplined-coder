#!/usr/bin/env bash
# 렌즈 출력 계약(scripts/lens_contract.json)을 렌즈 에이전트 정의에 대조하고, 플러그인의
# 에이전트 호출 정책을 검사한다. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACT="$HERE/scripts/lens_contract.json"
FX="$(mktemp -d)"; trap 'rm -rf "$FX"' EXIT
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"
_json_python || true

# 계약에 아는 렌즈 이름. spec 「에이전트 구성」 표가 원본이다.
KNOWN="lens-adversarial lens-adversarial-claim lens-consistency lens-fit lens-grounding lens-readability"

# policy_violations <agents_dir> <workflows_dir>
# 위반마다 `agents:<파일>:<사유>` 나 `workflows:<파일>:<줄>` 한 줄을 낸다. 0=위반 없음, 1=있음.
# 사유는 no-tools(tools 줄 없음), not-one-line(값이 비었거나 `[`·따옴표로 시작함), agent-tool(Agent·Task 가 있음)이다.
policy_violations() {
  json_run '
import os, re, sys
sys.stdout.reconfigure(newline="\n")  # 윈도우에서 줄 끝에 CR 이 붙으면 호출자의 grep 줄끝 일치가 깨진다.
agents_dir, wf_dir = sys.argv[1:3]
bad = []
for name in sorted(os.listdir(agents_dir)) if os.path.isdir(agents_dir) else []:
    if not name.endswith(".md"):
        continue
    lines = open(os.path.join(agents_dir, name), encoding="utf-8").read().splitlines()
    fm = []
    if lines and lines[0] == "---":
        for l in lines[1:]:
            if l == "---":
                break
            fm.append(l)
    def field(key):
        # 한 줄 쉼표 목록 필드의 이름 목록. 줄이 없으면 None, 블록·흐름 목록이나 따옴표 값이면 "bad".
        hit = [l for l in fm if re.match(key + r":", l)]
        if not hit:
            return None
        val = hit[0][len(key) + 1:].strip()
        if not val or val[0] in "[\"\x27":
            return "bad"
        return [x.strip().split("(")[0].strip() for x in val.split(",")]
    tools = field("tools")
    if tools is None:
        # tools 를 생략하면 Agent 와 MCP 를 포함한 세션 도구를 모두 물려받는다. 도구는 목적에 맞게 계획해 허가한다.
        bad.append("agents:%s:no-tools" % name); continue
    if tools == "bad":
        bad.append("agents:%s:not-one-line" % name); continue
    if any(x in ("Agent", "Task") for x in tools):
        bad.append("agents:%s:agent-tool" % name)

def blank(src):
    # 주석과 문자열을 같은 길이의 공백으로 바꿔 괄호 짝과 키 검색이 코드만 보게 한다. 줄바꿈은 남긴다.
    out, i, n = [], 0, len(src)
    def fill(s): return re.sub(r"[^\n]", " ", s)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i); j = n if j < 0 else j
            out.append(fill(src[i:j])); i = j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2); j = n if j < 0 else j + 2
            out.append(fill(src[i:j])); i = j
        elif c in "\"\x27`":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            j = min(j + 1, n)
            out.append(c + fill(src[i+1:j-1]) + (c if j - 1 > i else "")); i = j
        else:
            out.append(c); i += 1
    return "".join(out)

for name in sorted(os.listdir(wf_dir)) if os.path.isdir(wf_dir) else []:
    if not name.endswith((".js", ".mjs")):
        continue
    code = blank(open(os.path.join(wf_dir, name), encoding="utf-8").read())
    for m in re.finditer(r"(?<![A-Za-z0-9_$.])agent\(", code):
        depth, j = 0, m.end() - 1
        while j < len(code):
            if code[j] == "(": depth += 1
            elif code[j] == ")":
                depth -= 1
                if depth == 0: break
            j += 1
        body = code[m.end():j]
        if not re.search(r"\bagentType\s*:", body) or "..." in body:
            bad.append("workflows:%s:%d" % (name, code.count("\n", 0, m.start()) + 1))
for b in bad:
    print(b)
sys.exit(1 if bad else 0)
' "$1" "$2"
}

echo "[계약]"
check "계약 파일이 JSON 으로 읽힌다" "json_valid_stdin < \"\$CONTRACT\""
check "계약의 렌즈 이름이 아는 이름이다" \
  "[ \"\$(json_run 'import json,sys; print(\" \".join(sorted(json.load(open(sys.argv[1],encoding=\"utf-8\"))[\"agents\"])))' \"\$CONTRACT\" 2>/dev/null)\" = \"\$KNOWN\" ]"
check "빼는 칸이 공통 최상위 칸이다" \
  "json_run 'import json,sys; c=json.load(open(sys.argv[1],encoding=\"utf-8\")); top={k.lstrip(\"?\") for k in c[\"common\"]}; sys.exit(0 if all(set(a.get(\"omit\",[]))<=top for a in c[\"agents\"].values()) else 1)' \"\$CONTRACT\""

echo "[호출 정책]"
# 정책: 사전 정의 호출만 허용한다(docs/superpowers/decisions/2026-10-25-agent-call-policy.md).
# 정의는 Agent 없는 한 줄 tools 를 두고, 워크플로의 agent() 는 옵션 객체에 agentType 을 직접 적는다.
check "현행 정의와 워크플로가 호출 정책을 지킨다" "policy_violations \"\$HERE/agents\" \"\$HERE/workflows\""

# tools 결함 주입 — 정의 하나의 tools 줄을 위반 형식으로 바꾼 픽스처마다 위반을 잡아야 한다.
first_def="$(ls "$HERE"/agents/*.md | head -1)"
mk_tools_fx() {  # $1=픽스처 이름, $2=sed 식. agents/ 를 복사하고 첫 정의의 tools 줄을 바꾼다.
  rm -rf "$FX/$1"; mkdir -p "$FX/$1/agents" "$FX/$1/workflows"
  cp "$HERE"/agents/*.md "$FX/$1/agents/"
  sed -i "$2" "$FX/$1/agents/$(basename "$first_def")"
}
mk_tools_fx t_agent     's/^\(tools: .*\)$/\1, Agent/'
mk_tools_fx t_task      's/^\(tools: .*\)$/\1, Task/'
mk_tools_fx t_agentsub  's/^\(tools: .*\)$/\1, Agent(lens-fit)/'
mk_tools_fx t_yaml      's/^tools: .*$/tools:\n  - Read/'
mk_tools_fx t_none      '/^tools: /d'
mk_tools_fx t_flow      's/^tools: .*$/tools: [Read, Agent]/'
mk_tools_fx t_quoted    's/^tools: .*$/tools: "Read, Task"/'
TOOLS_MISS=""
for row in t_agent:agent-tool t_task:agent-tool t_agentsub:agent-tool t_yaml:not-one-line t_none:no-tools t_flow:not-one-line t_quoted:not-one-line; do
  f="${row%%:*}"; why="${row##*:}"
  # 위반이 있으면 함수가 1 을 돌려주므로 pipefail 에 걸리지 않게 출력을 먼저 받아 둔다.
  out="$(policy_violations "$FX/$f/agents" "$FX/$f/workflows" 2>/dev/null || true)"
  grep -q "^agents:.*:$why\$" <<<"$out" || TOOLS_MISS="$TOOLS_MISS $f"
done
[ -n "$TOOLS_MISS" ] && echo "    놓친 픽스처:$TOOLS_MISS"
check "tools 위반 형식을 모두 잡는다" "[ -z \"\$TOOLS_MISS\" ]"

# 워크플로 결함 주입 — agentType 키가 있는 첫 호출에서 그 키를 지운다.
rm -rf "$FX/w_noat"; mkdir -p "$FX/w_noat/agents" "$FX/w_noat/workflows"
json_run '
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
out = re.sub(r"agentType:\s*[A-Za-z_][A-Za-z0-9_.]*\s*,?\s*", "", src, count=1)
open(sys.argv[2], "w", encoding="utf-8").write(out)
' "$HERE/workflows/prior-art-search.js" "$FX/w_noat/workflows/prior-art-search.js"
check "agentType 을 뺀 호출을 잡는다" "policy_violations \"\$FX/w_noat/agents\" \"\$FX/w_noat/workflows\" 2>/dev/null | grep -q '^workflows:'"

echo "[정의]"
. "$HERE/scripts/_doc_keys.sh"
# 정의마다 기대하는 tools 줄. spec 「에이전트 구성」 표가 원본이고, readability 의 브라우저 도구 이름은
# docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md 시험 4 가 확인한 이름이다.
declare -A TOOLS=(
  [lens-adversarial]="Read, Grep, Glob"
  [lens-adversarial-claim]="Read, Grep, Glob, WebSearch, WebFetch"
  [lens-consistency]="Read, Grep, Glob"
  [lens-fit]="Read, Grep, Glob"
  [lens-grounding]="Read, Grep, Glob"
  [lens-readability]="Read, mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_snapshot"
)

# example_ok <정의 파일> <렌즈 이름> — 「출력 예시」 절의 첫 ```json 블록을 계약과 대조한다.
# 최상위는 공통 키에서 omit 을 빼고 extra 를 더한 집합, 배열 원소는 그 칸에 적힌 원소 키 집합이다.
# `?` 키는 있어도 없어도 통과다. lens 값과 issues[].type 값(| 로 늘어놓은 것 포함)도 본다.
example_ok() {
  json_run '
import json, re, sys
path, name, cpath = sys.argv[1:4]
c = json.load(open(cpath, encoding="utf-8")); a = c["agents"][name]
lines = open(path, encoding="utf-8").read().splitlines()
i = next(n for n, l in enumerate(lines) if re.match(r"##\s+출력 예시\s*$", l))
while not lines[i].startswith("```json"): i += 1
j = i + 1
while not lines[j].startswith("```"): j += 1
ex = json.loads("\n".join(lines[i+1:j]))
spec = {k: v for k, v in c["common"].items() if k.lstrip("?") not in a["omit"]}
spec.update(a["extra"])
def same(obj, sp):
    req = {k for k in sp if not k.startswith("?")}
    allowed = {k.lstrip("?") for k in sp}
    if not (req <= set(obj) <= allowed): return False
    for k, v in sp.items():
        k = k.lstrip("?")
        if isinstance(v, list) and v and isinstance(v[0], dict) and k in obj:
            if not all(isinstance(e, dict) and same(e, v[0]) for e in obj[k]): return False
    return True
ok = same(ex, spec) and ex.get("lens") == name
for it in ex.get("issues", []):
    ok = ok and all(t in a["types"] for t in str(it.get("type", "")).split("|"))
sys.exit(0 if ok else 1)
' "$1" "$2" "$CONTRACT"
}

for name in $KNOWN; do
  d="$HERE/agents/$name.md"
  check "$name: 정의 파일과 이름이 같다" "[ -f \"$d\" ] && grep -qx 'name: $name' \"$d\""
  check "$name: 모델이 opus 다" "grep -qx 'model: opus' \"$d\""
  check "$name: 도구가 spec 표와 같다" "grep -qxF 'tools: ${TOOLS[$name]}' \"$d\""
  check "$name: 입력 절이 두 줄의 부재를 다룬다" \
    "has_sec \"$d\" '입력' && sec_has \"$d\" '입력' MODE && sec_has \"$d\" '입력' PRINCIPLES"
  check "$name: 출력 예시가 계약과 같다" "example_ok \"$d\" $name 2>/dev/null"
  check "$name: 읽기 범위 절이 있다" "has_sec \"$d\" '읽기 범위'"
  check "$name: description 이 입력 안내로 dispatching-lenses 를 가리킨다" \
    "grep -E '^description: ' \"$d\" | grep -qF '\`dispatching-lenses\`'"
  check "$name: 출력 예시가 계약 소유자를 가리킨다" \
    "sec_has \"$d\" '출력 예시' '「결과를 모으는 법」' && sec_has \"$d\" '출력 예시' 'scripts/lens_contract.json'"
done
check "lens-readability: 도구 부재 처리를 적는다" "grep -qF '브라우저 도구 없음' \"\$HERE/agents/lens-readability.md\""

# 예시 결함 주입 — 계약 밖 칸을 넣은 예시는 대조가 실패해야 한다.
cp "$HERE/agents/lens-grounding.md" "$FX/bad_example.md" 2>/dev/null || : > "$FX/bad_example.md"
sed -i 's/^{ "lens": "lens-grounding",/{ "lens": "lens-grounding", "severity": "",/' "$FX/bad_example.md"
check "예시에 계약 밖 칸이 있으면 잡는다" \
  "grep -qF '\"severity\"' \"\$FX/bad_example.md\" && ! example_ok \"\$FX/bad_example.md\" lens-grounding 2>/dev/null"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
