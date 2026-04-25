# ACPs — Agent Client Protocol

ACP is the LSP-of-agents: a standard that lets any editor host any AI agent. Claude Code is an ACP agent; Zed, JetBrains, Neovim, Emacs, and Toad are ACP clients.

## Your ACP integrations

| Client | Install | Connection |
|--------|---------|-----------|
| **Zed** (Flatpak) | Already installed · official Claude Code bridge | Zed → Agent → Add Agent → Claude Code |
| **JetBrains IDEs** (IntelliJ/PyCharm/WebStorm) | Install ACP Agent Registry plugin | Tools → ACP → Browse → Claude Code |
| **Neovim via CodeCompanion** | `Plug 'olimorris/codecompanion.nvim'` | `:CodeCompanionChat` with `strategy = "acp"` |
| **Neovim via avante.nvim** | `Plug 'yetone/avante.nvim'` | Config `provider = "claude-acp"` |
| **Emacs** | `claude-code-ide.el` package | `M-x claude-code-ide-start` |
| **Toad TUI** | `pipx install batrachianai-toad` | `toad --agent claude` |

## Running Claude Code as an ACP server

```bash
claude acp            # stdio ACP server (for editor embedding)
claude acp --port 5000
```

## Running Kimi as ACP (alternative)

```bash
kimi acp              # Moonshot's coding agent over ACP
```

## ZeroClaw as ACP host / client

ZeroClaw acts both ways:
- **As server:** `zeroclaw acp` — editors can embed ZeroClaw.
- **As client calling Claude:** auto-spawns `claude` via `[mcp.servers]` in `~/.zeroclaw/config.toml`.

## Debugging

```bash
# Test Claude's ACP server responds to initialize
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | claude acp
```

Expect an `initialize` response with protocol version.

## See also

- [ACP spec](https://agentclientprotocol.com/)
- [Zed + ACP blog](https://zed.dev/blog/claude-code-via-acp)
- `~/Desktop/Claude-Code-Ecosystem.md` → ACP section
