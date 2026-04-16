#!/bin/sh
# Install the ProjectPal Cursor registration into ~/.cursor/mcp.json.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT="$SCRIPT_DIR/.."
cd "$REPO_ROOT"
CURSOR_DIR="$HOME/.cursor"
MCP_FILE="$CURSOR_DIR/mcp.json"
INSTALL_ROOT="$CURSOR_DIR/projectpal"
PACKAGE_SRC="$REPO_ROOT/build/cursor/cursor-mcp"
PACKAGE_DST="$INSTALL_ROOT/cursor-mcp"
RULES_DST="$INSTALL_ROOT/rules"

mkdir -p "$CURSOR_DIR" "$PACKAGE_DST/bin" "$RULES_DST"

cp "$PACKAGE_SRC/package.json" "$PACKAGE_DST/package.json"
cp "$PACKAGE_SRC/bin/projectpal-cursor-mcp" "$PACKAGE_DST/bin/projectpal-cursor-mcp"
chmod +x "$PACKAGE_DST/bin/projectpal-cursor-mcp"
cp "$REPO_ROOT/build/cursor/.cursor/rules/projectpal.md" "$RULES_DST/projectpal.md"

MCP_FILE="$MCP_FILE" PROJECTPAL_INSTALL_ROOT="$INSTALL_ROOT" python3 <<'PY'
import json
import os
from pathlib import Path

mcp_path = Path(os.environ["MCP_FILE"])
install_root = Path(os.environ["PROJECTPAL_INSTALL_ROOT"])
launcher_path = install_root / "cursor-mcp" / "bin" / "projectpal-cursor-mcp"
rules_path = install_root / "rules" / "projectpal.md"

data = {}
if mcp_path.exists():
    raw = mcp_path.read_text()
    if raw.strip():
        data = json.loads(raw)

if not isinstance(data, dict):
    data = {}

data["connector"] = "cursor"
data["version"] = 1
data.setdefault("routing_rules", [])

mcp_servers = data.setdefault("mcpServers", {})
if not isinstance(mcp_servers, dict):
    mcp_servers = {}
    data["mcpServers"] = mcp_servers

mcp_servers["projectpal"] = {
    "connector": "cursor",
    "version": 1,
    "routing_rules": [],
    "installed_artifact_root": str(install_root),
    "launcher_path": str(launcher_path),
    "rules_path": str(rules_path),
}

mcp_path.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "Installed Cursor ProjectPal registration -> $MCP_FILE"
