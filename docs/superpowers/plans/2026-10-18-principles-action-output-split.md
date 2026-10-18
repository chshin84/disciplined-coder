# 에이전트원칙 행동·출력 재편 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `agent-principles.md` 를 spec 의 「목표 구조」와 「조항 문구」대로 재편하고, 검사 스크립트·근거 참고서·참조 문서를 새 구조에 맞춘다.

**Architecture:** 원칙 파일은 마크다운 한 파일이다. `scripts/test_docs_drift.sh` 는 조항 ID·절 제목·소유 선언으로 원칙과 참고서의 연결을 검사한다. 이 plan 은 검사 스크립트를 새 구조 기준으로 먼저 고쳐 실패를 확인하고, 원칙과 참고서를 고쳐 통과시킨 뒤, 참조 문서의 절 제목을 고친다.

**Tech Stack:** Markdown, bash, awk, git.

**Spec:** `docs/superpowers/specs/2026-10-18-principles-action-output-split-design.md`

## Global Constraints

- 작업은 `superpowers:using-git-worktrees` 로 만든 worktree 브랜치에서 하라. push 하지 말고, main 병합은 Task 3 에서 사용자에게 물은 뒤에만 하라. 원칙 사본은 GitHub 의 main 에서 autoUpdate 로 모든 프로젝트에 퍼지므로, 병합과 push 를 한 번에 묶어 퍼지는 시점을 하나로 둔다.
- 각 검사 스크립트의 계약은 FAIL=0 이다. 기대 개수는 숫자로 적지 말고 FAIL=0 으로 판정하라.
- 문서를 대조하는 검사는 조항 ID·절 제목·소유 선언·포인터로 판정한다(`scripts/_doc_keys.sh`).
- 조항 줄 형식은 `- **\`ID\`** — 지시. 이유 한 줄.` 이다. spec 에서 새 조항에 붙인 '(새)' 표지는 원칙에서 빼라.
- 근거와 출처는 `docs/domain-discipline.md`·`docs/domain-korean.md` 에 조항 ID 로 적어라. 원칙의 지시 문장을 참고서에 그대로 옮겨 적으면 `KO_DUP`·`DC_DUP` 검사가 실패하므로, 변경 이유는 새 문안을 인용하지 말고 설명으로 적어라.
- 커밋된 리뷰 기록(`docs/superpowers/reviews/` 아래)은 봉인되어 있다. 손대지 마라.
- 옛 절 제목 검색의 예외는 날짜를 단 이력 문장, `evals/principles/` 의 `clauses`·`cases`·`results`, `docs/superpowers/rewrite-map/`, 리뷰 기록, spec·plan 이다.
- 커밋할 때는 파일 경로를 하나씩 적어라. 디렉터리 단위로 add 하지 마라.

## Review Focus

- 한국어 조항 ID 구간이 「공통」 끝에서 멈춰야 한다. 파일 끝까지 늘어나면 `TITLE-*`·`INSTRUCTION-FORM` 이 domain-korean 근거를 요구받는다. Task 1 Step 7 이 이 구간을 기대 목록과 대조한다.
- 묶음 제목의 단계가 바뀌어도 묶음 존재 검사가 정확한 단계로 찾아야 한다. Task 1 Step 1 이 묶음마다 단계를 지정한다.
- 「행동」 절 추출이 하위 제목에서 멈추지 않고 다음 `## ` 까지 가야 `LENS-ALLOWED`·`ASK-OPTIONS`·`SUB-ORCHESTRATE` 를 모두 본다. `doc_sec` 은 같은 단계 이상의 제목에서만 멈추므로 이 동작을 이미 한다. Task 1 Step 8 의 결함 주입이 이를 확인한다.
- `doc_sec` 이 `##### 문서 타입과 수명` 을 이름으로 찾아야 소유 선언 검사가 유지된다. `doc_sec` 은 단계와 무관하게 이름으로 찾으므로 스크립트를 고치지 않는다. Task 1 Step 6 의 전체 검사가 확인한다.
- hook 메시지의 「」 절 이름은 하나여야 한다. `scripts/test_hooks.sh` 가 그 이름 하나를 뽑아 원칙에서 `## <이름>` 을 찾는다. Task 2 Step 2 가 이를 지킨다.

