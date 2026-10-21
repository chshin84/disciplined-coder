# 조항 측정·문서 정리·병합 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** spec 의 남은 과제(T2·T3·T4·T5·T7·T8·T10)와 사용자가 2026-10-21 에 더한 기존 문서 정리를 실행하고, 브랜치를 main 에 병합한 뒤 push 여부를 사용자에게 묻는다.

**Architecture:** 측정에는 기존 조항별 클린룸 시험 도구(`scripts/eval_clause.sh`·`scripts/eval_clause_report.sh`)와 기존 과제를 쓴다. 이번 차수의 시험 단위는 이름 머리 `c20-` 로 기존 단위와 나누고, 단위마다 기준 커밋을 적는 `base` 파일을 둔다. 채택 후보는 사용자 확인을 받은 뒤에만 `agent-principles.md` 에 옮긴다. 문서 정리는 측정 기록을 다 쓴 뒤에 한다.

**Tech Stack:** bash, Python 3(`json_run`), Claude Code CLI(`claude -p`), Anthropic API 키(`~/.dc-eval.env`).

**Spec:** `docs/superpowers/specs/2026-10-20-clause-decision-point-design.md`. 앞 plan `docs/superpowers/plans/2026-10-20-clause-baseline-and-doc-form-check.md` 의 실행 세션이 T1·T6·T9 를 끝냈다(커밋 a0ab399..6b90dd4).

## spec 과 다르게 정한 점

아래는 이 plan 작성자가 리뷰 지적(`docs/superpowers/reviews/2026-10-21-clause-measurement-and-merge-review.md`)을 받아 정한 판단이다.

| spec 의 내용 | 이 plan 의 처리 | 이유 |
|---|---|---|
| T2: 2026-10-12 과제와 채점 기준을 cases 형식으로 옮긴다 | 추가 질문 짝(`q-<단위>-f1`·`f2`)이 없는 조항에만, 동률이 났을 때 2026-10-12 과제로 짝을 만든다 | 대부분의 조항에 2026-10-18 에 만든 추가 질문 짝이 이미 있고, 시험 도구가 그 짝으로 "과제 3개, 같으면 2개 추가" 규칙을 처리한다(`scripts/_eval_clause.py` 의 `report_unit`) |
| T3: 후보 표의 조항마다 현행 위반 수를 측정한다 | 시험하는 단위의 현행 조건 위반 수로 갈음한다. 시험하지 않기로 한 `BULLET-SCOPE`(8b4a05a)·`SECRETS` 후보는 측정하지 않는다 | 사용자가 2026-10-20 에 두 후보를 시험하지 않기로 정했다 |
| T5: `EDIT-PRIORITY` 시험에 T6 경고 문구를 과제 프롬프트에 넣는다 | 경고를 받은 상황을 담은 새 과제 묶음(`q-edit-hook-*`)을 만들어 그 묶음만 고르는 단위로 시험한다 | 기존 `EDIT-PRIORITY` 과제와 섞이면 기존 단위의 판정이 바뀐다 |

## Global Constraints

이 plan 의 모든 Task 에 아래 제약을 적용하라.

