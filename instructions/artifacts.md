<!-- Ownership: Layer 1 artifact contracts live here; source text originates in CLAUDE.md and is loaded when artifact format detail is needed. -->

# Artifacts

All generated documents go to `.projectpal/artifacts/` in the current project directory. This makes them readable alongside the project as work progresses.

```
.projectpal/
  artifacts/
    prd/
    tech-spec/
    tickets/
    debate/
  parking-lot.md
```

If `.projectpal/artifacts/` doesn't exist, create it before saving. All artifact paths are relative to the current working directory.

All generated documents use YAML frontmatter:

```yaml
---
project: <project-name>
phase: <phase-number>
type: prd | tech-spec | ticket | debate
status: <varies by artifact type>
created: <ISO-8601>
cynefin: simple | complicated | complex | chaotic
---
```

Status vocabulary by artifact type:
- PRD: `draft | debated | approved | archived`
- Tech spec: `draft | approved | archived`
- Debate: `complete`
- Ticket bundle and tickets: `ready | queued | running | blocked | complete | deferred | archived`

User-facing labels must follow the new UX even when file names keep the legacy internal artifact types:
- `prd` artifact → present as the user's **Brief**
- `tech-spec` artifact → present as **Technical Details**
- `debate` artifact → backstage only; never present as a visible stage label unless the user explicitly asks to inspect the debate record

Check-in-facing artifacts should be presented through the ProjectPal shell, not dumped raw into chat.

Artifact review pattern:
- header shell
- three-line summary
- artifact link or links
- one approval question

**Debate artifact template** (save to `.projectpal/artifacts/debate/<project-name>-debate.md`):
```yaml
---
project: <project-name>
phase: 2
type: debate
status: complete
created: <ISO-8601>
critic-verdict: pass | pass-with-revisions | needs-rework
---
```

After Judge completes, save full deliberation to `.projectpal/artifacts/debate/<project-name>-debate.md`. Never show proactively, and never narrate Critic/Judge progress to the user while it is running. Surface the debate record only if the user explicitly asks to inspect it.

**Technical Details artifact template** (stored under the internal `tech-spec` type and folder):
```yaml
---
project: <project-name>
phase: 4
type: tech-spec
status: draft | approved | archived
created: <ISO-8601>
cynefin: simple | complicated | complex | chaotic
precedents: [<mempalace-ref>, ...]   # optional — omit if none
spikes: [question: resolved | open]  # optional — omit if none
---
```

**Ticket bundle contract**
- The ticket bundle saved under `.projectpal/artifacts/tickets/` is the canonical Phase 6 artifact.
- Individual ticket files stay alongside the bundle and follow the same repo-local artifact rules.
- During Phase 7, update ticket status in place and preserve the Final Integration Report in the bundle.
