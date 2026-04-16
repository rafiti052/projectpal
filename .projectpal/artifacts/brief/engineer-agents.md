---
project: engineer-agents
phase: 1
type: brief
status: approved
created: 2026-04-15T23:45:00-03:00
complexity: simple
---

## Problem Statement

ProjectPal has seven sub-agents that advise, plan, and review, but none of them write code. Implementation work today runs inline through the Pal itself, with no dedicated persona, no execution discipline, and no structured blocker handling. When the user approves a batch of tickets and wants to step away, there is no agent that can pick them up one by one and keep going until something genuinely blocks progress. The user ends up babysitting builds instead of staying in the product seat.

## User Profile

A solo builder who thinks in product terms and works in short, high-focus windows. They already trust the ProjectPal pipeline enough to let specialized agents handle strategy, architecture, and ticket generation. They want the same delegation for the actual building: hand off approved tickets and come back to finished work or a clear blocker report. They chose "fast executor" over "careful craftsperson" deliberately -- they value momentum and trust themselves to course-correct on review rather than gate every cut.

## Proposed Solution

Add an **Engineer** agent -- the eighth ProjectPal persona and the first one that writes code. The Engineer consumes approved tickets produced by the Scrum Master and executes them without pausing for approval between each. When tickets have no dependency conflicts and non-overlapping `allowed_writes`, the Engineer spawns multiple agents to run them in parallel. When dependencies or write surfaces overlap, it falls back to sequential execution. It only stops when it hits an actual blocker. It respects the `allowed_writes` boundaries already defined in each ticket. Its persona is a fast executor: ships first, flags issues after, and yields decisions back to the user rather than making product calls on its own.

### User Goals

- Stay in the product seat while implementation happens through a dedicated agent with a proper persona, just like the other seven agents.
- Approve a batch of tickets and walk away, trusting the Engineer to execute them sequentially without unnecessary stops.
- Get a clear, structured report when the Engineer hits a genuine blocker instead of a vague pause.

### UX Outcomes

- **Continuity**: the user returns to completed work or a precise blocker summary, not a half-finished state with no explanation.
- **Confidence**: the Engineer's persona is predictable -- it builds, it does not redesign, reframe, or second-guess approved tickets.
- **Speed**: independent tickets run in parallel; dependent ones flow sequentially with no inter-ticket pause. A batch of tickets finishes faster than manual one-by-one execution.

### Value Framing

The Engineer closes the last gap in the ProjectPal agent pipeline. Today the system can take an idea from chaos to approved tickets, but the final mile -- actually building -- has no persona, no voice, and no execution contract. Adding the Engineer means the full pipeline from Discovery to shipped code runs through specialized agents, and the user's role stays where they want it: product decisions, not implementation labor.

## Success Criteria

1. The user can approve a batch of tickets and the Engineer executes them — in parallel where safe, sequentially where needed — without stopping between tickets.
2. When the Engineer encounters a genuine blocker, it stops with a structured report that names the blocker, what it tried, and what decision it needs.
3. The Engineer respects `allowed_writes` from ticket metadata -- it does not touch files outside its ticket scope.
4. The Engineer has a full persona prompt in `prompts/` consistent with the seven existing agents.

## Scope

**In scope:**

- Engineer agent persona prompt (`prompts/engineer-agent.md`)
- Execution contract: how the Engineer consumes tickets, signals completion, and reports blockers
- Parallel execution: spawn one Engineer agent per ticket within a wave (the Scrum Master's wave plan already guarantees non-overlapping `allowed_writes`)
- Integration point with Phase 7 (Implementation) in the existing pipeline
- Blocker handling protocol (try N approaches, then stop with structured report)

**Out of scope:**

- Automatic rollback when a parallel ticket fails (blocker stops that ticket; others continue unless they depend on it)
- Quality-based rerouting or automatic rollback
- Changes to the Scrum Master's ticket format beyond what the Engineer needs to read
- Multi-model routing for the Engineer (covered by the connector-wiring project)
- Designer review protocol changes (already handled in Phase 7)

## Risks & Open Questions

1. **Blocker threshold**: How many approaches should the Engineer try before stopping? The transcript mentioned "try up to N approaches" from the user's research but did not lock a number. Needs a sensible default in the prompt (suggest 3).
2. **Batch boundaries**: When the Engineer finishes all tickets in a batch, does it trigger the existing Phase 7 wrap-up flow automatically, or does it hand back to the Pal? Needs to align with the current Phase 7/8 handoff.
3. **Voice calibration**: The user chose "fast executor" and the research surfaced "confident but deferential." The prompt needs to hit that register without drifting into either robotic terse or over-eager chatty. First draft will need a tone check.

## Kill Criteria

- If the Engineer cannot stay within `allowed_writes` boundaries reliably, the agent is unsafe to run unattended and the approach needs rethinking.
- If batch execution requires more user intervention than running tickets manually through the Pal, the agent adds overhead instead of removing it.
- If the persona prompt cannot be kept consistent with the existing seven-agent format, the abstraction is wrong and should be reconsidered before shipping.
