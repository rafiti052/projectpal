# PRD v3: ProjectPal — AI-Powered Product Pipeline

**Version:** 3.0 — Canonical Document  
**Status:** Draft — Awaiting Human Checkpoint 1  
**Consolidates:** PRD v1 · PRD v2 · Cynefin Addendum v2.1 · User Research Interview  
**Method:** User-Centered Design + Cynefin Framework + Human-in-the-Loop Architecture

---

## 1. Product Vision

**ProjectPal is an AI-powered product companion that transforms chaotic ideas into executable projects — without losing its owner's creative mind in the process.**

The system combines:

- A conversational persona (the Pal) that follows the user's non-linear reasoning
- A structured phase pipeline (discovery → specification → execution)
- A multi-agent architecture with debate between LLMs
- Explicit human checkpoints based on the nature of the problem (Cynefin)
- Persistent long-term memory (MemPalace) that eliminates context reconstruction

The goal is not to automate product. It's to ensure good ideas don't die from lack of infrastructure to survive real life.

---

## 2. The Real Problem

### The technical problem (surface-level)

LLMs suffer from amnesia between sessions. "Vibe coding" results in messy code, mixed responsibilities, and constant reinvention of the wheel.

### The human problem (the real one)

> _"Tried to organize my ideas because I think in a rather chaotic way and have ADHD."_

Good ideas die not from lack of quality — but from lack of infrastructure to survive real life. The user thinks out loud, has short focus windows, and when that window closes, the idea goes to sleep. In most cases, it doesn't resurface in time.

**Real cost:** the company website was never rewritten. Not because the idea was bad — because the process of getting it out of someone's head and into production didn't have the right support.

### The three failures of the status quo

**Failure 1 — Input demands structure the user doesn't have at the moment of the idea.**
Current tools (Notion, Jira, Linear) assume you know what you mean. The user knows what they want to _say_.

**Failure 2 — Context doesn't survive discontinuity.**
When the user stops and comes back days later, they need to mentally reconstruct the entire project state. No tool preserves that context for them.

**Failure 3 — Out-of-phase work is wasted.**
When the user goes deep on something from the wrong phase (ADHD hyperfocus), the work is ignored or lost. Nobody captures it and redirects it to the right moment.

---

## 3. The Real User

Profile derived from direct user research:

| Dimension            | Observation                                   | Product Implication                                 |
| -------------------- | --------------------------------------------- | --------------------------------------------------- |
| Thinking style       | Chaotic, non-linear, ADHD                     | Input must never require prior structure            |
| Preferred channel    | Voice — to themselves, friends, AI voice chat | Primary interface: natural conversation             |
| What drives progress | The right question at the right time          | The system pulls — doesn't wait                     |
| Context memory       | Weak between sessions                         | System remembers everything; user remembers nothing |
| Hyperfocus           | Goes deep in the wrong phase                  | Parking Lot captures, doesn't block                 |
| Desired relationship | "A pal" — not a PM, not a gatekeeper          | Tone: patient companion, not process                |
| Task management      | Uses Kanban as external memory                | Visible state interface, not imposed                |

**ProjectPal is not a tool. It's a character.**

The Pal accompanies the chaos, asks the next question, remembers everything, captures what's out of place, and gently brings the user back to the right phase.

---

## 4. Value Hypothesis

> **If the system acts as a patient companion that asks the right question, classifies the nature of the problem, preserves context between sessions, and captures out-of-phase work without losing it — then the user can ship ideas that currently die before taking shape.**

**The real success metric:** the company website was rewritten.

---

## 5. Decision Architecture — Cynefin Framework

The level of human intervention is determined by the nature of the problem, not the system's preference.

### The Four Domains

