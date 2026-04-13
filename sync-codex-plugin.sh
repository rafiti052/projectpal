#!/bin/sh
# Generate CLAUDE.md, AGENTS.md, and skills/projectpal/SKILL.md from src/.

set -eu

SOURCE_DIR="src"
SHARED_FILE="$SOURCE_DIR/shared/layer0.md"
PREFIX_FILE="$SOURCE_DIR/adapters/runtime-output-prefix.md"
SKILL_HEADER_FILE="$SOURCE_DIR/adapters/codex-skill-header.md"
CLAUDE_FILE="CLAUDE.md"
SKILL_DIR="skills/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"
AGENTS_FILE="AGENTS.md"

mkdir -p "$SKILL_DIR"

cat "$PREFIX_FILE" > "$CLAUDE_FILE"
printf '\n' >> "$CLAUDE_FILE"
cat "$SHARED_FILE" >> "$CLAUDE_FILE"

cat "$PREFIX_FILE" > "$AGENTS_FILE"
printf '\n' >> "$AGENTS_FILE"
cat "$SHARED_FILE" >> "$AGENTS_FILE"

cat "$SKILL_HEADER_FILE" > "$SKILL_FILE"
printf '\n' >> "$SKILL_FILE"
cat "$PREFIX_FILE" >> "$SKILL_FILE"
printf '\n' >> "$SKILL_FILE"
cat "$SHARED_FILE" >> "$SKILL_FILE"

echo "Generated $CLAUDE_FILE from $SHARED_FILE"
echo "Generated $AGENTS_FILE from $SHARED_FILE"
echo "Generated $SKILL_FILE from $SOURCE_DIR"
