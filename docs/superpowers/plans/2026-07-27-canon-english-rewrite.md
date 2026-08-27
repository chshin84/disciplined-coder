# 정본과 스킬 영문 재작성 구현 계획

> **되돌린 작업의 계획이다(superseded).** 이 재작성은 되돌려졌고 정본은 지금도 한국어다. 아래
> 태스크를 실행하지 마라 — 그대로 따라가면 사용자가 되돌리기로 정한 재작성을 다시 하게 된다.
> 바로 아래 "For agentic workers" 줄이 이 계획을 태스크 단위로 구현하라고 하지만, 그 지시는 이
> 표시로 효력을 잃는다. 설계는 `docs/superpowers/specs/2026-07-27-canon-english-rewrite-design.md`에
> 있고 같은 표시가 달려 있다.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 상시 로드되는 정본과 온디맨드 스킬을 영문으로 다시 써서 토큰 밀도와 지시 준수율을 높이되, 무엇이 사라졌는지 대응표로 드러나게 한다.

**Architecture:** 파일마다 "다시 쓰기 → 대응표 남기기 → 그 파일에 매달린 테스트 가드 고치기"를 한 묶음으로 처리한다. 각 태스크가 끝날 때 세 스위트가 `FAIL=0`이어야 하므로, **자기가 깨뜨린 가드는 자기 태스크 안에서 고친다.** 재작성 자체는 검증할 수 없으므로 대응표가 그 자리를 대신한다.

**Tech Stack:** 마크다운 문서, bash 테스트 스위트, `claude plugin validate`.

## Global Constraints

- 세 스위트 모두 `FAIL=0`이다 — `bash scripts/test_scaffold.sh`, `bash scripts/test_hooks.sh`, `bash scripts/test_codex_scaffold.sh`. 테스트 기대 개수를 코드에 박지 않는다.
- `claude plugin validate ./`가 통과해야 한다(version 경고 하나는 의도된 것이라 무시한다).
- **번역이 아니라 재작성이다.** 옮길 때마다 "이 문장이 필요한가"를 묻고, 겹친다고 확신하지 못하면 남긴다.
- **파일마다 대응표를 `docs/superpowers/rewrite-map/<원본파일명>.md`에 남긴다.** 형식은 아래 Task 1 Step 2에 있다.
- **한국어로 유지하는 것** — `README.md`, `docs/DESIGN-NOTES.md`, `docs/solved_problems.md`, 커맨드 다섯 개의 **본문**, `scripts/_scaffold_common.sh`의 solved 템플릿 머리말, 훅이 CLI에 띄우는 메시지, `CLAUDE.md`(레포 루트), `docs/superpowers/` 전체.
- **영문으로 바꾸는 것** — `agent-principles.md`, `domains-index.md`, 스킬 열 개의 frontmatter와 본문, 커맨드 다섯 개의 **frontmatter**.
- `CLEAR-COMM`의 문체 규범 블록은 **한국어로 남긴다** — 규칙 설명도 예시도. 그 자리에 이유를 한 줄로 밝힌다.
- 절차 절의 새 이름은 정확히 이 다섯이다 — `Verification Layer`, `Design Inputs`, `Solved Log`, `Document Hygiene`, `Parallel Orchestration`.
- 원칙 ID(`CLEAR-COMM`·`EXPLICIT`·`SSOT` 등)는 바꾸지 않는다. 다른 문서가 그 ID로 참조한다.
- **PC 전역 오답노트(`~/.claude/disciplined-coder/solved_problems.md`)는 어떤 태스크도 건드리지 않는다.** git 밖이라 복구 수단이 없다.

---

### Task 1: 정본을 영문으로 다시 쓰고 그에 매달린 가드를 고친다

**Files:**
- Modify: `agent-principles.md` (전면)
- Create: `docs/superpowers/rewrite-map/agent-principles.md`
- Modify: `scripts/test_scaffold.sh` (가드 여덟 + 새 가드)
- Modify: `scripts/test_codex_scaffold.sh` (가드 여섯)

**Interfaces:**
- Consumes: 없다. 첫 태스크다.
- Produces: 절차 절의 영문 이름 다섯(`Verification Layer`·`Design Inputs`·`Solved Log`·`Document Hygiene`·`Parallel Orchestration`)과, 정본에만 존재하는 유일 문자열(아래 Step 4에서 고른다). 뒤 태스크들이 이 이름으로 참조한다.

