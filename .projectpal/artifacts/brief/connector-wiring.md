---

## project: connector-wiring
phase: 1
type: brief
status: refined
created: 2026-04-15
complexity: complicated

## Problem Statement

ProjectPal has substantial connector infrastructure — router, registry, approval gate, fallback handler, a full Gemini adapter, and adapter contracts for other providers — but none of it is invoked on the live sub-agent execution path the product uses today. Every sub-agent (Strategist, Architect, Manager, and others) runs on whatever model the host assistant supplies, with no supported way to prefer a different external model or to continue reliably when a preferred path is unavailable.

Two distinct gaps produce this pain. First, the **runtime wiring is absent**: adapters exist but are never called when sub-agents spin up. Second, the **operator preference model does not exist**: there is no way for an operator to express "try Gemini first, then fall back to the host" as a durable, role-scoped configuration.

## User Profile

The primary stakeholder is someone building or operating ProjectPal who wants sub-agents to spin up against different models as part of normal product behavior — not a one-off manual experiment. They think in terms of agent roles and a ranked preference of models, not a single fixed binding. They accept a config file as the source of truth. They do **not** want setup to over-configure them: install lays down a **default ranking** without forcing a long wizard, the optional guided path lets them **drop out at any time**, and **changing rankings happens later** in a dedicated **config flow**, not during initial setup. Connector use is **opt-in** — they approve and follow connect steps **only if** they want external models. They care specifically about availability-class failures (missing credentials, quota exhaustion, request errors), not automatic escalation based on response quality. They pointed to the claudeoctopus pattern as a reference for provider-style routing and graceful degradation, while wanting a leaner shape: ranked preferences per role, availability-based fallback, and the primary assistant as the guaranteed floor.

## Proposed Solution

Introduce **role-scoped ranked model routing** distinct from the repo's current `routing.yml` concept (which maps phase + task_type to a connector). The new behavior maps **agent role → ordered list of model/provider options**, tries the list from the top, and on availability failures moves down the chain until the run lands on the **primary assistant model** as the non-negotiable floor. **Default rankings are written during install/setup** so the product works out of the box. **Editing rankings is out of setup** — it belongs in a separate **config flow** (see parking lot: `connector-config-flow`). An **optional** guided wizard may walk through connector **approval and connection steps only** for operators who want external models; it must allow **dropout at any step** and must **not** block core ProjectPal use if skipped.

Fallback semantics are explicit: if a call fails for an availability-class reason, try the next option. If a model returns any response, that attempt counts as success — this is not a quality-based rerouter.

### User Goals

- Run ProjectPal sub-agents using different models instead of everything forced onto the host assistant's model.
- Have a ranking of models to try, always falling back until reaching the primary model (the assistant itself) — so nobody gets stuck.
- Restrict automatic stepping to availability failures (missing API key, quota issues, errors), not response quality.
- Get a **sensible default ranking on install** without being forced through ranking editors in setup.
- **Change rankings later** via a dedicated config flow, not during initial setup.
- **Opt into** external connectors: approve and follow connect steps **only when** they want them; otherwise stay on defaults and the primary assistant floor.
- Take inspiration from claudeoctopus-style provider routing and graceful degradation, adapted to a leaner ProjectPal version.

### UX Outcomes

- **Continuity**: A session keeps going without operator-visible interruption when a preferred external route becomes unusable mid-run (e.g., Strategist configured for Gemini, API key expires, system falls back to the host model).
- **Predictability**: For a given agent role, behavior follows a clear ordered try list rather than opaque "whatever the host picked."
- **Light setup**: Initial experience does not over-setup — defaults ship, optional steps only for those who want connectors, **dropout allowed at any wizard step** with no penalty to using ProjectPal on the primary assistant.
- **Operator confidence**: Durable file-backed defaults plus a **later config flow** for power users who want to tune rankings without YAML surgery at install time.
- **Grace under failure**: Missing credentials, exhausted quota, and hard errors produce automatic downgrade rather than dead-ends — ending at the assistant floor.

### Value Framing

This turns existing connector work from "present in the repo" into runtime leverage: cheaper/faster external models become usable where appropriate without sacrificing reliability. It reduces operational fragility (keys, quotas, transient provider outages) by making degradation a first-class path instead of a special-case incident. It also creates a cleaner product seam between routing policy (per role, ranked) and invocation mechanics (adapters, approval, logging), which should make future provider additions less ad hoc.

## Success Criteria

