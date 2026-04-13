#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
DEFAULT_BUDGET_LIMIT=1000
DEFAULT_SUMMARY_LIMIT=150

usage() {
  cat <<'EOF' >&2
usage:
  sh scripts/projectpal-flow.sh artifact-budget-check <markdown-path> [budget-limit] [exception-note-file] [compact-summary-file]
  sh scripts/projectpal-flow.sh split-evaluate <word-count> <budget-limit> <unresolved-scope:true|false> <exception-needed:true|false> <parent-project> [entry-phase]
  sh scripts/projectpal-flow.sh handoff-build <source-phase> <target-phase> <artifact-ref> <bridge-summary-file> [memory-summary-file] [dropped-context:true|false] [reentry-required:true|false]
  sh scripts/projectpal-flow.sh context-reset-evaluate <handoff-package-path>
  sh scripts/projectpal-flow.sh memory-summary <results-file> <repo-slug> [feat-slug] [phase] [kind] [limit]
  sh scripts/projectpal-flow.sh build-phase-input <critic|judge|tech-spec|tickets> <approved-artifact-ref> <handoff-package-path> [memory-summary-file] [extra-artifact-ref]
  sh scripts/projectpal-flow.sh sync-resume-bridge <state-path> <approved-artifact-ref> <bridge-summary-file> [resume-source]
  sh scripts/projectpal-flow.sh reduction-report <baseline-summary-path> <new-flow-summary-path> [output-path]
  sh scripts/projectpal-flow.sh phase7-batch-close-check <ticket-bundle-path>
  sh scripts/projectpal-flow.sh generate-implementation-aid <output-path> <source-file>...
EOF
  exit 1
}

bool_or_false() {
  case ${1:-false} in
    true|false) printf '%s\n' "$1" ;;
    *) printf '%s\n' "false" ;;
  esac
}

require_file() {
  if [ ! -f "$1" ]; then
    printf '%s\n' "projectpal-flow: file not found: $1" >&2
    exit 1
  fi
}

trim_file_to_line() {
  awk 'NF { sub(/^[[:space:]]+/, "", $0); print; exit }' "$1"
}

read_multiline_yaml_block() {
  awk '
    BEGIN { in_block = 0 }
    /^bridge_summary:[[:space:]]*\|/ { in_block = 1; next }
    in_block {
      if ($0 ~ /^  /) {
        sub(/^  /, "", $0)
        print
      } else {
        exit
      }
    }
  ' "$1"
}

command_artifact_budget_check() {
  if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
    usage
  fi

  markdown_path=$1
  budget_limit=${2:-$DEFAULT_BUDGET_LIMIT}
  exception_note_file=${3:-}
  compact_summary_file=${4:-}

  require_file "$markdown_path"

  word_count=$(
    sh "$SCRIPT_DIR/markdown-word-budget.sh" "$markdown_path" "$budget_limit" |
      awk -F': ' '/^word_count:/ { print $2 }'
  )

  within_budget=false
  exception_required=false
  if [ "$word_count" -le "$budget_limit" ]; then
    within_budget=true
  else
    exception_required=true
    if [ -z "$exception_note_file" ]; then
      printf '%s\n' "projectpal-flow: exception note required for oversized artifact: $markdown_path" >&2
      exit 2
    fi
    require_file "$exception_note_file"
  fi

  printf '%s\n' "artifact_ref: $markdown_path"
  printf '%s\n' "word_count: $word_count"
  printf '%s\n' "budget_limit: $budget_limit"
  printf '%s\n' "within_budget: $within_budget"
  printf '%s\n' "exception_required: $exception_required"
  if [ -n "$exception_note_file" ]; then
    printf '%s\n' "exception_note: |"
    sed 's/^/  /' "$exception_note_file"
  fi
  if [ -n "$compact_summary_file" ]; then
    require_file "$compact_summary_file"
    printf '%s\n' "compact_summary: |"
    sed 's/^/  /' "$compact_summary_file"
  fi
}

command_split_evaluate() {
  if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
    usage
  fi

  word_count=$1
  budget_limit=$2
  unresolved_scope=$(bool_or_false "$3")
  exception_needed=$(bool_or_false "$4")
  parent_project=$5
  entry_phase=${6:-1}

  split_required=false
  if [ "$word_count" -gt "$budget_limit" ] || [ "$unresolved_scope" = "true" ] || [ "$exception_needed" = "true" ]; then
    split_required=true
  fi

  printf '%s\n' "parent_project: $parent_project"
  printf '%s\n' "entry_phase: $entry_phase"
  printf '%s\n' "word_count: $word_count"
  printf '%s\n' "budget_limit: $budget_limit"
  printf '%s\n' "unresolved_scope: $unresolved_scope"
  printf '%s\n' "exception_needed: $exception_needed"
  printf '%s\n' "split_required: $split_required"
  printf '%s\n' "slices:"
  if [ "$split_required" = "true" ]; then
    printf '%s\n' "  - slice_slug: ${parent_project}-slice-1"
    printf '%s\n' "    split_reason: budget-or-scope-gate"
    printf '%s\n' "    success_target: preserve requirements without oversized artifacts"
  else
    printf '%s\n' "  []"
  fi
}

