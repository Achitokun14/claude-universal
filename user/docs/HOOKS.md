# Hooks

Lifecycle scripts that enforce rules automatically. Installed at `~/.claude/hooks/` and wired in `settings.json` under `"hooks"`.

## Event types (all supported)

| Event | When it fires | Typical use |
|-------|--------------|-------------|
| `PreToolUse` | Before Claude invokes a tool | Block / approve actions |
| `PostToolUse` | After tool succeeds | Post-processing (format, lint, notify) |
| `UserPromptSubmit` | User hits Enter | Inject context |
| `Stop` | Claude finishes responding | Notifications |
| `SessionStart` | New session begins | Load project state |
| `SubagentStop` | Spawned agent completes | Logging |
| `Notification` | Claude raises a notification | Custom routing |

## Bundle hooks (user scope)

| File | Event | Matcher | Purpose | Exit codes |
|------|-------|---------|---------|-----------|
| `block-ai-attribution.sh` | `PreToolUse` | `Bash` | Block `git commit` with Co-Authored-By / 🤖 / "Generated with Claude Code" | 0 pass · 2 block |
| `block-secret-writes.sh` | `PreToolUse` | `Write\|Edit\|MultiEdit` | Block writes to `.env*` / `*.key` / `*.pem` / `.credentials.json` / `.ssh/*` | 0 pass · 2 block |
| `auto-format.sh` | `PostToolUse` | `Edit\|Write\|MultiEdit` | Run `biome` / `ruff` / `rustfmt` / `gofmt` on touched file | 0 always (never blocks) |
| `notify-stop.sh` | `Stop` | (any) | `notify-send` desktop ping when Claude finishes | 0 |
| `session-context.sh` | `SessionStart` | `startup\|resume` | Inject branch, dirty count, last 3 commits | 0 |

## Input format

Hooks receive JSON on stdin:
```json
{
  "session_id": "...",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "git commit -m 'feat: x'" },
  "cwd": "/path/to/cwd",
  "transcript_path": "..."
}
```

Parse with `jq`:
```bash
command="$(echo "$payload" | jq -r '.tool_input.command // ""')"
```

## Output / exit codes

| Exit | Meaning | Where stderr goes |
|------|---------|-------------------|
| `0` | Pass — no action | Hidden from Claude (debug) |
| `1` | Non-blocking error | Logged |
| `2` | **Block** the action | Fed back to Claude as feedback |

Print to stderr what Claude should hear, then `exit 2`.

## Dependencies

- **`jq`** required (all hooks parse stdin JSON). Install: `sudo apt install jq`.
- **`notify-send`** for `notify-stop.sh` (from `libnotify-bin`, already installed on GNOME/KDE).

## Disabling a hook

Two ways:

1. **Remove from settings** — edit `~/.claude/settings.json` and delete the hook block.
2. **Unexecutable** — `chmod -x ~/.claude/hooks/block-ai-attribution.sh` (hooks need execute bit).

## Adding your own

1. Create `~/.claude/hooks/my-hook.sh`, make it executable.
2. Add to `settings.json` under `"hooks"`:
   ```json
   "PreToolUse": [
     {
       "matcher": "Bash",
       "hooks": [{ "type": "command", "command": "~/.claude/hooks/my-hook.sh" }]
     }
   ]
   ```
3. Start a new session — settings reload on session start.

## Project-level hooks

`<repo>/.claude/hooks/*.sh` — use `${CLAUDE_PROJECT_DIR}` for portable paths:
```json
"command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/run-tests-before-commit.sh"
```

## Debugging

```bash
# Simulate a hook call
echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m '\''feat: x\n\nCo-Authored-By: Claude'\''"}}' \
  | ~/.claude/hooks/block-ai-attribution.sh
echo "exit=$?"
```

Exit 2 = working.
