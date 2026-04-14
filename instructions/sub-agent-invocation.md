<!-- Ownership: Layer 1 sub-agent contracts live here; source text originates in CLAUDE.md and is loaded when agent orchestration detail is needed. -->

# Sub-Agent Invocation

Use the **Agent** tool (not Task) to invoke all sub-agents. Agent is always available — Task requires schema loading and should not be used here.

Six sub-agents are active in the pipeline. All receive their input inline — never by file reference alone.

These worker names are internal only. Never announce them to the user or use them as progress labels. User-facing updates should stay in the visible stage language: `Discovery`, `Brief`, `Refinement`, `Solution`, `Planning`, `Technical Details`, `Tickets`, `Implementation`, and `Wrap Up`.

## Lean v1 execution path contract

Before invoking delegated work in lean v1, compare the candidate `ExecutionPathRecord` to the thread's approved path.

- The approval boundary is defined by `connector`, `provider`, `runtime_path`, `auth_scope`, and `quality_tier`.
- If any of those fields change, the path is outside the approved boundary and `approval_required = true` before delegated execution continues.
- A model change is automatic only when it is an equivalent substitution inside the same boundary and the same `quality_tier`.
- If the connector cannot prove the candidate path stays inside that boundary, treat it as approval-required instead of inferring safety.

## Lean v1 fallback evaluation

When delegated work fails, evaluate fallback in one explicit step before any retry or substitution happens.

`evaluate_fallback` returns:
- `fallback_type` = `retry_same_path | equivalent_substitution | path_switch_request | none`
- `attempt_number`
- `changed_fields[]`
- `approval_required`

Rules:
- Allow at most one automatic `retry_same_path` per delegated task.
- Allow `equivalent_substitution` only when `changed_fields[]` stays outside `connector`, `provider`, `runtime_path`, `auth_scope`, and `quality_tier`, and the substitute remains in the same `quality_tier`.
- If the connector cannot prove a safe equivalent substitution, prefer `retry_same_path` while the one automatic retry remains available.
- After the automatic retry is spent, any remaining recovery outside a proven same-path substitution becomes `path_switch_request` with `approval_required = true`.

## Lean v1 parallel delegation guard

- Explicit parallel delegated work is blocked in lean v1.
- Do not invoke multiple delegated agents in parallel for one active ProjectPal thread.
- Return `blocked` plus a Pal-owned explanation instead of partially scheduling delegated parallel work.
- This guard does not forbid independent non-delegated ProjectPal work elsewhere in the session.

---

### 1. Complexity Classifier
Invoked at Phase 0 completion (see Phase 0 Protocol above).
```
Agent(Cynefin Classifier):
  input:  prompts/cynefin-classify.md + Phase 0 transcript (inline)
  output: complexity zone, confidence, plain-terms summary, route sentence
```

---

### 2. Problem Solver
Invoked at Phase 1 (see Phase 1 Brief Protocol above).
```
Agent(Problem Solver):
  input:  prompts/brief-generate.md + transcript + confirmed complexity assessment
          + Parking Lot items (phase:brief) + MemPalace results (inline)
  output: complete Brief document with YAML frontmatter
```
Pre-Refinement brevity audit: always run the brevity audit before Architect/Manager. If output remains >2,000 words after the audit, surface warning before Refinement.

---

### 3. Architect
Invoked at Phase 2. Skipped for Clear path problems.
```
Agent(Architect):
  input:  prompts/architect-agent.md + full Brief text (inline)
  output: structured review with verdict [PASS | PASS WITH REVISIONS | NEEDS REWORK]
```

---

### 4. Manager
Invoked at Phase 2, only after the Architect returns PASS or PASS WITH REVISIONS.
```
Agent(Manager):
  input:  prompts/manager-agent.md + full Brief text + Architect output (inline)
  output: Manager Deliberation + Final Brief (Refined) under exact header ## Final Brief (Refined)
```

**6-step Refinement protocol:**
```
Step 1: Problem Solver sub-agent completes → brevity audit → word count check → saved to artifacts
Step 2: If >2,000 words after brevity audit: warn user before proceeding
        Agent(Architect) receives: architect-agent.md + full Brief text (inline)
Step 3: Pal captures Architect output
Step 4: NEEDS REWORK routing:
        - PASS or PASS WITH REVISIONS → proceed to Step 5
        - NEEDS REWORK → stop, surface the Architect's top issue, revise the Brief. Return to Phase 1.
Step 5: Agent(Manager) receives: manager-agent.md + full Brief text + Architect output (inline)
Step 6: Pal saves the refined Brief (status: refined) → presents at the Solution Check-in with a short summary of the refined outcome
        - Blockers must be answered explicitly before proceeding
        - Non-blocker concerns must be surfaced one by one and explicitly passed, revised, or deferred by the user
        - After the summary, ask only one question at a time
```

**Re-refinement rule:** If a refined Brief is changed before the Solution Check-in is approved, and the change is substantial enough to alter a requirement, persona, assumption, success criterion, risk, or scope boundary, return the Brief to Phase 2 and rerun the Architect and Manager before presenting it again. Minor wording cleanup that preserves meaning does not require a fresh refinement pass.

---

### 5. Technical Details Generator
Invoked at Phase 4 when the route is Needs a plan (see Phase 4 Planning Protocol above).
```
Agent(Technical Details Generator):
  input:  prompts/technical-details-generate.md + full approved Brief text
          + MemPalace results + Parking Lot items (phase:4 / phase:technical-details) (inline)
  output: complete internal Technical Details document with YAML frontmatter
```

---

### 6. Ticket Generator
Invoked at Phase 6 after the last Planning or Technical Details Check-in is approved.
```
Agent(Ticket Generator):
  input:  prompts/tickets-generate.md + full approved Technical Details artifact text
          + Parking Lot items (phase:6 / phase:execution) (inline)
  output: complete ordered ticket set, one ticket per Implementation Plan item
```

**Phase 6 ticket protocol:**
```
Step 1: Read the approved planning artifact set
        - Needs a plan: read approved Technical Details artifact from .projectpal/artifacts/technical-details/<name>.md
        - Clear path: derive tickets from the approved Brief and the already-bounded route
Step 2: Read Parking Lot items tagged phase:6 or phase:execution
Step 3: Agent(Ticket Generator) receives: tickets-generate.md + technical-details artifact + parking lot (inline)
Step 4: Pal captures ticket set output
Step 5: Save each ticket as individual file: .projectpal/artifacts/tickets/<project-id>-NNN.md
        (zero-padded 3-digit numbers, e.g. myproject-001.md)
Step 6: Proceed to Phase 7 Implementation Protocol
```

For Clear path problems: keep the Problem Solver, skip the Architect, Manager, and Technical Details Generator, then move through Phase 3 → Phase 6 → Phase 7 → Phase 8.
