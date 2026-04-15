<!-- Ownership: ConnectorAdapter interface contract. All adapters (Gemini, Cursor) and callers (Router, FallbackHandler) import from this definition. Do not couple this file to any specific adapter. -->

# ConnectorAdapter Interface Contract

## Purpose

Defines the shared contract all connector adapters must implement. This is a contract-only artifact — no implementation lives here. Downstream tickets (004, 005, 006, 008, 009) depend on this shape to prevent interface drift and merge conflicts.

---

## ConnectorAdapter interface

```
ConnectorAdapter:
  invoke(task: DelegationTask, model_override: string | null) → DelegationResult
  check_status() → ConnectorStatusSnapshot
  heartbeat_hook(elapsed_seconds: int) → void
```

**Method notes:**

- `invoke` — executes the delegated task using the connector; applies `model_override` when provided, otherwise uses the connector's configured `preferred_model`.
- `check_status` — returns a point-in-time availability snapshot; must not mutate any state.
- `heartbeat_hook` — called by the internal polling loop approximately every 60 seconds during a long `invoke` call; adapters may no-op if they have no meaningful progress signal.

---

## DelegationResult

```
DelegationResult:
  result_state: string        # "success" | "failure" | "timeout"
  output: string | null
  failure_reason: string | null
  elapsed_seconds: int
```

**Field notes:**

- `result_state` must be one of the three literal strings above.
- `output` is null on failure or timeout.
- `failure_reason` is null on success; on failure, use one of: `"auth"`, `"quota"`, `"timeout"`, `"runtime_error"`, `"unknown"`.
- `elapsed_seconds` is always populated, including on failure.

---

## ConnectorStatusSnapshot

```
ConnectorStatusSnapshot:
  connector: string
  reachable: bool
  last_checked_at: ISO-8601 | null
  last_failure_at: ISO-8601 | null
```

**Field notes:**

- `connector` is the connector identity string (e.g. `"gemini"`, `"cursor"`).
- `reachable` reflects the result of the most recent `check_status` call.
- `last_checked_at` is null only before the first status check.
- `last_failure_at` is null if no failure has occurred in the current session.

---

## DelegationTask (reference — defined in state.yml schema)

ConnectorAdapter methods receive and reference `DelegationTask` instances. The full shape lives in the state.yml schema. Minimum fields expected by an adapter:

```
DelegationTask:
  task_id: string
  thread_id: string
  task_type: string
  acceptance_criteria_summary: string
  execution_path_id: string
```

---

## Constraints

- This file is the single source of truth for all three interface shapes above.
- No implementation code belongs here.
- Any change to signatures must be reflected in all downstream adapter files before merge.
