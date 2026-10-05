# 금지어 목록 원본 이전 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 금지어 목록의 원본을 옛 저장소 JSON 에서 이 저장소의 목록 파일과 근거 파일로 옮기고, 받기 워크플로를
원문 대조 검사로 바꾼다.

**Architecture:** 루트의 `korean-banned-words.md` 는 위치와 표가 그대로이고 머리 안내만 바뀌어 원본이 된다.
근거는 옛 JSON 에서 한 번 변환해 `skills/lens-readability/banned-words-evidence.md` 에 둔다. 편집 규칙은
`.claude/rules/banned-words.md` 에 둔다. `scripts/test_docs_drift.sh` 의 금지 표현 절은 목록 파일을 원문 그대로
읽는 파이썬 검사와 `banned_parse` 출력을 대조한다.

**Tech Stack:** bash, awk(`hooks/_banned_words.sh`), 파이썬(`scripts/_json_valid.sh` 의 `json_run`)

**Spec:** `docs/superpowers/specs/2026-10-06-banned-words-merge-design.md`

## Global Constraints

- 작업 위치는 워크트리 `D:\projects\Structure\disciplined-coder\.claude\worktrees\elegant-seeking-thacker` 이고, 메인 체크아웃을 고치지 않는다.
- 목록 파일의 첫 줄 `# 한국어 금지어 목록`, `### 금지 표현` 제목, 표의 칸 순서(금지어·대체어·적용 대상·분류·제외)를 바꾸지 않는다.
- 훅(`hooks/_banned_words.sh` 의 awk, `doc_word_*`, `stop_gates.sh`)과 스캐폴드(`_scaffold_common.sh`·`scaffold.sh`)의 동작 코드는 고치지 않는다. 주석만 고친다.
- 근거 파일의 사용자 원문 인용은 고쳐 쓰지 않는다.
- 옛 저장소 `D:\projects\Structure\korean-banned-words` 는 읽기만 한다. 변환 스크립트는 scratchpad 에서 실행하고 커밋하지 않는다.
- `docs/superpowers/` 아래 기존 설계·계획·리뷰 기록은 고치지 않는다.
- 이 저장소의 문서에 금지 표현 검사를 다시 적용하지 않는다(`path_in_own_repo` 결정 유지).
- 각 태스크가 끝나면 저장소 `CLAUDE.md` 「변경 뒤 실행」 명령으로 확인한다. 기대 개수를 숫자로 박지 않는다.
- 커밋 메시지는 한국어 평서문이고 끝에 `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>` 를 붙인다.

## Review Focus

- **제외 칸 앞 세로줄 소실:** `판` 행의 제외 칸 앞 `|` 가 빠지면 훅이 그 행의 제외를 잃는다. 검사가 `행 형식` 위반을 내야 한다(Task 3 자기시험).
- **표 중간의 `#` 줄:** awk 가 그 줄에서 멈춰 아래 행을 버린다. 검사가 `행 형식` 위반을 내야 한다(Task 3 자기시험).
- **꺼 둔 항목 줄에서 이름이 빠짐:** 근거 절은 남고 목록에서 사라진다. 검사가 `근거 대응` 위반을 내야 한다(Task 3 자기시험).
- **근거 파일의 원문 인용:** 인용에 든 대구 때문에 대구 한도 검사가 실패하면 안 된다. 근거 파일을 `ANTI_DOCS` 에서 빼고 전체 검사가 `ALL PASS` 여야 한다(Task 3).
- **사본 편집:** `~/.claude/disciplined-coder/` 사본을 고치지 말라는 안내와 원본 저장소 이름이 목록 파일 머리에 있어야 한다. 검사가 머리 12줄에서 `chshin84/disciplined-coder` 와 `사본` 을 확인한다(Task 3).

---

### Task 1: 근거 파일 만들기

**Files:**
- Create: `skills/lens-readability/banned-words-evidence.md`
- Create(커밋 안 함): scratchpad 의 `convert_evidence.py`

**Interfaces:**
- Consumes: 옛 저장소 `korean-banned-words.json` 의 `entries`(`banned`·`replace`·`instruction`·`exclude`·`scope`·`category`·`enabled`·`disabled_reason`·`evidence`)와 `rules`(`text`·`evidence`), `categories`(`id`·`title`)
- Produces: 근거 파일. 금지어 항목은 `` ## `<첫 금지어>` `` 절, 규칙은 `## 규칙: <규칙 첫 문장>` 절이다. Task 3 의 근거 대응·규칙 대응 검사가 이 두 제목 형식을 읽는다.

- [ ] **Step 1: 옛 저장소가 이전 시점 그대로인지 확인한다**