command_handoff_build() {
  if [ "$#" -lt 4 ] || [ "$#" -gt 7 ]; then
    usage
  fi

  source_phase=$1
  target_phase=$2
  artifact_ref=$3
  bridge_summary_file=$4
  memory_summary_file=${5:-}
  dropped_context=$(bool_or_false "${6:-true}")
  reentry_required=$(bool_or_false "${7:-false}")

  require_file "$bridge_summary_file"
  bridge_summary=$(trim_file_to_line "$bridge_summary_file")

  printf '%s\n' "source_phase: $source_phase"
  printf '%s\n' "target_phase: $target_phase"
  printf '%s\n' "artifact_ref: $artifact_ref"
  printf '%s\n' "bridge_summary: |"
  sed 's/^/  /' "$bridge_summary_file"
  printf '%s\n' "dropped_context: $dropped_context"
  printf '%s\n' "reentry_required: $reentry_required"
  printf '%s\n' "resume_input: $bridge_summary"
  if [ -n "$memory_summary_file" ]; then
    require_file "$memory_summary_file"
    printf '%s\n' "memory_summary: |"
    sed 's/^/  /' "$memory_summary_file"
  fi
}

command_context_reset_evaluate() {
  if [ "$#" -ne 1 ]; then
    usage
  fi

  package_path=$1
  require_file "$package_path"

  artifact_ref=$(awk -F': ' '/^artifact_ref:/ { print $2; exit }' "$package_path")
  dropped_context=$(awk -F': ' '/^dropped_context:/ { print $2; exit }' "$package_path")
  reentry_required=$(awk -F': ' '/^reentry_required:/ { print $2; exit }' "$package_path")
  has_bridge=false
  if grep -q '^bridge_summary: |' "$package_path"; then
    has_bridge=true
  fi

  safe_to_drop=false
  resume_mode=reentry
  if [ -n "$artifact_ref" ] && [ "$has_bridge" = "true" ]; then
    if [ "$dropped_context" = "true" ]; then
      safe_to_drop=true
    fi
    if [ "$reentry_required" = "true" ]; then
      resume_mode=reentry
    else
      resume_mode=bridge
    fi
  fi

  printf '%s\n' "artifact_ref: $artifact_ref"
  printf '%s\n' "has_bridge_summary: $has_bridge"
  printf '%s\n' "dropped_context: ${dropped_context:-false}"
  printf '%s\n' "reentry_required: ${reentry_required:-false}"
  printf '%s\n' "safe_to_drop_live_context: $safe_to_drop"
  printf '%s\n' "resume_mode: $resume_mode"
}

command_memory_summary() {
  if [ "$#" -lt 2 ] || [ "$#" -gt 6 ]; then
    usage
  fi

  results_file=$1
  repo_slug=$2
  feat_slug=${3:-}
  phase=${4:-}
  kind=${5:-}
  limit=${6:-3}

  require_file "$results_file"

  selected=$(
    awk -v repo="repo:""$repo_slug" -v feat="feat:""$feat_slug" -v phase_tag="phase:""$phase" -v kind_tag="kind:""$kind" -v limit="$limit" '
      index($0, repo) {
        score = 0
        if (feat != "feat:" && index($0, feat)) score += 4
        if (phase_tag != "phase:" && index($0, phase_tag)) score += 2
        if (kind_tag != "kind:" && index($0, kind_tag)) score += 1
        lines[++count] = $0
        scores[count] = score
      }
      END {
        emitted = 0
        for (target = 7; target >= 0; target--) {
          for (i = 1; i <= count; i++) {
            if (scores[i] == target) {
              print lines[i]
              emitted++
              if (emitted >= limit) exit
            }
          }
        }
      }
    ' "$results_file"
  )

  if [ -z "$selected" ]; then
    printf '%s\n' "refs: []"
    printf '%s\n' "summary: "
    exit 0
  fi

  summary=$(
    printf '%s\n' "$selected" |
      awk -v max_words="$DEFAULT_SUMMARY_LIMIT" '
        {
          for (i = 1; i <= NF; i++) {
            if (count < max_words) {
              words[++count] = $i
            }
          }
        }
        END {
          for (i = 1; i <= count; i++) {
            printf "%s", words[i]
            if (i < count) printf " "
          }
          printf "\n"
        }
      '
  )

  printf '%s\n' "refs:"
  printf '%s\n' "$selected" | sed 's/^/  - /'
  printf '%s\n' "summary: |"
  printf '%s\n' "$summary" | sed 's/^/  /'
}

