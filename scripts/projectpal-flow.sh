#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
DEFAULT_BUDGET_LIMIT=1000
DEFAULT_SUMMARY_LIMIT=150

usage() {
  cat <<'EOF' >&2
usage:
  sh scripts/projectpal-flow.sh resolve-repo-context [cwd]
  sh scripts/projectpal-flow.sh read-resume-bridge <state-path> [cwd]
  sh scripts/projectpal-flow.sh probe-assistants [cwd]
  sh scripts/projectpal-flow.sh probe-mempalace [cwd]
  sh scripts/projectpal-flow.sh prepare-repo [cwd]
  sh scripts/projectpal-flow.sh onboarding-flow [cwd]
  sh scripts/projectpal-flow.sh artifact-budget-check <markdown-path> [budget-limit] [exception-note-file] [compact-summary-file]
  sh scripts/projectpal-flow.sh split-evaluate <word-count> <budget-limit> <unresolved-scope:true|false> <exception-needed:true|false> <parent-project> [entry-phase]
  sh scripts/projectpal-flow.sh handoff-build <source-phase> <target-phase> <artifact-ref> <bridge-summary-file> [memory-summary-file] [dropped-context:true|false] [reentry-required:true|false]
  sh scripts/projectpal-flow.sh context-reset-evaluate <handoff-package-path>
  sh scripts/projectpal-flow.sh memory-summary <results-file> <repo-slug> [feat-slug] [phase] [kind] [limit]
  sh scripts/projectpal-flow.sh build-phase-input <architect|manager|technical-details|tickets> <approved-artifact-ref> <handoff-package-path> [memory-summary-file] [extra-artifact-ref]
  sh scripts/projectpal-flow.sh sync-resume-bridge <state-path> <approved-artifact-ref> <bridge-summary-file> [resume-source]
  sh scripts/projectpal-flow.sh reduction-report <baseline-summary-path> <new-flow-summary-path> [output-path]
  sh scripts/projectpal-flow.sh phase7-batch-close-check <ticket-bundle-path>
  sh scripts/projectpal-flow.sh thread-orchestration-isolation-check <fixture-path>
  sh scripts/projectpal-flow.sh agent-orchestration-proof-flow-check <fixture-path>
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

canonical_dir() {
  target_dir=$1
  if [ -d "$target_dir" ]; then
    (
      CDPATH= cd -- "$target_dir" && pwd -P
    )
  else
    printf '%s\n' "$target_dir"
  fi
}

normalize_path_if_dir() {
  target_path=$1
  if [ -n "$target_path" ] && [ -d "$target_path" ]; then
    canonical_dir "$target_path"
  else
    printf '%s\n' "$target_path"
  fi
}

utc_timestamp() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

today_utc() {
  date -u +%Y-%m-%d
}

write_bridge_state() {
  state_path=$1
  repo_slug=$2
  repo_root_hint=$3
  current_project=$4
  current_phase=$5
  resume_source=$6
  preferred_assistant=$7
  last_blocker=$8
  next_step=$9
  bridge_summary=${10}

  tmp_path=$(mktemp)
  awk '
    BEGIN {
      skip_next_steps = 0
      skip_bridge_summary = 0
    }
    /^repo_slug:/ { next }
    /^repo_root_hint:/ { next }
    /^current_project:/ { next }
    /^current_phase:/ { next }
    /^last_session:/ { next }
    /^resume_source:/ { next }
    /^synced_at:/ { next }
    /^preferred_assistant:/ { next }
    /^last_blocker:/ { next }
    /^next_steps:/ {
      skip_next_steps = 1
      next
    }
    /^bridge_summary:[[:space:]]*\|/ {
      skip_bridge_summary = 1
      next
    }
    skip_next_steps {
      if ($0 ~ /^  - /) next
      skip_next_steps = 0
    }
    skip_bridge_summary {
      if ($0 ~ /^  /) next
      skip_bridge_summary = 0
    }
    { print }
  ' "$state_path" > "$tmp_path"

  {
    cat "$tmp_path"
    printf '%s\n' "repo_slug: $repo_slug"
    printf '%s\n' "repo_root_hint: $repo_root_hint"
    printf '%s\n' "current_project: $current_project"
    printf '%s\n' "current_phase: $current_phase"
    printf '%s\n' "last_session: $(utc_timestamp)"
    printf '%s\n' "resume_source: $resume_source"
    printf '%s\n' "synced_at: $(utc_timestamp)"
    printf '%s\n' "preferred_assistant: $preferred_assistant"
    printf '%s\n' "last_blocker: $last_blocker"
    printf '%s\n' "next_steps:"
    printf '%s\n' "  - \"$next_step\""
    printf '%s\n' "bridge_summary: |"
    printf '%s\n' "  $bridge_summary"
  } > "$state_path"

  rm -f "$tmp_path"
}

yaml_value() {
  key=$1
  file_path=$2
  awk -F': ' -v key="$key" '$1 == key { print $2; exit }' "$file_path"
}

resolve_repo_root() {
  target_dir=$(canonical_dir "${1:-.}")
  repo_root=$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$repo_root" ]; then
    canonical_dir "$repo_root"
  else
    printf '%s\n' ""
  fi
}

command_resolve_repo_context() {
  if [ "$#" -gt 1 ]; then
    usage
  fi

  target_dir=$(canonical_dir "${1:-.}")
  repo_root=$(resolve_repo_root "$target_dir")
  is_git_repo=false
  repo_slug=$(basename "$target_dir")
  confidence=low
  worktree_key=

  if [ -n "$repo_root" ]; then
    is_git_repo=true
    repo_slug=$(basename "$repo_root")
    confidence=high
    worktree_key=$repo_root
  fi

  printf '%s\n' "cwd: $target_dir"
  printf '%s\n' "repo_root: ${repo_root:-$target_dir}"
  printf '%s\n' "repo_slug: $repo_slug"
  printf '%s\n' "is_git_repo: $is_git_repo"
  printf '%s\n' "confidence: $confidence"
  printf '%s\n' "worktree_key: ${worktree_key:-$target_dir}"
}

command_read_resume_bridge() {
  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
  fi

  state_path=$1
  target_dir=${2:-.}

  require_file "$state_path"

  repo_context=$(command_resolve_repo_context "$target_dir")
  current_repo_root=$(printf '%s\n' "$repo_context" | awk -F': ' '/^repo_root:/ { print $2; exit }')
  current_repo_slug=$(printf '%s\n' "$repo_context" | awk -F': ' '/^repo_slug:/ { print $2; exit }')
  current_confidence=$(printf '%s\n' "$repo_context" | awk -F': ' '/^confidence:/ { print $2; exit }')

  stored_repo_slug=$(yaml_value repo_slug "$state_path")
  stored_repo_root_hint=$(normalize_path_if_dir "$(yaml_value repo_root_hint "$state_path")")
  resume_source=$(yaml_value resume_source "$state_path")
  last_artifact_ref=$(yaml_value last_artifact_ref "$state_path")
  bridge_summary=$(read_multiline_yaml_block "$state_path")

  bridge_valid=true
  mismatch_reason=
  if [ -n "$stored_repo_root_hint" ] && [ -n "$current_repo_root" ] && [ "$stored_repo_root_hint" != "$current_repo_root" ]; then
    bridge_valid=false
    mismatch_reason=repo_root_hint_mismatch
  elif [ -n "$stored_repo_slug" ] && [ "$stored_repo_slug" != "$current_repo_slug" ]; then
    bridge_valid=false
    mismatch_reason=repo_slug_mismatch
  fi

  printf '%s\n' "$repo_context"
  printf '%s\n' "stored_repo_slug: $stored_repo_slug"
  printf '%s\n' "stored_repo_root_hint: $stored_repo_root_hint"
  printf '%s\n' "resume_source: $resume_source"
  printf '%s\n' "last_artifact_ref: $last_artifact_ref"
  printf '%s\n' "bridge_valid: $bridge_valid"
  printf '%s\n' "mismatch_reason: ${mismatch_reason:-none}"
  printf '%s\n' "bridge_confidence: $current_confidence"
  printf '%s\n' "bridge_summary: |"
  if [ -n "$bridge_summary" ]; then
    printf '%s\n' "$bridge_summary" | sed 's/^/  /'
  fi
}

command_probe_assistants() {
  if [ "$#" -gt 1 ]; then
    usage
  fi

  target_dir=$(canonical_dir "${1:-.}")
  claude_signal=false
  codex_signal=false
  cursor_signal=false
  preferred=codex
  confidence=inconclusive
  fallback_used=true

  if [ -f "$target_dir/.claude/settings.local.json" ] || [ -f "$target_dir/src/shared/layer0.md" ] || [ -f "$target_dir/sync-claude-skill.sh" ]; then
    claude_signal=true
  fi
  if [ -f "$target_dir/.codex-plugin/plugin.json" ] || [ -f "$target_dir/skills/projectpal/SKILL.md" ] || [ -f "$target_dir/sync-codex-plugin.sh" ]; then
    codex_signal=true
  fi
  if [ -f "$target_dir/sync-cursor-skill.sh" ]; then
    cursor_signal=true
  fi

  if [ -n "${PROJECTPAL_ASSISTANT_HINT:-}" ]; then
    preferred=$PROJECTPAL_ASSISTANT_HINT
    confidence=high
    fallback_used=false
  elif [ "$claude_signal" = "true" ] && [ "$codex_signal" = "false" ]; then
    preferred=claude
    confidence=high
    fallback_used=false
  elif [ "$claude_signal" = "false" ] && [ "$codex_signal" = "false" ] && [ "$cursor_signal" = "true" ]; then
    preferred=cursor
    confidence=high
    fallback_used=false
  elif [ "$claude_signal" = "false" ] && [ "$codex_signal" = "true" ]; then
    preferred=codex
    confidence=high
    fallback_used=false
  fi

  printf '%s\n' "preferred: $preferred"
  printf '%s\n' "confidence: $confidence"
  printf '%s\n' "fallback_used: $fallback_used"
  printf '%s\n' "signals:"
  printf '%s\n' "  - claude:$claude_signal"
  printf '%s\n' "  - codex:$codex_signal"
  printf '%s\n' "  - cursor:$cursor_signal"
}

assistant_handoff_message() {
  case ${1:-codex} in
    claude)
      printf '%s\n' "Open Claude Code in this repo and run /projectpal."
      ;;
    cursor)
      printf '%s\n' "Open Cursor in this repo and start ProjectPal."
      ;;
    gemini)
      printf '%s\n' "Open Gemini in this repo and start ProjectPal."
      ;;
    *)
      printf '%s\n' "Open Codex in this repo and type ProjectPal."
      ;;
  esac
}

