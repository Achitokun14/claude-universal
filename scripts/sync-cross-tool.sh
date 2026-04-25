#!/usr/bin/env bash
# sync-cross-tool.sh — Mirror the Claude Code bundle across Kimi / OpenCode / Gemini CLI.
#
# What's portable vs not:
#   - AGENTS.md / GEMINI.md system-prompt content:  100% portable (markdown)
#   - MCP servers:                                    90% portable (stdio protocol is standard)
#   - Slash commands (13 bundled):                   per-tool format; OpenCode+Gemini supported
#   - Skills (1,488 items):                          Claude-specific format, NOT portable
#   - Hooks:                                          Claude-specific, NOT portable
#   - Shell aliases:                                  100% portable (already in ~/.zshrc)
#
# Idempotent. Re-run any time a new MCP or command is added to the Claude bundle.

set -euo pipefail

BUNDLE="$HOME/Desktop/ACTIVITIES/claude-universal"
CLAUDE_MD="$BUNDLE/user/CLAUDE.md"

say() { printf '▸ %s\n' "$*"; }

# ═══════════════════════════════════════════════════════════════════
# 1. Core managed-block content (shared system prompt)
# ═══════════════════════════════════════════════════════════════════

# Extract the managed block's text body (strip BEGIN/END markers for re-wrapping per tool)
MD_BODY="$(sed -n '/<!-- BEGIN: claude-universal/,/<!-- END: claude-universal/p' "$CLAUDE_MD" \
            | sed '1d;$d' | sed '/^$/d;:a;$!{N;ba};')"

# ═══════════════════════════════════════════════════════════════════
# 2. Portable MCP server definitions (stdio-based; each tool adapts config schema)
# ═══════════════════════════════════════════════════════════════════

# Base list — these work identically across Claude, Kimi, OpenCode, Gemini
declare -A MCP_SERVERS=(
  ["lightpanda"]="$HOME/.local/bin/lightpanda mcp"
  ["fetch"]="uvx mcp-server-fetch"
  ["puppeteer"]="npx -y @modelcontextprotocol/server-puppeteer"
  ["github"]="npx -y @modelcontextprotocol/server-github"
)

# ═══════════════════════════════════════════════════════════════════
# 3. OpenCode — ~/.config/opencode/opencode.json + AGENTS.md
# ═══════════════════════════════════════════════════════════════════

sync_opencode() {
  if ! command -v opencode >/dev/null 2>&1; then
    say "opencode not installed — skipping"
    return
  fi
  local cfg_dir="$HOME/.config/opencode"
  local oc_json="$cfg_dir/opencode.json"
  local agents_md="$cfg_dir/AGENTS.md"
  mkdir -p "$cfg_dir"

  # AGENTS.md — opencode auto-discovers this
  cat > "$agents_md" <<AGENTS
<!-- BEGIN: claude-universal managed block (synced from ~/.claude/CLAUDE.md) -->
$MD_BODY
<!-- END: claude-universal managed block -->
AGENTS
  say "opencode: wrote $agents_md"

  # opencode.json — inject portable MCPs into existing config
  if [[ ! -f "$oc_json" ]]; then
    # Create minimal config if missing
    echo '{"$schema":"https://opencode.ai/config.json","mcp":{}}' > "$oc_json"
  fi

  python3 - "$oc_json" <<'PY'
import json, sys, os
path = sys.argv[1]
cfg = json.load(open(path))
cfg.setdefault('mcp', {})

servers = {
    'lightpanda': {
        'type': 'local',
        'command': [os.path.expanduser('~/.local/bin/lightpanda'), 'mcp'],
        'enabled': True,
    },
    'fetch': {
        'type': 'local',
        'command': ['uvx', 'mcp-server-fetch'],
        'enabled': True,
    },
}
for name, spec in servers.items():
    if name not in cfg['mcp']:
        cfg['mcp'][name] = spec

json.dump(cfg, open(path, 'w'), indent=2)
print(f"  ✓ opencode.json: {len(cfg['mcp'])} MCP servers now registered")
PY
}

# ═══════════════════════════════════════════════════════════════════
# 4. Gemini CLI — ~/.gemini/GEMINI.md + ~/.gemini/settings.json
# ═══════════════════════════════════════════════════════════════════

