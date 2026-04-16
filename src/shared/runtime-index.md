

# Shared Layer 1 Index

ProjectPal currently keeps detailed protocols in repo-local files under `instructions/`.

This index exists so the neutral source can refer to those responsibilities without re-embedding the full detailed text into runtime wrappers.

## Deferred instruction map

- `instructions/phase-protocols.md`
Phase 0, Phase 1, Refinement, and Phase 4/7/8 detailed protocols.
- `instructions/session-resumption-schema.md`
Repo resolution, resume schemas, partial-context logic, and bridge save cadence.
- `instructions/sub-agent-invocation.md`
Sub-agent contracts and Refinement / ticket generation orchestration.
- `instructions/artifacts.md`
Artifact layout, frontmatter contracts, and Refinement / Technical Details templates.

## Constraint

The shared runtime surfaces should point to these files, not duplicate their content inline unless a runtime absolutely requires a local wrapper note.