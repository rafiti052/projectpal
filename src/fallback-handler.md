<!-- Ownership: FallbackHandler contract for connector failure evaluation and persistence. -->

# FallbackHandler

## Purpose

Define the v1 fallback policy for connector failures. The handler evaluates materiality, writes fallback history, and returns the disclosure decision to the caller.

---

## Public interface

```
FallbackHandler:
  evaluate(task: DelegationTask, failure: NormalizedFailure) → FallbackEvaluation

FallbackEvaluation:
  fallback_type: "silent" | "disclosed" | "blocked"
  approval_required: bool
  material_impact: bool
  disclosure_message: string | null
```

---

## Materiality heuristic

The failure is material when the failed connector is the designated connector for the current phase/task route.

```
material_impact =
  failure.connector == ConnectorRouter.resolve(task.phase, task.task_type).connector
```

Rules:

- no matching route → `material_impact = false`
- failed connector differs from the designated connector → `material_impact = false`
- failed connector matches the designated connector → `material_impact = true`

In v1, Gemini failures during Phase 2 refinement are the primary material case.

---

## Persistence contract

Append one fallback record on every evaluation to `.projectpal/state.yml` under:

```yaml
thread_orchestration:
  fallback_records:
    - fallback_id: string
      task_id: string
      attempt_number: int
      fallback_type: retry_same_path | equivalent_substitution | path_switch_request | none
      from_execution_path_id: string | null
      to_execution_path_id: string | null
      changed_fields: [string]
      approval_required: bool
      disclosed_in_next_summary: bool
      outcome: succeeded | failed | awaiting_approval | blocked
```

Additional rules:

- append-only; never overwrite earlier records
- preserve unrelated state keys verbatim
- tag the record to the current thread/task boundary
- same-path fallback disclosure is attached to the next natural summary, not emitted here

---

## Lean v1 fallback policy

- Automatic recovery gets one `retry_same_path` attempt
- `equivalent_substitution` is automatic only inside the approved path boundary and same `quality_tier`
- Any change to `connector`, `provider`, `runtime_path`, `auth_scope`, or `quality_tier` requires approval handling
- If the connector cannot prove a safe equivalent substitute, stop after the same-path retry and mark the case for approval

This means `FallbackHandler` may return `approval_required = true` even when the user-facing prompt has not been shown yet.

---

## Disclosure contract

When `material_impact = true`, populate a human-readable disclosure message for the caller.

v1 baseline:

> The refinement step ran on the primary assistant because the routed connector was unavailable.

When `material_impact = false`, return `disclosure_message = null`.

The caller owns timing and phrasing of the visible disclosure.

---

## Constraints

- `FallbackHandler` evaluates and records; it does not invoke connectors
- It may consult `ConnectorRouter`, but it does not mutate routing rules
- It must not emit user-facing approval prompts directly
- It must not erase thread-local isolation when persisting records

---

## Verification checklist

- [ ] material failures populate `disclosure_message`
- [ ] non-material failures keep `disclosure_message = null`
- [ ] every evaluation appends one fallback record
- [ ] persisted records remain thread-scoped
- [ ] approval-required path changes are flagged without silently continuing
