# Release readiness — 2026-04-15

Two-part audit for the `projectpal` repo: flow optimization (including sub-agent handoff), then integration testing (Part B).

---

## Part A — Flow optimization and sub-agent handoff (completed)

### A.1 Parking lot and roadmap hygiene

- Connector **product** wiring is explicitly **not** a near-term target; it lives only in `docs/north-star.md` §14 with schedule language. Active `next_steps` should not treat it as imminent work.
- The prior parking-lot row marked flow optimization “incorporated” without deliverables — corrected by shipping this Part A and the instruction updates below.

### A.2 Sub-agent artifact handoff

- **Added** `instructions/sub-agent-invocation.md` → **Sub-agent artifact handoff (staging)**: `.projectpal/staging/<agent-slug>-<draft-id>.md`, Pal `mkdir -p`, agent returns `artifact_draft_path`, Pal validates and promotes into canonical `artifacts/` paths per `instructions/artifacts.md`.
- **Updated** debate Step 1 and Phase 6 Step 4 to allow capture from staging when used.
- **Updated** Designer contract line to reference staging for long designer-review payloads.
- **Added** `instructions/artifacts.md` tree entry for `staging/`, plus **Staging drafts and promotion** rules.

### A.3 Repo preparation

- **`scripts/onboarding-flow.sh` `prepare-repo`:** creates `.projectpal/staging` and `artifacts/designer-review` alongside existing artifact folders so prepared repos match the documented layout.

### A.4 Connector scaffolding posture (code clarity, not product ship)

- Connector runtime scaffolding is not shipped in v0.4; connector modules and routing/install templates are removed from the install surface. The connector roadmap remains only in `docs/north-star.md` (§14) for later versions.

### A.5 AHA and phase surfaces (spot check)

- Lean posture and Designer gates remain centralized in `src/shared/core.md` and `instructions/phase-protocols.md`; no change required beyond the handoff flow above. Connector carve-out in AHA still applies only when an in-repo Brief mandates connector work.

---

## Part B — Full testing audit (release gate)

**Status:** completed; re-verified on demand (see B.1 for latest run).

Commands (repo root):

```bash
pnpm test
pnpm typecheck
pnpm test:integration
pnpm check:install --fixture
```

### B.1 Results

- Last run: 2026-04-15 (local; Vitest v3.2.4, Node per `engines`)
- `pnpm test` (Vitest): **pass** (5 tests)
- `pnpm typecheck`: **pass**
- `pnpm test:integration`: **pass** (`projectpal-runtime tests passed`)
- `pnpm check:install --fixture`: **pass** (0 failures; gemini + cursor adapter checks)
- Notes: Integration initially failed earlier in the cycle because `CLAUDE.md` / `AGENTS.md` lacked the HTML comment from `src/adapters/runtime-output-prefix.md` (`ProjectPal neutral source under src/`). Restored that one-line prefix and re-ran `scripts/generate.sh` so generated surfaces match what `scripts/test-integration.sh` asserts. The `check:install` npm script invokes `tsx scripts/check-install.ts` without hardcoding `--fixture`, so the release gate passes `--fixture` once from the CLI.

---

## Audit closure (accountable sweep)

**Closed:** 2026-04-15 (same release-readiness document; Pal closure batch).

Each row is either **Verified** (present in tree and matches the audit intent) or documents an explicit follow-up outside this audit.


| Ref | Topic                         | Status       | Notes                                                                                                                                                                                                                                           |
| --- | ----------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A.1 | Parking lot / roadmap hygiene | **Verified** | Connector product wiring called out only as long-range shape in `docs/north-star.md` §14; `.projectpal/state.yml` `next_steps` reviewed and rewritten so nothing reads as an imminent connector **product** ship (see north-star for schedule). |
| A.2 | Sub-agent artifact handoff    | **Verified** | `instructions/sub-agent-invocation.md` documents staging path + `artifact_draft_path`; Phase 6 / Designer references updated in that file.                                                                                                      |
| A.3 | Repo preparation              | **Verified** | `scripts/onboarding-flow.sh` `prepare-repo` creates `.projectpal/staging` and `artifacts/designer-review` with sibling artifact dirs (see script `mkdir -p` block).                                                                             |
| A.4 | Connector scaffolding posture | **Verified** | Connector runtime modules are not shipped in v0.4; only north-star backlog remains.                                                                                                              |
| A.5 | AHA / phase surfaces          | **Verified** | No additional change required per audit; spot-check unchanged.                                                                                                                                                                                  |
| B   | Full testing audit            | **Verified** | Commands in §Part B re-run on closure; all **pass** (Vitest 5, `tsc`, integration script, `check:install --fixture`).                                                                                                                           |


**Open defects from this audit:** none. Optional product follow-ups stay on `.projectpal/parking-lot.md` (e.g. onboarding helpers P2), not in this gate.

**Artifacts for this closure:** `.projectpal/artifacts/brief/release-readiness-audit-closure.md`, `.projectpal/artifacts/tickets/release-readiness-audit-closure-bundle.md`.

### Closure command re-run

Re-run at end of closure batch (2026-04-15): `pnpm test` (5 passed), `pnpm typecheck` (pass), `pnpm test:integration` (`projectpal-runtime tests passed`), `pnpm check:install --fixture` (0 failures).