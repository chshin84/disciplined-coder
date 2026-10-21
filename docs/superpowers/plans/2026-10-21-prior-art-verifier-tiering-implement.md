# 선행연구 검증자 단계 분리 구현과 재측정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 선행연구 검증 단계를 추출·판정·상향 판정·지도 대조 에이전트로 나눠 Haiku 5.5 high 중심으로 바꾸고, 어려운 항목을 넣은 자료로 구성 전체를 다시 측정해 병합 여부를 정한다.

**Architecture:** 에이전트 정의 네 개가 단계를 맡는다. 최종 `verdict` 는 워크플로 스크립트의 새 함수 `mergeStages` 가 spec 「최종 판정과 실패 처리」 순서로 정한다. 반환값의 바깥 형식은 바꾸지 않는다. 재측정은 `evals/prior-art-verifier/run.py` 가 각 단계를 실제 모델로 실행하고, `replay.py` 가 그 출력을 `harn fn mergeStages` 에 넣어 최종 판정을 얻는다. 그래서 측정과 운영은 합치기 코드와 단계 입력 블록을 함께 쓴다. 실행 방식은 다르다. 운영은 에이전트 정의를 agentType 으로 실행하고, 재측정은 정의 본문을 `claude -p` 의 system 프롬프트로 넣는다. 이 차이는 Task 4 의 frontmatter 확인 단계가 따로 확인한다.

**Tech Stack:** JavaScript(워크플로, node 시험 도구), bash 테스트, Python 3 하네스, Claude Code CLI 2.1.305.

**Spec:** `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md`(「확정 구성과 판정 불가 상향」과 「채택 규칙」 포함)

## 용어

- **첫 plan:** `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-selection.md` 다.
- **결정 기록 2:** `docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition-2.md` 다.
- **맞힘:** 최종 `verdict` 가 정답과 같은 항목이다. 참 항목은 `supported`, 오류 항목은 `supported` 가 아닌 값이 정답이다.
- **판정 불가로 넘김:** 판정 에이전트가 한 칸 이상에 `판정 불가` 를 내 상향 판정 에이전트로 넘어간 항목이다.
- **틀리게 확신함:** 판정 에이전트가 모든 칸에 `일치`·`불일치` 를 냈는데, 그 칸들로 정한 판정이 정답과 반대인 항목이다. 상향 전 Haiku 출력으로 센다. 병합 조건이 아니며 결정 기록에 적는 관찰값이다.
- **오류 통과·참 기각:** 첫 plan 과 같다. 최종 `verdict` 기준으로 오류 항목이 `supported` 이면 오류 통과, 참 항목이 `supported` 가 아니면 참 기각이다.

## Global Constraints

- 모델과 노력 수준: 추출 검증자·판정 에이전트·지도 대조 에이전트는 `model: claude-haiku-5-5`, `effort: high`. 상향 판정 에이전트는 `model: claude-sonnet-5-5`, `effort: high`. 사용자가 Haiku 5.5 를 지정했으므로 별칭(`haiku`) 대신 전체 모델 ID 를 쓴다.
- 에이전트 이름: 추출 검증자는 spec 「바뀌는 파일」 대로 기존 `prior-art-verifier` 정의를 바꿔 쓴다. 새 정의는 `prior-art-judge`, `prior-art-judge-escalation`, `prior-art-mapcheck` 다.
- 도구: 추출 검증자는 `WebFetch, Read`, 판정·상향 판정·지도 대조 에이전트는 `Read`.
- `MODE:` 값: 추출 `extract`, 판정 `judge`, 상향 판정 `judge`, 지도 대조 `map`.
- `match` 값은 `일치`·`불일치`·`판정 불가` 다. 판정 불가 이유 유형은 `맥락 부족`·`조건 얽힘`·`표·그림 값`·`언어 해석` 이고, 판정 불가인 칸마다 하나를 붙인다.
- 반환값의 바깥 키(`passed`·`rejected`·`unverifiable`·`verify_failed`·`verifiers`·`verifier_count`·`map_check` 등)는 바꾸지 마라. `verifiers[].stages` 만 새로 둔다.
- 병합 조건(spec 「채택 규칙」): 구성 전체의 `total_cost_usd` 가 기준선보다 낮다. 그리고 기준선이 두 실행 모두에서 맞힌 항목은 새 구성의 최종 `verdict` 도 두 실행 모두에서 맞힌다.
- main 병합과 push 는 사용자 승인을 받은 뒤에만 하라.
- 하네스 테스트 파일 이름은 `test_*.sh` 가 아닌 이름으로 지어라.

