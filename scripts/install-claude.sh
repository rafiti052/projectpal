#!/bin/sh
# Manage the generated Claude runtime surface from build/claude/ into Claude Code.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR/.."

BUILD_DIR="$SCRIPT_DIR/../build/claude"
SKILL_DIR="$HOME/.claude/skills/projectpal"
HOOK_DIR="$HOME/.claude/hooks/projectpal"
SKILL_FILE="$SKILL_DIR/SKILL.md"
HOOK_FILE="$HOOK_DIR/pp-compress"

usage() {
  cat <<'EOF'
usage:
  sh scripts/install-claude.sh [install|update|uninstall|validate]
EOF
}

command=${1:-install}

case "$command" in
  install|update)
    if [ ! -f "$BUILD_DIR/skills/projectpal/SKILL.md" ] || [ ! -f "$BUILD_DIR/hooks/pp-compress" ]; then
      sh scripts/build-platform.sh claude >/dev/null
    fi

    if [ ! -f "$BUILD_DIR/skills/projectpal/SKILL.md" ] || [ ! -f "$BUILD_DIR/hooks/pp-compress" ]; then
      printf '%s\n' "install-claude: missing build/claude outputs; build failed (tried scripts/build-platform.sh claude)" >&2
      exit 1
    fi

    mkdir -p "$SKILL_DIR" "$HOOK_DIR"

    cp "$BUILD_DIR/skills/projectpal/SKILL.md" "$SKILL_FILE"
    cp "$BUILD_DIR/hooks/pp-compress" "$HOOK_FILE"

    printf '%s\n' "Installed generated Claude runtime surface -> $SKILL_FILE"
    printf '%s\n' "Installed Claude hook -> $HOOK_FILE"
    ;;
  uninstall)
    rm -f "$SKILL_FILE" "$HOOK_FILE"
    rmdir "$SKILL_DIR" "$HOOK_DIR" 2>/dev/null || true

    printf '%s\n' "Uninstalled Claude runtime surface from $SKILL_FILE"
    printf '%s\n' "Uninstalled Claude hook from $HOOK_FILE"
    ;;
  validate)
    if [ ! -f "$BUILD_DIR/CLAUDE.md" ] || [ ! -f "$BUILD_DIR/skills/projectpal/SKILL.md" ] || [ ! -f "$BUILD_DIR/hooks/pp-compress" ]; then
      printf '%s\n' "install-claude: build/claude is incomplete; run scripts/build-platform.sh claude first" >&2
      exit 1
    fi

    printf '%s\n' "Validated Claude build artifacts -> $BUILD_DIR"
    ;;
  -h|--help)
    usage
    ;;
  *)
    printf '%s\n' "install-claude: unknown command '$command'" >&2
    usage >&2
    exit 1
    ;;
esac
