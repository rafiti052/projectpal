

# Current-State Mapping

## Shared behavior inventory

These are currently shared ProjectPal behavior blocks that should move into the neutral source:


| Current file                 | Current block                                            | Classification          | Planned neutral home                        |
| ---------------------------- | -------------------------------------------------------- | ----------------------- | ------------------------------------------- |
| `CLAUDE.md`                  | Full core runtime body                                   | Shared                  | `src/shared/core.md`                        |
| `AGENTS.md`                  | Full core runtime body                                   | Shared generated mirror | `src/shared/core.md`                        |
| `skills/projectpal/SKILL.md` | Embedded ProjectPal runtime body copied from `CLAUDE.md` | Shared generated body   | `src/shared/core.md`                        |
| `instructions/*.md`          | Detailed deferred protocols and contracts                | Shared deferred detail  | referenced by `src/shared/runtime-index.md` |


## Runtime-specific wrapper inventory

These blocks should remain outside the shared neutral source:


| Current file                  | Current block                       | Classification           | Planned adapter home                   |
| ----------------------------- | ----------------------------------- | ------------------------ | -------------------------------------- |
| `skills/projectpal/SKILL.md`  | skill frontmatter                   | Codex wrapper            | `src/adapters/codex.md`                |
| `skills/projectpal/SKILL.md`  | Codex adapter preamble              | Codex wrapper            | `src/adapters/codex.md`                |
| `skills/projectpal/SKILL.md`  | Codex packaging footer              | Codex wrapper            | `src/adapters/codex.md`                |
| `.codex-plugin/plugin.json`   | plugin metadata and prompt triggers | Codex wrapper metadata   | `src/adapters/codex.md`                |
| `CLAUDE.md`                   | ownership comment and file identity | Claude wrapper, minimal  | `src/adapters/claude.md`               |
| `~/.cursor/mcp.json`          | Cursor registration metadata        | Cursor install wrapper   | `src/adapters/cursor.md`               |
| `.cursor/rules/projectpal.md` | repo-local Cursor context           | Cursor repo template     | `templates/cursor-rules-projectpal.md` |


## Non-source operational files

These files support runtime operation but are not themselves the authoring source:


| File                               | Role                                | Classification        |
| ---------------------------------- | ----------------------------------- | --------------------- |
| `.mcp.json`                        | project MCP server wiring           | operational config    |
| `.claude/settings.local.json`      | local Claude permissions/settings   | local runtime config  |
| `scripts/install-cursor.sh`        | installs Cursor global registration | install tooling       |
| `scripts/generate.sh`              | generation script                   | generation tooling    |


## Minimum wrapper boundary summary

- Claude: effectively no behavioral wrapper, only file-level identity.
- Codex: frontmatter, invocation preamble, plugin metadata, and packaging footer are the true wrapper boundary.
- Cursor: registration metadata and repo-local rules template are wrapper-owned outside the shared body.
- Connector runtime (routing/connector delegation) is intentionally deferred; v0.4 ships only the always-loaded Claude/Codex surfaces plus Cursor MCP registration.