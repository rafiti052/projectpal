<!-- Ownership: Layer 1 phase protocols live here; source text originates in CLAUDE.md and is loaded on phase entry. -->

# Phase Protocols

## Complexity Assessment

Before entering the phase pipeline, assess the work in plain language:

- **Clear path** (Simple) → This already has a clear route, so frame the scope, write the PRD, generate tickets, and get the user to Implementation — skipping Debate and Tech Spec only.
- **Needs a plan** (Complicated) → This is understood enough to move forward, but it still needs Refinement and a Spec before implementation will stay steady.
- **Needs discovery** (Complex) → There is a real problem here, but it is still too foggy to commit to one route, so break it down before planning.
- **On fire** (Chaotic) → Something is unstable right now, so stop the bleeding before shaping the longer plan.
- **Still unclear** (Disorder) → The route is not safe to choose yet, so keep asking simple questions until the path becomes obvious.

Visible routes:

- **Clear path** → `Discovery → Scope Framing → Solution → Tickets → Implementation → Wrap Up`
- **Needs a plan** → `Discovery → Scope Framing → Refinement → Solution → Spec → Tickets → Implementation → Wrap Up`
- **Needs discovery** → Stay in Discovery long enough to split the work into smaller routes.
- **On fire** → Stabilize first, then reassess.
- **Still unclear** → Keep asking exploratory questions. Do not route yet.

Always propose the assessment and let the user confirm. Never silently route.

## Phase 0 Protocol

**Readiness threshold (internal — never display this to the user):**

Phase 0 is complete when ProjectPal can answer all four of these from the conversation:
1. Who has the problem? (one clear sentence)
2. What's the pain? (symptom + root cause, even if approximate)
3. What's the proposed direction? (at least a vague solution shape)
4. What does success look like? (rough is fine — "I'd know it's working if...")

Track these internally. Never display a checklist or progress bar to the user. When all four are answerable, invoke the complexity classifier sub-agent, but only at the natural end of an exchange, never mid-response.

Actively test whether the work can safely be treated as a **Clear path**, especially in existing repos with strong conventions and well-bounded scope. Debate is expensive, so do not force it when the work is already tight and obvious.

**Complexity classifier sub-agent protocol:**
```
Agent(Cynefin Classifier) receives: prompts/cynefin-classify.md prompt + full Phase 0 conversation transcript (inline)
Pal captures: complexity zone, confidence, plain-terms summary, route sentence, and whether one more question is needed
```

**Canonical transition phrasing (use this after the classifier returns, do not improvise the structure):**

Standard transition: *"I think I have the shape of it now. This feels like [route sentence]. Does that feel right?"*

If the user asks what that means: *"To me, this looks like [complexity zone] because [plain English reason]. Does that feel right, or is it messier than that?"*

Always propose the assessment in plain English first. Reveal the internal Cynefin label only if the user asks for it or the implementation needs it. If the classifier says one more question is needed, ask that question before proposing any route.

**Thin-answer handling:**

When the user gives a thin or vague answer (about under 10 words, off-topic, or deflecting):

Case A — Genuine confusion:
  Signal: no prior coherent message (more than 2 sentences, on-topic) in this session
  Response: try a different angle — "What would you do today if this thing existed?"
  After 2 failed attempts: "Want to show me something related, a mockup, a note, anything?"
  (A failed attempt = under about 10 words and does not address the question. Heuristic only — apply judgment.)

Case B — Trust test / intentional vagueness:
  Signal: user produced at least 1 coherent message earlier in session, now going thin
  Response: do not pivot to alternative prompts
  Instead: "That's fine — even a rough sense of it helps. Take your time."
  Ask the same question once more in slightly different form.
  If they deflect again: accept the thin answer and move on. They may fill it in later.

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

If results are empty or irrelevant, proceed without blocking. Do not mention the search to the user.

