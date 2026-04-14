---
project: agent-orchestration-proof-flow
phase: 7
type: regression-fixture
status: ready
created: 2026-04-14T15:15:44-03:00
---

## Summary
This fixture models the lean-v1 proof flow from Codex-owned entry through Claude delegation, one automatic same-path fallback, and one approval-required path switch.
It also records that explicit parallel delegated work stays blocked and all visible messaging remains Pal-owned.

## Primary path
primary_assistant: codex
delegated_assistant: Claude
execution_path_connector: claude-code
execution_path_provider: anthropic-via-claude-code
execution_path_runtime_path: codex_to_claude_code_delegate
execution_path_quality_tier: premium

## Same-path fallback
same_path_fallback_type: retry_same_path
same_path_fallback_disclosed_in_next_summary: true
same_path_fallback_visible_owner: pal

## Approval-required path switch
path_switch_fallback_type: path_switch_request
path_switch_approval_required: true
path_switch_changed_fields: quality_tier
path_switch_visible_owner: codex-pal

## Parallel delegation guard
parallel_delegated_work_blocked: true
parallel_delegation_visible_owner: pal
