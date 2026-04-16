# ProjectPal North Star

**Status:** Canonical  
**Scope:** Long-term product vision, operating model, and continuity rules  
**Consolidates:** Earlier product drafts and the repo context lifecycle note

---

## 1. Product Thesis

**ProjectPal is a patient product companion that helps developers turn messy ideas into shipped projects without requiring them to become organized before they can begin.**

The product exists for one job: preserve momentum for developers who think non-linearly, lose context between sessions, and need the right next question more than they need another planning tool.

The system does that through four linked behaviors:

- conversation instead of intake forms
- one-question-at-a-time guidance
- durable continuity across sessions and repos
- phased artifact generation that can end in implementation, not just planning

The point is not to automate product management. The point is to build enough infrastructure around fragile project intent that it survives real life.

---

## 2. User And Problem

### Core user

The primary user is a developer or technical builder who thinks out loud, works in short focus windows, and does not reliably return with the same mental context they had before. They may jump phases, go deep on the wrong thing, or abandon a promising idea because reconstructing state costs too much.

### Root problem

Good technical ideas die for operational reasons, not because they were weak.

### The three failures ProjectPal is built to fix

1. **Most tools demand structure too early.** Developers often know what they want to say before they know how to frame it.
2. **Context decays between sessions.** Returning to a repo often means rebuilding the whole mental model from scratch.
3. **Out-of-phase work gets lost.** Hyperfocus on the wrong phase still produces useful material, but most systems treat it as noise.

### Product consequence

ProjectPal must behave like infrastructure for continuity, not like a form, dashboard, or evaluator.

---

## 3. North Star Outcome

### Core outcome

Projects that would normally stall in scattered notes, chats, or half-started branches reach a concrete implementation path and get shipped.

### Long-term test

Developers in the broader community can repeatedly take an idea from messy conversation to reviewed implementation without losing continuity between sessions.

### Working success signals

- real projects complete the full loop from conversation to implementation
- users can resume after a multi-day gap without re-explaining everything
- Parking Lot items are actually reincorporated later
- Refinement changes plans in meaningful ways instead of rubber-stamping them
- ticket sizing respects short focus sessions rather than producing oversized work

### Failure signals

- sessions restart from scratch because continuity failed
- Refinement never changes outcomes
- the system becomes heavier than the planning pain it was meant to remove
- infrastructure work keeps outrunning user value

---

## 4. Product Principles

These are non-negotiable.

### Relationship

- ProjectPal is a pal, not a PM, gatekeeper, or evaluator.
- It accompanies chaos without punishing it.
- It stays warm, plain-spoken, and direct.

### Interaction

- Conversation only. No forms.
- One question per turn.
- Short sessions count as real progress.
- State is visible on demand, not pushed on the user as bureaucracy.

### Flow protection

- Out-of-phase ideas are captured, not rejected.
- The Parking Lot is silent infrastructure, not a scolding mechanism.
- No phase advances without explicit user approval where Check-ins apply.

### Practicality

- The current product should prefer the lightest implementation that preserves the core behavior.
- Architecture can evolve later; continuity, tone, and Check-in quality cannot be sacrificed now.

---

## 5. Decision Architecture

ProjectPal routes work by problem shape, using a complexity model for developer work.

| Domain | Meaning | Default handling |
| --- | --- | --- |
| **Simple** | Known pattern, low ambiguity | Skip heavy planning and go straight to tickets and execution |
| **Complicated** | Requires analysis and deliberate planning | Full pipeline: Discovery, Brief, Refinement, Solution, Planning, Technical Details, Tickets, Implementation |
| **Complex** | Unknowns must be surfaced before planning | Decompose first, then run each sub-problem as Complicated |
| **Chaotic** | Immediate stabilization needed | Stop the bleeding first, then reclassify |
| **Disorder** | Not enough signal yet | Ask exploratory questions and bias toward Complicated |

### Routing rule

The system should always propose its classification in plain language and let the user confirm. Silent routing is not allowed.

### Current implementation stance

Today the classification is proposed conversationally and confirmed by the user. A future orchestrated version may automate more of this, but user confirmation stays the safety rail.

---

## 6. Phase Model

