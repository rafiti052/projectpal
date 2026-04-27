<!-- Ownership: This directory is the canonical shared source of truth for ProjectPal behavior. -->

# ProjectPal Neutral Source

This directory is the shared authoring center for ProjectPal.

The repo now separates:
- shared ProjectPal behavior in neutral Markdown
- host-specific wrapper and packaging content in `platforms/<host>/`
- generated host outputs in `build/<host>/`
- generation rules separately from product behavior

## Layout

```text
src/
  README.md
  shared/
    core.md
    runtime-index.md
  adapters/
    claude.md
    codex.md
    cursor.md
    runtime-output-prefix.md
    codex-skill-header.md
  generation/
    contract.md
    mapping.md

platforms/
  claude/
  codex/
  cursor/

build/
  claude/
  codex/
  cursor/
```

## Responsibilities

- `shared/core.md`
  Canonical shared runtime body for the always-loaded ProjectPal surface. This is the content that should generate `CLAUDE.md`, `AGENTS.md`, and the shared body inside `skills/projectpal/SKILL.md`.

- `shared/runtime-index.md`
  Neutral index of deferred instruction files and their responsibilities. This keeps the source aware of the split between shared runtime behavior and the detailed files under `instructions/`.

- `adapters/runtime-output-prefix.md`
  Shared generated-file prefix used by runtime outputs so they clearly identify the shared source.

- `adapters/*.md`
  Transitional bridge docs for the legacy top-level wrappers. These stay under `src/` until the wrapper scripts are fully repointed at `platforms/<host>/`.

- `platforms/<host>/`
  Host-owned adapter inputs. Each host manifest lists the exact files that host may read and the exact outputs it may write under `build/<host>/`.

- `build/<host>/`
  Generated host package roots. Shared install and validation flows should target these outputs instead of mixing generated files into the repo root.

- `generation/contract.md`
  Source-first generation rules: what gets generated, in what order, and what verification is required after changes.

- `generation/mapping.md`
  Current-state inventory showing which parts of the shipped runtime surfaces are shared versus adapter-specific.

## Scope

This source tree owns only shared behavior and shared generation rules.

That means `src/` owns:
- canonical shared ProjectPal behavior
- shared generated-file identity text
- bridge documentation for the legacy wrapper surfaces

Host packaging glue, install metadata, and generated host artifacts belong under `platforms/` and `build/`, not in the repo root.
