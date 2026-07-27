---
name: nested-orchestration
description: How to run two or more multi-task plans in parallel across three tiers — an orchestrator, then sub-orchestrators, then workers and reviewers. Covers one isolated worktree per spec, an autonomous L2, mechanically enforced ownership boundaries, and stateless resumption. The Parallel Orchestration section of agent-principles is what triggers it.
---
# nested-orchestration — three-tier parallel orchestration (the SSOT for the method)

> The `Parallel Orchestration` section of `agent-principles.md` is the trigger index. This document
> is the SSOT for *how*. This skill does not reimplement the existing skills but composes them — for
> the detail of each mechanism, open that skill.

## When to use it — the routing decision tree
Once there are two or more independent units of work:
- Each unit is a **single task** (it carries no plan-and-review loop of its own) — go to
  `dispatching-parallel-agents` and its two tiers. That is the end of it.
- Each unit is a **multi-task plan** (a chunk carrying its own plan, implement, and review loop) —
  use this skill and its three tiers.

Why the third tier earns its place: a two-tier worker solves exactly one task, and a sequential SDD
run stacks N loops into one context. Only three tiers run **N SDD loops at once, each in its own
isolated context**. That isolation and that concurrency are what the one extra coordination tier
buys. A single task gets none of it, so do not bolt the tier on.

## The flow — a three-stage pipeline (not a batch)
The human bottleneck lives mostly in the spec phase. So lock the specs one at a time, and fan out the
moment one locks.

1. **L1 (the main session, working with the human)**: lock the specs one at a time with
   `brainstorming`. The moment one locks, create a worktree (`using-git-worktrees`, or
   `isolation: 'worktree'` on `Agent`) and dispatch an L2 **in the background**. Meanwhile L1 carries
   on brainstorming the next spec.
2. **L2 (the autonomous sub-orchestrator, which cannot talk to a human)**: take the locked spec
   through `writing-plans` (starting from the plan) and then `subagent-driven-development` (the
   implementation), inside its own worktree. L2's SDD loop is what spawns L3, the implementers and
   reviewers. **Verification is wired in at three points.** For the spec phase L1 has already
   finished with `domain-spec-review` (hook-enforced). **For the plan phase L2 runs
   `domain-spec-review` autonomously and handles it through accept and regenerate itself**, but since
   it cannot talk to a human, an escalate situation bubbles up as the BLOCKED state below. The
   execution phase belongs to the SDD task reviewer plus whichever `reviewer-*` lenses the risk
   warrants.
3. **L1 integration**: take the completion notices from the L2s, gather their reports, verify the
   ownership mechanically, then merge and run a final branch review. This integration is not a light
   job and it happens at L1 — the bottleneck is narrowed, not removed. You may defer the integration
   until all the brainstorming is done, or, at scale, delegate the integration itself to its own
   subagent.

## The L2 dispatch template — six blocks
L2 can talk to nobody but its own parent, L1. Its prompt therefore has to be self-contained. Fixed
vocabulary: L2 is the sub-orchestrator, and L3 is the implementers and reviewers ("worker" is
two-tier vocabulary).

1. **Role declaration** — "You are an autonomous sub-orchestrator. You will finish this spec and
   produce a branch without another round trip to me, the orchestrator. You are in an isolated git
   worktree."
2. **The mission** — the spec path (stated to be the SSOT) plus an enumeration of the deliverables.
3. **Ownership boundary (strictly observed)** — the file and directory paths this workstream owns,
   plus an **explicit prohibition** on the files another workstream owns.
4. **The method (`TDD` plus three tiers)** — implement through implementers (edit the same file
   sequentially, and never mutate it in parallel), follow the project's test conventions, and have a
   **read-only reviewer subagent** read the diff and return findings for L2 to act on (the reviewer
   leaves the files unchanged). Pick the reviewers in proportion to the risk (the `Verification
   Layer` section) — the SDD task reviewer, and the `reviewer-grounding` and `reviewer-adversarial`
   lenses where they are needed.
5. **Injected context** — the gotchas for this domain recalled from `solved_problems`, so that the
   same thing is not rediscovered twice.
