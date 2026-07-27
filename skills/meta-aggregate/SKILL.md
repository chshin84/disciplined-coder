---
name: meta-aggregate
description: The aggregation step that gathers the output of two or more reviewers, checks the structural health of that output — conflicts between them, coverage gaps — and decides accept, regenerate, or escalate. It is not a reviewer and not a lens. It is a code blueprint, and it never re-judges the content.
---
# meta-aggregate — aggregation and decision (code blueprint)

> This is **not a reviewer** (not a lens). It is the step that runs after the reviewers finish,
> gathers their results, and settles what happens next. And it is not a prompt but a **code
> blueprint** — implement it as deterministic code.

## Avoiding judgment recursion (the core constraint)
Look only at the **structure** of the reviewer output. **Do not re-judge the content, and do not
weight one reviewer against another**, as in deciding which reviewer is right. The recursion ends at
a human.

## What it does
- **Aggregate**: gather every reviewer's issues into one list, tag each one with its source, and sort
  by severity. This is mechanical.
- **Detect conflicts**: where two verdicts land on the same spot and oppose each other, mark it as an
  escalate candidate.
- **Coverage gaps**: where nobody looked at a dimension the risk calls for, recommend adding the
  missing reviewer.

## Decision policy (default)
- Even one critical issue means **regenerate** — call the first pass again with the issues attached.
  Once the retry cap is reached, escalate instead.
- A conflict or a gap means **escalate** to a human, or fill in the missing dimension and aggregate
  again.
- No critical issue and no conflict means **accept**, with the major and minor issues logged.

## Output schema
```
{ "decision": "accept|regenerate|escalate", "reason": "...", "aggregated": [ { "severity": "...", "type": "...", "source": "grounding|fit|consistency|adversarial", "where": "...", "detail": "..." } ], "retry_count": 0 }
```

## How it is implemented (depends on the context)
- **Product runtime** (`domain-llm-runtime`): implement it as a deterministic Python function.
  Aggregating and counting are deterministic, so no model is needed. Reach for an LLM only for an
  ambiguous conflict verdict, and even there only optionally.
- **Spec and plan review** (`domain-spec-review`): there is no product code, so the main session
  follows this narrow procedure and aggregates by hand. It is simple enough that no separate script
  ships with it, which keeps the plugin hooks pure bash and dependency-free for portability.
- Either way, cap the regenerate loop — one or two rounds, say — so it can neither spin forever nor
  run the cost away.
