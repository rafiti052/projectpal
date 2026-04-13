# Repo Context Lifecycle

This note records the Phase 7 ticket 001 decision for repo-scoped continuity.

## Decision

ProjectPal resolves repo continuity from the active repo first, not from one shared local state blob.

## Resolution Rules

1. Detect the active repo root with `git rev-parse --show-toplevel`.
2. Use the repo-root directory name as `repo_slug`.
3. If git root detection fails, fall back to the current working directory name and treat the result as low confidence.
4. Persist `repo_root_hint` alongside the local bridge state whenever a git root is known.
5. If the current repo root and the stored `repo_root_hint` differ, ignore the old bridge state and initialize a new bridge for the current repo.

## Schema

### RepoAnchor

- `repo_slug`
- `repo_root_hint`
- `last_phase`
- `last_resume_summary`
- `last_next_step`
- `last_seen_at`
- `memory_refs[]`

Stored in MemPalace under `wing="Projects"` and `room="<repo-slug>"`.

### FeatureScope

- `repo_slug`
- `feat_slug`
- `phase`
- `status`
- `summary`
- `updated_at`

Stored in the same repo room with tagged content, including `kind:feature-scope`.

### ResumeBridge

- `repo_slug`
- `repo_root_hint`
- `current_project`
- `current_phase`
- `cynefin_domain`
- `last_session`
- `resume_source`
- `synced_at`
- `artifacts_dir`
- `partial_context`
- `next_steps[]`

Stored locally in `.projectpal/state.yml`.

## First Visit

- If repo-scoped memory exists in `Projects/<repo-slug>`, it is authoritative.
- If repo-scoped memory does not exist but the local bridge matches the current repo, use the bridge as the startup summary seed.
- If neither exists, start fresh in Phase 0 and create the bridge on first save.

## Search And Write Order

Search order:
1. Repo room first
2. Matching `feat:` tags in that room
3. `kind:parking-lot` items for that repo
4. Local bridge fallback
5. Global memory fallback

Write order when MemPalace is available:
1. Repo-scoped drawer in `Projects/<repo-slug>`
2. Local bridge update in `.projectpal/state.yml`
3. Local Parking Lot markdown update when the item is parked work

## Parking Lot Mirror

Every parked item uses compact tags in both places:
`repo:<repo-slug> feat:<feat-slug|none> phase:<phase-tag> kind:parking-lot`

This keeps phase-entry surfacing repo-local and lets the local markdown file stay readable.

## Parallel Repos And Worktrees

- Different repos never share `.projectpal/state.yml`.
- Multiple worktrees of the same repo share repo-scoped MemPalace continuity under `Projects/<repo-slug>`.
- Each worktree keeps its own `.projectpal/state.yml` bridge file.
- If a worktree bridge disagrees with repo-scoped memory, repo-scoped memory wins and the bridge is updated on the next sync.

## Why

This keeps resume behavior tied to the repo that produced the context, prevents stale state from leaking across repos, and avoids treating worktrees as unrelated projects.
