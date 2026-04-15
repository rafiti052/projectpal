# Parking Lot

Things mentioned out of order — captured here so nothing gets lost.
The Pal surfaces each item when its phase arrives.

<!-- Captured by the Pal. Items are tagged by repo, optional feat, target phase, and priority. -->
<!-- Format: - [feat:<feat-slug>|feat:none] [phase:<phase-tag>] [priority:P0|P1|P2] Item description (project: name; captured: date; status: open|incorporated|deferred) -->
<!-- Priority: P0 = active or immediate next · P1 = high value, near-term · P2 = future / lower urgency -->
<!-- Last cleaned: 2026-04-15 — removed incorporated and shipped items. -->

- [follow-up] [feat:agent-platform-expansion] [phase:prd] [priority:P1] Remaining orchestration work after v0.4.0: richer event/history records, cross-assistant handoff behavior, and helper visibility overlay refinement. Scaffolding, reconciliation machinery, and multi-adapter execution all shipped in v0.4.0. (project: projectpal; captured: 2026-04-14; updated: 2026-04-15; status: open)

- [active] [feat:flow-optimization-and-personas] [phase:discovery] [priority:P0] Four-item sequence for v0.4.x: (1) Strategist + debate pipeline — shipped in repo. (2) Designer persona + wave gate — shipped in repo. (3) **AHA principle in Planning/Technical Details** — next. (4) Flow optimization audit — after AHA. (project: projectpal; captured: 2026-04-15; updated: 2026-04-15; status: open)

- [follow-up] [feat:persona-debate-cycle] [phase:implementation] [priority:P0] Scrub "Cynefin" naming and land seven-persona debate cycle — shipped in repo (prompts, instructions, schemas, tests). (project: projectpal; captured: 2026-04-15; updated: 2026-04-15; status: incorporated)

- [follow-up] [feat:agent-platform-expansion] [phase:implementation] [priority:P1] Sub-agent handoff refactor: agents should write output directly to a staging path (`.projectpal/staging/<agent>-draft.md`) and signal done with a path pointer — Pal then validates and moves to the canonical artifact path. Eliminates the current round-trip where agents return full document text to the Pal context and Pal re-saves it. Touches all six sub-agent contracts in `instructions/sub-agent-invocation.md`. Tie to existing follow-up: "richer event/history records, cross-assistant handoff behavior" (captured 2026-04-14). (project: projectpal; captured: 2026-04-15; status: open)

- [follow-up] [feat:onboarding-helpers] [phase:prd] [priority:P2] Optional onboarding helpers: GitHub CLI and PR-template check during setup, plus a new-repo first-run prompt for deeper technical guidance saved to MemPalace. (project: projectpal; captured: 2026-04-10; status: open)

- [follow-up] [feat:connector-config-flow] [phase:tech-spec] [priority:P1] A config flow for connector decisions — structured flow to reduce friction around connector approval and routing setup. Design alongside the connector abstraction. (project: projectpal; captured: 2026-04-14; status: open)

- [follow-up] [feat:windows-native-install] [phase:prd] [priority:P1] Windows native install (non-WSL). WSL-only shipped in v0.4.0. Native Windows path deferred — user to circle back. (project: projectpal; captured: 2026-04-15; status: open)
