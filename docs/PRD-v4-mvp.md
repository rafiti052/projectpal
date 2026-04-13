# PRD v4: ProjectPal — MVP CLI with Claude Code

**Version:** 4.0  
**Status:** Approved — Shipped as v0.1  
**Evolves from:** PRD v3 (north star preserved in `docs/PRD-v3-north-star.md`)  
**Key decision:** Validate the core loop before scaling the infrastructure

---

## 1. Product Vision

**ProjectPal is an AI-powered product companion that turns chaotic ideas into executable projects — running as a CLI via Claude Code, with real multi-agent debate and persistent memory.**

The MVP validates the central hypothesis with the smallest possible infrastructure:

- Claude Code as runtime (no LangGraph, no Docker, no state machine)
- CLAUDE.md as the Pal's persona and rules
- Multi-agent debate via sub-agents (Agent tool) with distinct personas
- MemPalace via MCP for long-term memory
- Local files for session state and Parking Lot

Once the core loop is validated, the architecture scales to PRD v3 (LangGraph, formal orchestration, Cynefin auto-routing).

---

## 2. The Real Problem

_(Unchanged from PRD v3 — the problem is the same; the solution is what changes in scope.)_

### The human problem

Good ideas die not from lack of quality — but from lack of infrastructure to survive real life. The user thinks out loud, has short focus windows, and when that window closes, the idea goes to sleep.

### The three failures of the status quo

1. **Input demands structure the user doesn't have at the moment of the idea.** Current tools assume you know what you mean. The user knows what they want to _say_.

2. **Context doesn't survive discontinuity.** When the user stops and comes back days later, they need to mentally reconstruct the entire project state.

3. **Out-of-phase work is wasted.** When the user goes deep on something from the wrong phase (ADHD hyperfocus), the work is ignored or lost.

---

## 3. The Real User

_(Unchanged from PRD v3.)_

| Dimension            | Observation                          | Product Implication                                 |
| -------------------- | ------------------------------------ | --------------------------------------------------- |
| Thinking style       | Chaotic, non-linear, ADHD            | Input must never require prior structure            |
| Preferred channel    | Voice / natural conversation         | Primary interface: conversation                     |
| What drives progress | The right question at the right time | The system pulls — doesn't wait                     |
| Context memory       | Weak between sessions                | System remembers everything; user remembers nothing |
| Hyperfocus           | Goes deep in the wrong phase         | Parking Lot captures, doesn't block                 |
| Desired relationship | "A pal" — not a PM                   | Tone: patient companion                             |
| Task management      | Kanban as external memory            | Visible state interface, not imposed                |

---

## 4. Value Hypothesis

> **If the system acts as a patient companion that asks the right question, classifies the nature of the problem, preserves context between sessions, and captures out-of-phase work without losing it — then the user can ship ideas that currently die before taking shape.**

**The real success metric:** the company website was rewritten.

---

## 5. Core Architectural Decision — Why Claude Code

### What PRD v3 proposed

LangGraph.js as orchestrator, multiple LLM instances as agents, Docker Compose, native `interrupt()` for checkpoints, MemorySaver as checkpointer.

### Why change for the MVP

The PRD v3 infrastructure solves problems that don't exist yet. The real risk isn't technical — it's never validating the core loop because the infrastructure consumed all the time.

### What Claude Code already provides natively

| Need               | PRD v3 Solution                       | Claude Code Solution                               |
| ------------------ | ------------------------------------- | -------------------------------------------------- |
| Pal conversation   | LangGraph node `pal-conversation`     | CLAUDE.md loaded automatically                     |
| Multi-agent debate | Separate LLM instances                | Sub-agents via Agent tool (built-in) — real, distinct personas |
| Human checkpoints  | `interrupt()` + `updateState()`       | Conversation turn — "Sound right?"                 |
| State persistence  | MemorySaver / checkpointer            | MemPalace (long-term) + `.projectpal/` (session)   |
| Cynefin routing    | LLM classifier node with auto-routing | Pal suggests, user confirms                        |
| Parking Lot        | GraphState field                      | Markdown file managed by the Pal                   |
| Tool use           | Anthropic SDK with tool definitions   | Native to Claude Code                              |
| Infrastructure     | Docker Compose                        | None — it's a CLI                                  |

