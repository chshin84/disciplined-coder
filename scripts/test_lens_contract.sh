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

# 렌즈 이름은 정의 파일(agents/lens-*.md)에서 도출한다. 손으로 적은 목록은 렌즈를 지우거나 합칠 때 먼저 낡는다.
KNOWN="$(cd "$HERE/agents" && ls lens-*.md 2>/dev/null | sed 's/\.md$//' | sort | tr '\n' ' ' | sed 's/ $//')"

# policy_violations <agents_dir> <workflows_dir>
# 위반마다 `agents:<파일>:<사유>` 나 `workflows:<파일>:<줄>` 한 줄을 낸다. 0=위반 없음, 1=있음.
# 워크플로는 `agent(` 라는 이름의 호출만 본다. `const run = agent` 같은 별칭으로 부르면 잡지 못한다.
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
check "계약 JSON 의 렌즈가 정의 파일과 같다" \
  "[ -n \"\$KNOWN\" ] && [ \"\$(json_run 'import json,sys; print(\" \".join(sorted(json.load(open(sys.argv[1],encoding=\"utf-8\"))[\"agents\"])))' \"\$CONTRACT\" 2>/dev/null)\" = \"\$KNOWN\" ]"
check "lens-adversarial 계약 types 에 contradiction 이 있다" \
  "json_run 'import json,sys; sys.exit(0 if \"contradiction\" in json.load(open(sys.argv[1],encoding=\"utf-8\"))[\"agents\"][\"lens-adversarial\"][\"types\"] else 1)' \"\$CONTRACT\""
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
mk_tools_fx t_agentsub  's/^\(tools: .*\)$/\1, Agent(lens-grounding)/'
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
# 정의마다 기대하는 tools 줄. spec 「에이전트 구성」·「2차 변경」 표가 원본이고, visual 의 브라우저 도구 이름은
# docs/superpowers/decisions/2026-10-25-lens-agent-runtime.md 시험 4 가 확인한 이름이다.
declare -A TOOLS=(
  [lens-adversarial]="Read, Grep, Glob"
  [lens-grounding]="Read, Grep, Glob"
  [lens-readability]="Read, mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_snapshot"
  [lens-rebuttal]="Read, Grep, Glob, WebSearch, WebFetch"
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
  check "$name: 정의 파일과 이름이 같다" "grep -qx 'name: $name' \"$d\""
  check "$name: 모델이 opus 다" "grep -qx 'model: opus' \"$d\""
  check "$name: 도구가 spec 표와 같다" "grep -qxF 'tools: ${TOOLS[$name]:-}' \"$d\""
  check "$name: 입력 절이 lens-review 의 입력 형식을 읽는다" \
    "has_sec \"$d\" '입력' && sec_has \"$d\" '입력' MODE && sec_has \"$d\" '입력' TARGET && sec_has \"$d\" '입력' CRITERIA"
  check "$name: 출력 예시가 계약과 같다" "example_ok \"$d\" $name 2>/dev/null"
  check "$name: 읽기 범위 절이 있다" "has_sec \"$d\" '읽기 범위'"
  check "$name: description 이 입력 안내로 lens-review 를 가리킨다" \
    "grep -E '^description: ' \"$d\" | grep -qF '\`lens-review\`'"
  check "$name: 출력 예시가 계약 소유자를 가리킨다" \
    "sec_has \"$d\" '출력 예시' '「통합과 1차 디펜스」' && sec_has \"$d\" '출력 예시' 'scripts/lens_contract.json'"
done
RDL="$HERE/agents/lens-readability.md"
check "lens-readability: 도구 부재 처리를 적는다" "grep -qF '브라우저 도구 없음' \"\$RDL\""
# 독자 렌즈는 대상·목적·문체 공격 항목만 받는다. 출처를 읽은 렌즈는 맥락 없는 독자를 흉내 낼 수 없기 때문이다.
check "lens-readability 에 입력 절이 있다" "has_sec \"\$RDL\" '입력' && sec_has \"\$RDL\" '입력' 'style-attacks.md'"
SA="$HERE/skills/lens-review/references/style-attacks.md"
check "style-attacks.md 에 과잉 지적 반례 절이 있다" "[ -f \"\$SA\" ] && has_sec \"\$SA\" '과잉 지적 반례'"

echo "[렌즈 공통과 웹 규칙]"
# v2 의 렌즈는 에이전트원칙을 읽지 않고, 판정 기준은 lens-review 가 CRITERIA 줄로 넘긴다(spec 「에이전트」 렌즈 공통 행).
PR_HIT="$(grep -lE 'PRINCIPLES|principles_applied' "$HERE"/agents/lens-*.md 2>/dev/null || true)"
check "렌즈 정의에 PRINCIPLES·principles_applied 가 없다" "[ -z \"\$PR_HIT\" ]"

fm_of() { awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f' "$1" | tr -d '\r'; }
# has_tool <정의> <정규식> — frontmatter 의 tools 목록에 정규식과 통째로 맞는 도구가 있으면 참.
has_tool() { grep -qxE "$2" <<<"$(fm_of "$1" | sed -n 's/^tools:[ ]*//p' | tr ',' '\n' | sed 's/^ *//; s/ *$//; s/(.*//')"; }
# 웹 주소를 여는 도구를 가진 정의는 금융투자협회 홈페이지 접속 금지를 직접 적는다. 반복 접속은 사내 접속 차단으로
# 이어지고, 서브에이전트는 메인 세션의 지시를 물려받는다고 볼 수 없다.
OPEN_RE='WebSearch|WebFetch|mcp__.*browser_navigate'
KOFIA_MISS=""; WEBN=0
for f in "$HERE"/agents/*.md; do
  has_tool "$f" "$OPEN_RE" || continue
  WEBN=$((WEBN+1))
  grep -qE '마라|금지' <<<"$(grep -F 'kofia.or.kr' "$f" || true)" || KOFIA_MISS="$KOFIA_MISS $(basename "$f")"
done
[ -n "$KOFIA_MISS" ] && echo "    금지가 없는 정의:$KOFIA_MISS"
check "웹 주소를 여는 도구(WebSearch·WebFetch·browser_navigate)를 가진 에이전트 정의에 kofia.or.kr 금지가 있다" \
  "[ \"\$WEBN\" -gt 0 ] && [ -z \"\$KOFIA_MISS\" ]"
lenses_with() { for f in "$HERE"/agents/lens-*.md; do has_tool "$f" "$1" && basename "$f" .md || true; done | tr '\n' ' ' | sed 's/ $//'; }
check "WebSearch·WebFetch 를 가진 렌즈는 lens-rebuttal 뿐이다" "[ \"\$(lenses_with 'WebSearch|WebFetch')\" = lens-rebuttal ]"
check "browser_navigate 를 가진 렌즈는 lens-readability 뿐이다" "[ \"\$(lenses_with 'mcp__.*browser_navigate')\" = lens-readability ]"
# 검색어는 외부 검색 서비스의 로그에 남는다. 검색하는 정의는 사내 정보를 빼고 일반화한 검색어를 쓰라고 적는다.
check "lens-rebuttal 가드가 사내 정보 검색어 금지를 둔다" "sec_has \"\$HERE/agents/lens-rebuttal.md\" '가드' '사내 정보'"
check "researcher 의 탐색 지시가 검색어 일반화를 둔다" "sec_has \"\$HERE/agents/researcher.md\" 'explore 모드' '사내 식별자'"

# 지운 렌즈 이름이 실리는 지시문과 실행 설정에 남으면 없는 에이전트를 부른다. 참고서(docs/domain-*.md)와 테스트
# 픽스처는 범위 밖이고, 공통 제외 목록은 _doc_keys.sh 의 REMOVED_REF_EXCLUDES 가 소유한다.
REMOVED_LENS_RE='lens-consistency|lens-fit|lens-visual|map-check'
RL_BAD=""
while IFS= read -r f; do
  [ -f "$HERE/$f" ] || continue
  skip=0
  for e in "${REMOVED_REF_EXCLUDES[@]}"; do
    # shellcheck disable=SC2053
    case "$e" in */) [[ $f == "$e"* ]] && skip=1 ;; *) [[ $f == $e ]] && skip=1 ;; esac
  done
  [ "$skip" = 1 ] && continue
  grep -qE "$REMOVED_LENS_RE" "$HERE/$f" && RL_BAD="$RL_BAD $f"
