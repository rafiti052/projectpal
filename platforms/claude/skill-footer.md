---

## State & Artifacts

**Project-local** (`.projectpal/` in the current working directory — readable alongside the code):
- Session bridge state: `.projectpal/state.yml`
- Parking Lot: `.projectpal/parking-lot.md`
- Artifacts: `.projectpal/artifacts/` for Briefs, Technical Details, Tickets, and refinement records

**Global** (`~/.projectpal/` helper files):
- Internal review log: stored under `~/.projectpal/`

If `.projectpal/artifacts/` does not exist in the current project, create it before saving. Never use `~/.projectpal/` for session state, artifacts, or parking-lot.
