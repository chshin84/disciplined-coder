# 정본 분리와 domain-coding·domain-writing 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 정본 `agent-principles.md`를 대화 규칙만 남기고, 코딩 규칙은 새 스킬 `domain-coding`으로, 카파시의 문서용 규칙은 새 스킬 `domain-writing`으로 옮기며, 코드 파일의 세션 첫 편집 전에 훅이 `domain-coding`을 열라고 알리게 한다.

**Architecture:** 정본은 `@import`로 모든 세션에 실리므로 파일 없는 답 한 번으로 어길 수 있는 조항만 남긴다. 산출물이 있어야 어기는 규칙은 스킬로 가고, 스킬은 Claude의 판단으로만 열리므로 훅이 도구 호출이라는 사실로 열게 한다. 훅은 기존 문서 넛지와 같은 헬퍼 셋을 쓰고, 세션당 한 번만 알리기 위해 훅 입력의 `session_id`(과 `agent_id`)로 임시 폴더에 표시 파일을 둔다.

**Tech Stack:** bash(Git Bash on Windows), Claude Code 플러그인 훅(`hooks/hooks.json`), 레포의 테스트 스크립트 `scripts/test_*.sh`(계약은 FAIL=0).

**Spec:** `docs/superpowers/specs/2026-09-05-canon-split-design.md`

## Global Constraints

- 테스트 실행 명령은 레포 `CLAUDE.md`가 정본이다. 워크트리 격리는 반복문을 거부하므로 아래 스크립트 파일로 돌린다. 이 파일은 이미 스크래치패드에 있다. 없으면 같은 내용으로 만든다.
  ```bash
  # C:/Users/ho381/AppData/Local/Temp/claude/D--projects-disciplined-coder/e2daecd4-e61b-4103-8166-47fbcbcec685/scratchpad/run_tests.sh
  #!/usr/bin/env bash
  cd "$1" || exit 2
  bad=""
  for t in scripts/test_*.sh; do
    out="$(bash "$t" 2>&1)" || bad="$bad $t"
    printf '%s: %s\n' "$t" "$(printf '%s\n' "$out" | tail -1)"
    printf '%s\n' "$out" | grep 'FAIL:' || true
  done
  [ -z "$bad" ] && echo "ALL PASS" || echo "FAILED:$bad"
  claude plugin validate ./ 2>&1 | tail -2
  ```
  실행은 `bash <위 경로>/run_tests.sh "D:/projects/disciplined-coder/.claude/worktrees/canon-split"`이다. `claude plugin validate ./`는 `version` 경고 하나만 내면 정상이다.
- 작업 폴더는 워크트리 `D:/projects/disciplined-coder/.claude/worktrees/canon-split`(브랜치 `worktree-canon-split`)이다. 메인 체크아웃 `D:/projects/disciplined-coder`는 건드리지 않는다.
- 파일 편집은 여러 줄 치환이 많으므로 파이썬 스크립트를 스크래치패드에 파일로 쓰고 `python <파일>`로 돌린다. 파이썬을 `-c`나 heredoc에 넣지 않는다(셸 따옴표 함정). 파일은 `io.open(path, encoding="utf-8", newline="")`로 읽고 써서 줄바꿈을 보존한다. 치환 전 `assert s.count(old) == 1`로 정확히 한 곳인지 확인한다.
- 워크트리 안에서는 한 Bash 호출에 명령 하나만 보낸다. `a && b` 사슬은 통과한다. `for`·heredoc·`$((...))`·`sed -n`은 거부될 수 있다.
- 커밋 메시지는 스크래치패드에 파일로 쓰고 `git commit -q -F <파일>`로 넣는다. 메시지 끝에 두 줄을 붙인다.
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_016SAvMLKU1ACEXds7QDsiDy
  ```
- 커밋은 둘이다. Task 1~4가 커밋 A(정본·두 스킬·참조), Task 5~6이 커밋 B(훅·테스트·README 훅 절)다. 되돌릴 때는 B를 먼저 되돌린다. A만 되돌리면 훅이 없는 스킬을 가리킨다.
- `docs/superpowers/` 아래 옛 spec·plan·리뷰 기록은 손대지 않는다. `docs/superpowers/reviews/`는 세션 시작에 읽기 전용으로 봉인되므로 Write나 Edit이 거부되면 봉인이다.
- 파일 이름에 `coding`을 넣지 않는다. `scripts/test_docs_drift.sh`가 제거된 기능의 어간 `coding`으로 `docs/superpowers/{specs,plans}` 아래 문서를 훑어 superseded 표시를 요구한다.
- 옛 조항 ID 열(`ASK-FORK`·`MEASURE-FIRST`·`SIMPLE`·`SURGICAL`·`TDD`·`EXPLAIN-STRUCTURE`·`EXPLICIT`·`FOCUSED`·`IDEMPOTENT`·`SSOT`)을 살아 있는 문서(`skills/`·`README.md`·`CLAUDE.md`·`scripts/scaffold.sh`)에 백틱으로 감싸 적지 않는다. `SSOT`라는 낱말을 개념 이름으로 백틱 없이 쓰는 것은 된다.

---

### Task 1: 정본을 대화 규칙만 남기게 줄인다

**Files:**
- Modify: `agent-principles.md`
- Test: `scripts/test_scaffold.sh` (canon-sections 블록과 karpathy-in-canon 블록)

**Interfaces:**
- Consumes: 없음.
- Produces: 정본의 절 여섯 `## 원칙`·`## Think Before Acting`·`## 검증`·`## 미해결의 처분`·`## 병렬 오케스트레이션`·`## 이 파일의 취급`. 뒤 태스크의 두 스킬이 이 정본을 "conversation rules live in the canon"으로 가리킨다.

- [ ] **Step 1: 테스트를 먼저 고친다**

`scripts/test_scaffold.sh`에서 두 곳을 바꾼다. 아래 파이썬을 스크래치패드에 `edit_t1_test.py`로 쓰고 돌린다.

```python
import io
p = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/scripts/test_scaffold.sh"
s = io.open(p, encoding="utf-8", newline="").read()
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:60]
    s = s.replace(old, new)

rep('for s in "원칙" "Karpathy 지침" "검증" "미해결의 처분" "병렬 오케스트레이션" "문서와 상태의 위생"; do',
    'for s in "원칙" "검증" "미해결의 처분" "병렬 오케스트레이션" "이 파일의 취급"; do')

old_block_start = "# --- karpathy-in-canon:"
old_block_end = 'check "live docs: no reference to $id"      "! grep -rqF \'\\`$id\\`\' \'$HERE/skills\' \'$HERE/README.md\' \'$HERE/scripts/scaffold.sh\'"\ndone\n'
i = s.index(old_block_start); j = s.index(old_block_end, i) + len(old_block_end)
new_block = '''# --- karpathy-split: 정본에는 대화 규칙만 남고, 코드 규칙은 domain-coding, 문서 규칙은 domain-writing에 있다 ---
# 기준은 "파일을 하나도 건드리지 않은 답 한 번으로도 어길 수 있으면 정본에 남는다"이다. 산출물이 있어야만
# 어기는 규칙은 스킬로 갔고, 스킬은 훅이 열게 한다(코드 넛지는 test_hooks.sh가 본다).
echo "[karpathy-split] conversation rules stay in the canon; code and document rules live in skills"
# 제목 검사는 줄 전체를 앵커로 잡는다. `grep -F '## Think Before Acting'` 은 `### Think Before Acting` 을
# 부분 문자열로 맞혀 절이 안 올라가도 초록이 된다.
check "canon: Think Before Acting is a top-level section" "grep -qE '^## Think Before Acting$' '$CANON'"
check "canon: Think Before Acting is not a subsection"    "! grep -qE '^### Think Before Acting$' '$CANON'"
check "canon: no Tradeoff line"                      "! grep -qF '**Tradeoff:**' '$CANON'"
for h in "Simplicity First" "Surgical Changes" "Goal-Driven Execution"; do
  check "canon: no '$h' section"                     "! grep -qF '### $h' '$CANON'"
