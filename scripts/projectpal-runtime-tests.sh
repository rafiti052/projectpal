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

existing_repo="$TMP_DIR/existing-repo"
new_repo="$TMP_DIR/new-repo"
mkdir -p "$existing_repo" "$new_repo"
git -C "$existing_repo" init >/dev/null 2>&1
git -C "$new_repo" init >/dev/null 2>&1
printf '%s\n' "# Existing Repo" > "$existing_repo/README.md"

sync_output=$(sh "$ROOT_DIR/sync-codex-plugin.sh")
assert_contains "$sync_output" "Generated CLAUDE.md from src/projectpal/shared/layer0.md"
assert_contains "$sync_output" "Generated AGENTS.md from src/projectpal/shared/layer0.md"
assert_contains "$sync_output" "Generated skills/projectpal/SKILL.md from src/projectpal"

assert_file_contains "$ROOT_DIR/CLAUDE.md" "ProjectPal neutral source under src/projectpal/"
assert_file_contains "$ROOT_DIR/AGENTS.md" "ProjectPal neutral source under src/projectpal/"
assert_file_contains "$ROOT_DIR/skills/projectpal/SKILL.md" 'In Codex, start ProjectPal by typing `ProjectPal`.'

codex_install_output=$(sh "$ROOT_DIR/install-projectpal.sh" codex)
assert_contains "$codex_install_output" "ProjectPal is installed for Codex."
assert_contains "$codex_install_output" "Next step: open Codex in the new or existing project repo and type ProjectPal."

claude_home="$TMP_DIR/claude-home"
mkdir -p "$claude_home"
claude_install_output=$(HOME="$claude_home" sh "$ROOT_DIR/install-projectpal.sh" claude)
assert_contains "$claude_install_output" "ProjectPal is installed for Claude Code."
assert_contains "$claude_install_output" "Next step: open Claude Code and run /projectpal."
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