- [ ] **Step 1: 현재 정본을 통째로 읽고 구조를 파악한다**

Run: `cat agent-principles.md`

원칙 글로서리, 환경 관례, 공통 함정, 절차 다섯 절이라는 뼈대를 확인한다. 어느 문단이 어느 절에 속하는지 메모한다.

- [ ] **Step 2: 대응표 파일을 먼저 만든다**

`docs/superpowers/rewrite-map/agent-principles.md`를 아래 형식으로 만든다. **재작성 전에 원문 항목을 다 채워 넣고, 새 문서를 쓰면서 오른쪽 두 칸을 메운다.** 나중에 몰아서 쓰면 빈칸이 드러나지 않는다.

```markdown
# 대응표 — agent-principles.md

원문의 각 항목이 새 문서 어디로 갔는지, 지웠다면 왜 지웠는지 남긴다.
'지움' 항목과 빈칸이 사람이 검토할 대상이다.

| 원문 항목 | 새 문서 위치 | 처리와 근거 |
|---|---|---|
| `CLEAR-COMM` — 결론 먼저 | CLEAR-COMM | 옮김 |
| `SURGICAL` — 주변 코드 스타일을 따른다 | (없음) | **지움** — Opus 5 기본 프롬프트의 "Write code that reads like the surrounding code"와 겹친다 |
```

세 번째 칸의 값은 `옮김`, `합침`, `**지움**` 셋 중 하나이며 지움에는 반드시 근거를 붙인다.

- [ ] **Step 3: 정본을 영문으로 다시 쓴다**

지킬 것은 Global Constraints에 다 적혀 있다. 특히 셋을 놓치지 마라.

첫째, `CLEAR-COMM` 안에 **"사용자에게는 한국어로 답한다"**를 명시한다. 지금은 정본이 한국어라 암묵적으로 정해지던 것이 영문화로 사라진다.

둘째, `CLEAR-COMM`의 **문체 규범 블록은 한국어로 남긴다.** 규칙 설명 문장도 예시도 한국어다. 그 자리에 "이 블록이 한국어인 이유는 한국어 산문의 어미와 리듬을 판정하기 때문이다"는 취지를 한 줄로 밝힌다.

셋째, `Solved Log` 절에 오답노트 규약 셋을 반영하고 **옛 형식 서술을 지운다.** 지금 그 절에 "형식은 '증상/트리거 → 교훈(다음엔 이렇게)' — 서술이 아니라 처방이 앞에"가 있는데, 새 형식은 순서가 반대라 남기면 정본이 둘이 된다. 반영할 규약 셋은 이렇다.

- 프로젝트 고유 교훈인데 `docs/solved_problems.md`가 없으면 그때 만들어 적는다. 미리 만들지는 않는다.
- 해결법이 바뀌면 그 항목을 고쳐 쓴다. 새 문제는 아래에 추가한다. 바꾼 이유는 spec에 남긴다.
- 결정과 취향은 solved가 아니라 spec에 적는다. solved는 겪은 문제와 그 해결법만 담는다.

- [ ] **Step 4: 정본에만 있는 유일 문자열을 고른다**

`디시플린`을 쓰던 기존 가드가 왜 무력한지부터 확인한다.

Run: `grep -n '디시플린' scripts/_scaffold_common.sh`
Expected: solved 템플릿 머리말에 "일반화 가능한 항목은 디시플린(agent-principles.md)으로 재기술해 승격한다"가 나온다.

`scaffold.sh`가 첫 실행 stdout에 정본과 solved를 함께 덤프하므로, 정본이 통째로 빠져도 이 머리말이 `디시플린`을 물어 가드가 초록으로 통과한다. 그래서 **새 가드는 정본에만 있고 다른 주입물에는 없는 문자열을 써야 한다.**

새 정본의 H1 제목을 후보로 삼고, 고른 뒤 반드시 확인한다.

Run: `grep -rn '<고른문자열>' scripts/ commands/ skills/ | grep -v test_`
Expected: 출력이 없다. 나오면 다른 문자열을 고른다.

- [ ] **Step 5: 깨진 가드를 고친다**

아래 열넷이 정본 문자열에 매달려 있다. 추출 줄이 죽으면 그 아래 `check`도 함께 죽으므로 묶어서 고친다.