| Domain          | Nature                                  | Approach                     | Pal Behavior                                                               | HITL                                 |
| --------------- | --------------------------------------- | ---------------------------- | -------------------------------------------------------------------------- | ------------------------------------ |
| **Simple**      | Clear and known cause-effect            | Sense → categorize → respond | "This seems straightforward — I'll generate the tickets."                  | Minimal (optional review)            |
| **Complicated** | Requires expert analysis                | Sense → analyze → respond    | "This deserves careful thought. Let's build a PRD together."               | Required — CP1 + CP2                 |
| **Complex**     | Cause-effect only visible in retrospect | Probe → sense → respond      | "Before any spec, we need to understand what you don't know yet."          | Required — Decomposition Checkpoint  |
| **Chaotic**     | No identifiable pattern — crisis        | Act → sense → respond        | "This sounds urgent. Before planning, let's make sure nothing gets worse." | Immediate — Stabilization Checkpoint |

### Disorder Zone

When the domain is uncertain (common in ADHD thinking), the Pal asks exploratory questions before classifying. Default: Complicated — never underestimates the problem.

### Domain Routing

```
Conversation with the Pal
       ↓
[Cynefin Classifier]
  ├── Simple      → Tickets directly (no PRD, no debate)
  ├── Complicated → Full pipeline (Phases 1–6)
  ├── Complex     → Decomposition → each sub-problem becomes Complicated
  └── Chaotic     → Alert + Stabilization → Complex → Complicated
```

**Critical protection rule:** No agent writes a tech spec for an undecomposed Complex problem. No agent generates tickets for an unstabilized Chaotic problem.

---

## 6. Workflow — Phases

### Phase 0: Conversation with the Pal

The user speaks freely. The Pal asks ONE question at a time. The Cynefin Classifier analyzes the conversation and determines the domain.

The Parking Lot is active from the very first moment: any idea that arrives out of phase is captured silently.

### Phase 1: Discovery (Complicated path)

The PM Agent generates a PRD draft from the accumulated conversation, consulting MemPalace principles (Memory Access Moment 1).

### Phase 2: LLM Debate

The PRD draft is submitted to the Critic Agent, which analyzes across three dimensions: problem clarity, technical feasibility, success criteria. The Judge Agent consolidates feedback and produces the armored (final) PRD.

### Phase 3: Human Checkpoint 1 — PRD

The system pauses. The Pal presents the PRD in plain language:

> _"Here's what I understood. Sound right?"_

The user decides: **Approve** (advance) · **Revise** (revision loop) · **Archive** (close)

### Phase 4: Technical Specification

The Architect Agent writes the Tech Spec based on the approved PRD, consulting MemPalace architectural precedents (Moment 2). The Parking Lot from the previous phase is injected here.

### Phase 5: Human Checkpoint 2 — Spec

The Pal presents the architecture with a 3-line executive summary before the full document.

> _"Before getting into the details: [summary]. Want to continue?"_

The user decides: **Approve** · **Revise** · **Archive**

### Phase 6: Execution

The Execution Agent generates granular, isolated tickets, one at a time, calibrated for 15-minute sessions. Final artifacts are saved to MemPalace (Moment 3).

### Simple Path (bypass)

Simple problems skip Phases 1–5 entirely. Conversation → Tickets directly.

### Complex Path (decomposition)

Before Phase 1, the Decomposition Agent breaks the problem into Complicated sub-problems. Each enters the pipeline independently with its own runId.

### Chaotic Path (crisis protocol)

The Alert Agent presents immediate stabilization measures. The Stabilization Checkpoint is required. After approval, the problem is treated as Complex.

---

## 7. Essential Features

### 7.1 Parking Lot

**What it is:** A repository for out-of-phase work, captured silently by the Pal during conversation.

**How it works:**

- When the user talks about something that belongs to another phase, the Pal captures and confirms:
  > _"Noted that for when we get to the implementation phase."_
- Each phase has its own Parking Lot
- At the start of each phase, the relevant Parking Lot is presented:
  > _"Last week you mentioned X when we were in discovery. Want to include it here?"_

**What it solves:** Out-of-phase hyperfocus is no longer wasted — it's redirected.

### 7.2 Context Summary (Session Resumption)

**What it is:** When resuming a session after >1 hour of inactivity, the Pal presents a 2–3 line summary before continuing.