## Review Focus

- 판정 에이전트가 `판정 불가` 를 냈는데 상향 판정 에이전트가 응답하지 않을 때: 그 URL 은 검증 실패여야 하고 `supported` 로 새면 안 된다. Task 2 의 `mergeStages` 검사 `상향 판정 실패는 URL 검증 실패다` 가 고정한다.
- 상향 판정 에이전트도 `판정 불가` 를 낸 주장: 그 주장만 검증 실패이고, 같은 URL 의 다른 주장 판정은 남아야 한다. Task 2 의 `상향 판정 불가는 그 주장만 검증 실패다` 가 고정한다.
- 판정 에이전트가 한 주장의 카테고리 칸 하나를 빠뜨릴 때: 빠진 칸을 일치로 보면 오류가 통과한다. Task 2 의 `카테고리 칸 누락은 URL 검증 실패다` 가 고정한다.
- 옛 `MODE: cite` 프롬프트가 추출 검증자에 들어올 때: 추출 검증자는 판정 없이 빈 `judgments` 를 돌려줘 그 URL 이 검증 실패로 드러나야 한다. Task 2 Step 3 의 정의 문단과 계약 검사가 고정한다.
- 정의 파일의 frontmatter `model` 이 실행에 적용되지 않을 때: 서브에이전트가 부모 모델을 물려받아 비용과 성적이 재측정과 달라진다. Task 4 의 frontmatter 확인 단계가 `modelUsage` 로 확인한다. `effort` 는 CLI 출력에 없어 확인하지 못한다는 사실을 결정 기록에 적는다.

---

### Task 1: 재측정 자료

**Files:**
- Create: `evals/prior-art-verifier/cases-v2.json`
- Modify: `evals/prior-art-verifier/build_cases.py`
- Modify: `evals/prior-art-verifier/check_cases.py`
- Modify: `evals/prior-art-verifier/run_tests.sh`

**Interfaces:**
- Consumes: 첫 plan 의 `cases.json` 형식.
- Produces: `cases-v2.json`. 형식은 `cases.json` 과 같고, `Item` 에 선택 칸 `hard_kind` 를 추가한다. 값과 그 항목의 `category` 는 아래 대응을 따른다.

| `hard_kind` | 뜻 | `category` |
|---|---|---|
| `context` | 초록과 본문의 결론이 다른 출처 | `direction` |
| `conditions` | 조건이 둘 이상 붙은 결과 | `numbers_conditions` |
| `table` | 수치가 표에만 있는 출처 | `numbers_conditions` |
| `korean` | 한국어 원문 | `direction` |
| `fake-200` | WebFetch 가 HTTP 200 으로 받지만 실제 문서가 없는 주소 | `access` |

- Produces: `python -I evals/prior-art-verifier/build_cases.py <search-r1.json> <cases.json> --v2 <cases-v2.json>`.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`run_tests.sh` 에 아래 검사를 추가한다.
- `cases-v2.json` 이 `check_cases.py` 를 통과한다. `check_cases.py` 는 카테고리마다 참·오류 수가 같은지를 지금처럼 본다.
- `check_cases.py` 는 `hard_kind` 값이 위 표의 다섯 값 중 하나이고 `category` 가 표와 같은지 본다.
- `hard_kind` 마다 참 항목과 오류 항목이 1건씩 있다.
- `num-t3` 의 `truth` 가 `false` 이고 `check_note` 에 결정 기록 2 의 정정 이유가 있다.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: FAIL(`cases-v2.json` 이 없다)