command_probe_mempalace() {
  if [ "$#" -gt 1 ]; then
    usage
  fi

  target_dir=$(canonical_dir "${1:-.}")
  available=false
  reason=missing
  fallback_mode=local-only
  timeout_ms=1500

  if [ -n "${PROJECTPAL_MEMPALACE_MODE:-}" ]; then
    case "$PROJECTPAL_MEMPALACE_MODE" in
      available)
        available=true
        reason=ok
        fallback_mode=shared-memory
        ;;
      missing)
        available=false
        reason=missing
        ;;
      *)
        available=false
        reason=$PROJECTPAL_MEMPALACE_MODE
        ;;
    esac
  elif [ -f "$target_dir/.mcp.json" ] && grep -q 'mempalace' "$target_dir/.mcp.json"; then
    available=true
    reason=ok
    fallback_mode=shared-memory
  elif [ -f "$target_dir/.gemini/settings.json" ] && grep -q 'mempalace' "$target_dir/.gemini/settings.json"; then
    available=true
    reason=ok
    fallback_mode=shared-memory
  fi

  printf '%s\n' "available: $available"
  printf '%s\n' "reason: $reason"
  printf '%s\n' "timeout_ms: $timeout_ms"
  printf '%s\n' "fallback_mode: $fallback_mode"
}