> _"In the last session, you were reviewing the PRD for your product platform. The next step is to approve the tech spec. Want to continue or is there something new?"_

**What it solves:** The user doesn't need to reconstruct their mental context to resume work.

### 7.3 LLM Debate

**What it is:** Before any human checkpoint on the PRD, the draft goes through internal debate between agents.

**Structure:**

1. **Critic Agent** — analyzes the PRD across 3 dimensions: problem clarity, technical feasibility, success criteria. Cites sections, proposes concrete improvements.
2. **Judge Agent** — consolidates valid critiques and produces the final ("armored") PRD.

**What the user sees:** Only the debate result (the armored PRD), not the process. The debate is internal.

### 7.4 Human Checkpoints with Interrupt

Checkpoints are the heart of the system. When reached:

- The graph pauses completely and persists its state
- The Pal presents the artifact in plain language
- The user has full control: approve, request revision, or archive
- No phase advances without an explicit decision

This is not a bureaucratic step — it's the user's protection against premature automation.

---

## 8. Long-Term Memory — MemPalace

MemPalace uses the Wings / Rooms / Halls taxonomy to organize context.

### Structure

- **Main Wing:** Product Engineering
- **Rooms:** Principles · Architectural Decisions · Precedents · Projects

### Progressive Access Policy

| Moment | Who accesses                    | Scope                        | Reason                                   |
| ------ | ------------------------------- | ---------------------------- | ---------------------------------------- |
| M1     | PM Agent, Debate Agents         | Principles and anti-patterns | Load tenets before generating PRD        |
| M2     | Architect Agent                 | M1 + Technical precedents    | Consult past decisions before specifying |
| M3     | Execution Agent (post-approval) | Write to Projects/{runId}    | Save final artifacts to permanent memory |

**Rule:** Agents don't have indiscriminate access to memory. Progressive access prevents "memory tourism" and unnecessary token spend.

---

## 9. Non-Negotiable UX Principles

Derived directly from user research:

| Principle                         | Rule                                                     | Why                                                                 |
| --------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------- |
| **Free-form input**               | Never forms. Always conversation.                        | User knows what they want to _say_, not what they want to _fill in_ |
| **One question at a time**        | The Pal never asks more than one question per turn       | Multiple simultaneous questions are paralyzing for ADHD             |
| **Short sessions are valid**      | 1 exchange = real progress = state saved                 | Respects short focus windows                                        |
| **State visible on demand**       | Shows "which phase you're in" when asked — never imposed | Doesn't interrupt flow to show bureaucracy                          |
| **Pal tone, not process tone**    | Never evaluator, never gatekeeper                        | Desired relationship: patient companion                             |
| **Silent Parking Lot**            | Captures without interrupting                            | The Pal accompanies, doesn't block                                  |
| **Context summary**               | Always after >1h of inactivity                           | Eliminates mental reconstruction cost                               |
| **Plain language at checkpoints** | No technical jargon when presenting PRD/Spec             | Checkpoint 2 (Spec) is the highest abandonment risk point           |
| **Calibrated tickets**            | One ticket = one ~15-minute session                      | Respects the user's real focus window                               |

---

## 10. Mandatory Tech Stack

| Layer          | Technology                                   | Justification                                                                    |
| -------------- | -------------------------------------------- | -------------------------------------------------------------------------------- |
| Runtime        | Node.js >= 20 LTS                            | Ecosystem, performance, compatibility                                            |
| Language       | TypeScript 5.x (strict)                      | Type safety in complex state graph                                               |
| Orchestration  | LangGraph.js ^0.2.x                          | Native interrupt() for Human-in-the-Loop; the only thing that solves the problem |
| LLM            | Anthropic SDK ^0.24.x                        | Instruction quality, tool use support                                            |
| Memory         | MemPalace (milla-jovovich/mempalace) via MCP | Structured long-term memory with open protocol                                   |
| Infrastructure | Docker Compose v2                            | Isolation between app and MemPalace, reproducibility                             |
| Unit tests     | Vitest                                       | Fast, native TypeScript                                                          |
| E2E tests      | Playwright                                   | Mandatory gate for the interrupt→human→resume flow                               |

