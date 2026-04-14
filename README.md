# ProjectPal `v0.3.6`

A patient AI companion that turns chaotic ideas into shipped projects.

## What is this?

ProjectPal helps you go from messy idea to actionable tickets without requiring you to have your thoughts organized first.

It works through conversation, not forms. It remembers context between sessions. It captures out-of-phase ideas instead of losing them. And it keeps more of the housekeeping quiet in the background so the user-facing flow stays calm.

## How it works

1. **Talk to the Pal** — describe your idea however it comes out
2. **Complexity Assessment** — the Pal names the safest route: Clear path, Needs a plan, Needs discovery, On fire, or Still unclear
3. **Brief → Solution** — the Pal turns the conversation into a first clear draft and brings it back for review
4. **Refinement → Planning → Technical Details when needed** — bounded work stays light; heavier work gets the extra pressure test and technical planning pass
5. **Tickets → Implementation** — the work is broken into tickets before the real green light to build
6. **Wrap Up** — changes are reviewed, state is saved locally first, and long-term memory sync stays in the background

## Canonical Instructions

`src/` is the neutral ProjectPal source in this repo.

The launcher-specific files for Claude Code and Codex CLI are generated runtime surfaces. `CLAUDE.md` and `AGENTS.md` are outputs, not the authoring center.
`docs/projectpal-ui-labels.en.json` is the label reference. If wording needs to ship through install or sync, change the source in `src/` and regenerate instead of patching the generated outputs directly.

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

Then register it with the assistant runtime you are using:

For Codex:

```bash
codex mcp add mempalace -- python3 -m mempalace.mcp_server
```

For Claude Code:

```bash
claude mcp add mempalace --command "python3 -m mempalace.mcp_server"
```

Then restart your AI assistant and start ProjectPal again.

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
│   ├── architect-agent.md            ← Internal Architect reviewer prompt
│   ├── manager-agent.md              ← Internal Manager reviewer prompt
│   ├── brief-generate.md             ← Internal Brief drafting prompt
│   ├── technical-details-generate.md ← Internal Technical Details drafting prompt
│   ├── tickets-generate.md           ← Ticket generation prompt
│   └── cynefin-classify.md           ← Domain classification prompt
├── docs/
│   ├── maintainer-codex-reinstall.md ← Maintainer-only clean reinstall guide
│   └── north-star.md          ← Current product direction note
└── .projectpal/               ← Local bridge state (managed by the Pal, per project)
    ├── state.yml              ← Repo-local bridge state for startup/resume
    └── parking-lot.md         ← Repo-scoped parked items with feat/phase tags
```

Generated artifacts (briefs, technical details, tickets) are saved to `.projectpal/artifacts/` within the current project directory — not here.

Repo continuity lives locally first in `.projectpal/state.yml`, with MemPalace available as background continuity and long-term memory under `Projects/<repo-slug>`. Shared knowledge remains in broader MemPalace wings such as `Principles`, `Decisions`, and `Precedents`.

Repo detection resolves the git repo root first and uses that directory name as `repo_slug`. If git detection fails, ProjectPal falls back to the current directory name, treats it as low-confidence startup context, and creates a fresh local bridge instead of reusing stale cross-repo state. Multiple worktrees of the same repo share repo-scoped memory while keeping separate `.projectpal/state.yml` bridge files.

## Milestones

| # | Deliverable | Status |
|---|------------|--------|
| M0 | CLAUDE.md + MemPalace connected | ✅ |
| M1 | Complexity Assessment works | ✅ |
| M2 | Clear-path route keeps the Brief and stays light | ✅ |
| M3 | Needs-a-plan route: Brief + Refinement | ✅ |
| M4 | Technical Details + tickets | ✅ |
| M5 | Parking Lot + session resumption | ✅ |
| M6 | MemPalace onboarding — graceful detection, install guidance, local-only fallback | ✅ |
| M7 | Full sub-agent pipeline — all 6 internal roles wired, with shipped labels aligned to Problem Solver, Architect, Manager, and Tech Lead | ✅ |
| **The Test** | **The website gets rewritten** | **pending** |

## The North Star

The current direction note lives in [docs/north-star.md](docs/north-star.md).
