#!/bin/sh
# Install ProjectPal for all supported assistants.
# Installs a baseline config everywhere, then asks which assistant is your primary.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'EOF'
usage:
  sh install-projectpal.sh

Installs ProjectPal for all supported assistants (Claude Code and Codex).
You will be asked which one is your primary — it gets the full setup.
All others get a basic config so /projectpal is callable everywhere.
EOF
  exit 0
fi

# ── Step 1: Generate all runtime surfaces from source ───────────────────────

if ! sh "$SCRIPT_DIR/sync-codex-plugin.sh"; then
  printf '\n%s\n' "install-projectpal: sync-codex-plugin.sh reported divergence — see above." >&2
  printf '%s\n' "Resolve the divergence and re-run install-projectpal.sh." >&2
  exit 1
fi

# ── Step 2: Install global skill for all assistants ─────────────────────────

sh "$SCRIPT_DIR/sync-claude-skill.sh"
printf '%s\n' "✓ Claude Code — basic config installed."

sh "$SCRIPT_DIR/sync-codex-skill.sh"
printf '%s\n' "✓ Codex — basic config installed."

# ── Step 3: Primary assistant selection ─────────────────────────────────────

is_interactive_stdin() {
  [ -t 0 ]
}

prompt_primary() {
  printf '\n%s\n' "Which assistant is your primary? (Enter to skip — ProjectPal will detect it on first use.)" >&2
  printf '%s\n' "  1. Claude Code" >&2
  printf '%s\n' "  2. Codex" >&2
  printf '%s' "> " >&2
  IFS= read -r answer || printf '%s\n' ""
  case "${answer:-}" in
    1|claude|Claude|CLAUDE) printf '%s\n' "claude" ;;
    2|codex|Codex|CODEX)   printf '%s\n' "codex" ;;
    *)                      printf '%s\n' "deferred" ;;
  esac
}

if is_interactive_stdin; then
  primary=$(prompt_primary)
else
  primary="deferred"
fi

mkdir -p "$HOME/.projectpal"
printf '%s\n' "$primary" > "$HOME/.projectpal/primary-assistant"

# ── Step 4: Completion messages ──────────────────────────────────────────────

case "$primary" in
  claude)
    printf '\n%s\n' "ProjectPal is ready. Claude Code is your primary — open it in any repo and run /projectpal."
    printf '%s\n'   "Codex — basic config ready. /projectpal is callable in any repo."
    printf '%s\n'   "To unlock full features in Codex, ProjectPal will prompt you inline when it detects missing setup."
    ;;
  codex)
    printf '\n%s\n' "ProjectPal is ready. Codex is your primary — open it in your repo and type ProjectPal."
    printf '%s\n'   "Claude Code — basic config ready. /projectpal is callable in any repo."
    printf '%s\n'   "To unlock full features in Claude Code, ProjectPal will prompt you inline when it detects missing setup."
    ;;
  deferred)
    printf '\n%s\n' "ProjectPal is ready in both assistants. Open either one and ProjectPal will detect your preference on first use."
    ;;
esac

printf '\n'
