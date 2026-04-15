# Contributing to ProjectPal

Thanks for contributing. This guide gets you from a fresh clone to a working dev environment.

---

## Prerequisites

These are already present on most Linux/WSL environments (confirmed on Amazon Linux 2023, Ubuntu):

- **git** — `git --version`
- **bash** — `bash --version`
- **python3** — `python3 --version`

You also need **Node 20+** and **pnpm**. Install them your way:

### Node 20+

Pick whichever fits your setup:

```sh
# nvm (recommended for contributors who manage multiple Node versions)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
nvm install 20 && nvm use 20

# fnm (faster alternative to nvm)
curl -fsSL https://fnm.vercel.app/install | bash
fnm install 20 && fnm use 20

# volta (pins versions per project)
curl https://get.volta.sh | bash
volta install node@20

# system package — Ubuntu/Debian
sudo apt install -y nodejs npm

# system package — Amazon Linux / Fedora
sudo dnf install -y nodejs npm
```

A `.nvmrc` file at the repo root pins Node 20. If you use nvm or fnm, running `nvm use` or `fnm use` in the repo directory picks it up automatically.

### pnpm

pnpm ships with Node 16+ via corepack — no separate install needed:

```sh
corepack enable
```

---

## Quick start

```sh
git clone https://github.com/rafiti052/projectpal.git
cd projectpal

# install Node 20+ your way (see above), then:
corepack enable
pnpm install
```

Verify the setup:

```sh
pnpm typecheck   # should exit 0 with no errors
pnpm test        # should pass 5/5 thread isolation tests
```

### Want a single command instead?

`scripts/setup-dev.sh` is an opinionated shortcut that installs nvm → Node 20 → pnpm and runs `pnpm install` for you. It's one path, not a requirement:

```sh
sh scripts/setup-dev.sh
```

---

## Available commands

| Command | What it does |
|---------|-------------|
| `pnpm typecheck` | TypeScript type check — zero errors expected |
| `pnpm test` | Thread isolation tests via vitest |
| `pnpm layer0` | Layer 0 parity check against fixture files |
| `pnpm tsx scripts/layer0-check.ts` | Layer 0 check against live state and routing files |

---

## End-user install

If you just want to use ProjectPal (not develop on it), Node is not required:

```sh
sh install-projectpal.sh
```

This works on macOS, Linux, and WSL out of the box — it uses only bash and python3.

---

## Branch and commit conventions

**Branches:**
```
feat/<short-slug>
fix/<short-slug>
```

**Commits:** imperative subject line, prefixed by type:
```
feat: add gemini adapter with heartbeat
fix: correct sed -i portability on linux
```

For AI-assisted commits, add a co-author line:
```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## Reporting issues

Open an issue at [github.com/rafiti052/projectpal/issues](https://github.com/rafiti052/projectpal/issues).