sync_gemini() {
  if ! command -v gemini >/dev/null 2>&1; then
    say "gemini not installed — skipping"
    return
  fi
  local gem_dir="$HOME/.gemini"
  mkdir -p "$gem_dir" "$gem_dir/commands"

  # GEMINI.md — Gemini's system-prompt convention
  cat > "$gem_dir/GEMINI.md" <<GEM
<!-- BEGIN: claude-universal managed block (synced from ~/.claude/CLAUDE.md) -->
$MD_BODY
<!-- END: claude-universal managed block -->
GEM
  say "gemini: wrote $gem_dir/GEMINI.md"

  # settings.json — merge MCP servers
  local settings="$gem_dir/settings.json"
  [[ ! -f "$settings" ]] && echo '{"mcpServers":{}}' > "$settings"

  python3 - "$settings" <<'PY'
import json, sys, os
path = sys.argv[1]
cfg = json.load(open(path))
cfg.setdefault('mcpServers', {})

servers = {
    'lightpanda': {
        'command': os.path.expanduser('~/.local/bin/lightpanda'),
        'args': ['mcp'],
    },
    'fetch': {
        'command': 'uvx',
        'args': ['mcp-server-fetch'],
    },
}
for name, spec in servers.items():
    if name not in cfg['mcpServers']:
        cfg['mcpServers'][name] = spec

json.dump(cfg, open(path, 'w'), indent=2)
print(f"  ✓ settings.json: {len(cfg['mcpServers'])} MCP servers now registered")
PY

  # Port slash commands (13 bundled) to Gemini's commands/ dir in TOML format
  local cmd_count=0
  for src in "$BUNDLE/user/commands"/*.md; do
    [[ -f "$src" ]] || continue
    local name; name="$(basename "${src%.md}")"
    local dst="$gem_dir/commands/$name.toml"
    if [[ ! -f "$dst" ]]; then
      # Gemini custom commands are TOML with `prompt = "..."`
      local desc; desc="$(grep -oP '^description:\s*\K.*' "$src" | head -1 | sed 's/"/\\"/g')"
      local body; body="$(sed -n '/^---$/,/^---$/!p' "$src" | sed 's/\\/\\\\/g;s/"/\\"/g;s/$/\\n/' | tr -d '\n')"
      {
        echo "description = \"${desc:-Bundled command: $name}\""
        echo "prompt = \"\"\""
        sed -n '/^---$/,/^---$/!p' "$src"
        echo "\"\"\""
      } > "$dst"
      cmd_count=$((cmd_count+1))
    fi
  done
  say "gemini: ported $cmd_count commands to $gem_dir/commands/*.toml"
}

# ═══════════════════════════════════════════════════════════════════
# 5. Kimi CLI — ~/.kimi/ (config.toml + MCP via `kimi mcp add`)
# ═══════════════════════════════════════════════════════════════════

sync_kimi() {
  if ! command -v kimi >/dev/null 2>&1; then
    say "kimi not installed — skipping"
    return
  fi
  local kimi_dir="$HOME/.kimi"
  mkdir -p "$kimi_dir"

  # Kimi doesn't have a standard AGENTS.md discovery — but we write one for reference
  # It DOES pick up rules from ~/.kimi/CLAUDE.md in recent builds
  cat > "$kimi_dir/AGENTS.md" <<KIMI
<!-- BEGIN: claude-universal managed block (synced from ~/.claude/CLAUDE.md) -->
$MD_BODY
<!-- END: claude-universal managed block -->
KIMI
  say "kimi: wrote $kimi_dir/AGENTS.md (readable reference; kimi may or may not auto-load)"

  # Register MCP servers via `kimi mcp add` (idempotent — kimi deduplicates)
  for name in "${!MCP_SERVERS[@]}"; do
    local cmd="${MCP_SERVERS[$name]}"
    if ! kimi mcp list 2>&1 | grep -q "^\s*$name\s"; then
      # shellcheck disable=SC2086
      kimi mcp add "$name" -- $cmd 2>&1 | tail -2 | sed 's/^/      /'
    fi
  done
  local c; c=$(kimi mcp list 2>&1 | grep -cE "^\s*\w" || echo 0)
  say "kimi: $c MCP servers registered"
}

# ═══════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Cross-tool sync — Claude → Kimi / OpenCode / Gemini"
echo "═══════════════════════════════════════════════════════════"

sync_opencode
echo
sync_gemini
echo
sync_kimi

echo
echo "═══════════════════════════════════════════════════════════"
echo " Done. Caveats:"
echo "   - Claude's 1,488 skills are NOT ported (format is Claude-specific)"
echo "   - Claude's hooks are NOT ported (format is Claude-specific)"
echo "   - Claude's plugin-provided MCPs are NOT auto-copied (they live inside plugins/)"
echo "   - Shell aliases are already set up (cc/kc/oc/cw via install-warp.sh)"
echo
echo " To re-run after adding new commands/MCPs to the Claude bundle:"
echo "   bash ~/Desktop/ACTIVITIES/claude-universal/scripts/sync-cross-tool.sh"
echo "═══════════════════════════════════════════════════════════"
