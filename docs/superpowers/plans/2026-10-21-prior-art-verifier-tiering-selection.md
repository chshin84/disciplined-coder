# 선행연구 검증자 설정 선택 시험 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 검증 카테고리마다 모델과 노력 수준을 고르는 시험 하네스를 만들고 실행해, 고른 구성과 결과를 결정 기록으로 남긴다.

**Architecture:** 이 plan 은 spec 의 「시험」 절과 「채택 규칙」의 승인 지점까지만 다룬다. 판정 에이전트의 수는 시험 결과로 정해진다. 그래서 spec 작성 때 사용자와 정한 대로, 에이전트 정의·워크플로·계약·SKILL.md 개정은 사용자 승인 뒤의 별도 plan 이 맡는다. 하네스는 `evals/prior-art-verifier/` 아래의 실행기·집계기·검사기와 단계별 프롬프트로 이루어진다. 실행기는 `claude -p` 를 단계와 설정마다 실행하고, 집계기는 결과를 세어 채택 규칙을 적용한다.

**Tech Stack:** Python 3(표준 라이브러리만), bash(`scripts/_eval_env.sh` 의 `eval_tmpdir`), Claude Code CLI 2.1.305 의 `claude -p`.

**Spec:** `docs/superpowers/specs/2026-10-20-prior-art-verifier-tiering-design.md`

## 용어

- **오류 통과:** 오류를 넣은 항목을 설정이 통과시킨 건수다. 기준선은 최종 `verdict` 가 `supported` 인 경우, 추출 단계는 기각 신호가 없는 경우, 판정 단계는 `match` 가 `일치` 인 경우다.
- **참 기각:** 참 항목을 설정이 기각한 건수다. 기준선은 최종 `verdict` 가 `unsupported` 나 `unverifiable` 인 경우, 추출 단계는 `access` 실패·`exists` 불일치·`quote` 없음 중 하나인 경우, 판정 단계는 `match` 가 `불일치` 인 경우다.
- **흔들림:** 기준선 두 실행 사이의 오류 통과 차이와 참 기각 차이다.
- **카테고리 코드:** 접근=`access`, 존재=`exists`, 구절=`quote`, 수치·조건=`numbers_conditions`, 방향=`direction`, 범위=`scope`, 지도 대조=`map`.

## Global Constraints

- 비용 비교 값은 `claude -p --output-format json` 출력의 `total_cost_usd` 다.
- 기준선은 현행 `agents/prior-art-verifier.md` 본문을 Opus 5.5 medium, 도구 WebFetch·Read 로 두 번 실행한 결과다. cite 모드와 map 모드를 모두 두 번 실행한다.
- 시험 격자는 Haiku 5.5 low·medium·high 와 Sonnet 5.5 low·medium·high 다. Opus 5.5 low 는 어느 단계든 Sonnet high 도 기준선에 못 미친 카테고리에서만 실행한다.
- 모델 ID 는 `claude-haiku-5-5`, `claude-sonnet-5-5`, `claude-opus-5-5` 다.
- 채택 규칙은 카테고리마다 오류 통과와 참 기각이 모두 기준선 이하인 설정 중에서 `total_cost_usd` 가 가장 낮은 설정을 고르는 것이다. 기준선과의 차이가 흔들림 안에 들면 같은 성적으로 본다. 기준선 값은 두 실행 중 나쁜 쪽(오류 통과와 참 기각 각각의 큰 값)을 쓴다.
- 추출 단계는 접근·존재·구절을 한 에이전트가 맡으므로 설정을 하나만 고른다. 세 카테고리 모두에서 채택 조건을 채운 설정 중 비용이 가장 낮은 설정이다.
- 모든 단계의 도구는 spec 「에이전트와 단계」 표를 따른다. 기준선과 추출은 `--tools WebFetch,Read --allowedTools WebFetch,Read`, 판정과 지도 대조는 `--tools Read --allowedTools Read` 다.
- 이 PC 에는 API 키 파일(`~/.dc-eval.env`)이 없어 `--bare` 를 쓸 수 없다. 모든 실행에 `--setting-sources "" --strict-mcp-config --disable-slash-commands --no-session-persistence` 를 붙이고, 실행 폴더는 `scripts/_eval_env.sh` 의 `eval_tmpdir`(기본 `/d/dc-eval-tmp`)로 만든다. 실행 환경에서 `CLAUDE_CODE_EFFORT_LEVEL` 과 `CLAUDE_CODE_SUBAGENT_MODEL` 을 지운다.
- 키·토큰을 대화·로그·문서·커밋에 적지 마라.
- 사용자 승인 전에는 `agents/`·`workflows/`·`scripts/prior_art_contract.json`·`skills/agent-prior-art/` 를 고치지 마라.
- 하네스 테스트 파일 이름은 `test_*.sh` 로 짓지 마라. 저장소 「변경 뒤 실행」은 `scripts/test_*.sh` 를 매번 실행하는데, 이 하네스는 일회성이다.

