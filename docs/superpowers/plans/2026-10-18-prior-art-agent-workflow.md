# 선행연구 탐색 워크플로 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 탐색 워크플로 `workflows/prior-art-search.js`와, 그 스크립트를 런타임 없이 node 로 실행하는 시험 도구 `scripts/workflow_harness.mjs`와, 시험 도구의 출력을 단언하는 워크플로 테스트 `scripts/test_workflow.sh`를 만든다.

**Architecture:** 워크플로 스크립트는 `meta`, 실행 흐름(본문), 스크립트 끝의 `function` 선언으로 이루어진다. 끝의 선언은 판정 함수(`checkQueries`·`groupByUrl`·`classify`·`mergeStatus`), `schemas()`, 프롬프트 도우미 `prompt()`, 결측 판정 `lacksPrior()`다. 시험 도구는 첫 줄의 `export `만 떼고 본문을 `AsyncFunction`으로 감싼다. `fn` 명령은 본문보다 먼저 `eval`로 끝의 함수를 부르고, `run` 명령은 가짜 훅을 주어 본문을 실행한다. 워크플로 테스트는 시험 도구의 한 줄 JSON 출력을 `json_run`의 파이썬으로 해석해 기대값과 비교한다.

**Tech Stack:** 순수 JavaScript(워크플로 런타임), Node.js ES 모듈(시험 도구, 이 PC 는 v24), bash 와 파이썬(`scripts/_json_valid.sh`의 `json_run`).

