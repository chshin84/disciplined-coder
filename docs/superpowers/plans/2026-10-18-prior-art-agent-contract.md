# 선행연구 에이전트 계약 코드 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 워크스트림 `workflow`와 `agents`가 주고받는 JSON 의 키를 계약 코드 `scripts/prior_art_contract.json`에 고정하고, 계약 테스트 `scripts/test_prior_art_contract.sh`가 워크플로 스키마와 에이전트 정의의 출력 형식 블록을 그 키와 대조하게 한다.

**Architecture:** 계약 코드는 자료 이름마다 반드시 있어야 하는 키를 중첩 객체로 적은 JSON 이다. 계약 테스트는 bash 로 `scripts/_test_check.sh`의 `check`를 쓰고, JSON 대조는 저장소의 처리기 하나인 `scripts/_json_valid.sh`의 `json_run`(파이썬)으로 한다. node 는 시험 도구 `scripts/workflow_harness.mjs`를 실행할 때만 쓴다. 워크플로 스크립트나 에이전트 정의가 아직 없으면 그 워크스트림 id 를 생략 줄로 출력하고 그 대조를 생략한다.

**Tech Stack:** bash, 파이썬(`json_run`), node(시험 도구 실행에만), JSON.

**Spec:** `docs/superpowers/specs/2026-10-18-prior-art-agent-design.md`. 이 plan 에서 '큰 명세'는 이 파일을 가리킨다. 따를 절은 「다시 나눈 분할」의 「계약 코드와 계약 테스트」와 계약 표다.

## Global Constraints

- 계약 코드와 계약 테스트는 현재 세션이 소유하며 통합 브랜치 `dev/prior-art-agent`에 커밋한다.
- 계약 테스트는 저장소 관례대로 FAIL=0 이 계약이고 기대 개수를 숫자로 박지 않는다. 끝에 `echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]`를 둔다.
- 생략은 `  SKIP: <워크스트림 id> — <사유>` 한 줄로 출력하고 실패로 세지 않는다. 현재 세션은 시험 병합에서 이 줄의 id 를 읽어, 병합 대상의 id 가 있으면 실패로 본다.
- 마지막 시험 병합 뒤 현재 세션이 생략 분기를 지운다(큰 명세 「다시 나눈 분할」의 소유 표 아래 문단). 이 plan 은 생략 분기를 만드는 데까지만 다룬다.
- 단언은 종료 코드만 보지 않고, 기대한 출력 줄이 나왔는지로 판정한다. `!`로 뒤집는 단언을 쓰지 않는다. 함수가 없거나 처리기가 없어 실패한 경우를 '키가 빠짐'으로 세지 않기 위해서다.
- 계약 테스트는 옛 이름 `lens-prior-art`를 쓰지 않는다.
- 변경 뒤 CLAUDE.md 「변경 뒤 실행」의 명령과 `claude plugin validate ./`를 실행한다.

## Review Focus

- **예시 JSON 이 파싱되지 않는 정의** — 표지 뒤 블록이 `JSON.parse`로 읽히지 않으면 `[계약 대조]`가 FAIL 을 낸다(단언 '깨진 블록을 알린다').
- **표지는 있는데 블록이 없는 정의** — 표지 다음 줄이 json 코드 울타리가 아니면 FAIL 이다(단언 '표지 뒤 블록 없음을 알린다').
- **배열 원소의 키** — 스키마는 `items.properties`와 `items.required`에서, 예시는 첫 원소에서 찾는다. 빈 배열 예시와 `items` 없는 스키마는 그 아래 키를 모두 없는 키로 본다(단언 '배열 원소의 빠진 키를 알린다', '빈 배열 예시를 알린다').
- **시험 도구 실패** — 워크플로 스크립트가 있는데 `fn schemas`가 실패하거나 상수가 빠지면 생략이 아니라 FAIL 이다.
- **한쪽 정의만 있는 상태** — 연구자·검증자 정의 중 하나만 있으면 생략이 아니라 없는 쪽이 FAIL 이다.

---

## File Structure

| 파일 | 할 일 |
|---|---|
| `scripts/prior_art_contract.json` | 자료별 필수 키 |
| `scripts/test_prior_art_contract.sh` | 계약 테스트 |

### Task 1: 계약 코드와 계약 테스트

**Files:**
- Create: `scripts/prior_art_contract.json`
- Create: `scripts/test_prior_art_contract.sh`