done
check "canon: subagent fleet rule stays"             "grep -qF \\"Don't launch a fleet of subagents for what one call can do\\" '$CANON'"
check "canon: fact-vs-judgment paragraph stays"      "grep -qF '사실과 판단은 다르다' '$CANON'"
check "canon: hygiene section gone"                  "! grep -qF '## 문서와 상태의 위생' '$CANON'"
check "canon: local-first convention gone"           "! grep -qF 'LOCAL-FIRST' '$CANON'"
for id in FAIL-LOUD KO-SYNTAX NAME-ITEMS PLAIN-KO PROSE-FORM READ-FLOW REVERSIBLE SECRETS; do
  check "canon: clause $id stays"                    "grep -qF '**\\`$id\\`' '$CANON'"
done
# 먼저 뺀 다섯은 살아 있는 문서 가드를 이미 통과한다 — Task 1 이 그 가드를 잠시라도 걷어내지 않도록 여기 둔다.
for id in ASK-FORK MEASURE-FIRST SIMPLE SURGICAL TDD; do
  check "canon: old clause $id removed"              "! grep -qF '**\\`$id\\`' '$CANON'"
  check "live docs: no reference to $id"             "! grep -rqF '\\`$id\\`' '$HERE/skills' '$HERE/README.md' '$HERE/scripts/scaffold.sh'"
done
# 이번에 빼는 다섯은 살아 있는 문서에 아직 남아 있다. 그 가드는 Task 4 가 참조를 고친 뒤에 붙인다.
for id in EXPLAIN-STRUCTURE EXPLICIT FOCUSED IDEMPOTENT SSOT; do
  check "canon: old clause $id removed"              "! grep -qF '**\\`$id\\`' '$CANON'"
done
'''
s = s[:i] + new_block + s[j:]
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

- [ ] **Step 2: 테스트가 빨간지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep 'FAIL:'`
Expected: FAIL이 열넷이다. `canon: Think Before Acting is a top-level section`, `canon: Think Before Acting is not a subsection`, `canon: no Tradeoff line`, `canon: no '...' section` 셋, `canon: subagent fleet rule stays`, `canon: hygiene section gone`, `canon: local-first convention gone`, `canon: old clause ...` 다섯이다. `canon: section '이 파일의 취급' present`와 `canon: fact-vs-judgment paragraph stays`는 지금도 초록이다.

- [ ] **Step 3: 정본을 고친다**

아래 파이썬을 `edit_t1_canon.py`로 쓰고 돌린다. 지우는 다섯 조항과 LOCAL-FIRST 문단과 「문서와 상태의 위생」 절은 그대로 지우고, 「Karpathy 지침」 블록은 Think Before Acting 절로 바꾸며, 「검증」 끝에 한 문단을 옮긴다.

```python
import io
p = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/agent-principles.md"
s = io.open(p, encoding="utf-8", newline="").read()
def rep(old, new):
    global s
    assert s.count(old) == 1, old[:60]
    s = s.replace(old, new)

# 1) 조항 다섯을 지운다 (줄 전체)
for line in [
  "- **`EXPLAIN-STRUCTURE` (구조 설명)** — 코드를 바꾸면 구조의 변화를 설명한다. 바뀐 줄이 아니라 무엇이 무엇을 부르게 되었고 무엇에 의존하게 되었는지를 적는다.\n",
  "- **`EXPLICIT` (명시성)** — 코드는 이름과 타입과 계약만으로 동작이 드러나야 하고, 에이전트에 넘기는 맥락은 상대가 알 것이라 가정하지 말고 프롬프트에 직접 적는다.\n",
  "- **`FOCUSED` (한 가지 일)** — 한 작업(함수, 파일, 스킬, 서브에이전트와 같이 하나의 업무 단위)은 한 가지 일만 한다. 다른 작업은 내부를 몰라도 입력과 출력만 알면 쓸 수 있게 만든다.\n",
  "- **`IDEMPOTENT` (멱등성)** — 스크립트와 셋업은 여러 번 실행해도 같은 결과를 내도록 한다. 이미 완료된 것은 건너뛰어, 두 번 돌려도 중복이나 손상이 생기지 않는다.\n",
  "- **`SSOT` (단일 출처)** — 하나의 사실은 한 곳에만 둔다. 다른 데서 필요하면 복제하지 말고 그곳을 참조하거나 거기서 도출한다.\n",
]:
    rep(line, "")

# 2) LOCAL-FIRST 관례 문단을 지운다
rep("`LOCAL-FIRST`는 원칙이 아니라 이 환경의 관례다. 기본은 이 PC에서 바로 돌리는 것이다. 도커는 운영 환경과 같은 조건이 필요할 때, 데이터베이스처럼 따로 띄워야 하는 서비스가 있을 때, 이 PC에 깔기 어려운 것이 필요할 때, 사용자가 지시했을 때에만 쓴다.\n\n", "")

# 3) Karpathy 지침 블록(겉 제목~Goal-Driven 끝)을 Think Before Acting 절로 바꾼다
i = s.index("## Karpathy 지침\n")
j = s.index("## 검증\n")
think = '''## Think Before Acting

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing, writing, or deciding:
- Don't assume the current state. Measure it in the actual code, data, and environment. If measuring doesn't settle it, ask whether to proceed.
- State your assumptions explicitly. If uncertain, ask - as a question with options, never in plain prose.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted. Don't launch a fleet of subagents for what one call can do.
- If something is unclear, stop. Name what's confusing. Ask.