Run:
```bash
git -C /d/projects/Structure/korean-banned-words log -1 --format=%h
diff -q /d/projects/Structure/korean-banned-words/dist/korean-banned-words.md korean-banned-words.md && echo SAME
```
Expected: `5b02378` 과 `SAME`. 다르면 멈추고 사용자에게 알린다.

- [ ] **Step 2: 변환 스크립트를 scratchpad 에 쓴다**

경로: `C:\Users\ho381\AppData\Local\Temp\claude\D--projects-Structure-disciplined-coder\5afd6f9e-2d4a-461c-bf8c-91ae5c6648cb\scratchpad\convert_evidence.py`

```python
import io, json, re, sys

src, lst, out = sys.argv[1:4]
d = json.load(io.open(src, encoding="utf-8"))
cat = {c["id"]: c["title"] for c in d["categories"]}

def scope_title(sc):
    return "문서와 답변" if "living-doc" in sc else "답변과 산출물"

def ticks(xs):
    return " · ".join("`%s`" % x for x in xs)

def evidence(ev):
    k = ev["kind"]
    if k == "reasoned" or "quote" not in ev:
        return ["근거 종류는 %s 이고 원문 인용은 없다." % k]
    lines = ["근거 종류는 %s 이고 날짜는 %s 이다." % (k, ev["date"]), ""]
    lines += ["> " + l if l else ">" for l in ev["quote"].split("\n")]
    return lines

# 목록 파일의 켜진 행과 JSON 의 켜진 항목이 같은 첫 금지어·적용 대상인지 먼저 맞춘다.
rows = [l for l in io.open(lst, encoding="utf-8").read().splitlines() if l.startswith("| `")]
table = {}
for r in rows:
    c = [x.strip() for x in r.strip().strip("|").split("|")]
    table[re.findall(r"`([^`]*)`", c[0])[0]] = c[2]
on = [e for e in d["entries"] if e["enabled"]]
assert set(table) == {e["banned"][0] for e in on}, "켜진 항목과 표의 첫 금지어가 다르다"
for e in on:
    assert table[e["banned"][0]] == scope_title(e["scope"]), e["banned"][0]

o = ["# 금지 표현 근거", "",
     "`korean-banned-words.md` 의 항목마다 그 말을 왜 쓰지 않는지와, 끈 항목은 왜 껐는지를 적는다. "
     "이 파일은 세션에 싣지 않는다. 목록을 고치는 규칙은 `.claude/rules/banned-words.md` 에 있다.", "",
     "2026-10-06에 옛 저장소 `KiwoomAX/korean-banned-words` 의 JSON(커밋 `5b02378`)에서 옮겼다. "
     "사용자 원문 인용은 고쳐 쓰지 않는다.", ""]
for e in d["entries"]:
    o.append("## `%s`" % e["banned"][0])
    o.append("")
    state = "켜져 있다" if e["enabled"] else "꺼져 있다"
    o.append("분류는 「%s」이고 %s." % (cat[e["category"]], state))
    if not e["enabled"]:
        o.append("")
        o.append("끈 사유: %s" % e["disabled_reason"])
        o.append("")
        repl = " · ".join(e["replace"]) if e.get("replace") else e.get("instruction", "")
        o.append("다시 켤 때의 표 칸: 금지어 %s, 대신 쓰는 말 %s, 적용 대상 %s, 제외 %s." % (
            ticks(e["banned"]), repl, scope_title(e["scope"]), ticks(e.get("exclude", [])) or "없음"))
    o.append("")
    o += evidence(e["evidence"])
    o.append("")
for r in d["rules"]:
    first = r["text"].split(". ")[0].rstrip(".") + "."
    o.append("## 규칙: %s" % first)
    o.append("")
    o += evidence(r["evidence"])
    o.append("")
io.open(out, "w", encoding="utf-8", newline="\n").write("\n".join(o).rstrip("\n") + "\n")
print("entries", len(d["entries"]), "rules", len(d["rules"]))
```

- [ ] **Step 3: 변환을 실행한다**

Run:
```bash
python "C:/Users/ho381/AppData/Local/Temp/claude/D--projects-Structure-disciplined-coder/5afd6f9e-2d4a-461c-bf8c-91ae5c6648cb/scratchpad/convert_evidence.py" \
  /d/projects/Structure/korean-banned-words/korean-banned-words.json korean-banned-words.md \
  skills/lens-readability/banned-words-evidence.md
