#!/usr/bin/env bash
# 렌즈 출력 계약(scripts/lens_contract.json)을 계약 원문과 렌즈 에이전트 정의에 대조하고, 플러그인의
# 에이전트 호출 정책을 검사한다. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONTRACT="$HERE/scripts/lens_contract.json"
AGG="$HERE/skills/aggregating-lenses/SKILL.md"
FX="$(mktemp -d)"; trap 'rm -rf "$FX"' EXIT
. "$HERE/scripts/_test_check.sh"
. "$HERE/scripts/_json_valid.sh"
_json_python || true

# 계약에 아는 렌즈 이름. spec 「에이전트 구성」 표가 원본이다.
KNOWN="lens-adversarial lens-adversarial-claim lens-consistency lens-fit lens-grounding lens-readability"

# keyset <JSON 파일> — 객체의 키를 경로로 늘어놓는다. 배열은 첫 원소의 키를 `칸[].키` 로 적는다.
# `?` 접두 키는 선택 키라 `?` 를 떼고 끝에 `?` 표시를 붙인다.
keyset() {
  json_run '
import json, sys
def walk(o, p, out, req_only):
    for k, v in o.items():
        opt = k.startswith("?")
        key = k[1:] if opt else k
        if req_only and opt:
            continue
        out.append(p + key)
        if isinstance(v, dict):
            walk(v, p + key + ".", out, req_only)
        elif isinstance(v, list) and v and isinstance(v[0], dict):
            walk(v[0], p + key + "[].", out, req_only)
d = json.load(open(sys.argv[1], encoding="utf-8"))
if len(sys.argv) > 2:
    d = d[sys.argv[2]]
out = []
walk(d, "", out, len(sys.argv) > 3)
print("\n".join(sorted(set(out))))
' "$@"
}

# agg_block — aggregating-lenses 「리뷰 산출물 계약」 절의 첫 코드 블록을 JSON 으로 꺼낸다.
agg_block() {
  json_run '
import json, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
i = next(n for n, l in enumerate(lines) if l.startswith("## 리뷰 산출물 계약"))
while not lines[i].startswith("```"): i += 1
j = i + 1
while not lines[j].startswith("```"): j += 1
print(json.dumps(json.loads("\n".join(lines[i+1:j])), ensure_ascii=False))
' "$AGG"
}

# policy_violations <agents_dir> <workflows_dir>
# 위반마다 `agents:<파일>:<사유>` 나 `workflows:<파일>:<줄>` 한 줄을 낸다. 0=위반 없음, 1=있음.
# 사유는 no-tools(tools 줄 없음), not-one-line(`tools:` 뒤 값이 비어 있음), agent-tool(Agent·Task 가 있음)이다.
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
    tl = [l for l in fm if re.match(r"tools:", l)]
    if not tl:
        bad.append("agents:%s:no-tools" % name); continue
    val = tl[0][len("tools:"):].strip()
    if not val:
        bad.append("agents:%s:not-one-line" % name); continue
    items = [x.strip().split("(")[0].strip() for x in val.split(",")]
    if any(x in ("Agent", "Task") for x in items):
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
agg_block > "$FX/agg.json" 2>/dev/null || true
check "계약의 공통 칸이 aggregating-lenses 리뷰 산출물 계약과 같다" \
  "[ \"\$(keyset \"\$FX/agg.json\")\" = \"\$(keyset \"\$CONTRACT\" common req)\" ]"
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
TOOLS_MISS=""
for row in t_agent:agent-tool t_task:agent-tool t_agentsub:agent-tool t_yaml:not-one-line t_none:no-tools; do
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

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
