# 선행연구 에이전트 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `lens-prior-art`를 지우고, 스킬 `agent-prior-art`와 연구자·검증자 에이전트 정의와 탐색 워크플로와 발동 넛지로 이루어진 선행연구 에이전트를 만든다.

**Architecture:** 메인 세션이 `agent-prior-art`의 오케스트레이터 절차를 따르며 단계마다 사용자 승인을 받는다. 탐색은 `workflows/prior-art-search.js`가 연구자와 검증자를 실행하고, 스크립트 안의 순수 함수가 질의 경계 검사·URL 묶기·통과 판정·상태 합치기를 결정론으로 한다. 발동은 UserPromptSubmit 넛지가 알린다.

**Tech Stack:** bash(훅·계약 테스트), JavaScript(워크플로 스크립트, node 로 실행하는 시험 도구), Markdown(스킬·에이전트 정의).

**Spec:** `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`

## Global Constraints

- 탐색 모드 연구자 수는 통상 2, 최대 20 이다(사용자 결정).
- 연구자와 검증자의 `maxTurns`는 20 이고, 두 정의의 `tools`에는 `Agent`가 없다.
- 연구자의 `tools`는 `WebSearch, WebFetch, Read, Grep, Glob`이고, 검증자의 `tools`는 `WebFetch, Read`다.
- 에이전트 등록 이름은 `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`다.
- 공백 라운드는 한 연구 질문에 1회까지다.
- `dispatching-lenses`의 단계당 10개 상한은 선행연구 에이전트에 적용되지 않는다.
- 넛지를 끄는 변수는 `DISCIPLINED_CODER_PRIOR_ART_NUDGE=off`이고, 넛지는 차단하지 않으며 세션당 횟수 제한이 없다.
- 넛지 주제어는 "선행연구", "prior art", "선행 사례", "누가 해봤", "선행연구렌즈", "lens-prior-art"이고, 요청형 표현은 "찾아", "뒤져", "조사해", "해봐", "있나", "없나"다. Task 5 의 발동 시험 결과로 이 목록을 고칠 수 있다.
- 출력의 `lens` 칸은 `agent` 칸이 되고 값은 `agent-prior-art`다. `kind` 열거는 `peer-reviewed|preprint|vendor|blog|standard|derived`다.
- 검증자 판정 기준 문장은 "옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported"를 그대로 쓴다.
- 원본 파일 이름은 `search-r<n>.json`, `researcher-<하위 질문 ID>-r<n>.json`, `verifier-r<n>.json`, `synthesis-r<n>.json`, `map-check-r<n>.json`이다.
- `search_status`의 값은 `ok`, `no-results`, `failed`, `not-attempted` 중 하나이고, `verification_status`의 값은 `ok`, `partial` 중 하나다. `overall_status`는 모든 하위 질문의 두 값이 `ok`일 때만 `ok`가 된다.
- 기준선 프롬프트는 커밋 `7a2d26d`의 `skills/lens-prior-art/SKILL.md`에 있다.
- 모든 문서 문장은 에이전트원칙의 출력지시를 따른다. 저장소 계약 테스트는 FAIL=0 이 계약이며 기대 개수를 숫자로 박지 않는다.
- 묶음 하나의 FAIL 수는 `bash <스크립트> 2>&1 | awk -v h='<묶음 머리>' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c FAIL`로 센다. 이 명령은 묶음 머리부터 다음 묶음 머리까지만 세므로 묶음의 줄 수에 기대지 않는다.
- 모든 작업은 브랜치 `feat/prior-art-agent`에서 한다. Task 5 를 통과하고 사용자가 승인하기 전에는 main 에 병합하지 않으며 push 하지 않는다.
- 변경 뒤 CLAUDE.md 「변경 뒤 실행」의 명령과 `claude plugin validate ./`를 실행한다.

## Review Focus

- **검증자 실패가 섞인 실행** — 검증자 `agent()` 하나가 `null`을 돌려주면, 그 URL 에만 기댄 항목은 검증 실패 목록에만 들어가고 해당 하위 질문의 `verification_status`가 `partial`이 되어야 한다(Task 1 의 `null 검증자` 시험).
- **연구자 실패** — 연구자 `agent()`가 `null`을 돌려주면 그 하위 질문의 `search_status`는 `failed`이고 `overall_status`는 `ok`가 아니어야 한다(Task 1 의 `null 연구자` 시험).
- **질의 경계의 오탐** — "prior art" 같은 일반 영어 구가 금지 목록이나 경로 정규식에 해당하면 안 된다(Task 1 의 `checkQueries` 음성 시험).
- **언급만 하는 메시지와 따옴표가 든 메시지** — "lens-prior-art 문구를 고쳐 줘"에는 넛지가 뜨지 않고, 큰따옴표가 든 요청 메시지에는 넛지가 떠야 한다(Task 3 의 음성·양성 시험).
- **한 URL 을 여러 하위 질문이 인용** — 검증자는 URL 마다 한 번만 실행되고, 판정은 그 URL 을 인용한 하위 질문 모두에 반영되어야 한다(Task 1 의 `groupByUrl` 시험).

---

## File Structure

