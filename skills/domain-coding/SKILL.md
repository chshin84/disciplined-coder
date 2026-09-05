---
name: domain-coding
description: 코드를 쓰거나 고칠 때의 규칙이다. 정본에서 옮겨 온 다섯 원칙(한 가지 일·단일 출처·멱등성·명시성·변경 설명)을 담고, 겹치는 카파시(Andrej Karpathy) 코딩 지침은 베끼지 않고 andrej-karpathy-skills 플러그인의 karpathy-guidelines 스킬을 열게 한다. 그 플러그인이 없으면 설치를 먼저 권한다. 문서가 아닌 프로젝트 안 파일에 세션의 첫 편집이 들어오면 편집 전에 훅이 이 스킬을 열라고 알린다. 코드를 구현하는 서브에이전트에도 이 파일 경로를 넘긴다.
---
# domain-coding — rules for writing and changing code

These rules apply whenever code is written or changed. Rules that also hold in plain conversation live in the always-loaded canon and are not repeated here.

## Karpathy guidelines

Do not read them here. They live in the `andrej-karpathy-skills` plugin's `karpathy-guidelines` skill, which is their single source of truth. **Open that skill before you write or change code.** Simplicity First, Surgical Changes, and Goal-Driven Execution are not repeated in this file.

If that skill is not available on this machine, the plugin is not installed. Tell the user so and give them the two commands, then continue without it:

```
claude plugin marketplace add forrestchang/andrej-karpathy-skills
claude plugin install andrej-karpathy-skills@karpathy-skills
```

Think Before Coding is the one section that is not there for you to open here: it applies to plain answers too, so it lives in the always-loaded canon as Think Before Acting.

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
