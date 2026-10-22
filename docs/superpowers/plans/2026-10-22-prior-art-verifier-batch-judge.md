# 선행연구 검증자 Opus 일괄 판정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 판정과 재판정을 주장 20개 안팎 묶음의 Opus 5.5 medium 호출로 바꾸고 상향 판정 에이전트를 없앤다. 끝까지 판정 불가인 주장은 기각한다. 그 뒤 새 구성만 두 번 측정해 병합 여부를 정한다.

**Architecture:** 추출·보충·지도 대조는 지금처럼 Haiku 5.5 high 가 URL 마다 실행한다. 워크플로는 추출이 모두 끝나면 판정 대상 주장을 URL 경계를 지키며 묶음으로 나눈다. 이어서 묶음마다 판정 에이전트를 한 번 실행한다(label `judge:<묶음 번호>`). 묶음 출력은 URL 별 판정 객체로 나눠 `mergeStages` 에 넘긴다. 보충한 주장도 같은 방식으로 묶어 재판정한다(label `rejudge:<묶음 번호>`). 재측정은 `cases-v3.json` 으로 새 구성을 두 번 실행하고, 기준선은 앞 재측정의 실행을 다시 쓴다.

**Tech Stack:** JavaScript(워크플로, node 시험 도구), bash 테스트, Python 3 하네스, Claude Code CLI 2.1.305.

**Spec:** `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md`(「Opus 일괄 판정」 포함)

## 용어

- **앞 plan:** `docs/superpowers/plans/2026-10-21-prior-art-verifier-tiering-fix.md` 다. 보충·재판정·맞힘·틀리게 확신함·오류 통과·참 기각의 뜻은 앞 plan 과 그 앞 plan 의 「용어」 와 같다.
- **묶음:** 판정 에이전트 호출 한 번에 넣는 주장의 모음이다. 이 plan 에서 새로 붙인 이름이다.
- **판정 누락:** 묶음 입력에 있는데 출력에 판정이 없는 주장이다.
- **결정 기록 5·6:** `docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition-5.md` 와 `-6.md` 다. 앞 재측정의 결과는 `evals/prior-art-verifier/results-v3/` 에 있다.

## Global Constraints

- 추출 검증자와 지도 대조 에이전트의 frontmatter 는 `model: claude-haiku-5-5`, `effort: high` 다. 판정 에이전트의 frontmatter 는 `model: claude-opus-5-5`, `effort: medium` 이다. 상향 판정 에이전트 정의(`agents/prior-art-judge-escalation.md`)를 지워라.
- 추출 검증자의 도구는 `WebFetch, Read` 이고, 판정·지도 대조 에이전트의 도구는 `Read` 다.
- 판정 칸의 `match` 값, `missing`, `unsure_reasons`, `source_note`(추출 출력의 `exists_note ?? ''`), 보충 입력·출력 형식은 앞 plan 「Global Constraints」 와 같다.
- 묶음 입력은 `{ items: [{ url, claims: [{ ref, text, quote, context, source_note }] }] }`(MODE `judge`)이다. 묶음 출력은 `{ judgments: [{ url, ref, numbers_conditions, direction, scope, missing, unsure_reasons, reason }], principles_applied }` 다. 재판정 묶음도 같은 형식이다.
- 묶음 크기: 묶음 하나에 주장을 20개 이하로 넣고, 한 URL 의 주장은 한 묶음에 둔다. 한 URL 의 주장이 20개를 넘으면 그 URL 만으로 묶음 하나를 만든다. URL 은 입력 차례대로 앞 묶음부터 채운다.
- 판정 차례는 아래와 같다.
  - 처음 판정에 `불일치` 가 있으면 그 주장은 `unsupported` 다.
  - 보충은 주장마다 한 번만 한다.
  - 보충 실패, 보충 출력의 `access` 실패나 `exists` 불일치는 그 주장만 검증 실패로 만든다.
  - 재판정에서도 `정보 부족` 이면 그 주장만 `verify_failed` 다.
  - 끝까지 `판정 불가` 인 칸이 있으면 그 주장은 `unsupported` 이고, 이유 유형을 합친 출력의 `reason` 에 남긴다.
