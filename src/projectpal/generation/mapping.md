<!-- Ownership: Current-state mapping from shipped runtime files into shared behavior and runtime-specific wrappers. -->

# Current-State Mapping

## Shared behavior inventory

These are currently shared ProjectPal behavior blocks that should move into the neutral source:

| Current file | Current block | Classification | Planned neutral home |
|--------------|---------------|----------------|----------------------|
| `CLAUDE.md` | Full Layer 0 runtime body | Shared | `src/projectpal/shared/layer0.md` |
| `AGENTS.md` | Full Layer 0 runtime body | Shared generated mirror | `src/projectpal/shared/layer0.md` |
| `skills/projectpal/SKILL.md` | Embedded ProjectPal runtime body copied from `CLAUDE.md` | Shared generated body | `src/projectpal/shared/layer0.md` |
| `instructions/*.md` | Detailed deferred protocols and contracts | Shared deferred detail | referenced by `src/projectpal/shared/layer1-index.md` |

## Runtime-specific wrapper inventory

These blocks should remain outside the shared neutral source:

| Current file | Current block | Classification | Planned adapter home |
|--------------|---------------|----------------|----------------------|
| `skills/projectpal/SKILL.md` | skill frontmatter | Codex wrapper | `src/projectpal/adapters/codex.md` |
| `skills/projectpal/SKILL.md` | Codex adapter preamble | Codex wrapper | `src/projectpal/adapters/codex.md` |
| `skills/projectpal/SKILL.md` | Codex packaging footer | Codex wrapper | `src/projectpal/adapters/codex.md` |
| `.codex-plugin/plugin.json` | plugin metadata and prompt triggers | Codex wrapper metadata | `src/projectpal/adapters/codex.md` |
| `CLAUDE.md` | ownership comment and file identity | Claude wrapper, minimal | `src/projectpal/adapters/claude.md` |

## Non-source operational files

These files support runtime operation but are not themselves the authoring source:

| File | Role | Classification |
|------|------|----------------|
| `.mcp.json` | project MCP server wiring | operational config |
| `.claude/settings.local.json` | local Claude permissions/settings | local runtime config |
| `.gemini/commands/projectpal.toml` | current Gemini adapter command | future adapter surface, out of scope for this phase |
| `.gemini/settings.json` | Gemini MCP/config state | future runtime config, out of scope for this phase |
| `sync-codex-plugin.sh` | current direct generation script | generation tooling, to be migrated to the neutral-source contract |

## Minimum wrapper boundary summary

- Claude: effectively no behavioral wrapper, only file-level identity.
- Codex: frontmatter, invocation preamble, plugin metadata, and packaging footer are the true wrapper boundary.
- Gemini: currently points at `CLAUDE.md` and remains out of scope for this phase so the neutral source can focus on shipped Claude and Codex outputs first.