| 파일 | 할 일 | Task |
|---|---|---|
| `workflows/prior-art-search.js` | 탐색 워크플로와 순수 함수 | 1 |
| `scripts/workflow_harness.mjs` | 가짜 `agent()`로 워크플로를 실행하는 시험 도구 | 1 |
| `scripts/test_workflow.sh` | 워크플로 계약 테스트 | 1 |
| `agents/prior-art-researcher.md` | 연구자 정의 | 2 |
| `agents/prior-art-verifier.md` | 검증자 정의 | 2 |
| `skills/agent-prior-art/SKILL.md` | 오케스트레이터 절차와 판정 규약 | 2 |
| `scripts/test_docs_drift.sh` | 새 검사 묶음 추가와 옛 검사 갱신 | 2, 4 |
| `hooks/prior_art_nudge_userpromptsubmit.sh` | 발동 넛지 | 3 |
| `hooks/hooks.json`, `scripts/test_hooks.sh`, `README.md` | 넛지 연결과 계약 테스트와 문서 | 3 |
| `skills/review-specs`, `review-docs`, `dispatching-lenses`, `aggregating-lenses`, `audit-repo-docs`, `lens-fit`, `domain-plugin`의 `SKILL.md`, `skills/nested-orchestration/references/sub-session-protocol.md`, `agent-principles.md`, `docs/domain-discipline.md`, `scripts/test_audit.sh` | 참조 처리 | 4 |
| `skills/lens-prior-art/` | 디렉터리 삭제 | 4 |
| `docs/superpowers/reviews/<Task 5 Step 1 실행일>-prior-art-agent-check.md`와 같은 이름 폴더 | 병합 전 시험 기록 | 5 |

---

### Task 1: 작업 브랜치, 탐색 워크플로와 그 시험 도구

**Files:**
- Create: `workflows/prior-art-search.js`
- Create: `scripts/workflow_harness.mjs`
- Create: `scripts/test_workflow.sh`

**Interfaces:**
- Consumes: 없음.
- Produces:
  - 워크플로 `args`(프로토콜): `{ question, situation, target, mode: "contrast"|"survey", round: 1|2, subquestions: [{ id, scope, include, exclude }], forbidden_terms: [string], principles_path }`.
  - 탐색 모드 연구자 출력(`RESEARCHER_SCHEMA`): `{ agent, mode, subquestion_id, search_status, read, queries, issues: [{ where, type, claim, consequence, evidence, citations: [{ url, kind, opened }] }], evidence_map: [{ case, url, axes: { purpose, mechanism, evaluation, target }, outcome, kind, source_level, route, adoption? }], saturation, not_found, disclosures, principles_applied, notes }`. 탐색 모드 연구자는 `survey`에서만 자기 하위 질문의 `evidence_map` 행을 채우고, `contrast`에서는 빈 배열을 둔다.
  - 주장 참조 `ref`의 형식은 `<subquestion_id>#<issue|case>#<index>`다(예: `sq1#issue#0`). `index`는 그 연구자 출력의 `issues`나 `evidence_map` 배열 위치다.
  - 검증자 인용 판정 출력(`VERIFIER_SCHEMA`): `{ url, judgments: [{ ref, verdict: "supported"|"unsupported"|"unverifiable", quote, reason }], principles_applied }`. 워크플로는 `verifier-r<n>.json`에 쓸 배열의 판정마다 `ref`에서 하위 질문 ID 를 꺼내 `subquestion_id` 칸으로 붙인다.
  - 종합 모드 연구자 출력(`SYNTHESIS_SCHEMA`): `{ evidence_map: [행], conclusions: [{ text, refs: [string] }], principles_applied }`. 행의 칸은 탐색 모드의 `evidence_map` 행과 같고, 통과 목록의 행만으로 만든다.
  - 지도 대조 출력(`MAPCHECK_SCHEMA`): `{ cells: [{ row, column, grounded: boolean, source_ref }], principles_applied }`.
  - 워크플로 반환값: `{ round, passed: [item], rejected: [item], unverifiable: [item], verify_failed: [{ url, refs }], coverage: [{ id, cases_found, passed }], subquestion_status: [{ id, search_status, verification_status }], overall_status, query_violations: [{ id, query, rule }], verifier_count, researchers: [출력], verifiers: [출력], synthesis?, map_check? }`. `item`은 `{ ref, urls }`다. `verifier_count`는 인용 판정 검증자 수이며 지도 대조 검증자를 세지 않는다.
  - 순수 함수(스크립트 최상위의 `function` 선언): `checkQueries(queries: string[], forbidden: string[]) -> { query, rule }[]`, `groupByUrl(outputs) -> { url, refs: string[], claims: string[] }[]`, `classify(outputs, verdicts, failedUrls) -> { passed, rejected, unverifiable, verify_failed }`, `mergeStatus(subquestions, outputs, verifyFailed) -> { subquestion_status, overall_status }`.

- [ ] **Step 1: 작업 브랜치를 만들고 설계 문서를 커밋한다**

```bash
git switch -c feat/prior-art-agent
git add docs/superpowers/specs/2026-10-18-prior-art-agent-design.md docs/superpowers/plans/2026-10-18-prior-art-agent.md docs/superpowers/reviews/2026-10-18-prior-art-agent-*
git commit -m "선행연구 에이전트 spec·plan 과 리뷰 기록을 남긴다"
```

Expected: `git branch --show-current`가 `feat/prior-art-agent`를 출력한다.

- [ ] **Step 2: 시험 도구 `scripts/workflow_harness.mjs` 작성**