'''
s = s[:i] + think + s[j:]

# 4) 「문서와 상태의 위생」 절을 지우고 둘째 문단은 「검증」 끝으로 옮긴다
hyg_start = s.index("## 문서와 상태의 위생\n")
hyg_end = s.index("## 이 파일의 취급\n")
s = s[:hyg_start] + s[hyg_end:]
rep("서브에이전트에 이 문서가 실린다고 가정하지 않는다.\n",
    '서브에이전트에 이 문서가 실린다고 가정하지 않는다.\n\n사실과 판단은 다르다. 훅은 계산으로 확인되는 사실만 기록한다. "완료"는 성공 기준에 비춰 내리는 판단이므로 근거와 함께 사용자에게 알린다.\n')

io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

돌린 뒤 `grep -n '^## ' agent-principles.md`로 절이 `원칙`·`Think Before Acting`·`검증`·`미해결의 처분`·`병렬 오케스트레이션`·`이 파일의 취급` 여섯인지 본다.

- [ ] **Step 4: 테스트가 초록인지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -1`
Expected: `PASS=<n> FAIL=0`. 다른 스크립트는 Task 4 끝에 한꺼번에 돌린다.

- [ ] **Step 5: 커밋하지 않는다**

커밋 A는 Task 4 끝에서 한다.

---

### Task 2: domain-coding 스킬을 만든다

**Files:**
- Create: `skills/domain-coding/SKILL.md`
- Test: `scripts/test_scaffold.sh` (karpathy-split 블록 뒤)

**Interfaces:**
- Consumes: Task 1의 정본. 본문 첫 문단이 "Rules that also hold in plain conversation live in the always-loaded canon"으로 정본을 가리킨다.
- Produces: 절 이름 여덟. 카파시 셋 `Simplicity First`·`Surgical Changes`·`Goal-Driven Execution`과 원칙 다섯 `Do one thing well`·`Single source of truth`·`Idempotence`·`Explicit is better than implicit`·`Describe the change, not the diff`이다. Task 4의 참조가 이 이름을 부르며, 그때 어느 스킬의 절인지 앞에 붙인다. `## Reach` 절이 `domain-docs`의 「렌즈에게 정본을 알리는 법」을 가리킨다.

- [ ] **Step 1: 테스트를 먼저 더한다**

`edit_t2_test.py`로 karpathy-split 블록 끝(마지막 `done` 뒤)에 붙인다.

```python
import io
p = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/scripts/test_scaffold.sh"
s = io.open(p, encoding="utf-8", newline="").read()
anchor = '''  check "canon: old clause $id removed"              "! grep -qF '**\\`$id\\`' '$CANON'"
done
'''
assert s.count(anchor) == 1
add = anchor + '''
DC="$HERE/skills/domain-coding/SKILL.md"
echo "[domain-coding] code rules live in one English skill"
check "domain-coding exists"                          "[ -f '$DC' ]"
for h in "Simplicity First" "Surgical Changes" "Goal-Driven Execution" "Do one thing well" "Single source of truth" "Idempotence" "Explicit is better than implicit" "Describe the change, not the diff"; do
  check "domain-coding: section '$h'"                 "grep -qF '### $h' '$DC'"
done
for h in "Karpathy guidelines" "Principles" "Local first" "Reach"; do
  check "domain-coding: section '$h'"                 "grep -qF '## $h' '$DC'"
done
check "domain-coding: Tradeoff line"                  "grep -qF '**Tradeoff:**' '$DC'"
check "domain-coding: never claim done"               "grep -qF 'Never claim \\"done\\" without execution evidence' '$DC'"
check "domain-coding: frontmatter name"               "grep -qF 'name: domain-coding' '$DC'"
'''
s = s.replace(anchor, add)
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

- [ ] **Step 2: 빨간지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -c 'domain-coding'`
Expected: FAIL 줄이 있다(파일이 없으므로 `domain-coding exists`부터 전부 FAIL).

- [ ] **Step 3: 스킬 파일을 쓴다**

Write 도구로 `skills/domain-coding/SKILL.md`를 아래 내용 그대로 만든다. 코드 블록 안의 ``` 세 개는 그대로 파일에 들어간다.

````markdown
---
name: domain-coding
description: 코드를 쓰거나 고칠 때의 규칙이다. 카파시(Andrej Karpathy) 코딩 지침의 코드용 세 절과, 정본에서 옮겨 온 다섯 원칙(한 가지 일·단일 출처·멱등성·명시성·변경 설명)과 로컬 우선 관례를 담는다. 문서가 아닌 프로젝트 안 파일에 세션의 첫 Write나 Edit이 들어오면 편집 전에 훅이 이 스킬을 열라고 알린다. 코드를 구현하는 서브에이전트에도 이 파일 경로를 넘긴다.
---
# domain-coding — rules for writing and changing code

These rules apply whenever code is written or changed. Rules that also hold in plain conversation live in the always-loaded canon and are not repeated here.

## Karpathy guidelines

From `andrej-karpathy-skills` 1.0.0. Think Before Coding lives in the canon as Think Before Acting.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification. Never claim "done" without execution evidence.

## Principles

### Do one thing well

"Write programs that do one thing and do it well. Write programs to work together." — Doug McIlroy, Bell System Technical Journal, 1978. "Gather together the things that change for the same reasons. Separate those things that change for different reasons." — Robert C. Martin, *The Single Responsibility Principle*.

A function, a file, a skill, or a subagent does one job. Anything else uses it through its inputs and outputs without reading its internals.

### Single source of truth

"Every piece of knowledge must have a single, unambiguous, authoritative representation within a system." — Andy Hunt and Dave Thomas, *The Pragmatic Programmer* (the DRY principle).

A fact lives in one place. Elsewhere, reference it or derive it. Never copy it.

### Idempotence

"An operation is idempotent if the result of performing it once is exactly the same as the result of performing it repeatedly without any intervening actions." — Ansible glossary.

Scripts and setup check the current state and act only on the difference, so a second run creates no duplicate and no damage.

### Explicit is better than implicit

"Explicit is better than implicit." — Tim Peters, PEP 20, *The Zen of Python*. "Make illegal states unrepresentable." — Yaron Minsky.

Behavior must be visible from names, types, and contracts alone. Context handed to an agent is written into its prompt, never assumed known.

### Describe the change, not the diff

"The rest of the description should fill in the details and include any supplemental information a reader needs to understand the changelist holistically." — Google Engineering Practices, *Writing good CL descriptions*. "Once the problem is established, describe what you are actually doing about it in technical detail." — Linux kernel, *Submitting patches*.

After changing code, report the change in structure: what now calls what, and what now depends on what. The diff already shows the lines.

## Local first

A convention of this environment, not a principle. Run on this machine by default. Use Docker only when production parity is required, when a service must run separately (a database, for example), when something cannot be installed here, or when the user says so.

## Reach

Subagents do not receive this file automatically. When a subagent implements code, put this file's path in its prompt the way `domain-docs`'s 「렌즈에게 정본을 알리는 법」 prescribes for the canon.
````

- [ ] **Step 4: 초록인지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -1`
Expected: `FAIL=0`.

---

### Task 3: domain-writing 스킬을 만든다

**Files:**
- Create: `skills/domain-writing/SKILL.md`
- Test: `scripts/test_scaffold.sh` (domain-coding 블록 뒤)

**Interfaces:**
- Consumes: 없음.
- Produces: 절 `## Simplicity First`·`## Surgical Changes`·`## Goal-Driven Execution`·`## Reach`. Task 4의 참조와 Task 6의 훅 문장이 스킬 이름 `domain-writing`을 부른다. 절 이름은 훅 문장에 넣지 않는다.

- [ ] **Step 1: 테스트를 먼저 더한다**

`edit_t3_test.py`:

```python
import io
p = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/scripts/test_scaffold.sh"
s = io.open(p, encoding="utf-8", newline="").read()
anchor = '''check "domain-coding: frontmatter name"               "grep -qF 'name: domain-coding' '$DC'"
'''
assert s.count(anchor) == 1
add = anchor + '''
DW="$HERE/skills/domain-writing/SKILL.md"
echo "[domain-writing] document-side karpathy rules live in one short English skill"
check "domain-writing exists"                         "[ -f '$DW' ]"
for h in "Simplicity First" "Surgical Changes" "Goal-Driven Execution" "Reach"; do
  check "domain-writing: section '$h'"                "grep -qF '## $h' '$DW'"
