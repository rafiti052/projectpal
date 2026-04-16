---
project: projectpal
type: ticket
status: ready
created: 2026-04-15
title: Remove MemPalace as a product dependency
---

## Goal

Make ProjectPal fully operable with **only** the local bridge (`.projectpal/state.yml`, parking lot, artifacts). Remove MemPalace from required flows, prompts, MCP wiring, and documentation so nothing assumes diary/search/drawer APIs exist.

## Scope

- **Runtime text**: strip or gate every `mempalace_*` tool reference in `src/shared/core.md`, `instructions/phase-protocols.md`, `instructions/sub-agent-invocation.md`, persona prompts under `prompts/`, and `templates/cursor-rules-projectpal.md` so the default path never mentions MemPalace as mandatory.
- **Instructions**: fold any still-useful continuity guidance from `instructions/mempalace-onboarding.md` and `instructions/mempalace-integration.md` into `session-resumption-schema.md` + `README.md`, then delete or archive the MemPalace-only docs.
- **Install / tests**: remove MemPalace-oriented env flags and assertions from `scripts/onboarding-flow.sh`, `scripts/test-integration.sh`, and `install-projectpal.sh` if they only exist for MemPalace.
- **Repo config**: drop MemPalace MCP server entries from `.mcp.json` (or document them as optional third-party add-ons outside this repo).
- **North star / changelog**: align product narrative with local-first continuity only.

## Acceptance

- Grep for `MemPalace` / `mempalace` across the shipped tree returns **no** user-facing requirement text (optional historical mention in `CHANGELOG.md` is fine).
- Session resumption instructions describe a single path: git root → `.projectpal/state.yml` → resume summary, with no tool calls required.
- CI / contributor scripts still pass after removals.

## Risks

- Users who already rely on MemPalace need a short migration note in `README.md` (export or one-time copy) before deleting onboarding docs.
