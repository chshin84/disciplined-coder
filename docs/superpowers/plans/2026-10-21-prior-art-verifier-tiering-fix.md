# 선행연구 검증자 재측정 뒤 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 구성 전체 재측정에서 확인된 참 기각 원인을 고친다. 판정을 충분성 판단과 판정으로 나누고, 정보 부족은 원문 보충으로, 판단 곤란은 Opus 로 보낸다. 그 뒤 새 구성만 다시 측정해 병합 여부를 정한다.

**Architecture:** 판정 에이전트는 칸마다 `정보 부족` 을 낼 수 있다. 워크플로는 `정보 부족` 이 있는 주장을 추출 검증자에게 다시 보내 원문에서 빠진 요소를 찾게 한다(`refetch:`). 이어서 보충된 구절로 판정 에이전트를 한 번 더 실행한다(`rejudge:`). `판정 불가` 가 있는 주장은 Opus 5.5 medium 상향 판정 에이전트로 보낸다(`escalate:`). 최종 판정은 지금처럼 `mergeStages` 가 정한다. 재측정은 새 구성만 두 번 실행하고, 기준선은 앞 재측정의 실행을 다시 쓴다.

**Tech Stack:** JavaScript(워크플로, node 시험 도구), bash 테스트, Python 3 하네스, Claude Code CLI 2.1.305.

**Spec:** `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md`(「재측정 뒤 수정」과 「충분성 판단과 두 갈래 상향」 포함)

## 용어

- **앞 plan:** `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-implement.md` 다. 맞힘·틀리게 확신함·오류 통과·참 기각의 뜻은 앞 plan 「용어」 와 같다.
- **결정 기록 3·4:** `docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition-3.md` 와 `-4.md` 다.
- **보충:** `정보 부족` 이 있는 주장을 추출 검증자가 원문에서 다시 찾는 단계다. 이 plan 에서 새로 붙인 이름이다.

## Global Constraints

- 모델과 노력 수준: 추출 검증자·판정 에이전트·지도 대조 에이전트는 `model: claude-haiku-5-5`, `effort: high`. 상향 판정 에이전트는 `model: claude-opus-5-5`, `effort: medium`.
- 도구: 추출 검증자는 `WebFetch, Read`, 판정·상향 판정·지도 대조 에이전트는 `Read`.
- 판정 칸의 값은 `일치`·`불일치`·`판정 불가`·`정보 부족` 이다. `정보 부족` 인 칸마다 `missing` 에 없는 요소를 적는다. `판정 불가` 인 칸마다 `unsure_reasons` 에 이유 유형(`맥락 부족`·`조건 얽힘`·`표·그림 값`·`언어 해석`)을 적는다.
- 판정 입력은 `{ url, claims: [{ ref, text, quote, context, source_note }] }` 다. `source_note` 는 그 주장에 대한 추출 출력의 `reason` 이고, 없으면 빈 문자열이다. 재판정·상향 판정 입력도 같은 형식이다.
- 보충 입력은 `{ url, claims: [{ ref, text, missing }] }`(MODE `refetch`)이고, 출력은 추출 출력과 같은 형식이다.
- 보충은 주장마다 한 번만 한다. 재판정에서도 `정보 부족` 이면 그 주장은 검증 실패다. 상향 판정에서도 `판정 불가` 면 그 주장은 검증 실패다.
- 인용 판정 기준("옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported")은 바꾸지 마라.
- 반환값의 바깥 키는 바꾸지 마라. `verifiers[].stages` 에 `refetch`·`rejudge` 를 추가한다.
- 병합 조건(spec 「채택 규칙」): 구성 전체의 `total_cost_usd` 가 기준선보다 낮다. 그리고 기준선이 두 실행 모두에서 맞힌 항목은 새 구성의 최종 `verdict` 도 두 실행 모두에서 맞힌다. 기준선은 `evals/prior-art-verifier/results-v2/runs.jsonl` 의 두 실행이다.
- main 병합과 push 는 사용자 승인을 받은 뒤에만 하라.
- 결정 기록은 기록 타입이다. 이미 있는 결정 기록은 고치지 말고 새 파일로 적어라.
- 실행 조건은 결정 기록 3 과 같다(`--setting-sources "" --strict-mcp-config --disable-slash-commands --no-session-persistence`, `--settings '{"disableAllHooks":true}'`, 실행 폴더 `D:/dc-eval-tmp` 아래, 자식 환경에서 `CLAUDE_CODE_EFFORT_LEVEL` 제거).

