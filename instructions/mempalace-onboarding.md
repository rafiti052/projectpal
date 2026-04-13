<!-- Ownership: Layer 1 MemPalace onboarding lives here; source text originates in CLAUDE.md and is loaded only when onboarding detail is needed. -->

# MemPalace Onboarding

### Onboarding Flow

**Step A — Explain.**

If a raw error appeared in the UI before this message, open with: *"That error above is just MemPalace not being connected — here's what that means..."*

Then present the canonical explanation, with case-specific opening:

- If the error suggests the tool is not in the tool set at all:
  > "Hey — before we start, one thing worth knowing: it looks like MemPalace isn't set up yet. MemPalace is my long-term memory layer. Without it, I can still help you today — but I won't remember anything next session. With it, I keep your decisions, past projects, and context across every conversation."

- If the tool is present but the call errored (server issue or misconfiguration):
  > "Hey — before we start, one thing worth knowing: it looks like MemPalace isn't connected in this session. MemPalace is my long-term memory layer. Without it, I can still help you today — but I won't remember anything next session. With it, I keep your decisions, past projects, and context across every conversation."

**Step B — Offer.**

> "Want me to set it up now, or continue without it for this session?"

Wait for user response before proceeding.

---

### Install Path (user chooses "set it up" — Case 1: never installed)

1. Run `pip install mempalace` via Bash tool.
2. If pip succeeds, register MemPalace with the assistant already chosen for this repo:
   - For Codex: run `codex mcp add mempalace -- python3 -m mempalace.mcp_server` via Bash tool.
   - For Claude Code: run `claude mcp add mempalace --command "python3 -m mempalace.mcp_server"` via Bash tool.
   - If the preferred assistant is still unknown, ask once, then use the matching command.
   - If `claude mcp add` fails or is unavailable: run `claude config get settingsDir` to discover the settings path. If a path is found, read the settings file at that path and add the entry below under `mcpServers`. If discovery or file write fails for any reason: go to Walkthrough.
     ```json
     "mempalace": {
       "type": "stdio",
       "command": "python3",
       "args": ["-m", "mempalace.mcp_server"]
     }
     ```
3. Confirm: *"Done — MemPalace is installed and registered. Restart your AI assistant, then start ProjectPal again."*
4. **Post-install guard**: `mempalace_available` stays `false` for the remainder of this session. All diary/drawer calls remain disabled. Do not proceed to Session Resumption. Session ends here — no project work until after restart.
5. If pip fails: surface the exact error, then go to Walkthrough.

**Walkthrough (final fallback for any failure):**

Present steps one at a time, waiting for confirmation after each:
1. *"Run this in your terminal: `pip install mempalace`"*
2. *"Then register MemPalace with your AI assistant. For Codex: `codex mcp add mempalace -- python3 -m mempalace.mcp_server`. For Claude Code: `claude mcp add mempalace --command 'python3 -m mempalace.mcp_server'`"*
3. *"Restart your AI assistant, then start ProjectPal again."*

---

### Reconnect Path (user chooses "set it up" — Case 2: installed but not connected)

Do not attempt reinstall.

1. Register MemPalace with the assistant already chosen for this repo.
   - For Codex: run `codex mcp add mempalace -- python3 -m mempalace.mcp_server` via Bash tool.
   - For Claude Code: run `claude mcp add mempalace --command "python3 -m mempalace.mcp_server"` via Bash tool.
   - If the preferred assistant is still unknown, ask once, then use the matching command.
   - If it succeeds: *"MemPalace is connected again. Restart your AI assistant, then start ProjectPal again."*
   - If it fails: walkthrough, one step at a time:
     1. *"Register MemPalace with your AI assistant. For Codex: `codex mcp add mempalace -- python3 -m mempalace.mcp_server`. For Claude Code: `claude mcp add mempalace --command 'python3 -m mempalace.mcp_server'`"*
     2. *"Restart your AI assistant, then start ProjectPal again."*

**Post-reconnect guard**: same as install — `mempalace_available` stays `false`, session ends here.

---

### Local-Only Path (user chooses "continue without")

- Respond: *"Got it — I'll keep notes locally this session, but they won't carry over."*
- Set `mempalace_available = false` for this session.
- Proceed to Session Resumption using `.projectpal/state.yml` only.
- All diary and drawer calls are disabled for this session (silently skipped).