- worktree `D:\projects\dc-clause-candidates` 의 브랜치 `feat/clause-candidates` 에서만 작업하라.
- push 는 Task 7 Step 4 에서 사용자가 승인했을 때만 하라.
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` 를 붙여라.
- API 키는 `scripts/_eval_env.sh` 의 `eval_load_key` 로만 읽고, 키 값을 출력하거나 파일·로그·커밋에 쓰지 마라.
- 같은 질문은 같은 조건으로 한 번만 생성하라.
- 조항 채택 규칙은 저장소 CLAUDE.md 「조항 추가와 문구 변경」을 따르라(2026-10-21 사용자 결정: 현행 규칙).
- 원칙 전체 묶음 비교와 희석 확인은 하지 마라.
- 채택한 문안의 근거 기록에는 "조항별 클린룸 시험에서만 확인했고 원칙 전체 속의 효과는 확인하지 않았다"를 가정으로 적어라.
- 문서 문장은 한국어 문어체로 쓰고, 원칙과 지시문의 할 일은 "~하라"로 써라.
- Task 마다 끝에 저장소 CLAUDE.md 「변경 뒤 실행」의 전체 테스트를 실행해 `ALL PASS` 를 확인하라.

이 plan 에서 "생성 키"는 `scripts/_eval_clause.py` 의 `gen_key` 가 과제 본문과 조건 문안으로 만드는 해시다. 시험 도구는 이 키가 `results/clauses/gen.jsonl` 에 있으면 생성을 다시 하지 않는다.

## Review Focus

| 입력·상황 | 기대 동작 | 고정하는 검사 |
|---|---|---|
| `base` 파일이 있는 단위 | `current.md` 를 그 커밋의 원칙으로 검사한다 | Task 1 `check_units` 시험 |
| `base` 파일이 없는 기존 단위 | 지금처럼 7a2d26d 로 검사한다 | Task 1 `check_units` 시험 |
| `system.md` 가 없는 단위 | 생성 키와 생성 명령이 지금과 같다 | Task 1 `gen_key` 시험 |
| `system.md` 가 있는 단위 | 생성 명령에 `--append-system-prompt` 가 붙고 생성 키가 달라진다 | Task 1 `gen_key` 시험 |
| 같은 조항의 변경안 단위들 | 모두 같은 과제 집합을 고른다 | Task 2 Step 1 확인 |

---

### Task 1: 시험 도구 확장(T2)

**Files:**
- Modify: `scripts/_eval_clause.py` (`load_units` 가 `base`·`system.md` 를 읽는다. `check_units` 가 단위별 기준 커밋 내용을 받는다. `gen_key` 와 생성 호출이 `system.md` 를 반영한다)
- Modify: `scripts/_eval_run.py` (생성 호출에 시스템 프롬프트 인자를 받는 매개변수)
- Modify: `scripts/test_eval_cases.sh` (단위마다 `base` 커밋의 `agent-principles.md` 를 꺼내 `check_units` 에 넘긴다)
- Modify: `scripts/_test_eval_clause.py` (아래 시험 추가)
- Modify: `evals/principles/README.md` (「클린룸 시험」 절에 `base`·`system.md` 설명)

**Interfaces:**
- Produces:
  - 단위 폴더의 `base` 파일은 기준 커밋 해시 한 줄이고, 없으면 7a2d26d 다.
  - 단위 폴더의 `system.md` 가 있으면 그 단위의 모든 생성 호출에 `--append-system-prompt <내용>` 을 붙인다. 생성 키는 `system.md` 가 있을 때만 그 내용의 해시를 덧붙이고, 없으면 지금 식(`_sha(prompt) + "-" + _sha(cond_text)`)을 그대로 쓴다.

- [ ] **Step 1: 실패하는 시험을 쓰라**

`scripts/_test_eval_clause.py` 에 아래 시험을 추가하라.

| 시험 | 기대 |
|---|---|
| `base` 가 있는 단위의 `current.md` 줄이 그 커밋 원칙에만 있음 | 오류 없음 |
| `base` 가 없는 단위의 `current.md` 줄이 7a2d26d 에 없음 | 오류 한 줄 |
| `system.md` 가 없는 단위의 `gen_key` | 지금 식과 같은 값 |
| `system.md` 가 있는 단위의 `gen_key` | 위 값과 다름 |
| `system.md` 가 있는 단위의 생성 명령 | `--append-system-prompt` 와 그 내용이 들어 있음 |

- [ ] **Step 2: 시험이 실패하는지 확인한 뒤 도구를 고쳐라**

Run: `bash scripts/test_eval_cases.sh`
Expected: 새 시험이 FAIL 로 나온다. 고친 뒤에는 이 스크립트의 FAIL 이 0 이다.

- [ ] **Step 3: 기존 결과가 그대로 쓰이는지 확인하라**

Run: `bash scripts/eval_clause_report.sh`
Expected: 2026-10-18 단위들의 판정이 고치기 전과 같다. `미완` 이 새로 생기지 않는다.

- [ ] **Step 4: 전체 테스트를 실행하고 커밋하라**

```bash
git add scripts evals/principles/README.md
git commit -m "조항 시험 도구에 단위별 기준 커밋과 시스템 프롬프트 조건을 넣는다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: `BULLET-SCOPE`·`NO-MID-MOD` 문안 비교(T3·T4, T7 의 `NO-MID-MOD`×`TERM-EXPLAIN`)

**Files:**
- Create: 아래 표의 단위 폴더, 각각 `current.md`·`new.md`·`ids`·`base`
- Modify: `docs/domain-korean.md` (두 조항 절의 측정 기록)