6. **Output contract (up to the branch and no further — never merge, deploy, or push to main)** —
   write the detail into a **report file** (the changed files, the final test results, the actual
   shape of any published schema, any departure from the spec, and the branch name), and **return to
   L1 nothing but the status, the blockers, a one-line summary, and the report path**. Write the
   report to **a per-workstream unique path outside the product tree** (`report-<workstream>.md`, for
   example) and **do not commit it to the branch that will be merged** — committing it at a fixed
   path makes the workstreams collide on merge, as measured. A subagent's `Write` can be stopped from
   writing a `.md` by a hook, so record the report through Bash into scratch instead (a measured
   gotcha).

## No human channel — BLOCKED and resumption
- When L2 hits a decision that needs a human (a 🔴), it must not try to surface it mid-run, since a
  background agent has no immediate channel. It **stops early at that point and returns the status
  `BLOCKED` together with the question**, leaving everything committed so far on the branch. It never
  guesses its way past (the "surface a 🔴 immediately" rule of the `Solved Log` section).
- L1 surfaces that question to the user. Once the user answers, L1 does not revive the halted L2 —
  it **folds the answer into the spec (resolving the 🔴) and re-dispatches a fresh L2 into that
  worktree**. The new L2 continues on top of the existing commits, which is what makes the resumption
  stateless.
- **Residual risk (stated honestly)**: bubbling BLOCKED up is a prompt nudge to an autonomous LLM,
  not a hard control. If L2 fails to notice a 🔴 and guesses instead, L1 only sees it once a finished
  branch arrives. The last line of defence is L1's integration check and the final branch review.

## Guardrails (`FAIL-LOUD`)
- **Ownership boundary enforcement (declared, then mechanically detected)**: while gathering, L1
  computes each branch's set of changed files (`git diff --name-only base..branch`). **An empty
  intersection between two sets is safe; anything else stops the merge and gets surfaced.** The
  report handoff lives outside the branch, so these sets hold product files only. An overlap then
  shows up as an explicit FAIL *before* the merge rather than as a silent merge conflict.
- **Crash and hang recovery**: L1 holds its dispatched workstreams as in-flight, and for an L2 whose
  completion notice never arrives it drills into the CLI (double-click) to check whether it is alive,
  re-dispatching from the last commit if it died. The limit: there is no timeout or health-check
  tooling, so this rests on L1 paying attention.
- **Cost (stated honestly)**: the substance of the tasks costs about the same sequentially or in
  parallel, but parallel is not free — every L2 re-establishes its context (re-reading the spec,
  re-recalling the gotchas, re-reading the codebase) and fans out its own agents, which is N times
  the overhead. What you buy is wall-clock time and context isolation. A measured reference point:
  roughly 40k tokens for one minor workstream, L3 included.

## Observability — what you see and what you do not
Manual `Agent` nesting does not appear on the `/workflows` aggregate dashboard, which belongs to the
`Workflow` tool alone. What you do get is the CLI showing the subagents, where a double-click drills
into each L2's live session — that is how you answer "what is each L2 doing right now". What you do
not get is the aggregate view, the metrics, or any surfaced display of the worktree assignment.
Bloat in the main context is mitigated by the report-file separation above.

## Do not reimplement (SSOT pointers)
- `brainstorming` takes an idea to a spec, `writing-plans` turns that spec into a plan, and
  `subagent-driven-development` owns the execution loop.
- `dispatching-parallel-agents` owns the parallel dispatch mechanism, which is both the single-task
  route and the foundation dispatch rests on.
- `using-git-worktrees` owns worktree isolation, and the `reviewer-*` skills own the review lenses.

## Limits (stated honestly)
Three tiers add a coordination tier, so they earn their keep only on a multi-task plan — which is
what the routing is for. BLOCKED honesty and ownership enforcement were verified in a spike, but
crash recovery and large workstreams are still unverified. This is the result of choosing autonomy
(L2's own judgement) over observability and reproducibility (`Workflow` determinism), so the price —
no aggregate UI, and the residual risk of a guess — is accepted.

**Non-goals**: no deterministic `Workflow` version, no aggregate UI dashboard, and **no persisted
orchestration state document** — in-flight state is held in the session conversation alone
(disciplined-coder's stateless identity). Nesting at L4 or deeper is not covered either (three tiers
only). For single-task parallelism, `dispatching-parallel-agents` is the SSOT.
