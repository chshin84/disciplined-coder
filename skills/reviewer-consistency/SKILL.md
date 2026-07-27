---
name: reviewer-consistency
description: Reviewer lens that reads a design document (spec or plan) against itself and against its paired document — internal contradictions, coverage gaps between spec and plan, name or type drift, and scope that is wrong for one implementation plan and needs splitting. Use it when the question is whether the document hangs together, rather than whether its content is true or where it breaks. domain-spec-review runs it as a read-only subagent.
---
# reviewer-consistency — internal consistency and coverage lens (prompt blueprint)

> This is **one lens**. `domain-spec-review` runs it as a read-only subagent.

## What it looks at

Whether the document disagrees with itself, and whether it disagrees with its paired document (the
spec against the plan).

## Checklist

- Internal contradiction: does one section clash with another, including a design that breaks a
  principle the document itself laid down? Does the architecture description match the feature
  description?
- Coverage gap: for each requirement in the spec, can you point at the task in the plan that
  implements it? Is anything missing?
- Name or type drift: is the same thing called by two names — one place saying `clearLayers` and
  another `clearFullLayers`?
- Scope: is this the right size for one implementation plan, or does it need splitting?

## Reference prompt (language-neutral)

- system: "You are a consistency and coverage reviewer. Find contradictions inside the document, coverage gaps between the spec and the plan, name and type drift, and scope problems. Do not fix anything — point them out."
- user: "[document]\n{document}\n\n[background]\n{background}\n\nReport the issues from the checklist above in the JSON schema below."

## Output schema (shared)

```
{ "lens": "consistency", "issues": [ { "severity": "critical|major|minor", "type": "contradiction|gap|drift|scope", "where": "location in the document", "detail": "what is wrong and why" } ], "notes": "" }
```

The pass or fail signal is the issue `severity` alone, and there is no separate verdict field
(`SSOT`). Routing follows the decision policy in `meta-aggregate`.