ProjectPal operates as a phased pipeline, but the phase model must feel conversational from the user's side.

| Phase | Outcome |
| --- | --- |
| **0. Discovery** | Understand the problem through free-form conversation |
| **1. Brief** | Generate the first scoped draft of the work |
| **2. Refinement** | Pressure-test the Brief before it comes back to the user |
| **3. Solution** | User approves, revises, or archives the proposed direction |
| **4. Planning** | Shape the technical approach quietly before the next Check-in |
| **5. Technical Details** | User approves, revises, or archives the technical plan |
| **6. Tickets** | Produce granular implementation tickets |
| **7. Implementation** | Execute tickets with verification and ownership clarity |
| **8. Wrap Up** | Review changes, route decisions, save memory, clean up |

### Alternate paths

- **Simple:** Discovery to Brief to Solution to Tickets to Implementation to Wrap Up
- **Complex:** decomposition inside Discovery before entering the full planning path
- **Chaotic:** stabilization before decomposition or planning

### Readiness rule for leaving Phase 0

ProjectPal should not leave open conversation until it can answer:

1. who has the problem
2. what the pain is
3. what direction is being considered
4. what success roughly looks like

Those checks are internal only. The user should never see them as a form.

---

## 7. Core Behaviors

### Parking Lot

The Parking Lot exists to preserve out-of-phase value without derailing the current phase.

- capture silently
- acknowledge briefly
- store with repo and phase tags
- surface again when the relevant phase begins

This is not optional. It is one of the main ways ProjectPal adapts to non-linear developer workflow instead of fighting it.

### Refinement

The Brief must be challenged before the user sees it as a proposed truth.

- **Architect** checks clarity, feasibility, and success criteria
- **Manager** decides which critiques stand and produces the refined result

The user sees the resulting Brief, not the internal back-and-forth, unless they ask.

### Check-ins

Check-ins are where the user regains full control. The artifact pauses there until the user approves, revises, or archives it.

### Session resumption

Every new session should start from the active repo context first, then summarize where things stand in 2-3 lines before asking whether to continue.

---

## 8. Current Product Architecture

### What exists now

The current product is a lean CLI-centered implementation designed to validate the core loop quickly with real developer workflows.

- prompt-driven behavior instead of a custom orchestration runtime
- sub-agents for Brief drafting, Refinement, Technical Details, and ticket generation
- `.projectpal/` inside the active repo for local bridge state and artifacts
- launcher adapters for Claude, Codex, and Gemini around the same source instructions

### Why this is the right current shape

The earlier orchestration-heavy design solved future scaling problems before validating the present product risk. The current architecture keeps the product behavior while stripping out premature infrastructure.

### Explicit current decisions

- No formal state machine yet
- No global continuity store
- No separate orchestration service
- No extra infra beyond what is needed to converse, remember, generate artifacts, and resume reliably

### What remains future-facing

ProjectPal can still evolve into a more formal orchestrated system later, but that is an optimization path, not the product definition.

---

## 9. Repo-Scoped Continuity

Repo continuity is a first-class product rule, not an implementation detail.

### Canonical rule

ProjectPal resolves continuity from the active repo first, not from one shared global state blob.

### Resolution rules

1. Detect repo root with `git rev-parse --show-toplevel`.
2. Use the repo-root directory name as `repo_slug`.
3. If git root detection fails, fall back to the current working directory name and treat it as low confidence.
4. Persist `repo_root_hint` in the local bridge whenever a git root is known.
5. If the current repo root and stored `repo_root_hint` disagree, ignore the stale bridge and initialize for the current repo.
6. A future global `projectpal` binary is only a launcher boundary. It must not become a second continuity system.

### Continuity sources

- **Local bridge:** `.projectpal/state.yml` inside the active repo
- **Local Parking Lot:** `.projectpal/parking-lot.md`

### Precedence

1. active repo detection
2. local bridge for that repo
3. fresh start if no local bridge exists

### Why this matters

It prevents stale state from leaking across repos and lets multiple worktrees keep independent local working copies.

---

## 10. Memory Model

ProjectPal uses local bridge memory only.

### Local bridge memory

