# Changelog

All notable changes to ProjectPal are documented here.

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
- **Codex sync script** — added `sync-codex-plugin.sh` to refresh the Codex skill entrypoint from `CLAUDE.md` while preserving the Claude Code `sync-skill.sh` flow.

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
- `sync-skill.sh` — deploys Pal as a Claude Code slash command (`/projectpal`)
- Persona label system: Low hanging fruit / Needs a plan / Uncharted territory / On fire / Can't read it yet
