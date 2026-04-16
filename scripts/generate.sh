#!/bin/sh
# Generate CLAUDE.md, AGENTS.md, skills/projectpal/SKILL.md, and .cursor/rules/projectpal.md from src/.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT="$SCRIPT_DIR/.."
cd "$REPO_ROOT"

SOURCE_DIR="src"
SHARED_FILE="$SOURCE_DIR/shared/core.md"
PREFIX_FILE="$SOURCE_DIR/adapters/runtime-output-prefix.md"
SKILL_HEADER_FILE="$SOURCE_DIR/adapters/codex-skill-header.md"
CLAUDE_FILE="CLAUDE.md"
SKILL_DIR="skills/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"
# AGENTS.md — Codex runtime surface
AGENTS_FILE="AGENTS.md"
# Cursor workspace rules — auto-loaded by Cursor from .cursor/rules/
CURSOR_RULES_TEMPLATE="templates/cursor-rules-projectpal.md"
CURSOR_RULES_FILE=".cursor/rules/projectpal.md"

mkdir -p "$SKILL_DIR"
mkdir -p ".cursor/rules"

# Snapshot existing files before generation (empty string if file does not exist).
# Only files that already exist are candidates for divergence — fresh generation is not divergence.
prev_claude=""
prev_agents=""
prev_skill=""
prev_cursor_rules=""
claude_existed=0
agents_existed=0
skill_existed=0
cursor_rules_existed=0
if [ -f "$CLAUDE_FILE" ]; then prev_claude=$(cat "$CLAUDE_FILE"); claude_existed=1; fi
if [ -f "$AGENTS_FILE" ]; then prev_agents=$(cat "$AGENTS_FILE"); agents_existed=1; fi
if [ -f "$SKILL_FILE"  ]; then prev_skill=$(cat "$SKILL_FILE");   skill_existed=1;  fi
if [ -f "$CURSOR_RULES_FILE" ]; then prev_cursor_rules=$(cat "$CURSOR_RULES_FILE"); cursor_rules_existed=1; fi

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

cp "$CURSOR_RULES_TEMPLATE" "$CURSOR_RULES_FILE"

# Compare generated output against snapshots.
new_claude=$(cat "$CLAUDE_FILE")
new_agents=$(cat "$AGENTS_FILE")
new_skill=$(cat "$SKILL_FILE")
new_cursor_rules=$(cat "$CURSOR_RULES_FILE")

diverged=0
[ "$claude_existed" -eq 1 ] && [ "$prev_claude" != "$new_claude" ] && diverged=1
[ "$agents_existed" -eq 1 ] && [ "$prev_agents" != "$new_agents" ] && diverged=1
[ "$skill_existed"  -eq 1 ] && [ "$prev_skill"  != "$new_skill"  ] && diverged=1
[ "$cursor_rules_existed" -eq 1 ] && [ "$prev_cursor_rules" != "$new_cursor_rules" ] && diverged=1

if [ "$diverged" -eq 1 ]; then
  printf '\n%s\n' "generate: output diverged from existing files." >&2
  [ "$prev_claude" != "$new_claude" ] && printf '  changed: %s\n' "$CLAUDE_FILE" >&2
  [ "$prev_agents" != "$new_agents" ] && printf '  changed: %s\n' "$AGENTS_FILE" >&2
  [ "$prev_skill"  != "$new_skill"  ] && printf '  changed: %s\n' "$SKILL_FILE" >&2
  [ "$prev_cursor_rules" != "$new_cursor_rules" ] && printf '  changed: %s\n' "$CURSOR_RULES_FILE" >&2
  printf '\n%s\n' "Generated output has been written. To reconcile:" >&2
  printf '%s\n' "  a) Accept as-is — the generated files are now on disk." >&2
  printf '%s\n' "  b) Review source — open src/shared/core.md or templates/cursor-rules-projectpal.md to absorb any manual edits first, then re-run." >&2
  exit 1
fi

echo "Generated $CLAUDE_FILE from $SHARED_FILE"
echo "Generated $AGENTS_FILE from $SHARED_FILE"
echo "Generated $SKILL_FILE from $SOURCE_DIR"
echo "Generated $CURSOR_RULES_FILE from $CURSOR_RULES_TEMPLATE"
