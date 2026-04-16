#!/bin/sh
# Install generated host artifacts from build/<host>/ into a target HOME and repo.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TARGET_HOME=${HOME:-}
TARGET_REPO="$ROOT_DIR"
HOST_ARGS=''

usage() {
  cat <<'EOF'
usage:
  sh scripts/install-local.sh [all|claude|codex|cursor ...] [--home DIR] [--repo DIR]
EOF
}

add_host() {
  host=$1
  if [ -z "$HOST_ARGS" ]; then
    HOST_ARGS=$host
  else
    HOST_ARGS="$HOST_ARGS $host"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    all|claude|codex|cursor)
      add_host "$1"
      shift
      ;;
    --home)
      TARGET_HOME=$2
      shift 2
      ;;
    --repo)
      TARGET_REPO=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf '%s\n' "install-local: unknown argument '$1'" >&2
      exit 1
      ;;
  esac
done

if [ -z "$TARGET_HOME" ]; then
  printf '%s\n' "install-local: HOME is not set and --home was not provided" >&2
  exit 1
fi

if [ -z "$HOST_ARGS" ]; then
  HOST_ARGS='all'
fi

sh "$ROOT_DIR/scripts/build-platform.sh" $HOST_ARGS >/dev/null

install_claude() {
  skill_dir="$TARGET_HOME/.claude/skills/projectpal"
  hook_dir="$TARGET_HOME/.claude/hooks/projectpal"

  mkdir -p "$skill_dir" "$hook_dir"
  cp "$ROOT_DIR/build/claude/skills/projectpal/SKILL.md" "$skill_dir/SKILL.md"
  cp "$ROOT_DIR/build/claude/hooks/pp-compress" "$hook_dir/pp-compress"
}

install_codex() {
  skill_dir="$TARGET_HOME/.codex/skills/projectpal"

  mkdir -p "$skill_dir"
  cp "$ROOT_DIR/build/codex/skills/projectpal/SKILL.md" "$skill_dir/SKILL.md"
}

install_cursor() {
  cursor_dir="$TARGET_HOME/.cursor"
  rules_dir="$TARGET_REPO/.cursor/rules"

  mkdir -p "$cursor_dir" "$rules_dir"

  BUILD_FILE="$ROOT_DIR/build/cursor/mcp.json" TARGET_FILE="$cursor_dir/mcp.json" python3 <<'PY'
from pathlib import Path
import json
import os

build_file = Path(os.environ["BUILD_FILE"])
target_file = Path(os.environ["TARGET_FILE"])

build_data = json.loads(build_file.read_text())
entry = build_data.get("mcpServers", {}).get("projectpal")

current = {}
if target_file.exists():
  raw = target_file.read_text().strip()
  if raw:
    current = json.loads(raw)

if not isinstance(current, dict):
  current = {}

current["connector"] = build_data.get("connector", "cursor")
current["version"] = build_data.get("version", 1)
current["routing_rules"] = build_data.get("routing_rules", [])

servers = current.get("mcpServers")
if not isinstance(servers, dict):
  servers = {}
current["mcpServers"] = servers
servers["projectpal"] = entry

target_file.write_text(json.dumps(current, indent=2) + "\n")
PY

  cp "$ROOT_DIR/build/cursor/.cursor/rules/projectpal.md" "$rules_dir/projectpal.md"
}

for host in $HOST_ARGS; do
  case "$host" in
    all)
      install_claude
      install_codex
      install_cursor
      ;;
    claude)
      install_claude
      ;;
    codex)
      install_codex
      ;;
    cursor)
      install_cursor
      ;;
  esac
done

printf '%s\n' "installed host artifacts from build/ into $TARGET_HOME"