- [ ] **Step 3: 자료를 만든다**

- `num-t3` 를 오류 항목으로 바꾸고, `check_note` 에 "주장이 원문의 '다중 비교 보정 뒤' 조건을 빠뜨렸고, 1,650 과 결과가 서로 다른 문장에 있다(결정 기록 2)" 를 적는다.
- `numbers_conditions` 참 항목을 두 건 추가해 참·오류를 4건씩 맞춘다. 한 건은 arXiv 2605.10039 의 "measuring compliance with a trivial target annotation across 1,650 Claude Code CLI sessions" 한 문장으로 뒷받침되는 주장이다. 다른 한 건은 구현자가 원문에서 직접 확인한 수치 주장이다.
- 어려운 항목은 `hard_kind` 마다 참 1건과 오류 1건을 만든다. 출처는 구현자가 찾되, 아래 조건을 모두 채워라.
  - `context`: 오류 항목은 초록만 보면 맞아 보이는 주장이다.
  - `conditions`: 오류 항목은 조건 하나만 넓힌 주장이다.
  - `table`: 오류 항목은 표의 다른 행 값을 쓴 주장이다.
  - `korean`: 오류 항목은 결말을 뒤집은 주장이다.
  - `fake-200`: 구현자는 WebFetch 로 열어 200 과 내용 없음을 확인한 뒤 넣어라. 참 항목은 같은 사이트의 실제 문서다.
- 어려운 항목마다 구현자가 원문을 직접 열어 확인한 내용을 `check_note` 에 적어라. 오류 항목에는 원문의 다른 구절이 그 주장을 뒷받침하지 않는다는 확인도 적어라.

- [ ] **Step 4: 검사가 통과하는지 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: `FAIL=0`

- [ ] **Step 5: 커밋한다**

```bash
git add evals/prior-art-verifier
git commit -m "검증자 재측정 자료(num-t3 정정, 어려운 항목)를 추가한다"
```

### Task 2: 에이전트 정의·스키마·워크플로 합치기

**Files:**
- Modify: `agents/prior-art-verifier.md`
- Create: `agents/prior-art-judge.md`, `agents/prior-art-judge-escalation.md`, `agents/prior-art-mapcheck.md`
- Modify: `workflows/prior-art-search.js`(`mergeStages` 추가, `classify` 의 주장 단위 검증 실패 처리)
- Modify: `scripts/workflow_harness.mjs`(`FN_NAMES` 에 `mergeStages` 추가)
- Modify: `scripts/prior_art_contract.json`
- Modify: `scripts/test_workflow.sh`, `scripts/test_prior_art_contract.sh`, `scripts/test_docs_drift.sh`

