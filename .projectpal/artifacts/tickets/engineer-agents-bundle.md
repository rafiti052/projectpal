---
project: engineer-agents
phase: 6
type: ticket-bundle
status: complete
created: 2026-04-15T23:50:00-03:00
complexity: simple
---

## Summary

This bundle delivers the Engineer agent — the eighth ProjectPal persona and the first that writes code. Five tickets cover the persona prompt, execution contract, blocker handling protocol, parallel execution logic, and Phase 7 integration. The bundle is contract-first and wave-based: Wave 1 establishes the foundational prompt and contracts, Wave 2 wires the Engineer into the existing pipeline.

## Coverage Check

| Brief scope item | Ticket(s) |
|---|---|
| Engineer agent persona prompt (`prompts/engineer-agent.md`) | 001 |
| Execution contract: how the Engineer consumes tickets, signals completion, and reports blockers | 002 |
| Blocker handling protocol (try N approaches, then stop with structured report) | 003 |
| Parallel execution: spawn one Engineer agent per ticket within a wave | 004 |
| Integration point with Phase 7 (Implementation) in the existing pipeline | 005 |

## Waves

### Wave 1 — Foundation

- **Entry criteria:** Brief approved, existing agent prompts available for reference.
- **Exit criteria:** Tickets 001, 002, and 003 are complete. The Engineer persona prompt exists at `prompts/engineer-agent.md`, the execution contract is embedded in that prompt, and the blocker protocol is defined.
- **Tickets:** 001, 002, 003
- **Parallelism:** 001 writes only to `prompts/engineer-agent.md`. 002 writes only to `instructions/sub-agent-invocation.md`. 003 writes only to `prompts/engineer-agent.md` (blocker protocol section). Because 001 and 003 both write to the same file, they run sequentially (003 depends on 001). 002 can run in parallel with 001.

### Wave 2 — Pipeline Integration

- **Entry criteria:** Wave 1 complete. Engineer prompt and contract exist.
- **Exit criteria:** Tickets 004 and 005 are complete. Phase 7 protocol references the Engineer correctly, and the sub-agent invocation file includes the Engineer entry with parallel execution guidance.
- **Tickets:** 004, 005
- **Parallelism:** 004 writes to `instructions/sub-agent-invocation.md`. 005 writes to `instructions/phase-protocols.md`. No overlap — can run in parallel.

## Ownership Boundaries

| Write surface | Exclusive owner (wave) |
|---|---|
| `prompts/engineer-agent.md` | 001 (W1), then 003 (W1, sequential after 001) |
| `instructions/sub-agent-invocation.md` | 002 (W1), then 004 (W2) |
| `instructions/phase-protocols.md` | 005 (W2) |

No same-wave write collisions exist. Within Wave 1, tickets 001 and 003 share a write surface but are ordered by dependency. Ticket 002 writes to a different file and runs in parallel with 001.

## Final Integration Report

_To be filled by Phase 7 after execution._

### Wave Summaries

- **Wave 1:** complete — Engineer persona prompt created with Role, Input, Workflow (4 steps), Output, Blocker Handling, and Anti-patterns sections. Sub-agent invocation entry added as `### 8. Engineer`. Count updated to eight.
- **Wave 2:** complete — Parallel execution guidance added to Engineer's sub-agent entry (wave-level spawning rules, lean v1 guard relationship). Phase 7 protocol updated with `### Engineer invocation protocol` subsection covering dispatch, completion signals, blocker surfacing, wave transitions, and handoff discipline.

### Active Owners per Wave

- Wave 1: builder (001, 002 parallel; 003 sequential after 001)
- Wave 2: builder (004, 005 parallel)

### Ownership Collisions

None. Confirmed after execution.

### Blocked Items

None.

### Verification Results

- [x] 001 — Engineer prompt exists at `prompts/engineer-agent.md` with Role, Input, Workflow, Output, Blocker Handling, Anti-patterns sections
- [x] 002 — `### 8. Engineer` entry exists in `instructions/sub-agent-invocation.md`
- [x] 003 — Blocker Handling section present in Engineer prompt with 3-attempt threshold and structured report format
- [x] 004 — Parallel execution guidance added to sub-agent invocation with wave-level rules and lean v1 guard note
- [x] 005 — `### Engineer invocation protocol` added to Phase 7 in `instructions/phase-protocols.md`

### Final Batch Status

Converged cleanly.
