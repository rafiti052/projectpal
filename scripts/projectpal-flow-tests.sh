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
resume_source: repo-memory
next_steps:
  - "Old step"
last_artifact_ref: .projectpal/artifacts/old.md
bridge_summary: |
  Old bridge summary.
EOF

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