done
check "domain-writing: frontmatter name"              "grep -qF 'name: domain-writing' '$DW'"
'''
s = s.replace(anchor, add)
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

- [ ] **Step 2: 빨간지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep -c 'domain-writing'`
Expected: FAIL 줄이 있다.

- [ ] **Step 3: 스킬 파일을 쓴다**

Write 도구로 `skills/domain-writing/SKILL.md`를 아래 내용 그대로 만든다.

```markdown
---
name: domain-writing
description: 문서를 새로 쓰거나 고칠 때 분량과 수정 범위와 완료 판정의 규칙이다. 카파시(Andrej Karpathy) 코딩 지침 세 절을 문서용으로 고친 것이다. 프로젝트 안의 .md를 만들거나 고치면 훅이 이 스킬을 열라고 알린다. 훅이 건너뛰는 spec·plan과 리뷰 기록과 프로젝트 밖 문서에서는 이 설명문으로 연다. 문서의 타입과 수명과 검진은 domain-docs가, 한국어 문장 규칙은 writing-korean이 소유한다.
---
# domain-writing — how much to write, how much to touch, when it is done

Adapted from `andrej-karpathy-skills` 1.0.0. The code wording lives in `domain-coding`; Think Before Acting lives in the canon.

## Simplicity First

The minimum document that solves the problem. Nothing speculative.
- No sections beyond what was asked.
- No templates or generalizations for a single-use document.
- No "flexibility" the reader did not ask for.
- If you write 200 lines and it could be 50, rewrite it.

## Surgical Changes

Touch only what the request needs. Clean up only your own mess.
- Don't "improve" adjacent paragraphs, wording, or formatting.
- Match the existing style, even if you'd write it differently.
- Remove sections and links that your change orphaned.
- Leave pre-existing dead text in place and mention it.

## Goal-Driven Execution

Define what the reader must be able to do after reading. Check the draft against that before calling the document done.

## Reach

Subagents do not receive this file automatically. When a subagent writes or edits a document, put this file's path in its prompt the way `domain-docs`'s 「렌즈에게 정본을 알리는 법」 prescribes for the canon.
```

- [ ] **Step 4: 초록인지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | tail -1`
Expected: `FAIL=0`.

---

### Task 4: 살아 있는 문서의 참조를 새 이름으로 바꾸고 커밋 A를 만든다

**Files:**
- Modify: `skills/domain-docs/SKILL.md`, `skills/domain-plugin/SKILL.md`, `skills/domain-spec-review/SKILL.md`, `skills/nested-orchestration/SKILL.md`, `CLAUDE.md`, `README.md`(40행·51행), `scripts/scaffold.sh`(주석 한 줄)
- Test: `scripts/test_scaffold.sh`(옛 ID 가드), `scripts/test_docs_drift.sh`(Reach 포인터)

**Interfaces:**
- Consumes: Task 2·3의 절 이름과 스킬 이름.
- Produces: 살아 있는 문서에 백틱 옛 ID가 없는 상태. Task 5·6은 이 상태 위에서 훅만 더한다.

- [ ] **Step 1: 테스트를 먼저 더한다**

`edit_t4_test.py`로 두 테스트 파일에 검사를 더한다.

```python
import io
R = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/"
# (a) test_scaffold: 두 루프를 하나로 합치고, 옛 ID 열 전부에 살아 있는 문서 가드를 건다
p = R + "scripts/test_scaffold.sh"
s = io.open(p, encoding="utf-8", newline="").read()
old = '''# 먼저 뺀 다섯은 살아 있는 문서 가드를 이미 통과한다 — Task 1 이 그 가드를 잠시라도 걷어내지 않도록 여기 둔다.
for id in ASK-FORK MEASURE-FIRST SIMPLE SURGICAL TDD; do
  check "canon: old clause $id removed"              "! grep -qF '**\\`$id\\`' '$CANON'"
  check "live docs: no reference to $id"             "! grep -rqF '\\`$id\\`' '$HERE/skills' '$HERE/README.md' '$HERE/scripts/scaffold.sh'"
done
# 이번에 빼는 다섯은 살아 있는 문서에 아직 남아 있다. 그 가드는 Task 4 가 참조를 고친 뒤에 붙인다.
for id in EXPLAIN-STRUCTURE EXPLICIT FOCUSED IDEMPOTENT SSOT; do
  check "canon: old clause $id removed"              "! grep -qF '**\\`$id\\`' '$CANON'"
done
'''
new = '''# 조항 이름은 정본에서도 살아 있는 문서에서도 되살아나면 안 된다. CLAUDE.md 도 함께 본다.
for id in ASK-FORK MEASURE-FIRST SIMPLE SURGICAL TDD EXPLAIN-STRUCTURE EXPLICIT FOCUSED IDEMPOTENT SSOT; do
  check "canon: old clause $id removed"              "! grep -qF '**\\`$id\\`' '$CANON'"
  check "live docs: no reference to $id"             "! grep -rqF '\\`$id\\`' '$HERE/skills' '$HERE/README.md' '$HERE/CLAUDE.md' '$HERE/scripts/scaffold.sh'"