| 어디 | 무엇에 매달렸나 |
|---|---|
| `scripts/test_scaffold.sh:32` | 정본 `디시플린` (stdout) |
| `scripts/test_scaffold.sh:218` 추출 → `220`·`221`·`222` | 정본 `멀티에이전트 워크플로 작성·실행`과 `ultracode 검증 모드` |
| `scripts/test_scaffold.sh:274`·`276` | 정본 `디시플린` (stdout 존재·부재) |
| `scripts/test_scaffold.sh:286` | 정본 `디시플린` 부재 |
| `scripts/test_scaffold.sh:291` 추출 → `293`·`294`·`295` | 정본 `### 마.` |
| `scripts/test_codex_scaffold.sh:41`·`136` | 정본 `디시플린` (AGENTS.md) |
| `scripts/test_codex_scaffold.sh:42` | 정본 `디시플린` (stdout) |
| `scripts/test_codex_scaffold.sh:131`·`132` | 정본 `# 디시플린 (팀 원칙)` |

`디시플린`을 쓰던 자리는 Step 4에서 고른 유일 문자열로 바꾼다. `### 마.`을 쓰던 자리는 `### Parallel Orchestration`으로 바꾼다. 표 행을 찾던 자리는 새 영문 트리거 문자열로 바꾼다. **무엇을 지키는 계약인지는 바꾸지 않는다** — 검사 이름과 의도를 그대로 두고 찾는 문자열만 교체한다.

`scripts/test_scaffold.sh`의 `§마` 라벨 일곱 곳(주석 셋, `check` 라벨 셋, `echo` 라벨 하나)도 `Parallel Orchestration`으로 바꾼다. 사람이 읽는 로그에 찍히기 때문이다.

- [ ] **Step 6: 새 가드 다섯을 추가한다**

`scripts/test_scaffold.sh`의 `echo "----"` 줄 앞에 넣는다. 케이스 번호가 아니라 이름으로 부른다.

```bash
# --- canon-english: 영문 재작성이 지켜야 할 정본 계약 ---
CANON="$HERE/agent-principles.md"
echo "[canon-english] rewritten canon keeps its contracts"
check "canon: reply-in-Korean directive"   "grep -qF '한국어로 답한다' '$CANON'"
check "canon: style block stays Korean"    "grep -qF '~한다' '$CANON'"
check "canon: style rule prose in Korean"  "grep -qF '명사 조각' '$CANON'"
for s in "Verification Layer" "Design Inputs" "Solved Log" "Document Hygiene" "Parallel Orchestration"; do
  check "canon: section '$s' present"      "grep -qF '### $s' '$CANON'"
done
check "canon: no ordinal sections left"    "! grep -qE '^### [가나다라마]\.' '$CANON'"
check "canon: Korean confined to style blk" "[ \$(awk '/korean-style-rules: start/{s=1} /korean-style-rules: end/{s=0; next} !s' '$CANON' | grep -c '[가-힣]') -eq 0 ]"

# --- section-refs: 옛 절 참조가 남지 않았다 (git 추적 파일, 스펙 아카이브 제외) ---
echo "[section-refs] no dangling ordinal references"
STALE="$(cd "$HERE" && git ls-files -z | xargs -0 grep -l '§[가나다라마]\|절차 [가나다라마]' 2>/dev/null | grep -v '^docs/superpowers/' || true)"
check "refs: none dangling"                "[ -z \"\$STALE\" ]"
```

`canon: Korean confined to style blk`가 동작하려면 **Step 3에서 문체 규범 블록을 HTML 주석 마커로 감싸야 한다.** 정본에 이렇게 쓴다.

```markdown
<!-- korean-style-rules: start -->
(여기부터 한국어 문체 규범 — 규칙 설명도 예시도 한국어다.
 이 블록이 한국어인 이유는 한국어 산문의 어미와 리듬을 판정하는 규칙이기 때문이다.
 영어로 옮기면 규칙이 가리키는 대상이 사라진다. 다음에 재작성할 때 번역하지 마라.)
<!-- korean-style-rules: end -->
```

블록 마커는 이 검사가 한글의 소재를 특정하는 유일한 수단이다. 마커 없이 한글 개수만 세면 어디에 있든 통과하므로 계약이 성립하지 않는다.