### What we lose (consciously accepted)

- **Formal state reproducibility** — without a state machine, state depends on the conversation + local files. Acceptable for a single-user MVP.
- **Cynefin auto-routing** — the human confirms the classification. This is actually better for the MVP (more HITL, less error risk).
- **Sub-pipeline parallelism** — Complex decomposition runs sequentially. Acceptable until there's volume.
- **E2E tests with Playwright** — no UI, no Playwright. Validation is: the project reached Phase 6.

### What we gain

- **Iteration speed** — prompts, not code. Behavior change = edit a .md file.
- **Immediate start** — zero setup beyond Claude Code + MemPalace.
- **Real debate** — sub-agents via Agent tool are separate instances with isolated context. Not self-review.
- **Portability** — prompts, phase model, and MemPalace schema migrate intact to LangGraph when needed.

---

## 6. Decision Architecture — Cynefin Framework (MVP)

_(Model unchanged from PRD v3. Simplified implementation.)_

| Domain          | Pal Behavior in MVP                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------- |
| **Simple**      | "This seems straightforward. I'll generate the tickets." → Conversation → Tickets                 |
| **Complicated** | "This deserves careful thought. Let's build a PRD together." → Full pipeline                      |
| **Complex**     | "Before any spec, we need to understand what you don't know yet." → Assisted manual decomposition |
| **Chaotic**     | "This sounds urgent. What's on fire right now?" → Stabilization first                             |
| **Disorder**    | Asks exploratory questions. Default: Complicated.                                                 |

**Difference from PRD v3:** In the MVP, the Pal suggests the classification and the user confirms. There's no automatic classifier as a separate node.

---

## 7. Workflow — Phases (MVP)

### Phase 0: Conversation with the Pal

The user speaks freely in the CLI. The Pal (via CLAUDE.md) asks ONE question at a time. When there's enough signal, it proposes the Cynefin classification.

Parking Lot is active: any out-of-phase idea is captured in `.projectpal/parking-lot.md`.

### Phase 1: Discovery (Complicated path)

The Pal generates a PRD draft using the `prompts/prd-generate.md` prompt, consulting MemPalace for principles and past decisions.

### Phase 2: Agent Debate

The PRD draft is submitted to two sub-agents invoked via Agent tool:

1. **Critic Agent** (`prompts/critic-agent.md`) — Analyzes problem clarity, technical feasibility, and success criteria. Persona: constructive skeptic, direct, cites specific sections.
2. **Judge Agent** (`prompts/judge-agent.md`) — Receives the original PRD + Critic's output. Accepts, partially rejects, or discards each critique. Produces the final (debated) PRD. Persona: senior arbiter, fair, decisive.

**The sub-agents are separate instances** with isolated context. It's not the same model doing self-review — they're distinct personas evaluating the same artifact independently.

The user sees only the final PRD. If they ask, they can see the full debate.

### Phase 3: Human Checkpoint 1 — PRD

The Pal presents the debated PRD in plain language:

> _"Here's what I understood. Sound right?"_

The user decides: **Approve** (advance) · **Revise** (loop) · **Archive** (close)

The approved PRD is saved to `artifacts/prd/` with YAML frontmatter.

### Phase 4: Technical Specification

The Pal generates the Tech Spec using `prompts/tech-spec-generate.md`, consulting MemPalace for architectural precedents. The Parking Lot from the previous phase is injected.

### Phase 5: Human Checkpoint 2 — Spec

The Pal presents a 3-line summary before the full document:

> _"Before the details: [summary]. Want to continue?"_

The user decides: **Approve** · **Revise** · **Archive**

### Phase 6: Execution

The Pal generates granular tickets in `artifacts/tickets/`, one at a time, calibrated for 15-minute sessions. Final artifacts are saved to MemPalace.

### Alternative Paths

- **Simple:** Phase 0 → Phase 6 (no PRD, no debate, no spec)
- **Complex:** Phase 0 → Pal-assisted decomposition → each sub-problem enters as Complicated
- **Chaotic:** Phase 0 → "What's on fire?" → Stabilization → Complex → Complicated