**Stack constraints:**

- No local SQL/NoSQL database in the MVP (AHA — no premature complexity)
- No additional web framework beyond what's needed for CLI/checkpoint webhook
- Checkpointer: MemorySaver (file) until there's a real need for distributed persistence

---

## 11. Directory Structure

```
/
├── docker-compose.yml
├── CONSTITUTION.md            ← versioned non-negotiable rules
├── .env.example
├── src/
│   ├── graph/
│   │   ├── state.ts           ← GraphState (central schema)
│   │   ├── graph.ts           ← graph compilation and routing
│   │   └── nodes/
│   │       ├── pal-conversation.ts     ← Phase 0: Pal converses
│   │       ├── cynefin-classifier.ts   ← Domain routing
│   │       ├── pm-agent.ts             ← Phase 1: PRD draft
│   │       ├── debate.ts               ← Phase 2: Critic + Judge
│   │       ├── checkpoint.ts           ← Phases 3 and 5: interrupt handler
│   │       ├── architect-agent.ts      ← Phase 4: Tech Spec
│   │       ├── execution-agent.ts      ← Phase 6: Tickets
│   │       ├── simple-agent.ts         ← Simple path (bypass)
│   │       ├── decomposition-agent.ts  ← Complex path
│   │       └── alert-agent.ts          ← Chaotic path
│   ├── memory/
│   │   └── mcp-client.ts      ← MCP client + inline access policy
│   ├── parking-lot/
│   │   └── detector.ts        ← Out-of-phase work detection
│   ├── artifacts/
│   │   └── writer.ts          ← .md generation with YAML frontmatter
│   └── main.ts                ← Entrypoint (CLI)
├── artifacts/
│   ├── prd/
│   ├── tech-spec/
│   └── tickets/
└── tests/
    ├── unit/
    └── e2e/
```

---

## 12. Delivery Phases — Sequential MVP

| Milestone | Deliverable                       | Completion Criteria                                                                  |
| --------- | --------------------------------- | ------------------------------------------------------------------------------------ |
| **M0**    | Scaffold + Docker Compose         | Both containers start, health check passes                                           |
| **M1**    | Cynefin Classifier + routing      | Classifier correctly routes to all 4 domains with unit tests                         |
| **M2**    | Simple path                       | Conversation → tickets without PRD, without debate                                   |
| **M3**    | Complicated path — Phases 1 and 2 | PM Agent + Debate (Critic + Judge) produce armored PRD                               |
| **M4**    | Human Checkpoint 1 (PRD)          | interrupt() pauses the graph; updateState() resumes; artifact saved                  |
| **M5**    | Phases 4 and 5 (Architect + CP2)  | Tech Spec generated with MCP context; CP2 functional                                 |
| **M6**    | Phase 6 (Execution + Parking Lot) | Tickets generated; Parking Lot injected at the correct phase; artifacts in MemPalace |
| **M7**    | Complex path (Decomposition)      | Decomposition Agent + Decomp Checkpoint + N independent sub-pipelines                |
| **M8**    | Chaotic path (Alert)              | Alert Agent + Stabilization Checkpoint + transition to Complex                       |
| **M9**    | Session Resumption                | Automatic summary after >1h; context recovered from MemPalace                        |
| **M10**   | Full E2E (mandatory gate)         | End-to-end Complicated pipeline with 2 approvals — Playwright green                  |

---

## 13. Success Metrics

Success is not technical. It's behavioral.

| Metric                          | 90-day Target                                | Failure Signal                                |
| ------------------------------- | -------------------------------------------- | --------------------------------------------- |
| Projects reaching Phase 6       | ≥ 1 real user project                        | 0 projects completed                          |
| Sessions resumed after >24h     | >50% of open sessions are resumed            | User abandons and starts from scratch         |
| Parking Lot used                | ≥ 1 item incorporated into a real project    | Feature exists but is never used              |
| Average session length          | 5–15 min                                     | >30 min (fatigue) or <2 min (abandonment)     |
| Cynefin classification accuracy | User doesn't correct domain in >80% of cases | User frequently disagrees with classification |
| **The Real Test**               | The company website was rewritten            | It wasn't                                     |

