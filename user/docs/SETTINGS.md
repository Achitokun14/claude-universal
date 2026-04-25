# Settings Reference

How `~/.claude/settings.json` is structured in this bundle, and what each section does.

## Top-level fields

| Field | Value | Why |
|-------|-------|-----|
| `alwaysThinkingEnabled` | `true` | Extended thinking on every response — worth the tokens for your complexity level. |
| `effortLevel` | `"high"` | Opus/Sonnet runs at max effort. |
| `autoUpdatesChannel` | `"latest"` | Track current stable Claude Code releases. |
| `minimumVersion` | `"2.1.11"` | Floor for hook format compatibility. |

## `permissions`

Three-tier model. Later scopes (project > user) override earlier ones. `deny` always wins.

### `defaultMode: "plan"`
Every session starts in plan mode — matches your habit of planning multi-file changes before touching them.

### `allow` — runs silently (~80 patterns)
Reads (`ls`, `cat`, `grep`, `find`, modern tools `bat`, `eza`, `fd`, `rg`, `jq`), git reads (`status`, `diff`, `log`, `show`), package reads (`npm list`, `pip show`), builds/tests/lints across JS/TS/Python/Rust/Go, and WebFetch whitelisted to docs domains + WebSearch.

### `deny` — hard-blocked (19 patterns)
Fork bombs, `rm -rf /`, `rm -rf ~`, `sudo rm -rf`, `mkfs*`, `dd if=*`, writes to `/dev/sda*` or `/dev/nvme*`, `chmod 777 /`, pipe-to-shell installers.

### `ask` — prompts for approval (25 patterns)
Anything that leaves your machine or changes state permanently: `git push*`, `git reset --hard`, `git rebase`, `git clean -fd`, all `docker`/`docker-compose`, `sudo*`, `rm*`, `mv*`, publish commands, `kubectl delete`, `terraform apply/destroy`, deploy commands.

## `hooks`

Five hook entries wired to scripts in `~/.claude/hooks/`. See [HOOKS.md](./HOOKS.md).

## `enabledPlugins`

30 curated plugins. See [PLUGINS.md](./PLUGINS.md).

## Customizing

### Add a command to `allow`
```bash
# In ~/.claude/settings.json
"allow": [
  ...,
  "Bash(my-custom-tool:*)"
]
```

### Move something from `allow` to `ask`
Just move the line. No restart needed — Claude re-reads settings each tool call.

### Project-level overrides
Put narrower allows in `<repo>/.claude/settings.json`. They merge on top of user settings.

### Machine-specific overrides
Use `~/.claude/settings.local.json` — same shape, not tracked in the bundle.

## Backup & restore

The installer writes `settings.json.bak.YYYYMMDD_HHMMSS` before any change. Restore:
```bash
cp ~/.claude/settings.json.bak.20260418_171705 ~/.claude/settings.json
```
