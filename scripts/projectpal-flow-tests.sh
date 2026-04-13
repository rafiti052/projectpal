#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/projectpal-flow-tests.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

assert_contains() {
  haystack=$1
  needle=$2
  if ! printf '%s\n' "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
    printf '%s\n' "assertion failed: expected output to contain: $needle" >&2
    exit 1
  fi
}

run_flow() {
  sh "$ROOT_DIR/scripts/projectpal-flow.sh" "$@"
}

FIXTURE_PATH="$ROOT_DIR/scripts/parallel-batch-fixture.md"

cat > "$TMP_DIR/sample.md" <<'EOF'
---
project: sample
phase: 1
type: prd
status: draft
---

one two three four five six seven eight nine ten eleven twelve
EOF

cat > "$TMP_DIR/exception-note.md" <<'EOF'
Budget exception keeps one concrete requirement visible.
EOF

cat > "$TMP_DIR/compact-summary.md" <<'EOF'
Compact summary stays short.
EOF

cat > "$TMP_DIR/bridge-summary.md" <<'EOF'
Resume from the approved artifact and bridge summary only.
EOF

cat > "$TMP_DIR/handoff.yml" <<'EOF'
source_phase: 4
target_phase: 6
artifact_ref: .projectpal/artifacts/tech-spec/example-spec.md
bridge_summary: |
  Resume from bridge summary.
dropped_context: true
reentry_required: false
EOF

cat > "$TMP_DIR/memory-results.txt" <<'EOF'
repo:projectpal feat:target phase:7 kind:review summary:Best match for the active feature.
repo:projectpal feat:target phase:6 kind:feature-scope status:active summary:Earlier active scope.
repo:projectpal feat:other phase:7 kind:review summary:Different feature.
repo:other feat:target phase:7 kind:review summary:Different repo.
EOF

cat > "$TMP_DIR/state.yml" <<'EOF'
repo_slug: projectpal
repo_root_hint: /tmp/original-root
resume_source: repo-memory
next_steps:
  - "Old step"
last_artifact_ref: .projectpal/artifacts/old.md
bridge_summary: |
  Old bridge summary.
EOF

mkdir -p "$TMP_DIR/repo"
git -C "$TMP_DIR/repo" init >/dev/null 2>&1

cat > "$TMP_DIR/repo/state.yml" <<EOF
repo_slug: repo
repo_root_hint: $TMP_DIR/repo
resume_source: bridge
last_artifact_ref: .projectpal/artifacts/current.md
bridge_summary: |
  Current bridge summary.
EOF

mkdir -p "$TMP_DIR/other"
git -C "$TMP_DIR/other" init >/dev/null 2>&1

cat > "$TMP_DIR/other/state.yml" <<EOF
repo_slug: repo
repo_root_hint: $TMP_DIR/repo
resume_source: bridge
last_artifact_ref: .projectpal/artifacts/current.md
bridge_summary: |
  Stale bridge summary.
EOF

mkdir -p "$TMP_DIR/prepare"
git -C "$TMP_DIR/prepare" init >/dev/null 2>&1

mkdir -p "$TMP_DIR/onboarding"
git -C "$TMP_DIR/onboarding" init >/dev/null 2>&1

cat > "$TMP_DIR/baseline-summary.yml" <<'EOF'
baseline_median_total_words: 2091
EOF

cat > "$TMP_DIR/new-flow-summary.yml" <<'EOF'
baseline_median_total_words: 1200
EOF

cat > "$TMP_DIR/source-a.md" <<'EOF'
# Source A

Local source excerpt.
EOF

cat > "$TMP_DIR/source-b.md" <<'EOF'
# Source B

Another local source excerpt.
EOF

budget_output=$(run_flow artifact-budget-check "$TMP_DIR/sample.md" 10 "$TMP_DIR/exception-note.md" "$TMP_DIR/compact-summary.md")
assert_contains "$budget_output" "word_count: 12"
assert_contains "$budget_output" "within_budget: false"
assert_contains "$budget_output" "exception_required: true"
assert_contains "$budget_output" "Budget exception keeps one concrete requirement visible."

repo_context_output=$(run_flow resolve-repo-context "$TMP_DIR/repo")
assert_contains "$repo_context_output" "repo_slug: repo"
assert_contains "$repo_context_output" "is_git_repo: true"
assert_contains "$repo_context_output" "confidence: high"

bridge_read_output=$(run_flow read-resume-bridge "$TMP_DIR/repo/state.yml" "$TMP_DIR/repo")
assert_contains "$bridge_read_output" "bridge_valid: true"
assert_contains "$bridge_read_output" "mismatch_reason: none"
assert_contains "$bridge_read_output" "Current bridge summary."

