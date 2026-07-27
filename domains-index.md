# Domain Reference Index

Every build target carries expectations that differ by domain — some are things it **ought to be**,
others are things you would **like it to be**. During design or planning, open the matching domain
reference and fold both into the spec (first priority); when they do not fit the spec, weigh them
during implementation instead (fallback). This file is only a table of contents — the detail lives
on-demand in each skill.

| Domain | Trigger (when) | When it applies | Caller skill |
|---|---|---|---|
| Document management | Writing or structuring documentation (a core Claude Code activity — document to document) | Design, development | `domain-docs` |
| Plugin management | Building a Claude Code plugin or marketplace | Design, development | `domain-plugin` |
| LLM runtime | The product calls an LLM at runtime | **Runtime** | `domain-llm-runtime` (plus `reviewer-*`, `meta-aggregate`) |

## How to use this

- **At design or planning time**: if the build target matches a domain above, open that skill and
  fold both what it ought to be and what you would like it to be into the spec.
- **At development time**: consult it then, if it did not make it into the spec.
- **List only a domain whose pain is confirmed.** Add a new domain only when it is actually needed
  (YAGNI, measure first), and do not leave an empty stub in place — an absent entry is more honest
  than one that only pretends to be handled.
