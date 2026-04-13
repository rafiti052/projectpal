<!-- Ownership: Layer 1 MemPalace integration detail lives here; source text originates in CLAUDE.md and is loaded when memory behavior needs full detail. -->

# MemPalace Integration

MemPalace is connected via MCP. Two distinct mechanisms — keep them separate:

- **Diary** (`mempalace_diary_write` / `mempalace_diary_read`): availability check and agent handoff only. Do not treat the diary as the source of truth for repo continuity.
- **Repo-scoped drawers** (`mempalace_add_drawer` + `mempalace_search`): continuity and parked work for the active repo under `wing="Projects"` and `room="<repo-slug>"`.
- **Global drawers** (`mempalace_add_drawer` + `mempalace_search`): shared knowledge in wings such as `Principles`, `Decisions`, and `Precedents`.

**Purpose:** Repo continuity should come from repo-scoped memory first, with `.projectpal/state.yml` as a bridge and the diary only as an availability/handoff mechanism. Load full artifacts only when the phase actively needs them.

## Repo-scoped memory conventions

- Repo anchor writes go to `wing="Projects"` and `room="<repo-slug>"`.
- Feature-scoped writes stay in the same room and add tags in content, such as `repo:<repo-slug> feat:<feat-slug> phase:<phase-tag> kind:feature-scope`.
- Parking Lot mirrors stay in the same room and add tags in content, such as `repo:<repo-slug> feat:<feat-slug|none> phase:<phase-tag> kind:parking-lot`.
- Repo-scoped search order is fixed: repo room first, then matching `feat:` tags in that room, then `kind:parking-lot` for that repo, then broader global fallback only if repo-local search misses.
- Repo-scoped writes happen before local bridge updates when MemPalace is available.

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

The diary read at session start is performed as part of the MemPalace Availability Check above — it serves double duty as detection and resumption. Do not call `mempalace_diary_read` a second time here.

*(Skip if `mempalace_available = false` — use `.projectpal/state.yml` instead)*

## When to load full artifact files

Only load `.projectpal/artifacts/` files when the phase actively needs the full content:

| Phase | Load full file? | Why |
|-------|----------------|-----|
| Session start | No | Use repo-scoped memory summary |
| Phase 2 (Debate) | Yes — PRD | Critic/Judge need full text |
| Phase 4 (Tech Spec) | Yes — PRD | Spec is generated from full PRD |
| Phase 5 (Checkpoint) | Yes — Spec | User reviews full spec |
| Phase 6 (Tickets) | Yes — Spec | Tickets derived from full spec |
| Phase 7 (Implementation) | Yes — Tickets | Work is driven by the ticket set |
| Phase 8 (Review & Wrap-Up) | Yes — Tickets and changed files | Review compares intended tickets against implemented changes |

Never load files preemptively. Token cost scales with file size — only pay when necessary.