```
Expected: `entries 68 rules 7` 이 출력되고 assert 가 실패하지 않는다. assert 가 실패하면 목록 파일과 JSON 이 다르다는 뜻이므로 멈추고 알린다.

- [ ] **Step 4: 근거 보존을 확인한다**

Run:
```bash
grep -c '^## `' skills/lens-readability/banned-words-evidence.md
grep -c '^## 규칙:' skills/lens-readability/banned-words-evidence.md
python -c "import json,io;d=json.load(io.open('/d/projects/Structure/korean-banned-words/korean-banned-words.json',encoding='utf-8'));print(len(d['entries']),len(d['rules']))"
```
Expected: 첫 두 값이 셋째 줄의 두 값과 같다. 규칙 첫 문장이 서로 겹치면 `## 규칙:` 제목이 같아지므로 `grep '^## 규칙:' … | sort | uniq -d` 가 빈 출력인지도 본다.

- [ ] **Step 5: 커밋**

```bash
git add skills/lens-readability/banned-words-evidence.md
git commit -q -F - <<'EOF'
금지 표현 근거를 옛 저장소 JSON(5b02378)에서 근거 파일로 옮긴다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

### Task 2: 목록 파일 머리를 원본 안내로 바꾸기

**Files:**
- Modify: `korean-banned-words.md:3-7`, `:15`, `:82`

**Interfaces:**
- Consumes: Task 1 의 근거 파일 경로
- Produces: 머리 12줄 안에 `chshin84/disciplined-coder` 와 `사본` 이 있는 목록 파일. Task 3 이 이 두 문자열을 검사한다.

- [ ] **Step 1: 바꾸기 전 파싱 행 수를 적어 둔다**

Run:
```bash
. hooks/_banned_words.sh; W=$(mktemp -d); banned_parse korean-banned-words.md "$W/p" "$W/t" "$W/e"; wc -l < "$W/p"; md5sum "$W/p" "$W/t" "$W/e"
```
출력값을 Step 4 에서 대조한다.

- [ ] **Step 2: 머리 3-7행을 바꾼다**

지금 3-7행(생성물 문장, 빈 줄, HTML 주석 세 줄)을 아래 한 문단으로 바꾼다.

```markdown
이 파일의 원본은 `chshin84/disciplined-coder` 저장소 루트의 `korean-banned-words.md` 다. `~/.claude/disciplined-coder/` 의 사본은 세션마다 원본으로 덮어쓰므로 사본을 고치지 않는다.
```

- [ ] **Step 3: 근거 위치와 꺼 둔 항목 문구를 바꾼다**

15행 끝 문장 `각 항목의 근거는 https://github.com/KiwoomAX/korean-banned-words 에 있다.` 를
`각 항목의 근거는 같은 저장소의 \`skills/lens-readability/banned-words-evidence.md\` 에 있다.` 로 바꾼다(백슬래시 없이 백틱).
82행의 `왜 껐는지는 원본이 적는다` 를 `왜 껐는지는 근거 파일이 적는다` 로 바꾼다.

- [ ] **Step 4: 표가 그대로인지 확인한다**

Run: Step 1 명령을 다시 실행한다.
Expected: 행 수와 세 파일의 md5 가 Step 1 과 같다. 그리고 `git diff --stat korean-banned-words.md` 가 이 파일 하나만 보이고, `git diff korean-banned-words.md | grep '^[-+]| `'` 가 빈 출력이다.

- [ ] **Step 5: 스캐폴드 시험을 실행한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -E 'FAIL|PASS=|FAIL='`
Expected: `FAIL:` 줄이 없다. 첫 줄 제목으로 사본이 실렸는지 보는 42행 검사가 통과한다.

- [ ] **Step 6: 커밋**

```bash
git add korean-banned-words.md
git commit -q -F - <<'EOF'
목록 파일 머리를 생성물 안내에서 원본 위치와 사본 안내로 바꾼다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

### Task 3: 목록 검사를 원문 대조로 바꾸고 받기 워크플로 지우기

**Files:**
- Modify: `scripts/test_docs_drift.sh:813-827`(금지 표현 절), `:855-857`(대구 한도 제외)
- Delete: `.github/workflows/banned-words-sync.yml`
- Create: `.claude/rules/banned-words.md`

**Interfaces:**
- Consumes: `banned_parse <표> <pairs> <toks>`(`hooks/_banned_words.sh`), `json_run <프로그램> <인자…>`(`scripts/_json_valid.sh`, 788행에서 이미 source 됨), `check "<이름>" "<명령>"`(`scripts/_test_check.sh`), Task 1 의 제목 형식, Task 2 의 머리 문자열
- Produces: `banlist_issues <목록> <근거>` 가 위반을 `종류<탭>내용` 줄로 낸다. 종류는 `행 형식`·`제외어`·`중복`·`적용 대상`·`근거 대응`·`규칙 대응` 이다.

- [ ] **Step 1: 금지 표현 절(813-827행)을 검사와 자기시험으로 바꾼다**

