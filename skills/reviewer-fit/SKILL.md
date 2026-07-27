---
name: reviewer-fit
description: Reviewer lens that checks an LLM output against its consumer contract — format, schema, length, style, and prohibitions — screening it for shape before anything downstream parses and uses it. Use it when the question is whether the shape is usable, not whether the content is true (that belongs to reviewer-grounding). Run deterministic verification first wherever it applies, and spend this lens only on what deterministic checks cannot catch.
---
# reviewer-fit — contract fitness lens (prompt blueprint)

> This is **one lens**. How it runs is the caller's decision — the runtime review call in
> `domain-llm-runtime`, or the document-review nudge that pairs `reviewer-grounding` with
> `reviewer-fit`. This document defines only what it looks at and what issue list it returns.

## What it looks at

Whether the output honours the format, schema, style, and constraints it was given, as other code, a
user, or another system consumes it. It does not judge whether the content is accurate; that belongs
to `reviewer-grounding`.

## Checklist

- Does it honour the required format and schema (valid JSON, required keys, correct types)?
- Does it honour the style and constraints — length, language, tone, forbidden words?
- Can downstream parse and use it as it stands, with no contamination such as stray text or markdown
  fences?
- Is it backward compatible with the existing output contract?

> Run **deterministic verification first** wherever it applies — a JSON schema validator, a regular
> expression. Spend the LLM review only on the style and the fuzzy constraints that deterministic
> checks cannot catch, which keeps the cost down.

## Reference prompt (language-neutral)

- system: "You are a fitness reviewer. Look only at whether the candidate honours the stated output contract — format, schema, style, constraints. Do not judge the accuracy of the content."
- user: "[output contract]\n{contract}\n\n[candidate]\n{candidate}\n\nReport the violations in the JSON schema below."

## Output schema (shared)

```
{ "lens": "fit", "issues": [ { "severity": "critical|major|minor", "type": "schema|format|style|constraint|compat", "where": "location in the candidate", "detail": "which contract clause is violated and how" } ], "notes": "" }
```

The pass or fail signal is the issue `severity` alone, and there is no separate verdict field
(`SSOT`). Routing — critical leading to regenerate or a fallback, and so on — follows the decision
policy in `meta-aggregate`.
