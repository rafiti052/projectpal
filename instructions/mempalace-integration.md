<!-- Ownership: Layer 1 MemPalace integration detail lives here; source text originates in CLAUDE.md and is loaded when memory behavior needs full detail. -->

# MemPalace Integration

MemPalace is connected via MCP. Two distinct mechanisms keep different jobs separate:

- **Diary** (`mempalace_diary_write` / `mempalace_diary_read`): availability check and agent handoff only. Do not treat the diary as the source of truth for repo continuity.
- **Repo-scoped drawers** (`mempalace_add_drawer` + `mempalace_search`): continuity and parked work for the active repo under `wing="Projects"` and `room="<repo-slug>"`.
- **Global drawers** (`mempalace_add_drawer` + `mempalace_search`): shared knowledge in wings such as `Principles`, `Decisions`, and `Precedents`.

**Purpose:** Local continuity should come from `.projectpal/state.yml` first, with repo-scoped memory as background continuity or bootstrap only when the local bridge is missing. The diary remains an availability and handoff mechanism only. Load full artifacts only when the phase actively needs them.

## Orchestration persistence guard

For lean v1 orchestration data, ProjectPal persists only connector-safe metadata and thread-local references.

- `allowed_metadata_fields[]` = `auth_state`, `availability_state`, `last_failure_reason`, `quota_state`
- `connector_identity` and timestamps may be kept as structural context.
- Connector-owned auth stays outside ProjectPal storage.
- Never store raw credentials, token material, token fingerprints, account identity, billing identifiers, or raw quota numbers in `.projectpal/`, artifacts, diary entries, or repo-scoped drawers.
- If the connector cannot prove a value, store `unknown` rather than guessing.

## Repo-scoped memory conventions

- Repo anchor writes go to `wing="Projects"` and `room="<repo-slug>"`.
- Feature-scoped writes stay in the same room and add tags in content, such as `repo:<repo-slug> feat:<feat-slug> phase:<phase-tag> kind:feature-scope`.
- Parking Lot mirrors stay in the same room and add tags in content, such as `repo:<repo-slug> feat:<feat-slug|none> phase:<phase-tag> kind:parking-lot`.
- Repo-scoped search order is fixed: local bridge first, then the repo room, then matching `feat:` tags in that room, then `kind:parking-lot` for that repo, then broader global fallback only if repo-local search misses.
- Repo-scoped writes happen quietly after local bridge updates succeed.

## Session end — always write diary before closing

*(Skip if `mempalace_available = false`)*

Write entries in compressed AAAK format. Example:
`SESSION:2026-04-09|<project>-phase<N>|built:<artifacts>|KEY:<decisions>|NEXT:<action>|★★`

```
mempalace_diary_write(
  agent_name="projectpal",
  entry="SESSION:<date>|<project>-phase<N>|built:<artifacts-list>|KEY:<key-decisions>|NEXT:<exact-next-action>|CTX:<2-sentence-summary>",
  topic="session-end"
)
```

No return value to store. Retrieval is always by recency — no ID needed.

## Session start — read diary before anything else

The diary read at session start is performed as part of the MemPalace Availability Check above. It serves double duty as detection and handoff context. Do not call `mempalace_diary_read` a second time here.

*(Skip if `mempalace_available = false` — use `.projectpal/state.yml` instead)*

## When to load full artifact files

Only load `.projectpal/artifacts/` files when the phase actively needs the full content:

| Phase | Load full file? | Why |
|-------|----------------|-----|
| Session start | No | Use local bridge first; fall back to repo-scoped memory only if needed |
| Phase 2 (Refinement) | Yes — Brief artifact | Internal reviewers need the full Brief text |
| Phase 4 (Planning) | Yes — Brief artifact | Technical Details are generated from the full Brief artifact |
| Phase 5 (Technical Details) | Yes — Technical Details artifact | User reviews the full Technical Details artifact |
| Phase 6 (Tickets) | Yes — Technical Details artifact | Tickets are derived from the full Technical Details artifact |
| Phase 7 (Implementation) | Yes — Tickets | Work is driven by the ticket set |
| Phase 8 (Wrap Up) | Yes — Tickets and changed files | Review compares intended tickets against implemented changes |

Never load files preemptively. Token cost scales with file size — only pay when necessary.
