# ProjectPal `v0.2.4`

A patient AI companion that turns chaotic ideas into shipped projects.

## What is this?

ProjectPal helps you go from messy idea to actionable tickets without requiring you to have your thoughts organized first.

It works through conversation, not forms. It remembers context between sessions. It captures out-of-phase ideas instead of losing them. And it uses a multi-agent debate system to stress-test plans before you commit.

## How it works

1. **Talk to the Pal** — describe your idea however it comes out
2. **Cynefin classification** — the Pal identifies the nature of the problem
3. **PRD generation + debate** — a Critic agent and Judge agent pressure-test the plan
4. **You decide** — approve, revise, or archive at every checkpoint
5. **Tech spec → tickets** — broken into 15-minute focus sessions
6. **Implementation → review** — tickets stay available while the Pal implements, verifies, and reviews progress
7. **MemPalace** — everything is remembered for next time

## Canonical Instructions

`src/` is the neutral ProjectPal source in this repo.

The launcher-specific files for Claude Code and Codex CLI are generated runtime surfaces. `CLAUDE.md` and `AGENTS.md` are outputs, not the authoring center.

## Setup

```bash
git clone git@github.com:rafiti052/projectpal.git
cd projectpal
```

## Install

Use the single installer entrypoint and choose your assistant when prompted.

```bash
sh ./install-projectpal.sh
```

Supported assistants right now:
- Codex
- Claude Code

The installer always refreshes the generated runtime surfaces from `src/` first, then installs the assistant-specific integration you choose.

### Codex

Codex is the primary path for new GitHub users.

1. Run the installer and choose `codex`.
2. Open Codex in the new project repo or an existing repo.
3. Type:

```text
ProjectPal
```

That is the canonical Codex entrypoint.

Codex reads the plugin manifest from `.codex-plugin/plugin.json`, which points at `skills/projectpal/SKILL.md` and the repo-local `.mcp.json`.

ProjectPal does **not** claim that `/projectpal` is a native Codex slash command.

### Claude Code

```bash
sh ./install-projectpal.sh claude
```

Then open Claude Code and run `/projectpal`.

### Refresh Generated Surfaces

If you are changing the neutral source or runtime wrappers directly:

```bash
sh ./sync-codex-plugin.sh
```

That regenerates:
- `CLAUDE.md`
- `AGENTS.md`
- `skills/projectpal/SKILL.md`

### MemPalace (long-term memory)

The Pal detects MemPalace automatically on first run. If it's not connected, it will explain what it is and offer to install and register it for you — no manual setup required.

If you prefer to set it up manually, install the package first:
```bash
pip install mempalace
```

Then register it with the assistant runtime you are using. For Claude Code:

```bash
claude mcp add mempalace --command "python3 -m mempalace.mcp_server"
# Restart Claude Code to activate
```

For Codex, use the equivalent Codex MCP registration flow for your local environment.

### Dependencies

- [Claude Code](https://claude.ai/code) (CLI or desktop)
- [Codex CLI](https://developers.openai.com/codex/overview)
- [MemPalace](https://github.com/rafiti052/mempalace) — optional but recommended for cross-session memory

## Project Structure

```
projectpal/
├── src/                       ← Neutral ProjectPal source for generated runtime surfaces
├── install-projectpal.sh      ← Single install entrypoint that prompts for Claude or Codex
├── CLAUDE.md                  ← Generated Claude runtime surface (local install output, not versioned)
├── AGENTS.md                  ← Generated agents-compatible runtime surface (local install output, not versioned)
├── sync-claude-skill.sh       ← Install generated Claude runtime surface into Claude Code
├── sync-codex-plugin.sh       ← Generate Claude and Codex runtime surfaces from src/
├── .codex-plugin/
│   └── plugin.json            ← Codex plugin manifest
├── .agents/plugins/
│   └── marketplace.json       ← Optional local Codex marketplace entry
├── skills/projectpal/
│   └── SKILL.md               ← Generated Codex skill entrypoint (local install output, not versioned)
├── .mcp.json                  ← MemPalace MCP connection
├── prompts/
│   ├── critic-agent.md        ← Critic sub-agent persona
│   ├── judge-agent.md         ← Judge sub-agent persona
│   ├── cynefin-classify.md    ← Domain classification prompt
│   ├── prd-generate.md        ← PRD generation prompt
│   ├── tech-spec-generate.md  ← Tech spec generation prompt
│   └── tickets-generate.md    ← Ticket generation prompt
├── docs/
│   ├── maintainer-codex-reinstall.md ← Maintainer-only clean reinstall guide
│   └── north-star.md          ← Current product direction note
└── .projectpal/               ← Local bridge state (managed by the Pal, per project)
    ├── state.yml              ← Repo-local bridge state for startup/resume
    └── parking-lot.md         ← Repo-scoped parked items with feat/phase tags
```

Generated artifacts (PRDs, specs, tickets) are saved to `.projectpal/artifacts/` within the current project directory — not here.

Repo continuity lives in MemPalace under `Projects/<repo-slug>`. Shared knowledge remains in broader MemPalace wings such as `Principles`, `Decisions`, and `Precedents`.

Repo detection resolves the git repo root first and uses that directory name as `repo_slug`. If git detection fails, ProjectPal falls back to the current directory name, treats it as low-confidence startup context, and creates a fresh local bridge instead of reusing stale cross-repo state. Multiple worktrees of the same repo share repo-scoped memory while keeping separate `.projectpal/state.yml` bridge files.

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

The current direction note lives in [docs/north-star.md](docs/north-star.md).