## Review Focus

- `claude -p` 가 오류(인증 실패, 과부하, 시간 초과, 사용량 한도)를 돌려줄 때: 그 실행은 성적에 넣지 않고 오류 줄로 남기며, 같은 key 가 같은 오류로 두 번 실패하면 실행기가 멈추고 그 사실을 출력한다. Task 2 의 `test_error_retry_cap` 이 고정한다.
- 고정한 추출 출력에 `quote` 가 없는 항목: spec 의 판정 순서에서는 판정 에이전트까지 가지 않으므로, 판정 단계 채점에서 빼고 뺀 항목을 보고에 적는다. Task 3 의 `test_no_quote_excluded` 가 고정한다.
- 판정이 빠진 출력: 일치로 세지 않고 `failures` 로 센다. Task 3 의 `test_missing_judgment_is_failure` 가 고정한다.
- 실행 기록의 모델이 요청과 다를 때: 그 실행을 오류로 센다. 첫 실제 실행에서 오류가 나면 격자를 시작하지 않고 멈춘다. Task 2 의 `test_model_mismatch_flagged` 와 Step 6 이 고정한다.
- 기준선 두 실행이 같은 성적일 때: 흔들림이 0 이므로 1건 차이도 다른 성적이다. Task 3 의 `test_zero_noise` 가 고정한다.

---

### Task 1: 시험 자료와 정답표

**Files:**
- Create: `evals/prior-art-verifier/cases.json`
- Create: `evals/prior-art-verifier/README.md`
- Create: `evals/prior-art-verifier/check_cases.py`
- Create: `evals/prior-art-verifier/run_tests.sh`

**Interfaces:**
- Produces: `cases.json` 의 형식 `{ "items": [Item], "map_cases": [MapCase] }`.
  - `Item = { id, category, url, claim: { ref, text }, truth: true|false, check_note }`. `category` 는 「용어」의 코드 중 `map` 을 뺀 값이다. `claim.text` 는 이슈 항목이면 `prior_claim` 문장이고, 사례 행이면 현행 워크플로처럼 `{ case, outcome, prior }` 를 JSON 문자열로 적은 값이다. `truth: false` 는 그 카테고리의 오류를 넣은 항목이다. `check_note` 는 구현자가 원문을 열어 확인한 내용이다.
  - `MapCase = { id, input: { evidence_map, passed: [{ ref, row }] }, truth: [{ row, column, grounded }] }`.
- Produces: `python -I evals/prior-art-verifier/check_cases.py <cases.json>`. 위반을 한 줄씩 출력하고, 위반이 있으면 종료 코드 1 로 끝난다.
- Produces: `bash evals/prior-art-verifier/run_tests.sh`. 이 하네스의 검사를 모두 실행하고 `FAIL=0` 이면 0 으로 끝난다. `scripts/_test_check.sh` 의 `check` 를 쓴다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`run_tests.sh` 에 아래 검사를 둔다.
- `cases.json` 이 JSON 으로 읽힌다.
- `check_cases.py` 가 0 으로 끝난다.
- 고장 낸 사본 세 가지에서 `check_cases.py` 가 1 로 끝난다. 사본은 오류 항목 하나를 지운 것, `check_note` 를 비운 것, arXiv 2605.10039 항목을 지운 것이다.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: FAIL(파일이 없다)

- [ ] **Step 3: `check_cases.py` 를 구현한다**

