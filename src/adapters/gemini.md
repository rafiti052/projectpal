<!-- Ownership: Gemini adapter contract for delegated external-model calls. -->

# Gemini Adapter

## Purpose

Define the v1 Gemini adapter boundary for delegated refinement work. This adapter is an internal connector, not a user-facing assistant surface.

---

## Public interface

```
GeminiAdapter:
  invoke(task: DelegationTask, model_override: string | null) → DelegationResult
  check_status() → ConnectorStatusSnapshot
  heartbeat_hook(elapsed_seconds: int) → void
```

The shared shape definitions live in `src/adapters/connector-adapter.md`.

---

## Invocation contract

### Model resolution

Resolve the model in this order:

1. `model_override` when provided
2. `connectors.gemini.override_model` from `~/.projectpal/routing.yml` when non-null
3. `connectors.gemini.preferred_model` from `~/.projectpal/routing.yml`
4. hard fallback: `gemini-fast`

### Auth contract

- Primary auth source: `GEMINI_API_KEY`
- Optional fallback: platform keychain lookup when the runtime supports it
- Never write keys, token material, account identity, or billing data to disk
- Missing auth returns `DelegationResult.result_state = "failure"` with `failure_reason = "auth"`

### Network contract

- Use standard HTTP
- Default model maps to Gemini Flash-class latency (`gemini-fast`)
- `gemini` is the standard-quality override
- The adapter owns request/response normalization, not persistence

### Return contract

`invoke` must always return a populated `DelegationResult`:

- `result_state = "success"` when output is available
- `result_state = "failure"` when auth, quota, or runtime failure prevents output
- `result_state = "timeout"` when the connector times out before a usable response

`elapsed_seconds` is always set, even on failure.

---

## Heartbeat contract

Long-running Gemini calls must surface progress without relying on threads or worker processes.

Default path:

1. Dispatch the HTTP request
2. Start an internal elapsed-time polling loop
3. Call `heartbeat_hook(elapsed_seconds)` approximately every 60 seconds while awaiting the response

Blocking-runtime fallback:

- If the runtime cannot yield during the request, emit one pre-call progress signal before the request begins
- Document this code path with the note: `pre-call fallback: loop blocked`

`heartbeat_hook` may log, emit an event, or forward to a runtime-specific update surface. The default implementation is a plain progress log.

---

## Status contract

`check_status()` returns one `ConnectorStatusSnapshot`.

Rules:

- `connector = "gemini"`
- `reachable = true` only when the API is reachable with the current auth context
- `last_checked_at` reflects the current status probe time
- `last_failure_at` is read from in-memory failure state only
- No direct writes to `.projectpal/state.yml` belong here

Persistence remains owned by `FallbackHandler`.

---

## Failure normalization

Normalize failures to the narrow set already used by the shared connector contract:

- `auth`
- `quota`
- `timeout`
- `runtime_error`
- `unknown`

If Gemini cannot prove a more specific reason, return `unknown`.

---

## Constraints

- Internal-only connector. The user never selects Gemini directly.
- No user-facing approval prompt is emitted from this adapter.
- No persistent state writes from `invoke` or `check_status`.
- Same-path retry policy is owned by the orchestration layer, not the adapter.

---

## Verification checklist

- [ ] `model_override` wins over routing config
- [ ] missing `GEMINI_API_KEY` returns a descriptive auth failure
- [ ] heartbeat emits during a simulated long-running request
- [ ] pre-call fallback emits once when the runtime blocks the polling loop
- [ ] `check_status()` reports `reachable = false` on auth or transport failure
- [ ] no state files are mutated directly by the adapter
