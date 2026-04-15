#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/projectpal-runtime-tests.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

assert_contains() {
  haystack=$1
  needle=$2
  if ! printf '%s\n' "$haystack" | grep -F -- "$needle" >/dev/null 2>&1; then
    printf '%s\n' "assertion failed: expected output to contain: $needle" >&2
    exit 1
  fi
}

assert_file_contains() {
  file_path=$1
  needle=$2
  if ! grep -F -- "$needle" "$file_path" >/dev/null 2>&1; then
    printf '%s\n' "assertion failed: expected $file_path to contain: $needle" >&2
    exit 1
  fi
}

assert_file_not_contains() {
  file_path=$1
  needle=$2
  if grep -F -- "$needle" "$file_path" >/dev/null 2>&1; then
    printf '%s\n' "assertion failed: expected $file_path not to contain: $needle" >&2
    exit 1
  fi
}

existing_repo="$TMP_DIR/existing-repo"
new_repo="$TMP_DIR/new-repo"
default_home="$TMP_DIR/default-home"
legacy_scope_framing="Discovery → Scope"" Framing"
legacy_old_guidance_line="**At every check""point, show what is documented so far, show the current plan, and ask for guidance before moving on.**"
legacy_old_conversation_line="Check""points are conversations, not forms."
mkdir -p "$existing_repo" "$new_repo" "$default_home"
git -C "$existing_repo" init >/dev/null 2>&1
git -C "$new_repo" init >/dev/null 2>&1
printf '%s\n' "# Existing Repo" > "$existing_repo/README.md"

sync_output=$(sh "$ROOT_DIR/sync-codex-plugin.sh")
assert_contains "$sync_output" "Generated CLAUDE.md from src/shared/layer0.md"
assert_contains "$sync_output" "Generated AGENTS.md from src/shared/layer0.md"
assert_contains "$sync_output" "Generated skills/projectpal/SKILL.md from src"
repo_audit_output=$(sh "$ROOT_DIR/scripts/projectpal-copy-audit.sh" "$ROOT_DIR")
assert_contains "$repo_audit_output" "projectpal-copy audit passed"

assert_file_contains "$ROOT_DIR/CLAUDE.md" "ProjectPal neutral source under src/"
assert_file_contains "$ROOT_DIR/AGENTS.md" "ProjectPal neutral source under src/"
assert_file_contains "$ROOT_DIR/AGENTS.md" "Complexity Assessment"
assert_file_contains "$ROOT_DIR/AGENTS.md" "👷 ProjectPal"
assert_file_contains "$ROOT_DIR/AGENTS.md" "You turn the conversation into a first scoped draft of the work."
assert_file_contains "$ROOT_DIR/AGENTS.md" "You break the work into tickets after Solution or Technical Details approval. Runs on every route — never skipped."
assert_file_contains "$ROOT_DIR/AGENTS.md" "**At every Check-in, show what is documented so far, show the current plan, and ask for guidance before moving on.**"
assert_file_contains "$ROOT_DIR/AGENTS.md" "**Check-ins are conversations, not forms.** \"Here's what I got. Sound right?\""
assert_file_contains "$ROOT_DIR/AGENTS.md" "**Tickets are 15-minute chunks.** Respect the focus window."
assert_file_not_contains "$ROOT_DIR/AGENTS.md" "$legacy_scope_framing"
assert_file_not_contains "$ROOT_DIR/AGENTS.md" "$legacy_old_guidance_line"
assert_file_not_contains "$ROOT_DIR/AGENTS.md" "$legacy_old_conversation_line"
assert_file_contains "$ROOT_DIR/skills/projectpal/SKILL.md" 'In Codex, start ProjectPal by typing `ProjectPal`.'
assert_file_contains "$ROOT_DIR/skills/projectpal/SKILL.md" "**Check-ins are conversations, not forms.** \"Here's what I got. Sound right?\""
assert_file_not_contains "$ROOT_DIR/skills/projectpal/SKILL.md" "$legacy_scope_framing"
assert_file_not_contains "$ROOT_DIR/skills/projectpal/SKILL.md" "$legacy_old_guidance_line"
assert_file_contains "$ROOT_DIR/instructions/session-resumption-schema.md" 'Read `.projectpal/state.yml` for the current repo first.'
assert_file_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" "MemPalace is what lets me carry context across sessions and across repos."
assert_file_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" 'This repo can still resume from `.projectpal/state.yml`, and MemPalace is what adds longer-term memory across sessions and across repos.'
assert_file_not_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" "my long-term memory layer"
assert_file_not_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" "they won't carry over"

