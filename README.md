# ProjectPal `v0.2.3`

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

`CLAUDE.md` is the current canonical ProjectPal source artifact in this repo.

The launcher-specific files for Claude Code, Codex CLI, and Gemini CLI are adapters generated or synced from that source. `AGENTS.md` stays as a repo-local mirror for toolchains that expect the standard agents filename.

## Setup

```bash
git clone git@github.com:rafiti052/projectpal.git
cd projectpal
```

### Claude Code

```bash
./sync-skill.sh
claude
```

Launcher: `/projectpal`

`./sync-skill.sh` installs the ProjectPal skill into `~/.claude/skills/projectpal/SKILL.md` and refreshes the repo-local `AGENTS.md` mirror.

### Codex CLI

```bash
./sync-codex-plugin.sh
```

Launchers:

- `projectpal` skill
- `Start ProjectPal`
- `Use the ProjectPal plugin`

Codex reads the plugin manifest from `.codex-plugin/plugin.json`, which points at `skills/projectpal/SKILL.md` and the repo-local `.mcp.json`.

ProjectPal does **not** claim that `/projectpal` is a native Codex slash command. OpenAI’s Codex docs currently position reusable workflows around skills, and custom prompts are deprecated in favor of skills.

After updating the generator, refresh the generated skill file:

```bash
./sync-codex-plugin.sh
```

### Gemini CLI

```bash
./sync-gemini-commands.sh
```

Launcher: `/projectpal`

This syncs the repo-managed Gemini command wrapper to `.gemini/commands/projectpal.toml`. The command wrapper references the shared ProjectPal instructions from `CLAUDE.md` instead of forking the persona into a second handwritten file.

If your Gemini session is already open, reload commands before testing.

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
- [Codex CLI](https://developers.openai.com/codex/overview)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [MemPalace](https://github.com/rafiti052/mempalace) — optional but recommended for cross-session memory

## Project Structure

```
projectpal/
├── CLAUDE.md                  ← Pal persona + rules (loaded by Claude Code)
├── AGENTS.md                  ← Same as CLAUDE.md (standard agents filename)
├── sync-skill.sh              ← Deploy CLAUDE.md as a Claude Code skill
├── sync-codex-plugin.sh       ← Refresh skills/projectpal/SKILL.md for Codex
├── sync-gemini-commands.sh    ← Refresh .gemini/commands/projectpal.toml for Gemini
├── .codex-plugin/
│   └── plugin.json            ← Codex plugin manifest
├── .gemini/
│   └── commands/
│       └── projectpal.toml    ← Gemini custom command wrapper
├── .agents/plugins/
│   └── marketplace.json       ← Optional local Codex marketplace entry
├── skills/projectpal/
│   └── SKILL.md               ← Generated Codex skill entrypoint
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
│   ├── PRD-v4-mvp.md          ← MVP spec — what this version implements
│   └── repo-context-lifecycle.md ← Repo resume and multi-worktree decision note
└── .projectpal/               ← Local bridge state (managed by the Pal, per project)
    ├── state.yml              ← Repo-local bridge state for startup/resume
    └── parking-lot.md         ← Repo-scoped parked items with feat/phase tags
```

Generated artifacts (PRDs, specs, tickets) are saved to `.projectpal/artifacts/` within the current project directory — not here.

Review-time measurement artifacts also live there. For the current performance baseline work, the repeatable fixture entrypoint is `sh scripts/phase2-baseline-fixture.sh <run-id>`, which prepares `.projectpal/artifacts/review/<run-id>/` with the fixed PRD/prompt references and output placeholders.

For artifact budget checks, use `sh scripts/markdown-word-budget.sh <markdown-path> [budget-limit]`. It counts markdown body words only and ignores YAML frontmatter when the file starts with a frontmatter block.

Repo continuity lives in MemPalace under `Projects/<repo-slug>`. Shared knowledge remains in broader MemPalace wings such as `Principles`, `Decisions`, and `Precedents`.

Repo detection resolves the git repo root first and uses that directory name as `repo_slug`. If git detection fails, ProjectPal falls back to the current directory name, treats it as low-confidence startup context, and creates a fresh local bridge instead of reusing stale cross-repo state. Multiple worktrees of the same repo share repo-scoped memory while keeping separate `.projectpal/state.yml` bridge files.

The repo-scoped schema and write/search order live in [docs/repo-context-lifecycle.md](docs/repo-context-lifecycle.md). In short: repo anchors and feature scopes live under `Projects/<repo-slug>`, the local bridge stays in `.projectpal/state.yml`, and Parking Lot items are mirrored with `repo:`, `feat:`, `phase:`, and `kind:parking-lot` tags so phase-entry surfacing stays repo-local.

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