**Interfaces:**
- Consumes: Task 1 의 `base`
- Produces: Task 5 가 사용자에게 보일 후보표의 행

이 plan 의 모든 `c20-` 단위는 아래 형식을 따른다.

- `current.md` 는 단위가 다루는 조항마다 두 줄을 둔다. 첫 줄은 그 조항이 속한 묶음 제목 바로 아래의 문단 줄 전체이고, 둘째 줄은 `agent-principles.md` 의 현행 조항 줄이다.
- `new.md` 는 `current.md` 와 같되, 시험하는 조항 줄만 표의 문안으로 바꾼다. 조항 줄은 `- **\`ID\`** — 본문` 형식이다.
- 표의 문안에 이유 문장("~하기 위해서다.")이 없으면 현행 조항 줄의 이유 문장을 끝에 붙여라. 문안 비교에 이유 문장의 유무가 섞이지 않게 하기 위해서다.
- `base` 는 `6b90dd4` 다.
- 같은 조항을 시험하는 단위끼리는 `ids` 와 실은 조항을 같게 두어라.

| 단위 | 실을 조항 | `ids` | 시험하는 조항 줄의 본문 |
|---|---|---|---|
| `c20-bullet-decision` | `BULLET-SCOPE` | `BULLET-SCOPE` | 불릿을 시작하기 전에 항목마다 한 문장으로 끝나는지 정하라. 한 문장으로 끝나지 않는 항목이 하나라도 있으면 그 목록을 처음부터 산문 문단으로 써라. 불릿은 같은 종류를 늘어놓을 때만 써라. 논증이 목록으로 끊기지 않게 하기 위해서다. |
| `c20-bullet-named` | `BULLET-SCOPE` | `BULLET-SCOPE` | 불릿은 같은 종류를 늘어놓을 때만 쓰고, 한 항목이 여러 문장이 되면 산문으로 써라. 굵은 라벨 뒤에 문장을 둘 이상 붙인 항목(`- **원인:** 문장. 문장.`)도 여러 문장 항목이다. 논증이 목록으로 끊기지 않게 하기 위해서다. |
| `c20-bullet-positive` | `BULLET-SCOPE` | `BULLET-SCOPE` | 같은 종류를 늘어놓을 때만 불릿을 쓰고, 항목마다 한 문장으로 써라. 설명이 두 문장 이상 필요한 내용은 문단으로 써라(예: '원인은 설정 누락이다. 그래서 배포가 멈췄다.'). 논증이 목록으로 끊기지 않게 하기 위해서다. |
| `c20-midmod-decision` | `NO-MID-MOD`, `TERM-EXPLAIN` | `NO-MID-MOD`, `TERM-EXPLAIN` | 명사를 꾸미는 말을 쓰기 전에 그 꾸밈말이 주어나 목적어를 따로 가지는지 정하라. 가지면 그 내용을 앞 문장으로 먼저 쓰고, 본 문장에서는 그 대상을 이름으로 가리켜라. 용어를 풀 때도 동작을 먼저 한 문장으로 쓰고 이름은 다음 문장에 둬라. 주어를 찾기 쉽게 하기 위해서다. |
| `c20-midmod-named` | `NO-MID-MOD`, `TERM-EXPLAIN` | `NO-MID-MOD`, `TERM-EXPLAIN` | 주어를 따로 가진 관형절(예: '감독원이 지적한')은 앞 문장으로 먼저 써라. 본 문장에서는 그 대상을 '그 건'처럼 가리켜라. 'X는 Y가 Z하는 W다' 꼴의 용어 풀이도 같다. 주어를 찾기 쉽게 하기 위해서다. |
| `c20-midmod-positive` | `NO-MID-MOD`, `TERM-EXPLAIN` | `NO-MID-MOD`, `TERM-EXPLAIN` | 주어와 서술어를 가깝게 두고 꾸밈말은 짧게 써라. 꾸밀 내용이 길면 앞 문장에 먼저 써라(예: '감독원이 3월에 지적했다. 그 건은 …'). 용어를 풀 때는 동작을 먼저 쓰고 이름을 뒤에 둬라(예: '서버가 같은 요청을 한 번만 처리하게 한다. 이 장치를 멱등성 키라고 한다.'). 주어를 찾기 쉽게 하기 위해서다. |

- [ ] **Step 1: 단위를 만들고 과제 집합을 확인하라**

