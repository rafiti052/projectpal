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
status: draft | debated | approved | archived
created: <ISO-8601>
cynefin: simple | complicated | complex | chaotic
---
```

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

After Judge completes, save full deliberation to `.projectpal/artifacts/debate/<project-name>-debate.md`. Never show proactively — surface only if user asks "show me the debate."

**Tech spec artifact template** (extended with optional fields):
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
