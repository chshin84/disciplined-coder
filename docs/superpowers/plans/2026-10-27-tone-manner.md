# 조절 축 문체 규칙 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 에이전트원칙의 고정 문어체를 청자·내용으로 정하는 조절 축 규칙으로 바꾸고, 클린룸 시험으로 채택을 판정한 뒤 원칙·근거 문서·렌즈·스킬에 한 커밋으로 반영한다.

**Architecture:** 먼저 조항 문안을 시험 단위(`evals/principles/clauses/`)에 현행·변경안으로 적고 질문과 판정 기준을 확정한 뒤 시험한다. 채택되면 같은 문안을 `agent-principles.md` 에 옮기고, 축 표와 측정 기록은 `docs/domain-korean.md` 에, 판정 기준은 렌즈와 스킬에 반영한다.

**Tech Stack:** 마크다운 문서, bash 시험 스크립트(`scripts/eval_clause.sh`, `scripts/eval_clause_report.sh`, `scripts/test_eval_cases.sh`, `scripts/test_*.sh`).

**Spec:** `docs/superpowers/specs/2026-10-27-tone-manner-design.md`

## Global Constraints

- 축은 격식·거리·온도·밀도이며, 격식 축이 상대높임을 함께 맡는다.
- 대화 답과 작업 보고의 격식은 합쇼체, 밀도는 산문으로 고정한다.
- 저장소 작업 문서의 격식은 '~다'·'~하라', 밀도는 산문으로 고정한다.
- 축 표와 축 위치 예는 `docs/domain-korean.md` 에만 둔다. 에이전트원칙에는 결정 규칙만 넣는다.
- 청자를 정할 수 없는 파일 산출물은 추정해 쓰고, 추정을 대화 답에 한 줄로 밝히며, 이 규칙을 `ASK-OPTIONS` 예외로 적는다.
- 고칠 대상으로 받은 원문은 청자 신호에서 빼라.
- 기계 검사는 금지어 검사와 기존 문서 형식 검사만 유지하라.
- 같은 질문을 같은 조건으로 다시 실행하지 마라(저장소 CLAUDE.md).
- 조항 문안은 저장소 CLAUDE.md 「퇴고 기준」을 따라 써라.
- 시험 실행과 '원칙 없음' 진단은 사용자가 2026-10-27 에 승인했다.

## Review Focus

- 사용자가 여러 턴 반말로 말한 뒤 작업 질문을 하면, 답은 합쇼체 산문을 유지해야 한다(Task 2 의 `q-tone-axis-3`).
- 사용자가 진행 상황을 물으면, 답은 개조식 조각 없이 산문이어야 한다(Task 2 의 `q-tone-axis-4`).
- 사용자가 대화체 발표자료를 고칠 원문으로 주면, 결과는 원문 문체를 따르지 않고 개조식이어야 한다(Task 2 의 `q-tone-axis-2`).
- 개조식으로 압축해도 원문의 한정어와 근거가 남아야 한다(Task 2 의 `q-tone-axis-2` 판정 기준).
- 원칙만 바뀌고 가독성 렌즈가 그대로이면 렌즈가 개조식을 문어체로 되돌리므로, 원칙과 렌즈가 같은 커밋에 반영되어야 한다(Task 4).

---

### Task 1: 시험 단위에 현행 문안과 변경안 작성

**Files:**
- Create: `evals/principles/clauses/c27-tone-axis/ids`, `base`, `current.md`, `new.md`
- Create: `evals/principles/clauses/c27-tone-axis-none/ids`, `base`, `new.md`

**Interfaces:**
- Produces: 새 조항 ID `TONE-AXIS`. `c27-tone-axis/ids` 에는 `TONE-AXIS`, `WRITTEN-ONLY`, `NO-MIRROR`, `FULL-SENTENCE`, `BULLET-SCOPE`, `NO-SQUEEZE`, `ONE-IDEA`, `VOCAB-PREF`, `ASK-OPTIONS` 를 한 줄씩 적는다. `c27-tone-axis-none/ids` 에는 `TONE-AXIS` 한 줄을 적는다. 두 `base` 에는 `a38f5e5b` 를 적는다.

- [ ] **Step 1: `current.md` 를 써라.** `agent-principles.md` 「출력」 절 머리 문장, `KO-SYNTAX` 머리 문장, ids 의 기존 조항 문안을 현재 파일에서 글자 그대로 옮겨라. 확인: `bash scripts/test_eval_cases.sh 2>&1 | grep c27` 에 "기준 원칙에 없다" 줄이 없어야 한다.

