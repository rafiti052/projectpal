# Changelog

All notable changes to ProjectPal are documented here.

---

## [Unreleased]

---

## [0.3.1] — 2026-04-14

### Changed
- MemPalace onboarding now explains local-only continuity in repo-first terms, including that `.projectpal/state.yml` still lets the same repo pick back up later.
- Onboarding bridge summaries now save calm repo handoff context instead of setup jargon such as memory mode or assistant metadata.
- User-facing stage descriptions now keep the friendly visible names aligned with the quieter voice system, using softer descriptions like scoped draft, build plan, and build steps.
- Generated runtime surfaces were refreshed from `src/shared/layer0.md` after the user-facing naming cleanup.
- README version bumped to `v0.3.1`.
- Codex plugin manifest version bumped to `0.3.1`.

### Fixed
- Local-only onboarding no longer implies that same-repo continuity is lost when MemPalace is unavailable.
- MemPalace intro copy now uses calmer, more grounded language instead of the older setup-heavy phrasing.
- Runtime and flow shell tests now assert the updated continuity and stage-copy wording so stale expectations are caught by default.

---

## [0.3.0] — 2026-04-13

### Changed
- ProjectPal now uses the quieter visible route `Discovery → Scope Framing → Refinement → Solution → Spec → Implementation → Wrap Up`, while keeping spec drafting and ticket setup silent in the background.
- Clear-path work now keeps the PRD, skips specialist debate and visible spec review, and goes straight from `Solution` to the `Implementation` checkpoint.
- Workflow-mode messages now use the `👷 ProjectPal` shell, with `Current / Next / Later` reserved for orientation and artifact reviews using the compact summary pattern.
- Local state remains the primary continuity layer, while wrap-up artifacts now consistently record approved and completed status across the PRD, UI companion, ticket bundle, and ticket set.
- MemPalace setup guidance is now assistant-aware across the live onboarding instructions, README, and reviewed copy surfaces.
- README version bumped to `v0.3.0`.
- Codex plugin manifest version bumped to `0.3.0`.

### Fixed
- Reviewed copy artifacts no longer expose silent internal stages such as `Spec Drafting` and `Implementation Setup` in the proposed visible roadmap.
- The implementation wrap-up records now agree on completion state, including the ticket bundle, ticket bodies, and parked follow-up status for the deferred wording pass.

## [0.2.4] — 2026-04-13

### Added
- `install-projectpal.sh` as the single installer entrypoint that prompts for Codex or Claude and refreshes generated runtime surfaces before install.
- `docs/maintainer-codex-reinstall.md` for the maintainer-only clean Codex reinstall test.
- `scripts/projectpal-runtime-tests.sh` for repeatable generation and install-freshness verification across Codex and Claude runtime outputs.

### Changed
- ProjectPal now uses `src/projectpal/` as the neutral source of truth for generated runtime surfaces.
- `sync-codex-plugin.sh` now regenerates `CLAUDE.md`, `AGENTS.md`, and `skills/projectpal/SKILL.md` from the neutral source.
- `sync-skill.sh` has been renamed to `sync-claude-skill.sh` so the Claude-specific install path is explicit.
- README now documents one installer entrypoint with Codex as the primary activation path and `ProjectPal` as the canonical Codex launch command.
- Release notes for neutral-source changes should explicitly call out regenerated `CLAUDE.md`, `AGENTS.md`, and `skills/projectpal/SKILL.md` so Claude and Codex runtime surfaces stay visible in the changelog.
- README version bumped to `v0.2.4`.
- Codex plugin manifest version bumped to `0.2.4`.

### Fixed
- Local onboarding verification now defaults to Codex when runtime detection is ambiguous, so the helper flow matches the primary installation path.
- Runtime install verification now uses an isolated temporary `HOME` for the Claude branch, avoiding sandbox-specific false positives while still checking the generated install output.
- Stale Gemini install/runtime hooks were removed from the root install surface and assistant probe output.

## [0.2.3] — 2026-04-10

### Added
- Repo-local Phase 7 helper scripts for artifact budget checks, phase handoff packaging, resume bridge sync, reduction reporting, and comparison artifact generation under `scripts/`.
- Focused shell verification for the new flow via `scripts/projectpal-flow-tests.sh`.
- Saved Phase 2 comparison helpers for baseline-vs-narrowed handoff inspection.

### Changed
- README now documents the local measurement and markdown budget helper entrypoints.
- README version bumped to `v0.2.3`.
- Codex plugin manifest version bumped to `0.2.3`.

