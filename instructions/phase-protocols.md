<!-- Ownership: Layer 1 phase protocols live here; source text originates in CLAUDE.md and is loaded on phase entry. -->

# Phase Protocols

## Complexity Assessment

Before entering the phase pipeline, assess the work in plain language:

- **Clear path** (Simple) → This already has a clear route, so shape the Brief, generate tickets, and get the user to Implementation — skipping Refinement and Technical Details only.
- **Needs a plan** (Complicated) → This is understood enough to move forward, but it still needs Refinement and Technical Details before implementation will stay steady.
- **Needs discovery** (Complex) → There is a real problem here, but it is still too foggy to commit to one route, so break it down before planning.
- **On fire** (Chaotic) → Something is unstable right now, so stop the bleeding before shaping the longer plan.
- **Still unclear** (Disorder) → The route is not safe to choose yet, so keep asking simple questions until the path becomes obvious.

Visible routes:

- **Clear path** → `Discovery → Brief → Solution → Tickets → Implementation → Wrap Up`
- **Needs a plan** → `Discovery → Brief → Refinement → Solution → Planning → Technical Details → Tickets → Implementation → Wrap Up`
- **Needs discovery** → Stay in Discovery long enough to split the work into smaller routes.
- **On fire** → Stabilize first, then reassess.
- **Still unclear** → Keep asking exploratory questions. Do not route yet.

Always propose the assessment and let the user confirm. Never silently route.

Use only the visible stage names in user-facing copy. Internal artifact ids and worker names stay backstage unless the user explicitly asks how the system works.

## Phase 0 Protocol

**Readiness threshold (internal — never display this to the user):**

Phase 0 is complete when ProjectPal can answer all four of these from the conversation:
1. Who has the problem? (one clear sentence)
2. What's the pain? (symptom + root cause, even if approximate)
3. What's the proposed direction? (at least a vague solution shape)
4. What does success look like? (rough is fine — "I'd know it's working if...")

Track these internally. Never display a checklist or progress bar to the user. When all four are answerable, invoke the complexity classifier sub-agent, but only at the natural end of an exchange, never mid-response.

Actively test whether the work can safely be treated as a **Clear path**, especially in existing repos with strong conventions and well-bounded scope. Refinement is expensive, so do not force it when the work is already tight and obvious.

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

## Phase 1: Brief Protocol

Before generating the internal Brief artifact that powers the user-facing Brief, search MemPalace for relevant past decisions:

*(Skip if `mempalace_available = false`)*

```
mempalace_search(
  query="<2-3 key domain terms from the current problem>",
  wing="Decisions",
  limit=5
)
```

If results are empty or irrelevant, proceed without blocking. Do not mention the search to the user.

**Brief drafting sub-agent protocol:**
```
Agent(Problem Solver) receives:
  - prompts/brief-generate.md prompt
  - Full Phase 0 conversation transcript (inline)
  - Confirmed complexity assessment (inline)
  - Parking Lot items tagged phase:brief (inline, or "none")
  - MemPalace search results (inline, or "none")

Pal captures: complete Brief document (with YAML frontmatter)
Pal runs brevity audit → checks word count → saves to .projectpal/artifacts/brief/<project-name>.md
```

Do not draft the Brief inline. Always use the sub-agent to generate the internal Brief artifact first.

### Brevity audit — required before Refinement

Before Phase 2 starts, audit the Brief for shortest-possible form. The goal is not to make the Brief terse; the goal is to remove every sentence that does not carry a distinct requirement, risk, assumption, success criterion, or necessary context.

Audit rules:
- Preserve the exact required Brief sections and YAML frontmatter.
- Remove repetition, throat-clearing, generic product language, and duplicated rationale.
- Merge bullets or paragraphs that say the same thing.
- Keep explicit gap flags. Do not delete uncertainty just to shorten the document.
- Do not remove user-provided nuance that changes meaning.

If the audit changes the Brief, save the shortened version before invoking the Architect. If it cannot be shortened without losing meaning, proceed and note internally: `brevity audit: no change`.

## Refinement System

When a Brief draft is ready and the route is **Needs a plan**, run the full Refinement pipeline before presenting to the user.

Do not spend Refinement on a **Clear path** just because the capability exists. If the work is already well-bounded, keep moving. **Skipping Refinement does not mean skipping Brief drafting or Tickets — those always run.**

The user sees only the final refined Brief, not the intermediate refinement record. But if they ask, show it.

### Refinement Check-in rule