- [ ] **Step 2: `new.md` 를 써라.** spec 「항상 지키는 규칙과 축이 움직이는 규칙」 표, 「고정한 축 위치」, 「청자 신호와 입력 문체의 구분」, 「청자를 정할 수 없을 때」, 「결정 시점과 결정 방법」을 조항 문안으로 옮겨라. `TONE-AXIS` 에는 결정 규칙만 넣고 축 표는 넣지 마라. `BULLET-SCOPE` 의 "같은 종류만 불릿"과 "두 문장 이상은 문단" 문장은 그대로 두어라. `VOCAB-PREF` 의 직역 금지 문장에는 구조 예(무생물 주어와 타동사, '~를 통해'·'~에 대한', 이중 피동)를 넣어라. 확인: spec 표의 조항마다 `new.md` 에 해당 문장이 있다.

- [ ] **Step 3: `c27-tone-axis-none/new.md` 에 Step 2 의 `TONE-AXIS` 조항 문안만 복사하라.** 이 단위는 `current.md` 가 없어 조항 없음 조건(원칙이 전혀 실리지 않은 빈 설정)과 비교한다. 확인: 두 `new.md` 의 `TONE-AXIS` 줄이 같다.

- [ ] **Step 4: 문안을 「퇴고 기준」으로 점검하라.** 주체 호응, 범위의 정확성, 한 조항 한 관심사, 원칙의 자기 적용, 결정점, 습관 반대 조항을 차례로 확인하라. 확인: 고친 점을 Step 5 의 커밋 본문에 항목으로 적는다.

- [ ] **Step 5: 커밋하라.** 제목은 "조절 축 문체 규칙의 현행 문안과 변경안을 시험 단위로 적는다"이고, 본문에는 Step 4 의 점검 결과를 적어라.

```bash
git add evals/principles/clauses/c27-tone-axis evals/principles/clauses/c27-tone-axis-none
git commit
```

### Task 2: 새 질문 추가와 기존 판정 기준 확정

**Files:**
- Create: `evals/principles/cases/q-tone-axis-1/` ~ `q-tone-axis-4/` 의 `prompt.md`, `criteria.md`
- Modify: c27-tone-axis 단위가 고르는 기존 질문 중 `type: deliverable` 질문의 `criteria.md`

**Interfaces:**
- Consumes: Task 1 의 조항 ID `TONE-AXIS`.
- Produces: 머리 `tags: [dev]`, `kind`, `pair`, `type`, `failure`, `clause`, `judge` 를 가진 질문. `q-tone-axis-1`(`should`, `type: deliverable`)과 `q-tone-axis-3`(`should-not`, `type: chat`)이 짝이고, `q-tone-axis-2`(`should`, `type: deliverable`)와 `q-tone-axis-4`(`should-not`, `type: chat`)가 짝이다.

- [ ] **Step 1: `q-tone-axis-1` 을 써라.** 아래 원문을 넣고 "전문가에게 평가를 청하는 LinkedIn 글로 다듬어 달라"고 요청하라. 원문에서 링크 주소와 회사 이름은 지웠다.

```text
한국인 사무직이 클로드 코드를 잘 활용하기 위한 플러그인을 제작하여 운영 중입니다. 전문가분들께 냉정한 평가를 듣고 싶습니다.
다들 AX많이 하시지요? 저는 금융 현업에서 AX를 진행하고 있습니다. 사내 클로드코드 패키지에 수퍼파워를 넣은 것만으로도 직원들의 반응은 괜찮았죠. 다만, 설계 수준의 일관성이 잘 지켜지지 않는다고 생각했습니다. 여기다가 AI 찌꺼기 같은 표현들이 계속 발목을 잡는 것도 있었구요. 무엇보다 비개발자들은 설계 검토하는데 스트레스를 많이 받더라구요.
이 문제점을 해결하고자 플러그인을 제작했습니다. 일단 저와 사내 사용자들은 이 접근으로 토큰/시간을 꽤나 save 했습니다. 날카로운 식견으로 평가를 부탁드립니다.
```

확인: `prompt.md` 에 링크 주소, 사람 이름, 회사 이름이 없다.

- [ ] **Step 2: `q-tone-axis-2` 를 써라.** 아래 원문을 넣고 "사내 발표자료의 근거 항목으로 고쳐 달라"고 요청하라.

```text
이 구조를 고른 이유
① 여의도와 서버를 잇는 전용선은 대역폭이 정해져 있다
② 위너스도 같은 전용선을 쓰므로 요청이 몰리면 위너스 접속도 느려질 수 있다
③ 파일 하나에 요청이 여러 번 오가면 처리가 오래 걸린다 (1 file multiple query)
④ 외부 서버는 공용폴더에 직접 접근하기 어렵다
```

확인: `prompt.md` 에 원문 네 항목과 제목이 모두 있다.

