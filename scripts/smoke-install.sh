#!/bin/sh
# Smoke-test the generated build/install contract in a temporary HOME and repo.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/projectpal-smoke-install.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

HOME_DIR="$TMP_DIR/home"
REPO_DIR="$TMP_DIR/repo"

mkdir -p "$HOME_DIR" "$REPO_DIR"

assert_file_contains() {
  file_path=$1
  needle=$2

  if ! grep -F -- "$needle" "$file_path" >/dev/null 2>&1; then
    printf '%s\n' "smoke-install: expected $file_path to contain: $needle" >&2
    exit 1
  fi
}

sh "$ROOT_DIR/scripts/validate-platform.sh" all >/dev/null
sh "$ROOT_DIR/scripts/install-local.sh" all --home "$HOME_DIR" --repo "$REPO_DIR" >/dev/null
sh "$ROOT_DIR/scripts/install-local.sh" cursor --home "$HOME_DIR" --repo "$REPO_DIR" >/dev/null

assert_file_contains "$HOME_DIR/.claude/skills/projectpal/SKILL.md" "name: projectpal"
assert_file_contains "$HOME_DIR/.codex/skills/projectpal/SKILL.md" "name: projectpal"
assert_file_contains "$HOME_DIR/.cursor/mcp.json" "\"projectpal\""
assert_file_contains "$REPO_DIR/.cursor/rules/projectpal.md" "## Deferred instructions"

projectpal_entry_count=$(grep -c '"projectpal"' "$HOME_DIR/.cursor/mcp.json")
if [ "$projectpal_entry_count" -ne 1 ]; then
  printf '%s\n' "smoke-install: expected one Cursor projectpal entry, found $projectpal_entry_count" >&2
  exit 1
fi

printf '%s\n' "smoke install passed"
