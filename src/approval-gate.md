<!-- Ownership: ApprovalGate behavior contract. Single enforcement point for connector authorization. Reads and writes ~/.projectpal/routing.yml. -->

# ApprovalGate

## Purpose

The `ApprovalGate` is the single enforcement point for connector authorization. It must be consulted before any connector adapter is invoked. A connector may never be called without a passing gate check.

---

## Public interface

```
ApprovalGate:
  check(connector: string) → GateResult
  persist(connector: string, approved: bool) → void

GateResult:
  status: "approved" | "declined" | "pending"
  re_fired: bool
```

---

## Behavior rules

### `check(connector)`

Read `~/.projectpal/routing.yml`. Locate the entry under `connectors.<connector>`.

| `approved` value in routing.yml | Session decline flag set? | Result |
|---|---|---|
| `true` | any | `{ status: "approved", re_fired: false }` |
| `false` | **yes** | `{ status: "declined", re_fired: false }` |
| `false` | **no** | Fire approval prompt → `{ status: "pending", re_fired: true }` |
| `null` | any | Fire approval prompt → `{ status: "pending", re_fired: true }` |
| entry absent | any | Fire approval prompt → `{ status: "pending", re_fired: true }` |

**Important:** `approved: false` in `routing.yml` means "was declined in a prior session." At the start of a new session, the in-memory decline flag is unset, so the gate re-fires once. This is correct: the user can approve on a fresh attempt.

### Approval prompt (when firing)

Surface this once per connector per session:

> "To use [connector name] for this task, I need your go-ahead. Should I connect to [connector name] for this session?"

Accept any clear affirmative ("yes", "go ahead", "sure", "ok") as approval. Accept any clear negative ("no", "skip", "don't") as decline. If ambiguous, ask once more with a yes/no framing.

### `persist(connector, approved)`

Write the decision to `~/.projectpal/routing.yml`:

**If `approved = true`:**
- Set `connectors.<connector>.approved = true`
- Set `connectors.<connector>.approved_at` to current ISO-8601 timestamp
- Clear `connectors.<connector>.declined_at` (set to null)

**If `approved = false`:**
- Set `connectors.<connector>.approved = false`
- Set `connectors.<connector>.declined_at` to current ISO-8601 timestamp
- Clear `connectors.<connector>.approved_at` (set to null)
- Set the **session-scoped decline flag** in memory for this connector (never written to disk)

### Atomic write protocol

All writes to `routing.yml` must be atomic:

1. Read the current `routing.yml` content.
2. Apply the change in memory.
3. Write the full updated content to `~/.projectpal/routing.yml.tmp`.
4. Rename `routing.yml.tmp` → `routing.yml`.

Never write partial updates directly to `routing.yml`. If the rename fails, leave the original file intact and surface a warning.

---

## Session-scoped decline flag

The decline flag lives in memory only — it resets when the session ends (process restart, new conversation). It is keyed by connector name. Its only purpose is to prevent the approval prompt from re-firing within the same session after the user has already declined.

**Never persist the decline flag to disk.** `routing.yml` is the long-term store; the session flag is the short-term guard.

---

## Constraints

- The gate must fire before any adapter invocation. No exceptions.
- The gate fires **once per connector per session**. Do not re-prompt after a decision is made.
- `routing.yml` updates must not touch `routing_rules` or other connector entries.
- A missing or unreadable `routing.yml` must surface a descriptive error — it must not silently allow invocation.

---

## Interaction with ConnectorRouter

The typical call sequence is:

```
1. ConnectorRouter.resolve(phase, task_type)  → AdapterSelection or null
2. ApprovalGate.check(selection.connector)    → GateResult
3a. If status == "approved"  → proceed to invoke
3b. If status == "pending"   → surface prompt, then persist(connector, user_answer)
3c. If status == "declined"  → skip connector, fall back to primary
```

The Router never calls the gate. The caller (Orchestrator or phase handler) is responsible for running `check` between resolution and invocation.

---

## Verification checklist

- [ ] `check("gemini")` returns `status: "pending"` when routing.yml has `approved: null`
- [ ] `persist("gemini", true)` writes `approved: true` and a valid ISO-8601 `approved_at`; subsequent `check` returns `status: "approved"`
- [ ] `persist("gemini", false)` writes `declined_at`; subsequent `check` in same session returns `status: "declined"` without re-firing the prompt
- [ ] A new session reads `approved: false` from routing.yml and re-fires the prompt (decline is session-scoped, not persistent)
- [ ] routing.yml write is atomic (write-temp-then-rename)
- [ ] `GateResult.re_fired` is true only when the prompt was actually fired
