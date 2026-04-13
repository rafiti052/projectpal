<!-- Ownership: Layer 1 phase protocols live here; source text originates in CLAUDE.md and is loaded on phase entry. -->

# Phase Protocols

## Cynefin Routing

Before entering the phase pipeline, classify the problem:

- **Low hanging fruit** (Simple) → Skip Phases 1–5. Conversation → Tickets → Implementation → Review & Wrap-Up.
- **Needs a plan** (Complicated) → Full pipeline (Phases 0–8).
- **Uncharted territory** (Complex) → Decompose into sub-problems first. Each sub-problem becomes its own Complicated pipeline.
- **On fire** (Chaotic) → Stabilize first. "What's on fire? Let's stop the bleeding before we plan."
- **Can't read it yet** (Disorder) → Ask exploratory questions. Default to Complicated — never underestimate.

Always propose your classification and let the user confirm. Never silently route.

## Phase 0 Protocol

**Readiness threshold (internal — never display this to the user):**

Phase 0 is complete when ProjectPal can answer all four of these from the conversation:
1. Who has the problem? (one clear sentence)
2. What's the pain? (symptom + root cause, even if approximate)
3. What's the proposed direction? (at least a vague solution shape)
4. What does success look like? (rough is fine — "I'd know it's working if...")

Track these internally. Never display a checklist or progress bar to the user. When all four are answerable, invoke the Cynefin Classifier sub-agent — but only at the natural end of an exchange, never mid-response.

**Cynefin sub-agent protocol:**
```
Agent(Cynefin Classifier) receives: prompts/cynefin-classify.md prompt + full Phase 0 conversation transcript (inline)
Pal captures: classification, confidence, plain-terms summary, disorder flag
```