아래를 검사한다.
- 카테고리마다 `truth: true` 와 `truth: false` 의 개수가 같다.
- `map_cases` 의 `truth` 에서 `grounded: true` 칸과 `grounded: false` 칸의 개수가 같다.
- 모든 항목의 `check_note` 가 비어 있지 않다.
- `id` 가 겹치지 않는다.
- `url` 이 `https://arxiv.org/abs/2605.10039` 인 `direction` 참 항목이 하나 있다.

- [ ] **Step 4: 자료를 만든다**

참 항목은 `D:\projects\dc-clause-candidates\docs\superpowers\reviews\2026-10-20-generation-constraints-prior-art.md` 「오케스트레이터 인용 확인」의 10건에서 시작하라. 10건은 모두 사례 행(`#case#`)이다. 그래서 `claim.text` 는 같은 폴더 `researcher-<하위 질문 ID>-r1.json` 의 `evidence_map` 행에서 `case`·`outcome`·각 축의 `prior` 를 꺼내 만든다. 카테고리마다 참 항목이 모자라면 같은 실행의 다른 주장을 원문에서 직접 열어 확인하고, 확인 내용을 `check_note` 에 적어라. 오류 항목은 spec 「시험 자료」 표의 방식으로 참 항목을 고쳐 만들고, 원문의 다른 구절이 그 주장을 뒷받침하지 않는지 확인해 `check_note` 에 적어라. 카테고리마다 참·오류 각각 4건을 목표로 하고, 원문 확인 비용이 크면 3건까지 줄여라.

`map_cases` 는 하나를 만든다. `search-r1.json` 의 `passed` 에서 `#case#` 참조만 고르고, 각 참조의 행을 연구자 출력 `evidence_map` 에서 찾아 `{ ref, row }` 로 이어 붙인다. 현행 워크플로 `workflows/prior-art-search.js` 의 `passed_rows` 와 같은 방식이다. `evidence_map` 은 `search-r1.json` 의 `synthesis.evidence_map` 을 쓰고, 근거 없는 칸을 넣은 만큼 근거 있는 칸을 정답표에 같은 수로 둔다.

`README.md` 에는 아래를 적는다.
- 자료의 출처 경로
- 항목 형식과 카테고리 코드
- 실행 명령(Task 4)
- 실행 조건: Global Constraints 의 CLI 플래그와 Task 2 Step 6 에서 확인한 적재 지시
- 이 폴더는 일회성 시험 기록이라는 사실

- [ ] **Step 5: 검사가 통과하는지 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: `FAIL=0`

- [ ] **Step 6: 커밋한다**

```bash
git add evals/prior-art-verifier
git commit -m "선행연구 검증자 시험 자료와 정답표를 추가한다"
```

### Task 2: 단계별 프롬프트와 실행기

**Files:**
- Create: `evals/prior-art-verifier/prompts/baseline-cite.md`, `baseline-map.md`, `extract.md`, `judge-numbers_conditions.md`, `judge-direction.md`, `judge-scope.md`, `map.md`
- Create: `evals/prior-art-verifier/run.py`
- Create: `evals/prior-art-verifier/fake_claude.py`
- Create: `evals/prior-art-verifier/fixtures/extract-sample.jsonl`
- Modify: `evals/prior-art-verifier/run_tests.sh`

**Interfaces:**
- Consumes: Task 1 의 `cases.json` 형식.
- Produces: `python -I evals/prior-art-verifier/run.py --stage <baseline-cite|baseline-map|extract|judge|map> --model <ID> --effort <low|medium|high> [--category <numbers_conditions|direction|scope>] [--extract-from <경로>] [--repeat <n>] [--out <runs.jsonl 경로>]`. `--out` 의 기본값은 `evals/prior-art-verifier/results/runs.jsonl` 이다.
- Produces: 결과 한 줄의 형식 `Run = { key, stage, model, effort, category, repeat, unit, output, cost_usd, usage, models_used, error, attempt }`.
  - `unit` 은 cite 계열이면 URL 이고 map 계열이면 `MapCase.id` 다.
  - `key` 는 (stage, model, effort, category, repeat, unit, 입력을 채운 최종 프롬프트의 sha256) 의 sha256 앞 16자다.
  - `output` 은 에이전트가 낸 JSON 이고, 읽지 못하면 `null` 이다.
  - `cost_usd` 는 출력의 `total_cost_usd` 이고, 시간 초과처럼 출력이 없으면 `null` 이다.