### Fixed
- `build-phase-input` no longer fails on bullet-line rendering in `scripts/projectpal-flow.sh`.
- Repo-scoped memory summary ranking now prefers matching `feat:` rows ahead of same-phase rows from other features.
- Phase 2 measurement review now distinguishes wrapper-only counts from comparable transported debate surfaces.

---

## [0.2.2] — 2026-04-10

### Changed
- ProjectPal instructions now treat repo-scoped MemPalace continuity as the source of truth for resume behavior, with `.projectpal/state.yml` reduced to a project-local bridge.
- Parking Lot guidance now uses repo/feat/phase scoping instead of phase-only capture.
- Global memory routing now distinguishes repo continuity in `Projects/<repo-slug>` from shared knowledge in broader wings such as `Principles`, `Decisions`, and `Precedents`.
- README version bumped to `v0.2.2`.
- Codex plugin manifest version bumped to `0.2.2`.

### Fixed
- Startup precedence now explicitly resolves repo context before local bridge fallback, addressing the wrong-project continuation bug in the instruction/runtime layer.

---

## [0.2.1] — 2026-04-10

### Fixed
- Phase 6 now generates tickets only; ProjectPal no longer routes directly to wrap-up or artifact cleanup before implementation.
- Added Phase 7 implementation and Phase 8 review/wrap-up so tickets remain available while work is implemented, verified, reviewed, optionally prepared for PR flow, saved to MemPalace, and only then cleaned up.

### Changed
- README version bumped to `v0.2.1`.
- Codex plugin manifest version bumped to `0.2.1`.

---

## [0.2.0] — 2026-04-10

### Added
- **Codex plugin support** — added `.codex-plugin/plugin.json`, generated `skills/projectpal/SKILL.md`, and an optional local Codex marketplace entry.
- **Codex sync script** — added `sync-codex-plugin.sh` to refresh the Codex skill entrypoint from `CLAUDE.md` while preserving the Claude Code `sync-claude-skill.sh` flow.

### Changed
- README now documents both Claude Code and Codex plugin setup paths.

---

## [0.1.1] — 2026-04-10

### Added
- **MemPalace onboarding flow** — when MemPalace isn't connected, the Pal now detects it, explains what it is, and offers to install/register it or continue in local-only mode. No more silent degradation.
  - Detection via attempt-based diary read (try → fail → explain)
  - Two-case branching: never installed vs. installed but not connected this session
  - Install path: `claude mcp add` first, settings path discovery fallback, manual walkthrough last resort
  - Post-install guard: diary/drawer calls disabled until restart
  - Local-only mode: full session with `state.yml` only, all MemPalace calls silently skipped
- **Full sub-agent pipeline** — all six generation steps are now proper isolated sub-agent invocations (matching the Critic/Judge pattern):
  - Cynefin Classifier (`prompts/cynefin-classify.md`) — invoked at Phase 0 completion
  - PRD Generator (`prompts/prd-generate.md`) — invoked at Phase 1
  - Tech Spec Generator (`prompts/tech-spec-generate.md`) — invoked at Phase 4
  - Ticket Generator (`prompts/tickets-generate.md`) — invoked at Phase 6
- **MemPalace availability gating** — all diary and drawer calls are gated on `mempalace_available` flag (session-scoped, never persisted)

### Changed
- Session Resumption restructured — diary read now doubles as the availability detection call (no duplicate calls)
- README updated: setup instructions reflect onboarding flow; MemPalace listed as optional but guided
- `docs/PRD-v4-mvp.md` status updated to "Approved — Shipped as v0.1"; Task tool references corrected to Agent tool; artifacts directory path corrected

### Fixed
- Silent MemPalace failures no longer leave the user with a blank session and no explanation
- `mempalace_available` flag is session-scoped only — eliminated stale-state bug where a prior local-only session could block MemPalace on the next run

---

## [0.1.0] — 2026-04-09

### Added
- Initial MVP: CLAUDE.md-driven Pal with full phase pipeline (Phases 0–6)
- Cynefin classification with user confirmation
- Multi-agent debate system: Critic + Judge sub-agents
- Parking Lot — silent capture of out-of-phase ideas
- Session resumption via MemPalace diary + local `state.yml`
- Phase 6 decision routing (A|B|C) and project wrap-up
- `sync-claude-skill.sh` — deploys Pal as a Claude Code slash command (`/projectpal`)
- Persona label system: Low hanging fruit / Needs a plan / Uncharted territory / On fire / Can't read it yet
