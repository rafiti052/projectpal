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
  parking-lot.md
```

If `.projectpal/artifacts/` doesn't exist, create it before saving. All artifact paths are relative to the current working directory.

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

**Debate record template** (save to `.projectpal/artifacts/refinement/<project-name>-debate.md`):

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

**Designer review template** (save to `.projectpal/artifacts/designer-review/<project-name>-wave-<id>.md`):

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