## Review Focus

- 보충 단계가 응답하지 않을 때: 그 URL 은 검증 실패여야 한다. 그 주장의 `정보 부족` 이 일치로 새면 안 된다. Task 1 의 `보충 실패는 URL 검증 실패다` 가 고정한다.
- 한 주장에 `정보 부족` 칸과 `판정 불가` 칸이 함께 있을 때: 보충과 재판정을 먼저 하고, 재판정에 남은 `판정 불가` 만 상향한다. Task 1 의 `정보 부족과 판정 불가가 함께면 보충 뒤 상향한다` 가 고정한다.
- 재판정이 `일치`·`불일치` 칸을 처음 판정과 다르게 낼 때: 재판정은 그 주장의 모든 칸을 새로 판정하므로 재판정의 값을 쓴다. Task 1 의 `재판정은 그 주장의 칸을 모두 대체한다` 가 고정한다.
- 운영 워크플로와 하네스가 다른 입력을 만들 때: 재측정이 운영을 대표하지 못한다. Task 2 의 `test_def_prompt_matches_workflow` 가 `refetch:`·`rejudge:`·`escalate:` 프롬프트까지 대조한다.
- 추출 정의 수정으로 오류 항목이 통과할 때: 보고는 카테고리별 오류 통과를 둘째 병합 조건과 따로 적어야 한다. Task 2 의 보고가 고정한다.

---

### Task 1: 판정 형식·보충·상향 구조

**Files:**
- Modify: `workflows/prior-art-search.js`(`judgeClaims`, 보충·재판정 단계, `mergeStages`·`mergeUrl`)
- Modify: `agents/prior-art-verifier.md`, `agents/prior-art-judge.md`, `agents/prior-art-judge-escalation.md`, `agents/prior-art-mapcheck.md`
- Modify: `scripts/prior_art_contract.json`, `scripts/test_workflow.sh`, `scripts/test_prior_art_contract.sh`, `scripts/test_docs_drift.sh`
- Modify: `skills/agent-prior-art/SKILL.md`

**Interfaces:**
- Produces: label 규약 `extract:<url>`, `judge:<url>`, `refetch:<url>`, `rejudge:<url>`, `escalate:<url>`, `map-check`. `refetch:` 의 agentType 은 `disciplined-coder:prior-art-verifier`, `rejudge:` 는 `disciplined-coder:prior-art-judge` 다.
- Produces: `mergeStages(refsByUrl, extract, judge, refetch, rejudge, escalation)`. 인자와 반환값은 URL 을 키로 둔 일반 객체다. 반환값은 `{ outputs, stages }` 이고 `stages[url]` 은 `{ extract, judge, refetch, rejudge, escalation }` 이다. 실행하지 않은 단계는 `null` 이다.
- Produces: 주장마다의 판정 차례. 처음 판정에 `정보 부족` 이 있으면 보충 출력의 구절로 재판정하고, 재판정 결과가 그 주장의 판정을 모두 대체한다. 그다음 `판정 불가` 칸만 상향 판정으로 바꾼다. 이어서 spec 「최종 판정과 실패 처리」 4·5번을 적용한다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`scripts/test_workflow.sh` 에 `harn fn mergeStages` 와 `harn run` 으로 아래 검사를 추가한다.
- `판정 입력에 source_note 가 있다`: `judge:` 호출 입력의 claims 마다 `source_note` 가 추출 출력의 `reason` 과 같다.
- `reason 없는 추출은 빈 source_note 다`
- `정보 부족은 보충으로 보낸다`: `refetch:` 호출 입력에 그 주장과 `missing` 이 있고, `rejudge:` 가 보충 구절로 실행된다.
- `정보 부족이 없으면 보충을 부르지 않는다`
- `보충 실패는 URL 검증 실패다`
- `재판정도 정보 부족이면 그 주장만 검증 실패다`
- `재판정은 그 주장의 칸을 모두 대체한다`
- `판정 불가는 Opus 상향으로 보낸다`: `escalate:` 호출의 agentType 이 `disciplined-coder:prior-art-judge-escalation` 이다.
- `정보 부족과 판정 불가가 함께면 보충 뒤 상향한다`
- 기존 검사 중 상향 관련 기대식은 새 판정 차례에 맞게 고친다.