- Produces: `--extract-from` 파일의 형식은 `Run` 줄이다. `extract-frozen.jsonl` 과 `fixtures/extract-sample.jsonl` 도 같은 형식을 쓴다.
- Produces: 함수 `build_cmd(stage: str, model: str, effort: str, prompt: str) -> list[str]`, `parse_output(text: str) -> dict | None`.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`run_tests.sh` 첫머리에서 `DC_EVAL_CLAUDE="python -I evals/prior-art-verifier/fake_claude.py"` 를 설정하라. 실행기 검사는 모두 `--out` 을 임시 폴더 경로로 준다. `fake_claude.py` 는 환경 변수 `FAKE_MODE` 에 따라 정상 JSON, `is_error` JSON, 다른 `modelUsage` 키, 시간 초과 흉내(오래 잠들기)를 낸다. 아래 검사를 넣는다.
- `test_build_cmd_tools`: 기준선·추출 단계의 명령에는 `--tools WebFetch,Read` 와 `--allowedTools WebFetch,Read` 가 있다. 판정·지도 대조 단계의 명령에는 `--tools Read` 와 `--allowedTools Read` 가 있다. 모든 단계에 `--effort`·`--model`·`--setting-sources`·`--strict-mcp-config`·`--disable-slash-commands`·`--no-session-persistence` 가 있다.
- `test_error_retry_cap`: `is_error` 를 내는 가짜 명령으로 두 번 실행하면 둘째 실행 뒤 실행기가 0 이 아닌 코드로 끝나고, 같은 key 의 `attempt` 가 2 인 줄이 있다.
- `test_cached_skip`: `error` 가 빈 줄이 있는 key 는 다시 실행하지 않는다.
- `test_model_mismatch_flagged`: 가짜 명령의 `modelUsage` 키가 요청한 모델과 다르면 `error` 에 `모델 불일치` 가 들어간다.
- `test_parse_output_fenced`: 마크다운 코드 펜스로 감싸고 앞에 설명 글이 붙은 JSON 을 `parse_output` 이 읽는다.
- `test_prompt_sha_changes_key`: 같은 설정에서 입력 주장 문장만 바꾸면 key 가 달라진다.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: FAIL(`run.py` 가 없다)

- [ ] **Step 3: 프롬프트를 쓴다**

- `baseline-cite.md` 와 `baseline-map.md` 는 `agents/prior-art-verifier.md` 본문(frontmatter 제외)을 그대로 옮기고, 그 아래에 각 모드의 입력을 넣을 자리를 둔다. 첫 줄의 `MODE:` 와 둘째 줄의 `PRINCIPLES:` 는 현행 규약대로 둔다. `PRINCIPLES:` 경로는 이 저장소의 `agent-principles.md` 절대 경로다.
- `extract.md` 는 주장마다 spec 「에이전트와 단계」 표의 추출 검증자 출력을 내게 한다. 출력은 `access`(`성공`·`실패`), `exists`(`일치`·`불일치`), `quote`, `context`, `reason` 이다. `quote` 에는 원문 구절을 고치지 않고 옮기게 한다. `context` 에는 그 구절 앞뒤의 부정·조건·비교를 WebFetch 에 따로 물어 얻은 답을 담게 한다.
- `judge-<코드>.md` 는 주장과 `quote`·`context` 만 받아, 그 카테고리 하나의 `match`(`일치`·`불일치`)와 `reason` 을 내게 한다. 판정 기준으로 spec 의 인용 판정 기준 문장을 그대로 넣고, spec 「검증 카테고리」 표의 그 행 '판정하는 내용' 칸도 그대로 넣는다.
- `map.md` 는 `agents/prior-art-verifier.md` 의 map 모드 단락과 지도 대조 출력 형식을 옮긴다.
- 모든 프롬프트의 출력은 JSON 하나로만 내게 한다.

- [ ] **Step 4: `run.py` 를 구현한다**