- 실패 범위는 아래와 같다.
  - 판정 묶음 호출이 응답하지 않으면 그 묶음에 넣은 URL 이 모두 검증 실패다.
  - 재판정 묶음 호출이 응답하지 않으면 그 묶음에 넣은 주장만 검증 실패다.
  - 판정·재판정 출력에서 빠진 주장은 그 주장만 검증 실패다.
  - 입력에 없던 URL 이나 ref 의 판정은 쓰지 않는다.
- 인용 판정 기준("옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported")을 그대로 지켜라.
- 반환값의 바깥 키를 그대로 지켜라. `verifiers[].stages` 의 키는 `extract`·`judge`·`refetch`·`rejudge` 이고, `escalation` 은 지워라. `stages[url].judge` 와 `.rejudge` 에는 묶음 출력 중 그 URL 의 판정만 넣어라.
- 병합 조건(spec 「채택 규칙」)은 비용 조건과 맞힘 유지 조건이다. 비용 조건은 구성 전체의 `total_cost_usd` 가 기준선보다 낮아야 채워진다. 맞힘 유지 조건은 기준선이 두 실행 모두에서 맞힌 항목을 새 구성의 최종 `verdict` 도 두 실행 모두에서 맞혀야 채워진다. 기준선은 `evals/prior-art-verifier/results-v2/runs.jsonl` 의 두 실행이고 `cases-v3.json` 으로 채점한다.
- main 병합과 push 는 사용자 승인을 받은 뒤에만 하라.
- 결정 기록은 기록 타입이다. 이미 있는 결정 기록은 그대로 두고 새 파일로 적어라.
- 측정 실행 조건은 결정 기록 5 와 같다. run.py `build_cmd` 의 플래그를 쓰고, 실행 폴더는 `D:/dc-eval-tmp` 아래에 두고, 자식 환경에서 `CLAUDE_CODE_EFFORT_LEVEL` 을 지운다.
- 커밋 전에는 검사를 실패 시 멈추는 방식으로 실행하고, 실패한 상태로 커밋하지 마라. `__pycache__` 파일은 커밋하지 마라.

## Review Focus

- 묶음 출력에서 한 URL 의 주장 하나만 빠질 때: 그 주장만 검증 실패이고 같은 URL 의 다른 주장과 다른 URL 의 판정은 남아야 한다. Task 1 의 `빠진 주장만 검증 실패다` 가 고정한다.
- 묶음 출력에 입력에 없던 URL 이나 ref 가 섞일 때: 그 판정은 버려야 하고 다른 URL 의 판정에 섞이면 안 된다. Task 1 의 `입력에 없던 판정은 쓰지 않는다` 가 고정한다.
- 판정 묶음 하나가 실패할 때: 그 묶음의 URL 만 검증 실패이고 다른 묶음의 판정은 남아야 한다. Task 1 의 `실패한 판정 묶음의 URL 만 검증 실패다` 가 고정한다.
- 판정 불가가 남은 주장: `unsupported` 이고 `reason` 에 이유 유형이 있어야 한다. Task 1 의 `판정 불가는 기각이고 이유가 남는다` 가 고정한다.
- 운영 규모의 일괄 판정: 시험은 주장 36~39개로 묶음 둘이다. 운영은 그보다 많은 묶음을 만든다. Task 2 의 결정 기록 7 에 측정한 묶음 크기와 출력 토큰을 적고, 그보다 큰 묶음은 측정 범위 밖이라는 사실을 적는다.

---

### Task 1: 묶음 판정 구조

**Files:**
- Modify: `workflows/prior-art-search.js`
  - Verify 단계의 판정·재판정 호출을 묶음 호출로 바꾼다.
  - `batchClaims`·`splitByUrl` 을 새로 만든다.
  - `nextStep`·`routeClaim` 의 상향 분기와 `escalateClaims`·`ESCALATION` 상수, 스키마 주석의 상향 서술을 지운다.
  - `mergeStages`·`mergeUrl` 을 새 서명과 판정 불가 기각에 맞춘다.
  - 판정 스키마에 `url` 칸을 추가한다.
