#!/bin/sh

set -eu

PROJECT_ROOT=${PROJECT_ROOT:-$(pwd)}
REVIEW_DIR="$PROJECT_ROOT/.projectpal/artifacts/review"
MANIFEST_PATH="$REVIEW_DIR/phase2-baseline-manifest.yml"
RUN_ID=${1:-run-1}
RUN_DIR="$REVIEW_DIR/$RUN_ID"

PRD_PATH=".projectpal/artifacts/prd/performance-architecture-and-token-efficiency.md"
CRITIC_PROMPT_PATH="prompts/critic-agent.md"
JUDGE_PROMPT_PATH="prompts/judge-agent.md"

mkdir -p "$RUN_DIR"

cat > "$MANIFEST_PATH" <<EOF
project: performance-architecture-and-token-efficiency
flow: phase2-baseline
repo_root: $PROJECT_ROOT
measured_inputs:
  prd_artifact: $PRD_PATH
  critic_prompt: $CRITIC_PROMPT_PATH
  judge_prompt: $JUDGE_PROMPT_PATH
run_contract:
  repo_state: "Use the current repo state without changing prompts or artifacts between runs."
  source_prd: "Use the debated PRD artifact at $PRD_PATH as the Phase 2 source input for every baseline run."
  critic_output: ".projectpal/artifacts/review/<run-id>/critic-output.md"
  judge_output: ".projectpal/artifacts/review/<run-id>/judge-output.md"
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

- PRD artifact: \`$PRD_PATH\`
- Critic prompt: \`$CRITIC_PROMPT_PATH\`
- Judge prompt: \`$JUDGE_PROMPT_PATH\`

## Expected outputs

- \`critic-output.md\` — the Critic review produced from the fixed PRD input
- \`judge-output.md\` — the Judge output produced from the fixed PRD input plus the run's Critic output
- \`measurement.yml\` — counts and metadata for this run

## Run shape

1. Keep the repo state unchanged for all baseline passes.
2. Use the same PRD artifact for every run.
3. Save Critic and Judge outputs in this directory.
4. Record \`prd_words\`, \`critic_words\`, \`judge_words\`, and \`total_words\` in \`measurement.yml\`.
EOF

cat > "$RUN_DIR/measurement.yml" <<EOF
flow: phase2-baseline
run_id: $RUN_ID
input_ref: $PRD_PATH
critic_output_ref: .projectpal/artifacts/review/$RUN_ID/critic-output.md
judge_output_ref: .projectpal/artifacts/review/$RUN_ID/judge-output.md
prd_words:
critic_words:
judge_words:
total_words:
measured_at:
notes:
EOF

touch "$RUN_DIR/critic-output.md" "$RUN_DIR/judge-output.md"

printf '%s\n' "Prepared baseline fixture at $RUN_DIR"
printf '%s\n' "Manifest: $MANIFEST_PATH"
