<!-- Ownership: This directory is the planned neutral source of truth for ProjectPal behavior and runtime generation. -->

# ProjectPal Neutral Source

This directory is the future authoring center for ProjectPal.

The goal is to stop treating generated runtime files as the source of truth and instead maintain:
- shared ProjectPal behavior in neutral Markdown
- runtime-specific wrapper content in explicit adapter files
- generation rules separately from product behavior

## Layout

```text
src/projectpal/
  README.md
  shared/
    layer0.md
    layer1-index.md
  adapters/
    claude.md
    codex.md
    runtime-output-prefix.md
    codex-skill-header.md
    codex-skill-footer.md
  generation/
    contract.md
    mapping.md
```

## Responsibilities

- `shared/layer0.md`
  Canonical shared runtime body for the always-loaded ProjectPal surface. This is the content that should generate `CLAUDE.md`, `AGENTS.md`, and the shared body inside `skills/projectpal/SKILL.md`.

- `shared/layer1-index.md`
  Neutral index of deferred instruction files and their responsibilities. This keeps the source aware of the split between shared runtime behavior and the detailed files under `instructions/`.

- `adapters/claude.md`
  Claude-only wrapper rules. This should stay minimal because Claude currently uses the shared body with little or no runtime-specific wrapping.

- `adapters/codex.md`
  Codex-only wrapper rules, including skill packaging context, invocation guidance, and generated surface notes that should not pollute the shared behavior.

- `adapters/runtime-output-prefix.md`
  Shared generated-file prefix used by runtime outputs so they clearly identify the neutral source.

- `adapters/codex-skill-header.md` and `adapters/codex-skill-footer.md`
  Codex skill-specific wrapper snippets that surround the shared Layer 0 body.

- `generation/contract.md`
  Source-first generation rules: what gets generated, in what order, and what verification is required after changes.

- `generation/mapping.md`
  Current-state inventory showing which parts of the shipped runtime surfaces are shared versus adapter-specific.

## Scope

This source tree is currently scoped to the shipped Claude and Codex surfaces only.

Future runtimes such as Gemini or Cursor may get adapters later, but they are intentionally out of scope for this phase so the neutral source does not get abstract too early.