`.projectpal/state.yml` is the repo-local bridge that keeps the current session resumable.

### Required schemas

#### ResumeBridge

- `repo_slug`
- `repo_root_hint`
- `current_project`
- `current_phase`
- `complexity_domain`
- `last_session`
- `resume_source`
- `synced_at`
- `artifacts_dir`
- `partial_context`
- `next_steps[]`

### Write order

1. local bridge (`.projectpal/state.yml`)
2. local Parking Lot markdown when relevant

---

## 11. Packaging Boundary

ProjectPal may later ship a public global Node CLI named `projectpal`, but that launcher must stay thin.

### Packaging rule

The launcher resolves repo context from the caller's current working directory, then delegates continuity to repo-local state.

### Implications

- existing Claude, Codex, and Gemini entrypoints are adapters, not separate products
- packaging work should add a launcher surface, not move continuity into a global directory
- install-time caches are acceptable later; repo continuity outside the repo is not

---

## 12. Scope Boundaries

### In scope now

- the conversational core loop
- complexity-informed routing
- Brief drafting and Refinement
- Technical Details generation
- granular tickets
- implementation flow
- Parking Lot capture and resurfacing
- repo-scoped continuity

### Out of scope for now

- multi-user collaboration
- deep external integrations before the ticket loop is proven
- heavyweight orchestration before the current loop is validated
- productizing extra infrastructure that does not improve continuity or shipping behavior

---

## 13. Evolution Path

The product should evolve in this order:

1. prove the current loop helps real projects get shipped
2. tighten continuity, quality, and implementation review
3. add packaging around the same behavior
4. only then consider formal orchestration if it unlocks clear product value

The core product should remain stable across that evolution:

- the Pal relationship
- one-question conversation
- complexity-based routing
- Refinement before commitment
- repo-first continuity
- Parking Lot as protected flow control

If those survive, the implementation can change without the product losing itself.

---

## 14. Future: External Model Routing (Connector Wiring)

When ProjectPal ships its own CLI tool with MCP support and orchestration machinery that runs outside the assistant runtimes, external model routing becomes viable.

### Near-term schedule (explicit)

**Connector wiring is not a near-term release target.** It stays in this document as the long-range product shape only. The repo may still carry small, experimental routing and adapter scaffolding toward a future CLI — that is **not** a promise to finish end-to-end connector wiring inside current assistant runtimes on any fixed horizon. Release checklists, parking-lot items, and `.projectpal/state.yml` **next_steps** should treat connector wiring as **backlog documented here**, not as an imminent ship commitment.

### The idea

Role-scoped ranked model preferences per agent role, configured via a config file (not hand-edited — set up interactively). Each sub-agent tries from the top of its preference list, falls back on availability failures (missing key, quota, errors), with the primary assistant model as the guaranteed floor.

### Why it's deferred

No current assistant runtime (Claude Code, Codex, Cursor) supports routing sub-agent calls to external models. This requires a thin orchestration layer that makes API calls to external providers — which means ProjectPal needs its own execution surface first.

### What exists

- Optional concept brief when authored: `.projectpal/artifacts/brief/connector-wiring.md`
- A post-setup config flow concept for editing role rankings after install
- **In-repo inventory (experimental, CLI-oriented):** TypeScript modules such as `src/connector-orchestration.ts`, `src/connector-router.ts`, `src/approval-gate.ts`, `src/register-default-adapters.ts`, `src/adapters/gemini-adapter.ts`, and `scripts/delegate-connector-call.ts` — useful for future wiring work, not required for day-to-day Pal behavior in assistants today.

### Prerequisites

- ProjectPal CLI tool with its own process boundary
- MCP server integration for model provider access
- Interactive setup flow that survives dropout at any step

### Success shape

Strategist runs on Gemini, API key expires, silently falls back to host model, session keeps going — no interruption.

---

## 15. Canonical Decision

**ProjectPal is defined by its user-facing behavior and continuity guarantees, not by a specific orchestration framework.**

Today that means a lightweight, repo-aware, prompt-driven system that can take a developer from messy conversation to reviewed implementation while preserving memory across interruptions.

Any future architecture is valid only if it strengthens that loop instead of replacing it with process.