시험 도구는 워크플로 스크립트 원문의 첫 문장 `export const meta`에서만 `export `를 떼고, 원문에 `export`가 둘 이상이면 오류로 끝난다. 본문은 `AsyncFunction('agent','parallel','pipeline','phase','log','args','__fn','__fnArgs', prefix + body)`로 감싸 실행한다. `prefix`는 `if (__fn) return ({checkQueries, groupByUrl, classify, mergeStatus})[__fn](...__fnArgs);` 한 줄이다. 순수 함수가 `function` 선언이라 끌어올려지므로 본문 앞에서 부를 수 있다. `agent()`는 픽스처 JSON 에서 `label`로 응답을 찾아 돌려주고, 응답이 `null`이면 `null`을 돌려준다. `parallel`과 `pipeline`은 런타임과 같은 의미(결과 배열, 실패는 `null`)로 흉내 낸다. 사용법은 `node scripts/workflow_harness.mjs <script> <fixture.json>`과 `node scripts/workflow_harness.mjs <script> --fn <이름> <json 인자 배열>`이다. 결과는 `JSON.stringify(x)` 한 줄로 stdout 에 쓰고, 예외가 나면 0 이 아닌 코드로 끝난다.

- [ ] **Step 3: 실패하는 계약 테스트 `scripts/test_workflow.sh` 작성**

`scripts/_test_check.sh`의 `check`를 쓴다. 픽스처는 테스트 안에서 `mktemp`로 만든다. 테스트 머리에 아래 두 함수를 둔다. `run`은 실행 오류나 JSON 이 아닌 출력에서 실패하므로, 부정 단언도 실행이 성공한 뒤에만 PASS 한다.

```bash
fn()  { node "$H" "$WF" --fn "$1" "$2"; }
run() { local o; o="$(node "$H" "$WF" "$1")" || return 1
        printf '%s' "$o" | node -e 'JSON.parse(require("fs").readFileSync(0))' || return 1
        printf '%s\n' "$o"; }
```

단언은 아래와 같다.

```bash
check "export 가 meta 하나뿐이다"                "[ \"\$(grep -c '^export ' \"\$WF\")\" = 1 ] && head -1 \"\$WF\" | grep -q '^export const meta'"
check "checkQueries: 금지어를 잡는다"           "fn checkQueries '[[\"disciplined-coder agent\"],[\"disciplined-coder\"]]' | grep -q '\"rule\":\"forbidden\"'"
check "checkQueries: 윈도우 경로를 잡는다"       "fn checkQueries '[[\"C:\\\\Users\\\\x\\\\a.md\"],[]]' | grep -q '\"rule\":\"path\"'"
check "checkQueries: 일반 구는 통과한다"         "[ \"\$(fn checkQueries '[[\"prior art search agent\"],[]]')\" = '[]' ]"
check "groupByUrl: 같은 URL 을 하나로 묶는다"    "fn groupByUrl \"\$TWO_SQ_SAME_URL\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0));process.exit(r.length===1&&r[0].refs.length===2?0:1)'"
check "null 검증자: 그 URL 항목은 verify_failed 에만 든다" "run \"\$FX_NULL_VERIFIER\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0));process.exit(r.verify_failed.length===1&&r.passed.length+r.rejected.length+r.unverifiable.length===0?0:1)'"
check "null 검증자: verification_status 가 partial" "run \"\$FX_NULL_VERIFIER\" | grep -q '\"verification_status\":\"partial\"'"
check "null 검증자: overall 은 ok 가 아니다"     "o=\$(run \"\$FX_NULL_VERIFIER\") && ! printf '%s' \"\$o\" | grep -q '\"overall_status\":\"ok\"'"
check "null 연구자: search_status 가 failed"     "run \"\$FX_NULL_RESEARCHER\" | grep -q '\"search_status\":\"failed\"'"
check "supported 만 통과 목록에 든다"             "run \"\$FX_MIXED\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0));process.exit(r.passed.length===1&&r.rejected.length===1?0:1)'"
check "unverifiable 은 탈락이 아니다"             "run \"\$FX_UNVERIFIABLE\" | node -e 'const r=JSON.parse(require(\"fs\").readFileSync(0));process.exit(r.unverifiable.length===1&&r.rejected.length===0?0:1)'"
check "contrast 는 종합을 실행하지 않는다"        "o=\$(run \"\$FX_MIXED\") && ! printf '%s' \"\$o\" | grep -q '\"synthesis\"'"
check "survey 는 종합과 지도 대조를 실행한다"     "run \"\$FX_SURVEY\" | grep -q '\"map_check\"'"
check "검증자 수는 URL 수와 같다"                 "run \"\$FX_SURVEY\" | grep -q '\"verifier_count\":2'"
check "search_status 가 failed 면 overall 은 ok 가 아니다" "o=\$(run \"\$FX_SEARCH_FAILED\") && ! printf '%s' \"\$o\" | grep -q '\"overall_status\":\"ok\"'"
```

`FX_SURVEY`는 서로 다른 URL 두 개를 인용하는 `survey` 픽스처다.

- [ ] **Step 4: 계약 테스트가 실패하는지 확인**

Run: `bash scripts/test_workflow.sh`
Expected: 모든 단언이 FAIL 이다(워크플로 파일이 없어 `run`과 `fn`이 실패한다).

- [ ] **Step 5: `workflows/prior-art-search.js` 구현**

첫 문장은 순수 리터럴 `export const meta = { name: 'prior-art-search', description: '선행연구 프로토콜의 하위 질문마다 연구자를 실행하고 인용을 검증한다', phases: [{ title: 'Research' }, { title: 'Verify' }, { title: 'Synthesize' }] }`다. 처리 순서는 spec 「오케스트레이터 절차」 2단계와 같다. 연구자는 `agent(prompt, { agentType: 'disciplined-coder:prior-art-researcher', schema: RESEARCHER_SCHEMA, label: 'research:<id>', phase: 'Research' })`, 검증자는 `agentType: 'disciplined-coder:prior-art-verifier'`, `label: 'verify:<url>'`로 실행한다. `agentType`과 `phase`가 실제 런타임에서 동작하는지는 Task 5 Step 2 가 확인한다. 프롬프트에는 `args.principles_path`와 하위 질문 범위와 질의 금지 목록을 넣는다.