**Interfaces:**
- Produces: 추출 입력 `{ url, claims: [{ ref, text }] }`(MODE `extract`). 추출 출력 `{ url, judgments: [{ ref, access: "성공"|"실패", exists: "일치"|"불일치", quote, context, reason }], principles_applied }`.
- Produces: 판정 입력 `{ url, claims: [{ ref, text, quote, context }] }`(MODE `judge`). 상향 판정 입력은 같은 형식이고, 판정 불가가 있는 주장만 넣는다.
- Produces: 판정 출력 `{ judgments: [{ ref, numbers_conditions, direction, scope, unsure_reasons, reason }], principles_applied }`. 세 카테고리 칸의 값은 `일치`·`불일치`·`판정 불가` 다. `unsure_reasons` 는 판정 불가인 칸 이름을 키로, 이유 유형을 값으로 둔 객체이고 판정 불가가 없으면 `{}` 다. 상향 판정 출력도 같은 형식이다.
- Produces: 워크플로 함수 `mergeStages(refsByUrl: {[url]: string[]}, extract: {[url]: object|null}, judge: {[url]: object|null}, escalation: {[url]: object|null}) -> { outputs: {[url]: {url, judgments:[{ref, verdict, quote, reason}], principles_applied}|null}, stages: {[url]: {extract, judge, escalation}} }`. 인자와 반환값은 모두 일반 객체다. `harn fn` 이 JSON 으로 주고받기 때문이다. `outputs[url]` 이 `null` 이면 그 URL 은 검증 실패다. 주장 하나만 검증 실패이면 그 판정의 `verdict` 가 `verify_failed` 다. `escalation` 에 키가 없는 URL 은 상향을 실행하지 않은 URL 이다.
- Produces: `classify` 는 `verdict` 가 `verify_failed` 인 판정을 받으면 그 주장을 `verify_failed` 에 `{ url, refs: [ref] }` 로 넣고, 같은 URL 의 다른 판정은 지금처럼 분류한다.
- Produces: 워크플로 label 규약 `extract:<url>`, `judge:<url>`, `escalate:<url>`, `map-check`.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`scripts/test_workflow.sh` 에 `harn fn mergeStages` 로 아래 검사를 추가한다. 입력은 고정 JSON 이다.
- `추출 출력이 없으면 URL 검증 실패다`: 추출이 `null` 이거나 한 ref 를 빠뜨리면 `outputs[url]` 이 `null`.
- `access 실패는 unverifiable 이다`
- `exists 불일치는 unsupported 다`
- `quote 없는 주장은 판정에 보내지 않는다`: 그 주장은 `unsupported` 이고, `harn run` 의 `judge:` 호출 입력에 없다.
- `카테고리 칸 누락은 URL 검증 실패다`: 판정에 `direction` 칸이 없으면 `outputs[url]` 이 `null`.
- `불일치가 하나라도 있으면 unsupported 다`
- `상향은 판정 불가 칸만 바꾼다`: 판정이 `방향: 판정 불가`·`범위: 일치`, 상향이 `방향: 일치`·`범위: 불일치` 면 `supported`.
- `상향 판정 실패는 URL 검증 실패다`: 상향 출력이 `null` 이면 `outputs[url]` 이 `null`.
- `상향 판정 불가는 그 주장만 검증 실패다`: 같은 URL 의 다른 주장은 `supported` 로 남고, 그 주장만 `verdict` 가 `verify_failed`.
- `판정 불가가 없으면 상향을 부르지 않는다`: `harn run` 의 호출 목록에 `escalate:` label 이 없다.

`classify` 검사에 `주장 단위 verify_failed 는 그 주장만 뺀다` 를 추가한다.

기존 `harn run` 검사(contrast·survey·실패 혼합 실행)의 응답표 키를 `verify:<url>` 에서 `extract:<url>`·`judge:<url>` 로 바꾸고, `MODE: cite` 블록 기대식을 `MODE: extract`·`MODE: judge` 블록으로 바꾼다. agentType 기대식은 `extract:` 가 `disciplined-coder:prior-art-verifier`, `judge:` 가 `disciplined-coder:prior-art-judge`, `escalate:` 가 `disciplined-coder:prior-art-judge-escalation`, `map-check` 가 `disciplined-coder:prior-art-mapcheck` 다. `verifier_count` 기대값은 지금처럼 인용 판정을 받은 URL 수다.

