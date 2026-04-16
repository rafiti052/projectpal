---
project: multi-platform-install-source-of-truth
phase: 6
type: audit
status: complete
ticket: 1
created: 2026-04-16T18:28:34-03:00
---

# Multi-platform install source of truth audit

This audit inventories the current install and bootstrap scaffold before the repo is reshaped around `src/` as the canonical source tree and `platforms/claude|cursor|codex` as host adapters.

## Disposition key

- `keep` means the surface stays in place as-is for now.
- `keep-with-wrapper` means the surface remains, but only as a thin adapter around generated or platform-native content.
- `migrate` means the surface should move into the new source/build layout.
- `remove` means the surface should stop being part of the shipped install/bootstrap surface.

## Current install paths and generated outputs

| Current surface | Kind | Disposition | Replacement target | Notes |
| --- | --- | --- | --- | --- |
| `sh ./install-projectpal.sh` | top-level install entrypoint | `keep-with-wrapper` | `scripts/install-local.sh` plus `build/<host>/` | The single user-facing installer still makes sense, but the host-specific work should eventually be delegated to host-native build outputs. |
| `scripts/generate.sh` | generation wrapper | `keep-with-wrapper` | `src/`, `platforms/<host>/`, `build/<host>/` | Already acts as a bridge from neutral source to generated runtime surfaces. |
| `scripts/install-claude.sh` | Claude installer | `keep-with-wrapper` | `platforms/claude/` and `build/claude/` | Installs the Claude runtime surface into `~/.claude/skills/projectpal/SKILL.md` today. |
| `scripts/install-codex.sh` | Codex installer | `keep-with-wrapper` | `platforms/codex/` and `build/codex/` | Installs the Codex runtime surface into `~/.codex/skills/projectpal/SKILL.md` today. |
| `scripts/install-cursor.sh` | Cursor installer | `keep-with-wrapper` | `platforms/cursor/` and `build/cursor/` | Writes Cursor registration into `~/.cursor/mcp.json` today. |
| `CLAUDE.md` | generated runtime output | `keep-with-wrapper` | `src/shared/core.md` plus `src/adapters/claude.md` | Generated Claude surface; should stay derived, not hand-maintained. |
| `AGENTS.md` | generated runtime output | `keep-with-wrapper` | `src/shared/core.md` | Generated Codex-compatible mirror of the shared runtime body. |
| `skills/projectpal/SKILL.md` | generated runtime output | `keep-with-wrapper` | `src/shared/core.md`, `src/adapters/codex.md`, `src/adapters/codex-skill-header.md` | Generated Codex skill body and wrapper content. |
| `.cursor/rules/projectpal.md` | generated runtime output | `keep-with-wrapper` | `templates/cursor-rules-projectpal.md` and later `platforms/cursor/` | Repo-local Cursor rules are still a generated install-time artifact. |
| `.codex-plugin/plugin.json` | packaging metadata | `keep-with-wrapper` | `platforms/codex/` and `build/codex/` | Current Codex plugin manifest is a live distribution wrapper, not shared source. |
| `~/.claude/skills/projectpal/SKILL.md` | installed Claude destination | `keep-with-wrapper` | `build/claude/` | This is the shipped destination for the Claude surface today. |
| `~/.codex/skills/projectpal/SKILL.md` | installed Codex destination | `keep-with-wrapper` | `build/codex/` | This is the shipped destination for the Codex skill today. |
| `~/.cursor/mcp.json` | installed Cursor destination | `keep-with-wrapper` | `build/cursor/` | This is the shipped destination for Cursor registration today. |
| `.projectpal/state.yml` | local bridge state | `keep` | `.projectpal/state.yml` | This is not part of the install surface; it is the repo-local continuity store. |

## Host-specific bootstrap leftovers

| Current surface | Kind | Disposition | Replacement target | Notes |
| --- | --- | --- | --- | --- |
| `bin/pp-compress` | Claude hook helper | `migrate` | `platforms/claude/hooks/pp-compress` | Host-specific hook logic should live with the Claude adapter, not as a loose root-level script. |
| `.claude/settings.local.json` | Claude hook config reference | `remove` | `~/.claude/settings.json` or future installer-managed Claude config | The file is referenced by `bin/pp-compress`, but it is not present in the repo and should not be treated as a tracked install artifact. |
| `cursor-mcp/` | Cursor launcher scaffold | `migrate` | `platforms/cursor/` and `build/cursor/` | This directory is a transitional Cursor package skeleton; it should become the explicit Cursor adapter/build surface. |
| `.agents/plugins/marketplace.json` | optional Codex marketplace bootstrap | `keep-with-wrapper` | `platforms/codex/` and `build/codex/` | Local marketplace wiring can stay as a wrapper for now, but it is not canonical source. |
| `.claude-plugin/` | transitional plugin scaffold | `remove` | none | Empty wrapper directory; no shipped payload found. |
| `.cursor-plugin/` | transitional plugin scaffold | `remove` | none | Empty wrapper directory; no shipped payload found. |
| `scripts/onboarding-flow.sh` | bootstrap/session orchestration | `keep-with-wrapper` | `instructions/*` plus later install-local helpers | This is still useful as orchestration, but it is not the final host packaging surface. |
| `scripts/setup-dev.sh` | contributor bootstrap | `keep` | `CONTRIBUTING.md` | Optional developer bootstrap remains useful and is already documented as such. |

## Docs and reference surfaces that still point at the legacy install shape

| Current surface | Kind | Disposition | Replacement target | Notes |
| --- | --- | --- | --- | --- |
| `README.md` | install documentation | `keep-with-wrapper` | future `build/<host>/` docs and install refs | The README still documents the current top-level installer and generated surfaces. |
| `CONTRIBUTING.md` | maintainer documentation | `keep-with-wrapper` | future `build/<host>/` docs and maintainer scripts | This guide still teaches the current generation and install flow. |
| `CHANGELOG.md` | release record | `keep` | none | Release history stays as-is; later entries can describe the new build layout. |
| `docs/north-star.md` | product vision | `keep` | none | Long-range direction note; not part of the install surface. |
| `docs/audits/2026-04-15-release-readiness.md` | historical audit | `keep` | none | Existing audit record for the prior release gate. |
| `src/generation/contract.md` | source contract | `keep` | none | This already describes the source-first generation model. |
| `src/generation/mapping.md` | source mapping | `keep-with-wrapper` | `src/`, `platforms/<host>/`, `build/<host>/` | Useful as the current-state bridge until the new layout lands. |
| `scripts/test-integration.sh` | verification wrapper | `keep-with-wrapper` | `tests/smoke/` and later `scripts/validate-platform.sh` | This script still validates generated surfaces and install paths against the current shape. |
| `scripts/check-install.ts` | verification wrapper | `keep-with-wrapper` | `tests/smoke/` and later `scripts/validate-platform.sh` | Install parity checks are still useful, but they should point at the generated build targets. |

## Audit conclusion

The current repo still mixes three different layers:

- canonical shared source under `src/`
- generated runtime wrappers for Claude, Codex, and Cursor
- host-specific bootstrap leftovers that should be moved into platform adapters or removed

For the redesign, the cleanest split is:

1. keep the top-level installer and generation scripts as wrappers for now
2. migrate host-specific glue into `platforms/claude`, `platforms/cursor`, and `platforms/codex`
3. retire empty transitional plugin scaffolds and other install leftovers that do not belong in the new source tree
4. re-point docs and verification at the generated `build/<host>/` artifacts once those exist

This inventory covers the current install paths, generated outputs, and bootstrap leftovers that need a keep/migrate/remove decision before later waves can safely reshape the repo.
