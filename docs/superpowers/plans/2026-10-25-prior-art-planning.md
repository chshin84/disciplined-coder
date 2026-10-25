# 선행연구 계획 수립과 탐색 방식 개선 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 프로토콜에 `intended_use`·`constraints`를 추가하고, 둘러보기 실행(`round` 0)과 contrast·survey·scout 연구자 지시문을 넣는다.

**Architecture:** 워크플로 `workflows/prior-art-search.js`가 `round`로 분기한다. 0 이면 연구자 하나를 `MODE: scout`로 실행하고 바로 반환하며, 1·2 이면 현행 흐름에 새 칸만 넘긴다. 키 이름의 원본은 계약 코드 `scripts/prior_art_contract.json`이다. 에이전트 정의의 예시 블록은 `test_prior_art_contract.sh`가 계약과 대조한다. 스킬 `SKILL.md`의 예시 블록은 대조하는 기계 검사가 없으므로 구현자가 같은 글자로 맞춘다.

**Tech Stack:** JavaScript(워크플로 런타임), bash 검사 스크립트, Python 식 단언(`json_true`), Markdown 스킬·에이전트 정의.

**Spec:** `docs/superpowers/specs/2026-10-25-prior-art-planning-design.md`

## 용어

네 축은 근거 지도 행의 `axes`(목적·메커니즘·평가·적용 대상)다. 공백 라운드는 커버리지 공백이 남은 하위 질문만 다시 탐색하는 `round` 2 실행이다.

## Global Constraints

- 새 프로토콜 칸 이름은 `intended_use`(문자열, 빈 값 불가)와 `constraints`(문자열 배열, 빈 배열 허용)다.
- `purpose`라는 칸 이름은 쓰지 마라.
- 둘러보기는 `round: 0`이고, 첫 탐색은 1, 공백 라운드는 2 다.
- 둘러보기 프롬프트 모드는 `scout`, 호출 label 은 `scout`, phase 는 `'Research'`다.
- `round` 0 반환값의 키 차례는 `round`, `researchers`, `query_violations`, `scout`다.
- 근거 지도 행의 새 칸은 `?bearing`(문자열), 종합 결론의 새 칸은 `?supports`(문자열)다.
- `bearing`과 `supports`는 검증 단계 입력에 넣지 마라.
- 둘러보기 원본 이름은 `search-r0.json`, `researcher-scout-r0.json`이다.
- 둘러보기 연구자의 도구 호출 상한은 10 이다(spec 「C. 먼저 둘러보기」, Anthropic 글의 "Simple fact-finding requires just 1 agent with 3-10 tool calls").
- 상한 값(연구자 통상 2·최대 20, `maxTurns` 20, 공백 라운드 1회, 판정 묶음 20)은 바꾸지 마라.
- 검사 계약은 FAIL=0 이고, 기대 개수를 숫자로 박지 마라.
- 새로 쓰는 한국어 문장은 저장소 `agent-principles.md`의 「출력」 절과 「작업 지시서」 절을 따르라.

## Review Focus

- 둘러보기 연구자가 응답하지 않거나 예외로 끝나면, `round` 0 실행은 예외 없이 `scout: null`을 반환해야 한다.
- 둘러보기 검색어에 금지어가 있으면 `query_violations`에 `id: "scout"`로 기록되어야 한다.
- 둘러보기 연구자가 정해진 칸 밖의 칸(예: `evidence_map`)을 내면 스키마가 그 칸을 허용하지 않아야 한다.
- survey 행에 `bearing`이 있으면 종합 입력 `passed_rows`의 행에 그대로 남고, 판정 입력의 `text`에는 들어가지 않아야 한다.
- `round` 0 실행은 `subquestions`가 비어 있어도 둘러보기 연구자 하나만 실행해야 한다.

---

### Task 1: 새 칸 전달과 계약

