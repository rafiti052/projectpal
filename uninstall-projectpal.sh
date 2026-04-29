#!/bin/sh
# Uninstall ProjectPal from all supported assistants.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
usage:
  sh uninstall-projectpal.sh

Removes ProjectPal assets installed for Claude Code, Codex, and Cursor.
Also clears the primary assistant hint at ~/.projectpal/primary-assistant.
EOF
  exit 0
fi

sh "$SCRIPT_DIR/scripts/install-claude.sh" uninstall
printf '%s\n' "✓ Claude Code — ProjectPal assets removed."

sh "$SCRIPT_DIR/scripts/install-codex.sh" uninstall
printf '%s\n' "✓ Codex — ProjectPal assets removed."

sh "$SCRIPT_DIR/scripts/install-cursor.sh" uninstall
printf '%s\n' "✓ Cursor — ProjectPal assets removed."

PRIMARY_HINT="$HOME/.projectpal/primary-assistant"
if [ -f "$PRIMARY_HINT" ]; then
  rm -f "$PRIMARY_HINT"
  printf '%s\n' "Cleared ProjectPal primary assistant hint."
fi

rmdir "$HOME/.projectpal" 2>/dev/null || true

printf '\n%s\n' "ProjectPal uninstall completed."