bridge_mismatch_output=$(run_flow read-resume-bridge "$TMP_DIR/other/state.yml" "$TMP_DIR/other")
assert_contains "$bridge_mismatch_output" "bridge_valid: false"
assert_contains "$bridge_mismatch_output" "mismatch_reason: repo_root_hint_mismatch"

assistant_probe_output=$(run_flow probe-assistants "$ROOT_DIR")
assert_contains "$assistant_probe_output" "preferred: codex"
assert_contains "$assistant_probe_output" "confidence: inconclusive"
assert_contains "$assistant_probe_output" "fallback_used: true"
assert_contains "$assistant_probe_output" "claude:true"
assert_contains "$assistant_probe_output" "codex:true"

assistant_hint_output=$(PROJECTPAL_ASSISTANT_HINT=codex run_flow probe-assistants "$ROOT_DIR")
assert_contains "$assistant_hint_output" "preferred: codex"
assert_contains "$assistant_hint_output" "confidence: high"
assert_contains "$assistant_hint_output" "fallback_used: false"

mempalace_probe_output=$(run_flow probe-mempalace "$ROOT_DIR")
assert_contains "$mempalace_probe_output" "available: true"
assert_contains "$mempalace_probe_output" "reason: ok"
assert_contains "$mempalace_probe_output" "fallback_mode: shared-memory"

mempalace_fallback_output=$(PROJECTPAL_MEMPALACE_MODE=server-error run_flow probe-mempalace "$ROOT_DIR")
assert_contains "$mempalace_fallback_output" "available: false"
assert_contains "$mempalace_fallback_output" "reason: server-error"
assert_contains "$mempalace_fallback_output" "fallback_mode: local-only"

prepare_repo_output=$(run_flow prepare-repo "$TMP_DIR/prepare")
assert_contains "$prepare_repo_output" "ok: true"
assert_contains "$prepare_repo_output" "state_status: created"
assert_contains "$prepare_repo_output" "gitignore_status: created"
assert_contains "$(cat "$TMP_DIR/prepare/.projectpal/state.yml")" "current_project: onboarding"
assert_contains "$(cat "$TMP_DIR/prepare/.gitignore")" ".projectpal/"

prepare_repo_rerun_output=$(run_flow prepare-repo "$TMP_DIR/prepare")
assert_contains "$prepare_repo_rerun_output" "ok: true"
assert_contains "$prepare_repo_rerun_output" "state_status: existing"
assert_contains "$prepare_repo_rerun_output" "gitignore_status: already-present"

prepare_repo_block_state_output=$(PROJECTPAL_PREPARE_REPO_MODE=block-projectpal run_flow prepare-repo "$TMP_DIR/prepare")
assert_contains "$prepare_repo_block_state_output" "ok: false"
assert_contains "$prepare_repo_block_state_output" "blocker_name: projectpal-state-write-blocked"
assert_contains "$prepare_repo_block_state_output" "blocker_next_step: Create .projectpal/state.yml in this repo, then rerun projectpal."

prepare_repo_block_gitignore_output=$(PROJECTPAL_PREPARE_REPO_MODE=block-gitignore run_flow prepare-repo "$TMP_DIR/prepare")
assert_contains "$prepare_repo_block_gitignore_output" "ok: false"
assert_contains "$prepare_repo_block_gitignore_output" "gitignore_status: blocked"
assert_contains "$prepare_repo_block_gitignore_output" "blocker_name: gitignore-write-blocked"
assert_contains "$prepare_repo_block_gitignore_output" "blocker_next_step: Add .projectpal/ to .gitignore, then rerun projectpal."

onboarding_success_output=$(run_flow onboarding-flow "$TMP_DIR/onboarding")
assert_contains "$onboarding_success_output" "assistant_preferred: codex"
assert_contains "$onboarding_success_output" "mempalace_available: false"
assert_contains "$onboarding_success_output" "repo_ready: true"
assert_contains "$onboarding_success_output" "final_next_step: Open Codex in this repo and type ProjectPal."
assert_contains "$onboarding_success_output" "handoff_message: Open Codex in this repo and type ProjectPal."
onboarding_state=$(cat "$TMP_DIR/onboarding/.projectpal/state.yml")
assert_contains "$onboarding_state" "current_project: onboarding"
assert_contains "$onboarding_state" "current_phase: onboarding"
assert_contains "$onboarding_state" "preferred_assistant: codex"
assert_contains "$onboarding_state" "last_blocker: none"
assert_contains "$onboarding_state" "Open Codex in this repo and type ProjectPal."