- [ ] **Step 3: `q-tone-axis-3`·`q-tone-axis-4` 를 써라.** `q-tone-axis-3` 은 사용자가 반말로 말한 이전 대화 다섯 턴 뒤의 작업 질문이다. `q-tone-axis-4` 는 작업 기록 뒤 "어디까지 됐어?" 질문이다. 확인: 두 질문 모두 `type: chat` 이다.

- [ ] **Step 4: 판정 기준을 써라.** 산출물 질문의 기준에는 "감싸는 대화 답은 합쇼체 산문, 산출물 본문은 아래 기준"을 나눠 적어라. `q-tone-axis-1` 의 성공 조건은 게시글 본문에 해요체와 1인칭 표현이 있는 것이다. `q-tone-axis-2` 의 성공 조건은 네 항목이 명사구나 명사형으로 끝나고 '직접'과 '같은 전용선을 쓴다'는 뜻이 남아 있는 것이다. `q-tone-axis-3` 의 실패 조건은 답에 반말이나 구어 종결이 있는 것이다. `q-tone-axis-4` 의 실패 조건은 답 본문이 명사 조각이나 기호로 문장을 대신하는 것이다. 확인: 네 `criteria.md` 에 성공과 실패가 모두 있다.

- [ ] **Step 5: 기존 deliverable 질문의 판정 기준을 시험 전에 확정하라.** 대상은 `q-bullet-scope-3`, `q-full-sentence-3`, `q-one-idea-3`, `slidetitle-split` 이고, ids 에 넣은 `ASK-OPTIONS`·`VOCAB-PREF` 가 끌어오는 질문 중 `type: deliverable` 인 질문도 포함한다. 기준이 산출물 본문의 개조식을 실패로 판정하면 새 문안에 맞게 고치고, 그렇지 않으면 그대로 두어라. 확인: 고친 질문과 그 이유를 커밋 본문에 적는다.

- [ ] **Step 6: 형식 검사를 실행하라.**

Run: `bash scripts/test_eval_cases.sh 2>&1 | tail -3`
Expected: `FAIL=0`

- [ ] **Step 7: 커밋하라.**

```bash
git add evals/principles/cases
git commit -m "조절 축 문체 규칙을 겨눈 질문을 추가하고 산출물 질문의 판정 기준을 확정한다"
```

### Task 3: 시험 실행과 채택 판정

**Files:**
- 결과: `evals/principles/results/clauses/gen.jsonl`, `judge.jsonl`(스크립트가 덧붙인다)

**Interfaces:**
- Consumes: Task 1 의 두 시험 단위, Task 2 의 질문과 판정 기준.
- Produces: 채택·기각 판정과 측정 메모(Task 4 의 측정 문단 재료).

- [ ] **Step 1: 두 단위를 실행하라.**

Run: `bash scripts/eval_clause.sh c27-tone-axis c27-tone-axis-none`
Expected: 종료 코드 0, `ERROR` 줄 없음.

- [ ] **Step 2: 판정을 보라.**

Run: `bash scripts/eval_clause_report.sh c27-tone-axis c27-tone-axis-none`
Expected: 두 단위의 조건별 위반 수와 판정이 나온다.

- [ ] **Step 3: 겨눈 질문과 회귀 질문을 나눠 세라.** `gen.jsonl`·`judge.jsonl` 에서 `q-tone-axis-*` 의 위반과 나머지 질문의 위반을 조건별로 따로 세어 측정 메모에 적어라. 확인: 메모에 두 합계가 조건별로 있다.

- [ ] **Step 4: 채택 규칙을 적용하라.** 문구 변경(`c27-tone-axis`)은 변경안 위반이 현행보다 적고, 회귀 질문의 변경안 위반이 현행보다 많지 않을 때 채택한다. 새 조항 `TONE-AXIS`(`c27-tone-axis-none`)는 저장소 규칙대로 조항 없음보다 위반이 적을 때만 넣고, 조항 없음에서 모든 질문이 지켜지면 넣지 않는다. 확인: 메모에 두 단위의 판정과 근거 숫자가 있다.

- [ ] **Step 5: 동률이면 질문 짝을 한 번만 추가하라.** 새 짝은 `evals/principles/cases/q-tone-axis-5`·`6` 에 쓰고, 머리에 `followup: true` 를 넣고, 판정 기준은 Task 2 Step 4 와 같은 방식으로 결과를 보기 전에 써라. 커밋한 뒤 Step 1~4 를 다시 실행하라. 확인: 보고 출력이 '동률' 대신 '채택(차이없음)'이나 '넣지않음'을 낸다.

- [ ] **Step 6: 진단을 해석하라.** `q-tone-axis-1`·`2` 에서 현행 조건이 실패하고 조항 없음 조건이 통과하면 원인을 현행 규칙으로, 두 조건이 모두 실패하면 모델의 기본값으로 메모에 적어라. 질문 두 개를 한 번씩 실행한 결과라는 한계를 같은 문장에 적어라. 확인: 메모에 두 조건의 결과가 함께 있다.