같은 조항 단위끼리 `questions()` 가 고르는 과제 목록이 같은지 확인하라. 다르면 진행을 멈추고 이유를 보고하라.

- [ ] **Step 2: 실행하고 판정하라**

Run: `bash scripts/eval_clause.sh c20-bullet-decision c20-bullet-named c20-bullet-positive c20-midmod-decision c20-midmod-named c20-midmod-positive`
Expected: 오류 0건

Run: `bash scripts/eval_clause_report.sh c20-bullet-decision c20-bullet-named c20-bullet-positive c20-midmod-decision c20-midmod-named c20-midmod-positive`
Expected: 단위마다 판정 한 줄. 추가 질문 짝이 있는 조항은 위반 수가 같으면 `채택(차이없음)` 으로 나온다.

- [ ] **Step 3: 조항마다 후보를 정하고 기록하라**

조항마다 `채택` 단위를 `채택(차이없음)` 단위보다 앞에 두고, 같은 판정 안에서는 위반이 적은 단위를, 위반 수도 같으면 문안이 짧은 단위를 후보로 골라라. 둘 다 없으면 현행 유지가 후보다. 결과를 `docs/domain-korean.md` 의 두 조항 절에 「측정(2026-10-21 조항별 클린룸 시험)」 문단으로 적어라. 문단에는 단위별 과제 수·현행 위반·변경안 위반·판정, 고른 후보, 그리고 아래 두 가정을 적어라.

- 조항별 클린룸 시험에서만 확인했고 원칙 전체 속의 효과는 확인하지 않았다.
- 같은 현행 표본에 세 변경안을 견주어 고른 결과이며, 위반 1~2건 차이는 측정 흔들림 안에 든다.

- [ ] **Step 4: 전체 테스트를 실행하고 커밋하라**

```bash
git add evals/principles docs/domain-korean.md
git commit -m "BULLET-SCOPE·NO-MID-MOD 의 결정점·지목형·긍정형 문안을 시험한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: `SECTION-HEAD`·`COUNT-EARNS`·`EDIT-PRIORITY` 시험(T5)

**Files:**
- Create: `evals/principles/clauses/c20-section-head/`, `c20-count-earns/`, `c20-edit-priority/`
- Create: `evals/principles/cases/q-edit-hook-1/`, `q-edit-hook-2/`, `q-edit-hook-3/`, `q-edit-hook-f1/`, `q-edit-hook-f2/` (각 `prompt.md`·`criteria.md`)
- Modify: `q-count-earns-*` 과제의 `criteria.md` (경계 사례가 없을 때만), `docs/domain-korean.md`·`docs/domain-discipline.md` (측정 기록)

**Interfaces:**
- Consumes: Task 1, 그리고 `hooks/doc_review_posttooluse.sh` 의 `out=` 경고 문구
- Produces: Task 5 후보표의 행

| 단위 | 실을 조항 | `ids` | 시험하는 조항 줄의 본문 |
|---|---|---|---|
| `c20-section-head` | `SECTION-HEAD` | `SECTION-HEAD` | 답을 시작하기 전에 다룰 주제가 둘 이상인지 정하라. 둘 이상이면 첫 주제부터 절 제목을 달고 시작하라. 긴 글에서 찾는 내용으로 바로 가게 하기 위해서다. |
| `c20-count-earns` | `COUNT-EARNS` | `COUNT-EARNS` | 목록을 시작하는 문장에 목록의 개수를 쓰지 말고, 앞에 나온 대상은 개수 대신 이름으로 가리켜라. 측정값·금액·기한처럼 결론을 받치는 숫자만 본문에 적어라. 결정과 무관한 숫자가 주의를 흩지 않게 하기 위해서다. |
| `c20-edit-priority` | `EDIT-PRIORITY` | `EDIT-HOOK` | 파일로 쓴 글에 형식 경고가 오면 전달하기 전에 이번에 쓴 줄 중 경고가 가리킨 줄을 고쳐라. 원래 있던 줄은 다시 쓰지 말고 사용자에게 알려라. 고칠 때는 중복 문장과 군더더기 문장을 먼저 덜어 내고, 그다음 문장 구조를 손보고, 낱말은 마지막에 바꿔라. 생성 중에 놓친 위반을 재작성으로 잡기 위해서다. |

`q-edit-hook-*` 과제는 `tags: [dev]`, `type: doc`, `clause: [EDIT-HOOK]` 로 두어라. `EDIT-HOOK` 은 이 묶음만 고르려고 붙인 시험용 이름이며 원칙의 조항 ID 가 아니다. 과제 본문에는 아래 세 가지를 직접 넣어라.

- 모델이 이번에 파일로 쓴 초안 전문
- 그 파일에 대해 `hooks/doc_review_posttooluse.sh` 가 내는 형식 경고 문구와 위반 줄 보고(`이름표:줄: 종류: 발췌`)
- "고친 파일 전문과 사용자에게 보낼 답을 써라"라는 요청

`kind: should` 과제는 이번에 쓴 줄이 경고를 받은 상황이고, 실패는 그 줄이 고쳐지지 않은 경우다. `kind: should-not` 과제는 원래 있던 줄이 경고를 받은 상황이고, 실패는 그 줄을 다시 쓴 경우다. `q-edit-hook-1`·`2` 를 짝(`pair`)으로, `f1`·`f2` 를 `followup: true` 짝으로 두어라.

`q-count-earns-*` 과제의 `criteria.md` 에 날짜·버전 번호·측정값·순서 있는 단계 번호를 「세지 않는 것」으로 적어라. 이미 적혀 있으면 고치지 마라. 고쳤으면 판정 키가 바뀌므로, 기존 `COUNT-EARNS` 단위도 함께 실행해 판정만 새로 내라. 생성은 기록에 있으므로 다시 하지 않는다.

- [ ] **Step 1: 과제와 단위를 만들고, 실행하고, 판정하라** — Task 2 Step 1·2 와 같은 방식이다. `criteria.md` 를 고쳤으면 기존 `COUNT-EARNS` 단위를 함께 실행하라.
- [ ] **Step 2: 기록하라** — Task 2 Step 3 과 같은 형식으로 `SECTION-HEAD`·`COUNT-EARNS` 는 `docs/domain-korean.md` 에, `EDIT-PRIORITY` 는 `docs/domain-discipline.md` 의 조항 절에 적어라.
- [ ] **Step 3: 전체 테스트를 실행하고 커밋하라**

```bash
git add evals/principles docs/domain-korean.md docs/domain-discipline.md
git commit -m "SECTION-HEAD·COUNT-EARNS·EDIT-PRIORITY 의 결정점 문안을 시험한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: 충돌 처방과 커밋 8b4a05a 후보 시험(T7·T8)

