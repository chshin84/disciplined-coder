# 선행연구 검증자 Opus 일괄 판정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 판정과 재판정을 Opus 5.5 medium 의 일괄 호출로 바꾸고 상향 판정 에이전트를 없앤다. 끝까지 판정 불가인 주장은 기각한다. 그 뒤 새 구성만 두 번 측정해 병합 여부를 정한다.

**Architecture:** 추출·보충·지도 대조는 지금처럼 Haiku 5.5 high 가 URL 마다 실행한다. 워크플로는 추출이 모두 끝나면 판정 대상 주장을 URL 별로 묶은 입력 하나를 만들어 판정 에이전트를 한 번 실행한다(label `judge`). 일괄 출력은 URL 별 판정 객체로 나눠 `mergeStages` 에 넘긴다. 보충한 주장도 같은 방식으로 한 번에 재판정한다(label `rejudge`). 재측정은 `cases-v3.json` 으로 새 구성을 두 번 실행하고, 기준선은 앞 재측정의 실행을 다시 쓴다.

**Tech Stack:** JavaScript(워크플로, node 시험 도구), bash 테스트, Python 3 하네스, Claude Code CLI 2.1.305.

**Spec:** `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md`(「Opus 일괄 판정」 포함)

## 용어

- **앞 plan:** `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-fix.md` 다. 보충·재판정·맞힘·틀리게 확신함·오류 통과·참 기각의 뜻은 앞 plan 과 그 앞 plan 의 「용어」 와 같다.
- **일괄 판정:** 모든 URL 의 판정 대상 주장을 입력 하나로 모아 판정 에이전트를 한 번 실행하는 방식이다. 이 plan 에서 새로 붙인 이름이다.
- **결정 기록 5·6:** `docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition-5.md` 와 `-6.md` 다.

## Global Constraints

- 모델과 노력 수준: 추출 검증자·지도 대조 에이전트는 `model: claude-haiku-5-5`, `effort: high`. 판정 에이전트는 `model: claude-opus-5-5`, `effort: medium`. 상향 판정 에이전트 정의(`agents/prior-art-judge-escalation.md`)는 지운다.
- 도구: 추출 검증자는 `WebFetch, Read`, 판정·지도 대조 에이전트는 `Read`.
- 판정 칸의 `match` 값, `missing`, `unsure_reasons`, `source_note`(추출 출력의 `exists_note ?? ''`), 보충 입력·출력 형식은 앞 plan 「Global Constraints」 그대로다.
- 일괄 판정 입력은 `{ items: [{ url, claims: [{ ref, text, quote, context, source_note }] }] }`(MODE `judge`)이다. 출력은 `{ judgments: [{ url, ref, numbers_conditions, direction, scope, missing, unsure_reasons, reason }], principles_applied }` 다. 재판정 입력·출력도 같은 형식이다.
- 판정 차례: 처음 판정에 `불일치` 가 있으면 `unsupported`, 보충은 주장마다 한 번, 보충·재판정 실패와 보충 출력의 `access` 실패·`exists` 불일치는 그 주장만 검증 실패다. 재판정에서도 `정보 부족` 이면 그 주장만 `verify_failed` 다. 끝까지 `판정 불가` 인 칸이 있으면 `unsupported` 이고, 이유 유형을 합친 출력의 `reason` 에 남긴다.
- 일괄 판정이나 일괄 재판정이 응답하지 않으면 그 호출에 넣은 모든 URL 이 검증 실패다. 판정 출력에 어떤 URL 의 주장이 빠졌으면 그 URL 이 검증 실패다.
- 인용 판정 기준("옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported")은 그대로 지켜라.
- 반환값의 바깥 키는 그대로 지켜라. `verifiers[].stages` 의 키는 `extract`·`judge`·`refetch`·`rejudge` 이고 `escalation` 은 지운다. `stages[url].judge` 와 `.rejudge` 에는 일괄 출력 중 그 URL 의 판정만 넣는다.
- 병합 조건(spec 「채택 규칙」): 구성 전체의 `total_cost_usd` 가 기준선보다 낮다. 그리고 기준선이 두 실행 모두에서 맞힌 항목은 새 구성의 최종 `verdict` 도 두 실행 모두에서 맞힌다. 기준선은 `evals/prior-art-verifier/results-v2/runs.jsonl` 의 두 실행이고 `cases-v3.json` 으로 채점한다.
- main 병합과 push 는 사용자 승인을 받은 뒤에만 하라.
- 결정 기록은 기록 타입이다. 이미 있는 결정 기록은 그대로 두고 새 파일로 적어라.
- 측정 실행 조건은 결정 기록 5 와 같다(run.py `build_cmd` 의 플래그, 실행 폴더 `D:/dc-eval-tmp` 아래, 자식 환경에서 `CLAUDE_CODE_EFFORT_LEVEL` 제거).
- 커밋 전에는 검사를 실패 시 멈추는 방식으로 실행하고, 실패한 상태로 커밋하지 마라. `__pycache__` 파일은 커밋하지 마라.

