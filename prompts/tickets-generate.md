# Ticket Generation — Prompt

You are generating the complete implementation ticket backlog from an approved Tech Spec.

## Role

Receive an approved Tech Spec and produce a full ordered set of tickets plus the bundle-level execution structure that Phase 7 will read. Each ticket scopes to one ~15-minute focus session. Generate the complete backlog in one pass, ordered by real dependencies and grouped into waves. The user picks up tickets cold — each one is self-contained.

## Input

1. **Approved Tech Spec** — Implementation Plan is the primary source; all other sections provide context
2. **Parking Lot items tagged `phase:execution` or `phase:6`** — Incorporate as additional tickets if relevant

## Output Contract

Generate two layers of output:

1. **Bundle artifact** — the project-level ticket bundle that defines waves, ownership boundaries, and the final integration report scaffold.
2. **Individual ticket files** — zero-padded markdown tickets (`001.md`, `002.md`, etc.) that follow the bundle contract exactly.

The bundle is the canonical Phase 6 artifact. Phase 7 must be able to read it and decide:

- which tickets belong to which wave
- which tickets can run in parallel
- which tickets are blocked by true prerequisites
- which write surfaces are exclusive to one active owner
- what verification and final reporting are required before the batch closes

## Bundle Structure

The bundle artifact must include these sections in this order:

1. `## Summary`
2. `## Coverage Check`
3. `## Waves`
4. `## Ownership Boundaries`
5. `## Final Integration Report`

### Bundle section rules

- **Summary:** Explain the implementation-planning goal in 2 to 4 sentences. State that the bundle is contract-first and wave-based.
- **Coverage Check:** Map every Implementation Plan item from the Tech Spec to one or more ticket ids. No Implementation Plan item may be left unmapped.
- **Waves:** Define each wave with:
  - wave label or id
  - entry criteria
  - exit criteria
  - ticket ids included in the wave
  - optional role slots when justified by risk, such as `reviewer` or `verifier`
- **Ownership Boundaries:** List file-level or subsystem-level exclusive write scopes so two active tickets do not claim the same write surface in the same wave.
- **Final Integration Report:** Provide the report scaffold Phase 7 will fill in. It must cover:
  - wave summaries
  - active owners per wave
  - ownership collisions or confirmation that there were none
  - blocked items and why they were blocked
  - verification results
  - final batch status and whether the run converged cleanly

## Wave Rules

- Use waves as the primary scheduling unit.
- A wave may contain multiple tickets only when their `depends_on` chains and write surfaces allow parallel execution.
- Use `builder` as the default execution owner.
- Add `reviewer` or `verifier` only as optional role slots for a wave when the work is cross-file, high-risk, or needs independent checking.
- Do not create new default personas beyond `builder`.
- Prefer file-level ownership boundaries. Use subsystem-level boundaries only when the spec implies a broader but still exclusive write scope.

## Ordering

Sort tickets by topological dependency order: tickets with no dependencies first, then each ticket after all its dependencies are listed. Within dependency-free groups, follow the workstream order from the spec's Implementation Plan.

## Ticket Format

Individual ticket files named with zero-padded 3-digit numbers: `001.md`, `002.md`, etc.

```yaml
---
project: <project-name>
ticket: <sequential number as integer>
title: <clear action title — verb + object>
phase: 6
type: ticket
status: ready
created: <ISO-8601>
estimated_minutes: <15 for S | 45 for M>
depends_on: [<ticket numbers as integers, empty list if none>]
---
```

## Body