- 실행 파일은 `DC_EVAL_CLAUDE` 가 있으면 그 값을 공백으로 나눈 인자 목록이고, 없으면 `["claude"]` 다.
- 실행 폴더는 `bash -c '. scripts/_eval_env.sh; eval_tmpdir'` 가 낸 경로다. 실패하면 그 오류를 출력하고 끝낸다.
- 환경에서 `CLAUDE_CODE_EFFORT_LEVEL` 과 `CLAUDE_CODE_SUBAGENT_MODEL` 을 지운다.
- 동시 실행 수는 4 이고, `runs.jsonl` 쓰기는 주 스레드가 `as_completed` 순서로 한 줄씩 한다.
- 시간 초과는 900초다. 시간 초과 줄은 `cost_usd: null` 과 `error: "시간 초과(900초)"` 로 남긴다.
- `judge` 단계 입력은 `--extract-from` 파일에서 같은 `unit`·`ref` 의 추출 출력을 읽어 만든다. `quote` 가 없는 항목은 실행하지 않는다.
- `models_used` 는 출력의 `modelUsage` 키를 정렬해 쉼표로 이은 값이다. 요청한 모델 ID 로 시작하는 키가 없으면 `error` 에 `모델 불일치` 를 적는다.
- 재실행 판단은 `error` 가 빈 줄이 있는 key 를 건너뛰는 방식이다. 오류 줄만 있는 key 는 다시 실행하고 `attempt` 를 하나 늘린다. 같은 key 에서 `attempt` 가 2 에 이르러도 오류이면, 그 key 와 오류 문구를 출력하고 0 이 아닌 코드로 끝낸다.
- 같은 `--out` 파일에 여러 셸이 동시에 쓰지 않도록, 시작할 때 `<out>.lock` 을 배타적으로 만들고 끝날 때 지운다. 잠금 파일이 이미 있으면 그 사실을 출력하고 끝낸다.

- [ ] **Step 5: 검사가 통과하는지 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: `FAIL=0`

- [ ] **Step 6: 실제 CLI 로 웹을 여는 단계를 한 번 실행해 실행 조건을 확인한다**

`cases.json` 의 2605.10039 항목 하나만 담은 임시 자료로 실행하라.
Run: `python -I evals/prior-art-verifier/run.py --stage extract --model claude-haiku-5-5 --effort low --out <임시 폴더>/probe.jsonl`
Expected: 줄의 `error` 가 비어 있고, `cost_usd` 가 숫자이며, `models_used` 에 `claude-haiku-5-5` 로 시작하는 키가 있고, `output.judgments` 의 `access` 가 `성공` 이다.

위 조건 중 하나라도 어긋나면 격자를 시작하지 말고 그 줄을 사용자에게 보여라. 그대로 통과하면, 같은 실행 조건에서 `claude -p` 에 "지금 실린 시스템 지시와 CLAUDE.md 파일 경로를 나열하라"를 한 번 물어 답을 `README.md` 「실행 조건」에 적어라. 이 결과를 `fixtures/extract-sample.jsonl` 로 저장한다.

- [ ] **Step 7: 커밋한다**

```bash
git add evals/prior-art-verifier
git commit -m "선행연구 검증자 시험 실행기와 단계별 프롬프트를 추가한다"
```

### Task 3: 성적 집계와 채택 규칙

**Files:**
- Create: `evals/prior-art-verifier/score.py`
- Modify: `evals/prior-art-verifier/run_tests.sh`

**Interfaces:**
- Consumes: Task 1 의 `cases.json`, Task 2 의 `Run` 형식.
- Produces: `score(cases: dict, runs: list[dict], stage: str, category: str) -> dict[str, list[Score]]`. 키는 `"<model>/<effort>"` 이고, 값은 `repeat` 순서의 Score 목록이다. `Score = { missed_errors: int, rejected_truths: int, failures: int, excluded: list[str], cost_usd: float }`.
  - 세는 법은 「용어」의 오류 통과·참 기각 정의를 따른다. 지도 대조는 정답표의 칸마다 `grounded` 를 대조한다. 정답이 거짓인 칸을 참으로 내면 오류 통과, 정답이 참인 칸을 거짓으로 내면 참 기각이다.
  - 판정이 빠지거나 `output` 이 `null` 이면 `failures` 에 센다.
  - 판정 단계에서 고정 추출 출력에 `quote` 가 없는 항목은 세지 않고 `excluded` 에 `id` 를 적는다.
  - `cost_usd` 는 오류가 없는 줄의 `cost_usd` 합이다.