command_prepare_repo() {
  if [ "$#" -gt 1 ]; then
    usage
  fi

  target_dir=$(canonical_dir "${1:-.}")
  repo_context=$(command_resolve_repo_context "$target_dir")
  repo_root=$(printf '%s\n' "$repo_context" | awk -F': ' '/^repo_root:/ { print $2; exit }')
  repo_slug=$(printf '%s\n' "$repo_context" | awk -F': ' '/^repo_slug:/ { print $2; exit }')
  is_git_repo=$(printf '%s\n' "$repo_context" | awk -F': ' '/^is_git_repo:/ { print $2; exit }')
  projectpal_dir=$repo_root/.projectpal
  artifacts_dir=$projectpal_dir/artifacts
  state_path=$projectpal_dir/state.yml
  gitignore_path=$repo_root/.gitignore
  cursor_rules_dir=$repo_root/.cursor/rules
  cursor_rules_path=$cursor_rules_dir/projectpal.md
  cursor_rules_template=$SCRIPT_DIR/../templates/cursor-rules-projectpal.md
  blocker_mode=${PROJECTPAL_PREPARE_REPO_MODE:-}
  ok=true
  state_status=existing
  gitignore_status=already-present
  cursor_rules_status=already-present
  blocker_name=
  blocker_detail=
  blocker_next_step=

  if [ "$blocker_mode" = "block-projectpal" ]; then
    ok=false
    state_status=blocked
    blocker_name=projectpal-state-write-blocked
    blocker_detail="I couldn't create ProjectPal's local workspace in .projectpal/ yet."
    blocker_next_step="Create .projectpal/state.yml in this repo, then run ProjectPal again."
  else
    mkdir -p "$projectpal_dir" "$artifacts_dir"/brief "$artifacts_dir"/technical-details "$artifacts_dir"/tickets "$artifacts_dir"/refinement
    if [ ! -f "$state_path" ]; then
      {
        printf '%s\n' "repo_slug: $repo_slug"
        printf '%s\n' "repo_root_hint: $repo_root"
        printf '%s\n' "current_project: onboarding"
        printf '%s\n' "current_phase: 0"
        printf '%s\n' "last_session: $(utc_timestamp)"
        printf '%s\n' "resume_source: fresh"
        printf '%s\n' "synced_at: $(utc_timestamp)"
        printf '%s\n' "artifacts_dir: .projectpal/artifacts"
        printf '%s\n' "next_steps:"
        printf '%s\n' "  - \"Finish setting up ProjectPal in this repo\""
        printf '%s\n' "bridge_summary: |"
        printf '%s\n' "  This repo has local ProjectPal state, so you can pick it back up here later."
      } > "$state_path"
      state_status=created
    fi
  fi

  if [ "$ok" = "true" ]; then
    if [ ! -f "$cursor_rules_path" ] && [ -f "$cursor_rules_template" ]; then
      mkdir -p "$cursor_rules_dir"
      cp "$cursor_rules_template" "$cursor_rules_path"
      cursor_rules_status=created
    fi

    if [ "$blocker_mode" = "block-gitignore" ]; then
      ok=false
      gitignore_status=blocked
      blocker_name=gitignore-write-blocked
      blocker_detail="I couldn't update .gitignore, so ProjectPal's local files might get tracked."
      blocker_next_step="Add .projectpal/ to .gitignore, then run ProjectPal again."
    else
      if [ -f "$gitignore_path" ]; then
        if grep -Fqx '.projectpal/' "$gitignore_path"; then
          gitignore_status=already-present
        else
          printf '%s\n' ".projectpal/" >> "$gitignore_path"
          gitignore_status=updated
        fi
      else
        if [ "$is_git_repo" = "true" ]; then
          printf '%s\n' ".projectpal/" > "$gitignore_path"
          gitignore_status=created
        else
          gitignore_status=advice-only
        fi
      fi
    fi
  fi

  printf '%s\n' "$repo_context"
  printf '%s\n' "ok: $ok"
  printf '%s\n' "projectpal_dir: $projectpal_dir"
  printf '%s\n' "state_path: $state_path"
  printf '%s\n' "state_status: $state_status"
  printf '%s\n' "cursor_rules_path: $cursor_rules_path"
  printf '%s\n' "cursor_rules_status: $cursor_rules_status"
  printf '%s\n' "gitignore_path: $gitignore_path"
  printf '%s\n' "gitignore_status: $gitignore_status"
  if [ "$ok" = "false" ]; then
    printf '%s\n' "blocker_name: $blocker_name"
    printf '%s\n' "blocker_detail: $blocker_detail"
    printf '%s\n' "blocker_next_step: $blocker_next_step"
  fi
}