**Files:**
- Create: `evals/principles/clauses/c20-checkable/`, `c20-concise-priority/`(`system.md` 포함), `c20-subject-object/`, `c20-yagni/`, `c20-vocab-pref/`, `c20-anti-limit/`
- Create(동률일 때만): 추가 질문 짝이 없는 조항의 `q-<단위>-f1`·`f2`
- Modify: `docs/domain-discipline.md`·`docs/domain-korean.md` (측정 기록)

**Interfaces:**
- Consumes: Task 1 의 `system.md`
- Produces: Task 5 후보표의 행

| 단위 | 실을 조항 | `ids` | 시험하는 조항 줄의 본문 |
|---|---|---|---|
| `c20-checkable` | `CHECKABLE`, `BULLET-SCOPE` | `CHECKABLE`, `BULLET-SCOPE` | 작업을 시작하기 전에 사용자 요구를 확인할 수 있는 기준으로 바꿔 적어라. 단계가 둘 이상이면 각 단계 문장 안에 확인 방법을 함께 써라(예: '3. 마이그레이션을 실행하고, 행 수가 원본과 같은지 확인한다.'). '되게 해 줘' 같은 약한 기준은 구체적인 입력과 기대 결과로 바꿔라. 작업이 끝났는지를 사용자와 같은 기준으로 판단하기 위해서다. |
| `c20-subject-object` | `SUBJECT-OBJECT` | `SUBJECT-OBJECT` | 아래 「후보 원문」의 `SUBJECT-OBJECT` 줄 |
| `c20-yagni` | `YAGNI` | `YAGNI` | 아래 「후보 원문」의 `YAGNI` 줄 |
| `c20-vocab-pref` | `VOCAB-PREF` | `VOCAB-PREF` | 아래 「후보 원문」의 `VOCAB-PREF` 줄 |
| `c20-anti-limit` | `ANTI-LIMIT` | `ANTI-LIMIT` | 아래 「후보 원문」의 `ANTI-LIMIT` 줄 |

