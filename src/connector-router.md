<!-- Ownership: ConnectorRouter behavior contract. Reads routing_rules from ~/.projectpal/routing.yml and selects the correct adapter for a given phase + task type. Read-only against all persistent state. -->

# ConnectorRouter

## Purpose

The `ConnectorRouter` decouples phase/task routing logic from adapter implementations. It reads `routing_rules` from `~/.projectpal/routing.yml` and returns the appropriate adapter selection for a given phase and task type. It does not invoke any adapter and does not write any state.

---

## Public interface

```
ConnectorRouter:
  resolve(phase: int, task_type: string) → AdapterSelection | null

AdapterSelection:
  connector: string
  adapter: ConnectorAdapter   # instantiated adapter instance
  model: string
  fallback: string
```

---

## Behavior rules

1. **Read at call time.** Load `routing_rules` from `~/.projectpal/routing.yml` on every `resolve` call. Do not cache — rules may change between calls without a process restart.

2. **First-match wins.** Evaluate rules top-to-bottom. Return the first rule where both `phase` and `task_type` match exactly.

3. **Null on no match.** If no rule matches, return `null`. Callers must treat `null` as "use primary assistant" and must not attempt adapter invocation.

4. **Instantiate the adapter.** For the matched rule, retrieve or create the adapter instance registered under `connector`. If the connector name is not registered, raise a descriptive configuration error — never return `null` silently for a matched-but-unregistered connector.

5. **Model comes from the rule.** The returned `model` is always taken from the matched rule's `model` field. Ignore `preferred_model` from the connector entry for this lookup.

6. **Cursor is never returned in v1.** No routing rule references Cursor in the initial schema. `resolve` must never return a Cursor adapter unless a rule is explicitly added to `routing.yml`.

---

## Current routing table (v1)

| Phase | Task type | Connector | Model | Fallback |
|-------|-----------|-----------|-------|----------|
| 2 | refinement | gemini | gemini-fast | primary |

---

## Registered adapters (v1)

| Connector | Adapter file |
|-----------|-------------|
| `gemini` | `src/adapters/gemini.md` (ticket 006) |
| `cursor` | `src/adapters/cursor.md` (ticket 009) — registered but not routed |

When `resolve` is called, the connector name from the matched rule is looked up in this registry. If not found, surface:

> "Connector '[name]' matched a routing rule but is not registered. Check routing.yml and ensure the adapter is installed."

---

## Error handling

| Condition | Behavior |
|-----------|----------|
| `routing.yml` missing | Raise: "routing.yml not found at ~/.projectpal/routing.yml. Run install to create it." |
| `routing.yml` malformed (not valid YAML or missing `routing_rules`) | Raise: "routing.yml is malformed. Expected a 'routing_rules' array." |
| Matched connector not in adapter registry | Raise descriptive config error (see above). |
| No matching rule | Return `null` silently. |

**Never swallow errors silently for matched-but-broken cases.** Only no-match is a valid silent null.

---

## Constraints

- Read-only. The Router never writes to `routing.yml`, `state.yml`, or any other file.
- Does not consult `ApprovalGate`. That is the caller's responsibility.
- Does not invoke any adapter.
- Rule order in `routing.yml` is significant — preserve it.

---

## Interaction with ApprovalGate

The typical call sequence (owned by the Orchestrator, not the Router):

```
1. ConnectorRouter.resolve(phase, task_type)   → AdapterSelection or null
2. if null → use primary assistant, stop
3. ApprovalGate.check(selection.connector)     → GateResult
4. if declined → use primary assistant, stop
5. if pending  → surface prompt, persist, re-check
6. if approved → selection.adapter.invoke(task, selection.model)
```

---

## Verification checklist

- [ ] `resolve(2, "refinement")` returns `AdapterSelection` with `connector: "gemini"`, `model: "gemini-fast"`, `fallback: "primary"`
- [ ] `resolve(1, "anything")` returns `null`
- [ ] `resolve(2, "not-refinement")` returns `null`
- [ ] Cursor is never returned by `resolve` given the v1 routing table
- [ ] A routing.yml with an added rule is picked up on the next call without restart
- [ ] A missing routing.yml raises a descriptive error, not a silent null
- [ ] A malformed routing.yml raises a descriptive error, not a silent null