`refs: none dangling`은 이 태스크 시점에는 스킬 본문이 아직 한국어라 FAIL한다. **이 검사만 Task 8까지 주석 처리해 두고, Task 8에서 되살린다.** 주석에 그 사실과 되살릴 태스크를 적는다.

- [ ] **Step 7: 뮤테이션으로 새 가드를 검증한다**

가드마다 대상을 되돌린 상태를 만들어 실제로 FAIL하는지 본 뒤 원복한다. 최소 이 셋은 반드시 한다.

정본에서 "한국어로 답한다" 줄을 지운다 → `canon: reply-in-Korean directive`가 FAIL해야 한다.
정본의 `### Parallel Orchestration`을 다른 이름으로 바꾼다 → 해당 검사가 FAIL해야 한다.
**`scripts/scaffold.sh`의 stdout 덤프 루프에서 `agent-principles.md`만 뺀다** → Step 5에서 고친 `stdout has principle marker`가 FAIL해야 한다. 이것이 vacuous 여부를 가리는 결정적 검증이다. 여기서 초록이 나오면 Step 4의 문자열 선택이 틀린 것이다.

정본의 문체 블록 **바깥**에 한국어 문장을 한 줄 넣는다 → `canon: Korean confined to style blk`가 FAIL해야 한다. 이것이 "한글 원본을 남기지 않는다"를 지키는 유일한 기계 검증이다.

각 뮤테이션의 명령과 FAIL 출력을 보고서에 남긴다.

- [ ] **Step 8: 세 스위트를 돌린다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2`
Expected: 세 줄 모두 `PASS=<n> FAIL=0`이다.

- [ ] **Step 9: 대응표의 빈칸을 확인한다**

Run: `grep -c '|' docs/superpowers/rewrite-map/agent-principles.md`

표의 모든 행에 세 번째 칸이 채워졌는지 눈으로 확인한다. 빈칸이 있으면 그 항목은 조용히 빠진 것이므로 되살리거나 근거를 적는다.

- [ ] **Step 10: 커밋한다**

```bash
git add agent-principles.md docs/superpowers/rewrite-map/agent-principles.md scripts/test_scaffold.sh scripts/test_codex_scaffold.sh
git commit -m "refactor(canon): 정본을 영문으로 다시 쓰고 절 이름을 붙인다"
```

---

### Task 2: `domains-index.md`를 다시 쓴다

**Files:**
- Modify: `domains-index.md`
- Create: `docs/superpowers/rewrite-map/domains-index.md`
- Modify: `scripts/test_codex_scaffold.sh:133`

**Interfaces:**
- Consumes: Task 1의 절 이름 다섯.
- Produces: `domains-index.md`의 새 영문 H1 제목. Task 2가 고치는 가드가 그것을 쓴다.

- [ ] **Step 1: 대응표를 만들고 다시 쓴다**

`docs/superpowers/rewrite-map/domains-index.md`를 Task 1 Step 2와 같은 형식으로 만든다. `domains-index.md`를 영문으로 다시 쓴다. 도메인 표의 참조 스킬 이름(`domain-docs` 등)은 파일명이므로 바꾸지 않는다.

- [ ] **Step 2: 깨진 가드를 고친다**

`scripts/test_codex_scaffold.sh:133`이 `개발 대상(도메인) 참고서`를 grep한다. 새 영문 제목으로 바꾼다.

Run: `grep -n '개발 대상' scripts/`
Expected: 출력이 없다.

- [ ] **Step 3: 세 스위트를 돌린다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2`
Expected: 세 줄 모두 `FAIL=0`이다.

- [ ] **Step 4: 커밋한다**

```bash
git add domains-index.md docs/superpowers/rewrite-map/domains-index.md scripts/test_codex_scaffold.sh
git commit -m "refactor(domains-index): 도메인 목차를 영문으로 다시 쓴다"
```

---

### Task 3: 리뷰어 렌즈 스킬 넷을 다시 쓴다

**Files:**
- Modify: `skills/reviewer-grounding/SKILL.md`, `skills/reviewer-consistency/SKILL.md`, `skills/reviewer-adversarial/SKILL.md`, `skills/reviewer-fit/SKILL.md`
- Create: `docs/superpowers/rewrite-map/reviewer-lenses.md` (넷을 한 표에)