done <<EOF
$(cd "$HERE" && git ls-files --cached --others --exclude-standard -- agents skills hooks workflows 'scripts/*.json')
EOF
[ -n "$RL_BAD" ] && echo "    지운 렌즈 이름이 남은 곳:$RL_BAD"
check "지운 렌즈 이름(lens-consistency·lens-fit·lens-visual·map-check)을 가리키는 살아 있는 지시문이 없다" "[ -z \"\$RL_BAD\" ]"

# 에이전트 description 은 세션마다 실리는 지시문이다. name·description 이 있고 description 에 백틱 밖 금지어가 없다.
. "$HERE/hooks/_banned_words.sh"
mkdir -p "$FX/bw"
banned_parse "$HERE/korean-banned-words.md" "$FX/bw/pairs" "$FX/bw/toks" "$FX/bw/excl"
FM_BAD=""
for f in "$HERE"/agents/*.md; do
  b="$(basename "$f")"; fmv="$(fm_of "$f")"
  if ! grep -q '^name: ' <<<"$fmv" || ! grep -q '^description: ' <<<"$fmv"; then FM_BAD="$FM_BAD $b(name·description)"; continue; fi
  grep -m1 '^description: ' <<<"$fmv" | sed 's/^description: //' > "$FX/desc.txt"
  [ -z "$(banned_report "$FX/bw/pairs" "$FX/desc.txt" "$FX/bw/excl")" ] || FM_BAD="$FM_BAD $b(금지어)"
done
[ -n "$FM_BAD" ] && echo "    안전하지 않은 frontmatter:$FM_BAD"
check "모든 에이전트 frontmatter 가 안전하다" "[ -z \"\$FM_BAD\" ]"

# 예시 결함 주입 — 계약 밖 칸을 넣은 예시는 대조가 실패해야 한다.
cp "$HERE/agents/lens-grounding.md" "$FX/bad_example.md" 2>/dev/null || : > "$FX/bad_example.md"
sed -i 's/^{ "lens": "lens-grounding",/{ "lens": "lens-grounding", "severity": "",/' "$FX/bad_example.md"
check "예시에 계약 밖 칸이 있으면 잡는다" \
  "grep -qF '\"severity\"' \"\$FX/bad_example.md\" && ! example_ok \"\$FX/bad_example.md\" lens-grounding 2>/dev/null"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]
