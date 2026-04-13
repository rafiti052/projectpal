#!/bin/sh
# Sync the Gemini custom command from the shared ProjectPal instruction source.
# Run this after editing CLAUDE.md to refresh the Gemini launcher command.

set -eu

COMMAND_DIR=".gemini/commands"
COMMAND_FILE="$COMMAND_DIR/projectpal.toml"

mkdir -p "$COMMAND_DIR"

cat > "$COMMAND_FILE" <<'HEADER'
description = "Start ProjectPal from the shared canonical instructions in CLAUDE.md."
prompt = """
Start ProjectPal for this repository.

Use the canonical ProjectPal instructions below.

@{CLAUDE.md}

After reading those instructions, open in Phase 0 with warm conversational intake and ask only one question.

If the user typed extra arguments after /projectpal, treat them as the latest user message.
"""
HEADER

echo "Synced CLAUDE.md -> $COMMAND_FILE"