**Interfaces:**
- Consumes: `scripts/_test_check.sh`의 `check`와 `pass`·`fail` 변수, `scripts/_json_valid.sh`의 `json_run`. 워크스트림 `workflow`의 시험 도구 명령 `printf '[]' | node scripts/workflow_harness.mjs fn schemas`가 종료 코드 0 과 함께 `{ RESEARCHER_SCHEMA, VERIFIER_SCHEMA, SYNTHESIS_SCHEMA, MAP_SCHEMA }` JSON 한 줄을 표준 출력에 내는 것.
- Produces: 계약 코드의 최상위 키 `args`·`researcher`·`verifier`·`synthesis`·`map`·`result`. 생략 줄 `  SKIP: workflow — ...`와 `  SKIP: agents — ...`.

**계약 코드의 표기.** 값이 `true`이면 하위 요구가 없는 키다. 값이 객체이면 그 객체의 키가 하위 요구다. 값이 객체 하나를 담은 배열이면 배열 원소가 그 객체의 키를 가져야 한다. 키 이름이 `?`로 시작하면 선택 키다. 선택 키는 스키마의 `properties`에는 있어야 하지만 `required`에는 없어도 되고, 예시에 없어도 된다.

- [ ] **Step 1: 계약 코드 작성**

`scripts/prior_art_contract.json`을 아래 내용으로 쓴다. 키는 큰 명세 「키 이름과 바깥 형식」과 계약 표에서 옮겼다.

```json
{
  "args": { "question": true, "situation": true, "target": true, "mode": true, "round": true,
            "subquestions": [{ "id": true, "scope": true, "include": true, "exclude": true }],
            "forbidden_terms": true, "researcher_count": true, "researcher_count_basis": true, "principles_path": true },
  "researcher": { "search_status": true, "queries": true,
                  "issues": [{ "prior_claim": true, "citations": true }],
                  "?evidence_map": [{ "case": true, "url": true, "outcome": true,
                                      "axes": { "purpose": { "prior": true, "same": true, "note": true },
                                                "mechanism": { "prior": true, "same": true, "note": true },
                                                "evaluation": { "prior": true, "same": true, "note": true },
                                                "target": { "prior": true, "same": true, "note": true } } }] },
  "verifier": { "url": true, "judgments": [{ "ref": true, "verdict": true, "quote": true, "reason": true }], "principles_applied": true },
  "synthesis": { "evidence_map": [{ "case": true, "url": true, "outcome": true, "axes": true }],
                 "conclusions": [{ "text": true, "refs": true }], "principles_applied": true },
  "map": { "cells": [{ "row": true, "column": true, "grounded": true, "source_ref": true }], "principles_applied": true },
  "result": { "round": true, "passed": [{ "ref": true, "urls": true }], "rejected": [{ "ref": true, "urls": true }],
              "unverifiable": [{ "ref": true, "urls": true }], "verify_failed": [{ "url": true, "refs": true }],
              "coverage": [{ "id": true, "cases_found": true, "passed": true }],
              "subquestion_status": [{ "id": true, "search_status": true, "verification_status": true }],
              "overall_status": true, "query_violations": [{ "id": true, "query": true, "rule": true }],
              "verifier_count": true, "researchers": [{ "id": true, "output": true }],
              "verifiers": [{ "url": true, "subquestions": true, "output": true }], "?synthesis": true, "?map_check": true }
}
```

`args`와 `result`는 이번 계약 테스트의 대조 상대가 없다. 두 자료는 키 이름의 원본으로만 둔다.

- [ ] **Step 2: 실패하는 단언을 픽스처로 작성**

`scripts/test_prior_art_contract.sh` 머리에서 `_test_check.sh`와 `_json_valid.sh`를 source 하고, 두 함수의 이름과 동작만 정한다.

- `contract_check <자료 이름> <스키마 파일 또는 -> <예시 파일 또는 ->` — `json_run`으로 계약 코드의 그 자료를 읽는다. `-`인 쪽은 대조하지 않는다. 빠진 키마다 `schema:<경로>`나 `example:<경로>` 한 줄을 출력한다. 경로는 `judgments[].quote`처럼 점과 `[]`로 잇는다. 스키마 쪽은 필수 키가 `properties`와 `required`에 모두 있어야 하고 선택 키는 `properties`에만 있으면 된다. 빠진 키가 없으면 0, 있으면 1 로 끝난다. 계약 코드에 그 자료가 없거나 요구 키가 0 개이거나 파일을 읽지 못하면 `error:<사유>` 한 줄을 내고 2 로 끝난다.
- `extract_block <자료 이름> <정의 파일>` — `<!-- output: <자료 이름> -->` 바로 다음 줄부터 json 코드 울타리 블록을 꺼낸다. 성공하면 그 JSON 을 출력하고 0 으로 끝난다. 표지가 없으면 `error:no-marker`, 표지 뒤 블록이 없으면 `error:no-block`, 파싱에 실패하면 `error:parse`를 내고 1 로 끝난다.

픽스처는 `mktemp -d`에 만들고, 파일 경로는 `json_run`에 별도 인자로만 넘긴다(프로그램 문자열에 끼워 넣지 않는다). 묶음 `[계약 테스트 자체]`의 단언은 아래와 같다.

