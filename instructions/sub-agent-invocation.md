

# Sub-Agent Invocation

Use the **Agent** tool (not Task) to invoke all sub-agents. Agent is always available — Task requires schema loading and should not be used here.

Eight sub-agents are active in the pipeline. All receive their input inline — never by file reference alone.

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

### 1. Complexity Analyst

Invoked at Phase 0 completion (see Phase 0 Protocol above).

```
Agent(Complexity Analyst):
  input:  prompts/complexity-analyst.md + Phase 0 transcript (inline)
  output: complexity zone, confidence, plain-terms summary, route sentence
```

---

### 2. Strategist

Invoked at Phase 1 (see Phase 1 Brief Protocol above).

```
Agent(Strategist):
  input:  prompts/strategist-agent.md + transcript + confirmed complexity assessment
          + Parking Lot items (phase:brief) (inline)
  output: complete Brief document with YAML frontmatter (opinionated product Brief, including User Goals / UX Outcomes / Value Framing subsections)
```

Pre-Refinement brevity audit: always run the brevity audit before Architect/Manager. If output remains >2,000 words after the audit, surface warning before Refinement.

---

### 3. Architect

Invoked at Phase 2. Skipped for Clear path problems.

```
Agent(Architect):
  input:  prompts/architect-agent.md + full Brief text (inline)
  output: structured review with verdict [PASS | PASS WITH REVISIONS | NEEDS REWORK]
          + **Sign-off** line (approved | approved-with-concern | rejected)
```

---

### 4. Manager

Invoked at Phase 2, only after the Architect returns PASS or PASS WITH REVISIONS.

```
Agent(Manager):
  input:  prompts/manager-agent.md + full Brief text + Architect output (inline)
  output: Manager Deliberation + **Sign-off** line (approved | approved-with-concern | rejected)
          + synthesis recommendations for the Pal (no standalone Final Brief — the Pal writes the approved Brief to the artifact)
```

**Debate protocol (bounded, max 3 rounds):**

```
Step 1: Agent(Strategist) drafts Brief → brevity audit → word count check → save working Brief
Step 2: If >2,000 words after brevity audit: warn user before proceeding
Step 3: Agent(Architect) receives: architect-agent.md + full Brief (inline) → critique + sign-off
Step 4: Agent(Manager) receives: manager-agent.md + full Brief + Architect output (inline) → deliberation + sign-off
Step 5: Evaluate sign-offs:
        All approved or approved-with-concern → Pal synthesizes final Brief, persists debate record (see artifacts.md debate-record template)
        Any rejected → collect rejection reasons, proceed to Step 6
Step 6: Agent(Strategist) receives: strategist-agent.md + Brief + rejection reasons (inline) → revised Brief
        Increment round counter. Return to Step 2.
Step 7: If round 3 is exhausted without consensus → Pal escalates to user with unresolved summary
```

**Re-refinement rule:** If a refined Brief is changed before the Solution Check-in is approved, and the change is substantial enough to alter a requirement, persona boundary, assumption, success criterion, risk, or scope boundary, return the Brief to Phase 2 and rerun the debate loop (Architect → Manager → Strategist as needed) before presenting it again. Minor wording cleanup that preserves meaning does not require a fresh refinement pass.

---

### 5. Tech Lead

Invoked at Phase 4 when the route is Needs a plan (see Phase 4 Planning Protocol above).

```
Agent(Tech Lead):
  input:  prompts/tech-lead-agent.md + full approved Brief text
          + Parking Lot items (phase:4 / phase:technical-details) (inline)
  output: complete internal Technical Details document with YAML frontmatter
```

---

### 6. Scrum Master

Invoked at Phase 6 after the last Planning or Technical Details Check-in is approved.

```
Agent(Scrum Master):
  input:  prompts/scrum-master-agent.md + full approved Technical Details artifact text
          + Parking Lot items (phase:6 / phase:execution) (inline)
  output: complete ordered ticket set, one ticket per Implementation Plan item, each with explicit allowed_writes for Engineer execution
```

**Phase 6 ticket protocol:**

```
Step 1: Read the approved planning artifact set
        - Needs a plan: read approved Technical Details artifact from .projectpal/artifacts/technical-details/<name>.md
        - Clear path: derive tickets from the approved Brief and the already-bounded route
Step 2: Read Parking Lot items tagged phase:6 or phase:execution
Step 3: Agent(Scrum Master) receives: scrum-master-agent.md + technical-details artifact + parking lot (inline)
Step 4: Pal captures ticket set output
Step 5: Save each ticket as individual file: .projectpal/artifacts/tickets/<NNN>.md (zero-padded 3-digit numbers)
Step 6: Proceed to Phase 7 Implementation Protocol
```

---

### 7. Designer

Invoked in Phase 7 after each **wave** of Implementation tickets completes when `designer_opt_in=true` on the thread or batch.

```
Agent(Designer):
  input:  prompts/designer-agent.md + combined wave output (diffs or Pal summary) + approved Brief + Technical Details / tech spec (inline)
  output: Designer Review Record at .projectpal/artifacts/designer-review/<project>-wave-<id>.md
```

Gate: a `changes-requested` verdict blocks starting the next wave until the Pal resolves the listed changes (new tickets or direct fixes).

---

### 8. Engineer

Invoked at Phase 7 for each ticket in the implementation batch. The Pal dispatches one ticket at a time; the Engineer executes the work scoped by that ticket and hands back to the Pal when finished.

```
Agent(Engineer):
  input:  prompts/engineer-agent.md + ticket content (inline) + project context
  output: completed ticket work + status update + blocker report (if any)
```

After completing its ticket, the Engineer returns control to the Pal, which updates the ticket status and decides whether to dispatch the next ticket or surface a blocker to the user.

**Phase 7 wave-level parallel execution:**

The Pal may spawn one Engineer agent per ticket within a wave when both conditions hold:

1. The ticket's `depends_on` chain is fully satisfied (all upstream tickets are `complete`).
2. The ticket's `allowed_writes` do not overlap on an exclusive write surface with any other currently running Engineer instance.

When either condition is not met, the Pal falls back to sequential dispatch for the affected tickets.

Rules for parallel Engineer execution:

- Each Engineer instance only writes within its own ticket's `allowed_writes` scope. No Engineer may revert or modify another Engineer's output.
- The Pal orchestrates the wave lifecycle: it spawns Engineers, tracks their status, and collects results. The Engineer hands back to the Pal after completing its ticket — it does not spawn further work or advance the wave on its own.
- Write ownership must stay clear: each running Engineer gets a distinct file or module responsibility as defined by its ticket's `allowed_writes`.
- This parallel pattern applies specifically to Phase 7 wave execution and does not override the lean v1 parallel delegation guard. The lean v1 guard blocks general parallel delegated work across the system; Engineer wave parallelism is an internal Phase 7 orchestration concern managed entirely by the Pal within a single active thread.

---

For Clear path problems: keep the **Strategist**, skip the Architect, Manager, and Tech Lead, then move through Phase 3 → Phase 6 → Phase 7 → Phase 8.

The **Engineer** runs in Phase 7 on every route — Clear path included. Whenever Implementation begins, the Pal dispatches tickets to the Engineer regardless of complexity assessment.