---

### Task 1: 원칙 재편과 검사·참고서 정합

**Files:**
- Modify: `scripts/test_docs_drift.sh` (112행 `KO_IDS`, 788·793행 `WF_BLOCK`·`PO_BLOCK`, 824행 묶음 루프, 864행 `sec_has ... '원칙'`, 785·786·840·355행 주석)
- Modify: `agent-principles.md` (전체 재편)
- Modify: `docs/domain-korean.md`, `docs/domain-discipline.md`
- Modify: `skills/lens-readability/SKILL.md` (65행 「고칠 순서」 포인터)

**Interfaces:**
- Produces: 새 절 제목 `## 행동`·`### 착수`·`### 결정`·`### 실행`·`#### 문서 관리`·`##### 문서 타입과 수명`·`##### 메모리와 문서 맵`·`### 검증`·`### 보고`·`## 출력`·`### 공통`·`### 읽기 위한 문서`·`### 작업 지시서`·`` ### `REVISE-ORDER` — 사후 검사 ``·`### 대화 답과 작업 보고`. Task 2 는 이 제목으로 참조를 고친다.

- [ ] **Step 1: 검사 스크립트를 새 구조 기준으로 고쳐라**

`KO_IDS` 는 `` /^#### `PLAIN-KO`/ `` 에서 시작해 다음 `^### ` 또는 `^## ` 앞에서 멈추게 하라. `WF_BLOCK`·`PO_BLOCK` 은 `^## 행동` 에서 시작해 다음 `^## ` 앞에서 멈추게 하라. 864행의 절 이름 `'원칙'` 은 `'행동'` 으로 바꿔라.

824행 루프는 묶음마다 정확한 단계로 찾게 하라. `PLAIN-KO`·`KO-SYNTAX`·`PROSE-FORM`·`READ-FLOW`·`UNPACK` 은 `` ^#### ` ``, `REVISE-ORDER` 는 `` ^### ` `` 이다. 주석의 옛 절 이름도 새 이름으로 고쳐라.

- [ ] **Step 2: 검사가 실패하는지 확인하라**

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep 'FAIL:'`
Expected: '한국어 조항 ID 를 뽑았다', `LENS-ALLOWED`·`SUB-ORCHESTRATE`·nested-orchestration 관련 검사, 「행동」 절의 `ASK-OPTIONS` 검사, 묶음 존재 검사가 FAIL 로 나온다.

- [ ] **Step 3: 검사 스크립트만 먼저 커밋하라**

```bash
git add scripts/test_docs_drift.sh
git commit -m "검사: 새 원칙 구조(행동·출력) 기준으로 절 추출과 묶음 단계를 고친다"
```

이 커밋 뒤에는 `scripts/test_docs_drift.sh` 를 고치지 마라. Step 6 에서 실패가 나면 원칙이나 참고서를 고쳐라. 검사를 고쳐야 할 것 같으면 멈추고 그 이유를 보고하라.

- [ ] **Step 4: `agent-principles.md` 를 재편하라**

spec 「목표 구조」의 절 순서대로 조항을 옮기고, 「조항 문구」의 완성 문장과 편집 지시를 그대로 적용하라. 「조항 문구」에 없는 조항은 현행 문구를 그대로 옮겨라. 현행의 `### 산출물 검증`·`## 코드`·`## 작업 문서·지시문` 제목은 없애라.

- [ ] **Step 5a: domain-korean 의 근거 절을 옮기고 고쳐라**

