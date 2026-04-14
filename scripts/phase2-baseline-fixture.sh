#!/bin/sh

set -eu

PROJECT_ROOT=${PROJECT_ROOT:-$(pwd)}
REVIEW_DIR="$PROJECT_ROOT/.projectpal/artifacts/review"
MANIFEST_PATH="$REVIEW_DIR/phase2-baseline-manifest.yml"
RUN_ID=${1:-run-1}
RUN_DIR="$REVIEW_DIR/$RUN_ID"

BRIEF_PATH=".projectpal/artifacts/brief/performance-architecture-and-token-efficiency.md"
ARCHITECT_PROMPT_PATH="prompts/architect-agent.md"
MANAGER_PROMPT_PATH="prompts/manager-agent.md"

mkdir -p "$RUN_DIR"

cat > "$MANIFEST_PATH" <<EOF
project: performance-architecture-and-token-efficiency
flow: phase2-baseline
repo_root: $PROJECT_ROOT
measured_inputs:
  brief_artifact: $BRIEF_PATH
  architect_prompt: $ARCHITECT_PROMPT_PATH
  manager_prompt: $MANAGER_PROMPT_PATH
run_contract:
  repo_state: "Use the current repo state without changing prompts or artifacts between runs."
  source_brief: "Use the refined Brief artifact at $BRIEF_PATH as the Phase 2 source input for every baseline run."
  architect_output: ".projectpal/artifacts/review/<run-id>/architect-output.md"
  manager_output: ".projectpal/artifacts/review/<run-id>/manager-output.md"
  measurement_record: ".projectpal/artifacts/review/<run-id>/measurement.yml"
entrypoint:
  command: "sh scripts/phase2-baseline-fixture.sh <run-id>"
  default_run: "sh scripts/phase2-baseline-fixture.sh run-1"
notes:
  - "This fixture prepares the exact input references and output paths for baseline runs."
  - "Run tickets 02-04 should write outputs into the prepared run directories."
EOF

cat > "$RUN_DIR/README.md" <<EOF
# Phase 2 Baseline Run: $RUN_ID

Use this run directory for one baseline measurement pass of the current Phase 2 flow.

## Fixed inputs

- Brief artifact: \`$BRIEF_PATH\`
- Architect prompt: \`$ARCHITECT_PROMPT_PATH\`
- Manager prompt: \`$MANAGER_PROMPT_PATH\`

## Expected outputs

- \`architect-output.md\` — the Architect review produced from the fixed Brief input
- \`manager-output.md\` — the Manager output produced from the fixed Brief input plus the Architect output
- \`measurement.yml\` — counts and metadata for this run

## Run shape

1. Keep the repo state unchanged for all baseline passes.
2. Use the same Brief artifact for every run.
3. Save Architect and Manager outputs in this directory.
4. Record \`brief_words\`, \`architect_words\`, \`manager_words\`, and \`total_words\` in \`measurement.yml\`.
EOF

cat > "$RUN_DIR/measurement.yml" <<EOF
flow: phase2-baseline
run_id: $RUN_ID
input_ref: $BRIEF_PATH
architect_output_ref: .projectpal/artifacts/review/$RUN_ID/architect-output.md
manager_output_ref: .projectpal/artifacts/review/$RUN_ID/manager-output.md
brief_words:
architect_words:
manager_words:
total_words:
measured_at:
notes:
EOF

touch "$RUN_DIR/architect-output.md" "$RUN_DIR/manager-output.md"

printf '%s\n' "Prepared baseline fixture at $RUN_DIR"
printf '%s\n' "Manifest: $MANIFEST_PATH"