**Files:**
- Modify: `scripts/prior_art_contract.json` (`args`, `researcher.?evidence_map[]`, `synthesis.conclusions[]`)
- Modify: `workflows/prior-art-search.js:25-33` (탐색 입력), `:110-114` (종합 입력), `schemas()`의 `RESEARCHER_SCHEMA`·`SYNTHESIS_SCHEMA`
- Modify: `agents/prior-art-researcher.md` (출력 예시 블록 `researcher`·`synthesis`, 「explore 모드」·「synthesize 모드」의 입력 형식 문장)
- Modify: `skills/agent-prior-art/SKILL.md` (출력 예시 블록 `researcher`·`synthesis`, 「키 이름과 바깥 형식」 표의 args·연구자·종합 행, 「에이전트에게 보내는 프롬프트」의 탐색·종합 입력)
- Test: `scripts/test_workflow.sh`

**Interfaces:**
- Produces: 탐색 입력 `{ question, situation, target, mode, subquestion, forbidden_terms, intended_use, constraints }`, 종합 입력 `{ question, target, intended_use, constraints, passed_rows }`.
- Produces: `mkin <응답표> <출력> [args 파일]` — 셋째 인자가 있으면 그 파일을 args 로 읽고, 없으면 `$FX/args_c.json`을 읽는다.

- [ ] **Step 1: 실패하는 검사를 써라**

`test_workflow.sh`의 `args_c.json`에 `"intended_use": "U", "constraints": ["K"]`를 추가하라. `mkin`에 선택 셋째 인자(args 파일 경로)를 추가하라. 이 인자는 Task 2 가 쓴다.

`E_RC_EXP`의 키 집합을 `{"question","situation","target","mode","subquestion","forbidden_terms","intended_use","constraints"}`로 바꾸고, `b["intended_use"] == "U" and b["constraints"] == ["K"]`를 추가하라. `E_RS_SYN`의 키 집합을 `{"question","target","intended_use","constraints","passed_rows"}`로 바꾸고, `b["intended_use"] == "U" and b["constraints"] == ["K"]`를 추가하라.

`row.json`에 `"bearing": "B0"`를 추가하라. survey 흐름에 아래 단언을 추가하라.

```python
all("B0" not in x["text"] for c in d["calls"] if c["label"].startswith("judge:") for it in block(c, "judge")["items"] for x in it["claims"])
```

- [ ] **Step 2: 검사가 실패하는지 확인하라**

Run: `bash scripts/test_workflow.sh 2>&1 | grep FAIL:`
Expected: 탐색 프롬프트 단언과 종합 호출 단언이 FAIL 로 나온다.

- [ ] **Step 3: 계약과 워크플로와 예시 블록을 고쳐라**

계약 `args`에 `"intended_use": true, "constraints": true`를, `researcher.?evidence_map[]`에 `"?bearing": true`를, `synthesis.conclusions[]`에 `"?supports": true`를 추가하라. 워크플로의 탐색 입력 객체와 종합 입력 객체에 `intended_use: args.intended_use, constraints: args.constraints`를 추가하라.

`RESEARCHER_SCHEMA`의 근거 지도 행에 `bearing`을, `SYNTHESIS_SCHEMA`의 결론에 `supports`를 `required` 밖의 문자열 칸으로 추가하라. 연구자 정의와 SKILL.md 의 `researcher`·`synthesis` 예시 블록에 `"bearing": "그 근거가 어느 후보안을 어느 방향으로 움직이는지"`와 `"supports": "지지하는 후보안"`을 같은 글자로 넣어라.

- [ ] **Step 4: 검사가 통과하는지 확인하라**

Run: `bash scripts/test_workflow.sh && bash scripts/test_prior_art_contract.sh && bash scripts/test_docs_drift.sh`
Expected: 각 스크립트가 `FAIL=0`.

- [ ] **Step 5: 커밋하라**

```bash
git add scripts/prior_art_contract.json workflows/prior-art-search.js agents/prior-art-researcher.md skills/agent-prior-art/SKILL.md scripts/test_workflow.sh
git commit -m "선행연구 프로토콜에 intended_use·constraints 를 추가하고 탐색·종합 입력에 넘긴다"
```

