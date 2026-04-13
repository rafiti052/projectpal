#!/bin/sh
# Sync CLAUDE.md -> AGENTS.md and skills/projectpal/SKILL.md.
# Run this after editing CLAUDE.md to refresh the generated instruction surfaces.

SKILL_DIR="skills/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"
AGENTS_FILE="AGENTS.md"

mkdir -p "$SKILL_DIR"

cat CLAUDE.md > "$AGENTS_FILE"

cat > "$SKILL_FILE" << 'HEADER'
---
name: projectpal
description: ProjectPal — your product companion. Turns chaotic ideas into shipped projects.
source_of_truth: CLAUDE.md
---

> Codex adapter: These instructions are shared with the Claude Code version. In Codex, start ProjectPal by invoking the `projectpal` skill or by using the documented launcher phrases such as "Start ProjectPal" or "Use the ProjectPal plugin." Do not assume `/projectpal` is a native Codex slash command. Where the text mentions Claude Code-specific commands, Agent, or Bash tool usage, use the equivalent Codex tools available in the current session.

HEADER

cat CLAUDE.md >> "$SKILL_FILE"

cat >> "$SKILL_FILE" << 'FOOTER'

---

## Codex Plugin Packaging

This file is generated from `CLAUDE.md` by `./sync-codex-plugin.sh`.

The Codex plugin entrypoint is `.codex-plugin/plugin.json`, which points at this `skills/` directory and the repo-local `.mcp.json`.

Do not edit this generated skill file directly. Edit `CLAUDE.md`, then run `./sync-codex-plugin.sh`.
FOOTER

echo "Synced CLAUDE.md -> $AGENTS_FILE"
echo "Synced CLAUDE.md -> $SKILL_FILE"