command_build_phase_input() {
  if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
    usage
  fi

  phase_kind=$1
  approved_artifact_ref=$2
  handoff_package_path=$3
  memory_summary_file=${4:-}
  extra_artifact_ref=${5:-}

  require_file "$handoff_package_path"
  bridge_summary=$(read_multiline_yaml_block "$handoff_package_path")

  printf '# %s Input Package\n\n' "$phase_kind"
  printf '## Canonical Inputs\n\n'
  printf '%s\n' "- Approved artifact ref: \`$approved_artifact_ref\`"
  printf '%s\n' "- Handoff package: \`$handoff_package_path\`"
  if [ -n "$extra_artifact_ref" ]; then
    printf '%s\n' "- Extra artifact ref: \`$extra_artifact_ref\`"
  fi
  printf '\n## Bridge Summary\n\n'
  if [ -n "$bridge_summary" ]; then
    printf '%s\n' "$bridge_summary"
  else
    printf '%s\n' "No bridge summary found."
  fi
  if [ -n "$memory_summary_file" ]; then
    require_file "$memory_summary_file"
    printf '\n## Memory Summary\n\n'
    cat "$memory_summary_file"
    printf '\n'
  fi
}

command_sync_resume_bridge() {
  if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    usage
  fi

  state_path=$1
  approved_artifact_ref=$2
  bridge_summary_file=$3
  resume_source=${4:-repo-memory}

  require_file "$state_path"
  require_file "$bridge_summary_file"

  tmp_path=$(mktemp)
  awk '
    BEGIN {
      skip = 0
    }
    /^last_artifact_ref:/ { next }
    /^bridge_summary:[[:space:]]*\|/ {
      skip = 1
      next
    }
    skip {
      if ($0 ~ /^  /) next
      skip = 0
    }
    /^resume_source:/ {
      print "resume_source: '"$resume_source"'"
      next
    }
    { print }
  ' "$state_path" > "$tmp_path"

  {
    cat "$tmp_path"
    printf '%s\n' "last_artifact_ref: $approved_artifact_ref"
    printf '%s\n' "bridge_summary: |"
    sed 's/^/  /' "$bridge_summary_file"
  } > "$state_path"

  rm -f "$tmp_path"
}

command_reduction_report() {
  if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage
  fi

  baseline_summary_path=$1
  new_flow_summary_path=$2
  output_path=${3:-}

  require_file "$baseline_summary_path"
  require_file "$new_flow_summary_path"

  baseline=$(awk -F': ' '/^baseline_median_total_words:/ { print $2; exit }' "$baseline_summary_path")
  new_value=$(awk -F': ' '/^baseline_median_total_words:/ { print $2; exit }' "$new_flow_summary_path")

  if [ -z "$baseline" ] || [ -z "$new_value" ]; then
    printf '%s\n' "projectpal-flow: reduction report needs baseline_median_total_words in both summary files" >&2
    exit 1
  fi

  reduction_percent=$(
    awk -v baseline="$baseline" -v current="$new_value" 'BEGIN {
      printf "%.2f", ((baseline - current) / baseline) * 100
    }'
  )

  target_met=false
  awk -v reduction="$reduction_percent" 'BEGIN { exit !(reduction >= 30) }' >/dev/null 2>&1 && target_met=true || true

  report=$(
    cat <<EOF
baseline_median_total_words: $baseline
new_flow_median_total_words: $new_value
reduction_percent: $reduction_percent
target_percent: 30
target_met: $target_met
EOF
  )

  if [ -n "$output_path" ]; then
    printf '%s\n' "$report" > "$output_path"
  fi

  printf '%s\n' "$report"
}