After the full Refinement pass completes, always bring a short human summary back to the user before moving on.

- Do not summarize refinement findings to the user after the Architect alone. The user-facing summary happens after the Manager so it reflects the real refined outcome.
- If the Architect returns `NEEDS REWORK`, stop and surface that blocker directly because the Manager will not run.
- If the Manager runs, use the Manager result as the source of truth for the summary and follow-up questions.
- The user must answer blocker judgments explicitly before the Brief can proceed.
- If the refinement pass returns non-blocker concerns, surface them one at a time after the summary.
- The user must explicitly pass, revise, or defer each concern before the Brief can be treated as approved.
- Never silently carry a `PASS WITH REVISIONS` Brief into Phase 4.
- Keep the same one-question-per-turn rhythm used in Discovery: after the summary, ask only one concern question, wait for the answer, then ask the next.
- Never narrate backstage steps like the Problem Solver, Architect, or Manager while they run. If progress needs to be shown, reference the visible stage only.

## Phase 4: Planning Protocol

Phase 4 is mostly silent work. The user sees the next Check-in as **Technical Details**, not the drafting step itself.

### Parking Lot surfacing (entry step — before generating anything)

When entering Phase 4:
1. Read `.projectpal/parking-lot.md`
2. Surface all items tagged `phase:4` or `phase:technical-details` for the current repo, one at a time:
   *"Before I write the technical details, earlier you mentioned [X]. Want to include it here?"*
3. If the user accepts: incorporate and flag the item as "incorporated" in `parking-lot.md`
4. If the user declines: flag it as "deferred" and do not surface it again

**Parking Lot mirror contract**
- Every parked item written to `.projectpal/parking-lot.md` must include `repo:<repo-slug>`, optional `feat:<feat-slug>`, and `phase:<phase-tag>`.
- *(Skip if `mempalace_available = false`)* Mirror the same parked item into `Projects/<repo-slug>` using `kind:parking-lot`.
- Parking Lot surfacing must filter by current repo before matching by phase.
- If the local Parking Lot and mirrored memory disagree, prefer the local markdown copy for the live session and reconcile the repo-scoped mirror on the next write.

### Prior context

Before generating the internal technical-details artifact that powers the user-facing Technical Details Check-in, search MemPalace for architectural precedents:

*(Skip if `mempalace_available = false`)*

```
mempalace_search(
  query="<2-3 key architectural terms from the Brief>",
  wing="Precedents",
  limit=5
)
```

If results are empty or irrelevant, proceed without blocking. Do not mention the search to the user.

**Technical Details sub-agent protocol:**
```
Agent(Technical Details Generator) receives:
  - prompts/technical-details-generate.md prompt
  - Full approved Brief text (inline — read from .projectpal/artifacts/brief/<name>.md)
  - MemPalace search results (inline, or "none")
  - Parking Lot items tagged phase:4 or phase:technical-details (inline, or "none")

Pal captures: complete internal Technical Details document (with YAML frontmatter)
Pal runs structural self-review → saves to .projectpal/artifacts/technical-details/<project-name>-technical-details.md
```

Do not generate the technical details inline. Always use the sub-agent.

### Spike protocol

Spike heuristic: if a key architectural decision has more than 2 unknown variables, it needs a spike before the technical details commit to it.

Spike protocol:
1. Pal identifies the spike question
2. Propose to the user: *"Before I can write [section], I need to check one thing. Can you [specific action] and share the result?"*
   OR, if it is safe and read-only, run it via the Bash tool and capture the result
3. Append the result to the affected Technical Details section as a resolved decision
4. Annotate in Risks: "Resolved: [date] via spike — [one-line finding]"
5. Update the Technical Details frontmatter: `spikes: [question: resolved]`

Time-box: if the spike cannot be resolved in one session, it becomes a Phase 6 ticket.

### Planning-to-ticket contract

Every Implementation Plan item must have:
- A clear action (verb + object)
- An estimated effort: S (about 15 min) | M (about 45 min) | L (needs decomposition)
- A dependency on previous steps (if any)

If any Implementation Plan item is sized L after drafting, decompose it inline into 2 or more ordered sub-steps, each sized S or M. Do this before presenting the technical details at the Technical Details Check-in. User confirmation is only needed if decomposition changes the architectural intent of the original item. No L-sized items should reach Phase 6.

### Technical Details delivery format

Default: generate the complete technical details artifact, then present it at the visible **Technical Details** Check-in with a 3-line executive summary first.

