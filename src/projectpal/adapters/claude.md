<!-- Ownership: Claude adapter boundary for generated Claude runtime surfaces. -->

# Claude Adapter

## Purpose

Document the minimal Claude-specific wrapper content that must remain outside the shared neutral source.

## Current boundary

- `CLAUDE.md` currently contains the shared Layer 0 body directly.
- There is no meaningful Claude-only behavioral wrapper beyond file identity and source-of-truth comments.

## Planned adapter responsibility

Keep the Claude adapter as thin as possible:
- file-level identity comments if needed
- any Claude-only launch note if one becomes necessary

The current generated-file prefix is shared through:
- `src/projectpal/adapters/runtime-output-prefix.md`

Everything else should come from `src/projectpal/shared/layer0.md`.

## Minimum wrapper conclusion

For the current repo state, the Claude runtime wrapper can be treated as effectively empty.