`checkQueries`의 경로 규칙은 `[A-Za-z]:[\\/]`, `(^|\s)[~.]?/[^\s/]+/`, `\.(md|js|sh|json|py|ts|mjs)\b`이고, 금지어는 대소문자를 무시한 부분 문자열로 대조한다. 금지 목록은 `args.forbidden_terms`만 쓴다(워크플로에는 파일 시스템 접근이 없다). `classify`는 항목마다 다음 순서로 판정한다. 판정 하나라도 `supported`이면 통과, 판정이 없고 URL 이 검증 실패 목록에 있으면 검증 실패, 모든 판정이 `unverifiable`이면 판정 불가, 그 밖은 탈락이다. `mergeStatus`는 연구자 출력이 `null`인 하위 질문의 `search_status`를 `failed`로 두고, 검증 실패 URL 을 인용한 하위 질문의 `verification_status`를 `partial`로 둔다.

- [ ] **Step 6: 계약 테스트 통과 확인**

Run: `bash scripts/test_workflow.sh`
Expected: 모든 줄이 PASS 이고 `FAIL`이 없다.

- [ ] **Step 7: 커밋**

```bash
git add workflows/prior-art-search.js scripts/workflow_harness.mjs scripts/test_workflow.sh
git commit -m "선행연구 탐색 워크플로와 그 시험 도구를 만든다"
```

### Task 2: 에이전트 정의와 `agent-prior-art` 스킬

**Files:**
- Create: `agents/prior-art-researcher.md`, `agents/prior-art-verifier.md`
- Create: `skills/agent-prior-art/SKILL.md`
- Modify: `scripts/test_docs_drift.sh`(새 검사 묶음 `[agent-prior-art]` 추가)

**Interfaces:**
- Consumes: Task 1 의 출력 스키마 이름과 칸, `ref` 형식.
- Produces: 스킬 절 이름 「오케스트레이터 절차」「발동과 기록」「상황별 전략」「실행할 때 지킬 상한」「판정 규약」「출력 스키마」「인용 확인」「레퍼런스 프롬프트」. Task 4 의 포인터가 이 이름을 가리킨다.

- [ ] **Step 1: 실패하는 drift 검사 추가**

```bash
echo "[agent-prior-art]"
APA="$HERE/skills/agent-prior-art/SKILL.md"; RES="$HERE/agents/prior-art-researcher.md"; VER="$HERE/agents/prior-art-verifier.md"
for s in '오케스트레이터 절차' '발동과 기록' '상황별 전략' '실행할 때 지킬 상한' '판정 규약' '출력 스키마' '인용 확인' '레퍼런스 프롬프트'; do
  check "agent-prior-art 에 「$s」 절이 있다" "has_sec \"\$APA\" '$s'"
done
check "description 에 옛 이름이 있다"           "sed -n '1,5p' \"\$APA\" | grep -qF 'lens-prior-art'"
check "description 에 선행연구렌즈가 있다"       "sed -n '1,5p' \"\$APA\" | grep -qF '선행연구렌즈'"
check "본문에 옛 이름이 없다"                   "! sed '1,5d' \"\$APA\" | grep -qF 'lens-prior-art'"
check "lens-derived 가 남지 않는다"             "! grep -qF 'lens-derived' \"\$APA\" \"\$RES\" \"\$VER\""
for f in "$RES" "$VER"; do
  check "$(basename "$f"): maxTurns 20"          "grep -qx 'maxTurns: 20' '$f'"
  check "$(basename "$f"): Agent 도구 없음"      "! sed -n '/^---$/,/^---$/p' '$f' | grep -E '^tools:' | grep -qw Agent"
done
SYS="$(awk '/^## 레퍼런스 프롬프트/{f=1;next} f&&/^## /{exit} f' "$APA" | grep -m1 '^- system:' | sed 's/^- system: "//; s/"$//')"
check "연구자 정의가 레퍼런스 프롬프트 본문을 그대로 옮긴다" "[ -n \"\$SYS\" ] && grep -qF -- \"\$SYS\" \"\$RES\""
check "판정 기준 문장이 스킬에 그대로 있다"     "grep -qF '옮긴 구절이 주장의 주어와 수치와 조건을 모두 포함하면 supported' \"\$APA\""
```

- [ ] **Step 2: 검사가 실패하는지 확인**

Run: `bash scripts/test_docs_drift.sh 2>&1 | awk -v h='[agent-prior-art]' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c FAIL`
Expected: 0 보다 큰 값이 나온다.

- [ ] **Step 3: `skills/agent-prior-art/SKILL.md` 작성**

frontmatter 의 `name`은 `agent-prior-art`이고, `description`은 발동 문구를 한 문단으로 포함한다. 발동 문구는 주제어와 "선행연구렌즈"와 `lens-prior-art`와 spec 「상황별 전략」의 상황 이름(spec 대조, 제안서 검진, 기존 도구 탐색, 결정 근거 탐색, 사실 확인)이다. YAML 평문 스칼라라서 `: `와 ` #`을 넣지 않는다(`domain-plugin` 「플러그인을 만들 때 지킬 것」의 frontmatter 불릿). 본문 절은 Interfaces 의 이름과 차례를 따르고, 내용은 spec 의 같은 이름 절을 지시문(명령형)으로 옮긴다. 본문에는 옛 이름 `lens-prior-art`를 쓰지 않는다.

