#!/bin/sh

set -eu

ROOT_DIR=${ROOT_DIR:-$(pwd)}
REVIEW_DIR="$ROOT_DIR/.projectpal/artifacts/review"
PRD_PATH="$ROOT_DIR/.projectpal/artifacts/prd/performance-architecture-and-token-efficiency.md"
BASELINE_CRITIC_PATH="$REVIEW_DIR/run-3/critic-output.md"
BASELINE_JUDGE_PATH="$REVIEW_DIR/run-3/judge-output.md"
POST_CHANGE_CRITIC_INPUT_PATH="$REVIEW_DIR/critic-input-package.md"
POST_CHANGE_JUDGE_INPUT_PATH="$REVIEW_DIR/judge-input-package.md"
HANDOFF_PATH="$REVIEW_DIR/phase1-to-2-handoff.yml"
MEMORY_SUMMARY_PATH="$REVIEW_DIR/memory-summary.yml"

BASELINE_BUNDLE_PATH="$REVIEW_DIR/phase2-baseline-median-bundle.md"
POST_CHANGE_CORE_BUNDLE_PATH="$REVIEW_DIR/phase2-post-change-core-bundle.md"
POST_CHANGE_TRANSPORT_BUNDLE_PATH="$REVIEW_DIR/phase2-post-change-transport-bundle.md"
SUMMARY_PATH="$REVIEW_DIR/phase2-corrected-comparison-summary.yml"

word_count() {
  sh "$ROOT_DIR/scripts/markdown-word-budget.sh" "$1" |
    awk -F': ' '/^word_count:/ { print $2; exit }'
}

percent_reduction() {
  baseline=$1
  current=$2
  awk -v baseline="$baseline" -v current="$current" 'BEGIN {
    if (baseline == 0) {
      print "0.00"
    } else {
      printf "%.2f", ((baseline - current) / baseline) * 100
    }
  }'
}

baseline_prd_words=$(word_count "$PRD_PATH")
baseline_critic_words=$(word_count "$BASELINE_CRITIC_PATH")
baseline_judge_words=$(word_count "$BASELINE_JUDGE_PATH")
post_change_critic_input_words=$(word_count "$POST_CHANGE_CRITIC_INPUT_PATH")
post_change_judge_input_words=$(word_count "$POST_CHANGE_JUDGE_INPUT_PATH")
handoff_words=$(word_count "$HANDOFF_PATH")
memory_summary_words=$(word_count "$MEMORY_SUMMARY_PATH")

baseline_bundle_words=$((baseline_prd_words + baseline_critic_words + baseline_judge_words))
post_change_core_bundle_words=$((baseline_prd_words + post_change_critic_input_words + post_change_judge_input_words))
post_change_transport_bundle_words=$((post_change_core_bundle_words + handoff_words + memory_summary_words))

core_reduction_percent=$(percent_reduction "$baseline_bundle_words" "$post_change_core_bundle_words")
transport_reduction_percent=$(percent_reduction "$baseline_bundle_words" "$post_change_transport_bundle_words")

cat > "$BASELINE_BUNDLE_PATH" <<EOF
# Phase 2 Baseline Median Bundle

