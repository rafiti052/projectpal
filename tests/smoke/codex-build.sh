#!/bin/sh
# Smoke-check the Codex build package and repo-local wrapper paths.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)

assert_file_contains() {
  file_path=$1
  needle=$2

  if ! grep -F -- "$needle" "$file_path" >/dev/null 2>&1; then
    printf '%s\n' "codex-build-smoke: expected $file_path to contain: $needle" >&2
    exit 1
  fi
}

assert_file_not_contains() {
  file_path=$1
  needle=$2

  if grep -F -- "$needle" "$file_path" >/dev/null 2>&1; then
    printf '%s\n' "codex-build-smoke: expected $file_path not to contain: $needle" >&2
    exit 1
  fi
}

sh "$ROOT_DIR/scripts/build-platform.sh" codex >/dev/null
sh "$ROOT_DIR/scripts/install-codex.sh" validate >/dev/null

assert_file_contains "$ROOT_DIR/build/codex/AGENTS.md" "ProjectPal neutral source under src/"
assert_file_contains "$ROOT_DIR/build/codex/skills/projectpal/SKILL.md" 'In Codex, start ProjectPal by typing `ProjectPal`.'
assert_file_contains "$ROOT_DIR/build/codex/.codex-plugin/plugin.json" '"defaultPrompt": ["ProjectPal"]'
assert_file_contains "$ROOT_DIR/.codex-plugin/plugin.json" '"skills": "./build/codex/skills/"'
assert_file_not_contains "$ROOT_DIR/.codex-plugin/plugin.json" '"skills": "./skills/"'
assert_file_contains "$ROOT_DIR/README.md" '`build/codex/.codex-plugin/plugin.json`'
assert_file_contains "$ROOT_DIR/README.md" '`build/codex/skills/projectpal/SKILL.md`'
assert_file_contains "$ROOT_DIR/README.md" 'sh scripts/smoke-install.sh'

printf '%s\n' "codex build smoke passed"
