---
name: domain-coding
description: 코드를 쓰거나 고칠 때의 규칙이다. 카파시(Andrej Karpathy) 코딩 지침의 코드용 세 절과, 정본에서 옮겨 온 다섯 원칙(한 가지 일·단일 출처·멱등성·명시성·변경 설명)을 담는다. 규칙을 얻으려고 다른 파일을 열 필요가 없게 이 한 파일로 닫아 둔다. 세션에서 파일을 처음 건드리려 하면 훅이 이 스킬을 열라고 알린다. 코드를 구현하는 서브에이전트에도 이 파일 경로를 넘긴다.
---
# domain-coding — rules for writing and changing code

These rules apply whenever code is written or changed. Rules that also hold in plain conversation live in the always-loaded canon and are not repeated here.

## Karpathy guidelines

From `andrej-karpathy-skills` 1.0.0, copied here so this file stands alone. Think Before Coding is not repeated: it applies to plain answers too and lives in the canon as Think Before Acting.

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

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

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

Behavior must be visible from names, types, and contracts alone.

### Describe the change, not the diff

"The rest of the description should fill in the details and include any supplemental information a reader needs to understand the changelist holistically." — Google Engineering Practices, *Writing good CL descriptions*. "Once the problem is established, describe what you are actually doing about it in technical detail." — Linux kernel, *Submitting patches*.

After changing code, report the change in structure: what now calls what, and what now depends on what. The diff already shows the lines.

## Reach

Subagents do not receive this file automatically. When a subagent implements code, put this file's path in its prompt the way `dispatching-lenses`'s 「렌즈에게 정본을 알리는 법」 prescribes for the canon.