### Task 2: 둘러보기 실행(round 0)

**Files:**
- Modify: `workflows/prior-art-search.js` (본문 머리의 `round` 분기, `schemas()`에 `SCOUT_SCHEMA`)
- Modify: `scripts/prior_art_contract.json` (`scout`, `result_scout`)
- Test: `scripts/test_workflow.sh` (새 묶음 「실행 흐름: scout」, 루트 required 검사), `scripts/test_prior_art_contract.sh` (200행 상수 목록과 짝 목록에 `SCOUT_SCHEMA`)

**Interfaces:**
- Consumes: Task 1 의 args 칸과 `mkin` 셋째 인자.
- Produces: 둘러보기 입력 `{ question, situation, target, intended_use, constraints, draft_subquestions, forbidden_terms }`.
- Produces: 둘러보기 출력 `{ search_status, queries, clusters: [{ topic, sources: [string], note }], subquestion_candidates: [{ scope, basis }], principles_applied }`, 반환값 `{ round: 0, researchers: [{ id: "scout", output }], query_violations, scout }`.

- [ ] **Step 1: 실패하는 검사를 써라**

`$FX/args_s.json`을 만들어라. 내용은 `args_c.json`에 `"round": 0`을 덮어쓴 값이다. `$FX/args_s0.json`은 거기에 `"subquestions": []`를 더 덮어쓴 값이다.

「실행 흐름: scout」 묶음의 응답표는 아래와 같다.

```json
{"@mode": "contrast", "responses": {
  "scout": {"search_status": "ok", "queries": ["Acme x", "y"], "clusters": [], "subquestion_candidates": [], "principles_applied": []}}}
```

`mkin "$FX/rsc_resp.json" "$FX/rsc_in.json" "$FX/args_s.json"`로 입력을 만들어 실행하고, 아래 단언을 확인하라. `block`과 `call`은 기존 `PY_WRAP_HEAD`·`PY_WRAP_TAIL`로 감싸라.

```python
[c["label"] for c in d["calls"]] == ["scout"] and d["calls"][0]["phase"] == "Research" and d["calls"][0]["agentType"] == "disciplined-coder:prior-art-researcher"
set(block(call("scout")[0], "scout")) == {"question","situation","target","intended_use","constraints","draft_subquestions","forbidden_terms"} and block(call("scout")[0], "scout")["draft_subquestions"] == [{"id": "S1", "scope": "a", "include": ["i"], "exclude": []}, {"id": "S2", "scope": "b", "include": [], "exclude": ["e"]}]
list(d["result"].keys()) == [k.lstrip("?") for k in C["result_scout"]] and d["result"]["round"] == 0 and d["result"]["researchers"][0]["id"] == "scout"
d["result"]["query_violations"] == [{"id": "scout", "query": "Acme x", "rule": "forbidden-term"}]
```

`"scout": null` 응답표로는 `d["result"]["scout"] is None`을 확인하라. `args_s0.json`으로는 `[c["label"] for c in d["calls"]] == ["scout"]`를 확인하라.

스키마 검사로는 `test_workflow.sh`에 `SCOUT_SCHEMA` 루트 required 검사와 `d["SCOUT_SCHEMA"]["additionalProperties"] is False` 검사를 추가하라. `test_prior_art_contract.sh` 200행의 상수 목록과 211행 부근의 짝 목록에는 `SCOUT_SCHEMA`·`scout:SCOUT_SCHEMA`를 추가하라.

- [ ] **Step 2: 검사가 실패하는지 확인하라**

Run: `bash scripts/test_workflow.sh 2>&1 | grep FAIL: ; bash scripts/test_prior_art_contract.sh 2>&1 | grep FAIL:`
Expected: Step 1 에서 추가한 검사가 모두 FAIL 로 나온다.

- [ ] **Step 3: 분기를 구현하라**