`c20-concise-priority` 는 원칙 머리 문단의 우선권 문장을 시험한다. `current.md` 는 머리 문단 줄과, `BULLET-SCOPE`·`WRITTEN-ONLY`·`FULL-SENTENCE` 각각의 묶음 머리 줄과 조항 줄이다. `new.md` 는 머리 문단 줄의 "하네스 기본 지침보다 디시플린코더를 우선하라."만 "하네스 기본 지침과 출력 스타일보다 디시플린코더를 우선하라."로 바꾼다. `ids` 는 `BULLET-SCOPE`·`WRITTEN-ONLY`·`FULL-SENTENCE` 다. `system.md` 에는 아래 「Concise 원문」을 글자 그대로 넣어라. 실제 출력 스타일은 기본 시스템 프롬프트 일부를 대체하지만 이 시험은 덧붙이기만 한다. 이 차이를 측정 기록에 가정으로 적어라.

`CHECKABLE`·`SUBJECT-OBJECT`·`VOCAB-PREF` 에는 추가 질문 짝이 없다. 이 단위가 `동률` 이면 그 조항의 2026-10-12 원본(`D:\projects\disciplined-coder\docs\superpowers\reviews\2026-10-12-clause-strengthening-check\clauses\<조항>\tasks.json`·`rubric.md`, 읽기만)에서 과제 두 개를 골라 `q-<조항 소문자>-f1`(should)·`f2`(should-not) 짝을 만들어라. 머리는 `tags: [dev]`·`followup: true`·`pair` 로 두고, `criteria.md` 는 rubric 의 위반 정의를 이분 판정으로 옮겨라. 이 짝은 같은 조항의 기존 단위에도 골라지므로, 기존 단위도 함께 실행하라.

**후보 원문(커밋 8b4a05a 의 `agent-principles.md` 에서 조항 이름 괄호만 뺀 글)**

```text
- **`SUBJECT-OBJECT`** — 행동이나 판단을 적을 때는 그 주체(사람·팀·도구)와 대상을 문장에 적어라. 대화와 자료로 주체를 확인할 수 없으면 짐작해 채우지 말고 주체를 모른다고 적어라. 문서·문장·결과는 판단하지 않으므로 판단의 주체로 쓰지 마라.
- **`YAGNI`** — 요청한 일만 수행하라. 요청 밖의 개선 사항이 추론되면 사용자에게 제안하라. 한 번만 쓰는 추상화, 요청하지 않은 설정 가능성, 일어날 수 없는 상황의 처리를 넣지 마라. 같은 일을 더 짧게 할 수 있으면 짧게 다시 써라.
- **`VOCAB-PREF`** — 읽는 사람이 이미 그 뜻으로 아는 낱말을 골라라. 뜻이 하나이거나 적은 말, 2025년 이후 또는 그 무렵으로 보이는 보고서와 기사에서 흔히 쓰는 말을 우선하라. 사용자의 업계에서 표준으로 쓰는 용어가 있으면 그 용어를 그대로 써라. 표준 용어가 영어 원어이면 원어로 써라. 용어를 새로 짓거나 고유명사를 한글로 음차하지 말고, 한자어와 외래어를 굳이 고유어로 바꾸지 마라. 영어를 번역할 때도 직역하지 말고 이 기준으로 낱말을 골라라.
- **`ANTI-LIMIT`** — `A가 아니라 B` 대구는 글 한 편에 한 번까지만 써라. 이미 한 번 썼으면 그다음부터는 A를 빼고 B만 단정문으로 써라.
```

**Concise 원문(2026-10-21 이 plan 을 쓴 세션의 시스템 프롬프트에서 옮김)**

```text
# Output Style: Concise
You are an interactive CLI tool that helps users with software engineering tasks. Keep your responses short and direct while doing the work just as thoroughly.

# Concise Style Active
The user chose brevity over narration. You should:

1. **Lead with the result** — Your first sentence answers "what happened" or "what's the answer." No preamble ("Let me...", "Now I'll...") and no closing recap of what you already said.
2. **Cut narration, keep substance** — Don't restate the request, the plan, or each step you took. Report outcomes, decisions, and anything the user must act on.
3. **Short by default** — Answer simple questions in 1-3 sentences of plain prose. Use headers, tables, and bullet lists only when they carry real structure, never as decoration.
4. **State things plainly** — Skip hedging boilerplate. Mention a caveat only when it changes what the user should do next.
5. **Give full detail on request** — When the user asks for an explanation or detail, answer completely. Conciseness never means withholding requested information.
6. **Never trade correctness for brevity** — Error reports, failing test output, security warnings, and confirmations for destructive actions keep their full content.

Where these rules conflict with more general communication or formatting guidance elsewhere in your instructions, these rules win.
```

