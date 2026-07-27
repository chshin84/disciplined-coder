---
name: domain-docs
description: Authoring rules for how documentation is written and structured in any project — principle documents, reference documents, READMEs, skill SKILL.md files, the managed regions of a CLAUDE.md, and the like. Consult it during design and during development. Specs and plans, which superpowers owns, are out of scope.
---
# domain-docs — rules for writing and structuring documentation

## Scope
These are the rules for writing and structuring documentation in any project, this plugin's own
documents included. superpowers already owns specs and plans, which are the heart of design
documentation, so what is handled here is everything else — principle documents, domain references,
user-facing `README` files, skill `SKILL.md` files, the managed regions of a `CLAUDE.md`, and so on.

## Rules for documents in general
- **Refer by ID, never by an ordinal number** — a table of contents or a numbering scheme (A/B/C, or
  1, 2, 3) implies a priority that does not exist. Use stable IDs and an unordered, alphabetical
  glossary instead (see `NO-PRIORITY`).
- **Document SSOT** — the same fact lives in one document only, and every other document refers to it
  through an `@import` or a link. Never duplicate it. The same holds when you cite an outside
  convention or standard: do not copy its text, distill it down to what matters, and then link the
  source (`SSOT`).
- **The managed-region pattern** — wrap an automatically generated section in BEGIN and END markers
  so it can be regenerated idempotently, and keep user content outside those markers.
- **Where to put it** — what is needed at all times goes in `CLAUDE.md` or an `@import`, what is
  needed on demand goes in a skill, and what applies only to certain paths goes in rules.
- **Enrich** — do not toss out a bare ID; explain it fully, in complete sentences (`CLEAR-COMM`).
- **From abstract to concrete** — replace a vague expression with concrete information: what, when,
  how much, and with what result. Not "it is slow" but "it takes 12 seconds to load". This is the
  central *method* named by 《글 잘 쓰고 싶은 개발자》, a Korean book on writing for developers.
- **Facts and evidence** — separate opinion from fact, mark what is unconfirmed as a possibility
  instead of asserting it, and attach checkable evidence to every claim: a log, a number, a
  reproduction condition.

## README (a user-facing document — rules specific to this type)
A README is a project's first impression and often its only point of contact. Apply the following on
top of the general document rules above. The universal principles (`SIMPLE`, `SSOT`, `FOCUSED`,
`CLEAR-COMM`) are not restated here but referenced by ID — only what is specific to a README belongs
here.

- **Let the reader answer four questions quickly** — ① Does this solve my problem? ② Can I use it?
  ③ Who built it? ④ Where do I learn more? Anything that blocks that path is padding.
- **Separate the audiences (the most common trap)** — do not mix the user's install-and-use path with
  the developer's internal rationale (design justifications, the full API, verification notes) in one
  document. Move the latter into a separate document or a skill (`FOCUSED` plus "where to put it").
- **A suggested reading path (not a ranking)** — the title and a one-line description, then
  Highlights as bullets of the core selling points, then an Overview of what it is and why. From
  there it runs on to installation, aiming at a one-line install command, then usage examples, then
  caveats and limits, and finally further reading and contributing. This is a path for the reader to
  walk, not the priority numbering that `NO-PRIORITY` forbids — **do not number the sections**.
- **Only what is needed (`SIMPLE` and YAGNI)** — the badges, table of contents, screenshots or GIFs,
  and changelog that general open-source guides recommend go in only when the project actually needs
  them. Do not overfeed a small tool. A self-explanatory title and a one-line install are often worth
  more than a GIF.

