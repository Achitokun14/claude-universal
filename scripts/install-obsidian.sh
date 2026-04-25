#!/usr/bin/env bash
# install-obsidian.sh — Install obsidian-cli (Yakitrak/notesmd-cli) +
# obsidian-mcp (StevenStavrakis) and wire MCP into all 6 coding agents.
#
# Skips agents whose binary is missing. Idempotent.
#
# Vault default: $OBSIDIAN_VAULT or ~/Desktop/ACTIVITIES.

set -euo pipefail

VAULT="${OBSIDIAN_VAULT:-$HOME/Desktop/ACTIVITIES}"
NOTESMD_VER="0.3.5"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

say() { printf '▸ %s\n' "$*"; }

# 1 — obsidian-cli (notesmd-cli)
if ! command -v obsidian-cli >/dev/null 2>&1; then
  say "downloading notesmd-cli v${NOTESMD_VER}"
  arch=$(uname -m); case "$arch" in x86_64) arch=amd64 ;; aarch64|arm64) arch=arm64 ;; esac
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  tmp=$(mktemp -d); trap "rm -rf $tmp" EXIT
  url="https://github.com/Yakitrak/obsidian-cli/releases/download/v${NOTESMD_VER}/notesmd-cli_${NOTESMD_VER}_${os}_${arch}.tar.gz"
  curl -fsSL "$url" | tar -xzC "$tmp"
  mkdir -p ~/.local/bin
  install -m 755 "$tmp/notesmd-cli" ~/.local/bin/obsidian-cli
  say "${GREEN}✓ obsidian-cli → ~/.local/bin/obsidian-cli${NC}"
else
  say "obsidian-cli already installed"
fi

# 2 — register vault if not already
if [[ -d "$VAULT" ]]; then
  ~/.local/bin/obsidian-cli list-vaults 2>/dev/null | grep -q "$VAULT" \
    || ~/.local/bin/obsidian-cli add-vault "$VAULT" 2>/dev/null || true
  ~/.local/bin/obsidian-cli set-default-vault "$(basename "$VAULT")" 2>/dev/null || true
  say "${GREEN}✓ vault registered: $VAULT${NC}"
else
  say "${YELLOW}vault path missing: $VAULT (skipping registration)${NC}"
fi

# 3 — obsidian-mcp (npm global)
if ! command -v obsidian-mcp >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then
    npm install -g obsidian-mcp 2>&1 | tail -3
    say "${GREEN}✓ obsidian-mcp installed${NC}"
  else
    say "${RED}npm missing — install Node.js first${NC}"
    exit 1
  fi
else
  say "obsidian-mcp already installed"
fi

# 4 — wire MCP into each agent (skip missing)
say "wiring obsidian MCP into coding agents (vault: $VAULT)"

# Claude
if command -v claude >/dev/null 2>&1; then
  if ! claude mcp list 2>/dev/null | grep -q "^obsidian:"; then
    claude mcp add obsidian --scope user -- npx -y obsidian-mcp "$VAULT" >/dev/null 2>&1 \
      && say "  ${GREEN}✓ claude${NC}" \
      || say "  ${RED}✗ claude (failed)${NC}"
  else
    say "  claude: present"
  fi
fi

# Codex
if [[ -f ~/.codex/config.toml ]]; then
  if ! grep -q '\[mcp_servers.obsidian\]' ~/.codex/config.toml; then
    cat >> ~/.codex/config.toml <<EOF

[mcp_servers.obsidian]
command = "npx"
args = ["-y", "obsidian-mcp", "$VAULT"]
EOF
    say "  ${GREEN}✓ codex${NC}"
  else
    say "  codex: present"
  fi
fi

# Goose
if [[ -f ~/.config/goose/mcp.json ]]; then
  python3 - <<PY
import json
from pathlib import Path
p = Path.home()/".config/goose/mcp.json"
d = json.loads(p.read_text())
d.setdefault("mcpServers", {})
if "obsidian" not in d["mcpServers"]:
    d["mcpServers"]["obsidian"] = {"command":"npx","args":["-y","obsidian-mcp","$VAULT"]}
    p.write_text(json.dumps(d, indent=2))
    print("  ✓ goose")
else:
    print("  goose: present")
PY
fi

# Gemini — direct JSON edit (CLI is interactive, hangs in scripts)
if [[ -f ~/.gemini/settings.json ]]; then
  python3 - <<PY
import json
from pathlib import Path
p = Path.home()/".gemini/settings.json"
d = json.loads(p.read_text())
d.setdefault("mcpServers", {})
if "obsidian" not in d["mcpServers"]:
    d["mcpServers"]["obsidian"] = {"command":"npx","args":["-y","obsidian-mcp","$VAULT"]}
    p.write_text(json.dumps(d, indent=2))
    print("  ✓ gemini")
else:
    print("  gemini: present")
PY
fi

# Kimi
if [[ -f ~/.kimi/mcp.json ]]; then
  python3 - <<PY
import json
from pathlib import Path
p = Path.home()/".kimi/mcp.json"
d = json.loads(p.read_text())
d.setdefault("mcpServers", {})
if "obsidian" not in d["mcpServers"]:
    d["mcpServers"]["obsidian"] = {"command":"npx","args":["-y","obsidian-mcp","$VAULT"]}
    p.write_text(json.dumps(d, indent=2))
    print("  ✓ kimi")
else:
    print("  kimi: present")
PY
fi

# OpenCode
if [[ -f ~/.config/opencode/opencode.json ]]; then
  python3 - <<PY
import json
from pathlib import Path
p = Path.home()/".config/opencode/opencode.json"
d = json.loads(p.read_text())
d.setdefault("mcp", {})
if "obsidian" not in d["mcp"]:
    d["mcp"]["obsidian"] = {"type":"local","command":["npx","-y","obsidian-mcp","$VAULT"]}
    p.write_text(json.dumps(d, indent=2))
    print("  ✓ opencode")
else:
    print("  opencode: present")
PY
fi

# Claw uses env vars only — no MCP support
say "  claw: skip (no MCP concept — uses env vars only)"

echo
say "${GREEN}done. Test with:${NC}"
echo "  obsidian-cli list"
echo "  obsidian-cli search 'wiki'"
echo "  (in any agent) ask: 'list notes in obsidian vault'"