---

## 8. Essential Features (MVP)

### 8.1 Multi-Agent Debate

**Implementation:** Sub-agents via Claude Code's Agent tool.

```
Pal generates PRD draft
    ↓
Task → Critic Agent (prompts/critic-agent.md)
    input: PRD draft
    output: Review with verdict
    ↓
Task → Judge Agent (prompts/judge-agent.md)
    input: PRD draft + Critic review
    output: Final (debated) PRD + deliberation log
    ↓
Pal presents final PRD to user
```

**Why this is a real debate, not self-review:**

- Each sub-agent is a separate invocation with its own system prompt
- The Critic doesn't see what the Judge will do; the Judge doesn't influence the Critic
- Personas are distinct: the Critic is skeptical and direct; the Judge is measured and decisive
- Context is isolated — no agent "remembers" being the other

**Scalability:** Once validated, migrates to dedicated LLM instances in LangGraph without changing the personas. Prompts are portable.

### 8.2 Parking Lot

**Implementation:** File `.projectpal/parking-lot.md` managed by the Pal.

**Format:**

```markdown
# Parking Lot

- [phase-4] "Use Redis for MemPalace caching" (captured: 2025-01-15, during Phase 0)
- [phase-6] "Remember to test with a 48h gap" (captured: 2025-01-15, during Phase 1)
```

**Behavior:**

- Silent capture during any phase
- Brief confirmation: _"Noted that for the implementation phase."_
- Injection at the start of the relevant phase: _"Last week you mentioned X. Want to include it?"_
- Repo-scoped tags should be carried with each item so the active repo can be filtered before phase surfacing
- Mirrored memory should use the same `repo:`, `feat:`, `phase:`, and `kind:parking-lot` tags under `Projects/<repo-slug>`

### 8.3 Session Resumption

**Implementation:** At the start of each session, the Pal:

1. Detects the active repo from git root first
2. Reads `.projectpal/state.yml` for repo-local bridge state
3. Consults repo-scoped memory in `Projects/<repo-slug>` before any broader fallback
4. Presents a 2–3 line summary

> _"In the last session, you were reviewing the PRD for the website redesign. The Critic pointed out that the success criteria were vague and the Judge partially agreed. Next step: revise and approve. Want to continue?"_

### 8.4 Checkpoints as Conversation

In the MVP, checkpoints aren't technical mechanisms (`interrupt()`). They're conversation turns where the Pal pauses and asks. The effect is the same: nothing advances without an explicit user decision.

The difference is that "state" is the conversation + files, not a formal state machine. For a single-user MVP, this is sufficient.

---

## 9. MemPalace — Usage in MVP

### Proposed Structure

```
Wing: ProductEngineering
├── Room: Principles        ← Tenets, anti-patterns, design values
├── Room: Decisions         ← ADRs, architectural choices
├── Room: Precedents        ← Past tech specs, patterns used
└── Room: Projects
    └── Hall: {project-name}
        ├── prd.md
        ├── tech-spec.md
        └── tickets/
```

### Access Policy

| Moment            | Who accesses | What is read/written                         |
| ----------------- | ------------ | -------------------------------------------- |
| Phase 1 (PRD)     | Pal          | Read: Principles, Decisions                  |
| Phase 4 (Spec)    | Pal          | Read: Principles, Decisions, Precedents      |
| Phase 6 (Tickets) | Pal          | Write: Projects/{project-name}/              |
| Session start     | Pal          | Read: Projects/{project-name}/ (for summary) |

### Connection

Via MCP in `.mcp.json`. The Pal invokes MemPalace tools directly.

---

## 10. Non-Negotiable UX Principles

