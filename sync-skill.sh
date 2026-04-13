#!/bin/sh
# Sync CLAUDE.md → ~/.claude/skills/projectpal/SKILL.md
# Run this after editing CLAUDE.md to redeploy the persona.

SKILL_DIR="$HOME/.claude/skills/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"

mkdir -p "$SKILL_DIR"

cat > "$SKILL_FILE" << 'HEADER'
---
name: projectpal
description: ProjectPal — your product companion. Turns chaotic ideas into shipped projects.
user-invocable: true
---

HEADER

cat CLAUDE.md >> "$SKILL_FILE"

cat >> "$SKILL_FILE" << 'FOOTER'

---

## State & Artifacts

**Project-local** (`.projectpal/` in the current working directory — readable alongside the code):
- Parking Lot: `.projectpal/parking-lot.md`
- Artifacts: `.projectpal/artifacts/{prd,tech-spec,tickets,debate}/`

**Global** (`~/.projectpal/` — cross-project, always at this absolute path):
- Session state: `~/.projectpal/state.yml`
- Debate log: `~/.projectpal/debate-log.md`

If `.projectpal/artifacts/` does not exist in the current project, create it before saving. Never use `~/.projectpal/` for artifacts or parking-lot.
FOOTER

cp CLAUDE.md AGENTS.md

echo "Synced CLAUDE.md → $SKILL_FILE"
echo "Synced CLAUDE.md → AGENTS.md"
