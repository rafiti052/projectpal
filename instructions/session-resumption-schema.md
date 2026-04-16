

# Session Resumption Schema

## Startup precedence rule

1. Detect the active repo first.
2. Read `.projectpal/state.yml` for the current repo first.
3. If the local bridge exists and matches the current repo, it wins for the live session.
4. If the local bridge is missing or too incomplete to resume safely, start fresh in Phase 0.

## Repo resolution rule

- Resolve `repo_slug` from `git rev-parse --show-toplevel` and use the repo-root directory name as the slug.
- If git root detection fails, fall back to the current working directory name and mark the result internally as low confidence.
- Store a `repo_root_hint` in `.projectpal/state.yml` whenever a git root is available. If the stored hint does not match the current repo root, ignore the old bridge state and reinitialize it for the current repo.
- First visit behavior: if `.projectpal/state.yml` exists for the current repo, seed the resume summary from it. If neither exists, start fresh in Phase 0.
- Parallel repo handling: different repos never share a bridge file. Each worktree keeps its own local bridge as the primary live-session state.

## Schema contract

`ResumeBridge` lives in `.projectpal/state.yml` and carries:

- `repo_slug`
- `repo_root_hint` when known
- `current_project`
- `current_phase`
- `complexity_domain`
- `last_session`
- `resume_source`
- `synced_at`
- `artifacts_dir`
- `partial_context`
- `thread_orchestration`
- `next_steps[]`

## Thread-local orchestration schema

Lean v1 stores orchestration data under `thread_orchestration` in `.projectpal/state.yml`.

- Every record in this block is thread-scoped.
- Never inherit `primary_assistant`, `approval_state`, `approved_execution_path_id`, or fallback history into a different thread.
- `shared_context_refs[]` may point at reusable artifacts or repo memory, but those refs do not transfer orchestration ownership or approval across threads.

`ThreadOrchestrationState` lives under `thread_orchestration.threads[]` and carries:

- `thread_id`
- `primary_assistant`
- `reporting_owner` = `pal`
- `state` = `active | waiting_for_approval | blocked | completed`
- `approved_execution_path_id`
- `approval_state` = `not_needed | approved | approval_required | denied`
- `shared_context_refs[]`
- `created_at`
- `updated_at`

`ExecutionPathRecord` lives under `thread_orchestration.execution_paths[]` and carries:

- `execution_path_id`
- `assistant`
- `connector`
- `provider`
- `runtime_path`
- `model`
- `quality_tier` = `premium | standard | fast`
- `auth_scope`
- `selection_reason`
- `approved_by_user`
- `approved_at`

Notes:

- The approved path boundary is defined by `connector`, `provider`, `runtime_path`, `auth_scope`, and `quality_tier`.
- If any boundary field changes, the candidate path is outside the approved path and `approval_required = true`.
- A model swap is automatic only when it stays inside the same approved path boundary and the same `quality_tier`.

`ConnectorStatusSnapshot` lives under `thread_orchestration.connector_status_snapshots[]` and carries:

- `connector_identity`
- `auth_state` = `available | missing | expired | denied | unknown`
- `availability_state` = `available | degraded | unavailable | unknown`
- `last_failure_reason` = `none | quota_exhausted | connector_exhausted | auth_failure | runtime_error | unknown`
- `quota_state` = `available | exhausted | unknown`
- `checked_at`

Persistence guard:

- `connector_owns_auth` = `true`
- `allowed_metadata_fields[]` = `auth_state`, `availability_state`, `last_failure_reason`, `quota_state`
- `connector_identity` and `checked_at` may be stored as non-secret structural context.
- Never persist raw credentials, token material, token fingerprints, account identity, billing identifiers, or raw quota numbers.
- If the connector cannot safely expose a metadata field, persist `unknown` instead of inferring detail.

`DelegationTask` lives under `thread_orchestration.delegation_tasks[]` and carries:

- `task_id`
- `thread_id`
- `task_type` = `drafting | critique | bounded_implementation`
- `acceptance_criteria_summary`
- `execution_path_id`
- `delegated`
- `result_state` = `pending | succeeded | failed | blocked`
- `user_visible_emitter` = `primary_assistant`
- `started_at`
- `finished_at`

`FallbackRecord` lives under `thread_orchestration.fallback_records[]` and carries:

