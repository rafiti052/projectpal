# Changelog

All notable changes to ProjectPal are documented here.

The format is loosely [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Dates are ISO-8601 (`YYYY-MM-DD`).

---

## [Unreleased]

### Changed

- Pal-facing AHA guidance (`src/shared/core.md`, `instructions/phase-protocols.md`, Tech Lead / Scrum Master prompts) no longer uses connector-specific filenames as the default carve-out example; Brief-mandated infrastructure stays explicit without front-loading connector product language in Discovery.
- Wrap Up no longer includes a Decision Routing phase; Phase 8 now closes after wrap-up summary and artifact cleanup.

---

## [0.4.0] — 2026-04-15

Lean “ships-a-surface” release: installable ProjectPal surfaces for Claude Code, Codex, and Cursor, with generated runtime packaging, parity checks, and release-ready verification wiring. Connector runtime work is deferred to the next version.

### Added

- Lean v0.4 scope posture: connector runtime work (routing/connector execution) is deferred to the next version and not part of the shipped install surface.
- `scripts/check-install.ts` — install parity checker across adapters; fixture mode for CI and release gates.
- `tests/fixtures/` — fixture state for deterministic install parity checks.
- Cursor MCP integration installed via `scripts/install-cursor.sh` (global `~/.cursor/mcp.json` + Cursor repo rule template).
- `templates/cursor-rules-projectpal.md` — Cursor rules template, copied to repos on prep.
- `CONTRIBUTING.md` — contributor guide with multi-option Node install (nvm, fnm, volta, system package).
- `scripts/setup-dev.sh` — opinionated nvm shortcut for contributors on Linux, WSL, and macOS (verified on Amazon Linux 2023).
- `.nvmrc` — pins Node 20 LTS; auto-detected by nvm, fnm, and volta.
- Sub-agent artifact staging — `instructions/sub-agent-invocation.md` and `instructions/artifacts.md` document `.projectpal/staging/`, `artifact_draft_path`, and Pal promotion into `.projectpal/artifacts/`.
- `docs/audits/2026-04-15-release-readiness.md` — release readiness audit (flow handoff + full test gate) with an accountable closure table.
- **Phase protocol hardening** — `instructions/phase-protocols.md` defines non-optional Check-ins (including Implementation entry / green light) and ties them to Clear path vs full route behavior.

### Changed

- `package.json` `check:install` invokes `tsx scripts/check-install.ts` without hardcoding `--fixture`; use `pnpm check:install --fixture` for the deterministic release gate.
- `CONTRIBUTING.md` and `scripts/setup-dev.sh` document live versus fixture behavior for install parity.
- `scripts/onboarding-flow.sh` `prepare-repo` creates `.projectpal/staging` and `artifacts/designer-review` with the rest of the documented artifact layout.
- `docs/north-star.md` keeps connector product wiring as long-range backlog (§14), not a near-term ship commitment.
- Connector execution remains deferred to the next version; v0.4 ships only installable assistant surfaces.
- `.gitignore` still ignores most of `.projectpal/`; selectively tracks `artifacts/brief/` and `artifacts/tickets/` for committed Pal artifacts while leaving other artifact subtrees and staging local-only.
- `src/shared/core.md` Check-in UX rule references phase-protocol obligations; regenerated `CLAUDE.md`, `AGENTS.md`, and `skills/projectpal/SKILL.md` via `scripts/generate.sh`.
- **README** — structure and release pointers updated for v0.4.0.
- **Codex plugin manifest** — version `0.4.0`.

### Fixed

- Install parity CLI no longer doubled the `--fixture` flag when both the script and the user supplied it.
- Integration tests and generated assistant surfaces stay aligned on the `ProjectPal neutral source under src/` marker in runtime output prefixes.

---

## [0.3.6] — 2026-04-14

### Changed

- Active prompt names, artifact contracts, and maintainer docs now use `Brief`, `Refinement`, `Planning`, `Technical Details`, `Architect`, and `Manager` consistently across the live repo.
- Internal artifact directories and frontmatter types now use `brief`, `technical-details`, and `refinement` instead of the older legacy ids.
- `docs/projectpal-ui-labels.en.json` now records canonical labels directly instead of keeping the old reviewer and artifact terms as reference keys.
- README version bumped to `v0.3.6`.
- Codex plugin manifest version bumped to `0.3.6`.

### Fixed

- Repo-wide copy verification now runs through `scripts/projectpal-copy-audit.sh` so stale prompt names and old stage labels fail the runtime checks by default.
- Install and sync verification now catches old wording in generated files, installed skills, and package metadata before release.

---

## [0.3.5] — 2026-04-14

### Changed

- User-facing workflow guidance now consistently uses the visible stage names `Brief`, `Refinement`, `Planning`, and `Technical Details` wherever the runtime or maintainer instructions talk about the flow.
- Artifact and sub-agent instructions now keep backstage artifact and reviewer labels out of user-facing copy unless the user explicitly asks for them.
- README version bumped to `v0.3.5`.
- Codex plugin manifest version bumped to `0.3.5`.

### Fixed

- Artifact review guidance now maps the internal brief and technical-details files to the user-facing `Brief` and `Technical Details` check-ins consistently.
- Planning and memory-loading instructions no longer mix legacy internal labels into user-facing phase descriptions.
- Runtime verification now checks the generated surfaces and installed Claude/Codex skills so label changes ship through `sync-codex-plugin.sh` and `install-projectpal.sh`.

---

## [0.3.1] — 2026-04-14

### Changed

- Onboarding bridge summaries now save calm repo handoff context instead of setup jargon such as memory mode or assistant metadata.
- User-facing stage descriptions now keep the friendly visible names aligned with the quieter voice system, using softer descriptions like scoped draft, build plan, and build steps.
- Generated runtime surfaces were refreshed from `src/shared/core.md` after the user-facing naming cleanup.
- README version bumped to `v0.3.1`.
- Codex plugin manifest version bumped to `0.3.1`.

### Fixed

- Runtime and flow shell tests now assert the updated continuity and stage-copy wording so stale expectations are caught by default.

---

## [0.3.0] — 2026-04-13

### Changed

- ProjectPal now uses the quieter visible route `Discovery → Brief → Refinement → Solution → Planning → Technical Details → Tickets → Implementation → Wrap Up`, while keeping technical drafting and ticket setup silent in the background.
- Clear-path work now keeps the Brief, skips the extra refinement and technical-details review, and goes straight from `Solution` to the `Implementation` check-in.
- Workflow-mode messages now use the `👷 ProjectPal` shell, with `Current / Next / Later` reserved for orientation and artifact reviews using the compact summary pattern.
- Local state remains the primary continuity layer, while wrap-up artifacts now consistently record approved and completed status across the Brief, UI companion, ticket bundle, and ticket set.
- README version bumped to `v0.3.0`.
- Codex plugin manifest version bumped to `0.3.0`.

### Fixed

- Reviewed copy artifacts no longer expose silent internal stages such as technical drafting and implementation setup in the proposed visible roadmap.
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
- Phase 2 measurement review now distinguishes wrapper-only counts from comparable transported refinement surfaces.

---

## [0.2.2] — 2026-04-10

### Changed

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
- Added Phase 7 implementation and Phase 8 review/wrap-up so tickets remain available while work is implemented, verified, reviewed, optionally prepared for PR flow, and only then cleaned up.

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

- **Full sub-agent pipeline** — all six generation steps are now proper isolated sub-agent invocations (matching the Architect/Manager review pattern):
  - Cynefin Classifier (`prompts/cynefin-classify.md`) — invoked at Phase 0 completion
  - Brief Generator (`prompts/brief-generate.md`) — invoked at Phase 1
  - Technical Details Generator (`prompts/technical-details-generate.md`) — invoked at Phase 4
  - Ticket Generator (`prompts/tickets-generate.md`) — invoked at Phase 6

### Changed

- Session Resumption restructured — diary read now doubles as the availability detection call (no duplicate calls)
- `docs/v4-mvp.md` status updated to "Approved — Shipped as v0.1"; Task tool references corrected to Agent tool; artifacts directory path corrected

### Fixed

- Availability gating is session-scoped only — eliminated stale-state bug where a prior local-only session could block optional integrations on the next run

---

## [0.1.0] — 2026-04-09

### Added

- Initial MVP: CLAUDE.md-driven Pal with full phase pipeline (Phases 0–6)
- Cynefin classification with user confirmation
- Multi-agent refinement system: Architect + Manager sub-agents
- Parking Lot — silent capture of out-of-phase ideas
- Phase 6 decision routing (A|B|C) and project wrap-up
- `sync-claude-skill.sh` — deploys Pal as a Claude Code slash command (`/projectpal`)
- Persona label system: Low hanging fruit / Needs a plan / Uncharted territory / On fire / Can't read it yet