`NAME-ITEMS`·`STATE-ASSUME` 의 근거 절을 domain-discipline 에서 domain-korean 의 `UNPACK` 절 아래로 옮겨라. `STATUS-FIRST` 의 근거 절은 domain-korean 에서 domain-discipline 으로 옮겨라. `EDIT-PRIORITY` 의 근거 절도 domain-discipline 으로 옮기고, 비게 되는 `## REVISE-ORDER — 고칠 순서` 절은 지워라.

「모든 출력」과 「남에게 전달하는 산출물」로 현재 소유자를 가리키는 문장(7·224행 등)은 새 절 이름으로 고쳐라. 생성형으로 바뀐 조항(`ANTI-LIMIT`·`NO-MID-MOD`·`NO-STACK-MOD`·`COMMA-CUT`·`ONE-IDEA`)과 `VOCAB-PREF` 의 절에는 2026-10-18 변경 이유를 한 단락씩 적어라. 변경 이유는 세 가지다. 스트리밍 생성 중에 지킬 수 있는 문구로 바꿨다. 사용자가 확정했다. 클린룸 시험을 생략했다.

- [ ] **Step 5b: domain-discipline 의 근거 절을 만들고 고쳐라**

`DELEGATED-SCORE`·`TOP-DOWN`·`REPORT-WHEN`·`REPORT-SCOPE`·`CONCRETE-FORM` 의 `### ID` 절을 만들어라. 절마다 근거와 "클린룸 시험 없이 넣었다" 문장과 되돌릴 계기(같은 교정이 다시 나오는 것)를 적어라. 옮겨 온 `EDIT-PRIORITY` 절에는 2026-10-18 변경 이유를 적어라. `NO-RAW-OUTPUT` 절에는 Google 코드 리뷰 지침 근거를 URL 과 가정 표시와 함께 적어라.

`##` 절 제목의 옛 층 이름과 '(원칙 층)' 표기는 새 구조에 맞춰라. 이번 차수의 근거는 「행동」 절 머리에 적어라. 근거는 2026-10-18 의 퀀트 market-leaders 세션 하나와 원칙 구분 검토 세션 둘의 대화 분석, spec 의 사용자 결정, 시험 생략이다.

- [ ] **Step 5c: lens-readability 의 포인터를 고쳐라**

`skills/lens-readability/SKILL.md` 65행이 domain-korean 의 「고칠 순서」를 가리킨다. 이 포인터를 domain-discipline 의 `EDIT-PRIORITY` 절로 바꿔라.

- [ ] **Step 6: 전체 검사를 실행하라**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령
Expected: `ALL PASS`

- [ ] **Step 7: 옮긴 근거와 한국어 조항 구간을 대조하라**

Run: `for id in NAME-ITEMS STATE-ASSUME STATUS-FIRST EDIT-PRIORITY DELEGATED-SCORE TOP-DOWN REPORT-WHEN REPORT-SCOPE CONCRETE-FORM; do echo "$id $(grep -cE "^### \`$id\`" docs/domain-korean.md docs/domain-discipline.md | awk -F: '{s+=$2} END{print s}')"; done`
Expected: 모든 줄이 `1` 로 끝난다.

Run: `awk '/^#### `PLAIN-KO`/{f=1} f&&/^##?#? /{exit} f' agent-principles.md | grep -oE '^- \*\*`[A-Z-]+`' | grep -oE '[A-Z][A-Z-]+' | tr '\n' ' '`
Expected: spec 「목표 구조」 「공통」의 ID 와 같은 목록이 나온다(`VOCAB-PREF` 부터 `STATE-ASSUME` 까지).

- [ ] **Step 8: 커밋하라**

```bash
git add agent-principles.md docs/domain-korean.md docs/domain-discipline.md skills/lens-readability/SKILL.md
git commit -m "에이전트원칙: 행동·출력으로 재편하고 근거 참고서를 맞춘다"
```

- [ ] **Step 9: 고친 검사에 결함을 주입해 실패를 확인하라**

Step 8 의 커밋 뒤에 아래 결함마다 파일을 임시로 고치고, `bash scripts/test_docs_drift.sh 2>&1 | grep -c 'FAIL:'` 가 1 이상인지 확인하라. 확인한 뒤 `git checkout -- <파일>` 로 되돌려라.