**Spec:** 하부 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-specworkflow-design.md`(아래 '하부 명세') 전체와, 큰 명세 `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`(아래 '큰 명세')의 「출력 스키마」「공유 결정」「경계」「다시 나눈 분할」「결정 기록」. 하부 명세와 큰 명세가 다르면 큰 명세의 계약 표와 계약 코드 `scripts/prior_art_contract.json`을 따른다.

**용어.** 이 plan 은 `scripts/test_workflow.sh`를 '워크플로 테스트'로, `scripts/test_prior_art_contract.sh`를 '계약 테스트'로 부른다. 하부 명세는 앞의 파일도 '계약 테스트'로 부른다.

## Global Constraints

- **수정 허용 경로** — 구현 워커는 `workflows/prior-art-search.js`, `scripts/workflow_harness.mjs`, `scripts/test_workflow.sh`만 만들거나 고친다. 다른 파일을 바꿔야 하면 구현 워커는 고치지 않고 BLOCKED 로 컨트롤러에게 보고한다.
- **등록 이름** — 파일 이름과 `meta.name`은 `prior-art-search`다. `agentType`은 `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`다.
- **런타임 금지 호출** — 스크립트는 `Date.now`, `Math.random`, 인자 없는 `new Date(`, `require(`, `import `를 쓰지 않고, 훅 `pipeline`·`budget`·`workflow`도 쓰지 않는다.
- **`meta`** — 첫 줄이 `export const meta = {`이고 순수 리터럴이다. 키는 `name`, 한 줄 `description`, `whenToUse`, `phases`이고 `phases` 제목은 `Research`·`Verify`·`Synthesize`·`MapCheck`다. `export `로 시작하는 줄은 이 줄 하나다. `meta` 안의 문자열에는 괄호를 쓰지 않는다(워크플로 테스트가 `meta` 구간의 `(`를 금지한다).
- **`model`·`effort`** — 어느 `agent()` 호출에도 넣지 않는다.
- **TDZ 함정** — 스키마 상수를 최상위 `const`로 두지 않는다. `schemas()`가 호출될 때 네 상수를 만들어 돌려주고, 본문도 `schemas()`를 불러 쓴다. 시험 도구가 본문보다 먼저 `eval(__fn)`을 실행하기 때문이다.
- **끝의 함수** — 스크립트 끝의 `function` 선언은 본문의 `const`와 훅(`agent`·`log` 등)을 참조하지 않는다. 정규식은 함수 안에 리터럴로 둔다.
- **스키마 `required`** — 원소의 `required`는 계약 코드의 같은 자료와 같다. 루트 `required`는 하부 명세 「출력 스키마 상수」 표를 따른다. 모든 객체 스키마에서 `required`는 `properties`의 부분집합이다.
- **단언 규칙** — 워크플로 테스트는 `set -euo pipefail`로 시작하고 `scripts/_test_check.sh`의 `check`와 `scripts/_json_valid.sh`의 `json_run`을 쓴다. 실패할 수 있는 명령(시험 도구, `awk`, `grep`)은 모두 `check`의 조건 문자열 안에서 실행한다. `! 명령 | grep` 부정 단언을 쓰지 않는다. 시험 도구 출력을 `grep -c`로 세지 않는다. 입력은 `<<'EOF'` heredoc 이고 시험 도구에는 표준 입력으로 넘긴다. 끝 줄은 `echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]`이다.
- **문서와 주석** — 한국어 문어체로 쓴다. 옛 이름 `lens-prior-art`를 이 plan 이 만드는 파일 어디에도 쓰지 않는다.

## 스스로 정한 내부 규칙

하부 명세가 비워 둔 규칙을 아래처럼 정한다. 컨트롤러는 이 규칙을 서브 세션 리포트의 「스스로 판정한 모호함」과 「명세 이탈」에 적는다.

**선행 서술 결측.** 큰 명세 계약 표 `researcher` 행의 결측 처리는 `lacksPrior(item)` 하나가 판정한다. 하부 명세 「판정 함수」의 함수 목록에는 없지만, `groupByUrl`과 `classify`가 함께 쓰는 판정이라 한 곳에 둔다. 이슈 항목은 `text`가 공백뿐이면 참이다. 근거 지도 항목은 `row.case`가 공백뿐이거나 네 축의 `prior`가 모두 공백뿐이면 참이다. 계약 표의 '공백만 있거나'를 세 칸 모두에 적용한 판정이다. 값이 문자열이 아니면 `String(v ?? '')`로 본다.

**결측 항목과 묶음.** `groupByUrl`은 결측 항목을 `items`에 남기되 어느 묶음의 `claims`에도 넣지 않는다. 그 항목 때문에 묶음의 `subquestions`가 늘지 않고, 그 항목의 URL 만 인용한 묶음은 생기지 않는다. `classify`는 결측 항목을 판정을 보지 않고 `rejected`에 둔다. 사유는 하부 명세 「사유의 위치」에 칸이 없으므로 반환값에 키를 더하지 않는다. 오케스트레이터는 판정이 없는 `rejected` 원소의 사유를 도출해야 하며, 이 사실은 리포트 「제안」으로 현재 세션에 넘긴다.

**인용 URL.** 인용의 `url`은 `String(c.url ?? '')`로 보고, 빈 문자열이면 URL 이 없는 인용이다. 연구자 출력에 `evidence_map`이 없으면 빈 배열로 본다.

**보낸 참조.** `classify`가 URL 하나에 '보낸 참조'로 보는 것은 그 URL 을 `urls`에 가지고 `lacksPrior`가 거짓인 항목의 `ref`다. 이 집합은 `groupByUrl`의 그 묶음 `claims`와 같다. `verifiers`에 원소가 없는 URL 은 검증자가 실패한 URL 로 본다.

**판정 모으기.** `classify`는 판정을 `ref`마다 배열로 모은다. URL 하나의 판정이 다른 URL 의 판정을 덮어쓰지 않는다.

**원소 차례.** `checkQueries`의 결과는 연구자 차례, 그 안에서 검색어 차례이며, 한 검색어 안에서는 `forbidden-term`이 `path-shape`보다 앞이다.

**경로 형태 정규식.** 하부 명세 「판정 함수」의 '`.` 뒤 영문자로 시작하는 1~5자의 확장자'를 `\.[A-Za-z][^.\\/]{0,4}$`로 옮긴다. 둘째 글자부터는 마침표와 경로 구분자가 아닌 글자다.

**사용법 오류.** 시험 도구의 종료 코드 2 는 알 수 없는 명령 이름, 판정 함수와 `schemas`가 아닌 함수 이름, 첫 줄 형식 위반, 표준 입력의 JSON 해석 실패다.

**빈 하위 질문.** `args.subquestions`가 빈 배열이면 `overall_status`는 하부 명세의 정의대로 `ok`다. 계약 표 `args` 행이 결측이 없다고 정하므로 이 입력을 따로 막지 않는다.

**`phase()` 호출.** 본문은 연구자 실행 앞에서 `phase('Research')`, 인용 판정 앞에서 `phase('Verify')`, 종합 앞에서 `phase('Synthesize')`, 지도 대조 앞에서 `phase('MapCheck')`를 부른다. 결정론 단계에서는 부르지 않는다.

**프롬프트 도우미.** `prompt(mode, principlesPath, input)`은 `` `MODE: ${mode}\nPRINCIPLES: ${principlesPath}\n\`\`\`json\n${JSON.stringify(input, null, 2)}\n\`\`\`` ``를 돌려준다.

---

### Task 1: 시험 도구와 스키마 상수

**Files:**
- Create: `scripts/workflow_harness.mjs`
- Create: `workflows/prior-art-search.js`. 이 태스크에서는 `meta`, `schemas()`, 본문 `return null`과, 본문이 `throw new Error('미구현')`인 `checkQueries`·`groupByUrl`·`classify`·`mergeStatus`·`lacksPrior` 선언을 둔다.
- Create: `scripts/test_workflow.sh`

**Interfaces:**
- Produces:
  - `node scripts/workflow_harness.mjs fn <이름>` — 표준 입력으로 인자 배열을 받고, 반환값을 `JSON.stringify` 한 줄로 표준 출력에 쓴다. 이름은 `checkQueries`·`groupByUrl`·`classify`·`mergeStatus`·`schemas`만 받는다.
  - `node scripts/workflow_harness.mjs run` — 표준 입력으로 `{ args, responses }`를 받고, `{ result, calls, logs }`를 한 줄로 쓴다. `responses`의 키는 `agent()`의 `opts.label`이다. 키가 없는 `label`을 부르면 치명 오류이고, 표준 오류에 그 `label`이 든 문구를 쓴 뒤 종료 코드 1 로 끝난다. `calls[]`는 `{ label, agentType, phase, model, effort, prompt }`이며 값이 `undefined`인 칸은 JSON 에서 빠진다.
  - 종료 코드는 성공이 0, 스크립트 예외와 치명 오류가 1, 사용법 오류(「스스로 정한 내부 규칙」)가 2 다.
  - `schemas()`는 `{ RESEARCHER_SCHEMA, VERIFIER_SCHEMA, SYNTHESIS_SCHEMA, MAP_SCHEMA }`를 돌려준다.
  - 워크플로 테스트의 변수 `HERE`(저장소 루트), `WF`(워크플로 경로), `FX`(`mktemp -d` 픽스처 디렉터리, `trap`으로 지운다)를 둔다.
  - 워크플로 테스트의 도우미 `harn <명령> [이름]`은 시험 도구를 실행한다(표준 입출력은 호출자가 잇는다).
  - 도우미 `json_true <파일> '<파이썬 식>'`은 그 파일을 읽은 값 `d`에 대해 식이 참이면 0 을 돌려준다. 식 안에서 계약 코드를 `C`로 읽을 수 있다.
  - 도우미 `json_same <파일 A> <파일 B>`는 두 파일을 `json.dumps(json.load(f), sort_keys=True, ensure_ascii=False)` 문자열로 바꿔 같으면 0 을 돌려준다. 그래서 `true`와 `1`은 다르다.

- [ ] **Step 1: 실패하는 워크플로 테스트를 쓴다**

`scripts/test_workflow.sh`의 머리 주석은 "탐색 워크플로를 시험 도구로 실행해 판정 함수와 실행 흐름을 검증한다. 계약: FAIL=0 (매직넘버 금지 — 개수는 테스트가 센다)."로 쓴다. 이 단계에서 `[정적 형식]`과 `[시험 도구 자체]` 묶음을 쓴다.

`[정적 형식]` 묶음의 단언은 하부 명세 「계약 테스트」 표의 `[정적 형식]` 행을 옮긴다.
- `command -v node`가 성공한다.
- 첫 줄이 `export const meta = {`로 시작한다.
- `grep -cE '^[[:space:]]*export ' "$WF"`가 1 이다.
- `meta` 구간은 첫 줄부터 줄 전체가 `}`나 `};`인 첫 줄까지다. 한 `check` 안에서 `awk`로 구간을 `$FX/meta.txt`에 자르고, 구간이 셋째 줄 이상이며 마지막 줄이 `}`나 `};`인지 보고, `&&`로 이어 `(`·`${`·`...`·백틱의 `grep -cF`가 각각 0 인지 본다. 그래서 구간이 비면 이 단언은 FAIL 이다.
- `meta` 구간에 `name: 'prior-art-search'`, `description:`, `whenToUse:`, `'Research'`·`'Verify'`·`'Synthesize'`·`'MapCheck'`가 각각 있다.
- 원문에서 `Date.now`·`Math.random`·`new Date(`·`require(`·`import `의 `grep -cF` 줄 수가 각각 0 이다(파일이 있어야 하므로 `[ -f "$WF" ] &&`를 앞에 둔다).
- `harn fn schemas`의 출력에서 네 상수 모두 루트 `type`이 `object`이다. `required`나 `properties`가 있는 모든 노드에서 `required`가 `properties`의 키에 든다(파이썬 재귀 검사).
- `VERIFIER_SCHEMA`의 `judgments.items.properties.verdict.enum`이 `['supported','unsupported','unverifiable']`이다. `RESEARCHER_SCHEMA`의 `search_status.enum`이 `['ok','no-results','failed','not-attempted']`이다.
- 루트 `required`가 집합으로 하부 명세 표와 같다. 연구자는 `search_status`·`queries`·`issues`, 검증자는 `url`·`judgments`·`principles_applied`, 종합은 `evidence_map`·`conclusions`·`principles_applied`, 지도 대조는 `cells`·`principles_applied`다.

`[시험 도구 자체]` 묶음의 단언은 종료 코드를 `check` 안에서 `harn ... ; [ $? -eq <값> ]` 형태로 비교한다.
- `fn nosuch`(입력 `[]`)의 종료 코드가 2 다.
- `run`에 깨진 JSON 입력을 주면 종료 코드가 2 다.
- `fn checkQueries`에 인자 `[[],[]]`를 주면 미구현 함수의 예외로 종료 코드가 1 이다. 이 단언은 Task 2 에서 지운다.

- [ ] **Step 2: 실패를 확인한다**

Run: `bash scripts/test_workflow.sh; echo "rc=$?"`
Expected: 마지막에 `PASS=… FAIL=…` 줄과 `rc=1`이 나온다. node 단언만 PASS 이고 나머지 단언은 FAIL 이다.

- [ ] **Step 3: 시험 도구와 스크립트 골격을 만든다**

시험 도구는 하부 명세 「시험 도구」절을 그대로 구현한다. 스크립트 경로는 `new URL('../workflows/prior-art-search.js', import.meta.url)`이다. 본문은 `'use strict';\nif (__fn) return eval(__fn)(...__fnArgs);\n` 뒤에 첫 줄의 맨 앞 7글자를 뗀 원문을 붙인다. 매개변수는 `agent, parallel, phase, log, args, __fn, __fnArgs`이고, 생성자는 `Object.getPrototypeOf(async function(){}).constructor`다.

가짜 `agent`는 하부 명세 「시험 도구」의 '가짜 `agent(prompt, opts)`'를 따른다. 스키마 검사는 루트부터 `properties`의 값과 `items`를 따라 재귀로 내려가며, `required`나 `properties`가 있는 노드마다 `required ⊆ keys(properties)`를 본다. 응답은 `structuredClone`으로 복사한다. 치명 오류는 모듈 변수 `fatal`에 문구를 남기고 예외를 던진다. 실행이 끝난 뒤 `fatal`이 있으면 시험 도구는 표준 오류에 그 문구를 쓰고 종료 코드 1 로 끝난다. 가짜 `parallel`은 thunk 를 차례로 `await`하고 예외는 `null`로 바꾼다.

스키마는 하부 명세 「출력 스키마 상수」 표와 계약 코드대로 만든다. 연구자 스키마의 `evidence_map`은 `properties`에만 두고 루트 `required`에 넣지 않는다. 종합 스키마의 `evidence_map` 원소 `axes`는 `{ type: 'object' }`로 둔다. `meta.whenToUse`는 "agent-prior-art 오케스트레이터가 사용자가 승인한 프로토콜로만 실행한다."이다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_workflow.sh; bash scripts/test_prior_art_contract.sh`
Expected: 두 스크립트 모두 `FAIL=0`이다. 계약 테스트는 `SKIP: agents` 줄을 내고, `스키마 … 가 계약 코드와 맞는다` 단언이 네 상수 모두 PASS 다.

- [ ] **Step 5: 커밋한다**

```bash
git add scripts/workflow_harness.mjs workflows/prior-art-search.js scripts/test_workflow.sh
git commit -m "탐색 워크플로 시험 도구와 스키마 상수를 만든다"
```

### Task 2: 판정 함수

**Files:**
- Modify: `workflows/prior-art-search.js`(Task 1 이 선언한 `checkQueries`·`groupByUrl`·`classify`·`mergeStatus`·`lacksPrior`의 본문을 채운다)
- Modify: `scripts/test_workflow.sh`(Task 1 의 미구현 단언을 지우고 판정 함수 묶음을 덧붙인다)

**Interfaces:**
- Consumes: Task 1 의 `harn`, `json_same`, `FX`.
- Produces(모두 순수 함수이며 형식의 원본은 하부 명세 「판정 함수」와 이 plan 의 「스스로 정한 내부 규칙」이다):
  - `checkQueries(researchers, forbiddenTerms)`는 `[{ id, query, rule }]`을 돌려주고, `rule`은 `'forbidden-term'`이나 `'path-shape'`다.
  - `groupByUrl(researchers)`는 `{ items: [{ ref, urls, text, row? }], groups: [{ url, subquestions, claims: [{ ref, text }] }] }`를 돌려준다.
  - `classify(items, verifiers)`는 `{ passed, rejected, unverifiable, verify_failed }`를 돌려준다. `verifiers`는 `[{ url, subquestions, output }]`이다.
  - `mergeStatus(researchers, items, classified)`는 `{ coverage, subquestion_status, overall_status }`를 돌려준다.
  - `lacksPrior(item)`은 불리언을 돌려준다.

- [ ] **Step 1: 실패하는 판정 함수 묶음을 쓴다**

묶음마다 입력 heredoc 을 `$FX/<이름>_in.json`에, 기대값 heredoc 을 `$FX/<이름>_want.json`에 쓴다. 단언은 `check "<설명>" "harn fn <함수> < \"\$FX/<이름>_in.json\" > \"\$FX/<이름>_got.json\" && json_same \"\$FX/<이름>_got.json\" \"\$FX/<이름>_want.json\""` 형태 한 줄이다. 한 묶음에 입력과 기대값의 쌍을 여럿 두어도 된다. heredoc 의 JSON 안에서 역슬래시는 `\\`로 적는다. 하부 명세 「계약 테스트」 표의 각 행을 아래 입력으로 덮는다.

`[질의 경계 검사]` 묶음의 입력은 아래와 같다.
- 연구자 S1 의 `queries`는 `acme agent plugin`, `see skills/agent-prior-art/SKILL.md`, `C:\Users\x\a.md notes`, `~/.claude config`, `cite (docs/x.md),`, `A/B testing`, `HTTP/1.1 caching`, `prior art search agent`, `Acme Beta /etc/x`이다.
- 금지어는 `["Acme", "beta", ""]`이다.
- 연구자 S2 는 `output: null`이다.

기대 배열에서 앞의 검색어 다섯 개는 원소를 하나씩 낸다. 첫째는 `forbidden-term`이고 나머지는 `path-shape`다. 마지막 검색어는 `forbidden-term`과 `path-shape` 원소를 이 차례로 낸다. 그 밖의 검색어는 원소를 내지 않는다.

`[URL 묶기]` 묶음의 입력은 아래와 같다.
- S1 이슈 0 은 `https://a`, `https://a`, `https://b`를 인용한다.
- S1 이슈 1 은 `kind: 'derived'`이고 `url: ''`인 인용 하나와 `url` 키가 없는 인용 하나를 가진다.
- S1 근거 지도 행 0 은 `url: 'https://a'`이고, 행 1 은 `url: ''`이다.
- S2 는 `evidence_map` 키가 없고, 이슈 0 이 `https://a`를, 이슈 1(`prior_claim: '  '`)이 `https://c`를 인용한다.
- S3 은 `output: null`이다.

기대값의 `items` 차례는 `S1#issue#0`, `S1#issue#1`, `S1#case#0`, `S1#case#1`, `S2#issue#0`, `S2#issue#1`이다. 근거 지도 항목의 `text`는 `JSON.stringify({ case, outcome, prior: { purpose, mechanism, evaluation, target } })`가 내는 문자열이며, 기대값 파일에는 그 문자열을 직접 적는다. `row`는 행 전체다. `groups`는 `https://a`(`subquestions` `['S1','S2']`, 참조 `S1#issue#0`·`S1#case#0`·`S2#issue#0`)와 `https://b`(`['S1']`, `S1#issue#0`)이며, `https://c` 묶음은 없다.

`[통과 판정]` 묶음은 하부 명세 표의 `[통과 판정]` 행이 적은 조건마다 항목 하나를 만들고, 아래 항목을 더한다.
- 두 URL 의 검증자가 모두 응답했고 앞 URL 이 `supported`, 뒤 URL 이 `unsupported`인 항목은 `passed`에 있다.
- 결측 항목이 응답한 검증자의 URL 을 공유하면, 그 항목은 `rejected`에 있고 그 검증자는 `verify_failed`에 없다.
- `verifiers`에 원소가 없는 URL 을 인용한 항목은 판정 목록 어디에도 없고 `verify_failed`에 그 URL 원소가 있다.
- 판정을 빠뜨린 묶음의 다른 참조가 `supported`를 받았어도 그 참조는 `passed`에 없다.
- 검증자 출력의 `url`을 보낸 URL 과 다르게 적은 묶음이 있다.
- 보내지 않은 참조 `S9#issue#0`의 `supported` 판정을 넣은 묶음이 있다.

`[상태 합치기]` 묶음의 첫 입력은 하위 질문 S1·S2·S3·S4·S10 이다. S1 은 `ok`이고 항목 셋 중 통과 하나이며 `verify_failed`에 `S1#` 참조가 있다. S2 는 `ok`이고 항목이 없다. S3 은 `output: null`이고, S4 는 `no-results`다. S10 은 `ok`이고 `verify_failed`에 `S10#` 참조가 있다. 기대값에서 S1·S10 은 `partial`이고 S2 는 `ok`이며 `overall_status`는 `not-ok`다. `coverage`의 `cases_found`와 `passed`를 정수로 적는다. 둘째 입력은 S2 만 있고 기대 `overall_status`는 `ok`다.

- [ ] **Step 2: 실패를 확인한다**

Run: `for h in '[질의 경계 검사]' '[URL 묶기]' '[통과 판정]' '[상태 합치기]'; do printf '%s ' "$h"; bash scripts/test_workflow.sh 2>&1 | awk -v h="$h" '$0==h{f=1;next} /^\[/{f=0} f' | grep -c '^  FAIL:'; done`
Expected: 묶음마다 1 이상이 나온다(함수가 `미구현` 예외를 던진다).

- [ ] **Step 3: 함수 본문을 구현한다**

`checkQueries`의 토큰 처리와 경로 판정은 아래와 같다. 이 정규식은 하부 명세의 문구와 「스스로 정한 내부 규칙」의 '경로 형태 정규식'을 옮긴 것이다.

```js
const t = tok.replace(/^["'`()\[\],.:;]+|["'`()\[\],.:;]+$/g, '')
const isPath = /^(~\/|\.\.?\/|\/)/.test(t) || /^[A-Za-z]:[\\/]/.test(t) ||
  (/[\\/]/.test(t) && /\.[A-Za-z][^.\\/]{0,4}$/.test(t))
```

`classify`는 하부 명세 「목록의 행선지」 표를 위 행부터 적용한다. 보낸 참조, 판정 모으기, 결측 항목은 「스스로 정한 내부 규칙」을 따른다.

- [ ] **Step 4: 통과를 확인한다**

Run: `bash scripts/test_workflow.sh`
Expected: `FAIL=0`.

- [ ] **Step 5: 커밋한다**

```bash
git add workflows/prior-art-search.js scripts/test_workflow.sh
git commit -m "탐색 워크플로의 판정 함수를 만든다"
```

### Task 3: 실행 흐름

**Files:**
- Modify: `workflows/prior-art-search.js`(본문과 `prompt` 도우미)
- Modify: `scripts/test_workflow.sh`(실행 흐름 묶음과 `[시험 도구 자체]`의 응답표 누락 단언)

**Interfaces:**
- Consumes: Task 2 의 판정 함수, Task 1 의 `schemas()`, `harn`, `json_true`, `FX`, 그리고 `responses` 키가 `label`이라는 시험 도구 규칙.
- Produces: 워크플로 반환값. 키 차례는 `round, passed, rejected, unverifiable, verify_failed, coverage, subquestion_status, overall_status, query_violations, verifier_count, researchers, verifiers`이고, `survey` 모드이면 `synthesis, map_check`가 뒤따른다.

- [ ] **Step 1: 실패하는 실행 흐름 묶음을 쓴다**

`args`는 계약 코드 `args`의 키를 모두 채운다. 하위 질문은 S1·S2, `principles_path`는 `'D:/x/agent-principles.md'`, `forbidden_terms`는 `['Acme']`, `round`는 1 이다. 응답표의 키는 `research:S1`, `research:S2`, `verify:<URL>`, `synthesize`, `map-check`다. 단언은 `check` 안에서 `harn run < 입력 > 출력 && json_true 출력 '<식>'` 형태로 쓴다.

- `[실행 흐름: contrast]` — 하부 명세 표의 같은 행 전부를 단언한다. 연구자 응답은 `evidence_map` 키를 두지 않는다. 탐색 프롬프트를 줄로 나눠 셋째 줄이 `` ```json ``이고 마지막 줄이 `` ``` ``인지 본다. 그 사이를 `json.loads`한 값의 키 집합이 `{question, situation, target, mode, subquestion, forbidden_terms}`이고 `subquestion`이 `args.subquestions`의 같은 원소와 같은지 본다. 반환값의 키 집합은 계약 코드 `result`의 키에서 `?`가 붙은 키를 뺀 집합과 같다(`C`로 계약 코드를 읽는다).
- `[실행 흐름: survey]` — 하부 명세 표의 같은 행 전부를 단언한다. 통과 행이 없는 응답표와 종합 응답이 `null`인 응답표는 따로 실행한다. `passed_rows`의 원소는 `{ ref, row }`이고 `row`가 연구자 응답의 그 행과 같다.
- `[실패 행선지]` — 하부 명세 표의 같은 행 전부를 단언한다.
- `[시험 도구 자체]`에 덧붙인다. 응답표에 `research:S2`가 없는 입력으로 `run`을 실행하면 종료 코드가 1 이고 표준 오류에 `research:S2`가 있다. 연구자 호출은 `parallel()` 안에 있어 가짜 `parallel`이 그 예외를 `null`로 바꾸므로, 이 단언은 예외가 삼켜져도 `fatal` 표시로 실패가 드러나는지 확인한다.

- [ ] **Step 2: 실패를 확인한다**

Run: Task 2 Step 2 의 명령에서 묶음 머리를 `'[실행 흐름: contrast]' '[실행 흐름: survey]' '[실패 행선지]' '[시험 도구 자체]'`로 바꿔 실행한다.
Expected: 묶음마다 1 이상이 나온다(본문이 `return null`이다).

- [ ] **Step 3: 본문을 구현한다**

하부 명세 「실행 흐름」의 단계를 차례로 따르고, `phase()`는 「스스로 정한 내부 규칙」대로 부른다. `parallel()`의 thunk 는 `() => agent(...)`만 돌려주고, 짝짓기는 반환 배열의 위치로 한다. 통과 행은 `passed` 중 `ref`에 `#case#`가 든 원소를 `items`의 같은 `ref` 항목의 `row`와 짝지어 만든다.

- [ ] **Step 4: 저장소 검사를 확인한다**

Run: CLAUDE.md 「변경 뒤 실행」의 명령 `d=$(mktemp -d); for t in scripts/test_*.sh; do ( bash "$t" > "$d/$(basename "$t").log" 2>&1 || echo "$t" >> "$d/bad" ) & done; wait; if [ -s "$d/bad" ]; then echo "FAILED:"; while read -r t; do echo "--- $t"; grep 'FAIL:' "$d/$(basename "$t").log"; done < "$d/bad"; else echo "ALL PASS"; fi`, 그다음 `bash scripts/test_prior_art_contract.sh | grep -F 'SKIP: agents'`, 그다음 `claude plugin validate ./`
Expected: 첫 명령은 `ALL PASS`를 낸다. 둘째 명령은 `SKIP: agents` 줄 하나를 낸다. validate 는 `Validation passed with warnings`이고, 경고는 변경 전 기준과 같은 하나(`root: CLAUDE.md at the plugin root is not loaded as project context`)뿐이다.

- [ ] **Step 5: 커밋한다**

```bash
git add workflows/prior-art-search.js scripts/test_workflow.sh
git commit -m "탐색 워크플로의 실행 흐름을 만든다"
```

## Review Focus

- **경로처럼 보이는 정상 검색어** — `A/B testing`, `HTTP/1.1` 같은 검색어는 위반이 아니어야 한다. Task 2 `[질의 경계 검사]`가 고정한다.
- **한 URL 만 실패한 항목** — 다른 URL 이 `unsupported`이면 탈락으로 단정하지 않아야 한다. Task 2 `[통과 판정]`이 고정한다.
- **여러 URL 의 판정이 엇갈린 항목** — `supported` 하나가 있으면 통과해야 한다. Task 2 `[통과 판정]`이 고정한다.
- **`S1`과 `S10` 접두사 충돌** — `S10#` 참조가 S1 을 `partial`로 만들면 안 된다. Task 2 `[상태 합치기]`가 고정한다.
- **응답표에 없는 호출이 조용히 `null`로 통과하는 것** — 시험 도구가 종료 코드 1 과 그 `label`을 낸다. Task 3 `[시험 도구 자체]`가 고정한다.

<!-- spec-review: passed -->
