# ProjectPal `v0.1.1`

A patient AI companion that turns chaotic ideas into shipped projects.

## What is this?

ProjectPal is a CLI tool powered by Claude Code that helps you go from messy idea to actionable tickets — without requiring you to have your thoughts organized first.

It works through conversation, not forms. It remembers context between sessions. It captures out-of-phase ideas instead of losing them. And it uses a multi-agent debate system to stress-test your plans before you commit.

## How it works

1. **Talk to the Pal** — describe your idea however it comes out
2. **Cynefin classification** — the Pal identifies the nature of the problem
3. **PRD generation + debate** — a Critic agent and Judge agent pressure-test the plan
4. **You decide** — approve, revise, or archive at every checkpoint
5. **Tech spec → tickets** — broken into 15-minute focus sessions
6. **MemPalace** — everything is remembered for next time

## Setup

```bash
# 1. Clone the repo
git clone git@github.com:rafiti052/projectpal.git
cd projectpal

# 2. Deploy as a Claude Code skill (recommended)
./sync-skill.sh
# This syncs CLAUDE.md → ~/.claude/skills/projectpal/SKILL.md
# making /projectpal available as a slash command in any project

# 3. Run Claude Code anywhere and invoke the Pal
claude
# Type /projectpal to start
```

The Pal loads automatically from `CLAUDE.md`. For non-Claude-Code environments, use `AGENTS.md` (identical content, standard filename).

### MemPalace (long-term memory)

The Pal detects MemPalace automatically on first run. If it's not connected, it will explain what it is and offer to install and register it for you — no manual setup required.

If you prefer to set it up manually:
```bash
pip install mempalace
claude mcp add mempalace --command "python3 -m mempalace.mcp_server"
# Restart Claude Code to activate
```

### Dependencies

- [Claude Code](https://claude.ai/code) (CLI or desktop)
- [MemPalace](https://github.com/rafiti052/mempalace) — optional but recommended for cross-session memory

## Project Structure

```
projectpal/
├── CLAUDE.md                  ← Pal persona + rules (loaded by Claude Code)
├── AGENTS.md                  ← Same as CLAUDE.md (standard agents filename)
├── sync-skill.sh              ← Deploy CLAUDE.md as a Claude Code skill
├── .mcp.json                  ← MemPalace MCP connection
├── prompts/
│   ├── critic-agent.md        ← Critic sub-agent persona
│   ├── judge-agent.md         ← Judge sub-agent persona
│   ├── cynefin-classify.md    ← Domain classification prompt
│   ├── prd-generate.md        ← PRD generation prompt
│   ├── tech-spec-generate.md  ← Tech spec generation prompt
│   └── tickets-generate.md    ← Ticket generation prompt
├── docs/
│   ├── PRD-v3-north-star.md   ← Full vision (LangGraph, Docker, formal orchestration)
│   └── PRD-v4-mvp.md          ← MVP spec — what this version implements
└── .projectpal/               ← Local state (managed by the Pal, per project)
    ├── state.yml              ← Current session state
    └── parking-lot.md         ← Items captured out of phase
```

Generated artifacts (PRDs, specs, tickets) are saved to `.projectpal/artifacts/` within the current project directory — not here.

## Milestones

| # | Deliverable | Status |
|---|------------|--------|
| M0 | CLAUDE.md + MemPalace connected | ✅ |
| M1 | Cynefin classification works | ✅ |
| M2 | Simple path | ✅ |
| M3 | Complicated path: PRD + debate | ✅ |
| M4 | Tech spec + tickets | ✅ |
| M5 | Parking Lot + session resumption | ✅ |
| M6 | MemPalace onboarding — graceful detection, install guidance, local-only fallback | ✅ |
| M7 | Full sub-agent pipeline — all 6 agents wired (Cynefin, PRD, Critic, Judge, Spec, Tickets) | ✅ |
| **The Test** | **The website gets rewritten** | **pending** |

## The North Star

This MVP (v0.1) is a subset of [PRD v3](docs/PRD-v3-north-star.md), which describes the full vision with LangGraph orchestration, formal state machines, and Cynefin auto-routing. We build that when the core loop is validated.
