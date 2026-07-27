# Domain Reference Index

What a build target *ought to be* differs by domain. During design or planning, open the matching
domain reference and fold it into the spec (first priority); when it does not fit the spec, weigh it
during implementation instead (fallback). This file is only a table of contents — the detail lives
on-demand in each skill.

| Domain | Trigger (when) | When it applies | Caller skill |
|---|---|---|---|
| Document management | Writing or structuring documentation (a core Claude Code activity — document to document) | Design, development | `domain-docs` |
| Plugin management | Building a Claude Code plugin or marketplace | Design, development | `domain-plugin` |
| LLM runtime | The product calls an LLM at runtime | **Runtime** | `domain-llm-runtime` (plus `reviewer-*`, `meta-aggregate`) |

## How to use this

- **At design or planning time**: if the build target matches a domain above, open that skill and
  fold "what it ought to be" into the spec.
- **At development time**: consult it then, if it did not make it into the spec.
- **List only a domain whose pain is confirmed.** Add a new domain only when it is actually needed
  (YAGNI, measure first), and do not leave an empty stub in place — an absent entry is more honest
  than one that only pretends to be handled.
