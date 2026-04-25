# Plugins

30 curated plugins (of the 72 you had installed). The rest stay in cache — opt-in per project as needed.

## Always-on (plugin name → purpose)

### Code Intelligence
- `context7` — library docs lookup (replaces memory guesses about APIs)
- `serena` — semantic code navigation (find symbols, references across repos)
- `chrome-devtools-mcp` — browser inspection / performance / a11y debugging
- `typescript-lsp` / `pyright-lsp` — language servers for inline diagnostics

### Reference Docs
- `microsoft-docs` — Microsoft Learn / Azure docs
- `mintlify` — search Mintlify-hosted docs
- `context7` (duplicate note: also covers most OSS library docs)

### Code Quality / Security
- `code-review` — formal PR review workflow
- `commit-commands` — `/commit`, `/commit-push-pr`, `/clean_gone`
- `superpowers` — structured planning / TDD / debugging / code review
- `aikido` — SAST + secrets + IaC scan
- `semgrep` — pattern-based custom rules
- `claude-md-management` — audit/update CLAUDE.md files

### Dev Workflow
- `feature-dev` — guided feature development with architecture focus
- `plugin-dev` — meta: write your own plugins/skills
- `hookify` — generate hooks from markdown descriptions
- `explanatory-output-style` / `learning-output-style` — teaching modes

### Integrations (OAuth-gated, opt-in per project)
- `github` · `gitlab` · `linear` · `sentry` · `notion` · `figma` · `vercel` · `stripe` · `railway` · `firecrawl` · `prisma`

### Disabled intentionally
- `playwright` — replaced by direct MCP (avoids plugin overhead)
- `discord` · `telegram` · `fiftyone` · `sourcegraph` · `greptile` · `pagerduty` · `zoominfo` — broken/unused in our testing

## Managing

```bash
# List enabled
claude plugins list

# Enable / disable
claude plugins enable <name>
claude plugins disable <name>

# Install from marketplace
claude plugins install <name>

# Update all
claude plugins update
```

## Marketplaces

Set in `~/.claude/settings.json`:
```json
"extraKnownMarketplaces": {
  "impeccable": { "source": { "source": "github", "repo": "pbakaus/impeccable" } }
}
```

## See also

- Official plugin registry: https://claude.com/plugins
- Community: `~/Desktop/Claude-Code-Ecosystem.md`