`# --- 금지 표현 목록은 생성물이다 ---` 부터 `check "워크플로가 원본 dist 를 받는다" …` 까지를 아래로 바꾼다.

```bash
# --- 금지 표현 목록이 훅이 읽는 형식을 지키고 근거 파일과 맞는다 ---
# 목록 파일이 원본이고 사람이 손으로 고친다. 훅의 awk 는 칸이 모자란 행을 소리 없이 버리고, 제외 칸 앞
# 세로줄이 빠진 행은 제외를 잃은 채 읽는다(hooks/_banned_words.sh). 그러면 `판정` 같은 정상 낱말이 모든
# PC 에서 거부된다. 그래서 awk 출력이 아니라 목록 원문을 따로 읽어 대조한다. 편집 규칙은
# .claude/rules/banned-words.md 에, 이 저장소 문서를 금지 표현 검사에서 빼는 사유는 hooks/_spec_marker.sh 의
# path_in_own_repo 주석에 있다.
BANSRC="$HERE/korean-banned-words.md"
BANEVD="$HERE/skills/lens-readability/banned-words-evidence.md"
. "$HERE/hooks/_banned_words.sh"
BANPROG='
import io, re, sys
lst, evd, pairs = sys.argv[1:4]
L = io.open(lst, encoding="utf-8").read().splitlines()
E = io.open(evd, encoding="utf-8").read().splitlines()
P = io.open(pairs, encoding="utf-8").read().splitlines()
out = []
head = [l for l in L if l.startswith("| 쓰지 않는 말")]
rows = [l for l in L if l.startswith("| `")]
if not head:
    out.append("행 형식\t표 머리행이 없다")
else:
    hp = head[0].count("|")
    for r in rows:
        if r.count("|") != hp:
            out.append("행 형식\t세로줄 수가 머리행과 다르다: " + r[:30])
if len(rows) != len(P):
    out.append("행 형식\t표 행 %d개 가운데 훅 파서가 읽은 행 %d개" % (len(rows), len(P)))
seen, firsts = set(), []
for r in rows:
    c = [x.strip() for x in r.strip().strip("|").split("|")]
    if len(c) < 5:
        continue
    toks = [t for t in re.findall(r"`([^`]*)`", c[0]) if t]
    if toks:
        firsts.append(toks[0])
    for t in toks:
        if t in seen:
            out.append("중복\t" + t)
        seen.add(t)
    if c[2] not in ("답변과 산출물", "문서와 답변"):
        out.append("적용 대상\t%s: %s" % (toks[:1], c[2]))
    for e in re.findall(r"`([^`]*)`", c[4]):
        if e and not any(t in e for t in toks):
            out.append("제외어\t%s 가 같은 행의 금지어를 품지 않는다" % e)
off = []
for l in L:
    if l.startswith("꺼 둔 항목은"):
        off = [t for t in re.findall(r"`([^`]*)`", l.split("이고,")[0]) if t]
heads = [m.group(1) for m in (re.match(r"^## `([^`]+)`\s*$", l) for l in E) if m]
for x in sorted((set(firsts) | set(off)) - set(heads)):
    out.append("근거 대응\t근거 절이 없다: " + x)
for x in sorted(set(heads) - set(firsts) - set(off)):
    out.append("근거 대응\t목록에 없는 근거 절: " + x)
start = [i for i, l in enumerate(L) if l.startswith("단어 쌍으로 적을 수 없는")]
rule_n = sum(1 for l in L[start[0]:] if l.startswith("- ")) if start else 0
rule_h = sum(1 for l in E if l.startswith("## 규칙:"))
if rule_n != rule_h:
    out.append("규칙 대응\t규칙 불릿 %d개, 근거 절 %d개" % (rule_n, rule_h))