- **Wave:** Name the wave this ticket belongs to.
- **What:** One clear thing to do — verb + object.
- **Why:** How this connects to the spec goal (one sentence).
- **Owner:** The active owner for the ticket. Default to `builder` unless the spec or wave explicitly justifies another role slot.
- **Persona:** Optional. Only include when a `reviewer` or `verifier` role slot is intentionally assigned.
- **Status:** Start every Phase 6 ticket as `ready`. The bundle and tickets must preserve the execution-state vocabulary Phase 7 will use later: `queued`, `blocked`, `running`, `complete`, `deferred`.
- **Primary files:** Optional but preferred when a ticket writes to a small, clear file set.
- **Allowed writes:** Required. List the exact files or subsystems this ticket may change.
- **Verification:** Required. List explicit checks the executor can run or inspect later.
- **Done when:** A concrete, verifiable completion state. Prefer: artifact exists at [path], test passes for [condition], or user can perform [observable action]. Never: "task is complete," "work is done," or any activity-completion language.
- **Handoff notes:** Optional. Use when a later ticket needs a specific follow-up, bridge-sync checkpoint, or integration reminder.
- **Notes:** Always include: "Source: [Implementation Plan step / workstream item]". If decomposed from an L-sized spec item: "Decomposed from L-sized spec item: [original item name]." Add any gotchas or references.

## Ticket Validity Rules

A generated ticket is valid only if all of the following are true:

- It belongs to exactly one wave.
- It has one active owner.
- It lists explicit `allowed writes`.
- It has verification steps that a maintainer can actually run or inspect.
- Its `depends_on` list contains only true prerequisites, not convenience ordering.
- Its `Done when` clause describes an observable end state.
- It does not overlap with another same-wave ticket on an exclusive write surface.

If any of these checks fail, revise the ticket before finalizing the bundle.

## Workflow

**Step 1 — Parse the Implementation Plan.**
List every item from the spec's Implementation Plan. Note its size (S or M) and any explicit dependencies.

**Step 2 — Handle L-sized items.**
If any Implementation Plan item is L-sized (or unambiguously > 45 min): decompose it into ≥2 sequential S/M tickets before assigning numbers. Preserve the dependency chain through the decomposed tickets. Flag each decomposed ticket in Notes.

**Step 3 — Build the wave plan.**
Group tickets into waves with explicit entry criteria, exit criteria, ownership boundaries, and optional role slots only when justified.

**Step 4 — Generate all tickets.**
Assign numbers in dependency-topological order. Write each ticket in full using the format above.

**Step 5 — Completeness quality gate.**
After generating all tickets: verify every Implementation Plan item maps to ≥1 ticket. If any item is missing, add the missing ticket(s) before finalizing.

**Step 6 — Validate the bundle contract.**
Before finalizing:
- confirm every ticket has a wave, owner, allowed writes, verification, and observable done state
- confirm every wave has entry criteria, exit criteria, and ticket ids
- confirm ownership boundaries prevent same-wave write collisions
- confirm the Final Integration Report section exists
- confirm the bridge-sync requirement appears in the ticket set when the work spans multiple batches or likely interruption points

**Step 7 — Verify parallelism.**
Review the `depends_on` chains and ownership boundaries together. If two tickets have no true dependency relationship and can run in parallel safely, they must NOT be chained. If they touch the same exclusive write surface, they must NOT run in the same wave without a stronger boundary split.

## Anti-patterns

- **Never chain tickets that can run in parallel.** Incorrect depends_on blocks execution unnecessarily.
- **Never use `estimated_minutes: 15` for an M-sized item.** S = 15 min, M = 45 min. Apply the value that matches the spec size label.
- **Never omit `Allowed writes`.** A ticket without an exclusive write scope is invalid for parallel execution.
- **Never omit `Verification`.** A contract-first ticket without explicit checks is incomplete.
- **Never put a ticket in multiple waves.** One ticket belongs to one wave only.
- **Never assign reviewer or verifier as new default personas.** They are optional role slots, not the normal execution path.
- **Never leave the bundle without a final integration report scaffold.**
- **Never write activity-completion "Done when."** "Feature is implemented" is not verifiable. "File exists at [path]" is.
- **Never produce a ticket for scope excluded in the PRD.**
- **Never write tickets in a language other than English.** Tickets are execution artifacts — they must be readable and searchable in English regardless of conversation language.
- **Never skip the completeness gate.** A missed Implementation Plan item means unbuilt functionality.
