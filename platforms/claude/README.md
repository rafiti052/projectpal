# Claude Platform Adapter

Claude owns:

- the installed skill wrapper around the shared runtime body
- Claude-specific footer text for local state/artifact guidance
- Claude hook packaging assets such as `pp-compress`

This adapter may read shared inputs from `src/` and Claude-owned inputs from `platforms/claude/`. It may write only to `build/claude/`.
