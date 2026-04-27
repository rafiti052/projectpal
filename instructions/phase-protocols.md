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

## Check-in obligations (non-optional)

Whenever this file, `instructions/sub-agent-invocation.md`, `instructions/artifacts.md`, or `src/shared/core.md` specifies a **Check-in** or an artifact review that functions as one (Solution, synthesized Brief after Refinement, Technical Details, ticket-set handoff when user confirmation is required before Implementation, Implementation **green light** before building when the user has not already explicitly waived that gate for this batch, Wrap Up), the Pal **runs that Check-in** before advancing.

- Do **not** skip or collapse a mandated Check-in because the route is **Clear path**, because the work feels obvious, or to finish implementation in fewer turns. **Clear path** only skips **Refinement** and **Technical Details** — it does **not** skip Brief, Solution, tickets, mandated Implementation entry confirmation, or Wrap Up.
- The only exception is an **explicit** same-session waiver from the user for **that specific** gate (name the gate they waived).
- Follow the ProjectPal shell and one-question cadence in `src/shared/core.md` and `instructions/artifacts.md` unless a subsection here already defines a different rhythm (for example one concern at a time after Refinement).

## Phase 0 Protocol

**Readiness threshold (internal — never display this to the user):**

Phase 0 is complete when ProjectPal can answer all four of these from the conversation:

1. Who has the problem? (one clear sentence)
2. What's the pain? (symptom + root cause, even if approximate)
3. What's the proposed direction? (at least a vague solution shape)
4. What does success look like? (rough is fine — "I'd know it's working if...")
5. Does the user allow agent delegation and parallelization?

### Designer opt-in trigger (Discovery)

During Discovery, evaluate whether the user request is design-relevant (layout, interaction flow, information hierarchy, accessibility behavior, or cross-device responsiveness).

- If design relevance is strong and no higher-priority Discovery question is unresolved, ask:
  - _"This sounds design-relevant. Want me to include a Designer pass as we shape it?"_
- Preserve one-question cadence. If core Discovery readiness is still unresolved, that readiness question outranks Designer opt-in in the current turn.
- If user declines Designer opt-in, do not re-ask immediately. Permit at most one re-offer in the same session only when materially stronger design signals appear.

Track these internally. Never display a checklist or progress bar to the user. When all four are answerable, invoke the complexity classifier sub-agent, but only at the natural end of an exchange, never mid-response.

Actively test whether the work can safely be treated as a **Clear path**, especially in existing repos with strong conventions and well-bounded scope. Refinement is expensive, so do not force it when the work is already tight and obvious.

**Avoid hasty abstractions (AHA) in Discovery:** You may **name** where tests, rigor, or architecture might matter later — keep it light and conversational — without locking the user into a stack, framework, or build path they have not chosen yet. Prefer one honest acknowledgment over a premature plan. **Do not contradict** approved in-repo work that already commits to infrastructure under `.projectpal/artifacts/brief/` — AHA steers _new_ conversation away from invented depth; it does not erase mandated contracts elsewhere in the repo.

**Complexity Analyst sub-agent protocol:**

```
Agent(Complexity Analyst) receives: prompts/complexity-analyst.md prompt + full Phase 0 conversation transcript (inline)
Pal captures: complexity zone, confidence, plain-terms summary, route sentence, and whether one more question is needed
```

**Canonical transition phrasing (use this after the classifier returns, do not improvise the structure):**

Standard transition: _"I think I have the shape of it now. This feels like [route sentence]. Does that feel right?"_

If the user asks what that means: _"To me, this looks like [complexity zone] because [plain English reason]. Does that feel right, or is it messier than that?"_

Always propose the assessment in plain English first. Reveal the internal complexity label only if the user asks for it or the implementation needs it. If the Complexity Analyst says one more question is needed, ask that question before proposing any route.

### Delegation opt-in gate (Discovery exit)

After the user confirms the route and before any Phase 1 delegated drafting or review work begins, ask one explicit delegation question:

- _"Want me to use specialist passes behind the scenes as we go, or keep it with me unless I ask again later?"_

Rules:

