# Discipline (Team Principles)

These apply to every task, always. This file is the **single source of truth**. The
disciplined-coder plugin keeps a copy at `~/.claude/disciplined-coder/` and injects it into every
project through the `@import` lines in the managed block of `~/.claude/CLAUDE.md`; it never writes
anything into a project folder. Do not edit the copy under `~/.claude` — every session refreshes it
from this original.

Each principle is referenced by a short ID such as `SSOT`. For how they rank against each other,
see `NO-PRIORITY`.

## Principles (referenced by ID, alphabetical)

- **`CLEAR-COMM` (clear communication)** — Reply to the user in Korean. The prose rules for that
  Korean output are the block below, and they are part of this principle. Never hand over a bare
  conclusion: give the reasoning and the alternatives you rejected. Do not skip steps. Where a
  judgement call is needed, ask a precise question instead of guessing quietly. Write for the
  reader — conclusion first, reasoning and principle after, so someone who stops early still has the
  answer (progressive disclosure). One idea per sentence, short paragraphs. Gloss domain jargon each
  time it appears; do not assume the reader knows the field. Prefer the answer that is least tiring
  to read over the answer that is shortest, and never compress to save tokens. Keep the reader
  moving: vary sentence length, and break a long answer with subheadings. **Do not refer to things by
  number** — say "the Codex double-injection fix" rather than `R6`, `Task 3`, or `case 18`. Numbers
  drift silently the moment an item is inserted or removed, and they tell the reader nothing. This
  applies to requirements in a spec, tasks in a plan, and sections in a document alike. An identifier
  inside code follows local convention (`SIMPLE`), but where that name reaches a human-readable log
  or output, use a name there too.

  <!-- korean-style-rules: start -->
  이 블록이 한국어인 이유는 여기 규칙이 한국어 산문의 어미와 리듬을 판정하기 때문이다. 영어로 옮기면
  규칙이 가리키는 대상 자체가 사라진다. 다음에 재작성할 때 번역하지 마라 — 규칙 설명도 예시도 한국어로
  둔다.

  - 사용자에게는 한국어로 답한다.
  - 출력은 완결된 문어체(서술형 '~한다/~이다')로 통일한다 — CLI 답변·문서·외부 게시 어디서나, 그리고
    **스펙·표·커밋 메시지·요약 같은 구조화된 산출물에서도 예외가 없다(거기서 가장 자주 무너진다).**
  - 'A vs B'·'수동 vs 자동'처럼 선택지를 명사 조각으로 나열하지 말고 'A로 할지 B로 할지'처럼 완결된
    문장으로 묻는다.
  - 'X = Y'·'원인 → 해결'처럼 기호로 문장을 대신하지 않는다(화살표·슬래시를 문장 안 보조로 쓰는 것은
    괜찮다).
  - '미배선'·'확정?'처럼 명사 조각이나 말끝 흐림으로 끝내지 않는다.
  - 표를 쓰더라도 셀은 암호 같은 조각이 아니라 알아볼 수 있는 문장이나 구로 채운다.
  - 문어체이되 딱딱한 격식이 아니라 읽기 편하게가 목표다.
  - 나쁜 예는 "리뷰 실패 거동 — v1=미노출 확정?"이고, 고친 예는 "리포트 생성이 실패하면 결과를 숨길지,
    아니면 검증 실패 표시를 붙여 보여줄지 정해야 한다."이다.
  <!-- korean-style-rules: end -->

- **`EXPLICIT` (explicitness, least surprise)** — No hidden magic in code or behaviour. If something
  happens, its intent shows in a name, a type, or a contract. Pass the context a reader needs
  explicitly rather than letting it leak in implicitly, so nobody has to open the internals to learn
  what a thing does.

- **`FAIL-LOUD` (no silent failure)** — When something goes wrong, break immediately and visibly.
  Never swallow a contract violation or drift (config that has diverged from code) and carry on. Let
  structure — invariants, generated config, explicit contracts — prevent the mistake or expose it,
  rather than relying on the author remembering correctly. Robustness beats author precision.

- **`FOCUSED` (one job, orthogonality)** — A unit does one thing. Design dependencies so a caller can
  use the interface without knowing the internals. Keep unrelated things independent, so changing one
  place does not break another. A file growing fat is a sign that one unit is doing several jobs;
  split it.

- **`IDEMPOTENT`** — Scripts, migrations, and setup steps reach the same state safely no matter how
  many times they run. Skip what is already done, and make sure a second run creates no duplicate and
  no corruption.

