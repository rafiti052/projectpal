#!/bin/sh
# Generate host package roots from shared source plus host-owned adapter inputs.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

usage() {
  cat <<'EOF'
usage:
  sh scripts/build-platform.sh [all|claude|codex|cursor ...]
EOF
}

normalize_hosts() {
  if [ "$#" -eq 0 ]; then
    printf '%s\n' claude codex cursor
    return
  fi

  for host in "$@"; do
    case "$host" in
      all)
        printf '%s\n' claude codex cursor
        return
        ;;
      claude|codex|cursor)
        printf '%s\n' "$host"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf '%s\n' "build-platform: unknown host '$host'" >&2
        exit 1
        ;;
    esac
  done
}

render_shared_runtime() {
  output_file=$1

  cat "$ROOT_DIR/src/adapters/runtime-output-prefix.md" > "$output_file"
  printf '\n' >> "$output_file"
  cat "$ROOT_DIR/src/shared/core.md" >> "$output_file"
}

build_claude() {
  build_dir="$ROOT_DIR/build/claude"
  skill_dir="$build_dir/skills/projectpal"
  hook_dir="$build_dir/hooks"

  mkdir -p "$skill_dir" "$hook_dir"

  render_shared_runtime "$build_dir/CLAUDE.md"

  cat "$ROOT_DIR/platforms/claude/skill-header.md" > "$skill_dir/SKILL.md"
  printf '\n' >> "$skill_dir/SKILL.md"
  cat "$build_dir/CLAUDE.md" >> "$skill_dir/SKILL.md"
  printf '\n' >> "$skill_dir/SKILL.md"
  cat "$ROOT_DIR/platforms/claude/skill-footer.md" >> "$skill_dir/SKILL.md"

  cp "$ROOT_DIR/platforms/claude/hooks/pp-compress" "$hook_dir/pp-compress"
}

build_codex() {
  build_dir="$ROOT_DIR/build/codex"
  skill_dir="$build_dir/skills/projectpal"
  plugin_dir="$build_dir/.codex-plugin"

  mkdir -p "$skill_dir" "$plugin_dir"

  render_shared_runtime "$build_dir/AGENTS.md"

  cat "$ROOT_DIR/platforms/codex/skill-header.md" > "$skill_dir/SKILL.md"
  printf '\n' >> "$skill_dir/SKILL.md"
  cat "$build_dir/AGENTS.md" >> "$skill_dir/SKILL.md"

  cp "$ROOT_DIR/platforms/codex/plugin.json" "$plugin_dir/plugin.json"
}

build_cursor() {
  build_dir="$ROOT_DIR/build/cursor"
  rules_dir="$build_dir/.cursor/rules"

  mkdir -p "$rules_dir"

  cp "$ROOT_DIR/platforms/cursor/rules/projectpal.md" "$rules_dir/projectpal.md"

  BUILD_ROOT="$ROOT_DIR" python3 <<'PY'
from pathlib import Path
import os

root = Path(os.environ["BUILD_ROOT"])
template = root / "platforms" / "cursor" / "mcp.json.template"
output = root / "build" / "cursor" / "mcp.json"

content = template.read_text()
content = content.replace("__PROJECTPAL_REPO_ROOT__", str(root))
output.write_text(content)
PY
}

for host in $(normalize_hosts "$@"); do
  case "$host" in
    claude) build_claude ;;
    codex) build_codex ;;
    cursor) build_cursor ;;
  esac
  printf '%s\n' "built $host -> build/$host"
done