- [ ] **Step 7: 한계를 메모에 적어라.** 묶음 단위라 결과가 나빠지면 원인 조항을 구분할 수 없다는 한계와, 단발 클린룸이 긴 세션의 표류를 재현하지 못한다는 한계를 적어라. 확인: 메모에 두 한계가 있다.

- [ ] **Step 8: 기각이면 멈추고 사용자에게 보고하라.** 결과 파일과 측정 메모는 `docs/superpowers/decisions/2026-10-27-tone-axis-rejected.md` 결정 기록으로 커밋하라. 시험 단위와 질문은 측정 이력으로 남겨라. 확인: 결정 기록과 결과 파일이 커밋되어 있다.

### Task 4: 원칙·근거 문서·렌즈·스킬 반영

**Files:**
- Modify: `agent-principles.md` (「출력」 절 머리 문장, `KO-SYNTAX` 머리 문장, Task 1 의 조항, `ASK-OPTIONS`, `VOCAB-PREF`)
- Modify: `docs/domain-korean.md` (새 절 「`TONE-AXIS`」, 바뀐 조항 절의 근거와 측정 문단)
- Modify: `agents/lens-readability.md` (「고정 규칙」, 「목적 주입」, 「관찰 목록」, 「고치는 범위」)
- Modify: `skills/review-docs/SKILL.md` (「`lens-fit`에 넘기는 계약」 절의 개조식 문장과 계약 항목)
- Modify: `skills/dispatching-lenses/SKILL.md` (「렌즈 그룹」 표의 `lens-readability`·`lens-fit` 행)
- 결과: `evals/principles/results/clauses/`

**Interfaces:**
- Consumes: Task 3 에서 채택한 `new.md` 문안과 측정 메모.

- [ ] **Step 1: `agent-principles.md` 에 채택한 문안을 글자 그대로 옮겨라.** 확인: `diff` 로 `new.md` 의 각 조항 줄이 `agent-principles.md` 에 있다.

- [ ] **Step 2: `docs/domain-korean.md` 를 고쳐라.** 새 절 「`TONE-AXIS`」에 spec 「조절 축」의 축 표와 축 위치 예, 사례, 선행연구 기록 포인터, Task 3 측정 메모를 적어라. 바뀐 조항 절마다 바꾼 이유와 사용자 승인(2026-10-27)을 적어라. 확인: `bash scripts/test_docs_drift.sh 2>&1 | tail -1` 이 `FAIL=0` 이다.

- [ ] **Step 3: 가독성 렌즈를 고쳐라.** 「고정 규칙」과 「고치는 범위」의 문어체 고정 문장을 "축 위치와 다른 종결을 지적하라"로 바꿔라. 「목적 주입」에 "축 위치를 받지 못하면 축이 움직이는 조항을 판정하지 말고 그 사실을 `notes` 에 적어라"를 넣어라. 「관찰 목록」에 직역투 구조, 어휘 정밀도, 압축으로 빠진 한정어를 넣어라. 확인: `bash scripts/test_lens_contract.sh 2>&1 | tail -1` 이 `FAIL=0` 이다.

- [ ] **Step 4: 스킬을 고쳐라.** `review-docs` 의 "개조식은 그것을 잡는 검사가 이 저장소에 없어 렌즈가 그대로 받는다"를 "개조식이 축 위치와 맞는지 렌즈가 본다"로 바꾸고, 계약에 축 위치를 넣어라. `dispatching-lenses` 「렌즈 그룹」의 두 행에 축 위치를 넘기는 항목을 넣어라. 확인: 두 파일에서 "축 위치"가 검색된다.

- [ ] **Step 5: 저장소 검사를 실행하라.**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 병렬 실행 명령
Expected: `ALL PASS`

Run: `claude plugin validate ./`
Expected: `Validation passed`

- [ ] **Step 6: 한 커밋으로 반영하라.** 원칙과 렌즈를 따로 반영하면 렌즈가 새 원칙을 따른 산출물을 문어체로 되돌리기 때문이다.

```bash
git add agent-principles.md docs/domain-korean.md agents/lens-readability.md skills/review-docs/SKILL.md skills/dispatching-lenses/SKILL.md evals/principles/results/clauses
git commit -m "문체를 청자와 내용으로 정하는 조절 축 규칙을 원칙과 렌즈에 반영한다"
```

plan 리뷰(`docs/superpowers/reviews/2026-10-27-tone-manner-plan-review.md`)의 지적을 반영해 판정 기준 점검을 시험 전으로 옮기고, 채택 규칙과 동률·기각 분기, 한계 기록을 고쳤다. 남은 지적 중 설계를 틀리게 만드는 지적은 없으므로 다시 리뷰하지 않는다.

<!-- spec-review: passed -->
