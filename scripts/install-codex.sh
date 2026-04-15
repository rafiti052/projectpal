#!/bin/sh
# Install the generated Codex runtime surface into Codex's global skill directory.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/.."

SKILL_DIR="$HOME/.codex/skills/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"

mkdir -p "$SKILL_DIR"

cp skills/projectpal/SKILL.md "$SKILL_FILE"

echo "Installed generated Codex runtime surface -> $SKILL_FILE"