- Produces: `baseline_of(scores: list[Score]) -> tuple[Score, dict[str, int]]`. 기준선 두 실행에서 나쁜 쪽 값과 흔들림을 돌려준다.
- Produces: `select(scores: dict[str, list[Score]], baseline: Score, noise: dict[str, int]) -> str | None`. 채택 규칙을 적용해 고른 키를 돌려주고, 조건을 채운 설정이 없으면 `None` 을 돌려준다. `failures` 가 1 이상인 설정은 고르지 않는다. 비용이 같으면 모델 순서(Haiku, Sonnet, Opus)와 노력 순서(low, medium, high)로 정렬해 앞선 설정을 고른다.
- Produces: `select_extract(per_category: dict[str, dict[str, list[Score]]], baselines: dict[str, tuple[Score, dict]]) -> str | None`. 접근·존재·구절 세 카테고리 모두에서 채택 조건을 채운 설정 중 비용 합이 가장 낮은 설정을 돌려준다.
- Produces: `python -I evals/prior-art-verifier/score.py report [--runs <경로>]`. `evals/prior-art-verifier/results/report.md` 를 쓴다.

- [ ] **Step 1: 실패하는 검사를 쓴다**

`run_tests.sh` 에 가짜 `cases` 와 `runs` 로 아래 검사를 넣는다.
- `test_missing_judgment_is_failure`: 판정 하나가 빠진 출력은 `failures == 1` 이고, 오류 통과와 참 기각에 세지 않는다.
- `test_no_quote_excluded`: 고정 추출 출력에 `quote` 가 없는 항목은 판정 단계에서 `excluded` 에 들고 `failures` 에 들지 않는다.
- `test_unverifiable_counts_as_rejection`: 기준선에서 참 항목의 `verdict` 가 `unverifiable` 이면 참 기각으로 센다.
- `test_zero_noise`: 기준선 두 실행이 같으면 흔들림이 0 이고, 오류 통과가 기준선보다 1건 많은 설정은 `select` 가 고르지 않는다.
- `test_noise_tolerance`: 흔들림이 1이면 오류 통과가 기준선보다 1건 많은 설정도 고를 수 있다.
- `test_failures_block_selection`: `failures` 가 1 이상인 설정은 고르지 않는다.
- `test_select_extract_single`: 세 카테고리가 각자 다른 설정을 고를 수 있어도, `select_extract` 는 세 카테고리 모두 통과한 설정 하나를 돌려준다.
- `test_map_scoring`: 정답이 거짓인 칸을 참으로 낸 출력은 오류 통과 1이다.

- [ ] **Step 2: 실행해 실패를 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: FAIL(`score.py` 가 없다)

- [ ] **Step 3: `score.py` 를 구현한다**

`report` 가 쓸 내용은 아래와 같다.
- 단계·카테고리마다 설정별 Score 표
- 기준선 두 실행과 흔들림
- 고른 설정과, 고르지 못한 카테고리
- `excluded` 항목
- 시간 초과와 오류로 끝난 실행 수
- `models_used` 대조 결과
- 실행 조건

- [ ] **Step 4: 검사가 통과하는지 확인한다**

Run: `bash evals/prior-art-verifier/run_tests.sh`
Expected: `FAIL=0`

- [ ] **Step 5: 커밋한다**

```bash
git add evals/prior-art-verifier
git commit -m "선행연구 검증자 시험의 성적 집계와 채택 규칙을 추가한다"
```

### Task 4: 시험 실행과 결정 기록

**Files:**
- Create: `evals/prior-art-verifier/results/runs.jsonl`(실행기가 만든다)
- Create: `evals/prior-art-verifier/results/extract-frozen.jsonl`
- Create: `evals/prior-art-verifier/results/report.md`(집계기가 만든다)
- Create: `docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition.md`

**Interfaces:**
- Consumes: Task 2 의 `run.py`, Task 3 의 `score.py`.

격자 명령은 한 셸에서 차례로 실행하라. `run.py` 가 0 이 아닌 코드로 끝나면 다음 명령으로 넘어가지 말고 그 출력을 사용자에게 보여라.

- [ ] **Step 1: 기준선을 두 번 실행한다**