- Preserve one-question cadence. If route confirmation is still unresolved, that question outranks delegation opt-in.
- This gate sits between **Discovery** and **Brief** on every route.
- The **Complexity Analyst** is the only delegated pass allowed before this gate.
- If the user opts in, record `delegation_preference: enabled` on the active thread and delegated Phase 1 to Phase 6 passes may proceed inside the approved execution path.
- If the user declines, record `delegation_preference: disabled` on the active thread and keep Phase 1 to Phase 6 work Pal-owned by default.
- If delegation is disabled and a later stage would materially benefit from a delegated pass, ask again at that boundary before invoking the worker.
- Phase 7 still requires its own Implementation green light before the first Engineer dispatch. The Discovery-exit opt-in does not replace that gate.

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

**Brief drafting sub-agent protocol:**

```
Agent(Strategist) receives:
  - prompts/strategist-agent.md prompt
  - Full Phase 0 conversation transcript (inline)
  - Confirmed complexity assessment (inline)
  - Parking Lot items tagged phase:brief (inline, or "none")

Pal captures: complete Brief document (with YAML frontmatter)
Pal runs brevity audit → checks word count → saves to .projectpal/artifacts/brief/<project-name>.md
```

If `delegation_preference: enabled`, do not draft the Brief inline. Use the Strategist sub-agent to generate the internal Brief artifact first.

If `delegation_preference: disabled`, the Pal drafts the Brief directly, still saves it to `.projectpal/artifacts/brief/<project-name>.md`, and keeps the same artifact contract and Check-in behavior.

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

If `delegation_preference: disabled`, the Pal runs the refinement reasoning locally and still saves the resulting Brief plus any required backstage artifact updates before the user-facing Check-in.

### Refinement Check-in rule (3-way debate)

Run Refinement as the bounded debate in `instructions/sub-agent-invocation.md` (Strategist ↔ Architect ↔ Manager, max three rounds). The user sees only the **Pal-synthesized** Brief and a short summary — not the debate record unless they ask.

- Do not surface a user-facing Refinement summary after the Architect alone. If any persona **rejects**, run the Strategist revision loop before the user sees anything new.
- If the Architect returns `NEEDS REWORK`, stop and surface that blocker directly because the Manager will not run.
- After **all** sign-offs are `approved` or `approved-with-concern`, the Pal synthesizes the final Brief into the artifact and **that** version drives the Check-in summary.
- If round 3 exhausts without consensus, escalate with an unresolved summary — do not silently merge.
- The user must answer blocker judgments explicitly before the Brief can proceed when blockers remain.
- If the pass returns non-blocker concerns, surface them one at a time after the summary.
- The user must explicitly pass, revise, or defer each concern before the Brief can be treated as approved.
- Never silently carry a `PASS WITH REVISIONS` posture into Phase 4 without user handling of flagged concerns.
- Keep the same one-question-per-turn rhythm used in Discovery: after the summary, ask only one concern question, wait for the answer, then ask the next.
- Never narrate backstage steps like the Strategist, Architect, or Manager while they run. If progress needs to be shown, reference the visible stage only.

## Phase 4: Planning Protocol

Phase 4 is mostly silent work. The user sees the next Check-in as **Technical Details**, not the drafting step itself.

### Parking Lot surfacing (entry step — before generating anything)

When entering Phase 4:

1. Read `.projectpal/parking-lot.md`
2. Surface all items tagged `phase:4` or `phase:technical-details` for the current repo, one at a time:
   _"Before I write the technical details, earlier you mentioned [X]. Want to include it here?"_
3. If the user accepts: incorporate and flag the item as "incorporated" in `parking-lot.md`
4. If the user declines: flag it as "deferred" and do not surface it again

**Parking Lot contract**

- Every parked item written to `.projectpal/parking-lot.md` must include `repo:<repo-slug>`, optional `feat:<feat-slug>`, and `phase:<phase-tag>`.
- Parking Lot surfacing must filter by current repo before matching by phase.

**Technical Details sub-agent protocol:**

```
Agent(Tech Lead) receives:
  - prompts/tech-lead-agent.md prompt
  - Full approved Brief text (inline — read from .projectpal/artifacts/brief/<name>.md)
  - Parking Lot items tagged phase:4 or phase:technical-details (inline, or "none")

Pal captures: complete internal Technical Details document (with YAML frontmatter)
Pal runs structural self-review → saves to .projectpal/artifacts/technical-details/<project-name>-technical-details.md
```

If `delegation_preference: enabled`, do not generate the technical details inline. Use the Tech Lead sub-agent.