command_phase7_batch_close_check() {
  if [ "$#" -ne 1 ]; then
    usage
  fi

  bundle_path=$1
  require_file "$bundle_path"

  has_final_report=false
  has_wave_summaries=false
  has_active_owners=false
  has_ownership_collisions=false
  has_blocked_items=false
  has_verification_results=false
  has_final_batch_status=false

  grep -q '^## Final Integration Report' "$bundle_path" && has_final_report=true || true
  grep -iq 'wave summaries\|wave summary' "$bundle_path" && has_wave_summaries=true || true
  grep -iq 'active owners' "$bundle_path" && has_active_owners=true || true
  grep -iq 'ownership collisions\|collisions' "$bundle_path" && has_ownership_collisions=true || true
  grep -iq 'blocked items\|blocked work' "$bundle_path" && has_blocked_items=true || true
  grep -iq 'verification results' "$bundle_path" && has_verification_results=true || true
  grep -iq 'final batch status\|final status' "$bundle_path" && has_final_batch_status=true || true

  close_ready=false
  if [ "$has_final_report" = "true" ] &&
     [ "$has_wave_summaries" = "true" ] &&
     [ "$has_active_owners" = "true" ] &&
     [ "$has_ownership_collisions" = "true" ] &&
     [ "$has_blocked_items" = "true" ] &&
     [ "$has_verification_results" = "true" ] &&
     [ "$has_final_batch_status" = "true" ]; then
    close_ready=true
  fi

  printf '%s\n' "artifact_ref: $bundle_path"
  printf '%s\n' "has_final_integration_report: $has_final_report"
  printf '%s\n' "has_wave_summaries: $has_wave_summaries"
  printf '%s\n' "has_active_owners: $has_active_owners"
  printf '%s\n' "has_ownership_collisions: $has_ownership_collisions"
  printf '%s\n' "has_blocked_items: $has_blocked_items"
  printf '%s\n' "has_verification_results: $has_verification_results"
  printf '%s\n' "has_final_batch_status: $has_final_batch_status"
  printf '%s\n' "close_ready: $close_ready"
}

command_generate_implementation_aid() {
  if [ "$#" -lt 2 ]; then
    usage
  fi

  output_path=$1
  shift

  {
    printf '%s\n' "# Implementation Aid"
    printf '\n'
    printf '%s\n' "This builder-only aid is generated from explicit local sources only."
    printf '\n'
    printf '%s\n' "## Sources"
    printf '\n'
    for source_file in "$@"; do
      require_file "$source_file"
      printf '%s\n' "- \`$source_file\`"
    done
    printf '\n'
    printf '%s\n' "## Repo Rules"
    printf '\n'
    printf '%s\n' "- Prefer approved artifacts, bridge summaries, and repo-local references over broad replay context."
    printf '%s\n' "- Use the markdown budget helper before saving canonical artifacts."
    printf '%s\n' "- Treat the baseline median total of 2091 words as the comparison target for post-change Phase 2 measurements."
    printf '\n'
    printf '%s\n' "## Phase 7 Guidance"
    printf '\n'
    printf '%s\n' "- Build from handoff packages, not from full-thread replay."
    printf '%s\n' "- Schedule work by wave order; do not open a later wave until the current wave exit criteria are met or remaining work is explicitly deferred."
    printf '%s\n' "- Within a wave, run only tickets whose true dependencies are satisfied and whose exclusive write surfaces do not overlap."
    printf '%s\n' "- Keep memory retrieval repo-scoped and summary-first."
    printf '%s\n' "- Preserve resume continuity by syncing approved artifact refs and bridge summaries into \`.projectpal/state.yml\`."
    printf '%s\n' "- Record ticket state with the vocabulary \`queued\`, \`blocked\`, \`running\`, \`complete\`, or \`deferred\`."
    printf '%s\n' "- Treat \`builder\` as the default owner; add \`reviewer\` or \`verifier\` only as optional role slots when risk justifies them."
    printf '%s\n' "- Do not close a batch without a Final Integration Report covering wave summaries, active owners, collisions, blocked items, verification results, and final batch status."
    printf '%s\n' "- When artifacts exceed the default budget, require an explicit exception note or split the work."
    printf '\n'
    for source_file in "$@"; do
      printf '## Excerpt: %s\n\n' "$source_file"
      sed -n '1,20p' "$source_file"
      printf '\n'
    done
  } > "$output_path"
}

if [ "$#" -lt 1 ]; then
  usage
fi

command=$1
shift

case "$command" in
  artifact-budget-check) command_artifact_budget_check "$@" ;;
  split-evaluate) command_split_evaluate "$@" ;;
  handoff-build) command_handoff_build "$@" ;;
  context-reset-evaluate) command_context_reset_evaluate "$@" ;;
  memory-summary) command_memory_summary "$@" ;;
  build-phase-input) command_build_phase_input "$@" ;;
  sync-resume-bridge) command_sync_resume_bridge "$@" ;;
  reduction-report) command_reduction_report "$@" ;;
  phase7-batch-close-check) command_phase7_batch_close_check "$@" ;;
  generate-implementation-aid) command_generate_implementation_aid "$@" ;;
  *) usage ;;
esac
