---
project: thread-orchestration-isolation
phase: 7
type: regression-fixture
status: ready
created: 2026-04-14T15:15:44-03:00
---

## Summary
This fixture proves that thread-local orchestration ownership and approval state do not bleed across threads.
It also makes the allowed preservation rule explicit: resuming the same thread keeps its original owner, approval state, and approved execution path.

## Same-thread resume
resume_thread_id: codex-thread-1
resume_entry_assistant: claude
resume_preserves_primary_assistant: codex
resume_preserves_approval_state: approved
resume_preserves_approved_execution_path_id: path-codex-claude-premium

## New thread after delegated work
new_thread_id: claude-thread-2
new_thread_entry_assistant: claude
new_thread_primary_assistant: claude
new_thread_approval_state: not_needed
new_thread_approved_execution_path_id: null
new_thread_non_inheritance: true

## Assistant change on fresh thread
assistant_switch_thread_id: gemini-thread-3
assistant_switch_entry_assistant: gemini
assistant_switch_primary_assistant: gemini
assistant_switch_approval_state: not_needed
assistant_switch_approved_execution_path_id: null
assistant_switch_non_inheritance: true

## Non-inheritance fields
- primary_assistant
- approval_state
- approved_execution_path_id