If the Implementation Plan has more than 5 items, offer:
*"These technical details have a lot of moving parts. Do you want to walk through them section by section, or see them all at once?"*

Respect the user's choice. Do not default to section-by-section unprompted.

### Structural self-review (before the Technical Details Check-in)

Before presenting the technical details, run a structural self-review:
- [ ] Every Implementation Plan item maps to 1 or more tickets (structural check)
- [ ] Data Model covers every entity mentioned in the Brief Problem Statement
- [ ] All `parking-lot.md` items tagged `phase:4` are incorporated or flagged deferred

If any check fails: fix it inline before presenting.

**IMPORTANT LIMITATION:** This check catches structural gaps. It does not catch semantic errors. The user's Technical Details Check-in is still the backstop for semantic review.

## Phase 7: Implementation Protocol

After tickets are generated and saved, implementation begins. Do not clean up artifacts at the end of Phase 6. Tickets must remain available to drive the work.

**Implementation rules:**
- Read the ticket set from `.projectpal/artifacts/tickets/`.
- Read the bundle by wave order first. Do not start a later wave until the current wave's exit criteria are satisfied or the remaining blocked work is explicitly deferred.
- Treat `begin_thread` as the ownership gate for thread-local orchestration: the first assistant in a thread sets `primary_assistant`, and every later entry to that same thread preserves the existing owner instead of silently reassigning it.
- Within a wave, parallelize only the tickets whose `depends_on` chain is satisfied and whose `allowed_writes` do not overlap on an exclusive write surface.
- Keep write ownership clear when parallelizing: each worker gets a distinct file or module responsibility and must not revert other workers' edits.
- Treat `builder` as the default execution owner. Use `reviewer` or `verifier` only when the wave or ticket explicitly asks for an optional role slot.
- Update ticket state in place as `queued`, `blocked`, `running`, `complete`, or `deferred`.
- When a ticket is blocked, record the exact dependency or ownership boundary that caused the block before moving on.
- Prefer existing codebase patterns and small, verifiable changes over broad rewrites.
- After each meaningful batch, run the smallest useful verification for the changed surface.
- Before any likely interruption point or long-running batch, sync `.projectpal/state.yml` so resume starts from the latest finished wave or ticket group.
- If a ticket cannot be implemented in the current session, leave artifacts intact and write the exact next ticket or action to the diary.

### Lean v1 fallback policy

- Automatic recovery is limited to one `retry_same_path` attempt per delegated task.
- `equivalent_substitution` is automatic only when the substitute stays inside the approved path boundary and the same `quality_tier`.
- Any recovery that changes `connector`, `provider`, `runtime_path`, `auth_scope`, or `quality_tier` is outside automatic recovery and must not continue silently.
- If the connector cannot prove a safe equivalent substitution, do not infer one. Use the single same-path retry if it has not been spent; otherwise stop and route the case into approval handling.

### Lean v1 approval gate

- If fallback evaluation returns `path_switch_request` or any `approval_required = true` result, pause delegated execution before the path changes.
- `request_approval` is always owned by the Pal in Codex.
- The approval ask must name the changed path fields and make it clear that the path switch was not part of the already approved boundary.
- Delegated adapters may report `approval_required = true`, but they must not emit user-facing approval prompts directly.

### Lean v1 reporting flow

- `render_pal_update` in Codex is the only path that turns delegated internal result data into visible user-facing text.
- Same-path fallback disclosure is attached to the next natural summary instead of emitted as a standalone delegated status message.
- Non-primary assistants must not emit user-facing progress, decisions, or completion text.

### Lean v1 parallel delegation guard

- Explicit parallel delegated work is blocked in lean v1.
- When a user asks for parallel delegated work, return one Pal-owned explanation that lean v1 only supports one delegated path at a time.
- This guard applies to delegated parallelism only; it does not forbid independent non-delegated ProjectPal work in the same session.

**Batch close rules:**
- A wave is only closed when its runnable tickets are `complete` or explicitly `deferred`, its blocked tickets explain why they are blocked, and its exit criteria are satisfied.
- Phase 7 cannot close without a Final Integration Report in the ticket bundle.
- The Final Integration Report must record wave summaries, active owners, ownership collisions or confirmation of none, blocked items, verification results, and final batch status.

**Implementation completion gate:**
Phase 7 is complete only when:
- All generated tickets are implemented, explicitly deferred, or rewritten as follow-up tickets.
- Verification has been run or the reason it could not run is captured.
- The local artifact set still exists for review.

## Phase 8: Wrap Up Protocol

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