`scripts/test_prior_art_contract.sh` 는 계약의 `extract`·`judge`·`map` 자료를 각 정의 파일의 출력 예시와 워크플로 스키마에 대조하도록 짝을 바꾸고, `cite` 짝은 지운다. `scripts/test_docs_drift.sh` 의 검증자 정의 검사는 정의 파일 네 개의 `tools`·`model`·`effort`·`maxTurns: 20` 을 본다. 같은 스크립트에 `상향 판정 정의는 판정 정의와 본문이 같다` 를 추가한다. 두 본문의 차이는 상향 문단 하나여야 한다.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash scripts/test_workflow.sh 2>&1 | grep -E "FAIL|PASS=" ; bash scripts/test_prior_art_contract.sh 2>&1 | tail -1; bash scripts/test_docs_drift.sh 2>&1 | grep FAIL`
Expected: 새 검사와 고친 기대식이 FAIL 이다.

- [ ] **Step 3: 정의 파일을 쓴다**

- `prior-art-verifier.md` 를 추출 검증자로 바꾼다. frontmatter 에 `model: claude-haiku-5-5`, `effort: high` 를 추가한다. 본문은 `evals/prior-art-verifier/prompts/extract.md` 를 옮기고, `MODE` 규약과 출력 예시(`<!-- output: extract -->`)를 둔다. 첫 줄이 `MODE: extract` 가 아니면 판정하지 말고 `{ url, judgments: [], principles_applied: [] }` 를 돌려주라는 문단을 둔다.
- `prior-art-judge.md` 는 세 판정 프롬프트(`judge-*.md`)를 한 정의로 합친다. `판정 불가` 와 이유 유형의 정의를 넣는다. 판정 불가는 "이 구절과 context 만으로 일치·불일치를 정할 수 없을 때만" 내라고 적는다.
- `prior-art-judge-escalation.md` 는 판정 정의와 같은 본문에 "판정 에이전트가 판정 불가로 넘긴 주장이다" 한 문단을 추가한다. 모델 외의 frontmatter 는 판정 정의와 같다.
- `prior-art-mapcheck.md` 는 `evals/prior-art-verifier/prompts/map.md` 를 옮긴다.
- 정의 파일 네 개의 `description` 에 "agent-prior-art 절차와 워크플로 disciplined-coder:prior-art-search 에서만 실행한다" 를 둔다.

- [ ] **Step 4: 워크플로와 계약을 고친다**

Verify 단계는 URL 마다 추출을 `parallel` 로 실행한다. 이어서 `quote` 가 있고 `access`·`exists` 가 통과한 주장만 모아 URL 마다 판정을 실행한다. 판정 출력에 `판정 불가` 가 있는 URL 만 그 주장들로 상향을 실행한다. 세 결과를 `mergeStages` 로 합친다. MapCheck 는 `prior-art-mapcheck` 를 쓴다. 계약에 `extract`·`judge` 자료와 `result.verifiers[].stages` 를 추가한다.

- [ ] **Step 5: 검사가 통과하는지 확인한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

- [ ] **Step 6: 커밋한다**

```bash
git add agents workflows scripts
git commit -m "선행연구 검증을 추출·판정·상향 판정·지도 대조로 나눈다"
```

### Task 3: 절차 문서

**Files:**
- Modify: `skills/agent-prior-art/SKILL.md`
- Modify: `README.md`(에이전트 목록이 있을 때)

**Interfaces:**
- Consumes: Task 2 의 정의 이름·label·입력과 출력 형식.

- [ ] **Step 1: 낡은 문서를 잡는 검사를 실행한다**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep FAIL`
Expected: 정의 이름이나 스키마 대조에서 SKILL.md 가 낡았다는 FAIL 이 있거나, FAIL 이 없다.

FAIL 이 있으면 Step 2 에서 그 절도 함께 고쳐라.

- [ ] **Step 2: SKILL.md 를 고친다**

- 「오케스트레이터 절차」의 「워크플로가 꺼진 환경」: `subagent_type` 네 개와 「최종 판정과 실패 처리」 순서를 오케스트레이터가 직접 적용한다는 사실을 적는다. 이 경로의 합치기는 지시 준수에만 기댄다는 사실도 적는다.
- 「반환값을 읽는 규칙」: `verifiers[].stages` 와 주장 단위 `verify_failed` 를 적는다.
- 「상태 값」: 검증 실패에 상향 판정 실패와 상향 판정 불가를 넣는다.
- 「실행할 때 지킬 상한」: 검증자 수는 URL 마다 추출 1, 판정 1, 상향 0~1 이라고 적는다.
- 「출력 스키마」의 「에이전트에게 보내는 프롬프트」 문단: 검증자 모드 값을 `extract`·`judge`·`map` 으로, 입력을 Task 2 Interfaces 의 추출·판정 입력으로 고친다.
- 「출력 스키마」의 추출·판정 출력과 「판정 모델 교체」 문단을 새 구성으로 고친다. 그 문단에서 Typesafe AI 의 Jev 를 다루는 두 문장은 그대로 둔다.
- 「인용 확인」: `quote` 의 출처가 추출 검증자라는 사실을 적는다.

