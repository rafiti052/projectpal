---
project: release-readiness-audit-closure
phase: 1
type: brief
status: approved
created: 2026-04-15T22:45:00-03:00
complexity: simple
---

# Brief — Close `docs/audits/2026-04-15-release-readiness.md`

## Goal

Finish the release-readiness audit as an accountable closure: every Part A and Part B clause is either already shipped (as the audit narrative states) or explicitly verified in-repo, with no silent gaps.

## Scope

1. **Part A (flow and handoff)** — Confirm referenced instruction and script behavior exists; connector scaffolding comments remain aligned with north-star §14.
2. **Part A.1 (bridge hygiene)** — Ensure `.projectpal/state.yml` `next_steps` does not read like imminent end-to-end connector product wiring; anchor to `docs/north-star.md` for schedule language.
3. **Part B (release gate)** — Re-run the four commands and record the sweep in the audit.
4. **Artifacts** — Fix `.gitignore` so committed Phase 6 ticket bundles (and this Brief) under `.projectpal/artifacts/` are actually trackable by Git.

## Out of scope

- Implementing connector product wiring or new onboarding helpers (parking lot P2 only).

## Success criteria

- Audit document includes a dated closure table mapping each subsection to **Verified** or **N/A** with notes.
- `pnpm test`, `pnpm typecheck`, `pnpm test:integration`, and `pnpm check:install --fixture` pass after changes.
- Ticket bundle lists the work and ends with a short integration report.