- [ ] **Step 1: 단위를 만들고, 실행하고, 판정하라** — Task 2 Step 1·2 와 같은 방식이다.
- [ ] **Step 2: 기록하라** — Task 2 Step 3 과 같은 형식으로 조항이 속한 참고서의 조항 절에 적어라. `c20-concise-priority` 는 `docs/domain-discipline.md` 「생성 제약」 절 끝에 적어라.
- [ ] **Step 3: 전체 테스트를 실행하고 커밋하라**

```bash
git add evals/principles docs/domain-korean.md docs/domain-discipline.md
git commit -m "CHECKABLE·출력 스타일 우선권 처방과 8b4a05a 후보 문안을 시험한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: 채택 확인과 원칙 반영(T10 앞부분)

**Files:**
- Modify: `agent-principles.md` (사용자가 승인한 문안만)

**Interfaces:**
- Consumes: Task 2~4 의 측정 기록

- [ ] **Step 1: 후보표를 사용자에게 보이고 승인을 받아라**

조항마다 현행 문안, 후보 문안, 단위별 과제 수·현행 위반·변경안 위반·판정을 한 표로 보여라. Task 2 Step 3 의 두 가정도 함께 적어라. 사용자가 조항마다 채택 여부를 정한다. 이 원칙은 병합과 push 뒤 이 PC 의 모든 프로젝트 세션에 실리기 때문이다.

- [ ] **Step 2: 승인한 문안을 옮겨라**

승인한 조항 줄만 `agent-principles.md` 에 옮겨라. 머리 문단 단위가 승인되었으면 머리 문단 문장을 바꿔라. 각 조항의 측정 기록 문단 끝에 "2026-10-21 사용자 승인으로 원칙에 옮겼다" 또는 "현행을 유지했다"를 적어라.

- [ ] **Step 3: 전체 테스트와 validate 를 실행하고 커밋하라**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령, `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`

```bash
git add agent-principles.md docs/domain-korean.md docs/domain-discipline.md
git commit -m "조항별 클린룸 시험 결과 중 사용자가 승인한 문안을 원칙에 옮긴다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: 기존 문서의 형식과 용어 정리(2026-10-21 사용자 결정, T10 용어 정리)

**Files:**
- Modify: `check()` 가 위반을 찾는 살아 있는 문서. 2026-10-21 집계에서는 `skills/audit-repo-docs/SKILL.md`, `skills/domain-plugin/SKILL.md`, `skills/nested-orchestration/SKILL.md`, `README.md`, `skills/domain-pruning/SKILL.md`, `skills/agent-prior-art/SKILL.md`, `CLAUDE.md`, `skills/dispatching-lenses/SKILL.md`, `skills/lens-readability/SKILL.md`, `skills/aggregating-lenses/SKILL.md`, `docs/domain-korean.md`, `skills/review-specs/SKILL.md`, `skills/review-docs/SKILL.md`, `skills/lens-consistency/SKILL.md`, `skills/lens-adversarial/SKILL.md`, `skills/lens-fit/SKILL.md`, `skills/domain-readme/SKILL.md` 였다. Task 2~5 가 쓴 측정 기록 때문에 `docs/domain-discipline.md` 가 늘 수 있다.
- Modify: "남에게 전달될"·"사람이 볼"을 쓰는 스킬 본문과 `README.md`

검사 대상에서 뺄 파일은 아래와 같다.

| 뺀 파일 | 이유 |
|---|---|
| `agent-principles.md` | 조항 줄 `- **\`ID\`** — …` 이 조항 형식이다. 문구 변경은 클린룸 시험 대상이다 |
| `korean-banned-words.md` | 표 위주의 원본 목록이다 |
| `docs/superpowers/` 아래 | 봉인된 기록과 지난 spec·plan 이다 |
| `evals/` 아래 | 평가 과제의 프롬프트는 일부러 위반을 담는다 |
| `HANDOFF-*.md` | 소비되면 지울 1회성 인계 문서다 |

**Interfaces:**
- Consumes: `hooks/_doc_form_check.py` 의 `check(text)`

- [ ] **Step 1: 고칠 줄을 뽑아라**