- [ ] **Step 3: 검사가 통과하는지 확인한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령과 `claude plugin validate ./`
Expected: `ALL PASS` 와 `Validation passed`

- [ ] **Step 4: 커밋한다**

```bash
git add skills/agent-prior-art/SKILL.md README.md
git commit -m "선행연구 절차 문서를 검증 단계 분리에 맞춘다"
```

### Task 4: 구성 전체 재측정

**Files:**
- Modify: `evals/prior-art-verifier/run.py`(정의 본문을 system 프롬프트로 읽는 단계 `extract-def`·`judge-def`·`escalate-def`·`map-def` 추가)
- Create: `evals/prior-art-verifier/replay.py`
- Modify: `evals/prior-art-verifier/score.py`, `harness_tests.py`, `run_tests.sh`
- Modify: `evals/prior-art-verifier/README.md`(새 단계·replay.py·`report-v2` 와 이번 plan 을 가리키는 포인터)
- Create: `evals/prior-art-verifier/results-v2/`(실행 결과)

**Interfaces:**
- Consumes: Task 2 의 입력 형식과 `mergeStages`.
- Produces: `-def` 단계의 사용자 메시지는 워크플로가 보내는 프롬프트와 같은 `MODE`·`PRINCIPLES`·입력 블록이다. `judge-def` 의 입력은 그 실행의 `extract-def` 출력에서 만든다. 첫 plan 의 짝 참 항목 구절 대체 규칙은 `-def` 단계에서 쓰지 않는다.
- Produces: `python -I evals/prior-art-verifier/replay.py --cases <cases-v2.json> --runs <runs.jsonl> --repeat <n> --out <replay.json>`. 실행 차례마다 URL 별 단계 출력을 일반 객체로 모아 `harn fn mergeStages` 에 넣고, `classify` 와 같은 규칙으로 항목마다 `{ id, repeat, verdict, judge_raw, escalated }` 를 쓴다.
- Produces: `score.py report-v2` — 병합 조건 두 가지의 충족 여부, 기준선이 맞힌 항목 중 새 구성이 틀린 항목 목록, 카테고리별 오류 통과·참 기각, 어려운 항목의 맞힘·판정 불가로 넘김·틀리게 확신함, 상향 비율, 단계별 비용을 `results-v2/report.md` 에 쓴다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`harness_tests.py` 에 아래 테스트를 추가한다.
- `test_def_prompt_matches_workflow`: 고정 입력으로 `harn run` 이 기록한 `extract:`·`judge:` 호출의 프롬프트가 run.py 의 `-def` 단계 사용자 메시지와 같다.
- `test_replay_uses_workflow_merge`: 가짜 단계 출력으로 replay 가 `mergeStages` 의 판정을 그대로 옮긴다.
- `test_confident_wrong_counted`: 판정 원본이 모든 칸에 `일치`·`불일치` 를 냈고 정답과 반대이면 틀리게 확신함으로 센다.
- `test_merge_condition_item_level`: 기준선이 두 번 맞힌 항목을 새 구성이 한 번이라도 틀리면 둘째 조건이 미충족이고, 기준선이 한 번 틀린 항목은 비교에서 빠진다.

- [ ] **Step 2: 실행해 실패를 확인하고 구현해 통과시킨다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: 처음 FAIL, 구현 뒤 `FAIL=0`.

