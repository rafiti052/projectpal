# Codex Platform Adapter

Codex owns:

- the generated `AGENTS.md` runtime mirror
- the installed skill wrapper and preamble
- Codex plugin packaging metadata

This adapter may read shared inputs from `src/` and Codex-owned inputs from `platforms/codex/`. It may write only to `build/codex/`.

The generated package root is `build/codex/`:

- `build/codex/AGENTS.md`
- `build/codex/skills/projectpal/SKILL.md`
- `build/codex/.codex-plugin/plugin.json`

Repo-local Codex wiring should treat `.codex-plugin/plugin.json` as a wrapper that points at the generated `build/codex/` skill artifact, not as the authoring source.