install_output=$(HOME="$default_home" sh "$ROOT_DIR/install-projectpal.sh")
assert_contains "$install_output" "ProjectPal is ready in all supported assistants."

claude_home="$TMP_DIR/claude-home"
mkdir -p "$claude_home"
claude_install_output=$(HOME="$claude_home" sh "$ROOT_DIR/install-projectpal.sh")
assert_contains "$claude_install_output" "ProjectPal is ready in all supported assistants."
installed_audit_output=$(sh "$ROOT_DIR/scripts/projectpal-copy-audit.sh" "$claude_home/.claude/skills/projectpal" "$claude_home/.codex/skills/projectpal")
assert_contains "$installed_audit_output" "projectpal-copy audit passed"
assert_file_contains "$claude_home/.claude/skills/projectpal/SKILL.md" "name: projectpal"
assert_file_contains "$claude_home/.claude/skills/projectpal/SKILL.md" "**At every Check-in, show what is documented so far, show the current plan, and ask for guidance before moving on.**"
assert_file_contains "$claude_home/.claude/skills/projectpal/SKILL.md" "**Check-ins are conversations, not forms.** \"Here's what I got. Sound right?\""
assert_file_not_contains "$claude_home/.claude/skills/projectpal/SKILL.md" "$legacy_scope_framing"
assert_file_not_contains "$claude_home/.claude/skills/projectpal/SKILL.md" "$legacy_old_guidance_line"
assert_file_contains "$claude_home/.codex/skills/projectpal/SKILL.md" "**At every Check-in, show what is documented so far, show the current plan, and ask for guidance before moving on.**"
assert_file_contains "$claude_home/.codex/skills/projectpal/SKILL.md" "**Check-ins are conversations, not forms.** \"Here's what I got. Sound right?\""
assert_file_not_contains "$claude_home/.codex/skills/projectpal/SKILL.md" "$legacy_scope_framing"
assert_file_not_contains "$claude_home/.codex/skills/projectpal/SKILL.md" "$legacy_old_guidance_line"
assert_file_contains "$claude_home/.projectpal/routing.yml" "preferred_model: gemini-fast"
assert_file_contains "$claude_home/.projectpal/routing.yml" "task_type: refinement"
assert_file_contains "$claude_home/.cursor/mcp.json" "\"projectpal\""
assert_file_contains "$claude_home/.cursor/mcp.json" "\"connector\": \"cursor\""

second_install_output=$(HOME="$claude_home" sh "$ROOT_DIR/install-projectpal.sh")
assert_contains "$second_install_output" "ProjectPal is ready in all supported assistants."
projectpal_entry_count=$(grep -c '"projectpal"' "$claude_home/.cursor/mcp.json")
if [ "$projectpal_entry_count" -ne 1 ]; then
  printf '%s\n' "assertion failed: expected one projectpal cursor entry, found $projectpal_entry_count" >&2
  exit 1
fi

existing_flow_output=$(PROJECTPAL_ASSISTANT_HINT=codex PROJECTPAL_MEMPALACE_MODE=missing sh "$ROOT_DIR/scripts/projectpal-flow.sh" onboarding-flow "$existing_repo")
assert_contains "$existing_flow_output" "assistant_preferred: codex"
assert_contains "$existing_flow_output" "repo_ready: true"
assert_contains "$existing_flow_output" "final_next_step: Open Codex in this repo and type ProjectPal."
assert_file_contains "$existing_repo/.cursor/rules/projectpal.md" "# ProjectPal"
assert_file_not_contains "$existing_repo/.cursor/rules/projectpal.md" "pp-compress"

new_flow_output=$(PROJECTPAL_ASSISTANT_HINT=codex PROJECTPAL_MEMPALACE_MODE=missing sh "$ROOT_DIR/scripts/projectpal-flow.sh" onboarding-flow "$new_repo")
assert_contains "$new_flow_output" "assistant_preferred: codex"
assert_contains "$new_flow_output" "repo_ready: true"
assert_contains "$new_flow_output" "final_next_step: Open Codex in this repo and type ProjectPal."
assert_file_contains "$new_repo/.cursor/rules/projectpal.md" "## Deferred instructions"
assert_file_not_contains "$new_repo/.cursor/rules/projectpal.md" "settings.json"

printf '%s\n' "projectpal-runtime tests passed"