onboarding_local_only_output=$(PROJECTPAL_MEMPALACE_MODE=missing run_flow onboarding-flow "$TMP_DIR/onboarding")
assert_contains "$onboarding_local_only_output" "mempalace_available: false"
assert_contains "$onboarding_local_only_output" "mempalace_mode: local-only"
assert_contains "$onboarding_local_only_output" "final_next_step: Open Codex in this repo and type ProjectPal."

onboarding_blocked_output=$(PROJECTPAL_PREPARE_REPO_MODE=block-gitignore run_flow onboarding-flow "$TMP_DIR/onboarding")
assert_contains "$onboarding_blocked_output" "repo_ready: false"
assert_contains "$onboarding_blocked_output" "blocker_name: gitignore-write-blocked"
assert_contains "$onboarding_blocked_output" "final_next_step: Add .projectpal/ to .gitignore, then rerun projectpal."
assert_contains "$(cat "$TMP_DIR/onboarding/.projectpal/state.yml")" "last_blocker: gitignore-write-blocked"

split_output=$(run_flow split-evaluate 1200 1000 false true example 1)
assert_contains "$split_output" "split_required: true"
assert_contains "$split_output" "slice_slug: example-slice-1"

handoff_output=$(run_flow handoff-build 4 6 .projectpal/artifacts/tech-spec/example-spec.md "$TMP_DIR/bridge-summary.md")
assert_contains "$handoff_output" "resume_input: Resume from the approved artifact and bridge summary only."

reset_output=$(run_flow context-reset-evaluate "$TMP_DIR/handoff.yml")
assert_contains "$reset_output" "safe_to_drop_live_context: true"
assert_contains "$reset_output" "resume_mode: bridge"

memory_output=$(run_flow memory-summary "$TMP_DIR/memory-results.txt" projectpal target 7 review 2)
assert_contains "$memory_output" "feat:target phase:7 kind:review"
assert_contains "$memory_output" "feat:target phase:6 kind:feature-scope"

phase_input_output=$(run_flow build-phase-input tickets .projectpal/artifacts/tech-spec/example-spec.md "$TMP_DIR/handoff.yml" "" .projectpal/artifacts/implementation-aid.md)
assert_contains "$phase_input_output" "- Approved artifact ref: \`.projectpal/artifacts/tech-spec/example-spec.md\`"
assert_contains "$phase_input_output" "- Extra artifact ref: \`.projectpal/artifacts/implementation-aid.md\`"

fixture_close_output=$(run_flow phase7-batch-close-check "$FIXTURE_PATH")
assert_contains "$fixture_close_output" "has_final_integration_report: true"
assert_contains "$fixture_close_output" "has_wave_summaries: true"
assert_contains "$fixture_close_output" "has_active_owners: true"
assert_contains "$fixture_close_output" "has_blocked_items: true"
assert_contains "$fixture_close_output" "close_ready: true"

run_flow sync-resume-bridge "$TMP_DIR/state.yml" .projectpal/artifacts/tech-spec/example-spec.md "$TMP_DIR/bridge-summary.md" repo-bridge > /dev/null
synced_state=$(cat "$TMP_DIR/state.yml")
assert_contains "$synced_state" "resume_source: repo-bridge"
assert_contains "$synced_state" "repo_root_hint: /tmp/original-root"
assert_contains "$synced_state" "last_artifact_ref: .projectpal/artifacts/tech-spec/example-spec.md"
assert_contains "$synced_state" "Resume from the approved artifact and bridge summary only."

reduction_output=$(run_flow reduction-report "$TMP_DIR/baseline-summary.yml" "$TMP_DIR/new-flow-summary.yml")
assert_contains "$reduction_output" "reduction_percent: 42.61"
assert_contains "$reduction_output" "target_met: true"

run_flow generate-implementation-aid "$TMP_DIR/implementation-aid.md" "$TMP_DIR/source-a.md" "$TMP_DIR/source-b.md" > /dev/null
implementation_aid=$(cat "$TMP_DIR/implementation-aid.md")
assert_contains "$implementation_aid" "## Sources"
assert_contains "$implementation_aid" "- \`$TMP_DIR/source-a.md\`"
assert_contains "$implementation_aid" "## Phase 7 Guidance"
assert_contains "$implementation_aid" "Do not close a batch without a Final Integration Report"

printf '%s\n' "projectpal-flow tests passed"