command_onboarding_flow() {
  if [ "$#" -gt 1 ]; then
    usage
  fi

  target_dir=$(canonical_dir "${1:-.}")
  repo_context=$(command_resolve_repo_context "$target_dir")
  repo_root=$(printf '%s\n' "$repo_context" | awk -F': ' '/^repo_root:/ { print $2; exit }')
  repo_slug=$(printf '%s\n' "$repo_context" | awk -F': ' '/^repo_slug:/ { print $2; exit }')

  assistant_probe=$(command_probe_assistants "$target_dir")
  preferred_assistant=$(printf '%s\n' "$assistant_probe" | awk -F': ' '/^preferred:/ { print $2; exit }')
  assistant_confidence=$(printf '%s\n' "$assistant_probe" | awk -F': ' '/^confidence:/ { print $2; exit }')
  assistant_fallback=$(printf '%s\n' "$assistant_probe" | awk -F': ' '/^fallback_used:/ { print $2; exit }')

  mempalace_probe=$(command_probe_mempalace "$target_dir")
  mempalace_available=$(printf '%s\n' "$mempalace_probe" | awk -F': ' '/^available:/ { print $2; exit }')
  mempalace_reason=$(printf '%s\n' "$mempalace_probe" | awk -F': ' '/^reason:/ { print $2; exit }')
  mempalace_mode=$(printf '%s\n' "$mempalace_probe" | awk -F': ' '/^fallback_mode:/ { print $2; exit }')

  prepare_output=$(command_prepare_repo "$target_dir")
  repo_ready=$(printf '%s\n' "$prepare_output" | awk -F': ' '/^ok:/ { print $2; exit }')
  state_path=$(printf '%s\n' "$prepare_output" | awk -F': ' '/^state_path:/ { print $2; exit }')
  blocker_name=$(printf '%s\n' "$prepare_output" | awk -F': ' '/^blocker_name:/ { print $2; exit }')
  blocker_detail=$(printf '%s\n' "$prepare_output" | awk -F': ' '/^blocker_detail:/ { print $2; exit }')
  blocker_next_step=$(printf '%s\n' "$prepare_output" | awk -F': ' '/^blocker_next_step:/ { print $2; exit }')

  handoff_message=$(assistant_handoff_message "$preferred_assistant")
  bridge_summary="This repo is ready for ProjectPal. Local state is set up, MemPalace is connected for longer-term memory. Next step: $handoff_message"
  next_step=$handoff_message
  current_phase=onboarding
  last_blocker=none

  if [ "$repo_ready" = "false" ]; then
    handoff_message=$blocker_next_step
    bridge_summary="This repo is almost ready for ProjectPal. One blocker still needs attention: $blocker_detail Next step: $blocker_next_step"
    next_step=$blocker_next_step
    last_blocker=$blocker_name
  elif [ "$mempalace_available" = "false" ]; then
    bridge_summary="This repo is ready for ProjectPal. Local state is set up here, so you can keep going in this repo today and pick it back up here later. MemPalace would add longer-term memory across sessions and repos. Next step: $handoff_message"
  fi

  if [ -f "$state_path" ]; then
    write_bridge_state "$state_path" "$repo_slug" "$repo_root" "onboarding" "$current_phase" "bridge" "$preferred_assistant" "$last_blocker" "$next_step" "$bridge_summary"
  fi

  printf '%s\n' "$repo_context"
  printf '%s\n' "assistant_preferred: $preferred_assistant"
  printf '%s\n' "assistant_confidence: $assistant_confidence"
  printf '%s\n' "assistant_fallback_used: $assistant_fallback"
  printf '%s\n' "mempalace_available: $mempalace_available"
  printf '%s\n' "mempalace_reason: $mempalace_reason"
  printf '%s\n' "mempalace_mode: $mempalace_mode"
  printf '%s\n' "repo_ready: $repo_ready"
  if [ "$repo_ready" = "false" ]; then
    printf '%s\n' "blocker_name: $blocker_name"
    printf '%s\n' "blocker_detail: $blocker_detail"
    printf '%s\n' "final_next_step: $blocker_next_step"
  else
    printf '%s\n' "final_next_step: $handoff_message"
  fi
  printf '%s\n' "handoff_message: $handoff_message"
  printf '%s\n' "state_path: $state_path"
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

  stored_repo_root_hint=$(yaml_value repo_root_hint "$state_path")
  current_repo_root=$(resolve_repo_root "$(dirname "$state_path")")
  repo_root_hint=$stored_repo_root_hint
  if [ -n "$current_repo_root" ]; then
    repo_root_hint=$current_repo_root
  fi

  tmp_path=$(mktemp)
  awk '
    BEGIN {
      skip = 0
    }
    /^repo_root_hint:/ { next }
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
    if [ -n "$repo_root_hint" ]; then
      printf '%s\n' "repo_root_hint: $repo_root_hint"
    fi
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

command_thread_orchestration_isolation_check() {
  if [ "$#" -ne 1 ]; then
    usage
  fi

  fixture_path=$1
  require_file "$fixture_path"

  resume_primary=$(yaml_value resume_preserves_primary_assistant "$fixture_path")
  resume_approval=$(yaml_value resume_preserves_approval_state "$fixture_path")
  resume_path=$(yaml_value resume_preserves_approved_execution_path_id "$fixture_path")
  new_thread_non_inheritance=$(yaml_value new_thread_non_inheritance "$fixture_path")
  new_thread_primary=$(yaml_value new_thread_primary_assistant "$fixture_path")
  new_thread_approval=$(yaml_value new_thread_approval_state "$fixture_path")
  new_thread_path=$(yaml_value new_thread_approved_execution_path_id "$fixture_path")
  assistant_switch_non_inheritance=$(yaml_value assistant_switch_non_inheritance "$fixture_path")
  assistant_switch_primary=$(yaml_value assistant_switch_primary_assistant "$fixture_path")
  assistant_switch_approval=$(yaml_value assistant_switch_approval_state "$fixture_path")
  assistant_switch_path=$(yaml_value assistant_switch_approved_execution_path_id "$fixture_path")

  resume_same_thread_preserved=false
  if [ -n "$resume_primary" ] && [ -n "$resume_approval" ] && [ -n "$resume_path" ]; then
    resume_same_thread_preserved=true
  fi

  printf '%s\n' "fixture_ref: $fixture_path"
  printf '%s\n' "resume_same_thread_preserved: $resume_same_thread_preserved"
  printf '%s\n' "resume_same_thread_primary_assistant: $resume_primary"
  printf '%s\n' "resume_same_thread_approval_state: $resume_approval"
  printf '%s\n' "resume_same_thread_approved_execution_path_id: $resume_path"
  printf '%s\n' "new_thread_non_inheritance: $new_thread_non_inheritance"
  printf '%s\n' "new_thread_primary_assistant: $new_thread_primary"
  printf '%s\n' "new_thread_approval_state: $new_thread_approval"
  printf '%s\n' "new_thread_approved_execution_path_id: $new_thread_path"
  printf '%s\n' "assistant_switch_non_inheritance: $assistant_switch_non_inheritance"
  printf '%s\n' "assistant_switch_primary_assistant: $assistant_switch_primary"
  printf '%s\n' "assistant_switch_approval_state: $assistant_switch_approval"
  printf '%s\n' "assistant_switch_approved_execution_path_id: $assistant_switch_path"
  printf '%s\n' "fields_checked:"
  fields_output=$(
    awk '
      /^## Non-inheritance fields/ { in_fields = 1; next }
      in_fields && /^- / {
        sub(/^- /, "", $0)
        print "  - " $0
        next
      }
      in_fields { exit }
    ' "$fixture_path"
  )
  if [ -n "$fields_output" ]; then
    printf '%s\n' "$fields_output"
  else
    printf '%s\n' "  []"
  fi
}

command_agent_orchestration_proof_flow_check() {
  if [ "$#" -ne 1 ]; then
    usage
  fi

  fixture_path=$1
  require_file "$fixture_path"

  primary_assistant=$(yaml_value primary_assistant "$fixture_path")
  delegated_assistant=$(yaml_value delegated_assistant "$fixture_path")
  execution_path_connector=$(yaml_value execution_path_connector "$fixture_path")
  execution_path_provider=$(yaml_value execution_path_provider "$fixture_path")
  execution_path_runtime_path=$(yaml_value execution_path_runtime_path "$fixture_path")
  execution_path_quality_tier=$(yaml_value execution_path_quality_tier "$fixture_path")
  same_path_fallback_type=$(yaml_value same_path_fallback_type "$fixture_path")
  same_path_fallback_disclosed_in_next_summary=$(yaml_value same_path_fallback_disclosed_in_next_summary "$fixture_path")
  same_path_fallback_visible_owner=$(yaml_value same_path_fallback_visible_owner "$fixture_path")
  path_switch_fallback_type=$(yaml_value path_switch_fallback_type "$fixture_path")
  path_switch_approval_required=$(yaml_value path_switch_approval_required "$fixture_path")
  path_switch_changed_fields=$(yaml_value path_switch_changed_fields "$fixture_path")
  path_switch_visible_owner=$(yaml_value path_switch_visible_owner "$fixture_path")
  parallel_delegated_work_blocked=$(yaml_value parallel_delegated_work_blocked "$fixture_path")
  parallel_delegation_visible_owner=$(yaml_value parallel_delegation_visible_owner "$fixture_path")

  printf '%s\n' "fixture_ref: $fixture_path"
  printf '%s\n' "primary_assistant: $primary_assistant"
  printf '%s\n' "delegated_assistant: $delegated_assistant"
  printf '%s\n' "execution_path_connector: $execution_path_connector"
  printf '%s\n' "execution_path_provider: $execution_path_provider"
  printf '%s\n' "execution_path_runtime_path: $execution_path_runtime_path"
  printf '%s\n' "execution_path_quality_tier: $execution_path_quality_tier"
  printf '%s\n' "same_path_fallback_type: $same_path_fallback_type"
  printf '%s\n' "same_path_fallback_disclosed_in_next_summary: $same_path_fallback_disclosed_in_next_summary"
  printf '%s\n' "same_path_fallback_visible_owner: $same_path_fallback_visible_owner"
  printf '%s\n' "path_switch_fallback_type: $path_switch_fallback_type"
  printf '%s\n' "path_switch_approval_required: $path_switch_approval_required"
  printf '%s\n' "path_switch_changed_fields: $path_switch_changed_fields"
  printf '%s\n' "path_switch_visible_owner: $path_switch_visible_owner"
  printf '%s\n' "parallel_delegated_work_blocked: $parallel_delegated_work_blocked"
  printf '%s\n' "parallel_delegation_visible_owner: $parallel_delegation_visible_owner"
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
  resolve-repo-context) command_resolve_repo_context "$@" ;;
  read-resume-bridge) command_read_resume_bridge "$@" ;;
  probe-assistants) command_probe_assistants "$@" ;;
  probe-mempalace) command_probe_mempalace "$@" ;;
  prepare-repo) command_prepare_repo "$@" ;;
  onboarding-flow) command_onboarding_flow "$@" ;;
  artifact-budget-check) command_artifact_budget_check "$@" ;;
  split-evaluate) command_split_evaluate "$@" ;;
  handoff-build) command_handoff_build "$@" ;;
  context-reset-evaluate) command_context_reset_evaluate "$@" ;;
  memory-summary) command_memory_summary "$@" ;;
  build-phase-input) command_build_phase_input "$@" ;;
  sync-resume-bridge) command_sync_resume_bridge "$@" ;;
  reduction-report) command_reduction_report "$@" ;;
  phase7-batch-close-check) command_phase7_batch_close_check "$@" ;;
  thread-orchestration-isolation-check) command_thread_orchestration_isolation_check "$@" ;;
  agent-orchestration-proof-flow-check) command_agent_orchestration_proof_flow_check "$@" ;;
  generate-implementation-aid) command_generate_implementation_aid "$@" ;;
  *) usage ;;
esac