본문의 `phase('Research')` 앞에 `args.round === 0` 분기를 두어라. 분기 안에서는 둘러보기 연구자를 연구자 호출과 같은 형태 `(await parallel([() => agent(prompt('scout', …), { agentType: RESEARCHER, label: 'scout', phase: 'Research', schema: S.SCOUT_SCHEMA })]))[0] ?? null`로 실행하라. 이 형태를 쓰는 이유는 `parallel`이 예외를 `null`로 바꾸기 때문이다.

분기는 `researchers = [{ id: 'scout', output }]`를 만들고 `checkQueries(researchers, args.forbidden_terms)`를 거쳐 반환하라. 검증·종합·coverage 계산 함수에는 닿지 않게 하라. `SCOUT_SCHEMA`는 루트와 `clusters`·`subquestion_candidates` 원소에 `additionalProperties: false`를 둔다. 계약에는 `scout`(출력 칸)와 `result_scout`(`round`, `researchers`, `query_violations`, `scout`)를 추가하라.

- [ ] **Step 4: 검사가 통과하는지 확인하라**

Run: `bash scripts/test_workflow.sh && bash scripts/test_prior_art_contract.sh`
Expected: 각 스크립트가 `FAIL=0`.

- [ ] **Step 5: 커밋하라**

```bash
git add workflows/prior-art-search.js scripts/prior_art_contract.json scripts/test_workflow.sh scripts/test_prior_art_contract.sh
git commit -m "선행연구 워크플로에 둘러보기 실행(round 0)을 추가한다"
```

### Task 3: 연구자 지시문

**Files:**
- Modify: `agents/prior-art-researcher.md` (「공통」의 모드 목록, 새 「scout 모드」 절과 출력 예시 블록 `scout`, 「explore 모드」를 contrast·survey 지시문으로 분리, 「synthesize 모드」)
- Modify: `skills/agent-prior-art/SKILL.md` 「레퍼런스 프롬프트」 (contrast 는 첫 `- system:` 줄, survey 는 `- system (survey):` 줄, scout 는 `- system (scout):` 줄)
- Test: `scripts/test_docs_drift.sh:960-961` 부근, `scripts/test_prior_art_contract.sh` (예시 짝 목록)

**Interfaces:**
- Consumes: Task 1·2 의 입력·출력 칸 이름.

- [ ] **Step 1: 실패하는 검사를 써라**

`test_docs_drift.sh`의 레퍼런스 프롬프트 대조 옆에 검사를 추가하라. 「레퍼런스 프롬프트」 절의 `- system (survey): "` 줄 본문과 `- system (scout): "` 줄 본문이 각각 연구자 정의에 글자 그대로 있는지 확인하는 검사다. `test_prior_art_contract.sh`의 예시 짝 목록에는 `scout:RD`를 추가하라.

