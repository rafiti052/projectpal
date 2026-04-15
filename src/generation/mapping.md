<!-- Ownership: Current-state mapping from shipped runtime files into shared behavior and runtime-specific wrappers. -->

# Current-State Mapping

## Shared behavior inventory

These are currently shared ProjectPal behavior blocks that should move into the neutral source:

| Current file | Current block | Classification | Planned neutral home |
|--------------|---------------|----------------|----------------------|
| `CLAUDE.md` | Full Layer 0 runtime body | Shared | `src/shared/layer0.md` |
| `AGENTS.md` | Full Layer 0 runtime body | Shared generated mirror | `src/shared/layer0.md` |
| `skills/projectpal/SKILL.md` | Embedded ProjectPal runtime body copied from `CLAUDE.md` | Shared generated body | `src/shared/layer0.md` |
| `instructions/*.md` | Detailed deferred protocols and contracts | Shared deferred detail | referenced by `src/shared/layer1-index.md` |

## Runtime-specific wrapper inventory

These blocks should remain outside the shared neutral source:

| Current file | Current block | Classification | Planned adapter home |
|--------------|---------------|----------------|----------------------|
| `skills/projectpal/SKILL.md` | skill frontmatter | Codex wrapper | `src/adapters/codex.md` |
| `skills/projectpal/SKILL.md` | Codex adapter preamble | Codex wrapper | `src/adapters/codex.md` |
| `skills/projectpal/SKILL.md` | Codex packaging footer | Codex wrapper | `src/adapters/codex.md` |
| `.codex-plugin/plugin.json` | plugin metadata and prompt triggers | Codex wrapper metadata | `src/adapters/codex.md` |
| `CLAUDE.md` | ownership comment and file identity | Claude wrapper, minimal | `src/adapters/claude.md` |
| `~/.cursor/mcp.json` | Cursor registration metadata | Cursor install wrapper | `src/adapters/cursor.md` |
| `.cursor/rules/projectpal.md` | repo-local Cursor context | Cursor repo template | `templates/cursor-rules-projectpal.md` |
| `~/.projectpal/routing.yml` | global connector approval + routing | routing install template | `templates/routing.yml` |

## Non-source operational files

These files support runtime operation but are not themselves the authoring source:

| File | Role | Classification |
|------|------|----------------|
| `.mcp.json` | project MCP server wiring | operational config |
| `.claude/settings.local.json` | local Claude permissions/settings | local runtime config |
| `.gemini/commands/projectpal.toml` | current Gemini adapter command | future runtime config |
| `.gemini/settings.json` | Gemini MCP/config state | future runtime config |
| `sync-cursor-skill.sh` | installs Cursor global registration | install tooling |
| `sync-codex-plugin.sh` | current direct generation script | generation tooling, to be migrated to the neutral-source contract |

## Minimum wrapper boundary summary

- Claude: effectively no behavioral wrapper, only file-level identity.
- Codex: frontmatter, invocation preamble, plugin metadata, and packaging footer are the true wrapper boundary.
- Cursor: registration metadata and repo-local rules template are wrapper-owned outside the shared body.
- Gemini: no generated runtime surface yet, but the adapter contract is now tracked in source so routing work can stay aligned with the shared connector model.