If `delegation_preference: disabled`, the Pal drafts the technical details directly, still saves them to `.projectpal/artifacts/technical-details/<project-name>-technical-details.md`, and runs the same structural self-review before the Check-in.

### Spike protocol

Spike heuristic: if a key architectural decision has more than 2 unknown variables, it needs a spike before the technical details commit to it.

Spike protocol:

1. Pal identifies the spike question
2. Propose to the user: _"Before I can write [section], I need to check one thing. Can you [specific action] and share the result?"_
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
_"These technical details have a lot of moving parts. Do you want to walk through them section by section, or see them all at once?"_

Respect the user's choice. Do not default to section-by-section unprompted.

### Structural self-review (before the Technical Details Check-in)

Before presenting the technical details, run a structural self-review:

- [ ] Every Implementation Plan item maps to 1 or more tickets (structural check)
- [ ] Data Model covers every entity mentioned in the Brief Problem Statement
- [ ] All `parking-lot.md` items tagged `phase:4` are incorporated or flagged deferred
- [ ] **AHA:** The Technical Details draft does not front-load test frameworks, harnesses, speculative architectural layers, or scaffolding the Brief did not earn; scaling paths may appear in Risks as **note, don't build**. **Carve-out:** Do not treat surfaces the **approved Brief** already mandates as debt to remove — only trim _new_ plan text that exceeds Brief scope.

If any check fails: fix it inline before presenting.

**IMPORTANT LIMITATION:** This check catches structural gaps. It does not catch semantic errors. The user's Technical Details Check-in is still the backstop for semantic review.

## Phase 7: Implementation Protocol

After tickets are generated and saved, implementation begins. Do not clean up artifacts at the end of Phase 6. Tickets must remain available to drive the work.

**Implementation entry Check-in:** Before the first Engineer dispatch (first wave), present a short ticket summary in the ProjectPal shell with a **green-light** question, unless the user has already given explicit go-ahead for this exact ticket batch in the current session. Treat urgency (“just do it”) as explicit only when it clearly refers to this implementation batch.

**Implementation rules:**

- Read the ticket set from `.projectpal/artifacts/tickets/`.
- Read the bundle by wave order first. Do not start a later wave until the current wave's exit criteria are satisfied or the remaining blocked work is explicitly deferred.
- Treat `begin_thread` as the ownership gate for thread-local orchestration: the first assistant in a thread sets `primary_assistant`, and every later entry to that same thread preserves the existing owner instead of silently reassigning it.
- Each ticket is executed by an **Engineer** instance (implementation worker). Multiple Engineers may run in parallel within a wave when `depends_on` and `allowed_writes` allow it. Each Engineer only writes within its ticket's `allowed_writes` scope.
- Within a wave, parallelize only the tickets whose `depends_on` chain is satisfied and whose `allowed_writes` do not overlap on an exclusive write surface.
- Keep write ownership clear when parallelizing: each worker gets a distinct file or module responsibility and must not revert other workers' edits.
- Treat `builder` as the default execution owner. Use `reviewer` or `verifier` only when the wave or ticket explicitly asks for an optional role slot.
- After each wave completes, if `designer_opt_in=true`, invoke `Agent(Designer)` on the **combined wave output** before starting the next wave. A `changes-requested` verdict blocks the next wave until the Pal resolves the listed changes.
- Update ticket state in place as `queued`, `blocked`, `running`, `complete`, or `deferred`.
- When a ticket is blocked, record the exact dependency or ownership boundary that caused the block before moving on.
- Prefer existing codebase patterns and small, verifiable changes over broad rewrites.
- After each meaningful batch, run the smallest useful verification for the changed surface.
- **AHA in Implementation:** Do not introduce new default test frameworks, harnesses, or global coverage machinery unless the **ticket** or **Brief** explicitly requires them — prefer the smallest check that proves the change (existing scripts, targeted commands, or manual inspection called out in the ticket). **Carve-out:** Work the **approved Brief** already commits to (including any named routing, approval, or fallback surfaces) keeps those obligations — AHA blocks _extra_ rigging, not Brief scope.
- Before any likely interruption point or long-running batch, sync `.projectpal/state.yml` so resume starts from the latest finished wave or ticket group.
- If a ticket cannot be implemented in the current session, leave artifacts intact and write the exact next ticket or action to the diary.

### Engineer invocation protocol

The Pal orchestrates all Engineer work. Engineers never self-dispatch.

