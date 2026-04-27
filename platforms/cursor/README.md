# Cursor Platform Adapter

Cursor owns:

- the global registration payload merged into `~/.cursor/mcp.json`
- the repo-local rules file copied into `.cursor/rules/projectpal.md`
- the packaged launcher copied into `~/.cursor/projectpal/cursor-mcp/`

This adapter may read shared inputs from `src/` and Cursor-owned inputs from `platforms/cursor/`. It may write only to `build/cursor/`.
