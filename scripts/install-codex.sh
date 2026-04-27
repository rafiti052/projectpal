#!/bin/sh
# Manage the generated Codex runtime surface from build/codex/ into Codex.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/.."

BUILD_DIR="$SCRIPT_DIR/../build/codex"
SKILL_DIR="$HOME/.codex/skills/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"

usage() {
  cat <<'EOF'
usage:
  sh scripts/install-codex.sh [install|update|uninstall|validate]
EOF
}

command=${1:-install}

case "$command" in
  install|update)
    if [ ! -f "$BUILD_DIR/AGENTS.md" ] || [ ! -f "$BUILD_DIR/skills/projectpal/SKILL.md" ] || [ ! -f "$BUILD_DIR/.codex-plugin/plugin.json" ]; then
      sh scripts/build-platform.sh codex >/dev/null
    fi

    if [ ! -f "$BUILD_DIR/AGENTS.md" ] || [ ! -f "$BUILD_DIR/skills/projectpal/SKILL.md" ] || [ ! -f "$BUILD_DIR/.codex-plugin/plugin.json" ]; then
      printf '%s\n' "install-codex: missing build/codex outputs; build failed (tried scripts/build-platform.sh codex)" >&2
      exit 1
    fi

    mkdir -p "$SKILL_DIR"
    cp "$BUILD_DIR/skills/projectpal/SKILL.md" "$SKILL_FILE"

    printf '%s\n' "Installed generated Codex runtime surface -> $SKILL_FILE"
    ;;
  uninstall)
    rm -f "$SKILL_FILE"
    rmdir "$SKILL_DIR" 2>/dev/null || true

    printf '%s\n' "Uninstalled Codex runtime surface from $SKILL_FILE"
    ;;
  validate)
    if [ ! -f "$BUILD_DIR/AGENTS.md" ] || [ ! -f "$BUILD_DIR/skills/projectpal/SKILL.md" ] || [ ! -f "$BUILD_DIR/.codex-plugin/plugin.json" ]; then
      printf '%s\n' "install-codex: build/codex is incomplete; run scripts/build-platform.sh codex first" >&2
      exit 1
    fi

    printf '%s\n' "Validated Codex build artifacts -> $BUILD_DIR"
    ;;
  -h|--help)
    usage
    ;;
  *)
    printf '%s\n' "install-codex: unknown command '$command'" >&2
    usage >&2
    exit 1
    ;;
esac
