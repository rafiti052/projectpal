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
mkdir -p "$existing_repo" "$new_repo"
git -C "$existing_repo" init >/dev/null 2>&1
git -C "$new_repo" init >/dev/null 2>&1
printf '%s\n' "# Existing Repo" > "$existing_repo/README.md"

sync_output=$(sh "$ROOT_DIR/sync-codex-plugin.sh")
assert_contains "$sync_output" "Generated CLAUDE.md from src/shared/layer0.md"
assert_contains "$sync_output" "Generated AGENTS.md from src/shared/layer0.md"
assert_contains "$sync_output" "Generated skills/projectpal/SKILL.md from src"

assert_file_contains "$ROOT_DIR/CLAUDE.md" "ProjectPal neutral source under src/"
assert_file_contains "$ROOT_DIR/AGENTS.md" "ProjectPal neutral source under src/"
assert_file_contains "$ROOT_DIR/AGENTS.md" "Complexity Assessment"
assert_file_contains "$ROOT_DIR/AGENTS.md" "👷 ProjectPal"
assert_file_contains "$ROOT_DIR/AGENTS.md" "You turn the conversation into a first scoped draft of the work."
assert_file_contains "$ROOT_DIR/AGENTS.md" "You break the work into small build steps in the background after Solution or Spec approval, depending on the route."
assert_file_contains "$ROOT_DIR/AGENTS.md" "**Build steps are 15-minute chunks.** Respect the focus window."
assert_file_contains "$ROOT_DIR/skills/projectpal/SKILL.md" 'In Codex, start ProjectPal by typing `ProjectPal`.'
assert_file_contains "$ROOT_DIR/instructions/session-resumption-schema.md" 'Read `.projectpal/state.yml` for the current repo first.'
assert_file_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" "MemPalace is what lets me carry context across sessions and across repos."
assert_file_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" 'This repo can still resume from `.projectpal/state.yml`, and MemPalace is what adds longer-term memory across sessions and across repos.'
assert_file_not_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" "my long-term memory layer"
assert_file_not_contains "$ROOT_DIR/instructions/mempalace-onboarding.md" "they won't carry over"

codex_install_output=$(sh "$ROOT_DIR/install-projectpal.sh" codex)
assert_contains "$codex_install_output" "ProjectPal is ready in Codex."
assert_contains "$codex_install_output" "Next, open Codex in your repo and type ProjectPal."

claude_home="$TMP_DIR/claude-home"
mkdir -p "$claude_home"
claude_install_output=$(HOME="$claude_home" sh "$ROOT_DIR/install-projectpal.sh" claude)
assert_contains "$claude_install_output" "ProjectPal is ready in Claude Code."
assert_contains "$claude_install_output" "Next, open Claude Code and run /projectpal."
assert_file_contains "$claude_home/.claude/skills/projectpal/SKILL.md" "name: projectpal"

existing_flow_output=$(PROJECTPAL_ASSISTANT_HINT=codex PROJECTPAL_MEMPALACE_MODE=missing sh "$ROOT_DIR/scripts/projectpal-flow.sh" onboarding-flow "$existing_repo")
assert_contains "$existing_flow_output" "assistant_preferred: codex"
assert_contains "$existing_flow_output" "repo_ready: true"
assert_contains "$existing_flow_output" "final_next_step: Open Codex in this repo and type ProjectPal."

new_flow_output=$(PROJECTPAL_ASSISTANT_HINT=codex PROJECTPAL_MEMPALACE_MODE=missing sh "$ROOT_DIR/scripts/projectpal-flow.sh" onboarding-flow "$new_repo")
assert_contains "$new_flow_output" "assistant_preferred: codex"
assert_contains "$new_flow_output" "repo_ready: true"
assert_contains "$new_flow_output" "final_next_step: Open Codex in this repo and type ProjectPal."

printf '%s\n' "projectpal-runtime tests passed"