**Interfaces:**
- Consumes: Task 1의 절 이름.
- Produces: 네 렌즈의 영문 출력 스키마. 이후 태스크의 `domain-spec-review`와 `meta-aggregate`가 그 스키마를 참조하므로 **필드 이름을 바꾸면 안 된다.**

- [ ] **Step 1: 네 파일의 JSON 스키마 필드를 먼저 적어 둔다**

Run: `grep -n 'severity\|"type"\|"where"\|"detail"\|lens' skills/reviewer-*/SKILL.md`

**이 필드 이름들은 바꾸지 않는다.** 서브에이전트가 이 스키마로 리턴하고 메인이 그 키로 읽는다. 영문화 대상은 설명 산문이지 스키마가 아니다.

- [ ] **Step 2: 대응표를 만들고 넷을 다시 쓴다**

frontmatter와 본문을 모두 영문으로 다시 쓴다. `description`은 어느 렌즈를 쓸지 고를 때 읽히므로 렌즈의 구분점이 드러나게 쓴다.

- [ ] **Step 3: 스키마가 안 바뀌었는지 확인한다**

Run: `grep -n 'severity\|"type"\|"where"\|"detail"' skills/reviewer-*/SKILL.md`
Expected: Step 1과 같은 필드 이름이 나온다.

- [ ] **Step 4: 세 스위트와 validate를 돌리고 커밋한다**

```bash
bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2
claude plugin validate ./
git add skills/reviewer-*/SKILL.md docs/superpowers/rewrite-map/reviewer-lenses.md
git commit -m "refactor(skills): 리뷰어 렌즈 넷을 영문으로 다시 쓴다"
```

---

### Task 4: `domain-plugin`·`meta-aggregate`·`domain-llm-runtime`을 다시 쓴다

**Files:**
- Modify: `skills/domain-plugin/SKILL.md`, `skills/meta-aggregate/SKILL.md`, `skills/domain-llm-runtime/SKILL.md`
- Create: `docs/superpowers/rewrite-map/domain-plugin-meta-llm.md`

**Interfaces:**
- Consumes: Task 1의 절 이름, Task 3의 렌즈 스키마 필드 이름.
- Produces: 없다.

- [ ] **Step 1: 대응표를 만들고 셋을 다시 쓴다**

`domain-llm-runtime`에 `절차 가` 참조가 하나 있다. `Verification Layer`로 바꾼다. `meta-aggregate`가 렌즈 출력을 읽으므로 Task 3의 필드 이름과 맞는지 확인한다.

- [ ] **Step 2: 세 스위트와 validate를 돌리고 커밋한다**

```bash
bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2
claude plugin validate ./
git add skills/domain-plugin/SKILL.md skills/meta-aggregate/SKILL.md skills/domain-llm-runtime/SKILL.md docs/superpowers/rewrite-map/domain-plugin-meta-llm.md
git commit -m "refactor(skills): domain-plugin·meta-aggregate·domain-llm-runtime을 영문으로 다시 쓴다"
```

---

### Task 5: `domain-spec-review`와 `nested-orchestration`을 다시 쓴다

**Files:**
- Modify: `skills/domain-spec-review/SKILL.md`, `skills/nested-orchestration/SKILL.md`
- Create: `docs/superpowers/rewrite-map/spec-review-nested.md`
- Modify: `scripts/test_scaffold.sh:304`·`305`

**Interfaces:**
- Consumes: Task 1의 절 이름, Task 3의 렌즈 스키마.
- Produces: `nested-orchestration` 본문의 새 영문 소제목. Task 5가 고치는 가드가 그것을 쓴다.

- [ ] **Step 1: 깨질 가드를 먼저 확인한다**

Run: `sed -n '300,308p' scripts/test_scaffold.sh`
Expected: `구간 소유권`과 `산출 계약`을 grep하는 `check` 둘이 보인다. 이 둘은 `skills/nested-orchestration/SKILL.md` 본문을 검사하므로 재작성으로 깨진다.

- [ ] **Step 2: 대응표를 만들고 둘을 다시 쓴다**

`nested-orchestration`에 `§마`·`§다`·`§가` 참조가 넷, `domain-spec-review`에 `절차 가` 참조가 하나 있다. 모두 새 이름으로 바꾼다.