「판정 규약」에는 커밋 `7a2d26d`의 `skills/lens-prior-art/SKILL.md` 「체크리스트」, 네 축 대조 문단, 「가드」를 옮기되, `lens-derived`만 `derived`로 바꾸고 나머지 글자는 그대로 둔다. 「레퍼런스 프롬프트」의 `- system: "…"` 줄은 같은 파일의 문장을 모드 처리 문장 없이 옮기며, 줄 머리를 `- system: "`로 둔다. 「출력 스키마」의 JSON 블록은 Task 1 의 스키마와 칸 이름이 같아야 한다.

- [ ] **Step 4: 두 에이전트 정의 작성**

frontmatter 는 `name`, `description`, `tools`(Global Constraints 값), `maxTurns: 20`이다. `model`은 지금 두지 않으며, Task 5 Step 7 의 판정에 따라 메인 세션이 추가 여부를 정한다. 연구자 본문의 첫 단락은 「레퍼런스 프롬프트」의 `- system:` 문장을 그대로 옮긴다. 다음 단락에는 모드 처리와 상한 지시를 적는다. 탐색 모드는 `survey`에서만 `evidence_map` 행을 채우고, 종합 모드는 웹 도구를 쓰지 않고 통과 목록의 행만으로 `evidence_map`과 `conclusions`를 만든다. 상한은 도구 호출 20회와 출처 약 100개다. 검증자 본문에는 인용 판정 모드와 지도 대조 모드의 지시, 판정 기준 문장, `unverifiable`의 뜻을 적는다.

- [ ] **Step 5: 검사 통과 확인**

Run: `bash scripts/test_docs_drift.sh 2>&1 | awk -v h='[agent-prior-art]' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c FAIL`
Expected: `0`

- [ ] **Step 6: 전체 계약 테스트의 남은 실패 확인**

Run: CLAUDE.md 「변경 뒤 실행」의 명령
Expected: 실패는 `scripts/test_docs_drift.sh`의 "agent-prior-art 을 에이전트원칙이나 다른 스킬이 부른다" 한 줄뿐이다. 다른 스킬의 포인터는 Task 4 가 만들므로 이 실패는 Task 4 Step 5 에서 사라진다. 이 상태로는 push 하지 않는다.

- [ ] **Step 7: 커밋**

```bash
git add agents skills/agent-prior-art scripts/test_docs_drift.sh
git commit -m "agent-prior-art 스킬과 연구자·검증자 에이전트 정의를 만든다"
```

### Task 3: 발동 넛지

**Files:**
- Create: `hooks/prior_art_nudge_userpromptsubmit.sh`
- Modify: `hooks/hooks.json`(`UserPromptSubmit` 이벤트 추가)
- Modify: `scripts/test_hooks.sh`(`[prior-art-nudge]` 묶음 추가)
- Modify: `README.md`(「하드 게이트와 넛지와 전역 설정 수정」 표와 「끄는 법」)

**Interfaces:**
- Consumes: Task 2 의 스킬 이름 `agent-prior-art`.
- Produces: 출력 `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"…agent-prior-art…"}}`. 조건이 맞지 않으면 아무것도 출력하지 않는다.

- [ ] **Step 1: 실패하는 계약 테스트 추가**

```bash
echo "[prior-art-nudge]"
NUD="$HERE/hooks/prior_art_nudge_userpromptsubmit.sh"
nud() { printf '{"session_id":"s","prompt":"%s"}' "$1" | bash "$NUD"; }
for p in '선행연구렌즈로 뒤져봐줘' '이걸 누가 해봤나 찾아 줘' 'prior art 조사해 줘' '\"agent loop\" 의 선행연구를 찾아 줘'; do
  check "요청 → 알림: $p"                 "nud '$p' | grep -qF 'agent-prior-art'"
done
for p in 'lens-prior-art 문구를 고쳐 줘' '선행연구 렌즈 절 이름을 바꾸자' '어제 선행연구 결과를 정리했다'; do
  check "언급만 → 무출력: $p"             "[ -z \"\$(nud '$p')\" ]"
done
check "같은 세션 두 번째 요청에도 알린다" "nud '선행연구 찾아 줘' >/dev/null; nud '선행연구 다시 찾아 줘' | grep -qF 'agent-prior-art'"
check "OFF → 무출력"                     "[ -z \"\$(printf '{\"prompt\":\"선행연구 찾아\"}' | DISCIPLINED_CODER_PRIOR_ART_NUDGE=off bash \"\$NUD\")\" ]"
check "출력이 JSON 이다"                  "nud '선행연구 찾아' | json_valid_stdin"
```

`json_valid_stdin`은 `scripts/_json_valid.sh`의 함수다. 음성 예시 "어제 선행연구 결과를 정리했다"는 요청형 표현이 없어 무출력이어야 한다.

- [ ] **Step 2: 계약 테스트가 실패하는지 확인**

Run: `bash scripts/test_hooks.sh 2>&1 | awk -v h='[prior-art-nudge]' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c FAIL`
Expected: 0 보다 큰 값이 나온다.

- [ ] **Step 3: 훅 구현**

