#!/usr/bin/env bash
# scripts/setup-dev.sh — ProjectPal dev setup (one opinionated path).
# See CONTRIBUTING.md for alternatives if you already have Node or prefer a different version manager.
#
# What this script does:
#   1. Installs nvm (if not already present)
#   2. Installs Node 20 LTS via nvm
#   3. Enables pnpm via corepack
#   4. Runs pnpm install
#   5. Runs pnpm typecheck as a smoke test
#
# Safe to re-run — all steps are idempotent.

set -euo pipefail

NVM_VERSION="v0.40.0"
NODE_VERSION="20"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# ── Safety: refuse to run as root ─────────────────────────────────────────

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "setup-dev.sh: do not run as root. Run as a regular user." >&2
  echo "See CONTRIBUTING.md for manual setup steps." >&2
  exit 1
fi

# ── Header ─────────────────────────────────────────────────────────────────

echo ""
echo "ProjectPal dev setup — one opinionated path."
echo "See CONTRIBUTING.md for alternatives."
echo ""

# ── Detect OS ──────────────────────────────────────────────────────────────

detect_os() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  elif [ "$(uname)" = "Darwin" ]; then
    echo "macos"
  else
    echo "linux"
  fi
}

OS=$(detect_os)
echo "Detected: $OS"
echo ""

# ── Step 1: Install nvm ────────────────────────────────────────────────────

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -s "$NVM_DIR/nvm.sh" ]; then
  echo "✓ nvm already installed at $NVM_DIR"
else
  echo "Installing nvm $NVM_VERSION ..."
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
  echo "✓ nvm installed"
fi

# Source nvm into this session
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"

# ── Step 2: Install and use Node 20 ───────────────────────────────────────

echo ""
echo "Installing Node $NODE_VERSION LTS ..."
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
echo "✓ Node $(node --version)"

# ── Step 3: Enable pnpm via corepack ──────────────────────────────────────

echo ""
echo "Enabling pnpm via corepack ..."
corepack enable
echo "✓ pnpm $(pnpm --version)"

# ── Step 4: pnpm install ──────────────────────────────────────────────────

echo ""
echo "Installing dependencies ..."
cd "$REPO_ROOT"
pnpm install
echo "✓ dependencies installed"

# ── Step 5: Smoke test ────────────────────────────────────────────────────

echo ""
echo "Running typecheck ..."
if pnpm typecheck; then
  TYPECHECK_RESULT="✓ pass"
else
  TYPECHECK_RESULT="✗ fail — run 'pnpm typecheck' to see errors"
fi

# ── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup complete"
echo "  Node:       $(node --version)"
echo "  pnpm:       $(pnpm --version)"
echo "  typecheck:  $TYPECHECK_RESULT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  pnpm test        # run thread isolation tests"
echo "  pnpm check:install --fixture  # install parity (fixture mode, matches release gate)"
echo ""
