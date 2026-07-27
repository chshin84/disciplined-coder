---
name: domain-spec-review
description: Verification caller for the spec and plan documents (the meta artifacts) Claude produces through brainstorming and writing-plans. It has independent reviewers (reviewer-grounding, reviewer-consistency, reviewer-adversarial) check the document and routes the result through meta-aggregate to accept, regenerate, or escalate. A hook enforces it whenever a superpowers spec or plan is written. This is not a product runtime call but a review of Claude's own design document.
---
# domain-spec-review — independent review caller for specs and plans

> **This is not a product code blueprint.** Runtime verification (`domain-llm-runtime`) is
> implemented by product code, and it applies when *the product calls an LLM*. This skill is a Claude
> Code workflow in which **the main session dispatches the subagents itself**, and it applies when
> *Claude writes a design document — a spec or a plan*. It does not replace the superpowers
> self-review; it adds a layer behind it.

## Why
The self-review inside `brainstorming` and `writing-plans` is the author reading their own writing,
which is weak against confirmation bias. On a high-risk design, a fresh reviewer who did not write
the document is what breaks that bias.

## Enforcement (hooks) — not skippable
When a spec or plan is written to the superpowers default paths
(`docs/superpowers/{specs,plans}/*.md`):
- **PostToolUse** detects it at once and instructs you to run this skill (non-blocking).
- **Stop** blocks the turn from ending while an unreviewed spec or plan is still there (a hard gate).
- Once the review is done, leaving a marker on the document's **last line** releases the gate:
  `<!-- spec-review: passed -->`, or `escalated` where the decision was escalate. **Never bake a date
  or a count into it** — the marker is a contract token for the gate, not state ("no state in
  documents"). An existing dated marker is still recognised (prefix match, for backward
  compatibility). Only a terminal decision, passed or escalated, is a marker; pending is not.
- To switch it off, set the environment variable `DISCIPLINED_CODER_REVIEW_GATE=off` (a global
  hook — `hooks/hooks.json`).

## The procedure (the shared method — see the `Verification Layer` section of `agent-principles.md`)
### 1) PREP (the "expectation first" of `TDD` — nothing improvised)
Before dispatching, the main session prepares these per lens.
- **Injected knowledge**: the document itself (the spec or plan path) plus the relevant background —
  the principles that apply, the prior decisions and earlier specs, **the concrete facts to verify**,
  and the relevant file paths. (This injected knowledge is exactly what `reviewer-grounding` calls
  its "source".)
- **Target checklist**: state in advance what that lens is to look at.

### 2) Dispatch — each reviewer as its own separate subagent
Run **one read-only subagent per reviewer** — an agent with no Edit and no Write, which structurally
rules out a false claim, and which keeps a single agent from sweeping every lens at once, so that
independence is enforced. Each one receives the document plus the injected knowledge and returns its
own JSON.
- `reviewer-grounding` — whether claims about external facts, cost, APIs, and the environment are
  grounded, and where an assertion or a hallucination carries no support.
- `reviewer-consistency` — internal contradictions, coverage gaps between the spec and the plan, name
  and type drift, and scope.
- `reviewer-adversarial` — failure modes, over-engineering, and irreversibility (guarded so that it
  never proposes adding a feature).

### 3) Meta aggregation — reuse `meta-aggregate`
Sort by severity, tag each issue with its source, and detect conflicts — this is code logic and needs
no LLM — and settle the decision from there. In a spec or plan review the main session carries out
`meta-aggregate`'s narrow procedure directly, since there is no product code here. There is a single
writer: the reviewers only return JSON, and the main session aggregates, applies the fixes, and
records the marker.

## Routing, then applying, then rework
- **accept** (no critical issue): fix the major and minor ones partially, since a partial fix is the
  default (`SURGICAL`), then leave the marker (passed).
- **regenerate** (one or more critical issues): rewrite only the sections that were flagged, then
  re-review only those sections. The cap is one round, and anything still standing after it
  escalates.
- **escalate** (a conflict, a question of direction, or the user being unavailable): surface it to
  the user as a 🔴 and leave the marker (escalated). The gate releases, because it is now waiting on
  a human decision. Never loop automatically.

## Limits (stated honestly — `FAIL-LOUD`)
The hook checks only that the marker is there — attach the marker without running a review and
nothing stops you. There is structural mitigation (read-only reviewers that can do nothing but
return JSON), but perfect enforcement is impossible. Outside what the hook detects — a custom path,
a non-git directory — it is FAIL-OPEN, so that work is never made impossible.