done
'''
assert s.count(old) == 1
s = s.replace(old, new)
io.open(p, "w", encoding="utf-8", newline="").write(s)

# (b) test_docs_drift: 두 스킬의 Reach 절도 소유자를 가리키기만 한다
p = R + "scripts/test_docs_drift.sh"
s = io.open(p, encoding="utf-8", newline="").read()
old = 'for D in "$HERE"/skills/domain-spec-review/SKILL.md "$HERE"/skills/nested-orchestration/SKILL.md; do'
assert s.count(old) == 1
s = s.replace(old, 'for D in "$HERE"/skills/domain-spec-review/SKILL.md "$HERE"/skills/nested-orchestration/SKILL.md "$HERE"/skills/domain-coding/SKILL.md "$HERE"/skills/domain-writing/SKILL.md; do')
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

- [ ] **Step 2: 빨간지 확인한다**

Run: `bash scripts/test_scaffold.sh 2>&1 | grep 'FAIL:'`
Expected: `live docs: no reference to EXPLICIT`·`FOCUSED`·`SSOT` 셋이 FAIL이다. domain-docs 21·29·63행과 CLAUDE.md 11행에 백틱 ID가 남아 있기 때문이다.

Run: `bash scripts/test_docs_drift.sh 2>&1 | grep 'FAIL:'`
Expected: `domain-writing 을 정본이나 다른 스킬이 부른다` 하나가 FAIL이다. 그 가드는 스킬 이름이 정본이나 다른 스킬의 `SKILL.md`에 한 번은 나오는지를 보는데, `domain-writing`이라는 글자는 아직 `docs/superpowers/` 밖 어디에도 없다. Step 3이 `domain-docs`와 `nested-orchestration`에 그 이름을 넣으면 초록이 된다. `domain-coding`은 `domain-writing` 본문이 이미 부르므로 여기서 FAIL이 아니다.

- [ ] **Step 3: 참조를 고친다**

`edit_t4_refs.py`:

파일 일곱을 한 번에 고친다. 치환을 먼저 전부 메모리에서 끝내고 마지막에 몰아 쓴다. 파일마다 그 자리에서 쓰면 뒤쪽에서 멈췄을 때 앞쪽만 바뀐 채 남고, 다시 돌리면 앞쪽의 `assert`가 0을 세어 또 멈춘다.

```python
import io
R = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/"
staged = []
def rw(path, pairs):
    s = io.open(R+path, encoding="utf-8", newline="").read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, old[:50])
        s = s.replace(old, new)
    staged.append((path, s))

rw("skills/domain-docs/SKILL.md", [
  ("핵심만 요약한 뒤 출처를 링크한다(`SSOT`).", "핵심만 요약한 뒤 출처를 링크한다(`domain-coding`의 Single source of truth)."),
  ("보편 원칙(Simplicity First·`SSOT`·`FOCUSED`·`READ-FLOW`)은 이름으로 참조하고", "보편 원칙(`domain-writing`의 Simplicity First, `domain-coding`의 Single source of truth와 Do one thing well, `READ-FLOW`)은 이름으로 참조하고"),
  ("프로젝트가 실제로 필요로 할 때만 넣는다(Simplicity First).", "프로젝트가 실제로 필요로 할 때만 넣는다(`domain-writing`의 Simplicity First)."),
  ("`agent-principles.md`의 「문서와 상태의 위생」 절의 상세는 여기가 소유한다.", "문서의 상태 위생은 여기가 소유한다."),
  ("문서가 자기 수정 규율을 선언하면(`EXPLICIT`)", "문서가 자기 수정 규율을 선언하면(`domain-coding`의 Explicit is better than implicit)"),
  ("기존 SSOT에 귀속될 수 있는지 먼저 본다(Simplicity First).", "기존 SSOT에 귀속될 수 있는지 먼저 본다(`domain-writing`의 Simplicity First)."),
])
rw("skills/domain-plugin/SKILL.md", [
  ("안 돌아 본 코드에는 오류가 숨는다(Simplicity First).", "안 돌아 본 코드에는 오류가 숨는다(`domain-coding`의 Simplicity First)."),
])
rw("skills/domain-spec-review/SKILL.md", [
  ("고칠 때는 지적된 곳만 손댄다(Surgical Changes).", "고칠 때는 지적된 곳만 손댄다(`domain-writing`의 Surgical Changes)."),
])
rw("skills/nested-orchestration/SKILL.md", [
  ("렌즈를 띄우기 전에 `domain-docs`의 「렌즈에게 정본을 알리는 법」을 읽는다.", "렌즈를 띄우기 전에 `domain-docs`의 「렌즈에게 정본을 알리는 법」을 읽는다. 구현자 프롬프트에는 `domain-coding`의 경로를, 문서를 쓰는 서브에이전트에는 `domain-writing`의 경로를 넣는다."),
])
rw("CLAUDE.md", [
  ("기대 개수를 숫자로 박지 않는다(`SSOT`).", "기대 개수를 숫자로 박지 않는다(Single source of truth)."),
])
rw("README.md", [
  ("새로 생기는 파일은 없다. 원칙은 `agent-principles.md` 한 곳에 둔다. ", "새로 생기는 파일은 없다. 원칙은 `agent-principles.md` 한 곳에 둔다. 그 정본에는 파일 없는 답 한 번으로도 어길 수 있는 대화 규칙만 있고, 코딩 규칙은 `skills/domain-coding/SKILL.md`에, 문서의 분량과 수정 범위 규칙은 `skills/domain-writing/SKILL.md`에 있다. "),
  ("정본의 「Karpathy 지침」 절은 그 플러그인의 네 절을 영어 그대로 옮기되 코드 밖의 문서와 절차에도 걸리게 낱말을 고친 것이고, 겹치던 조항은 정본에서 뺐다.", "정본의 「Think Before Acting」 절과 `domain-coding`·`domain-writing`의 카파시 절은 그 플러그인의 네 절을 옮긴 것이고, 겹치던 조항은 정본에서 뺐다."),
])
rw("scripts/scaffold.sh", [
  ("#     정본의 Karpathy 지침 절은 이 플러그인의 네 절을 옮긴 것이다.", "#     정본의 Think Before Acting 절과 domain-coding·domain-writing 의 카파시 절은 이 플러그인의 네 절을 옮긴 것이다."),
])

for path, text in staged:
    io.open(R+path, "w", encoding="utf-8", newline="").write(text)
    print("edited", path)
```

- [ ] **Step 4: 전체 테스트와 검증을 돌린다**

먼저 새 스킬 둘을 git 인덱스에 등록한다. `scripts/test_docs_drift.sh`의 금지 표현 검사는 대상을 `git ls-files '*.md'`로 뽑으므로, 미추적 파일은 한 번도 훑지 않은 채 "ALL PASS"가 난다.

Run: `git add -N skills/domain-coding/SKILL.md skills/domain-writing/SKILL.md`

Run: `bash <스크래치패드>/run_tests.sh "D:/projects/disciplined-coder/.claude/worktrees/canon-split"`
Expected: 다섯 스크립트 모두 `FAIL=0`, `ALL PASS`, validate는 version 경고 하나. 금지 표현 검사가 새 두 스킬을 훑고도 초록이어야 한다. 걸리면 그 낱말을 `skills/writing-korean/SKILL.md`의 목록에서 확인해 설명문을 고친다.

- [ ] **Step 5: 커밋 A**

스크래치패드에 `commit_a.txt`:

```
정본을 대화 규칙만 남기고 코딩 규칙과 문서 규칙을 두 스킬로 옮긴다

기준은 파일 없는 답 한 번으로 어길 수 있으면 정본에 남는다는 것이다. 다섯 조항
EXPLAIN-STRUCTURE·EXPLICIT·FOCUSED·IDEMPOTENT·SSOT와 카파시 세 절과 LOCAL-FIRST 관례는
새 스킬 domain-coding이 영어로 갖는다. 옮긴 다섯은 번역하지 않고 널리 쓰이는 영어 정식
표현을 출처와 함께 썼다. 카파시의 문서용 문장 세 절은 새 스킬 domain-writing이 갖는다.
정본에는 Think Before Acting과 조항 여덟과 절차 절 셋이 남는다. 살아 있는 문서의 참조는
새 절 이름으로 바꿨고, 옛 ID 열이 정본과 살아 있는 문서에 되살아나면 테스트가 잡는다.
설계: docs/superpowers/specs/2026-09-05-canon-split-design.md

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_016SAvMLKU1ACEXds7QDsiDy
```

Run: `git add agent-principles.md skills/domain-coding/SKILL.md skills/domain-writing/SKILL.md skills/domain-docs/SKILL.md skills/domain-plugin/SKILL.md skills/domain-spec-review/SKILL.md skills/nested-orchestration/SKILL.md CLAUDE.md README.md scripts/scaffold.sh scripts/test_scaffold.sh scripts/test_docs_drift.sh && git commit -q -F <스크래치패드>/commit_a.txt && git log --oneline -1`

---

### Task 5: 코드 넛지 훅을 만든다

**Files:**
- Create: `hooks/code_nudge_pretooluse.sh`, `hooks/code_nudge_sessionstart.sh`
- Modify: `hooks/hooks.json` (PreToolUse `Write|Edit` 목록 끝과 SessionStart 목록 끝)
- Test: `scripts/test_hooks.sh`

**Interfaces:**
- Consumes: `hooks/_spec_marker.sh`의 `path_in_project`, `hooks/_extract_path.sh`, `hooks/_json_escape.sh`의 `escape_for_json`. 훅 입력 JSON의 `session_id`(모든 훅 공통)와 `agent_id`(서브에이전트 안에서만). 환경변수 `DISCIPLINED_CODER_REVIEW_GATE`와 `TMPDIR`.
- Produces: 편집 훅은 stdout에 `{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"..."}}` 한 줄 또는 빈 출력을 낸다. 표시 파일은 `${TMPDIR:-/tmp}/disciplined-coder/code-nudge-<session_id>[-<agent_id>]`이고, 세션 시작 훅이 그 세션 몫을 지운다. 이 훅을 부르는 이름 「코드 넛지」는 Task 6이 README에 만든다.

- [ ] **Step 1: 테스트를 먼저 더한다**

`edit_t5_test.py`로 `scripts/test_hooks.sh`의 `echo "[doc-format-pre]"` 바로 앞에 블록을 넣는다. 훅 호출마다 `TMPDIR`을 픽스처 폴더로 돌려 표시 파일을 격리한다.

```python
import io
p = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/scripts/test_hooks.sh"
s = io.open(p, encoding="utf-8", newline="").read()
anchor = 'echo "[doc-format-pre]"\n'
assert s.count(anchor) == 1
block = '''echo "[code-nudge-pre — 문서가 아닌 파일의 세션 첫 편집 전에 domain-coding을 열라고 한 번 알린다]"
# 표시 파일은 TMPDIR 아래에 남으므로 픽스처 폴더로 돌린다 — 안 그러면 스위트를 두 번째 돌릴 때 앞 실행의
# 표시 파일이 남아 "첫 편집" 검사가 조용히 깨진다(IDEMPOTENT).
CNUD="$HERE/hooks/code_nudge_pretooluse.sh"
mkdir -p "$T/tmp"
cnud() { printf '%s' "$1" | TMPDIR="$T/tmp" bash "$CNUD"; }
JS() { printf '{"session_id":"%s"%s,"tool_input":{"file_path":"%s"}}' "$1" "$2" "$3"; }
check "훅 파일이 있다"                              "[ -f '$CNUD' ]"
check "첫 코드 편집 → domain-coding 안내"           "cnud '$(JS s1 "" "$T/src/main.py")' | grep -qF 'domain-coding'"
check "안내가 유효한 JSON"                          "cnud '$(JS s1b "" "$T/src/main.py")' | json_valid_stdin"
check "안내는 PreToolUse 이벤트를 말한다"            "cnud '$(JS s1c "" "$T/src/main.py")' | grep -qF '\\"hookEventName\\":\\"PreToolUse\\"'"
check "같은 키 둘째 편집 → 무출력"                  "[ -z \\"\\$(cnud '$(JS s1 "" "$T/src/other.py")')\\" ]"
check "같은 세션 다른 agent_id → 다시 안내"         "cnud '$(JS s1 ',"agent_id":"a1"' "$T/src/main.py")' | grep -qF 'domain-coding'"
check "문서(.md) → 무출력"                          "[ -z \\"\\$(cnud '$(JS s2 "" "$T/existing.md")')\\" ]"
check "리뷰 기록 JSON → 무출력"                     "[ -z \\"\\$(cnud '$(JS s3 "" "$T/docs/superpowers/reviews/x-review/lens-grounding-1.json")')\\" ]"
check "프로젝트 밖 → 무출력"                        "[ -z \\"\\$(cnud '$(JS s4 "" "$OUTSIDE/tool.py")')\\" ]"
check "OFF → 무출력"                                "[ -z \\"\\$(DISCIPLINED_CODER_REVIEW_GATE=off cnud '$(JS s5 "" "$T/src/main.py")')\\" ]"
check "session_id 없음 → 매번 안내"                 "cnud '$(J "$T/src/main.py")' | grep -qF 'domain-coding' && cnud '$(J "$T/src/main.py")' | grep -qF 'domain-coding'"
check "설정 파일(.json)도 대상"                     "cnud '$(JS s6 "" "$T/hooks.json")' | grep -qF 'domain-coding'"

