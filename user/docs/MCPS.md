# MCP Servers

Model Context Protocol servers expose tools/resources Claude can use. The bundle keeps 5 practical MCPs installed and documents the rest for reference.

## Core (installed & authenticated)

| Server | Type | Purpose | Config |
|--------|------|---------|--------|
| `firecrawl` | stdio | Web scraping via Firecrawl CLI | `npx -y firecrawl-mcp` (needs `FIRECRAWL_API_KEY`) |
| `browserbase` | stdio | Cloud browser automation | `npx -y @browserbasehq/mcp-server-browserbase` |
| `playwright` | stdio | Local browser automation via CLI | `npx @playwright/mcp@latest` |
| `duckduckgo` | stdio | Free web search, no key | `npx -y duckduckgo-mcp-server` |
| `next-devtools` | stdio | Next.js dev tools | `npx -y next-devtools-mcp` |
| `svelte` | stdio | Svelte MCP (docs + autofixer) | `npx -y @sveltejs/mcp` |
| `vue-devtools` | stdio | Vue + Vite MCP | `npx -y vue-mcp-server` |

## From enabled plugins (bundled)

Auto-registered when their plugin is enabled:

- **context7** — library docs lookup (`mcp__plugin_context7_context7__query-docs`)
- **chrome-devtools** — DevTools protocol for page inspection
- **microsoft-learn** — Microsoft/Azure docs (`search`, `fetch`, `code_sample_search`)
- **mintlify** — Mintlify docs search
- **sonatype-guide** — OSS version + vulnerability lookup
- **aikido** — security scanner (SAST, secrets, IaC)
- **semgrep** — custom rule-based scanning
- **serena** — semantic codebase navigation (symbols, references, memories)
- **github / gitlab / linear / notion / figma / vercel / stripe** — SaaS integrations (OAuth-gated)
- **prisma** — local Prisma studio + migrations

## Managing servers

```bash
# List
claude mcp list

# Add stdio server
claude mcp add <name> -- <command> [args...]

# Add HTTP server with OAuth
claude mcp add <name> --type http --url https://example.com/mcp --oauth

# Remove
claude mcp remove <name>

# Reset a broken OAuth session
claude mcp reset-auth <name>
```

## Environment

Required env vars (set in `~/.zshrc` or systemd env):
- `FIRECRAWL_API_KEY` — firecrawl
- `BROWSERBASE_API_KEY`, `BROWSERBASE_PROJECT_ID` — browserbase

## Health check

```bash
claude mcp list
```
Each server prints: ✓ Connected · ! Needs authentication · ✗ Failed.

## Adding project-specific MCPs

In `<repo>/.claude.json` or `<repo>/.mcp.json`:
```json
{
  "mcpServers": {
    "my-db": {
      "command": "npx",
      "args": ["-y", "mongodb-mcp-server", "--connectionString", "${MONGO_URL}"]
    }
  }
}
```

## Universal MCPs always available (user-scope)

Wired across all 6 agents (Claude/Codex/Goose/Gemini/Kimi/OpenCode). Claw uses env vars only — no MCP.

### `obsidian` — vault read/write/search
- Backed by [`obsidian-mcp`](https://github.com/StevenStavrakis/obsidian-mcp) (filesystem-direct, no plugin)
- Default vault: `~/Desktop/ACTIVITIES`
- Tools: read note, create note, edit note, move/delete, manage tags, search vault
- Override vault: `OBSIDIAN_VAULT=/path bash claude-universal/scripts/install-obsidian.sh`
- CLI counterpart: `obsidian-cli` (Yakitrak / notesmd-cli) — `obsidian-cli {create,open,search,daily,frontmatter,...}`

## Universal CLI tools (user-scope, system PATH)

### `markitdown` — file-to-markdown converter
- Microsoft's [markitdown](https://github.com/microsoft/markitdown)
- Converts: PDF, DOCX, XLSX, PPTX, images (OCR via magika), audio, HTML, JSON, XML, ZIP, CSV
- Use: `markitdown report.pdf > report.md` · `cat doc.docx | markitdown`
- Pairs well with `/extract` and `obsidian-cli create` for ingesting docs into vault
- Install: `bash claude-universal/scripts/install-markitdown.sh`

## See also

- `~/Desktop/Free-APIs-Directory.md` for free/OSS MCPs catalog
- `~/Desktop/Claude-Code-Ecosystem.md` for 60+ more MCP options