This bundle captures the median baseline debate surface using the debated PRD, the median-run Critic output, and the median-run Judge output from \`run-3\`.

## Counts

- PRD words: $baseline_prd_words
- Critic output words: $baseline_critic_words
- Judge output words: $baseline_judge_words
- Total words: $baseline_bundle_words

## Debated PRD

EOF
cat "$PRD_PATH" >> "$BASELINE_BUNDLE_PATH"
cat >> "$BASELINE_BUNDLE_PATH" <<EOF

## Median Baseline Critic Output

EOF
cat "$BASELINE_CRITIC_PATH" >> "$BASELINE_BUNDLE_PATH"
cat >> "$BASELINE_BUNDLE_PATH" <<EOF

## Median Baseline Judge Output

EOF
cat "$BASELINE_JUDGE_PATH" >> "$BASELINE_BUNDLE_PATH"

cat > "$POST_CHANGE_CORE_BUNDLE_PATH" <<EOF
# Phase 2 Post-Change Core Bundle

This bundle captures the narrowed Phase 2 core surface using the full debated PRD plus the saved critic and judge input packages from the new handoff flow.

## Counts

- PRD words: $baseline_prd_words
- Critic input package words: $post_change_critic_input_words
- Judge input package words: $post_change_judge_input_words
- Total words: $post_change_core_bundle_words
- Reduction vs baseline bundle: $core_reduction_percent%

## Debated PRD

EOF
cat "$PRD_PATH" >> "$POST_CHANGE_CORE_BUNDLE_PATH"
cat >> "$POST_CHANGE_CORE_BUNDLE_PATH" <<EOF

## Post-Change Critic Input Package

EOF
cat "$POST_CHANGE_CRITIC_INPUT_PATH" >> "$POST_CHANGE_CORE_BUNDLE_PATH"
cat >> "$POST_CHANGE_CORE_BUNDLE_PATH" <<EOF

## Post-Change Judge Input Package

EOF
cat "$POST_CHANGE_JUDGE_INPUT_PATH" >> "$POST_CHANGE_CORE_BUNDLE_PATH"

cat > "$POST_CHANGE_TRANSPORT_BUNDLE_PATH" <<EOF
# Phase 2 Post-Change Transport Bundle

This bundle extends the post-change core surface with the saved handoff artifact and memory summary so the full transported context can be inspected in one place.

## Counts

- Core bundle words: $post_change_core_bundle_words
- Handoff package words: $handoff_words
- Memory summary words: $memory_summary_words
- Total words: $post_change_transport_bundle_words
- Reduction vs baseline bundle: $transport_reduction_percent%

## Debated PRD

EOF
cat "$PRD_PATH" >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH"
cat >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH" <<EOF

## Phase 1 To 2 Handoff

EOF
cat "$HANDOFF_PATH" >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH"
cat >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH" <<EOF

## Memory Summary

EOF
cat "$MEMORY_SUMMARY_PATH" >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH"
cat >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH" <<EOF

## Post-Change Critic Input Package

EOF
cat "$POST_CHANGE_CRITIC_INPUT_PATH" >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH"
cat >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH" <<EOF

## Post-Change Judge Input Package

EOF
cat "$POST_CHANGE_JUDGE_INPUT_PATH" >> "$POST_CHANGE_TRANSPORT_BUNDLE_PATH"

cat > "$SUMMARY_PATH" <<EOF
flow: phase2-corrected-comparison
project: performance-architecture-and-token-efficiency
status: complete
baseline_surface:
  kind: median-baseline-bundle
  artifact_ref: .projectpal/artifacts/review/phase2-baseline-median-bundle.md
  prd_words: $baseline_prd_words
  critic_words: $baseline_critic_words
  judge_words: $baseline_judge_words
  total_words: $baseline_bundle_words
post_change_surfaces:
  core_bundle:
    artifact_ref: .projectpal/artifacts/review/phase2-post-change-core-bundle.md
    prd_words: $baseline_prd_words
    critic_input_package_words: $post_change_critic_input_words
    judge_input_package_words: $post_change_judge_input_words
    total_words: $post_change_core_bundle_words
    reduction_percent_vs_baseline: $core_reduction_percent
  transport_bundle:
    artifact_ref: .projectpal/artifacts/review/phase2-post-change-transport-bundle.md
    core_bundle_words: $post_change_core_bundle_words
    handoff_words: $handoff_words
    memory_summary_words: $memory_summary_words
    total_words: $post_change_transport_bundle_words
    reduction_percent_vs_baseline: $transport_reduction_percent
notes:
  - "This corrected comparison does not claim output quality equivalence; it saves the baseline and post-change artifacts side by side for manual inspection."
  - "The baseline bundle uses the median baseline run (run-3) because its total sits between run-1 and run-2."
  - "The post-change core bundle keeps the full debated PRD and the narrowed saved debate input packages."
  - "The post-change transport bundle includes the extra handoff and memory artifacts that travel with the narrowed flow."
EOF

printf '%s\n' "Generated comparison artifacts:"
printf '%s\n' "  $BASELINE_BUNDLE_PATH"
printf '%s\n' "  $POST_CHANGE_CORE_BUNDLE_PATH"
printf '%s\n' "  $POST_CHANGE_TRANSPORT_BUNDLE_PATH"
printf '%s\n' "  $SUMMARY_PATH"