Sources (material to distill — link them rather than copying their text):
[banesullivan/README](https://github.com/banesullivan/README),
[awesome-readme](https://github.com/matiassingers/awesome-readme),
[Make a README](https://www.makeareadme.com/),
[글 잘 쓰고 싶은 개발자](https://wikidocs.net/book/20224) (the title and the opening description should
reveal the identity and the intended reader within ten seconds, each sentence should carry one
meaning, the conclusion should come first, and padding should be deleted),
[좋은 README 작성법 (InfoGrab)](https://insight.infograb.net/blog/2023/08/23/good-readme/) (a checklist
of components: usage examples, troubleshooting, maintainers, license).

## Forms for each kind of writing (applied as you write)
Every kind of writing has a form suited to its purpose, and you frame the piece in that form at the
moment you write it. Follow the general document rules above for anything universal, and when you
need a per-kind template, distill appendices C through G of 《글 잘 쓰고 싶은 개발자》, the wikidocs book
in the source list above. Only the essentials are recorded here:
- **A bug report** — write it so that someone else can reproduce it exactly (the environment, the
  steps to reproduce, and the gap between what was expected and what happened).
- **A code review** — point at the code rather than the person, and give the reason alongside.
- **A work report** — separate what is finished, what remains, and who owns the next action.
- **A README or a technical blog post** — put the summary and the purpose at the very front, and
  write it so the reader can follow along.
- **A publicly posted document such as a GitHub issue or pull request** — write it so a maintainer
  can understand it without the author's context, put the conclusion first, gloss the terminology as
  it appears, and follow the bug-report form when it is a bug.

> A document that goes out publicly, such as a GitHub issue or a pull request description, **passes
> through `reviewer-grounding` (are the claims grounded in the code) and `reviewer-fit` (does it fit
> the form and the contract) before it is posted** (the `Verification Layer` section — never put a
> lone LLM output straight in front of an outside audience). Do not dump audit or analysis notes
> verbatim.

## Document types and lifetimes — the type decides the prescription (the SSOT for state hygiene)
This is the detailed canon behind the `Document Hygiene` section of `agent-principles.md`.
**Preventing staleness is not one rule but a strategy per type** — once you settle the type, the
prescription follows. The governing idea is **drift-proof by construction**: do not hold the line
with maintenance, build the thing so that going stale is impossible from the start (state that was
never written cannot rot, and a handoff already deleted cannot compete). Types divide along three
axes — ① does it hold volatile state, ② how long does it live, and ③ is it the SSOT or merely a copy
or a courier.

| Type | What it holds | Lifetime | How it is kept from going stale | Teeth (the project's guard) |
|---|---|---|---|---|
| **State** (a roadmap) | What is finished, what is next, and the current stage | Living, with a single home | Derive it first, keep it in one place only, and link to that place from everywhere else | Check it against the code and the infrastructure |
| **Procedure and contract** (operations, setup, contract) | The how, and schema contracts | Living | No state, only the how — what is never written cannot rot | A doc-to-code test, such as one tying a mode to its runbook |
| **Design** (analysis and design, or a spec or plan) | The why, and how the design works | The rationale keeps living, while a spec is deleted once it ships | No state, plus a superseded marking; for anything shipped, git stands in its place | Keep the pointers in code comments in sync |
| **Handoff** (`HANDOFF-*`) | A one-time handover | Until consumed, then deleted | Delete it immediately — what is gone cannot rot | Lint for leftover handoff patterns |
| **Issue** (the solved mistake notebook) | A lesson from a problem already finished | Append-only, with nothing moved | Recorded after the problem was finished, so it is not state (the exception); issue tracking is delegated to a tracker | Recall before you start, plus the `Solved Log` section of `agent-principles` |
| **Context** (Claude's memory) | Decisions and context carried across sessions | Living, and local to one PC | Where it disagrees with the code the code wins, and its PC-local limit is understood | Cite code evidence for every claim of fact |
| **Norm and index** (a `CLAUDE.md`, or a document map) | Where things are, and how the work is done | Living | Pointers and rules only, never state; keep a map light and derive it first | — |

> The solved log is kept **per layer** — the project's `docs/solved_problems.md` and the PC's
> `~/.claude/…` (scope routing). Append-only means immutable **within one layer**, and a lesson that
> applies more widely is **rewritten** into the layer above it (a promotion) — that is not moving
> bytes but writing it again in more general terms, so it does not contradict "nothing moved".

Read the table down its columns and half of the staleness strategies converge on **"do not hold
state, delete it, or derive it"** — in practice only one type of document, the state document, needs
maintaining by hand, and pushing even that one toward derivation leaves nothing to touch. The common
pain of "update all the documents before and after the work" is a symptom of an `SSOT` violation,
not an intrinsic cost.

### Modification discipline — how a document is allowed to change (the second axis)
On top of the content type (what a document holds), classifying **how it is allowed to change**
sharpens the prescription. When a document *declares* its own modification discipline (`EXPLICIT`),
that declaration becomes the contract for machine enforcement — the BEGIN and END managed block is
one instance of this.

| Modification discipline | How it changes | Maintenance obligation | Failure mode | Machine enforcement |
|---|---|---|---|---|
| append-only | Additions only, with the past left untouched | None | It bloats (distill it periodically) | Refuse edits or deletions of earlier lines |
| generated | Regenerated from the truth, never touched by hand | None, since it syncs automatically | A bug in the generator | Regenerate, then guard on the diff |
| living | Hand-edited in place | Yes, and it carries the highest risk | Drift and false positives | No state, only the how; or a doc-to-code guard |
| ephemeral | Written once, then deleted | An obligation to delete | If it survives it becomes a false competitor | Lint for leftover patterns |

Push a document toward **append-only or generated** wherever you can, since both carry zero
maintenance obligation. The core insight is that **writing state down takes on an obligation — a
debt — to update it every time that state changes**. Clear the debt or pay it by not writing the
state down, by deriving it, or by a `FAIL-LOUD` guard, and never pay it with memory, meaning
correction after the fact.

### Memory, the solved log, and the backlog (special cases)
- **Auto memory is machine-local** — the official documentation says it is not shared across machines
  and involves no implicit learning. Use it freely as a disposable scratchpad for Claude's working
  context, but anything that has to be shared or carried elsewhere belongs in a git-tracked document,
  such as the project `CLAUDE.md` or a committed file.
- **The solved log is the exception to "no state"** — it is an append-only lesson registered *after*
  the problem is finished, so it is not current state.
- **Issues and backlogs are not tracked.** A must-keep backlog is delegated to the project's real
  tracker, such as GitHub Issues with its automatic closing — never create a hand-maintained backlog
  file, because it rots the way an "unsolved" list does. A 🔴, which marks something that needs a
  user decision, is surfaced immediately.

### Applying this — classification, not a sweep (when you write or delete a document)
This is not "audit every related document after an action", which depends on memory, but a local
decision about **the single document you are touching**.
1. What type is it? (See the table above.)
2. Does it hold state? If the type must not hold state, take it out and move it to the home for
   state. If the type may hold it, keep it in that one place only.
3. Is it a handoff? Then drive it into its permanent home and delete it.
4. Can derivation replace it? Then do not write it down; point at the truth in the code or the
   infrastructure.
5. Does a drift guard exist for this type? If not, recommend adding one to the project
   (`FAIL-LOUD`).

### The document map (kept light)
A project may keep a map from each concern to the SSOT document that owns it (the norm-and-index
type). **A hand-maintained map is itself one more thing that drifts**, so keep only light pointers and
replace them with derivation where you can. Before creating a new document, check first whether it
could belong to an existing SSOT (`SIMPLE` and YAGNI — this is how document sprawl is prevented).

## How a document is reviewed (the method behind the documentation row of `Verification Layer` — owned here)
After writing or revising an ordinary document, call two lenses — `reviewer-grounding` (is it true
and accurate) and `reviewer-fit` (does it fit the form and the contract) — each as its own
**read-only subagent**, so the document gets a review by someone other than its author (self-editing
alone is not the end of it). The caller injects the source into each lens (the facts to verify and
the contract to hold to), each lens returns its findings as JSON, and the main session is what
applies them. Unlike a spec or a plan there is no marker gate here, so this nudges without blocking.