`set -euo pipefail`과 OFF 변수 확인을 맨 앞에 둔다. stdin 은 `IFS= read -r -d '' INPUT || true`로 읽는다(`hooks/_hook_input.sh` 머리 주석의 작은 입력 훅 방식). `json_str`은 첫 따옴표에서 끊겨 따옴표가 든 메시지를 놓치므로 쓰지 않는다. 대신 `MSG="${INPUT#*\"prompt\"}"`로 `prompt` 칸부터 끝까지를 잘라 대조한다. `prompt` 칸이 없으면(`MSG`가 `INPUT`과 같으면) 아무것도 출력하지 않는다. 주제어와 요청형 표현은 셸의 `case` 패턴으로 대조해 외부 프로세스를 실행하지 않는다(`domain-plugin` 「훅을 만들 때의 값」). 알림 문장은 "선행연구 요청으로 보인다 — `agent-prior-art` 스킬을 열어 그 「오케스트레이터 절차」를 따르라. 넛지일 뿐 차단은 아니다."이며 `_json_escape.sh`로 이스케이프한다. `hooks.json`에 `"UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/prior_art_nudge_userpromptsubmit.sh\"" }] }]`를 추가한다.

- [ ] **Step 4: README 갱신**

훅 표에 `| UserPromptSubmit | \`hooks/prior_art_nudge_userpromptsubmit.sh\` | 사용자 메시지가 선행연구를 요청하면 \`agent-prior-art\`를 열라고 알린다 | 알림 |` 행을 추가한다. 「끄는 법」에 `DISCIPLINED_CODER_PRIOR_ART_NUDGE=off` 불릿을 추가하고, "두 변수는" 문장을 변수 수를 적지 않는 문장("이 변수들은")으로 고친다.

- [ ] **Step 5: 계약 테스트 통과 확인**

Run: `bash scripts/test_hooks.sh 2>&1 | awk -v h='[prior-art-nudge]' '$0==h{f=1;next} /^\[/{f=0} f' | grep -c FAIL`
Expected: `0`

- [ ] **Step 6: 넛지 실행 시간 측정**

Run: `time (for i in 1 2 3 4 5 6 7 8 9 10; do printf '{"prompt":"선행연구 찾아"}' | bash hooks/prior_art_nudge_userpromptsubmit.sh >/dev/null; done)`
Expected: 측정값이 출력되고, 메인 세션이 그 값을 Task 5 기록에 옮긴다.

- [ ] **Step 7: 커밋**

```bash
git add hooks/prior_art_nudge_userpromptsubmit.sh hooks/hooks.json scripts/test_hooks.sh README.md
git commit -m "선행연구 요청을 알리는 UserPromptSubmit 넛지를 단다"
```

### Task 4: 참조 처리와 `lens-prior-art` 삭제

**Files:**
- Modify: `skills/review-specs/SKILL.md`, `skills/review-docs/SKILL.md`, `skills/dispatching-lenses/SKILL.md`, `skills/aggregating-lenses/SKILL.md`, `skills/audit-repo-docs/SKILL.md`, `skills/lens-fit/SKILL.md`, `skills/domain-plugin/SKILL.md`, `skills/nested-orchestration/references/sub-session-protocol.md`, `agent-principles.md`, `docs/domain-discipline.md`, `scripts/test_audit.sh`, `scripts/test_docs_drift.sh`
- Delete: `skills/lens-prior-art/`

**Interfaces:**
- Consumes: Task 2 의 절 이름.
- Produces: 없음.

처리할 문장은 2026-10-18 기준 아래와 같다. 이 표는 `git ls-files`에서 리뷰 기록·spec·plan 을 뺀 `lens-prior-art` grep 결과와, 그 글자 없이 선행연구 렌즈를 전제로 한 문장을 합친 것이다. 줄 번호는 그 시점의 값이다.

| 파일:줄 | 처리 |
|---|---|
| `agent-principles.md:132` | "(웹에 나가는 `lens-prior-art` 등)" 괄호를 지운다 |
| `docs/domain-discipline.md:315·329·332·341` | 과거 측정 서술로 남기고, 그 절 끝에 "2026-10-18 삭제, `agent-prior-art`로 대체" 한 문장을 적는다. `LENS-ALLOWED` 절 끝에 예시 삭제와 클린룸 시험 생략(사용자 결정, 지시 내용 불변)을 적는다 |
| `scripts/test_audit.sh:211` | 주석을 지금 검사하는 내용에 맞게 고친다 |
| `scripts/test_docs_drift.sh:225` | review-docs 34행을 다시 쓴 뒤에도 "공통 규칙을 렌즈 그룹으로 넘긴다" 검사가 `lens-readability`의 위임으로 성립하는지 확인하고, 성립하지 않으면 새 문장에 맞게 고친다 |
| `scripts/test_docs_drift.sh:226` | 검사 대상을 `「인용 확인」`과 `agent-prior-art`로 바꾼다 |
| `scripts/test_docs_drift.sh:846-849` | 주석과 `canon: 선행연구 렌즈를 이름으로 예외` 검사를 지운다 |
| `skills/aggregating-lenses/SKILL.md:22` | `lens` 열거에서 `lens-prior-art`를 지운다 |
| `skills/aggregating-lenses/SKILL.md:53·56` | 예외 문단과 `lens-prior-art` 항목을 지우고 `lens-readability`만 남긴다 |
| `skills/aggregating-lenses/SKILL.md:84-87`과 그 아래 문장 | `search_status`·`citations`·`not_found`·`disclosures` 행을 지우고, 조용한 통과 문장을 `purpose`만 남게 고친다 |
| `skills/audit-repo-docs/SKILL.md:49` | "`lens-prior-art`는 제안하지 않는다"를 "`agent-prior-art`는 제안하지 않는다"로 바꾼다 |
| `skills/dispatching-lenses/SKILL.md:73·75·88·100` | 표 행, 자세 '외부 탐색' 정의, 웹 렌즈 수 세기 문장, 발동 기준 문장을 지운다 |
| `skills/lens-fit/SKILL.md:38` | `lens-prior-art`의 `search_status` 비유를 지운다 |
| `skills/nested-orchestration/references/sub-session-protocol.md:56` | '사용자 승인이 필요한 렌즈'를 '사용자 승인이 필요한 렌즈나 선행연구 에이전트'로 바꾸고 `agent-prior-art` 「발동과 기록」을 가리킨다 |
| `skills/nested-orchestration/references/sub-session-protocol.md:114` | `렌즈 그룹 판정` 행의 형식을 '렌즈나 선행연구 에이전트 — 대상 문서 — 발동 기준에 해당한 이유'로 바꾼다 |
| `skills/review-docs/SKILL.md:34·38·40` | 공통 규칙 위임을 `agent-prior-art` 「발동과 기록」으로, 질의 경계 포인터를 「판정 규약」으로, 인용 검증 포인터를 「인용 확인」으로 바꾼다 |
| `skills/review-docs/SKILL.md` 「기록 파일 이름 규칙」 | `prior-art` 종류의 원본 파일 이름 표를 추가한다 |
| `skills/review-specs/SKILL.md:23·27·32·34·41·52·59·61·63·64·76·101·118` | 선행연구 렌즈를 `agent-prior-art` 실행으로 바꾼다. 「선행연구 렌즈의 제안과 승인」 절 이름을 「선행연구 에이전트의 제안과 승인」으로 바꾸고, 단계 상한 미루기 문장을 지우며, `🔴` 조건을 `overall_status`로 바꾼다 |
| `skills/review-specs/SKILL.md:70` | '통상과 최대한 중 고르기' 문장을 `agent-prior-art` 「오케스트레이터 절차」 1단계의 프로토콜 승인으로 바꾼다. 연구자 수는 프로토콜이 정한다 |
| `skills/review-specs/SKILL.md:137-145` | 절 제목의 '(`lens-prior-art` 전용)'을 지우고, 범위 문장을 `agent-prior-art` 「인용 확인」으로 옮긴 뒤 그 절을 가리키는 한 문장으로 줄인다. 「`prior-art` 기록에 적을 것」에 프로토콜 전문과 탈락·판정 불가·검증 실패 목록과 질의 경계 위반을 추가한다 |
| `skills/domain-plugin/SKILL.md` | 컴포넌트 위치에 `workflows/`를, 이름 규칙에 `agent-` 부류를 추가한다 |

