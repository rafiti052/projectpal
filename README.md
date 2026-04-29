# ProjectPal

A patient AI companion that turns chaotic ideas into shipped projects.

## What is this?

ProjectPal helps you go from messy idea to actionable tickets without requiring you to have your thoughts organized first.

It works through conversation, not forms. It remembers context between sessions. It captures out-of-phase ideas instead of losing them. And it keeps more of the housekeeping quiet in the background so the user-facing flow stays calm.

## How it works

1. **Talk to the Pal** — describe your idea however it comes out
2. **Complexity Assessment** — the Pal names the safest route: Clear path, Needs a plan, Needs discovery, On fire, or Still unclear
3. **Brief → Solution** — the Pal turns the conversation into a first clear draft and brings it back for review
4. **Refinement → Planning → Technical Details when the route needs them** — Clear path skips these; heavier routes keep the extra pressure test and technical planning pass
5. **Tickets → Implementation** — the work is broken into tickets before the real green light to build
6. **Wrap Up** — changes are reviewed, state is saved locally first, and long-term memory sync stays in the background

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
- Cursor

The installer always refreshes the generated runtime surfaces from `src/` first, installs the assistant-specific integrations, and writes the assistant primary hint to `~/.projectpal/primary-assistant`.

Note: `build/` outputs are intentionally not committed. The installer will build the platform artifacts (Claude/Codex/Cursor) automatically on each install.

### Uninstall

To remove ProjectPal integrations from all supported assistants:

```bash
sh ./uninstall-projectpal.sh
```

### Codex

Codex is the primary path for new GitHub users.

1. Run the installer and choose `codex`.
2. Open Codex in the new project repo or an existing repo.
3. Type:

```text
ProjectPal
```

That is the canonical Codex entrypoint.

The generated Codex package lives in `build/codex/`, and its packaged manifest lives at `build/codex/.codex-plugin/plugin.json`.
The repo-local Codex wrapper manifest at `.codex-plugin/plugin.json` delegates to `build/codex/skills/projectpal/SKILL.md`.

ProjectPal does **not** claim that `/projectpal` is a native Codex slash command.

### Claude Code

Run the installer, choose `claude` when prompted, then open Claude Code and run `/projectpal`.

### Cursor

Run the installer, choose `cursor` when prompted, then open a prepared repo in Cursor.

ProjectPal's global Cursor registration is written to `~/.cursor/mcp.json`, and repo-local rules are copied into `.cursor/rules/projectpal.md` when the repo is prepared through the ProjectPal flow.

### Refresh Generated Surfaces

If you are changing the neutral source or runtime wrappers directly:

```bash
sh scripts/generate.sh
sh scripts/build-platform.sh codex
```

That regenerates:
- `CLAUDE.md`
- `AGENTS.md`
- `skills/projectpal/SKILL.md`
- `build/codex/AGENTS.md`
- `build/codex/skills/projectpal/SKILL.md`
- `build/codex/.codex-plugin/plugin.json`

### Maintainer checks (TypeScript tree)

From a clone with Node 20+ and pnpm:

```bash
pnpm install
pnpm test
pnpm typecheck
pnpm test:integration
pnpm check:install --fixture
```

For the packaged multi-platform contract, also run:

```bash
sh scripts/validate-platform.sh codex
sh tests/smoke/codex-build.sh
sh scripts/smoke-install.sh
```

### Dependencies

- [Claude Code](https://claude.ai/code) (CLI or desktop)
- [Codex CLI](https://developers.openai.com/codex/overview)

## Project Structure

```
projectpal/
├── src/                       ← Neutral ProjectPal source for generated runtime surfaces
├── platforms/                 ← Platform-owned adapter inputs (Claude, Codex, Cursor)
├── install-projectpal.sh      ← Single install entrypoint that prompts for Claude, Codex, or Cursor
├── CLAUDE.md                  ← Generated Claude runtime surface (local install output, not versioned)
├── AGENTS.md                  ← Generated agents-compatible runtime surface (local install output, not versioned)
├── scripts/                   ← Contributor tools (generate, install, test, audit)
├── templates/                 ← Install-time templates such as Cursor rules
├── .codex-plugin/
│   └── plugin.json            ← Repo-local Codex wrapper manifest pointing at build/codex
├── build/
│   ├── claude/                ← Generated Claude artifacts (installed into ~/.claude)
│   ├── codex/                 ← Generated Codex artifacts (installed into ~/.codex)
│   └── cursor/                ← Generated Cursor artifacts (installed/registered in ~/.cursor)
├── .agents/plugins/
│   └── marketplace.json       ← Optional local Codex marketplace entry
├── skills/projectpal/
│   └── SKILL.md               ← Legacy generated Codex skill mirror kept for compatibility
├── prompts/
│   ├── architect-agent.md            ← Internal Architect reviewer prompt
│   ├── manager-agent.md              ← Internal Manager reviewer prompt
│   ├── strategist-agent.md           ← Strategist Brief drafting prompt
│   ├── designer-agent.md             ← Designer wave-review prompt
│   ├── complexity-analyst.md         ← Complexity classification prompt
│   ├── tech-lead-agent.md            ← Technical Details drafting prompt
│   └── scrum-master-agent.md         ← Ticket generation prompt
├── docs/
│   └── north-star.md          ← Long-range product direction (delegation / CLI shape in §14)
├── instructions/              ← Phase protocols, artifacts, session schema, sub-agent contracts
└── .projectpal/               ← Local bridge state (managed by the Pal, per project)
    ├── state.yml              ← Repo-local bridge state for startup/resume
    ├── parking-lot.md         ← Repo-scoped parked items with feat/phase tags
    └── artifacts/             ← brief/ + tickets/ may be committed; other subtrees stay local
        ├── brief/
        └── tickets/
```

Generated work artifacts (briefs, technical details, tickets) default to `.projectpal/artifacts/` in the active repo. This repository also tracks example or batch artifacts under `artifacts/brief/` and `artifacts/tickets/` when they are part of the shipped Pal workflow.

Repo continuity lives locally in `.projectpal/state.yml`.

Repo detection resolves the git repo root first and uses that directory name as `repo_slug`. If git detection fails, ProjectPal falls back to the current directory name, treats it as low-confidence startup context, and creates a fresh local bridge. Multiple worktrees of the same repo keep separate `.projectpal/state.yml` bridge files.

## Milestones

| # | Deliverable | Status |
|---|------------|--------|
| M0 | CLAUDE.md + local state connected | ✅ |
| M1 | Complexity Assessment works | ✅ |
| M2 | Clear-path route keeps the Brief and stays light | ✅ |
| M3 | Needs-a-plan route: Brief + Refinement | ✅ |
| M4 | Technical Details + tickets | ✅ |
| M5 | Parking Lot + session resumption | ✅ |
| M6 | Session resumption — graceful detection and local state fallback | ✅ |
| M7 | Full sub-agent pipeline — seven internal roles wired (Strategist, Architect, Manager, Tech Lead, Scrum Master, Complexity Analyst, Designer) | ✅ |
| **The Test** | **The website gets rewritten** | **pending** |

## The North Star

The current direction note lives in [docs/north-star.md](docs/north-star.md).

## Release notes

Shipped versions are listed in [CHANGELOG.md](CHANGELOG.md). The packaged Codex manifest at `build/codex/.codex-plugin/plugin.json` carries the same semver as `package.json` for each release, and the repo-local `.codex-plugin/plugin.json` wrapper should continue to point at that generated build tree.
