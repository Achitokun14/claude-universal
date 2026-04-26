# Changelog

The full version history lives at [user/docs/CHANGELOG.md](user/docs/CHANGELOG.md). The latest 3 versions are mirrored below.

For all versions: see [user/docs/CHANGELOG.md](user/docs/CHANGELOG.md).

## [1.18.0] — 2026-04-26

### Added — one-command universal `./setup`

`./setup` is now the canonical entrypoint. Detects OS, pkg-manager, shell, and which AI CLIs are installed, then plans → confirms → installs → verifies. Idempotent (re-run = safe no-op when up-to-date), updateable (`--update`), reversible (`--uninstall`).

**New flags:**
`--dry-run` · `--yes` · `--update` · `--uninstall` · `--doctor` · `--with=NAME[,NAME]` · `--skip=STEP[,STEP]` · `--only=user` · `--version` · `--help`

**Architecture:**
- `setup.sh` (orchestrator, ~280 lines)
- `lib/{ui,detect,deps,plan,apply,verify}.sh` (single-purpose helpers)
- `VERSION` file as single source-of-truth
- Manifest at `~/.claude/.claude-universal-manifest.json` records install state for clean updates/uninstalls

### CI + tests
- `.github/workflows/lint.yml` — shellcheck, shfmt (advisory), secret-scan, path-leak-scan
- `.github/workflows/smoke.yml` — runs `./setup --version|--help|--doctor|--dry-run --yes` + `tests/smoke.sh` on Ubuntu + macOS
- `tests/smoke.sh` — 15-assertion smoke suite (15/15 passing)

### Fixed
- `notify-stop.sh` — cross-OS now (Linux notify-send / macOS osascript / Windows PowerShell), silently no-op if no notifier
- `skill-router.sh` — falls back to script-adjacent `skill-router.conf` if `~/.claude/hooks/skill-router.conf` is absent (lets fresh installs and tests work)
- Removed misleading TODO in `install-inspired.sh:183` (skills-selective falls through correctly to surface_skills)

### Cleanups
- `.shellcheckrc` + `.editorconfig` for consistent contributor formatting
- `install.sh` reads `VERSION` and supports `--version` + `--help`


## [1.17.0] — 2026-04-25

### Added — Obsidian + markitdown universal tools
- `obsidian` MCP wired into 6 coding agents (Claude · Codex · Goose · Gemini · Kimi · OpenCode), backed by `obsidian-mcp` (StevenStavrakis), default vault `~/Desktop/ACTIVITIES`
- `obsidian-cli` (Yakitrak/notesmd-cli v0.3.5) at `~/.local/bin/obsidian-cli`
- `markitdown` (Microsoft 0.1.5) at `~/.local/bin/markitdown` — PDF/DOCX/XLSX/PPTX/images/audio/HTML → MD
- `scripts/install-obsidian.sh`, `scripts/install-markitdown.sh`
- `user/docs/MCPS.md` — new "Universal MCPs always available" + "Universal CLI tools" sections

## [1.16.0] — 2026-04-25

### Added — skill-router hook (token-thrifty auto-suggest)
- `~/.claude/hooks/skill-router.sh` — UserPromptSubmit hook scanning prompts against curated keyword→skill map
- 0 tokens when no trigger fires; ≤80 tokens cap when triggers match (vs ~300 always-on for BASE-style)
- 37 curated triggers covering planning · research · debug · TDD · browser · frontend · backend · ops · git · memory
- Editable `skill-router.conf`, reloaded each prompt
- Dedup via sha1 of last hint set — repeat prompts emit nothing

## [1.15.1] — 2026-04-24

### Project fan-out
- Ran `install.sh project <path>` against all 22 Claude-managed projects on the host machine
- Per-project: managed CLAUDE.md block, settings.json deep-merge, AGENTS.md symlink, hook examples, .gitignore append
- User-scope artifacts (skills, MCPs, plugins) stay at `~/.claude/`; auto-apply to every project

---

For releases prior to 1.15.1, see [user/docs/CHANGELOG.md](user/docs/CHANGELOG.md).