print("\n".join(out))
'
banlist_issues() {  # $1=목록 파일, $2=근거 파일 → 위반을 "종류<탭>내용" 줄로 낸다
  local w; w="$(mktemp -d)"
  banned_parse "$1" "$w/pairs" "$w/toks" || { echo "행 형식	훅 파서가 실패했다"; return 0; }
  json_run "$BANPROG" "$1" "$2" "$w/pairs"
}
ban_mut() {  # $1=원본, $2=사본, $3=찾을 문자열, $4=바꿀 문자열 → 첫 번째만 바꾼 사본을 쓴다
  json_run 'import io,sys
s = io.open(sys.argv[1], encoding="utf-8").read()
assert sys.argv[3] in s, sys.argv[3]
io.open(sys.argv[2], "w", encoding="utf-8", newline="\n").write(s.replace(sys.argv[3], sys.argv[4], 1))' "$@"
}
echo "[금지 표현] 목록 형식과 근거 대응"
check "목록 파일이 있다"                     "[ -f \"\$BANSRC\" ]"
check "근거 파일이 있다"                     "[ -f \"\$BANEVD\" ]"
check "목록 머리가 원본 저장소를 적는다"      "head -12 \"\$BANSRC\" | grep -qF 'chshin84/disciplined-coder'"
check "목록 머리가 사본을 고치지 말라고 적는다" "head -12 \"\$BANSRC\" | grep -qF '사본'"
check "편집 규칙 파일이 목록 파일 경로에 걸린다" "grep -qF 'korean-banned-words.md' '$HERE/.claude/rules/banned-words.md'"
check "받기 워크플로가 없다"                  "[ ! -e '$HERE/.github/workflows/banned-words-sync.yml' ]"
BANOUT="$(banlist_issues "$BANSRC" "$BANEVD" 2>&1)" || BANOUT="실행 실패	$BANOUT"
for kind in "행 형식" "제외어" "중복" "적용 대상" "근거 대응" "규칙 대응" "실행 실패"; do
  check "실제 목록에 $kind 위반이 없다" "! printf '%s\n' \"\$BANOUT\" | grep -q '^$kind	'"
done
# 자기시험 — 일부러 깨뜨린 사본에서 각 검사가 실제로 위반을 내는지 본다. 이것이 없으면 검사가 늘 빈
# 출력을 내도 통과한다.
BANFX="$(mktemp -d)"; cp "$BANEVD" "$BANFX/evd.md"
ban_fx() {  # $1=찾을 문자열, $2=바꿀 문자열 → 목록 사본을 깨뜨려 위반을 낸다
  ban_mut "$BANSRC" "$BANFX/lst.md" "$1" "$2" && banlist_issues "$BANFX/lst.md" "$BANFX/evd.md"
}
FX_PIPE="$(ban_fx '평소에 쓰지 않는 말 | `판정`' '평소에 쓰지 않는 말 `판정`' 2>&1 || true)"
FX_HASH="$(ban_fx '| `짚` |' $'# 끼어든 줄\n| `짚` |' 2>&1 || true)"
FX_EXCL="$(ban_fx '`판정` · `판단`' '`판정` · `결단`' 2>&1 || true)"
FX_DUP="$(ban_fx '| `짚` |' '| `짚` · `훑` |' 2>&1 || true)"
FX_SCOPE="$(ban_fx '지적 · 언급 | 답변과 산출물' '지적 · 언급 | 답변과 산출' 2>&1 || true)"
FX_OFF="$(ban_fx '`기대를 걸` · ' '' 2>&1 || true)"
FX_RULE="$(ban_fx '- 비유로 설명하지 않는다.' '비유로 설명하지 않는다.' 2>&1 || true)"
ban_mut "$BANEVD" "$BANFX/evd2.md" '## `짚`' '## `짚다`'
FX_EVD="$(banlist_issues "$BANSRC" "$BANFX/evd2.md" 2>&1 || true)"
check "자기시험: 제외 칸 앞 세로줄이 빠지면 행 형식"  "printf '%s\n' \"\$FX_PIPE\"  | grep -q '^행 형식'"
check "자기시험: 표 중간에 # 줄이 끼면 행 형식"      "printf '%s\n' \"\$FX_HASH\"  | grep -q '^행 형식'"
check "자기시험: 제외어가 금지어를 안 품으면 제외어"  "printf '%s\n' \"\$FX_EXCL\"  | grep -q '^제외어'"
check "자기시험: 금지어가 두 행에 있으면 중복"        "printf '%s\n' \"\$FX_DUP\"   | grep -q '^중복'"
check "자기시험: 적용 대상 오타는 적용 대상"          "printf '%s\n' \"\$FX_SCOPE\" | grep -q '^적용 대상'"
check "자기시험: 꺼 둔 이름이 빠지면 근거 대응"       "printf '%s\n' \"\$FX_OFF\"   | grep -q '^근거 대응'"
check "자기시험: 규칙 불릿이 빠지면 규칙 대응"        "printf '%s\n' \"\$FX_RULE\"  | grep -q '^규칙 대응'"
check "자기시험: 근거 절 제목이 바뀌면 근거 대응"     "printf '%s\n' \"\$FX_EVD\"   | grep -q '^근거 대응'"
```

- [ ] **Step 2: 편집 규칙 파일과 근거 절이 없으니 검사가 실패하는지 본다**

이 단계에서는 `.claude/rules/banned-words.md` 가 아직 없고 받기 워크플로도 남아 있다.

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep -E '^ *FAIL' | head`
Expected: `편집 규칙 파일이 목록 파일 경로에 걸린다` 와 `받기 워크플로가 없다` 가 FAIL 이다. `실제 목록에 … 위반이 없다` 와 자기시험 여덟 개는 통과한다. 실제 목록에서 위반이 나오면 Task 1·2 를 되짚는다.

