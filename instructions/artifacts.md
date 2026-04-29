# Artifacts

All generated documents go to `.projectpal/artifacts/` in the current project directory. This makes them readable alongside the project as work progresses.

```
.projectpal/
  artifacts/
    brief/
    technical-details/
    tickets/
    refinement/          # debate records (`type: debate-record`) live here
    designer-review/
  staging/               # transient sub-agent drafts (see sub-agent-invocation.md)
  parking-lot.md
```

If `.projectpal/artifacts/` does not exist, create it before saving. If you use the staging handoff, create `.projectpal/staging/` before the agent writes. All artifact paths are relative to the current working directory.

## Naming contract

Use **artifact-type prefix + post-Discovery work summary slug** as the base naming pattern for every artifact:

- Brief: `.projectpal/artifacts/brief/brief-<work-summary>.md`
- Technical Details: `.projectpal/artifacts/technical-details/technical-details-<work-summary>.md`
- Ticket bundle: `.projectpal/artifacts/tickets/tickets-<work-summary>-bundle.md`
- Individual tickets: `.projectpal/artifacts/tickets/ticket-<work-summary>-NNN.md`
- Debate record: `.projectpal/artifacts/refinement/debate-record-<work-summary>.md`
- Designer review record: `.projectpal/artifacts/designer-review/designer-review-<work-summary>-wave-<id>.md`

`<work-summary>` is a concise slug produced after Discovery confirms scope. Use lowercase ASCII and hyphens.

## Staging drafts and promotion

Sub-agents may write large drafts under `.projectpal/staging/<agent-slug>-<draft-id>.md` and return `artifact_draft_path` in their completion signal. The Pal validates content, then **promotes** into the canonical tree under `artifacts/` (see templates above). Staging files are disposable after a successful promotion; do not treat them as user-facing artifacts.

All generated documents use YAML frontmatter:

```yaml
---
project: <project-name>
phase: <phase-number>
type: brief | technical-details | ticket | refinement | debate-record | designer-review
status: <varies by artifact type>
created: <ISO-8601>
complexity: simple | complicated | complex | chaotic
---
```

Status vocabulary by artifact type:

- Brief artifact (`brief`): `draft | refined | approved | archived`
- Technical Details artifact (`technical-details`): `draft | approved | archived`
- Debate record (`debate-record`, stored under `refinement/`): `complete | escalated`
- Designer review (`designer-review`): `approved | changes-requested`
- Legacy refinement record (`refinement`, deprecated path): `complete` — prefer `debate-record` for new work
- Ticket bundle and tickets: `ready | queued | running | blocked | complete | deferred | archived`

User-facing labels must follow the new UX consistently:

- `brief` artifact → present as the user's **Brief**
- `technical-details` artifact → present as **Technical Details**
- `debate-record` and legacy `refinement` files → backstage only; never present as raw stage labels unless the user explicitly asks to inspect the record

Check-in-facing artifacts should be presented through the ProjectPal shell, not dumped raw into chat.

Artifact review pattern:

- header shell
- three-line summary
- artifact link or links
- one approval question

Mandated Check-ins named in `instructions/phase-protocols.md` (see **Check-in obligations**) use this shape unless that document specifies a different rhythm.

**Debate record template** (save to `.projectpal/artifacts/refinement/debate-record-<work-summary>.md`):

```yaml
---
project: <project-name>
phase: 2
type: debate-record
status: complete | escalated
created: <ISO-8601>
rounds: <1-3>
outcome: consensus | escalated
strategist_sign_off: approved | approved-with-concern | rejected
architect_sign_off: approved | approved-with-concern | rejected
manager_sign_off: approved | approved-with-concern | rejected
concerns: []  # optional — omit if none
---
```

Body holds per-round critique narrative. The Pal synthesizes the user-facing Brief from this record; never show the debate body proactively.

**Designer review template** (save to `.projectpal/artifacts/designer-review/designer-review-<work-summary>-wave-<id>.md`):

```yaml
---
project: <project-name>
phase: 7
type: designer-review
status: approved | changes-requested
wave: <wave-id>
created: <ISO-8601>
---
```

**Technical Details artifact template** (stored under the `technical-details` type and folder):

```yaml
---
project: <project-name>
phase: 4
type: technical-details
status: draft | approved | archived
created: <ISO-8601>
complexity: simple | complicated | complex | chaotic
precedents: []                        # optional — omit if none
spikes: [question: resolved | open]  # optional — omit if none
---
```

**Ticket bundle contract**

- The ticket bundle saved under `.projectpal/artifacts/tickets/` is the canonical Phase 6 artifact.
- Individual ticket files stay alongside the bundle and follow the same repo-local artifact rules.
- During Phase 7, update ticket status in place and preserve the Final Integration Report in the bundle.

