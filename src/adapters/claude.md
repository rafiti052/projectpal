

# Claude Adapter

## Purpose

Document the minimal Claude-specific wrapper content that must remain outside the shared neutral source.

## Current boundary

- `CLAUDE.md` currently contains the shared core body directly.
- There is no meaningful Claude-only behavioral wrapper beyond file identity and source-of-truth comments.

## Planned adapter responsibility

Keep the Claude adapter as thin as possible:

- file-level identity comments if needed
- any Claude-only launch note if one becomes necessary

## v0.4 posture

Connector routing / delegated execution is intentionally not shipped in v0.4. `CLAUDE.md` is the only Claude runtime surface (generated from `src/shared/core.md`), so this adapter remains a thin, file-level wrapper with no connector status or delegation plumbing.

If connector delegation is added in a later version, keep it thin and avoid leaking credentials, billing identifiers, token material, or raw provider quota numbers.

## Minimum wrapper conclusion

For lean v1, the Claude wrapper stays minimal but no longer empty: it owns the reference adapter's internal result and status contract, while shared product behavior still lives in `src/shared/core.md`.