_(Unchanged from PRD v3. These are the product's DNA.)_

| Principle                     | Rule                                     |
| ----------------------------- | ---------------------------------------- |
| Free-form input               | Never forms. Always conversation.        |
| One question at a time        | Never more than one question per turn    |
| Short sessions are valid      | 1 exchange = real progress = state saved |
| State visible on demand       | Shows phase when asked — never imposed   |
| Pal tone                      | Patient companion, never gatekeeper      |
| Silent Parking Lot            | Captures without interrupting            |
| Context summary               | Always upon resuming a session           |
| Plain language at checkpoints | Zero jargon when presenting PRD/Spec     |
| 15-minute tickets             | Respects the real focus window           |

---

## 11. Tech Stack (MVP)

| Layer       | Technology                         | Justification                                    |
| ----------- | ---------------------------------- | ------------------------------------------------ |
| Runtime     | Claude Code CLI                    | Zero infrastructure; native conversation + tools |
| Persona     | CLAUDE.md                          | Loaded automatically by Claude Code              |
| Multi-agent | Agent tool (sub-agents)             | Isolated instances with distinct personas        |
| Memory      | MemPalace via MCP                  | Structured long-term memory                      |
| Local state | `.projectpal/` (YAML + MD)         | Session state without a database                 |
| Artifacts   | `artifacts/` (MD with frontmatter) | Git-versionable documents                        |
| Prompts     | `prompts/*.md`                     | Editable behavior without code                   |

**What's NOT in the MVP (and why):**

| Absent               | Reason                                                          |
| -------------------- | --------------------------------------------------------------- |
| LangGraph            | Orchestration is overkill before validating the loop            |
| Docker               | No services to isolate                                          |
| Node.js / TypeScript | No custom code — only prompts and configuration                 |
| Database             | MemPalace + local files are sufficient                          |
| Vitest / Playwright  | No code to test. Validation is: the project reached production. |
| CI/CD                | Single-user, single-machine                                     |

---

## 12. Directory Structure

```
projectpal/
├── CLAUDE.md                      ← Pal persona + rules + phase model
├── .mcp.json                      ← MemPalace connection
├── README.md                      ← Project documentation
├── prompts/
│   ├── critic-agent.md            ← Critic persona (sub-agent)
│   ├── judge-agent.md             ← Judge persona (sub-agent)
│   ├── cynefin-classify.md        ← Classification heuristics
│   ├── prd-generate.md            ← PRD generation
│   ├── tech-spec-generate.md      ← Tech spec generation
│   └── tickets-generate.md        ← Ticket generation
└── .projectpal/                   ← Per-project local state (managed by the Pal)
    ├── artifacts/
    │   ├── prd/                   ← Generated PRDs
    │   ├── tech-spec/             ← Generated specs
    │   ├── tickets/               ← Generated tickets
    │   └── debate/                ← Debate records
├── docs/
│   ├── PRD-v3-north-star.md       ← Full vision (LangGraph, Docker, etc.)
│   └── PRD-v4-mvp.md             ← This document
├── commands/                      ← (Reserved for future slash commands)
└── .projectpal/
    ├── state.yml                  ← Current session state
    └── parking-lot.md             ← Items captured out of phase
```

---

## 13. Milestones — Sequential MVP

| #            | Deliverable                           | Completion Criteria                              |
| ------------ | ------------------------------------- | ------------------------------------------------ |
| **M0**       | Scaffold + MemPalace connected        | Pal converses and reads/writes memory            |
| **M1**       | Cynefin classification working        | Pal classifies, user confirms                    |
| **M2**       | Simple path                           | Conversation → tickets in `artifacts/`           |
| **M3**       | Complicated path: PRD + Debate        | Critic + Judge produce debated PRD via Agent tool |
| **M4**       | Tech Spec + Tickets from approved PRD | Full pipeline for one real project               |
| **M5**       | Parking Lot + Session Resumption      | Context survives a 24h+ gap via MemPalace        |
| **The Test** | **The company website was rewritten** | **It shipped**                                   |

---

## 14. Success Metrics

| Metric                      | 90-day Target                  | Failure Signal                            |
| --------------------------- | ------------------------------ | ----------------------------------------- |
| Projects reaching Phase 6   | ≥ 1 real project               | 0 projects completed                      |
| Sessions resumed after >24h | >50% resumed                   | Abandons and starts from scratch          |
| Parking Lot used            | ≥ 1 item incorporated          | Feature exists but never used             |
| Debate changes the PRD      | >30% of PRDs altered by debate | Debate is a rubber stamp                  |
| Average session length      | 5–15 min                       | >30 min (fatigue) or <2 min (abandonment) |
| **The Real Test**           | **Website rewritten**          | **It wasn't**                             |

---

## 15. Kill Criteria

### Hard Kill (automatic)

- 0 sessions completed in 30 days
- MemPalace fails consistently (>3 sessions with context loss)
- Token cost > R$ 500/month with no project shipped

### Review Trigger (default: kill)

- Debate never alters the PRD (Critic + Judge are useless → simplify to self-review)
- Cynefin classification disagreed with in >30% of sessions
- Session resumption fails consistently (user needs to re-explain context)

### 30-day Success Criteria

1. ≥ 1 real project completes Phases 0–6
2. Parking Lot used in ≥ 1 project
3. Debate altered ≥ 1 PRD in a way the user found useful
4. Session resumption functional after a real gap of >24h
5. Prompts iterated ≥ 3 times based on actual usage

---

## 16. Out of Scope (MVP)

| Out                                | When                              | Reason                                     |
| ---------------------------------- | --------------------------------- | ------------------------------------------ |
| LangGraph / formal orchestration   | When core loop validated          | PRD v3 is the roadmap                      |
| Multi-user                         | Future phase                      | Validate single-user first                 |
| Jira / Linear / GitHub integration | Future phase                      | Tickets must have value before integrating |
| Voice input (STT)                  | Post-MVP                          | Architecture supports it; infra not ready  |
| Dashboard / analytics              | Post-MVP                          | Logs are enough                            |
| Web / mobile UI                    | Post-MVP                          | CLI first                                  |
| Multiple Critics in debate         | When 1 Critic proves insufficient | ADR-005 from PRD v3                        |

---

## 17. Architectural Decisions (ADRs) — MVP

### ADR-MVP-001: Claude Code as runtime

Eliminates all orchestration infrastructure. CLAUDE.md defines persona and rules. Agent tool enables real multi-agent debate. Reversible: prompts migrate to LangGraph without changes.

### ADR-MVP-002: Sub-agents via Agent tool (built-in) for debate

Agent tool instantiates sub-agents with isolated context and distinct system prompts. Not self-review — they are separate invocations. Validates the debate hypothesis before investing in dedicated infrastructure.

### ADR-MVP-003: State in local files + MemPalace

`.projectpal/state.yml` for session state; MemPalace for long-term memory. No database. Reversible: migrates to MemorySaver/checkpointer when needed.

### ADR-MVP-004: No automated tests

No custom code = no unit tests. Validation is behavioral: did the project reach Phase 6? Was the debate useful? Did context survive? Formal tests come with formal code (LangGraph).

### ADR-MVP-005: Prompts as configuration

All behavior lives in `.md` files. Iterating on the product = editing a prompt. No deploy, no build, no restart. Maximum iteration speed.

### ADR-MVP-006: MemPalace preserved from MVP

Long-term memory is core to the value proposition (Failure 2: context doesn't survive). Non-negotiable even in the leanest MVP. Data written to MemPalace in the MVP will be used in the LangGraph version — zero migration.

---

## 18. Evolution Path: MVP → PRD v3

```
MVP (now)                            PRD v3 (when validated)
─────────────                        ─────────────────────────
Claude Code CLI                  →   LangGraph.js + Node.js
CLAUDE.md                        →   pal-conversation node
Agent tool sub-agents             →   Dedicated LLM instances
Conversation as checkpoint       →   interrupt() + updateState()
.projectpal/state.yml            →   MemorySaver / checkpointer
Cynefin suggested by Pal         →   Classifier node with auto-routing
Parking Lot in .md               →   GraphState field
Prompts in .md                   →   System prompts in graph nodes
No Docker                        →   Docker Compose
No tests                         →   Vitest + Playwright
```

**Everything built in the MVP migrates.** Prompts, personas, MemPalace schema, phase model, and generated artifacts. The infrastructure changes; the product doesn't.

---

_PRD v4 — MVP CLI with Claude Code. Real multi-agent debate with distinct personas. MemPalace from day 1. Validate the core loop before scaling. Awaiting Human Checkpoint 1._
