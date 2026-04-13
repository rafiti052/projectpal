# Maintainer Codex Reinstall

This document is only for the maintainer's one-time clean reinstall test.

## Goal

Recreate a clean local state, then verify ProjectPal can be installed again and launched in Codex from scratch.

## Remove current local install state

From the repo root:

```bash
rm -f "$HOME/.claude/skills/projectpal/SKILL.md"
```

That Claude cleanup is only relevant if this machine previously installed the Claude runtime too.

Optional cleanup if you want to remove generated runtime surfaces before reinstalling:

```bash
git checkout -- CLAUDE.md AGENTS.md skills/projectpal/SKILL.md
```

Do not remove:
- `src/projectpal/`
- `instructions/`
- `.codex-plugin/plugin.json`
- `.mcp.json`

Those are part of the repo and should still exist for a clean reinstall from source.

## Reinstall for Codex

From the repo root:

```bash
sh ./install-projectpal.sh codex
```

Expected result:
- generated runtime surfaces are refreshed from `src/projectpal/`
- Codex-facing ProjectPal files are present and current

## Verify the Codex launch path

1. Open Codex in the target repo.
2. Type `ProjectPal`.
3. Confirm ProjectPal starts in Phase 0 and asks one conversational question.

## Notes

- This doc is intentionally maintainer-only.
- It is not a user-facing install guide.
- It should survive ProjectPal artifact cleanup because it lives in `docs/`, not `.projectpal/artifacts/`.