- `agent-principles.md` 에서 `LENS-ALLOWED` 줄을 「출력」 절 끝으로 옮긴다.
- `docs/domain-korean.md` 에서 `STATE-ASSUME` 절을 지운다.
- `agent-principles.md` 에서 `` #### `UNPACK` `` 를 `` ### `UNPACK` `` 로 바꾼다.

- [ ] **Step 10: spec 의 문구가 들어갔는지 확인하라**

Run: 아래 낱말 조각마다 `grep -cF '<조각>' agent-principles.md`
조각: `출력의 전달력이 가장 중요하다`, `이 절의 조항은 모든 작업에 적용하라`, `` `SUB-ORCHESTRATE` 판단을 생략하라 ``, `작업이 끝났는지를 사용자와 같은 기준으로`, `외부 자료로 덮지 않고`, `질문이 다루는 설계 층`, `위임한다고 명시했으면`, `되돌리기 어려운 손실을`, `가장 넓은 설계 층`, `설계 문서가 있든 없든`, `거부 문구와 함께`, `요청 범위 밖으로 보고 빼라`, `다시 리뷰하지 않는 안을 권장안으로`, `새 결과도 없는 중간 알림`, `이 세션이 서브 세션에 위임한 일`, `Claude 가 쓰는 모든 글`, `글을 쓰는 동안 아래 조항을 모두 적용하라`, `새로 붙인 이름이라고 밝혀라`, `'뿐 아니라'는 대상이 아니다`, `관형절이 길어질 것 같으면`, `더 꾸밀 내용은 서술어나 다음 문장에 써라`, `다시 쉼표가 필요해지는 곳에서`, `네 문장에 이르면 새 단락을`, `파일로 쓰는 작업 보고도 여기에 든다`, `에이전트가 읽고 따를 글`, `다 쓴 뒤 전달하기 전에 적용하라`, `「공통」 조항의 위반을 다시 검출해`, `대화 답으로 보내는 글`, `코드 변경은 \`EXPLAIN-STRUCTURE\` 를 따르라`
Expected: 모든 조각이 `1` 이다.

Run: `grep -c '표준 용어가 영어 원어이면 원어로 써라' agent-principles.md`
Expected: `0`

- [ ] **Step 11: 새 조항 근거 절의 시험 생략 표시를 확인하라**

Run: `for id in DELEGATED-SCORE TOP-DOWN REPORT-WHEN REPORT-SCOPE CONCRETE-FORM; do echo "$id $(awk -v h="### \`$id\`" '$0==h{f=1;next} f&&/^##/{exit} f' docs/domain-discipline.md | grep -c '클린룸 시험 없이')"; done`
Expected: 모든 줄이 `1` 이상으로 끝난다.

- [ ] **Step 12: 「공통」에 사후 확인형 문구가 남았는지 보고하라**

「공통」의 조항을 하나씩 읽어라. spec 이 현행 유지로 정한 `BULLET-SCOPE`·`SECTION-HEAD`·`TERM-ONE` 은 대상에서 빼라. 다 쓴 뒤에야 판단할 수 있는 문구(예: '떼어 내라', '한 번까지만')가 남았으면 고치지 말고 조항 ID 와 문구를 보고하라.
Expected: 보고할 문구가 없다.

### Task 2: 참조 문서의 절 제목과 review-specs

**Files:**
- Modify: `skills/review-specs/SKILL.md` (「작업 순서와 다시 리뷰」)
- Modify: `skills/domain-readme/SKILL.md`, `CLAUDE.md`, `README.md`, `hooks/doc_format_pretooluse.sh`, `scripts/scaffold.sh`, `evals/principles/README.md`

**Interfaces:**
- Consumes: Task 1 의 새 절 제목.

- [ ] **Step 1: 옛 절 제목의 남은 위치를 찾아라**

