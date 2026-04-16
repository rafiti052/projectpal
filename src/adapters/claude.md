

# Claude Adapter

## Purpose

Document the minimal Claude-specific wrapper content that must remain outside the shared neutral source.

## Current boundary

- `CLAUDE.md` currently contains the shared core body directly.
- There is no meaningful Claude-only behavioral wrapper beyond file identity and source-of-truth comments.

## Planned adapter responsibility

Keep the Claude adapter as thin as possible:

- file-level identity comments if needed
- any Claude-only launch note if one becomes necessary

## Lean v1 reference adapter contract

The Claude Code path is the only delegated reference adapter in scope for lean v1.

### `get_reference_connector_status`

Return one normalized `ConnectorStatusSnapshot` shape:

- `connector_identity`
- `auth_state` = `available | missing | expired | denied | unknown`
- `availability_state` = `available | degraded | unavailable | unknown`
- `last_failure_reason` = `none | quota_exhausted | connector_exhausted | auth_failure | runtime_error | unknown`
- `quota_state` = `available | exhausted | unknown`
- `checked_at`

Rules:

- Normalize any missing or ambiguous telemetry to `unknown`.
- Never return raw credential material, account identity, billing data, or raw quota values.

### `delegate_via_reference_path`

Return one internal result shape:

- `result_state` = `succeeded | failed | blocked`
- `structured_result`
- `normalized_failure`

When `normalized_failure` is present, it may carry only:

- `failure_reason` = `quota_exhausted | connector_exhausted | auth_failure | runtime_error | unknown`

Rules:

- The adapter returns internal result data only.
- Non-primary assistants must not emit user-facing progress, decisions, or completion text.
- Same-path fallback disclosure belongs to the next natural summary in Codex, not the delegated adapter output.
- If the connector cannot prove a more specific failure reason, return `unknown`.

The current generated-file prefix is shared through:

- `src/adapters/runtime-output-prefix.md`

Everything else should come from `src/shared/core.md`.

## Minimum wrapper conclusion

For lean v1, the Claude wrapper stays minimal but no longer empty: it owns the reference adapter's internal result and status contract, while shared product behavior still lives in `src/shared/core.md`.