추적 중인 `.md` 중 위 표의 파일을 뺀 전부에 `check()` 를 실행해 파일·줄·종류 목록을 만들어라.

- [ ] **Step 2: 형식을 고쳐라**

라벨 불릿은 두 형태 중 하나로 고쳐라. 라벨 뒤 첫 문장만으로 항목이 성립하면 그 문장만 불릿에 남기고 나머지 문장은 목록 바로 뒤 문단으로 옮겨라. 그렇지 않으면 그 목록 전체를 산문 문단으로 바꿔라. 문장은 옮기기만 하고 다시 쓰지 마라. 지시의 조건과 순서가 바뀌면 스킬 동작이 바뀌기 때문이다. 아래는 글자 그대로 두어라.

- 스킬 front matter 의 `description`
- 절 제목, 소유 선언 문장("…은 여기가 소유한다"), 조항 ID, 포인터 문장
- 렌즈 SKILL.md 「체크리스트」 절의 `- **축**` 줄 머리. 이 절에서는 첫째 형태만 써라. `scripts/test_docs_drift.sh` 가 `- **` 줄에서 축 이름을 뽑기 때문이다

제목 개수는 제목에서 개수를 지워라.

- [ ] **Step 3: 용어를 맞춰라**

Run: `grep -rn -E '남에게 전달될|사람이 볼' skills README.md`
스킬 본문과 README 의 "남에게 전달될 문서"·"사람이 볼 문서"를 "읽기 위한 문서"로 바꿔라. front matter `description` 과 원칙의 `REVIEW-DELIVERABLE` 은 바꾸지 마라.

- [ ] **Step 4: 확인하라**

Run: Step 1 의 `check()` 실행
Expected: 위반이 0건이다.

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령, `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`

- [ ] **Step 5: 커밋하라**

```bash
git add -A skills README.md CLAUDE.md docs/domain-korean.md docs/domain-discipline.md
git commit -m "살아 있는 문서의 라벨 불릿·제목 개수와 '읽기 위한 문서' 용어를 정리한다" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7: main 병합과 push 확인(T10 마지막)

이 PC 의 세션은 GitHub 마켓플레이스 `chshin84/disciplined-coder` 의 main 을 자동 갱신으로 받는다(`~/.claude/plugins/known_marketplaces.json`). 그래서 로컬 병합만으로는 세션이 바뀌지 않고, push 해야 바뀐다. 사용자는 2026-10-21 에 병합 뒤 push 직전에 다시 묻기로 정했다.

- [ ] **Step 1: 병합 전 상태를 기록하라**

`git worktree list` 로 main 이 어느 worktree 에도 체크아웃되어 있지 않은지 확인하라. `git rev-parse main` 값을 기록하라. main 저장소 폴더 `D:\projects\disciplined-coder` 는 `feat/clause-strengthening` 을 체크아웃하고 있고 미추적 측정 원본이 있으므로, 그 폴더에서 병합하지 마라.

- [ ] **Step 2: 병합하라**

Run: `git switch main && git merge --no-ff feat/clause-candidates`
Expected: 충돌이 없다. 충돌이 있으면 `git merge --abort` 로 되돌리고 사용자에게 알려라. 병합 뒤 전체 테스트가 실패하면 `git reset --hard <Step 1 의 main 값>` 으로 되돌리고 실패 문구를 보고하라.

- [ ] **Step 3: plan 을 정리하라**

이 plan 과 앞 plan 을 지우기 전 커밋에 `archive/2026-10-21-clause-plans` 보존 태그를 달고, 두 plan 파일을 지우는 커밋을 만들어라. 이 브랜치의 리뷰 기록은 다음 차수 대조에 쓰는 최근 기록이므로 지우지 마라.

- [ ] **Step 4: push 승인을 받아라**

바뀐 조항 목록, 훅 동작, push 할 커밋과 태그 목록을 사용자에게 보이고 push 승인을 받아라. 승인하면 `git push origin main` 과 `git push origin archive/2026-10-18-prior-art-agent-draft-plan archive/2026-10-21-clause-plans` 를 실행하라. 다른 로컬 태그는 올리지 마라. push 뒤 되돌려야 하면 병합 커밋을 `git revert -m 1` 로 되돌린다는 사실도 함께 알려라. 승인하지 않으면 로컬 병합 상태로 두고 끝내라.

<!-- spec-review: passed -->