Run: `grep -rnE '「(원칙|모든 출력|남에게 전달하는 산출물|작업 문서·지시문|코드|산출물 검증|고칠 순서)」' --include=*.md --include=*.sh . | grep -vE 'docs/superpowers/(reviews|specs|plans|rewrite-map)/|evals/principles/(clauses|cases|results)'`
Expected: `CLAUDE.md`·`README.md`·`hooks/doc_format_pretooluse.sh`·`scripts/scaffold.sh`·`skills/domain-readme/SKILL.md` 와, 날짜를 단 이력 문장에서 결과가 나온다.

Run: `grep -n '남에게 전달하는 산출물' evals/principles/README.md`
Expected: 63행의 표 라벨이 나온다.

- [ ] **Step 2: 각 위치를 새 이름으로 고쳐라**

옛 「작업 문서·지시문」은 문맥에 따라 「문서 관리」(타입과 수명)나 「작업 지시서」(지시문 작성)로 고쳐라. `hooks/doc_format_pretooluse.sh` 28행의 메시지는 낫표 절 이름을 「문서 관리」 하나만 적어라. 지시문 작성 규칙도 가리켜야 하면 낫표 없이 '작업 지시서 절'로 적어라.

`evals/principles/README.md` 63행의 라벨은 '읽기 위한 문서(`deliverable`)'로 바꿔라. 날짜를 단 이력 문장은 그대로 둬라.

- [ ] **Step 3: review-specs 의 다시 리뷰 기준을 맞춰라**

`skills/review-specs/SKILL.md` 「작업 순서와 다시 리뷰」에 두 문장을 넣어라. 하나는 "물을 때는 남은 지적이 설계를 틀리게 만드는지를 함께 적고, 그런 지적이 없으면 다시 리뷰하지 않는 안을 권장안으로 제시한다."이다. 다른 하나는 "다시 리뷰하면 바뀐 절과, 그 절이 가리키거나 그 절을 가리키는 절을 대상으로 한다."이다.

- [ ] **Step 4: 남은 위치가 이력 문장뿐인지 확인하라**

Run: Step 1 의 첫 명령
Expected: 결과가 없거나, 날짜를 단 이력 문장만 나온다.

- [ ] **Step 5: 전체 검사와 플러그인 검증을 실행하라**

Run: 저장소 CLAUDE.md 「변경 뒤 실행」의 명령, 이어서 `claude plugin validate ./`
Expected: `ALL PASS`, `Validation passed`

- [ ] **Step 6: 커밋하라**

```bash
git add skills/review-specs/SKILL.md skills/domain-readme/SKILL.md CLAUDE.md README.md hooks/doc_format_pretooluse.sh scripts/scaffold.sh evals/principles/README.md
git commit -m "참조 문서의 절 제목을 새 원칙 구조에 맞추고 review-specs 의 다시 리뷰 기준을 맞춘다"
```

### Task 3: 메모리 처분과 병합

**Files:**
- Delete(사용자가 고르면): `~/.claude/projects/D--projects-Structure-disciplined-coder/memory/score-options-then-proceed.md`, `report-only-this-session-work.md` 와 `MEMORY.md` 의 해당 줄

**Interfaces:**
- Consumes: Task 1·2 의 커밋.

- [ ] **Step 1: 메모리 처분을 물어라**

두 메모리가 원칙의 `DELEGATED-SCORE`·`REPORT-SCOPE` 로 옮겨졌다. 지울지 선택 도구로 묻고, 고른 대로 처리하라.

- [ ] **Step 2: 병합과 push 를 물어라**

worktree 브랜치를 main 에 병합하고 push 할지 선택 도구로 물어라. push 하면 원칙 사본이 autoUpdate 로 모든 프로젝트에 퍼진다는 사실과, 되돌리려면 병합 커밋을 revert 해 push 해야 하며 다음 세션부터 반영된다는 사실을 함께 적어라. 사용자가 승인하면 병합하고 push 하라.

<!-- spec-review: passed -->