- **`MEASURE-FIRST`** — Check before you assume. The environment, the data, and the actual behaviour
  may differ from your model of them, so look at the real state before touching it; work built on a
  guess is usually wasted. Volatile facts especially — current state, whether something is deployed,
  whether a feature exists — are derived from the truth (code, infrastructure, the user's latest
  word) rather than read off a document. A status document is a cache of the truth, not the truth.

- **`NO-PRIORITY`** — These principles carry no ranking and no order. This is an alphabetical
  glossary addressed by ID, with no numbers and no groups, and a principle's position on the page
  means nothing. Apply every principle that fits the situation.

- **`REVERSIBLE`** — Prefer decisions you can undo. Favour the two-way door you can walk back
  through, make a one-way door deliberately, and record why you chose it.

- **`SECRETS`** — Real secrets (keys, tokens, passwords) stay backend-only and never reach the
  client; ship the client non-secret identifiers instead. Keep secrets and personally identifying
  information out of prompts and logs too.

- **`SIMPLE` (simplicity, YAGNI)** — Do not build a generalisation or an abstraction you do not need
  yet. Start with the simplest thing that works and add complexity only when it is genuinely
  required. Do not grow a job that a single call handles into an agent system — weigh the latency and
  the cost that buys.

- **`SSOT` (single source of truth)** — One fact, one setting, one decision lives authoritatively in
  exactly one place. Everywhere else references it or derives from it rather than copying it. The
  moment a human has to keep two places in sync by hand, the two diverge.

- **`SURGICAL` (touch only what the request needs)** — Change only the lines the request reaches. Do
  not refactor, tidy, or reformat working code around them. Flag dead code you find rather than
  deleting it, and remove only what your own change made unnecessary.

- **`TDD` (test first)** — Write the failing test first. Fix a verifiable success criterion for what
  "done" means before you start, and work until that criterion turns green. Never claim something
  works without execution evidence.

## Environment convention (not a universal principle)

- **`DOCKER-FIRST`** — Where a Docker environment exists, run in the same container as production
  rather than directly on the host, and fall back to local execution only when there is no Docker.
  This is a convention of this environment, not a universal principle.

## Cross-project gotchas

- **`.gitignore` has no inline comments** — git reads a trailing `# comment` as part of the pattern,
  so `*.log  # ignore logs` tries to ignore a file literally named that and does nothing useful. Put
  the comment on its own line.

- **Mocks and real clients disagree about `None`** — a test double usually returns an empty `{}` or
  `[]` for an empty result while the real SDK may return `None`, so the test passes and production
  raises `AttributeError` on `None.something`. Guard with `x or {}` and `x or []`, and do not let a
  test double weaken the production contract that an empty result is `None`.

- **No magic numbers in test expectations** — never pin an expected count such as "reach PASS=K".
  Every check added or removed would force a human to correct the number, which violates `SSOT`.
  Verify the contract as an invariant (`FAIL=0`) and let the test count for itself.

## Procedures (separate from the principles — run them when the trigger fires)

> This section holds only *when* and *what*, as a trigger index. The *how* lives in each caller
> skill, which owns it, so that what is always loaded stays light.

### Verification Layer

Never let an LLM-produced result stand as a lone conclusion, whether it is product output or Claude's
own design document. Add review in proportion to the risk. The trigger decides which reviewer
applies.

| Trigger (when) | What gets verified | Caller | How it is enforced |
|---|---|---|---|
| The product calls an LLM at runtime | The product's LLM output | `domain-llm-runtime` | Implemented in product code |
| Writing a spec | Claude's design document | `domain-spec-review` | A hook enforces it |
| Writing a plan | Claude's plan document | `domain-spec-review` | A hook enforces it |
| Writing documentation such as a README | Claude's document | `reviewer-grounding` plus `reviewer-fit` (the method lives in `domain-docs`) | A hook suggests and nudges |
| Authoring or running a multi-agent workflow that produces findings or conclusions | The workflow agents' findings and conclusions | `reviewer-*` lens skills (the workflow's verification step derives its lenses from SKILL.md — never rewrite them ad hoc) | This always-loaded principle plus the ultracode review mode, which `/ultracode-review` toggles |

The *method* behind each row belongs to the skill named in the caller column — open that skill. It is
not duplicated here in the always-loaded text.

### Design Inputs