## Review Focus

- 일괄 판정 출력에서 한 URL 의 주장 하나만 빠질 때: 그 URL 만 검증 실패이고 다른 URL 의 판정은 남아야 한다. Task 1 의 `일괄 판정에서 빠진 URL 만 검증 실패다` 가 고정한다.
- 일괄 판정 출력에 입력에 없던 URL 이나 ref 가 섞일 때: 그 판정은 무시되어야 하고 다른 URL 의 판정에 섞이면 안 된다. Task 1 의 `입력에 없던 판정은 쓰지 않는다` 가 고정한다.
- 판정 불가가 남은 주장: `unsupported` 이고 `reason` 에 이유 유형이 있어야 한다. `verify_failed` 로 세면 하위 질문이 `partial` 이 된다. Task 1 의 `판정 불가는 기각이고 이유가 남는다` 가 고정한다.
- 보충할 주장이 없을 때: 일괄 재판정을 실행하지 않아야 한다. Task 1 의 `보충이 없으면 재판정을 부르지 않는다` 가 고정한다.
- 주장 수가 많아 Opus 가 일부를 빠뜨릴 때: 재측정 보고가 판정 누락 수를 적어야 한다. Task 2 의 보고가 고정한다.

---

### Task 1: 일괄 판정 구조

**Files:**
- Modify: `workflows/prior-art-search.js`(Verify 단계의 판정·재판정 호출, 일괄 입력을 만드는 함수, 일괄 출력을 URL 별로 나누는 함수, `mergeStages`·`mergeUrl` 의 상향 제거와 판정 불가 처리, 판정 스키마)
- Modify: `agents/prior-art-judge.md`
- Delete: `agents/prior-art-judge-escalation.md`
- Modify: `scripts/workflow_harness.mjs`(`FN_NAMES` 에 새 함수 추가)
- Modify: `scripts/prior_art_contract.json`, `scripts/test_workflow.sh`, `scripts/test_prior_art_contract.sh`, `scripts/test_docs_drift.sh`
- Modify: `skills/agent-prior-art/SKILL.md`

**Interfaces:**
- Produces: `batchJudgeInput(claimsByUrl: {[url]: claim[]}) -> { items: [{ url, claims }] }`. 주장이 없는 URL 은 넣지 않는다.
- Produces: `splitByUrl(batchOutput: object|null, claimsByUrl) -> {[url]: { judgments, principles_applied }|null}`. `batchOutput` 이 `null` 이면 모든 URL 이 `null` 이다. 입력에 없던 URL 이나 ref 의 판정은 버린다.
- Produces: `mergeStages(refsByUrl, extract, judge, refetch, rejudge)`. 인자와 반환값은 URL 을 키로 둔 일반 객체다. `judge`·`rejudge` 는 `splitByUrl` 의 결과다.
- Produces: label 규약 `extract:<url>`, `judge`, `refetch:<url>`, `rejudge`, `map-check`. `judge`·`rejudge` 의 agentType 은 `disciplined-coder:prior-art-judge` 다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`scripts/test_workflow.sh` 에 `harn fn` 과 `harn run` 으로 아래 검사를 추가하라.
- `판정은 한 번만 부른다`: URL 이 셋이어도 `judge` 호출이 하나이고, 입력 `items` 에 세 URL 이 있다.
- `주장 없는 URL 은 일괄 입력에 넣지 않는다`
- `일괄 판정에서 빠진 URL 만 검증 실패다`
- `입력에 없던 판정은 쓰지 않는다`
- `일괄 판정 실패는 넣은 URL 모두 검증 실패다`: `harn run` 응답표에 `judge` 를 `null` 로 넣는다.
- `보충이 없으면 재판정을 부르지 않는다`
- `재판정은 보충한 주장만 모아 한 번 부른다`
- `판정 불가는 기각이고 이유가 남는다`: 끝까지 `판정 불가` 인 주장의 `verdict` 가 `unsupported` 이고 `reason` 에 이유 유형이 있다.
- `재판정도 정보 부족이면 그 주장만 검증 실패다`
- `상향 호출이 없다`: 호출 목록에 `escalate:` label 이 없다.

