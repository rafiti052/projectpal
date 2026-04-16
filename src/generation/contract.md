

# Generation Contract

## Goal

Every feature touching ProjectPal runtime behavior should update the shared source first, then regenerate the host build outputs.

## Canonical generation order

1. Edit neutral source files under `src/`
2. Edit or add host-owned adapter inputs under `platforms/<host>/`
3. Generate host outputs under `build/<host>/`
4. Run verification against the `src/` + `platforms/<host>/` input boundary
5. Repoint or refresh legacy wrapper surfaces only if that ticket explicitly owns them

## Verification expectations

- Generated build files clearly identify themselves as derived outputs
- Shared behavior is not hand-maintained in multiple host trees
- Each host reads only `src/` plus its own `platforms/<host>/` inputs
- Each host writes only to `build/<host>/`
- Shared install and smoke flows target `build/<host>/`

## Transitional bridge

The repo still has top-level wrappers such as `CLAUDE.md`, `AGENTS.md`, `skills/projectpal/SKILL.md`, and `templates/cursor-rules-projectpal.md`.

Those wrappers remain in place for now, but they are no longer the canonical host packaging source. New host packaging work should land in `platforms/<host>/` and `build/<host>/`, then later tickets can repoint the wrappers at those generated trees.