- [ ] **Step 1: 실패하는 완료 검사 추가**

`scripts/test_docs_drift.sh`에 추가한다. 예외 파일은 옛 이름을 일부러 포함한다. 넛지 훅은 옛 이름을 주제어로, 두 계약 테스트는 옛 이름을 단언 문자열로, `docs/domain-discipline.md`는 과거 측정 서술로 포함하고, `agent-prior-art`는 description 에만 포함한다.

```bash
echo "[lens-prior-art 제거]"
LEFT="$(cd "$HERE" && git ls-files | grep -v '^docs/superpowers/\(reviews\|specs\|plans\)/' \
  | grep -vxF -e hooks/prior_art_nudge_userpromptsubmit.sh -e scripts/test_hooks.sh -e scripts/test_docs_drift.sh -e docs/domain-discipline.md \
  | xargs grep -n 'lens-prior-art' 2>/dev/null | grep -v '^skills/agent-prior-art/SKILL.md:[1-5]:' || true)"
check "예외 밖에 lens-prior-art 가 남지 않는다"   "[ -z \"\$LEFT\" ]"
check "lens-prior-art 디렉터리가 없다"           "[ ! -d \"\$HERE/skills/lens-prior-art\" ]"
check "domain-discipline 에 삭제 표시가 있다"     "grep -qF '2026-10-18 삭제, \`agent-prior-art\`로 대체' \"\$HERE/docs/domain-discipline.md\""
check "LENS-ALLOWED 규칙 문장은 남아 있다"        "grep -qF '호출 절차가 사용자 승인을 요구하는 렌즈' \"\$HERE/agent-principles.md\""
```

- [ ] **Step 2: 검사가 실패하는지 확인**

Run: `bash scripts/test_docs_drift.sh 2>&1 | awk -v h='[lens-prior-art 제거]' '$0==h{f=1;next} /^\[/{f=0} f'`
Expected: 앞의 세 줄이 FAIL 이다.

- [ ] **Step 3: 위 표대로 문장을 처리한다**

표에 없는 문장이 grep 에 남으면 같은 원칙(가리키게 바꾸거나 지운다)으로 처리하고 커밋 메시지에 적는다.

- [ ] **Step 4: `skills/lens-prior-art/`를 지운다**

Run: `git rm -r skills/lens-prior-art`
Expected: `rm 'skills/lens-prior-art/SKILL.md'`가 출력된다.

- [ ] **Step 5: 전체 계약 테스트 통과 확인**

Run: CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

- [ ] **Step 6: 커밋**

```bash
git add -A skills agent-principles.md docs/domain-discipline.md scripts
git commit -m "lens-prior-art 를 지우고 참조를 agent-prior-art 로 옮긴다"
```

### Task 5: 병합 전 시험

이 Task 는 메인 세션이 직접 실행한다. `--plugin-dir` 세션에 메시지를 입력하는 일은 사람만 할 수 있으므로, 메인 세션은 보낼 메시지를 준비해 사용자에게 입력을 요청하고 결과를 받아 기록한다.

**Files:**
- Create: `docs/superpowers/reviews/<Task 5 Step 1 실행일>-prior-art-agent-check.md`와 같은 이름 폴더(원본 JSON). 날짜는 Step 1 을 실행한 날의 `YYYY-MM-DD`다.
- Modify(조건부): `agents/prior-art-verifier.md`(`model: haiku`)