echo "[code-nudge-sessionstart — 세션이 시작·재개·비워지면 그 세션의 표시를 지운다]"
# 표시 파일은 "이 맥락에서 이미 알렸다"를 뜻한다. 재개한 세션이 같은 session_id 를 다시 받는지는 훅 문서가
# 정하지 않는데, 이 훅이 있으면 어느 쪽이든 맞는다 — 아이디가 새로 나면 없는 파일을 지우는 무해한 동작이고,
# 재사용되면 넛지가 제대로 다시 걸린다. 쌓인 표시 파일을 치우는 유일한 걸음이기도 하다.
CSTA="$HERE/hooks/code_nudge_sessionstart.sh"
csta() { printf '%s' "$1" | TMPDIR="$T/tmp" bash "$CSTA"; }
JSS() { printf '{"session_id":"%s","hook_event_name":"SessionStart","source":"resume"}' "$1"; }
check "세션 시작 훅 파일이 있다"                    "[ -f '$CSTA' ]"
check "세션 시작은 아무것도 안 낸다"                "[ -z \\"\\$(csta '$(JSS s9)')\\" ]"
check "세션 시작이 표시를 지워 다시 알린다"         "csta '$(JSS s1)' && cnud '$(JS s1 "" "$T/src/main.py")' | grep -qF 'domain-coding'"