**`구간 소유권`과 `산출 계약`에 해당하는 개념은 반드시 남긴다.** 테스트가 그 존재를 계약으로 지키고 있다. 영문 소제목을 정하고 다음 단계에서 가드를 그 이름으로 바꾼다.

- [ ] **Step 3: 깨진 가드를 고친다**

`scripts/test_scaffold.sh`의 두 `check`가 찾는 문자열을 Step 2에서 정한 영문 소제목으로 바꾼다. 검사 이름과 의도는 그대로 둔다.

- [ ] **Step 4: 뮤테이션으로 확인한다**

`skills/nested-orchestration/SKILL.md`에서 그 소제목 하나를 지운다 → 해당 `check`가 FAIL해야 한다. 확인 후 원복한다.

- [ ] **Step 5: 세 스위트와 validate를 돌리고 커밋한다**

```bash
bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2
claude plugin validate ./
git add skills/domain-spec-review/SKILL.md skills/nested-orchestration/SKILL.md docs/superpowers/rewrite-map/spec-review-nested.md scripts/test_scaffold.sh
git commit -m "refactor(skills): domain-spec-review·nested-orchestration을 영문으로 다시 쓴다"
```

---

### Task 6: `domain-docs`를 다시 쓴다

**Files:**
- Modify: `skills/domain-docs/SKILL.md`
- Create: `docs/superpowers/rewrite-map/domain-docs.md`

**Interfaces:**
- Consumes: Task 1의 절 이름.
- Produces: 없다.

- [ ] **Step 1: 대응표를 만들고 다시 쓴다**

가장 큰 스킬(6,179자)이라 대응표가 특히 중요하다. `§라`·`§다`·`§가` 참조가 넷 있으니 새 이름으로 바꾼다. 이 스킬은 문서 타입별 처방 표를 소유하므로 **표의 행이 하나도 빠지지 않았는지** 대응표로 확인한다.

- [ ] **Step 2: 세 스위트와 validate를 돌리고 커밋한다**

```bash
bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2
claude plugin validate ./
git add skills/domain-docs/SKILL.md docs/superpowers/rewrite-map/domain-docs.md
git commit -m "refactor(skills): domain-docs를 영문으로 다시 쓴다"
```

---

### Task 7: 커맨드 다섯 개의 frontmatter를 다시 쓴다

**Files:**
- Modify: `commands/setup-discipline.md`, `commands/show-principles.md`, `commands/show-solved.md`, `commands/issue-mode.md`, `commands/ultracode-review.md`
- Create: `docs/superpowers/rewrite-map/commands.md`

**Interfaces:**
- Consumes: 없다.
- Produces: 없다.

- [ ] **Step 1: frontmatter만 영문으로 바꾼다**

**본문은 한국어로 둔다.** 본문이 곧 사용자에게 보이는 출력을 규정하는 지시문이다. `description`만 영문으로 다시 쓴다.

