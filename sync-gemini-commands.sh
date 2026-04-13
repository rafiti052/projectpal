#!/bin/sh
# Sync the Gemini custom command from the generated ProjectPal runtime surface.
# Run this after refreshing generated runtime surfaces to update the Gemini launcher command.

set -eu

COMMAND_DIR=".gemini/commands"
COMMAND_FILE="$COMMAND_DIR/projectpal.toml"

mkdir -p "$COMMAND_DIR"

cat > "$COMMAND_FILE" <<'HEADER'
description = "Start ProjectPal from the generated runtime surface backed by src/projectpal."
prompt = """
Start ProjectPal for this repository.

Use the generated ProjectPal runtime surface below.

@{CLAUDE.md}

After reading those instructions, open in Phase 0 with warm conversational intake and ask only one question.

If the user typed extra arguments after /projectpal, treat them as the latest user message.
"""
HEADER

echo "Synced generated CLAUDE.md -> $COMMAND_FILE"