**Interfaces:**
- Consumes: Task 1~4 의 전체 구성.
- Produces: 채택 판정. 사용자가 이 판정을 보고 병합 여부를 정한다.

- [ ] **Step 1: 플러그인 검증**

Run: `claude plugin validate ./`
Expected: `Validation passed`가 나오고, 기존 경고 "CLAUDE.md at the plugin root is not loaded" 외에 새 경고가 없다.

- [ ] **Step 2: 런타임 실측**

메인 세션이 사용자에게 `claude --plugin-dir "$(git rev-parse --show-toplevel)"`로 새 세션을 열어 달라고 요청한다. 그 세션에서 하위 질문 하나짜리 프로토콜로 `prior-art-search`를 한 번 실행한다. 메인 세션은 그 실행의 `journal.jsonl`에서 아래를 확인해 기록한다.
- 연구자와 검증자가 `disciplined-coder:prior-art-researcher`와 `disciplined-coder:prior-art-verifier`로 실행되었고, 검증자가 `WebSearch`를 쓰지 못했다.
- `phase` 옵션이 진행 표시의 묶음에 반영되었다.
- 훅 입력의 `prompt` 칸에 한글이 원문으로 왔는지 `\uXXXX`로 왔는지. `\uXXXX`로 왔으면 넛지의 한글 주제어 대조를 고치고 Task 3 의 계약 테스트를 다시 실행한다.

어느 하나라도 기대와 다르면 원인과 고칠 방법을 사용자에게 보고하고 진행을 멈춘다.

- [ ] **Step 3: 과제 프로토콜을 쓰고 사용자 승인을 받는다**

과제는 spec 「시험 계획」의 기존 도구 탐색, 결정 근거 탐색, spec 대조다. 프로토콜은 `round: 1`이고 공백 라운드를 두지 않으며, 같은 하위 질문과 연구자 수를 기준선과 공유한다. 메인 세션은 프로토콜 전문을 기록 파일에 먼저 적고, 과제마다 예상 연구자 수와 검증자 수를 함께 보여 사용자 승인을 받는다.

- [ ] **Step 4: 첫 짝 실행과 비용 확인**

첫 과제에서 기준선과 새 에이전트를 1회씩 실행한다. 기준선은 `git show 7a2d26d:skills/lens-prior-art/SKILL.md`의 「레퍼런스 프롬프트」에 `queries` 칸만 추가해 general-purpose 서브에이전트로 실행한다. 새 에이전트는 `prior-art-search` 워크플로로 실행한다. 기준선 출력의 인용은 Agent 도구로 `disciplined-coder:prior-art-verifier`를 URL 마다 실행해 판정한다. 메인 세션은 두 실행의 토큰 사용량과 검증자 수를 사용자에게 보이고 나머지 실행의 승인을 받는다. 실행마다 원본을 기록 폴더에 원본 파일 규칙 이름으로 저장한다.

- [ ] **Step 5: 나머지 실행**

과제마다 기준선과 새 에이전트를 2회차까지 채운다. Haiku 검증자 조건은 새 에이전트 조건의 연구자 출력을 그대로 두고, 같은 URL 들을 Agent 도구의 `model: "haiku"` 인자로 실행한 `disciplined-coder:prior-art-verifier`에게 다시 판정시킨다. 실행마다 원본을 기록 폴더에 저장한다.

- [ ] **Step 6: 발동 시험**

메인 세션은 spec 「시험 계획」 측정값의 발동 시험 메시지를 사용자에게 건네고, 사용자가 `--plugin-dir` 세션에 차례로 입력한다. 메인 세션은 넛지 알림 여부와 그 세션이 `agent-prior-art`를 열었는지를 기록한다. 넛지가 뜨지 않은 메시지가 있으면 주제어나 요청형 표현 목록을 고치고, Task 3 의 계약 테스트에 그 메시지를 양성 예시로 추가해 통과시킨 뒤 발동 시험을 한 번 다시 실행한다. Task 3 Step 6 의 넛지 실행 시간과, `maxTurns` 20 에 이른 연구자의 도구 호출 수도 기록한다.

- [ ] **Step 7: 채택 판정**

메인 세션은 짝지은 두 비교 각각에서 아래 조건이 성립하는지 기록에 적는다.
- 새 에이전트의 통과 사례 수가 기준선의 90% 이상이다.
- 새 에이전트의 오인 수와 질의 경계 위반 수가 기준선보다 많지 않다.
- 발동 시험의 모든 메시지에서 넛지가 뜨고 `agent-prior-art`가 열린다.

토큰 사용량이 기준선의 3배를 넘으면 사용자에게 채택 여부를 묻는다. Haiku 검증자의 오판 수가 세션 모델 검증자의 오판 수 이하이면 메인 세션이 `agents/prior-art-verifier.md`에 `model: haiku`를 추가한다. 오인 수와 Haiku 오판 수에서 표본 세 건씩을 골라 사용자에게 확인받는다.

- [ ] **Step 8: 시험 기록 커밋**

통과 여부와 무관하게 기록을 커밋한다.

```bash
git add docs/superpowers/reviews agents/prior-art-verifier.md
git commit -m "선행연구 에이전트 병합 전 시험 기록을 남긴다"
```

- [ ] **Step 9: 결과 보고와 병합 결정**

메인 세션은 채택 판정과 그 근거를 사용자에게 보고한다. 채택 기준을 통과하면 사용자에게 main 병합 승인을 요청하고, 통과하지 못하면 병합하지 않고 원인과 사용자가 정할 일을 보고한다.

<!-- spec-review: passed -->