'''
s = s.replace(anchor, block + anchor)
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

- [ ] **Step 2: 빨간지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep 'FAIL:'`
Expected: 새 블록 둘의 검사가 모두 FAIL이다. `훅 파일이 있다`와 `세션 시작 훅 파일이 있다`를 비롯해 두 훅을 부르는 검사 전부다. 배선 검사 "모든 훅 스크립트가 어딘가에 배선되어 있다"는 아직 PASS다. 훅 파일이 없으므로 배선할 것도 없기 때문이다.

- [ ] **Step 3: 훅 스크립트를 쓴다**

Write 도구로 `hooks/code_nudge_pretooluse.sh`를 아래 내용 그대로 만든다.

```bash
#!/usr/bin/env bash
# PreToolUse(Write|Edit): 문서가 아닌 프로젝트 안 파일에 세션의 첫 편집이 들어오면 domain-coding을 열라고
# 알린다(비블로킹, 게이트 아님). 편집 뒤가 아니라 편집 전에 알려야 규칙을 읽고 고칠 수 있다 — 새 문서 넛지가
# PreToolUse 인 것과 같은 이유다.
# 세션 키는 훅 입력의 공통 필드 session_id 에 agent_id(서브에이전트 안의 훅 호출에만 온다)를 이은 것이다.
# 그래서 서브에이전트는 부모의 표시 파일과 무관하게 자기 넛지를 한 번 받는다.
# 필드의 정본: https://code.claude.com/docs/en/hooks
# 경로는 _extract_path.sh 가 추출(다중 순회). 순수 bash.
set -euo pipefail
[ "${DISCIPLINED_CODER_REVIEW_GATE:-on}" = "off" ] && exit 0
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/_spec_marker.sh"   # 경로 술어(path_in_project) 공유(SSOT)
. "$DIR/_json_escape.sh"   # JSON 문자열 이스케이프 공유(SSOT)
INPUT="$(cat)"
match=""
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  case "$FILE" in *.md) continue ;; esac                          # 문서는 문서 넛지가 맡는다
  case "$FILE" in *docs/superpowers/reviews/*) continue ;; esac    # 렌즈 원본 JSON 은 코드가 아니다
  path_in_project "$FILE" || continue                             # 프로젝트 밖(메모리·계획 파일)에는 걸지 않는다
  match="$FILE"; break
done <<EOF
$(printf '%s' "$INPUT" | bash "$DIR/_extract_path.sh")
EOF
[ -n "$match" ] || exit 0

# stdin JSON 의 최상위 문자열 필드 하나를 뽑는다. 없으면 빈 문자열.
json_str() {
  printf '%s' "$INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/' || true
}
sid="$(json_str session_id)"
aid="$(json_str agent_id)"
if [ -n "$sid" ]; then
  key="$sid${aid:+-$aid}"
  mdir="${TMPDIR:-/tmp}/disciplined-coder"
  marker="$mdir/code-nudge-$key"
  [ -e "$marker" ] && exit 0
  mkdir -p "$mdir" && : > "$marker"
fi
# session_id 가 없으면 계약이 깨진 것이다. 표시 파일 없이 매번 알린다 — 조용히 빠지지 않는다(FAIL-LOUD).

base="$(basename "$match")"
# 스킬의 절 이름을 여기 박지 않는다 — 훅은 스킬을 가리키기만 하고 내용을 베끼지 않는다(문서 넛지와 같은 규칙).
msg="🧑‍💻 문서가 아닌 파일(${base})을 고치려 한다 — 고치기 전에 disciplined-coder domain-coding을 열어 코드 규칙을 읽어라. 넛지일 뿐 차단은 아니다."
esc="$(escape_for_json "$msg")"
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$esc"
exit 0
```

- [ ] **Step 4: 세션 시작 훅을 쓴다**

Write 도구로 `hooks/code_nudge_sessionstart.sh`를 아래 내용 그대로 만든다.

```bash
#!/usr/bin/env bash
# SessionStart(startup|resume|clear): 이 세션의 코드 넛지 표시 파일을 지운다.
# 표시 파일은 "이 맥락에서 이미 알렸다"를 뜻한다. 세션이 새로 시작하거나 재개되거나 비워지면 스킬이 다시
# 안 실린 맥락이므로 표시도 지운다. 재개한 세션이 같은 session_id 를 다시 받는지는 훅 문서가 정하지 않고
# 이 PC 의 전사 파일로도 갈리지 않았는데, 이 훅이 있으면 어느 쪽이든 맞는다 — 아이디가 새로 나면 없는
# 파일을 지우는 무해한 동작이고, 재사용되면 넛지가 제대로 다시 걸린다. 쌓인 표시 파일을 치우는 유일한
# 걸음이기도 하다. 게이트 환경변수와 무관하다 — 지우는 것은 안내가 아니라 청소다.
set -euo pipefail
INPUT="$(cat)"
sid="$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)"$/\1/' || true)"
[ -n "$sid" ] || exit 0
mdir="${TMPDIR:-/tmp}/disciplined-coder"
# 서브에이전트 몫은 agent_id 가 뒤에 붙으므로 글롭으로 함께 지운다. 없으면 -f 가 조용히 넘어간다.
rm -f "$mdir/code-nudge-$sid" "$mdir/code-nudge-$sid"-* 2>/dev/null || true
exit 0
```

- [ ] **Step 5: 배선한다**

`edit_t5_wire.py`:

이 파일만 줄바꿈이 CRLF다. 다른 파일은 전부 LF다. 그래서 앵커를 줄 목록으로 두고 파일이 쓰는 줄바꿈으로 이어 붙인다. LF로 적은 앵커를 그대로 쓰면 한 곳도 못 맞히고, 파일 전체를 LF로 바꾸면 이 변경과 무관한 줄까지 diff에 들어온다.

```python
import io
p = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/hooks/hooks.json"
s = io.open(p, encoding="utf-8", newline="").read()
nl = "\r\n" if "\r\n" in s else "\n"
def J(lines):
    return nl.join(lines)

pre_old = J([
  '          {',
  '            "type": "command",',
  '            "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/hooks/doc_format_pretooluse.sh\\""',
  '          }',
  '        ]',
])
pre_new = J([
  '          {',
  '            "type": "command",',
  '            "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/hooks/doc_format_pretooluse.sh\\""',
  '          },',
  '          {',
  '            "type": "command",',
  '            "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/hooks/code_nudge_pretooluse.sh\\""',
  '          }',
  '        ]',
])
assert s.count(pre_old) == 1, "pre"
s = s.replace(pre_old, pre_new)

start_old = J([
  '            "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh\\""',
  '          }',
  '        ]',
])
start_new = J([
  '            "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh\\""',
  '          },',
  '          {',
  '            "type": "command",',
  '            "command": "bash \\"${CLAUDE_PLUGIN_ROOT}/hooks/code_nudge_sessionstart.sh\\""',
  '          }',
  '        ]',
])
assert s.count(start_old) == 1, "start"
s = s.replace(start_old, start_new)

io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

- [ ] **Step 6: 초록인지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | tail -1`
Expected: `PASS=<n> FAIL=0`. 배선 검사 둘(`배선이 가리키는 스크립트가 모두 존재`·`모든 훅 스크립트가 어딘가에 배선되어 있다`)도 PASS다. 이 태스크는 스위트를 초록으로 끝낸다.

- [ ] **Step 7: 커밋하지 않는다**

커밋 B는 Task 6 끝에서 한다.

---

### Task 6: 문서 넛지에 domain-writing을 덧붙이고 README 훅 절을 맞춘 뒤 커밋 B를 만든다

**Files:**
- Modify: `hooks/doc_format_pretooluse.sh`(알림 문장), `hooks/doc_review_posttooluse.sh`(알림 문장), `README.md`(「하드 게이트와 넛지와 전역 설정 수정」 절)
- Test: `scripts/test_hooks.sh`

**Interfaces:**
- Consumes: Task 3의 스킬 이름 `domain-writing`. Task 5가 만든 파일 `hooks/code_nudge_pretooluse.sh`와 `hooks/code_nudge_sessionstart.sh`.
- Produces: 훅 목록의 정본인 README 절이 넛지 넷과 코드 넛지를 적은 상태. 「코드 넛지」라는 이름이 여기서 처음 생긴다.

- [ ] **Step 1: 테스트를 먼저 더한다**

`edit_t6_test.py`:

```python
import io
p = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/scripts/test_hooks.sh"
s = io.open(p, encoding="utf-8", newline="").read()
a1 = '''check "새 리뷰 기록 → 무출력"            "[ -z \\"\\$(fpre '$(J "$T/docs/superpowers/reviews/new-check.md")')\\" ]"
'''
assert s.count(a1) == 1
s = s.replace(a1, a1 + '''check "새 문서 넛지가 domain-writing 을 가리킨다" "fpre '$(J "$T/newdoc.md")' | grep -qF 'domain-writing'"
''')
a2 = '''check "Windows 형식 경로도 프로젝트 안"  "drev '$(J "$(cygpath -w "$T" 2>/dev/null || printf '%s' "$T")\\\\\\\\win.md")' | grep -q additionalContext"
'''
assert s.count(a2) == 1, "a2"
s = s.replace(a2, a2 + '''check "수정 넛지가 domain-writing 을 가리킨다"   "drev '$(J "$T/existing.md")' | grep -qF 'domain-writing'"
check "수정 넛지에 스킬 절 이름을 박지 않는다"   "! drev '$(J "$T/existing.md")' | grep -qF 'Surgical Changes'"
check "README 가 코드 넛지를 적는다"             "grep -qF '코드 넛지' '$HERE/README.md'"
''')
io.open(p, "w", encoding="utf-8", newline="").write(s)
print("ok")
```

`a2`의 assert가 실패하면 `grep -n 'Windows 형식 경로' scripts/test_hooks.sh`로 그 줄을 열어 백슬래시 개수를 맞춘다. 파일에는 `\\\\win.md`처럼 백슬래시 넷이 있다.

- [ ] **Step 2: 빨간지 확인한다**

Run: `bash scripts/test_hooks.sh 2>&1 | grep 'FAIL:'`
Expected: `새 문서 넛지가 domain-writing 을 가리킨다`·`수정 넛지가 domain-writing 을 가리킨다`·`README 가 코드 넛지를 적는다` 셋이 FAIL이다.

- [ ] **Step 3: 훅 문장과 README를 고친다**

`edit_t6_impl.py`:

```python
import io
R = "D:/projects/disciplined-coder/.claude/worktrees/canon-split/"
staged = []
def rw(path, pairs):
    s = io.open(R+path, encoding="utf-8", newline="").read()
    for old, new in pairs:
        assert s.count(old) == 1, (path, old[:50])
        s = s.replace(old, new)
    staged.append((path, s))

rw("hooks/doc_format_pretooluse.sh", [
  ("결론/요약을 앞에 두고 내용을 양식대로 배치하라.\"", "결론/요약을 앞에 두고 내용을 양식대로 배치하라. 분량은 domain-writing을 따른다.\""),
])
rw("hooks/doc_review_posttooluse.sh", [
  ("셀프 퇴고만으로 끝내지 말 것. 넛지일 뿐 차단은 아니다.\"", "셀프 퇴고만으로 끝내지 말 것. 고칠 범위는 domain-writing을 따른다. 넛지일 뿐 차단은 아니다.\""),
])
rw("README.md", [
  ("읽기 전용 파일 수정을 막는 차단 하나와 넛지 셋과 전역 설정 수정 하나가 걸리고", "읽기 전용 파일 수정을 막는 차단 하나와 넛지 넷과 전역 설정 수정 하나가 걸리고"),
  ("하나로 넷 다 꺼지고, 읽기 전용 차단과 설치 권유는 그 변수와 무관하며",
   "하나로 다섯 다 꺼지고, 읽기 전용 차단과 설치 권유와 코드 넛지 표시를 지우는 세션 시작 훅은 그 변수와 무관하며"),
  ("- **넛지 셋** — 차단하지 않고 안내만 한다. spec이나 plan을 쓰면 리뷰를 지시하고, 새 `.md`를 만들면 `domain-docs`의 양식을 제안하며, `.md`를 고치면 문서 검진을 권한다. 프로젝트 폴더 밖의 문서와 리뷰 기록에는 뜨지 않는다.",
   "- **문서 넛지 셋** — 차단하지 않고 안내만 한다. spec이나 plan을 쓰면 리뷰를 지시하고, 새 `.md`를 만들면 `domain-docs`의 양식과 `domain-writing`의 분량 규칙을 권하며, `.md`를 고치면 문서 검진과 `domain-writing`의 수정 범위 규칙을 권한다. 프로젝트 폴더 밖의 문서와 리뷰 기록에는 뜨지 않는다.\n- **코드 넛지 하나** — 문서가 아닌 프로젝트 안 파일에 세션의 첫 `Write`나 `Edit`이 들어오면 편집 전에 `domain-coding`을 열라고 한 번 알린다. 세션은 훅 입력의 `session_id`로 가르고 서브에이전트는 `agent_id`로 따로 세므로 각자 한 번씩 받는다. 그 표시는 임시 폴더에 두고 세션이 시작·재개·비워질 때 지운다. `.md`와 리뷰 기록 폴더와 프로젝트 밖 경로에는 뜨지 않는다."),
])

for path, text in staged:
    io.open(R+path, "w", encoding="utf-8", newline="").write(text)
    print("edited", path)
```

- [ ] **Step 4: 전체 테스트와 검증을 돌린다**

Run: `bash <스크래치패드>/run_tests.sh "D:/projects/disciplined-coder/.claude/worktrees/canon-split"`
Expected: 다섯 스크립트 모두 `FAIL=0`, `ALL PASS`, validate는 version 경고 하나. 특히 `test_docs_drift.sh`의 "개수를 적은 자리마다 이름이 함께 있다" 검사가 README의 "넛지 넷"·"다섯 다 꺼지고"·"문서 넛지 셋"·"코드 넛지 하나"를 잡지 않아야 한다. 그 검사의 정규식은 렌즈 개수와 "곳에"만 보므로 걸리지 않는 것이 정상이고, 걸리면 그 출력을 그대로 보고한다.

- [ ] **Step 5: 커밋 B**

`commit_b.txt`:

```
코드 파일의 세션 첫 편집 전에 domain-coding을 열라고 알리는 훅을 건다

스킬은 Claude가 판단해야 열리고 정본은 판단 없이 실린다. 코딩 규칙이 스킬로 갔으므로
훅이 도구 호출이라는 사실로 열게 한다. PreToolUse(Write|Edit)에서 문서가 아닌 프로젝트
안 파일을 잡고, 훅 입력의 session_id와 agent_id로 표시 파일을 두어 세션과 서브에이전트마다
한 번만 알린다. 리뷰 기록 폴더는 건너뛴다. 문서 넛지 둘은 domain-writing을 함께 가리키되
절 이름은 박지 않는다. README 훅 절은 넛지 넷을 적는다.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_016SAvMLKU1ACEXds7QDsiDy
```

Run: `git add hooks/code_nudge_pretooluse.sh hooks/code_nudge_sessionstart.sh hooks/hooks.json hooks/doc_format_pretooluse.sh hooks/doc_review_posttooluse.sh README.md scripts/test_hooks.sh && git commit -q -F <스크래치패드>/commit_b.txt && git log --oneline -2`

---

### 끝낸 뒤

- `git log --oneline -3`으로 커밋 A와 B가 spec의 「되돌리기」 절대로 갈라져 있는지 본다.
- 이 워크트리의 변경은 아직 `main`에 없다. 병합은 사용자가 정한다. superpowers:finishing-a-development-branch를 연다.
- 실행 중인 플러그인은 `~/.claude/plugins/cache/`의 사본이라 새 훅은 플러그인이 갱신된 다음 세션부터 돈다.

<!-- spec-review: passed -->