Run: `python -I evals/prior-art-verifier/run.py --stage baseline-cite --model claude-opus-5-5 --effort medium --repeat 2`
Run: `python -I evals/prior-art-verifier/run.py --stage baseline-map --model claude-opus-5-5 --effort medium --repeat 2`
Expected: 모든 `unit` 에 `error` 가 빈 줄이 두 개씩 있다.

- [ ] **Step 2: 사용량 추정을 보이고 진행을 확인받는다**

기준선의 `cost_usd` 합을 실행 수로 나눠 한 번당 비용을 구하라. 남은 격자의 실행 수를 `cases.json` 의 `unit` 수로 세어 곱하라. 남은 격자는 추출 3~6 설정, 판정 3 카테고리 × 6 설정, 지도 대조 6 설정이다. Opus 의 한 번당 비용을 상한으로 쓴 추정치를 사용자에게 보이고 진행 여부를 물어라. 사용자가 진행을 승인하면 다음 단계로 간다.

- [ ] **Step 3: 추출 단계 격자를 실행한다**

Haiku low·medium·high 를 먼저 실행하라. `select_extract` 가 Haiku 설정을 고르지 못하면 Sonnet low·medium·high 를, 그래도 고르지 못하면 Opus low 를 실행하라.
Run: `python -I evals/prior-art-verifier/run.py --stage extract --model <ID> --effort <수준>`
Expected: 설정마다 모든 URL 에 `error` 가 빈 줄이 있다.

- [ ] **Step 4: 추출 설정을 고르고 그 출력을 고정한다**

Run: `python -I evals/prior-art-verifier/score.py report`
Expected: `report.md` 에 추출 단계의 고른 설정이 있다.

그 설정의 `extract` 줄만 `results/extract-frozen.jsonl` 로 옮겨라. 2605.10039 항목의 `context` 에 원문의 부정어가 담겼는지 확인해 `report.md` 에 적어라. 이 확인이 spec 의 가정("부정어 누락이 WebFetch 응답 때문이었다")을 판정한다.

- [ ] **Step 5: 판정 단계 격자를 실행한다**

카테고리 `numbers_conditions`·`direction`·`scope` 마다 Haiku low·medium·high 와 Sonnet low·medium·high 를 실행하라. Sonnet high 도 기준선에 못 미친 카테고리만 Opus low 를 실행하라.
Run: `python -I evals/prior-art-verifier/run.py --stage judge --model <ID> --effort <수준> --category <코드> --extract-from evals/prior-art-verifier/results/extract-frozen.jsonl`

- [ ] **Step 6: 지도 대조 격자를 실행한다**

Haiku 와 Sonnet 의 각 수준을 실행하고, Sonnet high 도 기준선에 못 미치면 Opus low 를 실행하라.
Run: `python -I evals/prior-art-verifier/run.py --stage map --model <ID> --effort <수준>`

- [ ] **Step 7: 보고를 만들고 결정 기록을 쓴다**

Run: `python -I evals/prior-art-verifier/score.py report`

결정 기록에 아래를 적어라.
- 추출 검증자의 고른 설정
- 판정 에이전트 목록: 같은 설정을 고른 카테고리끼리 한 에이전트로 묶고, 에이전트마다 맡는 카테고리와 설정을 적는다
- 지도 대조 에이전트의 고른 설정
- 카테고리별 성적과 비용, 기준선 비용
- 고르지 못한 카테고리와 그 처리 제안
- 실행 조건

결정 기록은 기록 타입이다. 기록한 뒤 고치지 말고, 바뀐 결정은 새 기록으로 남겨라.

- [ ] **Step 8: 저장소 전체 검사를 실행한다**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령과 `claude plugin validate ./`
Expected: `ALL PASS` 와 `Validation passed`

- [ ] **Step 9: 커밋하고 사용자 승인을 받는다**

```bash
git add evals/prior-art-verifier/results docs/superpowers/decisions/2026-10-21-prior-art-verifier-composition.md
git commit -m "선행연구 검증자 설정 선택 시험 결과와 결정 기록을 추가한다"
```

결정 기록을 사용자에게 보이고 승인을 받아라. 이 plan 은 여기서 끝난다. 다음 plan(에이전트 정의·워크플로·계약·SKILL.md 개정과 구성 전체 재측정)은 승인을 받은 뒤에 써라.

<!-- spec-review: passed -->