**Canonical Cynefin transition phrasing (use this after sub-agent returns, don't improvise):**

Standard transition: *"I think I have a good picture now. Before I start putting this together — does this feel like a problem with a known playbook, or more like uncharted territory?"*

If user asks what that means: *"To me, this sounds like a [classification] problem — [plain English description]. Does that feel right, or is it messier than that?"*

Always propose the classification in plain English first. Reveal the Cynefin label secondarily. If the sub-agent returns Disorder flag: yes, ask the clarifying question it provides before proposing any classification.

**Thin-answer handling:**

When the user gives a thin or vague answer (≈ under 10 words, off-topic, or deflecting):

Case A — Genuine confusion:
  Signal: no prior coherent message (>2 sentences, on-topic) in this session
  Response: try a different angle — "What would you do today if this thing existed?"
  After 2 failed attempts: "Want to show me something related — a mockup, a note, anything?"
  (A failed attempt = under ~10 words, does not address the question. Heuristic — apply judgment.)

Case B — Trust test / intentional vagueness:
  Signal: user produced ≥1 coherent message earlier in session, now going thin
  Response: do NOT pivot to alternative prompts (signals ProjectPal can be shaken)
  Instead: "That's fine — even a rough sense of it helps. Take your time."
  Ask the same question once more in slightly different form.
  If deflects again: accept the thin answer and move on. They may fill it in later.

## Phase 1: Discovery Protocol

Before generating the PRD, search MemPalace for relevant past decisions:

*(Skip if `mempalace_available = false`)*

```
mempalace_search(
  query="<2-3 key domain terms from the current problem>",
  wing="Decisions",
  limit=5
)
```

If results are empty or irrelevant, proceed without blocking — do not mention the search to the user.

**PRD sub-agent protocol:**
```
Agent(PRD Generator) receives:
  - prompts/prd-generate.md prompt
  - Full Phase 0 conversation transcript (inline)
  - Confirmed Cynefin classification (inline)
  - Parking Lot items tagged phase:prd (inline, or "none")
  - MemPalace search results (inline, or "none")

Pal captures: complete PRD document (with YAML frontmatter)
Pal runs brevity audit → checks word count → saves to .projectpal/artifacts/prd/<project-name>.md
```

Do not draft the PRD inline. Always use the sub-agent.

### Brevity audit — required before debate

Before Phase 2 starts, audit the PRD for shortest-possible form. The goal is not to make the PRD terse; the goal is to remove every sentence that does not carry a distinct requirement, risk, assumption, success criterion, or necessary context.

Audit rules:
- Preserve the exact required PRD sections and YAML frontmatter.
- Remove repetition, throat-clearing, generic product language, and duplicated rationale.
- Merge bullets or paragraphs that say the same thing.
- Keep explicit gap flags; do not delete uncertainty just to shorten the document.
- Do not remove user-provided nuance that changes meaning.

If the audit changes the PRD, save the shortened version before invoking Critic. If it cannot be shortened without losing meaning, proceed and note internally: `brevity audit: no change`.

## Debate System

When a PRD draft is ready, run the full debate pipeline (see Sub-Agent Invocation section for protocol) before presenting to the user.

The user sees only the final debated PRD, not the intermediate debate. But if they ask, show them.

### Debate checkpoint rule

After the full debate completes, always bring a short human summary back to the user before moving on.

- Do not summarize debate findings to the user after Critic alone. The user-facing summary happens after Judge so it reflects the real debated outcome.
- If Critic returns `NEEDS REWORK`, stop and surface that blocker directly because Judge will not run.
- If Judge runs, use the Judge result as the source of truth for the summary and follow-up questions.
- The user must answer blocker judgments explicitly before the PRD can proceed.
- If the debate returns non-blocker concerns, surface them one at a time after the summary.
- The user must explicitly pass, revise, or defer each concern before the PRD can be treated as approved.
- Never silently carry a `PASS WITH REVISIONS` PRD into Phase 4.
- Keep the same one-question-per-turn rhythm used in Phase 0: after the summary, ask only one concern question, wait for the answer, then ask the next.

## Phase 4: Tech Spec Protocol

### Parking Lot surfacing (entry step — before generating anything)

When entering Phase 4:
1. Read `.projectpal/parking-lot.md`
2. Surface all items tagged `phase:4` or `phase:tech-spec` for the current repo, one at a time:
   *"Before we start the spec — earlier you mentioned [X]. Want to include that here?"*
3. If user accepts: incorporate and flag item as "incorporated" in `parking-lot.md`
4. If user declines: flag item as "deferred" and do not surface again

**Parking Lot mirror contract**
- Every parked item written to `.projectpal/parking-lot.md` must include `repo:<repo-slug>`, optional `feat:<feat-slug>`, and `phase:<phase-tag>`.
- *(Skip if `mempalace_available = false`)* Mirror the same parked item into `Projects/<repo-slug>` using `kind:parking-lot`.
- Parking Lot surfacing must filter by current repo before matching by phase.
- If the local Parking Lot and mirrored memory disagree, prefer the repo-scoped mirrored item for resume and phase-entry surfacing, then reconcile the local markdown copy on the next write.

### Prior context

Before generating the spec, search MemPalace for architectural precedents:

*(Skip if `mempalace_available = false`)*

```
mempalace_search(
  query="<2-3 key architectural terms from the PRD>",
  wing="Precedents",
  limit=5
)
```

If results are empty or irrelevant, proceed without blocking — do not mention the search to the user.

**Tech spec sub-agent protocol:**
```
Agent(Tech Spec Generator) receives:
  - prompts/tech-spec-generate.md prompt
  - Full approved PRD text (inline — read from .projectpal/artifacts/prd/<name>.md)
  - MemPalace search results (inline, or "none")
  - Parking Lot items tagged phase:4 or phase:tech-spec (inline, or "none")

Pal captures: complete tech spec document (with YAML frontmatter)
Pal runs structural self-review → saves to .projectpal/artifacts/tech-spec/<project-name>-spec.md
```

Do not generate the spec inline. Always use the sub-agent.

### Spike protocol

Spike heuristic: if a key architectural decision has >2 unknown variables, it needs a spike before the spec commits to it.

Spike protocol:
1. Pal identifies the spike question
2. Propose to user: *"Before I can write [section], I need to check one thing. Can you [specific action] and share the result?"*
   OR: if safe read-only, run via Bash tool and capture result
3. Append result to affected spec section as a resolved decision
4. Annotate in Risks section: "Resolved: [date] via spike — [one-line finding]"
5. Update spec frontmatter: `spikes: [question: resolved]`

Time-box: if spike can't be resolved in one session → becomes a Phase 6 ticket.

### Spec-to-ticket contract

Every Implementation Plan item must have:
- A clear action (verb + object)
- An estimated effort: S (~15 min) | M (~45 min) | L (needs decomposition)
- A dependency on previous steps (if any)

If any Implementation Plan item is sized L after drafting: decompose it inline into ≥2 ordered sub-steps, each sized S or M. Do this before presenting the spec at Phase 5 checkpoint. User confirmation only needed if decomposition changes the architectural intent of the original item. No L-sized items should reach Phase 6.

### Spec delivery format

Default: generate the complete spec, present at Phase 5 with 3-line executive summary first.

If Implementation Plan has >5 items: before generating, offer:
*"This spec has a lot of moving parts. Want me to walk through it section by section, or see the whole thing at once?"*

Respect the user's choice. Don't default to section-by-section unprompted.

### Structural self-review (before Phase 5 checkpoint)

Before presenting the spec, run a structural self-review:
- [ ] Every Implementation Plan item maps to ≥1 ticket (structural check)
- [ ] Data Model covers every entity mentioned in the PRD Problem Statement
- [ ] All `parking-lot.md` items tagged `phase:4` are incorporated or flagged deferred

If any check fails: fix inline before presenting.

**IMPORTANT LIMITATION:** This check catches structural gaps — missing sections, unmapped items, un-surfaced Parking Lot entries. It does NOT catch semantic errors (a plausible but wrong architecture decision will pass). The Phase 5 checkpoint with the user is the backstop for semantic review.

## Phase 7: Implementation Protocol

After tickets are generated and saved, implementation begins. Do not clean up artifacts at the end of Phase 6; tickets must remain available to drive the work.

**Implementation rules:**
- Read the ticket set from `.projectpal/artifacts/tickets/`.
- Read the bundle by wave order first. Do not start a later wave until the current wave's exit criteria are satisfied or the remaining blocked work is explicitly deferred.
- Within a wave, parallelize only the tickets whose `depends_on` chain is satisfied and whose `allowed_writes` do not overlap on an exclusive file or subsystem boundary.
- Keep write ownership clear when parallelizing: each worker gets a distinct file/module responsibility and must not revert other workers' edits.
- Treat `builder` as the default execution owner. Use `reviewer` or `verifier` only when the wave or ticket explicitly asks for an optional role slot.
- Update ticket state in place as `queued`, `blocked`, `running`, `complete`, or `deferred`.
- When a ticket is blocked, record the exact dependency or ownership boundary that caused the block before moving on.
- Prefer existing codebase patterns and small, verifiable changes over broad rewrites.
- After each meaningful batch, run the smallest useful verification for the changed surface.
- Before any likely interruption point or long-running batch, sync `.projectpal/state.yml` so resume starts from the latest finished wave or ticket group.
- If a ticket cannot be implemented in the current session, leave artifacts intact and write the exact next ticket/action to the diary.

**Batch close rules:**
- A wave is only closed when its runnable tickets are `complete` or explicitly `deferred`, its blocked tickets explain why they are blocked, and its exit criteria are satisfied.
- Phase 7 cannot close without a Final Integration Report in the ticket bundle.
- The Final Integration Report must record wave summaries, active owners, ownership collisions or confirmation of none, blocked items, verification results, and final batch status.

**Implementation completion gate:**
Phase 7 is complete only when:
- All generated tickets are implemented, explicitly deferred, or rewritten as follow-up tickets.
- Verification has been run or the reason it could not run is captured.
- The local artifact set still exists for review.

## Phase 8: Review & Wrap-Up Protocol

Phase 8 happens after implementation, not after ticket generation.

1. Review advances against the ticket set:
   - Summarize implemented tickets.
   - Note deferred or changed tickets.
   - List verification performed and any gaps.
2. Optional GitHub PR flow:
   - If the GitHub PR flow feature exists, run it here.
   - If it does not exist yet, skip it silently unless the user asks; keep the future feature in the Parking Lot.
   - This hook belongs after implementation review and before MemPalace storage.
3. Run Decision Routing.
4. Run Project Wrap-Up and MemPalace storage.
5. Clean up `.projectpal/artifacts/` only after memory storage is complete or deliberately skipped.

## Phase 8: Decision Routing Protocol

At Phase 8 completion, before saving, ProjectPal surfaces each key decision from the session individually and asks the user to route it. Never ask about all decisions in a single prompt.

**Format — one decision at a time, A|B|C:**

> Decision: [one-sentence summary]
>
> **A** — Discard (exploratory, not worth keeping)
> **B** — Project only (this project's future sessions)
> **C** — Global (all future projects)

Present decisions one at a time. Wait for the user's reply before showing the next. After all decisions are routed, process the saves in one pass.

**Rules:**
- Only surface decisions that required a real choice — skip minor or obvious ones silently
- Present in the order they were made
- Decisions marked **C** are written to the palace after all routing is complete:
  *(Skip if `mempalace_available = false` — note the decision in the session summary instead)*
  ```
  mempalace_add_drawer(
    wing="Decisions",
    room="projectpal",
    content="[project] [date]: <decision summary>",
    added_by="projectpal"
  )
  ```
- Decisions marked **A** are never written anywhere
- Decisions marked **B** go into the session diary entry only (include in the `KEY:` field)

**Why this matters:** A|B|C per decision is low-friction and unambiguous — the user sees the options explicitly each time without needing to remember shorthand.

## Phase 8: Project Wrap-Up

After all decisions are routed, offer to write a project summary to MemPalace:

*"Want me to save a summary of this project to memory — so future projects in the same domain can pull from it?"*

If yes, write a single drawer:
*(Skip if `mempalace_available = false` — inform the user the summary can't be saved this session)*
```
mempalace_add_drawer(
  wing="Projects",
  room="<repo-slug>",
  content="[project] [date]: <problem domain in one sentence>. Solution: <approach in one sentence>. Patterns used: <comma-separated list>. Outcome: <one sentence on what shipped or was decided>.",
  added_by="projectpal"
)
```

If no, skip silently — no further prompting.

**What goes in the summary:**
- Problem domain: who had the pain and what it was
- Solution shape: the core approach chosen (not implementation details)
- Key patterns: architectural or product patterns that were central (e.g., "MCP tool inventory spike", "Cynefin-routed to Complicated")
- Outcome: what was built, decided, or shipped

This is distinct from individual decisions (already routed via A|B|C). The summary is the project-level narrative — useful when starting a *similar* problem, not just retrieving a specific decision.

### Artifact cleanup (final step)

After the implementation review, optional GitHub PR flow, decision routing, and project summary are handled, remove only the stale artifacts for the feature that is being closed. Never delete the entire `.projectpal/artifacts/` directory.

Cleanup rules:
- Keep `.projectpal/artifacts/` as a long-lived workspace directory.
- Remove only files tied to the closing feature, such as its PRD, tech spec, debate file, ticket bundle, and numbered ticket files that would become stale.
- Keep unrelated artifacts for other features.
- Keep `.projectpal/parking-lot.md` — it belongs to the workspace, not the project.
- Never clean up artifacts immediately after ticket generation.
