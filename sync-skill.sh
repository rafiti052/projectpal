#!/bin/sh
# Sync the current canonical ProjectPal source artifact (`CLAUDE.md`)
# into Claude Code's skill directory and the repo-local `AGENTS.md` mirror.

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
- Artifacts: `.projectpal/artifacts/{prd,tech-spec,tickets,debate}/`

**Global** (`MemPalace` and `~/.projectpal/` helper files):
- Repo-scoped continuity: `Projects/<repo-slug>` in MemPalace
- Shared knowledge: `Principles`, `Decisions`, and `Precedents` wings in MemPalace
- Debate log: `~/.projectpal/debate-log.md`

If `.projectpal/artifacts/` does not exist in the current project, create it before saving. Never use `~/.projectpal/` for session state, artifacts, or parking-lot.
FOOTER

cp CLAUDE.md AGENTS.md

echo "Synced current canonical source (CLAUDE.md) -> $SKILL_FILE"
echo "Synced current canonical source (CLAUDE.md) -> AGENTS.md"