- `fallback_id`
- `task_id`
- `attempt_number`
- `fallback_type` = `retry_same_path | equivalent_substitution | path_switch_request | none`
- `from_execution_path_id`
- `to_execution_path_id`
- `changed_fields[]`
- `approval_required`
- `disclosed_in_next_summary`
- `outcome` = `succeeded | failed | awaiting_approval | blocked`

Example bridge shape:

```yaml
thread_orchestration:
  active_thread_id: "<thread-id or null>"
  threads:
    - thread_id: "<thread-id>"
      primary_assistant: "<assistant-id>"
      reporting_owner: pal
      state: "active | waiting_for_approval | blocked | completed"
      approved_execution_path_id: "<path-id or null>"
      approval_state: "not_needed | approved | approval_required | denied"
      shared_context_refs: []
      created_at: "<ISO-8601>"
      updated_at: "<ISO-8601>"
  execution_paths:
    - execution_path_id: "<path-id>"
      assistant: "<assistant-id>"
      connector: "<connector-id>"
      provider: "<provider-id>"
      runtime_path: "<runtime-path>"
      model: "<model-id>"
      quality_tier: "premium | standard | fast"
      auth_scope: "<coarse boundary label>"
      selection_reason: "<reason>"
      approved_by_user: false
      approved_at: "<ISO-8601 or null>"
  connector_status_snapshots:
    - connector_identity: "<connector-id>"
      auth_state: "available | missing | expired | denied | unknown"
      availability_state: "available | degraded | unavailable | unknown"
      last_failure_reason: "none | quota_exhausted | connector_exhausted | auth_failure | runtime_error | unknown"
      quota_state: "available | exhausted | unknown"
      checked_at: "<ISO-8601>"
  delegation_tasks:
    - task_id: "<task-id>"
      thread_id: "<thread-id>"
      task_type: "drafting | critique | bounded_implementation"
      acceptance_criteria_summary: "<summary>"
      execution_path_id: "<path-id>"
      delegated: false
      result_state: "pending | succeeded | failed | blocked"
      user_visible_emitter: "primary_assistant"
      started_at: "<ISO-8601>"
      finished_at: "<ISO-8601 or null>"
  fallback_records:
    - fallback_id: "<fallback-id>"
      task_id: "<task-id>"
      attempt_number: 1
      fallback_type: "retry_same_path | equivalent_substitution | path_switch_request | none"
      from_execution_path_id: "<path-id or null>"
      to_execution_path_id: "<path-id or null>"
      changed_fields: []
      approval_required: false
      disclosed_in_next_summary: false
      outcome: "succeeded | failed | awaiting_approval | blocked"
```

## Partial context schema

If Phase 0 is incomplete when a session ends, save to `.projectpal/state.yml`:

```yaml
partial_context:
  complete: false
  readiness:
    who_has_the_problem:
      answered: true | false
      source: "<verbatim excerpt or null>"
    whats_the_pain:
      answered: true | false
      source: "<verbatim excerpt or null>"
    proposed_direction:
      answered: true | false
      source: "<verbatim excerpt or null>"
    what_does_success_look_like:
      answered: true | false
      source: "<verbatim excerpt or null>"
```

## Resume logic when `partial_context.complete: false`

1. Read the answered fields
2. Generate re-entry from source excerpt of the first answered field:
  *"Last time you mentioned [source]. Tell me more about that, or is there something new?"*
3. Queue unanswered fields in priority order (who → pain → direction → success)
4. Ask the highest-priority unanswered field next — one question only
5. Never re-ask answered fields. Never push to Phase 1 until all four are answered.

When all four are answered: set `complete: true`. Clear `partial_context` after Phase 1 completes.

## Bridge save cadence

To preserve resume continuity during long sessions or interrupted runs, ProjectPal should save `.projectpal/state.yml` more often than phase boundaries alone.

- Save the local bridge after every approved artifact write.
- Save the local bridge after every meaningful phase transition.
- Save the local bridge after any substantial user-approved revision to a Brief, Technical Details artifact, or ticket set.
- During long phases, save the local bridge after each meaningful batch of work, using the freshest `last_artifact_ref`, `next_steps`, and `bridge_summary`.
- Before any likely interruption point, such as a long sub-agent run, large edit batch, or implementation batch that may exceed the session budget, save the local bridge first.
- If work stops unexpectedly, the bridge should be specific enough that the next session can resume from the last completed batch rather than replaying the whole phase.

