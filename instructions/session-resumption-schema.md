<!-- Ownership: Layer 1 session-resumption schema lives here; source text originates in CLAUDE.md and is loaded when repo continuity detail is needed. -->

# Session Resumption Schema

## Startup precedence rule

1. Detect the active repo first.
2. If repo-scoped memory exists for that repo, it wins.
3. `.projectpal/state.yml` is only a lightweight bridge when repo-scoped memory is unavailable or repo detection is ambiguous.
4. If repo-scoped memory and `.projectpal/state.yml` disagree, repo-scoped memory wins for the current repo and the local bridge should be updated to match.

## Repo resolution rule

- Resolve `repo_slug` from `git rev-parse --show-toplevel` and use the repo-root directory name as the slug.
- If git root detection fails, fall back to the current working directory name and mark the result internally as low confidence.
- Store a `repo_root_hint` in `.projectpal/state.yml` whenever a git root is available. If the stored hint does not match the current repo root, ignore the old bridge state and reinitialize it for the current repo.
- First visit behavior: if repo-scoped memory is missing but `.projectpal/state.yml` exists for the current repo, seed the resume summary from the bridge. If neither exists, start fresh in Phase 0 and create the bridge on first save.
- Parallel repo handling: different repos never share a bridge file. Multiple worktrees of the same repo share repo-scoped memory in `Projects/<repo-slug>`, but each worktree keeps its own local bridge until the next successful sync.

## Schema contract

`RepoAnchor` lives in repo-scoped memory and carries:
- `repo_slug`
- `repo_root_hint` when known
- `last_phase`
- `last_resume_summary`
- `last_next_step`
- `last_seen_at`
- `memory_refs[]` for related repo-scoped drawers

`FeatureScope` lives in repo-scoped memory and carries:
- `repo_slug`
- `feat_slug`
- `phase`
- `status`
- `summary`
- `updated_at`

`ResumeBridge` lives in `.projectpal/state.yml` and carries:
- `repo_slug`
- `repo_root_hint` when known
- `current_project`
- `current_phase`
- `cynefin_domain`
- `last_session`
- `resume_source`
- `synced_at`
- `artifacts_dir`
- `partial_context`
- `next_steps[]`

## Partial context schema

If Phase 0 is incomplete when a session ends, save to `.projectpal/state.yml`:

```yaml
partial_context:
  complete: false
  readiness:
    who_has_the_problem:
      answered: true | false
      source: "<verbatim excerpt or null>"
    whats_the_pain:
      answered: true | false
      source: "<verbatim excerpt or null>"
    proposed_direction:
      answered: true | false
      source: "<verbatim excerpt or null>"
    what_does_success_look_like:
      answered: true | false
      source: "<verbatim excerpt or null>"
```

## Resume logic when `partial_context.complete: false`

1. Read the answered fields
2. Generate re-entry from source excerpt of the first answered field:
   *"Last time you mentioned [source]. Tell me more about that, or is there something new?"*
3. Queue unanswered fields in priority order (who → pain → direction → success)
4. Ask the highest-priority unanswered field next — one question only
5. Never re-ask answered fields. Never push to Phase 1 until all four are answered.

When all four are answered: set `complete: true`. Clear `partial_context` after Phase 1 completes.

## Bridge save cadence

To preserve resume continuity during long sessions or interrupted runs, ProjectPal should save `.projectpal/state.yml` more often than phase boundaries alone.

- Save the local bridge after every approved artifact write.
- Save the local bridge after every meaningful phase transition.
- Save the local bridge after any substantial user-approved revision to a PRD, spec, or ticket set.
- During long phases, save the local bridge after each meaningful batch of work, using the freshest `last_artifact_ref`, `next_steps`, and `bridge_summary`.
- Before any likely interruption point, such as a long sub-agent run, large edit batch, or implementation batch that may exceed the session budget, save the local bridge first.
- If work stops unexpectedly, the bridge should be specific enough that the next session can resume from the last completed batch rather than replaying the whole phase.
