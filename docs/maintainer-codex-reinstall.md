# Maintainer Codex Reinstall

Use this when you need to verify the shipped Codex package from a fresh build instead of relying on the legacy generated repo-root skill.

## Canonical Codex artifact

The generated Codex package lives under `build/codex/`:

- `build/codex/AGENTS.md`
- `build/codex/skills/projectpal/SKILL.md`
- `build/codex/.codex-plugin/plugin.json`

The repo-local wrapper at `.codex-plugin/plugin.json` now points at `build/codex/skills/` so the checked-out repo and the packaged artifact use the same Codex skill path.

## Rebuild

```bash
sh scripts/build-platform.sh codex
sh scripts/install-codex.sh validate
```

## Install into Codex

```bash
sh scripts/install-codex.sh install
```

That copies `build/codex/skills/projectpal/SKILL.md` into `~/.codex/skills/projectpal/SKILL.md`.

## Smoke validation

Run both checks from the repo root:

```bash
sh tests/smoke/codex-build.sh
sh scripts/smoke-install.sh
```

`tests/smoke/codex-build.sh` verifies the built package and repo-local wrapper paths. `scripts/smoke-install.sh` exercises install flows in a clean temporary home/repo.