`scripts/test_docs_drift.sh` 의 정의 검사는 상향 판정 정의의 `model: claude-opus-5-5`, `effort: medium` 을 본다. 판정 정의와 상향 판정 정의의 본문 동일 검사는 유지한다. `scripts/test_prior_art_contract.sh` 는 계약의 `judge` 자료(네 값과 `missing`)와 `refetch` 입력 예시를 정의 파일의 출력 예시와 대조한다.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash scripts/test_workflow.sh 2>&1 | grep -E "FAIL|PASS="; bash scripts/test_prior_art_contract.sh 2>&1 | tail -1; bash scripts/test_docs_drift.sh 2>&1 | grep FAIL`
Expected: 새 검사와 고친 기대식이 FAIL 이다.

- [ ] **Step 3: 정의를 고친다**

- `prior-art-judge.md` 와 `prior-art-judge-escalation.md` 에 같은 문단 세 개를 추가하거나 고친다.
  - 칸마다 먼저 판정에 필요한 정보가 구절과 `context` 에 있는지 판단하라. 없으면 그 칸을 `정보 부족` 으로 두고, 없는 요소를 `missing` 에 적어라.
  - 정보가 있는 칸만 `일치`·`불일치` 를 내라. 정보는 있으나 판단이 어려우면 `판정 불가` 를 내라.
  - 출처의 제목·저자·학회·변수 이름은 추출 검증자가 확인했다. 그 확인 사유가 `source_note` 다. 출처의 정체를 판정 대상으로 삼지 말고 수치·조건·방향·범위만 판정하라.
- 상향 판정 정의의 frontmatter 를 `model: claude-opus-5-5`, `effort: medium` 으로 바꾼다.
- `prior-art-verifier.md` 의 구절 지시에 아래 두 문단을 추가한다.
  - 주장의 수치·조건·결론이 든 문장을 `quote` 에 그대로 옮겨라. 한 문장에 그 요소가 모두 없으면 가장 가까운 문장을 옮기고, 없는 요소를 `context` 에 적어라.
  - 첫 줄이 `MODE: refetch` 이면 주장마다 `missing` 의 요소가 든 문장을 원문에서 찾아 `quote` 에 옮겨라. 출력 형식은 추출 출력과 같다.
- `prior-art-mapcheck.md` 에 판정할 칸 목록(행마다 `case`, `outcome`, 축마다 `prior`)을 적고, 출력 예시도 이 칸을 모두 포함하게 고친다.

- [ ] **Step 4: 워크플로와 SKILL.md 를 고친다**

Verify 단계는 추출 → 판정 → 보충(`정보 부족` 이 있는 URL 만) → 재판정 → 상향(`판정 불가` 가 있는 URL 만) 순서로 실행한다. 각 단계는 URL 마다 `parallel` 로 실행한다. SKILL.md 는 「워크플로가 꺼진 환경」·「반환값을 읽는 규칙」·「상태 값」·「실행할 때 지킬 상한」·「에이전트에게 보내는 프롬프트」·「출력 스키마」를 새 차례에 맞게 고친다. 상한은 URL 마다 추출 1~2, 판정 1~2, 상향 0~1 이다.

- [ ] **Step 5: 검사가 통과하는지 확인한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령, `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`

- [ ] **Step 6: 커밋한다**

```bash
git add workflows agents scripts skills
git commit -m "판정을 충분성 판단과 판정으로 나누고 정보 부족은 보충, 판단 곤란은 Opus 로 보낸다"
```

### Task 2: 새 구성 재측정

**Files:**
- Modify: `evals/prior-art-verifier/run.py`(`refetch-def`·`rejudge-def` 단계, `_judge_claims` 의 `source_note`, `escalate-def` 의 모델)
- Modify: `evals/prior-art-verifier/replay.py`, `score.py`(`report-v3`), `harness_tests.py`, `run_tests.sh`, `README.md`
- Create: `evals/prior-art-verifier/results-v3/`(실행 결과)
- Create: `docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition-5.md`

**Interfaces:**
- Consumes: Task 1 의 정의·label·입력 형식·`mergeStages` 서명.
- Produces: `python -I evals/prior-art-verifier/score.py report-v3 --baseline results-v2/runs.jsonl --runs results-v3/runs-def.jsonl --replay results-v3/replay.json --out results-v3/report.md`. 보고 내용은 앞 plan 의 `report-v2` 와 같다. 여기에 보충·상향을 거친 항목과 그 결과, 남은 `정보 부족`·`판정 불가` 의 `missing`·이유 유형·사유 문장을 추가한다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`harness_tests.py` 에 아래 테스트를 추가한다.
- `test_def_prompt_matches_workflow` 를 넓혀 `refetch:`·`rejudge:`·`escalate:` 프롬프트도 `harn run` 기록과 대조한다.
- `test_replay_passes_refetch_and_rejudge`: 가짜 단계 출력으로 replay 가 `mergeStages` 의 새 인자를 채운다.
- `test_report_v3_uses_given_baseline`: 인자로 준 기준선 파일로 병합 조건을 계산한다.
- `test_report_v3_lists_remaining_unsure`: 남은 `정보 부족`·`판정 불가` 항목과 사유가 보고에 있다.

- [ ] **Step 2: 실행해 실패를 확인하고 구현해 통과시킨다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: 처음 FAIL, 구현 뒤 `FAIL=0`.

- [ ] **Step 3: 새 구성을 두 번 실행하고 재생한다**

- `extract-def`·`judge-def`(Haiku high)를 `--repeat 2` 로 `results-v3/runs-def.jsonl` 에 실행한다.
- `정보 부족` 이 있는 주장만 `refetch-def`(Haiku high)와 `rejudge-def`(Haiku high)로 실행한다.
- `판정 불가` 가 남은 주장만 `escalate-def`(Opus medium)로 실행한다.
- `map-def`(Haiku high)를 `--repeat 2` 로 실행한다.
- `replay.py --runs results-v3/runs-def.jsonl --repeat 2 --out results-v3/replay.json` 로 최종 판정을 만든다.

예상 비용은 약 $1~2 다. 지출이 $5 를 넘을 것 같으면 실행을 멈추고 보고하라.

- [ ] **Step 4: 보고를 만들고 병합 조건을 판정한다**

Run: Interfaces 의 `report-v3` 명령
Expected: `results-v3/report.md` 에 병합 조건 두 가지의 충족 여부, 기준선이 맞힌 항목 중 새 구성이 틀린 항목 목록, 카테고리별 오류 통과·참 기각, 보충·상향 비율과 결과, 단계별 비용이 있다.

- [ ] **Step 5: 결정 기록 5 를 쓰고 커밋한다**

결정 기록 5 에 아래를 적는다.
- 재측정 결과와 병합 조건 판정
- 결정 기록 4 의 실패 13건 각각이 이번에 맞았는지
- 보충과 Opus 상향이 각각 몇 주장에서 실행되었고 결과가 어땠는지
- 새로 틀린 항목과 그 원인, 오류 통과 수

결정은 적지 말고 사실만 적어라. 원인을 확인하지 못한 문장에는 가정이라고 밝혀라.

```bash
git add evals/prior-art-verifier docs/superpowers/decisions
git commit -m "충분성 판단 구성의 재측정 결과와 결정 기록 5 를 추가한다"
```

- [ ] **Step 6: 사용자에게 병합 여부를 묻는다**

병합 조건을 모두 채웠으면 결정 기록 5 를 보이고 main 병합 승인을 받아라. 하나라도 못 채웠으면 병합하지 말고, 못 채운 조건과 틀린 항목을 보인 뒤 다음 설계를 사용자에게 물어라.