- [ ] **Step 3: frontmatter 의 모델 적용을 확인한다**

worktree 를 플러그인으로 실은 CLI 에서 판정 정의와 상향 판정 정의를 Agent 도구로 한 번씩 실행한다. 실행 조건은 첫 plan 과 같다(`--setting-sources "" --strict-mcp-config --disable-slash-commands --no-session-persistence`, 실행 폴더 `D:/dc-eval-tmp` 아래).

Run: `claude -p "<고정 판정 입력을 subagent_type disciplined-coder:prior-art-judge 로 실행하라>" --plugin-dir D:/projects/dc-verifier-tier --model claude-sonnet-5-5 --output-format json`(상향 판정 정의는 `--model claude-haiku-5-5` 로 실행한다)
Expected: 판정 정의 실행의 `modelUsage` 에 `claude-haiku-5-5` 가 있고, 상향 판정 정의 실행의 `modelUsage` 에 `claude-sonnet-5-5` 가 있다.

부모와 다른 모델이 `modelUsage` 에 없으면 frontmatter 가 적용되지 않았다. 그때는 재측정을 하지 말고 그 출력을 사용자에게 보여라. 워크플로의 `agent()` 가 agentType 정의를 Agent 도구와 같은 방식으로 적용한다는 전제는 가정으로 결정 기록에 적어라.

- [ ] **Step 4: 기준선을 새 자료로 두 번 실행한다**

Run: `python -I evals/prior-art-verifier/run.py --cases evals/prior-art-verifier/cases-v2.json --out evals/prior-art-verifier/results-v2/runs.jsonl --stage baseline-cite --model claude-opus-5-5 --effort medium --repeat 2`
Expected: 모든 URL 에 오류 없는 줄이 두 개씩 있다.

- [ ] **Step 5: 새 구성을 단계별로 두 번 실행하고 재생한다**

- 추출(`extract-def`, Haiku high)을 `--repeat 2` 로 실행한다. 판정(`judge-def`, Haiku high)은 같은 차례의 추출 출력으로 실행한다.
- 판정 불가가 있으면 그 주장만으로 상향(`escalate-def`, Sonnet high)을 실행한다.
- 지도 대조(`map-def`, Haiku high)를 `--repeat 2` 로 실행한다.
- 어려운 항목에 한해 판정을 Haiku low·medium 으로도 한 번씩 실행한다. 수준별 판정 불가로 넘김과 틀리게 확신함을 결정 기록에 관찰값으로 적는다(2026-10-21 사용자 요청). 이 비교는 병합 판정에 쓰지 않는다.
- `replay.py --repeat 2` 로 최종 판정을 만든다.

- [ ] **Step 6: 보고를 만들고 병합 조건을 판정한다**

Run: `python -I evals/prior-art-verifier/score.py report-v2`
Expected: `results-v2/report.md` 에 병합 조건 두 가지의 충족 여부, 기준선이 맞힌 항목 중 새 구성이 틀린 항목 목록, 상향 비율, 단계별 비용이 있다.

- [ ] **Step 7: 결정 기록 3 을 쓰고 커밋한다**

`docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition-3.md` 에 재측정 결과, 병합 조건 판정, 어려운 항목의 종류별 결과, 수준별 판정 불가 비교, Step 3 의 frontmatter 확인 결과를 적는다. `effort` 적용 값은 CLI 출력에 없어 확인하지 못했다는 사실도 적는다.

```bash
git add evals/prior-art-verifier docs/superpowers/decisions
git commit -m "검증자 구성 전체 재측정 결과와 결정 기록 3 을 추가한다"
```

- [ ] **Step 8: 사용자에게 병합 여부를 묻는다**

병합 조건을 모두 채웠으면 결정 기록 3 을 보이고 main 병합 승인을 받아라. 하나라도 못 채웠으면 병합하지 말고, 못 채운 조건과 틀린 항목을 보인 뒤 다음 설계를 사용자에게 물어라.