**Prompt and dispatch:**

```
Agent(Engineer) receives:
  - prompts/engineer-agent.md prompt
  - Ticket content (inline — read from .projectpal/artifacts/tickets/<ticket-id>.md)
  - Any resolved spike data or dependency outputs referenced by the ticket

Pal dispatches one Engineer per runnable ticket in the current wave.
```

**Wave reading:** Before dispatching Engineers, the Pal reads the ticket bundle in wave order and identifies every ticket in the current wave whose `depends_on` chain is satisfied and whose `allowed_writes` do not overlap with another running ticket's exclusive write surface. Only those tickets are dispatched.

**Completion signals:** Each Engineer reports back to the Pal with one of:

- `complete` — ticket work is done, changed files listed, verification result (if any).
- `blocked` — ticket cannot proceed; blocker description and the exact dependency or constraint that caused the block are included.
- `failed` — an unrecoverable error occurred; error detail and partial-progress summary are included.

The Pal updates ticket state in the bundle (`complete`, `blocked`, or `deferred`) as each signal arrives.

**Blocker surfacing:** When an Engineer reports `blocked` or `failed`:

1. The Pal records the blocker in the ticket's frontmatter.
2. If the blocker is resolvable within the current wave (e.g., a dependency ticket just needs to finish first), the Pal holds the blocked ticket and re-evaluates after the blocking ticket completes.
3. If the blocker requires a user decision or is outside the approved path boundary, the Pal surfaces it immediately: _"Ticket [id] hit a blocker: [one-line description]. How do you want to handle it?"_
4. The blocked ticket stays `blocked` until the user or a resolved dependency clears it.

**Wave transitions:** A wave is eligible to close when every ticket in it is `complete`, explicitly `deferred`, or `blocked` with a recorded reason. The Pal must not start dispatching tickets from the next wave until the current wave's exit criteria are met. When a wave closes:

1. The Pal writes a wave summary to the ticket bundle.
2. If `designer_opt_in=true`, the Designer review gate (below) runs before the next wave.
3. The Pal reads the next wave from the bundle and begins the dispatch cycle again.

**Handoff discipline:** Engineers hand control back to the Pal after completing their assigned ticket(s). Engineers do not read the next wave, dispatch other Engineers, or modify tickets outside their `allowed_writes`. The Pal is the sole wave lifecycle owner.

### Designer review-pass completion gate (when opted in)

If `designer_opt_in=true` for the active thread:

- Run **wave-level** Designer review after each Implementation wave (combined output), per `instructions/sub-agent-invocation.md`.
- Optionally retain a lightweight pre-plan / post-plan pass if the batch contract still calls for it — do not substitute those for the wave gate when tickets are driving execution.
- Require final visual/experience review completion before Wrap Up closure when UI shipped in the batch.
- Treat missing final review or an unresolved `changes-requested` wave as a phase-closure blocker, not as an optional note.

### Lean v1 fallback policy

- Automatic recovery is limited to one `retry_same_path` attempt per delegated task.
- `equivalent_substitution` is automatic only when the substitute stays inside the approved execution-path boundary.
- Any recovery that attempts to change the candidate `execution_path_id` outside the approved boundary is outside automatic recovery and must not continue silently.
- If the system cannot prove a safe equivalent substitution, do not infer one. Use the single same-path retry if it has not been spent; otherwise stop and route the case into approval handling.

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

- Explicit parallel delegated work is blocked in lean v1, **with one exception: Engineer wave parallelism** — the Pal may spawn one Engineer per runnable ticket within a wave when `depends_on` and `allowed_writes` allow it (see **Engineer invocation protocol** above).
- All other parallel delegated work (non-Engineer paths, multi-Pal orchestration) is blocked. When a user asks for it, return one Pal-owned explanation that lean v1 only supports one delegated path at a time outside Engineer wave execution.
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
3. **Artifact cleanup gate (required — do not skip):** Before touching any `.projectpal/staging/` files, ask:
   > "Want me to clean up the staging files from this batch? I'll archive the tickets and remove the staging drafts."
   - Wait for explicit yes (or equivalent) before proceeding.
   - If the user says no or does not respond affirmatively: leave `.projectpal/staging/` as-is and note it in the session summary.
4. Clean up `.projectpal/artifacts/` only after the user confirms cleanup in step 3.
