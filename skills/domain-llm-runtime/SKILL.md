---
name: domain-llm-runtime
description: Verification caller for building a feature where the product calls an LLM at runtime. Never let a single call stand as the answer — pick reviewers (reviewer-*) in proportion to the risk and implement them as review calls inside the product code, and apply the non-functional checklist every time. For the reviewer lenses and for meta-aggregate, see their own skills.
---
# domain-llm-runtime — runtime LLM verification caller

A feature where the product **calls an LLM at runtime** must not end at that single call. Implement a
**verification layer** in the code. The reviewers here are not Claude Code agents but **a blueprint
the product code implements**. The shared method — PREP, then independent lenses, then meta
aggregation, then routing — follows the `Verification Layer` section of `agent-principles.md`.

## Choosing reviewers (in proportion to the risk)
Score the risk by adding one point for each of these that holds. There is an external call. There is
an LLM component. An interface contract changes. Human-in-the-loop or compliance is involved. The
spec runs to three sections or more.

| Score | Reviewers | Meta |
|---|---|---|
| 0–1 | No reviewer applies, and only the non-functional checklist does | Not needed |
| 2–3 | `reviewer-grounding` | Not needed with a single reviewer |
| 4–5 | `reviewer-grounding` plus `reviewer-fit` | `meta-aggregate` is required (two or more reviewers) |

- The "source" for `reviewer-grounding` is, here, **the original request together with the context
  that was supplied**.
- `reviewer-fit` looks at the downstream contract. For schema and format, run **a code validator
  first** and spend a review call only where that validator fails, which keeps the cost down.
- `meta-aggregate` is, here, implemented as **a deterministic Python function** rather than an LLM
  call.

## Assembly
Once the first call returns, run the reviewer review calls in parallel according to the risk, and let
`meta-aggregate` aggregate them and decide accept, regenerate, or escalate. The non-functional
checklist is not a stage in that sequence; it wraps around the outside as a set of properties the
whole calling code must satisfy at all times.

## Non-functional checklist (runtime only — a code blueprint)
These are not reviewers and not LLM calls. They are requirements the calling code has to meet, and
during implementation you nail each one down with a code guard plus a test that verifies the guard.
They are deterministic, so verify them with static checks and tests.
- **Timeout on external calls** — without one the call waits forever. (critical)
- **Retry policy** — retry with exponential backoff against transient failures and rate limits.
  (major)
- **None guard on empty or failed responses** — a real SDK can return None for an empty result, so an
  `x or {}` guard keeps the AttributeError from firing. (major)
- **Error response shape** — return a structured error the caller can handle. (major)
- **Cost and token ceilings** — cap the input and the output tokens, and cap the number of retries.
  (major)
- **Observability** — log the requests, the latency, the tokens, and the failure rate (principle
  `MEASURE-FIRST`). (minor to major)
- **Human-in-the-loop gate** — an irreversible or high-risk action needs human approval. Where
  compliance is involved this is critical, and otherwise it follows policy.
- **Sensitive data** — never expose secrets or PII in prompts or logs (principle `SECRETS`).

Handle a missing item by its severity, where a critical one blocks the merge and the deploy.

## Cost
A review call is extra cost and extra latency. Add it only in proportion to the risk. Whatever a
deterministic check can verify — a schema, a regular expression — goes in code first. Only critical
issues force a regenerate.