아래 기존 검사와 자료도 고쳐라.
- 기존의 `judge:<url>`·`rejudge:<url>`·`escalate:<url>` 응답표 키와 기대식, `E_MG_STAGES` 의 stages 집합은 새 구조에 맞게 바꾼다.
- `prior_art_contract.json` 의 `judge` 자료는 일괄 출력 형식으로 바꾸고, 일괄 입력 예시를 추가하고, `stages` 에서 `escalation` 을 지운다.
- `test_prior_art_contract.sh` 는 위 자료를 판정 정의의 예시 블록과 대조한다.
- `test_docs_drift.sh` 의 정의 검사는 정의 파일 셋(추출·판정·지도 대조)을 보고, 판정 정의가 `model: claude-opus-5-5`, `effort: medium` 인지 본다. 상향 판정 정의와 관련된 검사(본문 동일, frontmatter 동일, `ESC_MARK`)는 지운다.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash scripts/test_workflow.sh 2>&1 | grep -E "FAIL|PASS="; bash scripts/test_prior_art_contract.sh 2>&1 | tail -1; bash scripts/test_docs_drift.sh 2>&1 | grep FAIL`
Expected: 새 검사와 고친 기대식이 FAIL 이다.

- [ ] **Step 3: 판정 정의를 고친다**

- frontmatter 를 `model: claude-opus-5-5`, `effort: medium` 으로 바꾼다.
- 입력이 URL 여러 개의 `items` 라는 사실과 출력 형식을 적고, 예시 블록을 일괄 형식으로 바꾼다.
- 아래 지시를 추가하라. "주장마다 그 주장과 같은 `items` 원소의 구절·맥락만 보고 판정하라. 다른 URL 의 구절을 근거로 쓰지 마라. 입력의 주장마다 판정 하나를 빠짐없이 내라."
- 충분성 판단, 다른 값이면 불일치, 출처 정체를 판정하지 않는다는 기존 지시는 그대로 둔다.
- `agents/prior-art-judge-escalation.md` 를 지운다.

- [ ] **Step 4: 워크플로와 SKILL.md 를 고친다**

Verify 단계는 아래 순서로 실행한다.
1. 추출을 URL 마다 `parallel` 로 실행한다.
2. 판정 대상 주장을 모아 `judge` 를 한 번 실행한다.
3. 보충을 URL 마다 `parallel` 로 실행한다.
4. 보충한 주장이 있으면 `rejudge` 를 한 번 실행한다.
5. 결과를 `mergeStages` 로 합친다.

SKILL.md 에서 아래 절을 새 구조에 맞게 고쳐라.
- 「오케스트레이터 절차」의 탐색 단계 서술과 「워크플로가 꺼진 환경」
- 「반환값을 읽는 규칙」·「상태 값」(판정 불가는 기각)
- 「실행할 때 지킬 상한」(URL 마다 추출 1, 보충 0~1; 실행마다 판정 1, 재판정 0~1)
- 「에이전트에게 보내는 프롬프트」·「출력 스키마」·「판정 모델 교체」
- 「인용 확인」

- [ ] **Step 5: 검사가 통과하는지 확인한다**

Run: `d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; cat "$d/bad"; else echo "ALL PASS"; fi; claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`

- [ ] **Step 6: 커밋한다**

```bash
git add -A workflows agents scripts skills
git commit -m "판정을 Opus 일괄 호출로 바꾸고 상향 판정 에이전트를 없앤다"
```

### Task 2: 일괄 판정 재측정

**Files:**
- Modify: `evals/prior-art-verifier/run.py`(`judge-def`·`rejudge-def` 를 실행 차례마다 일괄 단위 하나로 실행, `escalate-def` 제거)
- Modify: `evals/prior-art-verifier/replay.py`(일괄 출력을 URL 별로 나눠 `mergeStages` 의 새 인자로 넘김)
- Modify: `evals/prior-art-verifier/score.py`(`report-v4`: 상향 대신 판정 누락 수와 판정 불가 기각 수)
- Modify: `evals/prior-art-verifier/harness_tests.py`, `run_tests.sh`, `README.md`
- Create: `evals/prior-art-verifier/results-v4/`(실행 결과)
- Create: `docs/superpowers/decisions/2026-10-22-prior-art-verifier-composition-7.md`

**Interfaces:**
- Consumes: Task 1 의 일괄 입력·출력 형식, `batchJudgeInput`·`splitByUrl`·`mergeStages` 서명. `cases-v3.json`.
- Produces: `judge-def`·`rejudge-def` 의 실행 단위는 실행 차례마다 하나(unit `batch`)다. 입력은 워크플로의 `batchJudgeInput` 과 같은 함수 규칙으로 만든다.
- Produces: `python -I evals/prior-art-verifier/score.py report-v4 --cases evals/prior-art-verifier/cases-v3.json --baseline evals/prior-art-verifier/results-v2/runs.jsonl --runs evals/prior-art-verifier/results-v4/runs-def.jsonl --replay evals/prior-art-verifier/results-v4/replay.json --out evals/prior-art-verifier/results-v4/report.md`. 보고 내용은 `report-v3` 와 같고, 상향 대신 판정 누락 수(입력에 있으나 출력에 없는 주장)와 판정 불가로 기각한 주장, 단계별 비용(판정 호출 비용 포함)을 적는다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`harness_tests.py` 에 아래 테스트를 추가하라.
- `test_def_prompt_matches_workflow` 를 고쳐 `judge`·`rejudge` 일괄 프롬프트를 `harn run` 기록과 대조한다.
- `test_batch_unit_per_repeat`: `judge-def` 와 `rejudge-def` 가 실행 차례마다 실행 단위 하나를 만든다.
- `test_replay_splits_batch`: 가짜 일괄 출력으로 replay 가 URL 별 판정을 `mergeStages` 에 넘기고, 빠진 URL 은 검증 실패가 된다.
- `test_report_v4_counts_missing_judgments`: 판정 누락 수와 판정 불가 기각 수가 보고에 있다.

옛 상향 단계를 기대하는 테스트는 지워라.

- [ ] **Step 2: 실행해 실패를 확인하고 구현해 통과시킨다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: 처음 FAIL, 구현 뒤 `FAIL=0`.

- [ ] **Step 3: 새 구성을 두 번 실행한다**

차례대로 실행하라. 모든 명령에 `--cases evals/prior-art-verifier/cases-v3.json --out evals/prior-art-verifier/results-v4/runs-def.jsonl --repeat 2` 를 붙인다.

Run: `python -I evals/prior-art-verifier/run.py --stage extract-def --model claude-haiku-5-5 --effort high …`, 이어서 `--stage judge-def --model claude-opus-5-5 --effort medium`, `--stage refetch-def --model claude-haiku-5-5 --effort high`, `--stage rejudge-def --model claude-opus-5-5 --effort medium`, `--stage map-def --model claude-haiku-5-5 --effort high`
Expected: 단계마다 실행 대상 단위에 오류 없는 줄이 실행 차례마다 하나씩 있다. `judge-def` 는 실행 차례마다 한 줄이다. 보충 대상이 없는 차례에는 `refetch-def`·`rejudge-def` 의 줄이 없다.

예상 비용은 실행 한 번에 약 $0.5~0.8, 두 번에 약 $1~1.6 이다. 추출 비용은 앞 재측정의 실측이고, Opus 판정 비용은 상향 한 건의 실측에 기댄 가정이다. 지출이 $5 를 넘을 것 같으면 실행을 멈추고 보고하라.

- [ ] **Step 4: 재생한다**

Run: `python -I evals/prior-art-verifier/replay.py --cases evals/prior-art-verifier/cases-v3.json --runs evals/prior-art-verifier/results-v4/runs-def.jsonl --repeat 2 --out evals/prior-art-verifier/results-v4/replay.json`
Expected: 항목마다 실행 차례별 `verdict` 가 있다.

- [ ] **Step 5: 보고를 만들고 병합 조건을 판정한다**

Run: Interfaces 의 `report-v4` 명령
Expected: `results-v4/report.md` 에 병합 조건 둘의 충족 여부, 기준선이 맞힌 항목 중 새 구성이 틀린 항목 목록, 카테고리별 오류 통과·참 기각, 판정 누락 수, 판정 불가 기각 수, 보충 비율과 결과, 단계별 비용이 있다.

- [ ] **Step 6: 결정 기록 7 을 쓰고 커밋한다**

결정 기록 7 에 아래를 적어라.
- 재측정 결과와 병합 조건 판정
- 결정 기록 5·6 의 실패 항목 각각이 이번에 맞았는지
- Opus 일괄 판정의 실제 비용과 spec 의 가정($0.2~0.3)의 비교
- 판정 누락 수와 판정 불가 기각 수
- 새로 틀린 항목과 그 원인, 카테고리별 오류 통과 수와 앞 재측정과의 비교

결정은 적지 말고 사실만 적어라. 원인을 확인하지 못한 문장에는 가정이라고 밝혀라.

```bash
git add evals/prior-art-verifier docs/superpowers/decisions
git commit -m "Opus 일괄 판정 구성의 재측정 결과와 결정 기록 7 을 추가한다"
```

- [ ] **Step 7: 사용자에게 병합 여부를 묻는다**

병합 조건을 모두 채웠으면 결정 기록 7 을 보이고 main 병합 승인을 받아라. 승인 요청에는 오류 통과 수와 앞 재측정과의 비교를 함께 보여라. 하나라도 못 채웠으면 병합하지 말고, 못 채운 조건과 틀린 항목을 보인 뒤 다음 설계를 사용자에게 물어라.
