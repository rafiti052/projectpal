---
project: release-readiness-audit-closure
phase: 6
type: ticket
status: complete
created: 2026-04-15T22:45:00-03:00
complexity: simple
---

# Ticket bundle — Release readiness audit closure

## Tickets

### 001 — Audit closure table + Part A spot check

- Add a dated **Audit closure** section to `docs/audits/2026-04-15-release-readiness.md` mapping A.1–A.5 and Part B to verification notes.
- Spot-check that Part A deliverables exist (`instructions/sub-agent-invocation.md` staging handoff, `instructions/artifacts.md` tree, `scripts/onboarding-flow.sh` `prepare-repo` mkdir list, connector file headers).

### 002 — Bridge `next_steps` vs north-star A.1

- Update `.projectpal/state.yml` `next_steps` so nothing implies connector product wiring is the next ship gate; include an explicit pointer to `docs/north-star.md` §14 for backlog-only wording.
- Refresh `bridge_summary` and `last_artifact_ref` after artifacts land.

### 003 — Gitignore for committed artifacts

- Adjust `.gitignore` so `.projectpal/artifacts/brief/` and `.projectpal/artifacts/tickets/` are trackable while transient paths (e.g. `staging/`, other artifact subtrees) stay ignored.

### 004 — Release gate commands

- Run Part B command block from the audit and confirm all green; note the run in the audit closure section.

## Final integration report

- **Gitignore:** `!.projectpal/artifacts/` plus selective un-ignore for `brief/` and `tickets/` under `artifacts/*` so designer-review and other local-only trees stay ignored.
- **Audit:** Closure table added; Part B re-run recorded in the same doc.
- **Bridge:** `next_steps` neutralized for connector-imminent misread; summary points at audit + north-star.
- **Tests:** See closure section in the audit for the latest command results.