- [ ] **Step 2: 검사가 실패하는지 확인하라**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep FAIL: ; bash scripts/test_prior_art_contract.sh 2>&1 | grep FAIL:`
Expected: Step 1 에서 추가한 검사가 모두 FAIL 로 나온다.

- [ ] **Step 3: contrast 지시문과 scout 지시문을 써라**

contrast 지시문은 현행 문장에서 survey 분기 문장("입력의 `mode`가 `survey`이면 …")을 빼라. 이어서 "입력의 `intended_use`와 `constraints`를 읽고, `constraints`의 기각한 대안과 이미 확인한 자료는 다시 찾아 보고하지 마라."를 추가하라.

scout 지시문에는 탐색 방법을 넣지 마라. 목표(주제의 자료 묶음과 하위 질문 후보 찾기), 출력 칸, 경계(질의 금지, 도구 호출 10회 이하)만 넣어라.

- [ ] **Step 4: survey 지시문을 써라**

survey 지시문에는 spec 「D. 연구자의 탐색」의 survey 목록 항목과 탐색 전술 목록을 모두 넣어라. contrast 지시문에 넣은 `constraints` 문장도 survey 지시문에 그대로 넣어라.

인용 따라가기 전술은 snowballing 이라는 이름으로도 알려져 있다. 그 전술을 넣기 전에 Wohlin, EASE 2014 "Guidelines for snowballing in systematic literature studies"를 WebFetch 로 열어 확인하라. 열지 못하면 survey 지시문의 인용 따라가기 항목 끝에 "(출처 미확인)"을 붙여라.

- [ ] **Step 5: 종합 지시문을 고쳐라**

종합 지시문에 아래 규칙을 넣어라.

- `intended_use`에 비추어 결론을 써라.
- 결정 근거 탐색이면 결론마다 지지하는 후보안을 `supports`에 적어라.
- 결론에 쓴 행의 축 차이를 결론 문장에 함께 적어라.
- 축이 모두 `same: false`인 행을 결론의 단독 근거로 쓰지 마라.

- [ ] **Step 6: 검사가 통과하는지 확인하라**

Run: `bash scripts/test_docs_drift.sh && bash scripts/test_prior_art_contract.sh`
Expected: 각 스크립트가 `FAIL=0`.

- [ ] **Step 7: 커밋하라**

```bash
git add agents/prior-art-researcher.md skills/agent-prior-art/SKILL.md scripts/test_docs_drift.sh scripts/test_prior_art_contract.sh
git commit -m "선행연구 연구자 지시문을 contrast·survey·scout 로 나눈다"
```

### Task 4: 오케스트레이터 절차와 기록 규칙

**Files:**
- Modify: `skills/agent-prior-art/SKILL.md` (아래 Step 1~3 의 절)
- Modify: `skills/review-docs/SKILL.md` 「기록 파일 이름 규칙」
- Modify: `skills/review-specs/SKILL.md` 「`prior-art` 기록에 적을 것」
- Test: `scripts/test_docs_drift.sh`

**Interfaces:**
- Consumes: Task 1~3 의 칸 이름과 반환값 형식. 구현자는 그 이름을 문장에 그대로 써라.

- [ ] **Step 1: 프로토콜과 1단계를 고쳐라**

「프로토콜 항목」에 `intended_use`·`constraints`를 추가하라. 1단계에는 spec 「A. 프로토콜의 내용」과 「B. 프로토콜의 합의」의 규칙을 옮겨라. 옮길 규칙은 칸 도출과 사용자 발언·추론 구분 표시, 금지 목록 펼치기와 실행 직전 대조, 재승인과 승인 판정 기준, 승인별 기록이다.

1단계의 **확인**은 아래 문장으로 바꿔라.

"기록 파일에 승인마다 프로토콜 전문 또는 바뀐 칸과 승인 사실이 있고, 질의 금지 목록의 식별 낱말은 범주와 개수로만 적혀 있다."

- [ ] **Step 2: 둘러보기 단계와 그 영향을 받는 절을 고쳐라**

1단계와 2단계 사이에 둘러보기 단계를 추가하라. 내용은 spec 「C. 먼저 둘러보기」다. 둘러보기 출처를 이미 확인한 자료로 보지 않는다는 규칙을 반드시 넣어라.

「원본 파일 규칙」에는 실행 차례 0 과, 원본을 쓰기 전에 `query_violations[].query`·연구자 `queries`의 금지 낱말을 범주 이름으로 가리는 규칙을 추가하라. 「세션이 끊긴 때」에는 둘러보기 검색어가 이미 나갔다는 사실을 기록에 적게 하라. 3단계에는 공백 라운드가 둘러보기를 다시 실행하지 않고 같은 `intended_use`·`constraints`를 넘긴다는 문장을 추가하라. 「세는 대상」에는 둘러보기 연구자를 상한에 세지 않는다는 문장을 추가하라.

「워크플로가 꺼진 환경」에는 두 문장을 추가하라. 첫째 문장은 오케스트레이터가 둘러보기를 `subagent_type: disciplined-coder:prior-art-researcher`, `MODE: scout`로 실행한다는 내용이다. 둘째 문장은 그 경로의 질의 경계 검사도 오케스트레이터가 한다는 내용이다.

- [ ] **Step 3: 상황별 전략과 출력 스키마를 고쳐라**

「상황별 전략」 표의 「하위 질문 분해」 열 머리를 「하위 질문 분해(기본값)」로 바꿔라. 「판정 규약」에는 survey 에서 체크리스트를 강제하지 않고 축이 다른 행도 근거로 넣는다는 예외를 추가하라.

「출력 스키마」 머리 문단의 예시 블록 목록에 `scout`를 추가하고, 둘러보기 출력 예시 블록(연구자 정의의 `scout` 블록과 같은 글자)을 넣어라. 「워크플로 반환값」과 「키 이름과 바깥 형식」 표에는 `round` 0 반환값 행과 둘러보기 출력 행을 추가하라. 「에이전트에게 보내는 프롬프트」의 모드 값에 `scout`를, 입력 형식에 둘러보기 입력을, label 목록에 `scout`를 추가하라.

- [ ] **Step 4: review-docs 와 review-specs 를 고쳐라**

review-docs 의 r<n> 정의 문장을 "이름의 `r<n>`은 실행 차례이며 둘러보기가 0, 첫 탐색이 1, 공백 라운드가 2다."로 바꿔라. 그 표에는 `| 둘러보기 워크플로 반환값 | search-r0.json |`과 `| 둘러보기 연구자 출력 | researcher-scout-r0.json |`을 추가하라.

review-specs 의 「`prior-art` 기록에 적을 것」 끝에 아래 문장을 추가하라.

"질의 금지 목록의 식별 낱말(사람 이름 등)은 `agent-prior-art` 1단계대로 범주 이름과 개수만 적는다."

- [ ] **Step 5: 전체 검사와 플러그인 검증을 실행하라**

Run: `d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi; claude plugin validate ./`
Expected: `ALL PASS`와 `Validation passed`.

- [ ] **Step 6: 커밋하라**

```bash
git add skills/agent-prior-art/SKILL.md skills/review-docs/SKILL.md skills/review-specs/SKILL.md
git commit -m "선행연구 오케스트레이터 절차에 용도·재승인·둘러보기와 식별 낱말 기록 규칙을 추가한다"
```

### Task 5: 문서 대조 확인

**Files:**
- 읽기만: `D:\projects\Structure\disciplined-coder\docs\superpowers\reviews\2026-10-24-review-checklist-prior-art.md`, 세션 기록 `~/.claude/projects/D--projects-Structure-disciplined-coder/75d7bf26-8409-4cb4-b3ae-500d82f66435.jsonl`

- [ ] **Step 1: 10-24 프로토콜을 새 규칙으로 다시 써 보라**

결과는 파일로 남기지 말고 완료 보고에 적어라. 완료 보고에도 금지 목록의 식별 낱말은 범주와 개수로만 적어라.

사용자의 13:18·13:24 발언 내용이 `intended_use`에, "비개발자"와 CheckEval·TICK 이 `constraints`에 들어가는지 확인하라. 이어서 사용자의 13:18 발언을 spec 「B. 프로토콜의 합의」의 승인 판정 기준에 비추어 보라. 그 발언이 실행을 말한 메시지가 아니므로 승인으로 분류되지 않는지 확인하라.

질의 금지 목록을 spec 「A. 프로토콜의 내용」의 규칙으로 펼쳐 보고, 펼친 목록에 범주 문자열이 남지 않는지 확인하라.

- [ ] **Step 2: 지시문 규칙이 들어갔는지 확인하라**

Run: `grep -c "단독 근거" agents/prior-art-researcher.md; grep -c "축이 다른 행" agents/prior-art-researcher.md skills/agent-prior-art/SKILL.md; grep -c "이미 확인한 자료로 보지 않는다" skills/agent-prior-art/SKILL.md`
Expected: 모든 출력이 1 이상.

- [ ] **Step 3: 실사용 확인 항목을 완료 보고에 남겨라**

완료 보고에 spec 「확인 방법」 8 을 다음 실사용 실행의 확인 항목으로 적어라. 확인 항목은 사용자가 용도를 다시 설명했는지와 승인 턴 수가 늘었는지다.

<!-- spec-review: passed -->
