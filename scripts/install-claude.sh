#!/bin/sh
# Install the generated Claude runtime surface into Claude Code's skill directory.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/.."

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
- Session bridge state: `.projectpal/state.yml`
- Parking Lot: `.projectpal/parking-lot.md`
- Artifacts: `.projectpal/artifacts/` for Briefs, Technical Details, Tickets, and refinement records

**Global** (`MemPalace` and `~/.projectpal/` helper files):
- Repo-scoped continuity: `Projects/<repo-slug>` in MemPalace
- Shared knowledge: `Principles`, `Decisions`, and `Precedents` wings in MemPalace
- Internal review log: stored under `~/.projectpal/`

If `.projectpal/artifacts/` does not exist in the current project, create it before saving. Never use `~/.projectpal/` for session state, artifacts, or parking-lot.
FOOTER

echo "Installed generated Claude runtime surface (CLAUDE.md) -> $SKILL_FILE"
