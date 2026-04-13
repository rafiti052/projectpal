#!/bin/sh
# Sync CLAUDE.md -> skills/projectpal/SKILL.md for the Codex plugin package.
# Run this after editing CLAUDE.md to refresh the Codex skill entrypoint.

SKILL_DIR="skills/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"

mkdir -p "$SKILL_DIR"

cat > "$SKILL_FILE" << 'HEADER'
---
name: projectpal
description: ProjectPal — your product companion. Turns chaotic ideas into shipped projects.
---

> Codex adapter: These instructions are shared with the Claude Code version. Where the text mentions Claude Code-specific commands such as `/projectpal`, interpret that as invoking this `projectpal` skill from Codex. Where it mentions Claude's Agent tool or Bash tool, use the equivalent Codex sub-agent and shell tools available in the current session.

HEADER

cat CLAUDE.md >> "$SKILL_FILE"

cat >> "$SKILL_FILE" << 'FOOTER'

---

## Codex Plugin Packaging

This file is generated from `CLAUDE.md` by `./sync-codex-plugin.sh`.

The Codex plugin entrypoint is `.codex-plugin/plugin.json`, which points at this `skills/` directory and the repo-local `.mcp.json`.

Do not edit this generated skill file directly. Edit `CLAUDE.md`, then run `./sync-codex-plugin.sh`.
FOOTER

echo "Synced CLAUDE.md -> $SKILL_FILE"