- For the **Strategist** role using **Gemini** as the preferred external model: when that path fails for an availability-class reason (e.g., API key expires), the system falls back to the host assistant model and the session continues without operator-visible interruption.
- At least one minimal, verifiable signal confirms fallback occurred (session artifact annotation, log entry, or equivalent) — sufficient to validate the mechanism without requiring new observability infrastructure.
- Ranked preferences are per agent role, persisted in a config file; **defaults are installed during setup** without requiring the user to author rankings there.
- Optional wizard: user can **exit at any time**; connector approval and connect steps appear **only if** the user opts in.
- On availability failure, the system advances to the next ranked option; when all external options are exhausted, execution uses the primary assistant as the guaranteed floor.
- If an external model returns a response, routing does not treat "bad quality" as a reason to try the next model.
- Phase 1 proves the pipe for **Strategist + Gemini** at minimum. Additional roles and connectors may be added within Phase 1 if explicitly scoped, but are not required for v1 success.

## Scope

**In scope**

- Ranked model preference per agent role, with sequential attempts and availability-based fallback.
- Config file as the durable source of truth; **default rankings written on install** so behavior is defined without user-authored YAML during setup.
- **Optional** guided path for connector **approval and connection** only when the user wants external models; **dropout at any step**; no forced ranking UI in setup.
- **Separate config flow** (post-setup) for **editing rankings** — not part of install/setup (aligns with `feat:connector-config-flow` in the parking lot).
- Primary assistant model as the final fallback floor.
- Lean claudeoctopus-inspired pattern: ranked preferences + graceful degradation, without parity to all claudeoctopus features.

**Routing precedence rule**

The repo currently maps `phase + task_type → connector` via `routing.yml`. This effort introduces a new axis: `agent role → ranked model preferences`. The precedence is: **role-scoped routing takes priority** when a sub-agent is being invoked. The existing phase/task_type routing remains available for non-sub-agent delegation. If both axes could apply, the role-scoped ranked list wins — the phase/task_type axis does not override an operator's per-role preference.

**Approval gate interaction**

External model attempts must pass through the existing approval gate before invocation. A connector that has not been approved by the operator is skipped in the ranked list (treated as unavailable), not silently invoked. This preserves the existing consent model without adding a new compliance framework.

**Availability-class failures (explicit taxonomy)**

Fallback triggers on these failure classes only:

- Missing or invalid credentials (API key absent, expired, or rejected)
- Quota or rate-limit signals (429, provider-specific quota responses)
- Transport failures (connection timeout, DNS failure, TLS errors)
- Provider server errors (5xx-class HTTP responses)

Explicitly excluded: successful responses with low-quality or unexpected content. If the model responds, the attempt is considered successful for routing purposes.

**Cursor in v1**

Cursor is registered but intentionally not routable as an external connector in v1. This is compatible with role-scoped routing — Cursor simply does not appear as a ranked option. This constraint is unchanged from the existing adapter contract.

**Explicitly out of scope**

- Quality-based fallback (detecting "garbage" responses and rerouting).
- Anything beyond the stated availability failure classes.
- **Ranking editors or deep connector tuning inside the initial setup wizard** — that stays in the later config flow.

## Risks & Open Questions

- **Config schema and migration**: The exact config format, filename, and migration story from existing `routing.yml` / templates is not yet specified. This is a Phase 1 closure item — must be decided before implementation begins.
- **Setup wizard vs config flow split**: Wire exact UX for optional approve/connect steps (dropout semantics, idempotency) and defer ranking edits to the config-flow track. Must be concrete enough for ticketing.
- **Default ranking template**: Which roles get non-trivial defaults vs primary-only on first install — needs a one-line product default for Phase 1.
- **"Silent" vs trustworthy operations**: The minimal observability contract (what signal proves fallback happened) needs a concrete implementation decision — log, session artifact annotation, or state.yml entry.
- **Additional roles beyond Strategist**: Phase 1 proves Strategist + Gemini. Whether other roles (Architect, Manager, Tech Lead, etc.) are wired in Phase 1 or deferred to a follow-up is an open scoping decision.
- **Error boundary precision**: Provider SDKs blur lines between error classes. The taxonomy above is intentionally conservative; edge cases (e.g., 403 that means "quota" vs "auth") may need provider-specific mapping.

## Kill Criteria

- If per-role ranked preferences are not real in practice (roles still effectively bind to the host model only), this is not delivering the core promise — pause and redesign.
- If "fallback" becomes quality-based rerouting or vague heuristics, it violates an explicit Phase 0 boundary — stop and reset scope.
- If the assistant floor is not reliably reachable under real failure modes (agents can stall or require manual intervention when external routes fail), the primary continuity goal is not met.
- If setup **forces** ranking configuration, **blocks dropout**, or **requires** connector connection before basic ProjectPal use, the solution does not match the agreed operator model.
- If defaults are not installed automatically or rankings can only be changed by hand-editing raw config with no config flow path, the solution does not match the agreed operator model.

