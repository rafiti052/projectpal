<!-- Ownership: Codex adapter boundary for generated Codex runtime surfaces. -->

# Codex Adapter

## Purpose

Document the Codex-specific wrapper content that must remain outside the shared neutral source.

## Current shipped Codex surfaces

- `AGENTS.md`
- `skills/projectpal/SKILL.md`
- `.codex-plugin/plugin.json`

## Current adapter-specific content

- `skills/projectpal/SKILL.md` frontmatter:
  - skill name
  - description
  - `source_of_truth`

- Codex adapter preamble in `skills/projectpal/SKILL.md`:
  - canonical Codex invocation: `ProjectPal`
  - warning that `/projectpal` is not assumed to be a native slash command
  - note translating Claude-specific tool language into Codex equivalents

- Codex packaging footer in `skills/projectpal/SKILL.md`:
  - generated-file warning
  - plugin packaging note
  - `.codex-plugin/plugin.json` pointer

- `.codex-plugin/plugin.json` metadata:
  - plugin identity
  - display metadata
  - default prompt triggers
  - skill and MCP paths

## Planned adapter responsibility

The Codex adapter should own only:
- skill wrapper frontmatter
- Codex invocation guidance
- plugin/package metadata
- generated-file packaging notes

These adapter-owned snippets now live in:
- `src/adapters/codex-skill-header.md`
- `src/adapters/codex-skill-footer.md`

The shared ProjectPal behavior should come from `src/shared/layer0.md`.

## Minimum wrapper conclusion

Codex needs a real wrapper boundary, but only around packaging and invocation context. The product behavior itself should not be authored here.

## Canonical entrypoint decision

Use `ProjectPal` as the canonical Codex entrypoint.

Reason:
- it matches the plugin display name
- it avoids implying slash-command support that Codex does not guarantee
- it is simpler than maintaining multiple documented trigger phrases

## Lean v1 approval handoff

Codex owns the visible approval step when lean v1 needs a path switch.

- If fallback evaluation produces `approval_required = true`, Codex renders `request_approval` through the Pal before execution continues.
- The Pal in Codex is the only visible speaker for a path switch ask.
- The approval summary must name the changed path fields and the reason the candidate path is outside the approved boundary.
- Delegated adapters may return `approval_required = true`, but they must not prompt the user directly.

## Lean v1 reporting surface

Codex owns the visible reporting path for delegated work.

- `render_pal_update` is the Codex-side handoff that turns internal result data into user-facing output.
- Same-path fallback disclosure belongs in the next natural summary, not as a separate delegated status message.
- Internal result payloads stay internal until the Pal renders them.
