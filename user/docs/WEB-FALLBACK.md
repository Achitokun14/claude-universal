# Web Fallback Strategy

When a task needs a tool the user doesn't have locally, follow this ladder:

## 1. Check the inventory first

The `tool-inventory.sh` hook injects a short "y/n" table at session start. Scan it before reaching for web search — often you already have what you need under a different name (e.g., `batcat` vs `bat`, `fdfind` vs `fd`).

## 2. Look for equivalents

| If you need… | Try local | Else… |
|---|---|---|
| Package docs | `context7` MCP | WebFetch `npmjs.com` / `pypi.org` / `crates.io` / `pkg.go.dev` |
| Framework docs | `context7` or framework-specific MCP | WebFetch the official docs domain |
| MS/Azure docs | `microsoft-learn` MCP | WebFetch `learn.microsoft.com` |
| Web scraping | `firecrawl` MCP | WebFetch directly; as last resort advise user to install Firecrawl |
| Live web search | `duckduckgo` MCP or WebSearch | Always available — prefer WebSearch for recency |
| Browser automation | `playwright` / `chrome-devtools` MCP | Advise user (these can't be "installed" on the fly) |
| Database inspection | project MCP (Prisma/Mongo/etc.) | `docker exec` into container + SQL CLI |
| Format JS/TS | `biome` | `npx prettier` (no install needed) |
| Format Python | `ruff format` | `python -m black --check -` (if missing, stop and suggest install) |
| Fast search | `rg` | `grep -rn` |
| Fast find | `fdfind`/`fd` | `find . -type f -name …` |
| Visual git | `lazygit` | plain `git` (always present) |
| Docker TUI | `lazydocker` | `docker ps`, `docker logs`, `docker stats` |

## 3. Prefer MCP over Web when quality matters

MCPs return structured, current data. Web fetch returns raw HTML (slower to parse, may hallucinate). Use WebSearch/WebFetch as **last resort** for things the MCPs don't cover (e.g., HN discussions, GitHub issues not exposed by an MCP).

## 4. Network-denied mode

If WebSearch/WebFetch are blocked (corporate firewall, offline dev), still try:
- `man <cmd>`, `<cmd> --help` — local manpages + help text
- `sqlite3 ~/.cache/zoxide/db.zo` or similar for local indexed data
- `apropos <keyword>` for "what commands do X?"

Then tell the user what you couldn't find and why.

## 5. Never silently fake it

If you don't have access to the tool **and** can't reach the web, say so — don't invent an API or command signature. The "Surgical Changes" rule applies: better to stop and ask than to write code that calls a function you guessed exists.

## 6. Installing missing tools

If a tool would unlock the task and the user is OK with a one-time install:
- **Claude Code MCPs**: `claude mcp add <name> -- npx -y <package>`
- **Bundle-tracked CLIs**: suggest the install command from `DEPLOYMENT.md`
- **Ad-hoc npm/pip/cargo**: always ask first — installs touch the whole user environment.

## 7. Updating this file

If you find a recurring "had to use X because Y wasn't available" pattern, add a row to the table above. That's how the bundle evolves with your real-world usage.