---

## 14. Kill Criteria

### Tier 1 — Hard Kill (automatic, no debate)

- 0 sessions completed in 30 days of real use
- P1 incident caused by the pipeline (corrupted data, overwritten PRD)
- Token cost > R$ 500/month with no project in production
- Sole maintainer absent for >2 weeks with no replacement

### Tier 2 — Review Trigger (default: kill, burden of proof on continuation)

- Average time per phase > 3 minutes (LLM stalling; review prompts)
- Cynefin classifier disagreed with in >30% of sessions
- 3 sprints with unplanned work on the same graph node

### Tier 3 — 30-day Success Criteria

1. ≥ 1 real project completes all 6 phases end to end
2. Parking Lot used in ≥ 1 project
3. 0 state loss incidents (interrupt + resume reliable)
4. 2+ people can modify a graph node and deploy independently
5. Session resumption tested and functional after a real gap of >24h

---

## 15. What This PRD Deliberately Does Not Solve (MVP)

| Out of Scope                            | When         | Reason                                                                                  |
| --------------------------------------- | ------------ | --------------------------------------------------------------------------------------- |
| Multi-user / team collaboration         | Future phase | ProjectPal is singular; validate the core loop first                                    |
| Integration with Jira / Linear / GitHub | Future phase | After validating that tickets have value without integration                            |
| Native voice input (STT)                | Post-MVP     | The conversational architecture supports voice; implementing STT is an infra dependency |
| Mobile                                  | Post-MVP     | Web first; mobile when core loop is validated                                           |
| Analytics dashboard                     | Post-MVP     | Logs are sufficient for MVP; dashboard is vanity before validation                      |

---

## 16. Architectural Decisions (ADRs)

### ADR-001: LangGraph.js for orchestration

Native `interrupt()` is the only primitive that solves Human-in-the-Loop with state persistence without additional infrastructure. There is no equivalent alternative in the Node.js ecosystem.

### ADR-002: MCP for MemPalace

Standardized protocol allows swapping the memory backend without changing agents. We don't couple to a specific implementation.

### ADR-003: MemorySaver as checkpointer

AHA — PostgreSQL/SQLite is premature complexity for a single-user MVP. Reversible: swapping the checkpointer doesn't change graph nodes.

### ADR-004: E2E as mandatory gate

The system's value is the interrupt→human→resume flow. Unit tests of isolated nodes don't prove the system works. Playwright gate before any merge.

### ADR-005: 1 Critic Agent, not 3

MVP uses 1 well-prompted Critic Agent with 3-dimensional analysis. Upgrade to multi-agent debate only if >50% of PRDs reach CP1 with undetected structural issues.

### ADR-006: Cynefin Classifier as LLM node

Domain classification is subtle enough to require natural language reasoning. A keyword-based heuristic would be brittle. Cost justified by the centrality of the routing decision.

### ADR-007: Complex = N independent pipelines (not dynamic subgraph)

Dynamic fan-out in LangGraph is compounding complexity (V3 — Compounding). Each decomposed sub-problem gets its own `runId` and enters the Complicated pipeline as a new independent session. Simpler, fully testable, no fan-in coordination problem.

### ADR-008: Parking Lot in GraphState + MemPalace

The Parking Lot doesn't need separate storage. It lives as a `parkingLot: Record<Phase, string[]>` field in GraphState during the active session, and is persisted to MemPalace at the end. Zero additional infra.

### ADR-009: Session Resumption inline in checkpoint node

The context summary is generated at the start of each checkpoint if the inactivity gap is >1h. It's not a separate module — it's conditional behavior inside the existing `runCheckpoint()`.

---

_PRD v3 — canonical document. Consolidates all user research, the Cynefin framework, the LLM debate architecture, and ProjectPal's UX principles. Awaiting Human Checkpoint 1._