- [ ] **Step 3: 받기 워크플로를 지운다**

Run: `git rm -q .github/workflows/banned-words-sync.yml`

- [ ] **Step 4: 편집 규칙 파일을 만든다**

먼저 Claude Code 문서(https://code.claude.com/docs/en/memory 의 `.claude/rules/` 절)에서 경로 한정 규칙의 frontmatter 키가 `paths` 인지 확인한다. 다르면 문서의 키를 쓰고 그 사실을 보고에 적는다. 이 파일도 대구 한도 검사 대상이므로 "A가 아니라 B" 형태를 한 번만 쓴다.

```markdown
---
paths:
  - "korean-banned-words.md"
  - "skills/lens-readability/banned-words-evidence.md"
---

# 금지 표현 목록 편집 규칙

`korean-banned-words.md` 가 금지 표현 목록의 원본이다. 이 파일은 모든 PC 의 `~/.claude/CLAUDE.md` 에 사본으로 실리고, 훅 `hooks/_banned_words.sh` 가 표를 파싱해 다른 프로젝트 산출물의 쓰기를 거부한다. 항목마다의 근거는 `skills/lens-readability/banned-words-evidence.md` 에 있다.

## 형식

`### 금지 표현` 제목과 첫 줄 `# 한국어 금지어 목록` 을 바꾸지 않는다. 표의 칸은 금지어·대체어·적용 대상·분류·제외 순서이고, 새 칸은 맨 뒤에만 추가한다. 적용 대상 칸에는 `답변과 산출물` 이나 `문서와 답변` 만 쓴다.

## 항목을 넣고 고칠 때

- **근거:** 행을 넣거나 끄거나 첫 금지어를 바꾸면 근거 파일의 `` ## `첫 금지어` `` 절도 같은 커밋에서 고친다.
- **어간:** 한글은 음절이 한 글자이므로 활용형마다 어간을 적는다. 어간이 다른 말에 들어가면 그 말을 제외 칸에 적는다.
- **측정:** 항목을 넣기 전에 실제 빈도와 거짓 검출을 센다.

## 항목을 끌 때

적용 대상별 말뭉치에서 만자당 0.15 미만인 항목은 끈다. 근거 종류가 `user` 인 항목은 빈도 때문에 끄지 않는다. 다른 항목과 검출이 겹치는 항목과 검토 뒤 기각한 후보도 끈다.

끄는 항목은 표에서 빼고 "꺼 둔 항목" 줄에 이름을 옮긴다. 근거 파일의 그 절에는 끈 사유와 날짜와 다시 켤 때의 표 칸을 적는다. 목록은 세션마다 실리므로 행이 늘면 그만큼 컨텍스트 비용이 된다.

## 커밋 전

목록 파일이나 근거 파일을 고치면 커밋 전에 저장소 `CLAUDE.md` 「변경 뒤 실행」 명령을 실행한다. main 은 보호되지 않았고 플러그인은 main 커밋으로 배포되므로, 형식이 틀린 표는 CI 가 알리기 전에 모든 PC 에 들어간다.
```

- [ ] **Step 5: 대구 한도에서 근거 파일을 뺀다**

855-857행을 아래로 바꾼다.

```bash
# 금지 표현 목록과 근거 파일은 뺀다. 목록은 분류 설명이, 근거 파일은 고쳐 쓰지 않는 사용자 원문 인용이
# 대구를 포함한다. 그 문장을 대구 한도에 맞추면 목록의 설명이나 근거의 원문이 달라진다.
ANTI_DOCS="$(printf '%s\n' "$AUDIT_DOCS" | grep -v -e '^korean-banned-words.md$' -e '^skills/lens-readability/banned-words-evidence.md$')"
```

- [ ] **Step 6: 전체 검사를 실행한다**

Run: 저장소 `CLAUDE.md` 「변경 뒤 실행」 명령
Expected: `ALL PASS`. 다른 검사가 근거 파일이나 편집 규칙 파일을 문서로 보고 실패하면, 그 검사가 무엇을 요구하는지 읽고 파일 쪽을 맞춘다. 사용자 원문 인용을 고쳐야만 통과하는 검사라면 멈추고 보고한다.

- [ ] **Step 7: 커밋**

```bash
git add scripts/test_docs_drift.sh .claude/rules/banned-words.md
git commit -q -F - <<'EOF'
금지 표현 목록 검사를 원문 대조로 바꾸고 받기 워크플로를 지우며 편집 규칙을 경로 한정 규칙으로 둔다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

### Task 4: 측정 스크립트에서 버전 표시와 근거 파일 다루기

**Files:**
- Modify: `scripts/check_banned_words.sh:36-45`

**Interfaces:**
- Consumes: Task 1 의 근거 파일 경로
- Produces: 버전 표시 줄이 없는 측정 출력

- [ ] **Step 1: 지금 출력을 본다**

Run: `bash scripts/check_banned_words.sh | head -3`
Expected: 첫 줄이 `목록: 버전 표시 없음` 이다(Task 2 에서 버전 표시를 지웠으므로). 근거 파일이 검출 목록에 나오는지도 본다.

- [ ] **Step 2: 36-45행을 고친다**

```bash
# 대상은 살아 있는 문서다. 기록과 설계 문서는 찍은 뒤 고치지 않거나 보존 목적이라 뺀다. 목록 파일은
# 표가 그 낱말을 이름으로 적고, 근거 파일은 그 낱말과 사용자 원문을 인용하므로 뺀다.
git ls-files '*.md' \
  | grep -v '^docs/superpowers/' \
  | grep -v -e '^korean-banned-words.md$' -e '^skills/lens-readability/banned-words-evidence.md$' \
  > "$W/files"

N="$(wc -l < "$W/files" | tr -d ' ')"
echo "대상: 살아 있는 문서 ${N}개 / 적용 대상: ${WANT:-전부}"
```

- [ ] **Step 3: 다시 실행한다**

Run: `bash scripts/check_banned_words.sh | head -3; bash scripts/check_banned_words.sh | grep -c banned-words-evidence || true`
Expected: 첫 줄이 `대상: …` 이고 마지막 값이 `0` 이다.

- [ ] **Step 4: 커밋**

```bash
git add scripts/check_banned_words.sh
git commit -q -F - <<'EOF'
금지 표현 측정에서 버전 표시 출력을 지우고 근거 파일을 측정 대상에서 뺀다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

### Task 5: 옛 원본을 전제한 문장 고치기

**Files:**
- Modify: `README.md:3`
- Modify: `skills/lens-readability/domain-korean.md` 「금지 표현의 근거」 첫 문단, 302행, 335행
- Modify: `skills/lens-fit/domain-discipline.md` `EDIT-DISCIPLINE` 절 첫 문장 둘
- Modify: `hooks/_banned_words.sh:2-3`, `hooks/doc_word_pretooluse.sh:37-38`, `hooks/_spec_marker.sh:65-67`

**Interfaces:**
- Consumes: Task 1·3 의 파일 경로
- Produces: 없음(문장 수정)

- [ ] **Step 1: 고칠 줄을 다시 뽑는다**

Run: `grep -rn "KiwoomAX/korean-banned-words\|banned-words-sync\|생성물\|원본 저장소\|외부 저장소\|사내 저장소" --include=*.md --include=*.sh --include=*.yml . | grep -v '^./docs/superpowers/' | grep -v '^./skills/lens-readability/banned-words-evidence.md'`
Expected: 아래 단계의 줄들이 나온다. 목록에 없는 줄이 나오면, 옛 저장소를 지금의 원본으로 말하는 현재 시제 문장인지 본다. 그렇다면 같은 방식으로 고치고, 과거 경위를 적은 문장이면 둔다.

- [ ] **Step 2: README 3행**

`한국어 금지 표현 목록을 모든 세션에 싣고 사내 저장소를 목록의 원본으로 가리킨다.` 를
`한국어 금지 표현 목록을 모든 세션에 싣는다. 목록의 원본은 이 저장소의 \`korean-banned-words.md\` 다.` 로 바꾼다(백슬래시 없이 백틱).

- [ ] **Step 3: domain-korean.md**

「금지 표현의 근거」 첫 문단의 앞 두 문장(`목록의 원본은 KiwoomAX/… @import 로 싣는다.`)을 아래로 바꾸고, 「목록을 스킬에 두지 않는 이유는」부터는 그대로 둔다.

```markdown
목록의 원본은 이 저장소 루트의 `korean-banned-words.md` 이고, 항목마다의 근거는 같은 디렉터리의
`banned-words-evidence.md` 가 소유한다. `scaffold.sh` 가 목록 파일을 `~/.claude/disciplined-coder/` 에
복사하고, `~/.claude/CLAUDE.md` 의 관리블록이 그 사본을 `@import` 로 싣는다.
```

302행의 `그 목록은` 으로 시작해 `생성물이라 여기서 고치지 않는다.` 로 끝나는 문장을 지운다(301행 끝 `그 목록은` 과 302행에 걸쳐 있다). 335행의 `원본이 항목을 추가하거나 빼면` 을 `목록 파일에 항목을 추가하거나 빼면` 으로 바꾼다.

- [ ] **Step 4: domain-discipline.md `EDIT-DISCIPLINE`**

`` `korean-banned-words.md` 는 머리에 생성물이라고 적는데, 손으로 고치면 그 수정은 다음 동기화 때 조용히 사라진다. `` 를 아래로 바꾼다.

```markdown
`korean-banned-words.md` 는 머리에 사본을 고치지 말라고 적는데, `~/.claude/disciplined-coder/` 사본을
손으로 고치면 그 수정은 다음 세션에 원본으로 덮여 조용히 사라진다.
```

- [ ] **Step 5: 훅 주석**

`hooks/_banned_words.sh` 2-3행:
```bash
# 공유 헬퍼: 「금지 표현」 표를 한 번 읽어 여러 파일로 낸다. 그 표는 에이전트원칙이 아니라
# korean-banned-words.md 에 있고, 그 파일이 목록의 원본이다.
```
`hooks/doc_word_pretooluse.sh` 37-38행:
```bash
# 표는 에이전트원칙이 아니라 목록 파일 korean-banned-words.md 에 있다. 에이전트원칙에는 포인터만 남는다.
```
`hooks/_spec_marker.sh` 65-67행에서 `표를 외부 저장소가 소유하고 하루 한 번` `동기화되므로, ` 를 지워 아래가 되게 한다.
```bash
# 영구로 정했고 위반이 있었다는 통지도 남기지 않기로 했다. 낱말이 추가되면 이 저장소의 문서가
# 아무것도 안 했는데 편집이 거부된다. 표와 근거를
```
줄바꿈 위치는 주변 주석 폭에 맞춰 조정한다.

- [ ] **Step 6: 남은 참조를 확인한다**

Run: Step 1 명령
Expected: 남은 줄이 없거나, 과거 경위를 적은 문장뿐이다. 남긴 줄은 보고에 적는다.

- [ ] **Step 7: 전체 검사와 커밋**

Run: 저장소 `CLAUDE.md` 「변경 뒤 실행」 명령. Expected: `ALL PASS`.

```bash
git add README.md skills/lens-readability/domain-korean.md skills/lens-fit/domain-discipline.md hooks/_banned_words.sh hooks/doc_word_pretooluse.sh hooks/_spec_marker.sh
git commit -q -F - <<'EOF'
옛 저장소를 금지 표현 원본으로 전제한 문장을 이 저장소의 목록 파일과 근거 파일로 고친다

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

### Task 6: 메모리와 최종 확인

**Files:**
- Modify(git 밖): `C:\Users\ho381\.claude\projects\D--projects-Structure-disciplined-coder\memory\dc-banned-words-check-off.md` 의 **Why:** 첫 문장

**Interfaces:**
- Consumes: Task 1-5 의 결과
- Produces: 병합 준비가 된 브랜치

- [ ] **Step 1: 메모리의 이유 문장을 고친다**

`금지어 표를 외부 저장소 \`KiwoomAX/korean-banned-words\` 가 소유하고 워크플로가 하루 한 번 받아 온다.` 를
`금지어 표에 낱말이 추가될 수 있다(2026-10-06부터 원본은 이 저장소의 \`korean-banned-words.md\` 다).` 로 바꾼다(백슬래시 없이 백틱). 그 뒤 문장은 둔다.

- [ ] **Step 2: 훅 파싱 행 수를 확인한다**

Run: Task 2 Step 1 명령. Expected: Task 2 에서 적은 행 수와 같다.

- [ ] **Step 3: 전체 검사와 플러그인 검증**

Run: 저장소 `CLAUDE.md` 「변경 뒤 실행」 명령, 그다음 `claude plugin validate ./`
Expected: `ALL PASS`, 그리고 `version` 경고 하나.

- [ ] **Step 4: 병합 직전 확인 목록을 보고에 적는다**

병합 직전에 Task 1 Step 1 명령을 다시 실행해 옛 저장소 HEAD 가 `5b02378` 인지 확인한다. 이번에는 `diff` 대상이
바뀐 목록 파일이므로 `git show <Task 1 이전 커밋>:korean-banned-words.md` 와 옛 `dist` 를 비교한다. 병합 뒤 kw-plugins
세션에 병합 커밋 해시를 보내고, writing-html-reports 세션에 `checks/common.py` 의 `~/.claude/kw-ax/` 대체 경로가
kw-control-tower 사본 삭제 뒤 쓰이지 않는다는 사실을 알린다. 이 두 메시지는 병합을 사용자가 정한 뒤에 보낸다.

<!-- spec-review: passed -->