```bash
check "맞는 스키마·예시는 통과한다"     "contract_check verifier \"\$FX/ok_schema.json\" \"\$FX/ok_example.json\" >/dev/null"
check "빠진 키를 알린다"                "contract_check verifier - \"\$FX/missing_quote.json\" | grep -qx 'example:judgments\[\]\.quote'"
check "required 누락을 알린다"          "contract_check verifier \"\$FX/no_required_schema.json\" - | grep -qx 'schema:judgments\[\]\.quote'"
check "배열 원소의 빠진 키를 알린다"     "contract_check researcher - \"\$FX/r_no_prior_claim.json\" | grep -qx 'example:issues\[\]\.prior_claim'"
check "빈 배열 예시를 알린다"           "contract_check researcher - \"\$FX/r_empty_issues.json\" | grep -qx 'example:issues\[\]\.prior_claim'"
check "없는 자료 이름은 오류다"          "contract_check nosuch - \"\$FX/ok_example.json\" | grep -q '^error:'"
check "깨진 블록을 알린다"              "extract_block researcher \"\$FX/broken_def.md\" | grep -qx 'error:parse'"
check "표지 뒤 블록 없음을 알린다"       "extract_block researcher \"\$FX/marker_only_def.md\" | grep -qx 'error:no-block'"
check "표지 없음을 알린다"              "extract_block researcher \"\$FX/no_marker_def.md\" | grep -qx 'error:no-marker'"
```

- [ ] **Step 3: 단언이 실패하는지 확인**

두 함수를 `echo stub; return 0`인 자리 표시 본문으로 둔 채 실행한다.

Run: `bash scripts/test_prior_art_contract.sh`
Expected: 첫 단언('맞는 스키마·예시는 통과한다')을 뺀 `[계약 테스트 자체]`의 단언이 모두 FAIL 이다. 자리 표시 본문은 기대한 줄을 출력하지 않기 때문이다. 첫 단언은 종료 코드 0 만 보므로 이 단계에서 PASS 다.

- [ ] **Step 4: 두 함수 구현**

Step 2 에서 정한 동작대로 두 함수의 본문을 `json_run` 프로그램으로 쓴다. 배열 요구에서 스키마의 `items`나 `items.properties`가 없거나 예시 배열이 비었으면, 그 아래 요구 키 경로를 모두 빠진 키로 출력한다.

Run: `bash scripts/test_prior_art_contract.sh`
Expected: `[계약 테스트 자체]`의 단언이 모두 PASS 다.

- [ ] **Step 5: `[계약 대조]` 묶음 구현**

워크플로 쪽은 아래 차례로 판정한다.

- `workflows/prior-art-search.js`가 없으면 `  SKIP: workflow — 워크플로 스크립트가 없다`를 출력하고 스키마 대조를 생략한다.
- 있으면 `command -v node`를 단언하고, 시험 도구 명령의 종료 코드가 0 이며 출력에 네 상수가 모두 있는지를 단언한다. 그다음 네 상수를 각각 `researcher`·`verifier`·`synthesis`·`map`과 `contract_check`로 대조한다.

에이전트 쪽은 아래 차례로 판정한다.

- `agents/prior-art-researcher.md`와 `agents/prior-art-verifier.md`가 둘 다 없으면 `  SKIP: agents — 에이전트 정의가 없다`를 출력하고 예시 대조를 생략한다.
- 하나라도 있으면 두 파일이 모두 있는지를 단언한다. 그다음 연구자 정의의 `researcher`·`synthesis`, 검증자 정의의 `verifier`·`map` 블록을 `extract_block`으로 꺼내 `contract_check`로 대조한다. 블록 추출이 실패하면 그 단언은 FAIL 이다.

대조 단언은 `contract_check`가 0 으로 끝나는지를 본다. 실패하면 출력된 빠진 키 경로가 로그에 남게 한다.

- [ ] **Step 6: 계약 테스트와 생략 확인**

Run: `bash scripts/test_prior_art_contract.sh`
Expected: 마지막 줄이 `PASS=<n> FAIL=0`이고, 통합 브랜치에는 두 워크스트림 파일이 없으므로 `SKIP: workflow`와 `SKIP: agents` 두 줄이 나온다.

- [ ] **Step 7: 저장소 전체 확인**

Run: CLAUDE.md 「변경 뒤 실행」의 명령, 그다음 `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`(기존 루트 CLAUDE.md 경고 외 새 경고 없음).

- [ ] **Step 8: 커밋**

```bash
git add scripts/prior_art_contract.json scripts/test_prior_art_contract.sh
git commit -m "선행연구 에이전트 계약 코드와 계약 테스트를 만든다"
```

<!-- spec-review: passed -->
