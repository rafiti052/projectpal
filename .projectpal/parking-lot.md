# Parking Lot

Things mentioned out of order — captured here so nothing gets lost.
The Pal surfaces each item when its phase arrives.

<!-- Captured by the Pal. Items are tagged by repo, optional feat, target phase, and priority. -->
<!-- Format: - [feat:<feat-slug>|feat:none] [phase:<phase-tag>] [priority:P0|P1|P2] Item description (project: name; captured: date; status: open|incorporated|deferred) -->
<!-- Priority: P0 = active or immediate next · P1 = high value, near-term · P2 = future / lower urgency -->
<!-- Last cleaned: 2026-04-15 (prioritized queue; removed agent-platform-expansion orchestration + windows-native-install; moved connector work to north-star §14) -->

- [done] [feat:engineer-agents] [phase:discovery] [priority:P0] Engineer agents for ticket implementation — sub-agents that execute individual tickets during Phase 7. (project: projectpal; captured: 2026-04-15; status: incorporated)
- [queued] [feat:agent-platform-expansion] [phase:implementation] [priority:P1] Sub-agent handoff refactor: agents should write output directly to a staging path (`.projectpal/staging/<agent>-draft.md`) and signal done with a path pointer — Pal then validates and moves to the canonical artifact path. Eliminates the current round-trip where agents return full document text to the Pal context and Pal re-saves it. Touches all six sub-agent contracts in `instructions/sub-agent-invocation.md`. (project: projectpal; captured: 2026-04-15; status: open)
- [queued] [feat:flow-optimization-and-personas] [phase:discovery] [priority:P1] Flow optimization audit — the last open item from the v0.4.x sequence. Include clearing connector work leftovers from the codebase and reviewing AHA principle coverage on that removed surface. (project: projectpal; captured: 2026-04-15; updated: 2026-04-15; status: open)
- [queued] [feat:testing-audit] [phase:implementation] [priority:P1] Full testing audit before next release: verify `pnpm test:integration` covers all wired scripts after the repo reorg (scripts renamed, sync scripts moved to scripts/, layer0→core rename, leftover cleanup). Confirm onboarding flow, install flow, and audit-sync still work end-to-end in a clean temp environment. Gate: do not release until this audit passes. (project: projectpal; captured: 2026-04-15; status: open)
- [follow-up] [feat:onboarding-helpers] [phase:prd] [priority:P2] Optional onboarding helpers: GitHub CLI and PR-template check during setup, plus a new-repo first-run prompt for deeper technical guidance. (project: projectpal; captured: 2026-04-10; status: open)
