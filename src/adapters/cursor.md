<!-- Ownership: Cursor adapter contract for repo-aware registration and environment checks. -->

# Cursor Adapter

## Purpose

Define the v1 Cursor adapter boundary. Cursor is a first-class assistant install target, but not a routed model connector in v1.

---

## Public interface

```
CursorAdapter:
  invoke(task: DelegationTask, model_override: string | null) → InvocationResult
  check_status() → { reachable: boolean; last_checked_at: string | null; last_failure_at: string | null }
  heartbeat_hook(elapsed_seconds: int) → void
```

The shared shape definitions live in the deferred connector contract (not required for v0.4 install surfaces).

---

## Registration contract

Cursor support has two surfaces:

1. Global registration in `~/.cursor/mcp.json`
2. Repo-local context in `.cursor/rules/projectpal.md`

The global config must preserve existing non-ProjectPal entries and idempotently ensure one `projectpal` registration entry.

Required registration metadata:

- `connector = "cursor"`
- `version = 1`
- `routing_rules = []`

The registration entry should also retain enough metadata to point back to the ProjectPal source repo and the Cursor rules template.

---

## Invocation contract

`invoke` is intentionally a no-op in v1.

Return:

```
InvocationResult:
  result_state: "skipped"
  output: null
  failure_reason: "cursor adapter is not routable"
  elapsed_seconds: 0
```

The Router must not dispatch Cursor unless a future routing rule explicitly adds it.

---

## Status contract

`check_status()` validates the install surface without mutating repo state.

Rules:

- Confirm `~/.cursor/mcp.json` exists
- Confirm the global config contains the ProjectPal registration entry
- Read `.projectpal/state.yml` at call time to determine whether Cursor is the current `primary_assistant`
- Report `reachable = true` only when the registration entry is present
- Set `last_failure_at` when the registration file is absent or malformed

Environment validation is advisory:

- Missing Cursor app/binary is a warning, not a hard error
- Missing registration entry is a status failure

---

## Heartbeat contract

`heartbeat_hook(elapsed_seconds)` is a no-op for Cursor in v1.

The method exists only to satisfy the shared connector interface.

---

## Constraints

- No routing logic in v1
- No writes to `.projectpal/state.yml`
- No writes to connector routing configuration (connector runtime is deferred in v0.4).
- Global registration must be idempotent
- Repo-local rules creation belongs to repo-preparation / install flow, not `check_status()`

---

## Verification checklist

- [ ] running registration twice leaves one `projectpal` entry in `~/.cursor/mcp.json`
- [ ] `invoke` returns `skipped` without side effects
- [ ] `check_status` reports `reachable = true` when the ProjectPal entry exists
- [ ] `check_status` reports `reachable = false` when the registration file is absent
- [ ] missing Cursor runtime is logged as a warning only
- [ ] the adapter performs lazy primary detection by reading state at call time