- [ ] **Step 2: README 커맨드 절과의 일치를 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -i 'README commands'`
Expected: 해당 검사가 PASS다. 이 가드가 README와 `commands/` 디렉터리의 드리프트를 막는다.

- [ ] **Step 3: 세 스위트와 validate를 돌리고 커밋한다**

```bash
bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2
claude plugin validate ./
git add commands/ docs/superpowers/rewrite-map/commands.md
git commit -m "refactor(commands): 커맨드 frontmatter를 영문으로 다시 쓴다"
```

---

### Task 8: 남은 참조를 고치고 오답노트 형식을 옮긴다

**Files:**
- Modify: `README.md`, `docs/DESIGN-NOTES.md`, `docs/solved_problems.md`, `.claude/workflows/self-audit.js`, `CLAUDE.md`
- Modify: `scripts/_scaffold_common.sh` (solved 템플릿 머리말)
- Modify: `scripts/test_scaffold.sh` (Task 1 Step 6의 `refs: none dangling` 주석 해제)

**Interfaces:**
- Consumes: Task 1의 절 이름, 앞선 모든 재작성.
- Produces: 없다. 마지막 태스크다.

- [ ] **Step 1: 남은 참조를 전수 확인한다**

Run: `git ls-files -z | xargs -0 grep -n '§[가나다라마]\|절차 [가나다라마]' 2>/dev/null | grep -v '^docs/superpowers/'`

남은 곳을 모두 새 영문 이름으로 바꾼다. **`.claude/workflows/self-audit.js`는 범위 표현 `절차(§가~라)`를 쓰므로 단순 치환이 안 된다** — 네 절 이름을 나열하거나 표현을 바꾼다.

한국어로 남는 문서 안에서도 절 이름은 영문 그대로 쓴다(예: "Verification Layer 절"). 번역하면 이름이 두 벌이 된다.

- [ ] **Step 2: solved 템플릿 머리말을 새 형식으로 바꾼다**

`scripts/_scaffold_common.sh`의 solved 템플릿 머리말을 아래 규칙으로 바꾼다. **한국어를 유지한다.** 옛 형식 서술("증상/트리거 → 교훈 — 처방이 앞")은 지운다.

- 증상은 굵게 한 줄로 띄운다.
- 원인과 해결은 그 아래 들여쓰기로 내린다.
- 한 항목은 세 줄을 넘기지 않는다.
- 순서는 시간순이고 아래에 추가한다.
- 항목이 스무 개를 넘으면 그때 영역별로 묶는다.
- 안 쓰이는 항목도 지우지 않는다.

- [ ] **Step 3: `docs/solved_problems.md`의 기존 항목을 새 형식으로 옮긴다**

머리말을 Step 2와 맞추고, 기존 항목을 증상 굵게 한 줄 + 원인·해결 들여쓰기로 다시 배치한다. **내용을 요약하거나 줄이지 마라** — 형식만 바꾼다. 세 줄을 넘는 항목은 그대로 두되 그 사실을 커밋 메시지에 적는다.

**`~/.claude/disciplined-coder/solved_problems.md`는 건드리지 마라.** git 밖이라 복구 수단이 없다.

- [ ] **Step 4: 레포 루트 `CLAUDE.md`의 오답노트 재진술을 맞춘다**

그 파일의 오답노트 문단이 새 규약·형식과 어긋나지 않게 고친다. 한국어를 유지한다.

- [ ] **Step 5: `refs: none dangling` 가드를 되살린다**

Task 1 Step 6에서 주석 처리해 둔 검사를 되살린다. 이제 모든 참조가 고쳐졌으므로 통과해야 한다.

이 검사의 패턴 `§[가나다라마]`도 `canon: no ordinal sections left`와 같은 로케일 함정을 밟는다 — 대괄호
문자 집합이 기본 C 로케일에서는 바이트로 대조되어 한글을 문자 단위로 매치하지 못한다. 되살릴 때
`grep`이 아니라 `LC_ALL=C.UTF-8 grep`으로 실행해야 이 검사가 실제로 한글 잔여 참조를 잡아낸다.

- [ ] **Step 6: 세 스위트와 validate를 돌린다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -2 && bash scripts/test_hooks.sh 2>&1 | tail -2 && bash scripts/test_codex_scaffold.sh 2>&1 | tail -2 && claude plugin validate ./ 2>&1 | tail -2`
Expected: 세 스위트가 `FAIL=0`이고 validate가 통과한다.

- [ ] **Step 7: 커밋한다**

```bash
git add -A
git commit -m "refactor(refs): 절 참조를 새 이름으로 바꾸고 오답노트 형식을 옮긴다"
```

---

## 완료 기준

- 세 스위트가 모두 `FAIL=0`이고 `claude plugin validate ./`가 통과한다.
- `git ls-files`가 추적하는 파일 중 `docs/superpowers/` 밖에서 `§가`류와 `절차 가`류가 검색되지 않는다.
- `agent-principles.md`에 절차 절 영문 이름 다섯이 있고 `### 가.`류가 없다.
- `agent-principles.md`에 "한국어로 답한다" 지시가 있고, 문체 규범 블록이 `korean-style-rules` 마커로 감싸여 한국어로 남아 있으며, 그 블록 밖에는 한글이 없다.
- `docs/superpowers/rewrite-map/` 아래에 대응표가 파일별로 있고, 모든 행의 처리 칸이 채워져 있다.
- `~/.claude/disciplined-coder/solved_problems.md`가 이번 작업으로 바뀌지 않았다.

## 사람이 검토할 것

**대응표의 '지움' 항목과 빈칸이다.** 결과물 전체를 통독하지 않아도 무엇이 사라졌는지 그 표로 드러난다. 빈칸이 있으면 조용히 빠진 것이므로 되살리거나 근거를 채워야 한다.

<!-- spec-review: passed -->
