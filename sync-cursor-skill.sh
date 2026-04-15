#!/bin/sh
# Install the ProjectPal Cursor registration into ~/.cursor/mcp.json.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
CURSOR_DIR="$HOME/.cursor"
MCP_FILE="$CURSOR_DIR/mcp.json"

mkdir -p "$CURSOR_DIR"

MCP_FILE="$MCP_FILE" PROJECTPAL_REPO_ROOT="$SCRIPT_DIR" python3 <<'PY'
import json
import os
from pathlib import Path

mcp_path = Path(os.environ["MCP_FILE"])
repo_root = os.environ["PROJECTPAL_REPO_ROOT"]

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
    "source_repo": repo_root,
    "skill_entrypoint": "ProjectPal",
    "rules_template": "templates/cursor-rules-projectpal.md",
}

mcp_path.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "Installed Cursor ProjectPal registration -> $MCP_FILE"
