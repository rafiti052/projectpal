---
project: projectpal
type: ticket
status: ready
created: 2026-04-15
title: Additional routed connectors (OpenAI, Anthropic, …)
---

## Goal

Ship connector adapters and routing entries beyond Gemini so role-based delegation can target OpenAI- and Anthropic-class APIs (and any other approved backends) with the same approval gate, availability fallback, and `primary` floor behavior already defined for Gemini.

## Acceptance

- At least one new connector has a TypeScript adapter, schema entry in `routing.yml`, and registration in the default adapter bootstrap.
- `routing.yml` / docs describe how operators approve and configure the new connector without hand-editing secrets into the repo.
- Integration or unit coverage proves the adapter returns structured `DelegationResult` on success and availability-class failures on missing auth / quota / transport errors.

## Notes

- Keep ranking edits in the post-setup config flow (parking lot: `connector-config-flow`); this ticket is about **execution backends**, not wizard UX.
