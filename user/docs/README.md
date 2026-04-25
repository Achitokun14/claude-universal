# Docs Index

Reference material that lives at `~/.claude/docs/` after install. Keep concise — update the relevant file + `CHANGELOG.md` whenever the bundle changes.

| File | What |
|------|------|
| [CHANGELOG.md](./CHANGELOG.md) | Semver history of bundle changes |
| [RULES.md](./RULES.md) | Canonical behavioral / commit / secret / destructive-action rules |
| [SETTINGS.md](./SETTINGS.md) | Everything in `settings.json` — permissions, plugins, tiers |
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Install, upgrade, roll back, sync across machines |
| [HOOKS.md](./HOOKS.md) | Lifecycle hook reference + how to add your own |
| [MCPS.md](./MCPS.md) | MCP server catalog + management |
| [SKILLS.md](./SKILLS.md) | Skill format, loading, sources |
| [ACPS.md](./ACPS.md) | Editor integrations (Zed, JetBrains, Neovim, Emacs, Toad) |
| [PLUGINS.md](./PLUGINS.md) | Enabled plugins + marketplaces |
| [AGENTS.md](./AGENTS.md) | Subagents (Agent tool) |
| [COMMANDS.md](./COMMANDS.md) | Slash commands |
| [WEB-FALLBACK.md](./WEB-FALLBACK.md) | What to do when a local tool is missing (ladder: project MCP → user MCP → CLI → web → ask) |

## Keeping these current

When you change the bundle:
1. Edit the relevant doc here (not the installer README — that stays user-facing).
2. Add a dated entry in `CHANGELOG.md` under `## [Unreleased]`.
3. Rerun `./install.sh user` to sync docs into `~/.claude/docs/`.
4. When you cut a version, rename `## [Unreleased]` → `## [X.Y.Z] — YYYY-MM-DD` in `CHANGELOG.md`.
