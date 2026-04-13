<!-- Ownership: Source-first generation contract for ProjectPal runtime surfaces. -->

# Generation Contract

## Goal

Every feature touching ProjectPal runtime behavior should update the neutral source first, then regenerate the shipped runtime surfaces.

## Planned generation order

1. Edit neutral source files under `src/`
2. Generate shared runtime outputs:
   - `CLAUDE.md`
   - `AGENTS.md`
   - shared body inside `skills/projectpal/SKILL.md`
3. Apply runtime-specific adapter wrappers:
   - Claude adapter as needed
   - Codex skill and packaging wrapper
4. Run verification
5. Record the regenerated runtime surfaces in the changelog

## Verification expectations

- Generated runtime files clearly identify themselves as generated outputs
- Shared behavior is not hand-maintained in multiple runtime files
- README and install flow stay aligned with the shipped Codex-first path
- Verification scripts or checklists confirm generation freshness

## Current repo gap

The repo still generates from `CLAUDE.md` directly. This contract defines the target workflow that later tickets will implement.