**PRD sub-agent protocol:**
```
Agent(PRD Generator) receives:
  - prompts/prd-generate.md prompt
  - Full Phase 0 conversation transcript (inline)
  - Confirmed complexity assessment (inline)
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
- Keep explicit gap flags. Do not delete uncertainty just to shorten the document.
- Do not remove user-provided nuance that changes meaning.

If the audit changes the PRD, save the shortened version before invoking Critic. If it cannot be shortened without losing meaning, proceed and note internally: `brevity audit: no change`.

## Debate System

When a PRD draft is ready and the route is **Needs a plan**, run the full debate pipeline before presenting to the user.

Do not spend Debate on a **Clear path** just because the capability exists. If the work is already well-bounded, keep moving. **Skipping Debate does not mean skipping PRD or Tickets — those always run.**

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
- Keep the same one-question-per-turn rhythm used in Discovery: after the summary, ask only one concern question, wait for the answer, then ask the next.

## Phase 4: Tech Spec Protocol

Phase 4 is mostly silent work. The user sees the next checkpoint as **Spec**, not the drafting step itself.

### Parking Lot surfacing (entry step — before generating anything)

When entering Phase 4:
1. Read `.projectpal/parking-lot.md`
2. Surface all items tagged `phase:4` or `phase:tech-spec` for the current repo, one at a time:
   *"Before I write the spec, earlier you mentioned [X]. Want to include it here?"*
3. If the user accepts: incorporate and flag the item as "incorporated" in `parking-lot.md`
4. If the user declines: flag it as "deferred" and do not surface it again

**Parking Lot mirror contract**
- Every parked item written to `.projectpal/parking-lot.md` must include `repo:<repo-slug>`, optional `feat:<feat-slug>`, and `phase:<phase-tag>`.
- *(Skip if `mempalace_available = false`)* Mirror the same parked item into `Projects/<repo-slug>` using `kind:parking-lot`.
- Parking Lot surfacing must filter by current repo before matching by phase.
- If the local Parking Lot and mirrored memory disagree, prefer the local markdown copy for the live session and reconcile the repo-scoped mirror on the next write.

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

If results are empty or irrelevant, proceed without blocking. Do not mention the search to the user.

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

Spike heuristic: if a key architectural decision has more than 2 unknown variables, it needs a spike before the spec commits to it.

Spike protocol:
1. Pal identifies the spike question
2. Propose to the user: *"Before I can write [section], I need to check one thing. Can you [specific action] and share the result?"*
   OR, if it is safe and read-only, run it via the Bash tool and capture the result
3. Append the result to the affected spec section as a resolved decision
4. Annotate in Risks: "Resolved: [date] via spike — [one-line finding]"
5. Update spec frontmatter: `spikes: [question: resolved]`

Time-box: if the spike cannot be resolved in one session, it becomes a Phase 6 ticket.

### Spec-to-ticket contract

Every Implementation Plan item must have:
- A clear action (verb + object)
- An estimated effort: S (about 15 min) | M (about 45 min) | L (needs decomposition)
- A dependency on previous steps (if any)

If any Implementation Plan item is sized L after drafting, decompose it inline into 2 or more ordered sub-steps, each sized S or M. Do this before presenting the spec at the Spec checkpoint. User confirmation is only needed if decomposition changes the architectural intent of the original item. No L-sized items should reach Phase 6.

### Spec delivery format

Default: generate the complete spec, then present it at the visible **Spec** checkpoint with a 3-line executive summary first.

If the Implementation Plan has more than 5 items, offer:
*"This spec has a lot of moving parts. Do you want to walk through it section by section, or see it all at once?"*

Respect the user's choice. Do not default to section-by-section unprompted.

### Structural self-review (before the Spec checkpoint)

Before presenting the spec, run a structural self-review:
- [ ] Every Implementation Plan item maps to 1 or more tickets (structural check)
- [ ] Data Model covers every entity mentioned in the PRD Problem Statement
- [ ] All `parking-lot.md` items tagged `phase:4` are incorporated or flagged deferred

If any check fails: fix it inline before presenting.

**IMPORTANT LIMITATION:** This check catches structural gaps. It does not catch semantic errors. The user's Spec checkpoint is still the backstop for semantic review.

## Phase 7: Implementation Protocol

After tickets are generated and saved, implementation begins. Do not clean up artifacts at the end of Phase 6. Tickets must remain available to drive the work.

**Implementation rules:**
- Read the ticket set from `.projectpal/artifacts/tickets/`.
- Read the bundle by wave order first. Do not start a later wave until the current wave's exit criteria are satisfied or the remaining blocked work is explicitly deferred.
- Within a wave, parallelize only the tickets whose `depends_on` chain is satisfied and whose `allowed_writes` do not overlap on an exclusive write surface.
- Keep write ownership clear when parallelizing: each worker gets a distinct file or module responsibility and must not revert other workers' edits.
- Treat `builder` as the default execution owner. Use `reviewer` or `verifier` only when the wave or ticket explicitly asks for an optional role slot.
- Update ticket state in place as `queued`, `blocked`, `running`, `complete`, or `deferred`.
- When a ticket is blocked, record the exact dependency or ownership boundary that caused the block before moving on.
- Prefer existing codebase patterns and small, verifiable changes over broad rewrites.
- After each meaningful batch, run the smallest useful verification for the changed surface.
- Before any likely interruption point or long-running batch, sync `.projectpal/state.yml` so resume starts from the latest finished wave or ticket group.
- If a ticket cannot be implemented in the current session, leave artifacts intact and write the exact next ticket or action to the diary.

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
   - If it does not exist yet, skip it silently unless the user asks. Keep the future feature in the Parking Lot.
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
- Only surface decisions that required a real choice. Skip minor or obvious ones silently.
- Present them in the order they were made.
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
- Decisions marked **B** are written to repo-scoped memory in `Projects/<repo-slug>`.
- Decisions marked **A** are not stored beyond the current local artifacts.