- Modify: `agents/prior-art-judge.md`
- Delete: `agents/prior-art-judge-escalation.md`
- Modify: `scripts/workflow_harness.mjs`(`FN_NAMES` 에 `batchClaims`·`splitByUrl` 추가)
- Modify: `scripts/prior_art_contract.json`, `scripts/test_workflow.sh`, `scripts/test_prior_art_contract.sh`, `scripts/test_docs_drift.sh`
- Modify: `skills/agent-prior-art/SKILL.md`

**Interfaces:**
- Produces: `batchClaims(claimsByUrl: {[url]: claim[]}, size: number) -> [{ items: [{ url, claims }] }]`. 묶음 크기 규칙은 Global Constraints 「묶음 크기」 다. 주장이 없는 URL 은 넣지 않는다. 워크플로는 `size` 에 20 을 넘긴다.
- Produces: `splitByUrl(batchOutputs: (object|null)[], batches) -> {[url]: { judgments, principles_applied }|null}`. 실패한 묶음의 URL 은 `null` 이다. 입력에 없던 URL 이나 ref 의 판정은 버린다.
- Produces: `mergeStages(refsByUrl, extract, judge, refetch, rejudge)`. 인자와 반환값은 URL 을 키로 둔 일반 객체다. `judge` 는 판정 묶음에 `splitByUrl` 을 적용한 결과다. `rejudge` 는 재판정 묶음에 `splitByUrl` 을 적용한 결과다. 재판정 묶음이 실패한 URL 의 값은 `null` 이고, 그 URL 의 보충 주장만 검증 실패가 된다.
- Produces: label 규약 `extract:<url>`, `judge:<n>`, `refetch:<url>`, `rejudge:<n>`, `map-check`. `<n>` 은 1 부터 세는 묶음 번호다. `judge:`·`rejudge:` 의 agentType 은 `disciplined-coder:prior-art-judge` 다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`scripts/test_workflow.sh` 에 `harn fn` 과 `harn run` 으로 아래 검사를 추가하라.
- `묶음은 주장 20개 이하이고 URL 을 나누지 않는다`: 주장 25개(URL 셋)가 묶음 둘이 된다.
- `20개를 넘는 URL 은 홀로 묶음이 된다`
- `주장 없는 URL 은 묶음에 넣지 않는다`
- `판정은 묶음마다 한 번 부른다`: 묶음이 둘이면 `judge:1`·`judge:2` 호출이 있다.
- `빠진 주장만 검증 실패다`
- `입력에 없던 판정은 쓰지 않는다`
- `실패한 판정 묶음의 URL 만 검증 실패다`: `harn run` 응답표에 `judge:1` 을 `null` 로 넣는다.
- `실패한 재판정 묶음은 보충 주장만 검증 실패다`
- `보충이 없으면 재판정을 부르지 않는다`
- `재판정은 보충한 주장만 묶어 부른다`
- `판정 불가는 기각이고 이유가 남는다`: 끝까지 `판정 불가` 인 주장의 `verdict` 가 `unsupported` 이고 `reason` 에 이유 유형이 있다.
- `재판정도 정보 부족이면 그 주장만 검증 실패다`
- `상향 호출이 없다`: 호출 목록에 `escalate:` label 이 없다.

