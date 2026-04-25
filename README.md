# claude-universal

> One portable bundle that brings 7 AI coding CLIs to feature-parity on your workstation, with safe defaults, idempotent installers, token-thrifty hooks, and a curated skill catalog. **Use any agent. Or all of them.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs: only via review](https://img.shields.io/badge/PRs-owner%20review-blue)](CONTRIBUTING.md)
[![Status: stable](https://img.shields.io/badge/status-stable-green)](#status)

## Why

If you use **Claude Code**, **Codex**, **Goose**, **Gemini CLI**, **Kimi**, **OpenCode**, or **Claw Code** — you're juggling per-CLI config files, separate skill libraries, mismatched MCP setups, and inconsistent hooks. This bundle:

- Ships **one source of truth** (`user/CLAUDE.md`, `user/hooks/`, etc.)
- Deploys to **each CLI's native config format** (no lowest-common-denominator translator)
- Adds **token-thrifty hooks** that suggest skills based on prompt intent (avg 0 tokens; cap 80)
- Wires **30+ MCPs** including Obsidian, Firecrawl, Chrome DevTools, Playwright, Lightpanda, Ghidra, Stripe, Sentry, Linear, Notion, GitHub, GitLab, Railway, Vercel — *once*, deployed everywhere
- Provides **idempotent installers** — run twice, never break
- Treats **secrets as a first-class concern** — none in this repo, gitignored templates explain how to store them locally

## Quick install

```bash
git clone https://github.com/Achitokun14/claude-universal.git
cd claude-universal
cp CREDS.md.template CREDS.md       # local-only, gitignored
cp SECRETS.md.template SECRETS.md   # local-only, gitignored
$EDITOR CREDS.md SECRETS.md         # fill in your env-var inventory

bash install.sh --dry-run user      # preview every change
bash install.sh user                # apply
```

See [QUICKSTART.md](QUICKSTART.md) for the 5-minute path including optional installers.

## What's included

### Per-CLI native deployment

| CLI | Skills | Commands | Hooks | MCPs | Custom providers |
|---|---|---|---|---|---|
| **Claude Code** | 358+ user-scope (catalog Tier-S/A surfaced) | 13 bundled | 11 hooks (post-tool, prompt, stop) | 25+ | — |
| **Codex** | 75+ symlinked from Claude | 13 mirrored | 11 hooks linked | TOML | — |
| **Goose** | 358 (already had — preserved) | — | hooks/ dir mirrored | 9+ MCPs | MiniMax planner |
| **Gemini CLI** | 60+ Tier-S/A linked | 13 ported | first-party hook migration | 5+ | — |
| **Kimi** | — (no skill concept) | — | — | 6+ MCPs | MiniMax + Ollama-cloud TOML |
| **OpenCode** | — | 13 as native agents | — | 41 MCPs | MiniMax + Ollama-cloud |
| **Claw Code** | env-var aggregator router | — | — | — | aggregator routing via `CLAW_API_*` |

### Token-thrifty skill router

`user/hooks/skill-router.sh` runs on every prompt. Most prompts → 0 tokens. Triggered prompts → ≤80 tokens with one-line skill pointers. Compare to BASE-style always-on injection (~300 tokens *every* prompt — 70-100% saving per turn).

Curated `skill-router.conf` covers ~37 high-leverage triggers across:
planning · brainstorm · research · debug · TDD · e2e · browser-automation · frontend (Next.js/React/Tailwind) · backend (NestJS/Go/Postgres) · ops (Railway/Docker/GitHub) · git · memory · skill-creation.

Edit `skill-router.conf` to tune; reloaded each prompt, no restart needed.

### Curated MCPs

```
obsidian          firecrawl         chrome-devtools-mcp   playwright
lightpanda        ghidra            browserbase           context7
serena            stripe            sentry                linear
notion            github            gitlab                railway
vercel            posthog           postman               adspirer
revenuecat        sonatype-guide    microsoft-learn       mintlify
prisma            planetscale       svelte                next-devtools
duckduckgo        figma             legalzoom             ...
```

All wired into the 6 agents that support MCP (Claw is env-var only).

### 11 universal hooks

| Event | Hook | What it does |
|---|---|---|
| `SessionStart` | `tool-inventory.sh` | Injects compact CLI/MCP/skill inventory |
| `UserPromptSubmit` | `skill-router.sh` | Token-thrifty intent → skill pointer |
| `UserPromptSubmit` | `carl-hook.py` | CARL rule injection (CARL repo) |
| `PreToolUse(Edit\|Write)` | `block-secret-writes.sh` | Refuses writes to `.env`, `*.key`, etc. |
| `PreToolUse(Bash)` | `block-ai-attribution.sh` | Strips `Co-Authored-By: Claude` from commits |
| `PostToolUse(Edit\|Write)` | `auto-format.sh` | Runs prettier/biome/ruff/rustfmt/gofmt |
| `PostToolUse(Bash\|Web*)` | `track-resources.sh` | Auto-maintains `useful-resources.md` |
| `PostToolUse(Web*)` | `entity-tracker.sh` | Graphiti-lite JSONL knowledge graph |
| `Stop` | `track-improvement.sh` | Updates per-project `IMPROVEMENT_STATE.json` |
| `Stop` | `notify-stop.sh` | Desktop notification when session ends |
| `Stop` | `memory-compiler.sh` | Compiles session insights to llm-wiki |

### 13 slash commands

```
/plan       /autoplan    /pair       /research    /extract
/wiki       /learn       /retro      /compress    /careful
/freeze     /crit        /ytdl
```

### Local-model launchers (in `~/.local/bin/`)

```
gemma4      gemma4:e4b      9.6 GB    ✅ native tool_calls (best for goose agent loops)
qwen36      qwen3.6:27b     16 GB     ✅ native (disk-gated ≥ 22 GB)
llama4      llama4:16x17b   67 GB     ✅ native (disk-gated ≥ 80 GB)
bonsai      bonsai-8b-q4km  5.2 GB    ⚠️ chat-only (reasoning model, no tool_calls)
```

## Security stance

- **No secrets in this repo.** `CREDS.md` and `SECRETS.md` are gitignored; `*.template` versions show structure.
- `permissions.allow`: 80 curated safe Bash patterns. `permissions.deny`: 19 destructive blocks. `permissions.ask`: 25 destructive-but-useful prompts.
- `defaultMode: "plan"` — no silent code execution.
- `block-secret-writes.sh` hook refuses writes to credential-shaped files.
- `block-ai-attribution.sh` strips AI auth-coauthor lines from commits (per-user preference).
- See [SECURITY.md](SECURITY.md) for vulnerability reports.

## Repository docs

| File | Purpose |
|---|---|
| [README.md](README.md) | This file |
| [QUICKSTART.md](QUICKSTART.md) | 5-minute install path |
| [HOW-TO-USE.md](HOW-TO-USE.md) | Narrative manual |
| [ARCHITECTURE.md](ARCHITECTURE.md) | How the bundle is organised |
| [CONTRIBUTING.md](CONTRIBUTING.md) | PR-only workflow + conventions |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community standards |
| [SECURITY.md](SECURITY.md) | Vulnerability reporting |
| [LICENSE](LICENSE) | MIT |
| [CREDS.md.template](CREDS.md.template) | Env-var inventory (copy → `CREDS.md`, gitignored) |
| [SECRETS.md.template](SECRETS.md.template) | Storage cookbook (copy → `SECRETS.md`, gitignored) |
| [user/docs/](user/docs/) | Per-area references (RULES · SETTINGS · HOOKS · MCPS · SKILLS · ACPS · COMMANDS · CHANGELOG · …) |

## Status

| Component | Status |
|---|---|
| `install.sh user` / `project` | Stable, idempotent, dry-run supported |
| Cross-tool sync (`sync-cross-tool*.sh`) | Stable across Claude / Codex / Goose / Gemini / Kimi / OpenCode |
| Skill router | Stable, validated 8/8 smoke tests |
| Local-model launchers | gemma4 + llama3.1 validated; qwen3.6 + llama4 untested (disk-gated) |
| Optional installers | All idempotent, all run from any cwd |

Tested on Linux (Debian/Ubuntu derivatives, Pop!_OS). macOS support via the same scripts (uses `$HOME`, `~`, no Linux-specific syscalls). Windows via PowerShell mirrors (`*.ps1`).

## Contributing

This is open source under MIT — fork and use freely. **Direct pushes to `main` are owner-only.** To contribute upstream: fork, branch, PR. The owner reviews every PR personally. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgements

The bundle integrates patterns from many excellent open-source projects:

- [obra/superpowers](https://github.com/obra/superpowers) — universal skill philosophy
- [garrytan/gstack](https://github.com/garrytan/gstack) — slash-command persona patterns
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) — instinct/learn skills
- [ChristopherKahler/{base,paul,carl}](https://github.com/ChristopherKahler) — workspace + planning + rule-injection frameworks
- [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — agent orchestration
- [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) — multi-persona collaboration
- [microsoft/markitdown](https://github.com/microsoft/markitdown) — file → markdown conversion
- [Yakitrak/obsidian-cli](https://github.com/Yakitrak/obsidian-cli) — vault CLI (notesmd-cli)
- [StevenStavrakis/obsidian-mcp](https://github.com/StevenStavrakis/obsidian-mcp) — vault MCP server
- [google/langextract](https://github.com/google/langextract) — structured extraction
- [lightpanda-io/browser](https://github.com/lightpanda-io/browser) — fast headless browser
- … and dozens more credited inline in `user/docs/INSPIRATIONS.md`.

Each upstream project retains its original license. The bundle scripts that orchestrate them are MIT.

## License

[MIT](LICENSE) — © 2026 Achitokun14
