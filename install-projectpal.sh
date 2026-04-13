#!/bin/sh
# Install ProjectPal for one supported assistant runtime.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

usage() {
  cat <<'EOF'
usage:
  sh install-projectpal.sh [claude|codex]

If no assistant is provided, the installer prompts for one.
EOF
}

normalize_choice() {
  case "${1:-}" in
    1|claude|Claude|CLAUDE) printf '%s\n' "claude" ;;
    2|codex|Codex|CODEX) printf '%s\n' "codex" ;;
    *) printf '%s\n' "" ;;
  esac
}

prompt_for_choice() {
  printf '%s\n' "Choose an assistant to install ProjectPal for:" >&2
  printf '%s\n' "  1. Claude Code" >&2
  printf '%s\n' "  2. Codex" >&2
  printf '%s' "> " >&2
  IFS= read -r answer || exit 1
  normalize_choice "$answer"
}

is_interactive_stdin() {
  [ -t 0 ]
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

choice=$(normalize_choice "${1:-}")
if [ -z "$choice" ]; then
  if is_interactive_stdin; then
    choice=$(prompt_for_choice)
  else
    usage >&2
    printf '\n%s\n' "install-projectpal: assistant choice required when stdin is not interactive" >&2
    exit 1
  fi
fi

if [ -z "$choice" ]; then
  printf '%s\n' "install-projectpal: invalid assistant choice" >&2
  exit 1
fi

sh "$SCRIPT_DIR/sync-codex-plugin.sh"

case "$choice" in
  claude)
    sh "$SCRIPT_DIR/sync-claude-skill.sh"
    printf '\n%s\n' "ProjectPal is installed for Claude Code."
    printf '%s\n' "Next step: open Claude Code and run /projectpal."
    ;;
  codex)
    printf '\n%s\n' "ProjectPal is installed for Codex."
    printf '%s\n' "Next step: open Codex in the new or existing project repo and type ProjectPal."
    ;;
esac
