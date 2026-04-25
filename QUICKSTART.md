# Quickstart — 5 minutes to a configured workstation

## Prereqs

- Linux / macOS / WSL2 (native Windows works for most things via PowerShell scripts)
- Bash 4+ or zsh
- `git`, `curl`, `jq`, `python3` (3.10+), Node.js 20+ (for npm-based MCPs)
- At least one AI coding CLI installed:
  [Claude Code](https://docs.claude.com/claude-code) ·
  [Codex](https://github.com/openai/codex) ·
  [Goose](https://block.github.io/goose) ·
  [Gemini CLI](https://github.com/google-gemini/gemini-cli) ·
  [Kimi CLI](https://platform.moonshot.cn/docs/cli) ·
  [OpenCode](https://opencode.ai) ·
  [Claw Code](https://claw.ac)

## 1. Clone

```bash
git clone https://github.com/Achitokun14/claude-universal.git
cd claude-universal
```

## 2. Set up your secrets (local-only, gitignored)

```bash
cp CREDS.md.template CREDS.md
cp SECRETS.md.template SECRETS.md
$EDITOR CREDS.md          # fill in your env-var inventory
$EDITOR SECRETS.md        # pick a storage strategy
```

Add at minimum to `~/.zshrc` (or equivalent):

```bash
export MINIMAX_API_KEY="<your aggregator key>"   # used by goose planner, claw, kimi/opencode
export GEMINI_API_KEY="<your google key>"        # used by gemini-cli, /extract skill
```

…then `source ~/.zshrc`.

## 3. Dry-run install (read-only preview)

```bash
bash install.sh --dry-run user
```

Shows every change it *would* make to `~/.claude/`. Read it. If anything looks wrong — STOP and file an issue.

## 4. Real install

```bash
bash install.sh user                       # global config (~/.claude/)
bash install-skills.sh                     # the design skill family
bash scripts/init-llm-wiki.sh              # persistent knowledge wiki
bash scripts/init-improvement-state.sh     # session improvement tracking
bash scripts/bootstrap-resources.sh        # useful-resources.md autotrack
```

For a specific repo:

```bash
bash install.sh project /path/to/your/repo
```

## 5. Optional installers (pick what you need)

```bash
bash scripts/install-obsidian.sh           # obsidian-cli + obsidian-mcp wired into 6 agents
bash scripts/install-markitdown.sh         # PDF/Office → Markdown converter
bash scripts/install-langextract.sh        # structured extraction (Gemini/OpenAI/Ollama)
bash scripts/install-lightpanda.sh         # 16× faster headless browser MCP
bash scripts/install-warp.sh               # cc/kc/oc/cw shell aliases
bash scripts/install-claw-code.sh          # the Claw Code aggregator-router
bash scripts/install-zrok.sh               # ngrok replacement for tunnels
bash scripts/install-ghidra.sh             # Ghidra + GhidraMCP for binary analysis
bash scripts/install-inspired.sh           # interactive: BASE / PAUL / CARL / superpowers / etc.
bash scripts/install-ollama.sh             # Ollama + curated local models
```

## 6. Cross-tool sync (after adding new commands/skills/MCPs)

```bash
bash scripts/sync-cross-tool.sh             # portable subset (markdown + MCPs)
bash scripts/sync-cross-tool-native.sh      # deep per-tool native (skills, agents, providers)
```

## 7. Verify

```bash
# Per-CLI version checks
claude --version
goose --version
codex --version
gemini --version
kimi --version
opencode --version
claw --version 2>/dev/null  # if installed

# MCP health (Claude)
claude mcp list

# Skill inventory
ls ~/.claude/skills/ | wc -l
```

## What just got installed

| Component | Path |
|---|---|
| Universal rules | `~/.claude/CLAUDE.md` (managed-block append) |
| 8 hooks (PostToolUse + Stop + UserPromptSubmit) | `~/.claude/hooks/*.sh` |
| Skill router | `~/.claude/hooks/skill-router.{sh,conf}` |
| Settings (deep-merged) | `~/.claude/settings.json` |
| Docs | `~/.claude/docs/{RULES,SETTINGS,HOOKS,MCPS,SKILLS,...}.md` |
| 13 slash commands | `~/.claude/commands/` |

## Troubleshooting

| Symptom | Fix |
|---|---|
| Goose returns 401 | Check `GOOSE_OPENAI_API_KEY` in `~/.config/goose/config.yaml` is the literal value (Goose YAML doesn't shell-expand) |
| Claude doesn't see new skills | Restart Claude Code (skills register at session-start) |
| Hooks don't fire | `chmod +x ~/.claude/hooks/*.sh` and check `~/.claude/settings.json` `hooks` block |
| `obsidian-cli: command not found` | Re-run `scripts/install-obsidian.sh`; ensure `~/.local/bin` is on `PATH` |

For more: see `HOW-TO-USE.md`, `ARCHITECTURE.md`, and per-tool docs in `user/docs/`.

## Uninstall

```bash
# Restore the most recent backup
mv ~/.claude/settings.json.bak.<TIMESTAMP> ~/.claude/settings.json

# Remove managed block from ~/.claude/CLAUDE.md
sed -i '/<!-- BEGIN: claude-universal/,/<!-- END: claude-universal/d' ~/.claude/CLAUDE.md

# Remove bundled hooks (keep your custom ones)
rm ~/.claude/hooks/{auto-format,block-ai-attribution,block-secret-writes,entity-tracker,memory-compiler,notify-stop,session-context,tool-inventory,track-improvement,track-resources,skill-router}.sh
rm ~/.claude/hooks/skill-router.conf

# (Optional) remove docs
rm -rf ~/.claude/docs/
```

The bundle never deletes anything you wrote yourself — only the markers it added.