When you design or plan, check whether what you are about to build is covered by the domain reference
index. If it is, open that reference and fold "what it ought to be" into the spec; when something
cannot go into the spec, weigh it during implementation instead. This is requirements gathering, not
verification.

### Solved Log

disciplined-coder **does not track issues or a backlog** — its job is work quality, not state or
issue management, which is out of scope. Subagents read this too, so each role is stated plainly.

- **The solved log is a mistake notebook.** Once you have **finished** a problem, record the lesson
  in `solved_problems.md`. Because it is written after the fact it is not "state", which makes it the
  one exception to "no state in documents". The entry format is defined in that log's own preamble,
  which owns it.
- **Route by scope.** A machine-wide lesson goes to the PC log, a project quirk goes to that repo's
  `docs/solved_problems.md`, and a universal lesson is rewritten upward into these principles. If a
  project-specific lesson has nowhere to go because `docs/solved_problems.md` does not exist, create
  the file at that moment — never in advance, since an empty log teaches nothing when recall fires.
- **Rewrite an entry when its fix changes.** Append a new problem at the bottom, but when the fix for
  an existing entry changes, edit that entry so an old prescription and a new one never sit side by
  side. Record why it changed in the spec.
- **Decisions and preferences belong in a spec, not in solved.** The solved log holds only problems
  that actually happened and how they were fixed.
- **Recall before you start.** Before debugging or implementing, look for a similar symptom in
  **both** the PC log and the project log, and derive the project log from the file existing at
  `docs/solved_problems.md` whether or not anything points at it — so recall still works after
  `/init` overwrites a project CLAUDE.md pointer.
- **Dispose of open items instead of tracking them.** Never keep a hand-maintained list of
  unresolved things, because it rots. There are four disposals. ① Do it now if it is small enough,
  which needs no issue at all. ② For a must-keep you are deferring, follow the current disposition
  mode: under `surface` (the default) it goes into memory as a machine-local working note and is
  surfaced to the user, and under `issues` (opt-in) it is delegated to an auto-closing tracker such
  as GitHub Issues (`/issue-mode` toggles this, and the current mode is injected at session start).
  ③ Surface a 🔴 immediately, as the next bullet says. ④ Surface any other minor item once and drop
  it, letting it go on purpose — what was never written down cannot rot, and anything that matters
  will resurface through later work or an audit. Even `issues` mode only *delegates* must-keeps to an
  external tracker; disciplined-coder still does not track them as state.
- **A 🔴 is surfaced, never stored.** A 🔴 marks something that needs a user decision, so it goes
  straight to the user rather than into memory, and nobody implements it autonomously. If it has to
  be kept, the user files it in a tracker.
- **Only the main session writes to solved**, which avoids concurrent-write corruption. Subagents
  report findings and lessons in their return value, and the main session merges, deduplicates, and
  records them.

### Document Hygiene

State and documents are not kept correct by remembering to update them — that is exactly how they
break (`FAIL-LOUD`). So do not defend against drift with maintenance; build things so that going
stale is impossible in the first place. State that was never written cannot rot, and a handoff
already deleted cannot compete. The trigger is not "audit everything after an action" but **the
moment you write or delete a document**.

- **Classify the type first.** When you touch a document, decide what it is — state, procedure or
  contract, design, handoff, issue, context, or norm. The prescription follows from the type, not
  from memory. **The per-type prescriptions, the lifetime table, and the drift guards (a single home
  for state, derivation over transcription, deleting a handoff immediately, keeping memory
  machine-local, what a project enforces) are owned by `domain-docs`** — open that skill rather than
  restating it in always-loaded text.
- **A fact is not a judgement.** Automation and hooks record only what can be derived, such as
  "pushed" or "tests passed". "Done" is a judgement bound to a success criterion (`TDD`), so surface
  it with its evidence instead of asserting it in prose.

### Parallel Orchestration

When two or more independent units of work each carry their own plan, implement, and review loop — a
**multi-task plan** — do not run them one after another in a single session. Consider a three-tier
arrangement (orchestrator, then sub-orchestrators, then workers and reviewers) that delegates each
spec to its own sub-orchestrator in an isolated worktree. When a unit is a **single task**, three
tiers are pure overhead, so use `dispatching-parallel-agents` and its two tiers instead. The human
bottleneck sits in the spec phase, so the natural shape is a pipeline that locks specs one at a time
and fans out the moment one locks. The *how* — routing, dispatch templates, guardrails, and
resumption — is owned by the `nested-orchestration` skill, and only the trigger lives here.