아래 기존 검사와 자료도 고쳐라.
- `test_workflow.sh` 의 `judge:<url>`·`rejudge:<url>`·`escalate:<url>` 응답표 키와 기대식, `E_MG_STAGES` 의 stages 집합을 새 구조에 맞게 바꿔라.
- `prior_art_contract.json` 의 `judge` 자료를 묶음 출력 형식으로 바꾸고, 묶음 입력 예시를 추가하고, `stages` 에서 `escalation` 을 지워라.
- `test_prior_art_contract.sh` 가 위 자료를 판정 정의의 예시 블록과 대조하게 하라. 상향 판정 정의(`ED`)의 존재 검사, `judge:ED` 예시 대조, `ED` enums 검사를 지워라.
- `test_docs_drift.sh` 의 정의 검사가 정의 파일 셋(추출·판정·지도 대조)을 보고 판정 정의의 `model: claude-opus-5-5`, `effort: medium` 을 보게 하라. 상향 판정 정의 관련 검사(본문 동일, frontmatter 동일, `ESC_MARK`)를 지워라.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash scripts/test_workflow.sh 2>&1 | grep -E "FAIL|PASS="; bash scripts/test_prior_art_contract.sh 2>&1 | tail -1; bash scripts/test_docs_drift.sh 2>&1 | grep FAIL`
Expected: 새 검사와 고친 기대식이 FAIL 이다.

- [ ] **Step 3: 판정 정의를 고친다**

- frontmatter 를 `model: claude-opus-5-5`, `effort: medium` 으로 바꿔라.
- 입력이 URL 여러 개의 `items` 라는 사실과 출력 형식을 적고, 예시 블록을 묶음 형식으로 바꿔라.
- 아래 지시를 추가하라. "주장마다 그 주장과 같은 `items` 원소의 구절·맥락만 보고 판정하라. 다른 URL 의 구절을 근거로 쓰지 마라. 입력의 주장마다 판정 하나를 빠짐없이 내라."
- 충분성 판단, 다른 값이면 불일치, 출처 정체를 판정하지 않는다는 기존 지시는 그대로 두어라.
- `agents/prior-art-judge-escalation.md` 를 지워라.

- [ ] **Step 4: 워크플로와 SKILL.md 를 고친다**

Verify 단계가 아래 순서로 실행되게 고쳐라.
1. 추출을 URL 마다 `parallel` 로 실행한다.
2. 판정 대상 주장을 `batchClaims` 로 묶고, 판정 묶음을 `parallel` 로 실행한다.
3. 보충을 URL 마다 `parallel` 로 실행한다.
4. 보충한 주장이 있으면 재판정 묶음을 `parallel` 로 실행한다.
5. 결과를 `mergeStages` 로 합친다.

SKILL.md 에서 아래 절을 새 구조에 맞게 고쳐라.
- 「오케스트레이터 절차」의 탐색 단계 서술과 「워크플로가 꺼진 환경」
- 「반환값을 읽는 규칙」: stages 의 `null` 이 실행 안 함인지 무응답인지는, 그 URL 이 든 묶음의 label(`judge:<n>`·`rejudge:<n>`) 호출 결과로 구별한다고 적어라.
- 「상태 값」: 판정 불가는 기각이다.
- 「실행할 때 지킬 상한」: URL 마다 추출 1, 보충 0~1 이다. 묶음마다 판정 1, 재판정 0~1 이다. 묶음의 주장은 20개 이하다.
- 「에이전트에게 보내는 프롬프트」·「출력 스키마」·「판정 모델 교체」
- 「인용 확인」

- [ ] **Step 5: 검사가 통과하는지 확인한다**

Run: `d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; cat "$d/bad"; else echo "ALL PASS"; fi; claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`

- [ ] **Step 6: 커밋한다**

```bash
git add -A workflows agents scripts skills
git commit -m "판정을 Opus 묶음 호출로 바꾸고 상향 판정 에이전트를 없앤다"
```

### Task 2: 묶음 판정 재측정

**Files:**
- Modify: `evals/prior-art-verifier/run.py`
  - `judge-def`·`rejudge-def` 를 실행 차례마다 묶음 단위(unit `batch:<n>`)로 실행하게 바꾼다.
  - 단계마다 앞 단계 설정을 따로 고르게 바꾼다. 추출·보충은 Haiku high 이고, 판정·재판정은 Opus medium 이다.
  - 판정 입력의 ref 를 정답이 드러나지 않는 번호(`c1`, `c2` …)로 바꾸고 채점 때 항목 id 로 되돌린다.
  - `next_step`·`route_claim` 사본을 워크플로의 새 규칙에 맞추고, `_escalate_claims`·`escalate-def` 를 지운다.
- Modify: `evals/prior-art-verifier/replay.py`(묶음 출력을 URL 별로 나눠 `mergeStages` 의 새 인자로 넘김, 상향 출력 칸 제거)
- Modify: `evals/prior-art-verifier/score.py`
  - `report-v4` 를 새로 만든다. `--prev-replay` 는 `results-v3/replay.json` 이다.
  - 단계 설정 상수를 판정·재판정 Opus medium 으로 바꾼다.
  - `report-v3` 와 `NEW_STAGES_V3` 를 지운다. `results-v3/report.md` 는 기록으로 남는다.
- Modify: `evals/prior-art-verifier/harness_tests.py`, `run_tests.sh`
- Modify: `evals/prior-art-verifier/README.md`
  - 「구성 전체 재측정」 의 `escalate-def` 명령을 지운다.
  - `report-v4`·`results-v4` 명령과 묶음 단위를 적는다.
  - 이번 plan 을 가리키는 포인터를 추가한다.
- Create: `evals/prior-art-verifier/results-v4/`(실행 결과)
- Create: `docs/superpowers/decisions/2026-10-22-prior-art-verifier-composition-7.md`

**Interfaces:**
- Consumes: Task 1 의 묶음 입력·출력 형식, `batchClaims`·`splitByUrl`·`mergeStages` 서명. `cases-v3.json`.
- Produces: `judge-def`·`rejudge-def` 의 묶음은 워크플로 `batchClaims` 와 같은 규칙(크기 20)으로 만든다. 각 단계는 실행 차례마다 묶음 수만큼 줄을 만든다.
- Produces: `python -I evals/prior-art-verifier/score.py report-v4 --cases evals/prior-art-verifier/cases-v3.json --baseline evals/prior-art-verifier/results-v2/runs.jsonl --runs evals/prior-art-verifier/results-v4/runs-def.jsonl --replay evals/prior-art-verifier/results-v4/replay.json --prev-replay evals/prior-art-verifier/results-v3/replay.json --out evals/prior-art-verifier/results-v4/report.md`.
- Produces: `report-v4` 의 보고 항목은 아래와 같다.
  - 병합 조건(비용 조건과 맞힘 유지 조건)의 충족 여부
  - 기준선이 맞힌 항목 중 새 구성이 틀린 항목 목록
  - 카테고리별 오류 통과·참 기각과 앞 재측정(results-v3)과의 비교
  - 판정 누락 수
  - 판정 불가로 기각한 주장을 참·오류로 나눈 수
  - 틀리게 확신함
  - 보충 비율과 결과
  - 묶음마다의 주장 수와 출력 토큰
  - 단계별 비용(판정·재판정 묶음 비용 포함)

- [ ] **Step 1: 실패하는 검사를 쓴다**

`harness_tests.py` 에 아래 테스트를 추가하라.
- `test_def_prompt_matches_workflow`: `judge:<n>`·`rejudge:<n>` 묶음 프롬프트를 `harn run` 기록과 대조하도록 고친다.
- `test_batches_match_workflow`: run.py 의 묶음이 같은 입력에서 `harn fn batchClaims` 와 같다.
- `test_upstream_config_per_stage`: `refetch-def` 와 replay 가 Opus medium 판정 줄을 찾는다.
- `test_neutral_refs_roundtrip`: 판정 입력에 항목 id 가 없고, 채점 때 id 로 되돌아온다.
- `test_replay_splits_batch`: 가짜 묶음 출력으로 replay 가 URL 별 판정을 `mergeStages` 에 넘기고, 빠진 주장만 검증 실패가 된다.
- `test_report_v4_items`: 판정 누락 수, 참·오류로 나눈 판정 불가 기각 수, 묶음별 크기와 출력 토큰이 보고에 있다.

옛 상향 단계와 `report-v3` 를 기대하는 테스트를 지워라.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: 새 테스트가 FAIL 이다.

- [ ] **Step 3: 하네스를 구현한다**

Files 에 적은 run.py·replay.py·score.py·README.md 변경을 구현하라.

- [ ] **Step 4: 하네스 검사가 통과하는지 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: `FAIL=0`

- [ ] **Step 5: 새 구성을 두 번 실행한다**

아래 명령을 차례대로 실행하라.

Run:
```bash
C="--cases evals/prior-art-verifier/cases-v3.json --out evals/prior-art-verifier/results-v4/runs-def.jsonl --repeat 2"
python -I evals/prior-art-verifier/run.py --stage extract-def --model claude-haiku-5-5 --effort high $C
python -I evals/prior-art-verifier/run.py --stage judge-def --model claude-opus-5-5 --effort medium $C
python -I evals/prior-art-verifier/run.py --stage refetch-def --model claude-haiku-5-5 --effort high $C
python -I evals/prior-art-verifier/run.py --stage rejudge-def --model claude-opus-5-5 --effort medium $C
python -I evals/prior-art-verifier/run.py --stage map-def --model claude-haiku-5-5 --effort high $C
```
Expected: 단계마다 실행 대상 단위에 오류 없는 줄이 실행 차례마다 하나씩 있다. `judge-def` 는 실행 차례마다 묶음 수만큼 줄이 있다. 보충 대상이 없는 차례에는 `refetch-def`·`rejudge-def` 의 줄이 없다.

오류로 끝난 시도가 있으면 다시 실행하기 전에 그 줄의 단계·묶음·오류 내용(출력 잘림 여부 포함)을 기록해 두어라. 결정 기록 7 에 적을 사실이다.

예상 비용은 실행 한 번에 약 $1.2, 두 번에 약 $2.4 다(가정, spec 「Opus 일괄 판정」 의 계산). 지출이 $5 를 넘을 것 같으면 실행을 멈추고 보고하라.

- [ ] **Step 6: 재생한다**

Run: `python -I evals/prior-art-verifier/replay.py --cases evals/prior-art-verifier/cases-v3.json --runs evals/prior-art-verifier/results-v4/runs-def.jsonl --repeat 2 --out evals/prior-art-verifier/results-v4/replay.json`
Expected: 항목마다 실행 차례별 `verdict` 가 있다.

- [ ] **Step 7: 보고를 만들고 병합 조건을 판정한다**

Run: `python -I evals/prior-art-verifier/score.py report-v4 --cases evals/prior-art-verifier/cases-v3.json --baseline evals/prior-art-verifier/results-v2/runs.jsonl --runs evals/prior-art-verifier/results-v4/runs-def.jsonl --replay evals/prior-art-verifier/results-v4/replay.json --prev-replay evals/prior-art-verifier/results-v3/replay.json --out evals/prior-art-verifier/results-v4/report.md`
Expected: `results-v4/report.md` 에 Interfaces 의 `report-v4` 보고 항목이 모두 있다.

- [ ] **Step 8: 결정 기록 7 을 쓰고 커밋한다**

결정 기록 7 에 아래를 적어라.
- 재측정 결과와 병합 조건 판정
- 결정 기록 5·6 의 실패 항목 각각이 이번에 맞았는지
- 판정 묶음·재판정 묶음의 실제 비용과 spec 의 가정(실행 한 번 약 $1.2)의 비교
- 묶음마다의 주장 수와 출력 토큰, 그리고 그보다 큰 묶음은 측정 범위 밖이라는 사실
- 오류로 끝난 일괄 시도의 수와 이유
- 판정 누락 수, 참·오류로 나눈 판정 불가 기각 수, 틀리게 확신함
- 새로 틀린 항목과 그 원인. 판정 `reason` 이 그 URL 의 quote·context 에 없는 구절을 인용했는지(URL 사이의 구절 섞임)도 확인해 적어라.
- 카테고리별 오류 통과 수와 앞 재측정과의 비교
- 지운 상향 판정 정의를 되살릴 때 쓸 커밋

결정은 적지 말고 사실만 적어라. 원인을 확인하지 못한 문장에는 가정이라고 밝혀라.

```bash
git add evals/prior-art-verifier docs/superpowers/decisions
git commit -m "Opus 묶음 판정 구성의 재측정 결과와 결정 기록 7 을 추가한다"
```

- [ ] **Step 9: 사용자에게 병합 여부를 묻는다**

병합 조건을 모두 채웠으면 결정 기록 7 을 보이고 main 병합 승인을 받아라. 승인 요청에는 오류 통과 수와 앞 재측정과의 비교를 함께 보여라. 하나라도 못 채웠으면 병합하지 말고, 못 채운 조건과 틀린 항목을 보인 뒤 다음 설계를 사용자에게 물어라.

<!-- spec-review: escalated -->
