#!/usr/bin/env bash
# install-ghidra.sh — Install Ghidra (NSA reverse-engineering suite) + GhidraMCP bridge
#                     + register MCP across all installed AI CLIs.
#
# Prereqs:
#   - JDK 21+ (Ghidra 11+ requires it; sdkman/apt/brew)
#   - uv (for PEP 723 bridge script)
#   - curl, jq, unzip
#
# What this does:
#   1. Downloads latest Ghidra release → ~/tools/ghidra/
#   2. Symlinks launcher to ~/.local/bin/ghidraRun + ghidra-headless
#   3. Downloads LaurieWired/GhidraMCP → ~/tools/ghidra-mcp/
#   4. Places extension zip in Ghidra's Extensions dir
#   5. Registers `ghidra` MCP in claude/goose/gemini/opencode/kimi/codex
#
# User manual step after this: launch Ghidra once, File → Install Extensions,
# tick GhidraMCP, restart, open a program → MCP backend on localhost:8080.

set -euo pipefail

TOOLS="$HOME/tools"
BIN="$HOME/.local/bin"
BRIDGE_DIR="$TOOLS/ghidra-mcp"
say() { printf '▸ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*" >&2; }

# ── deps ──────────────────────────────────────────────────────────
for dep in java curl jq unzip uv; do
  command -v "$dep" >/dev/null || { warn "missing: $dep"; exit 2; }
done

JAVA_MAJOR=$(java --version 2>&1 | head -1 | grep -oE '[0-9]+' | head -1)
(( JAVA_MAJOR >= 21 )) || { warn "need JDK 21+, got $JAVA_MAJOR"; exit 3; }

mkdir -p "$TOOLS" "$BIN"

# ── 1. Ghidra ──────────────────────────────────────────────────────
if [[ -x "$TOOLS/ghidra/ghidraRun" ]]; then
  say "Ghidra already installed at $TOOLS/ghidra"
else
  say "fetching latest Ghidra release metadata"
  URL=$(curl -sL "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest" \
        | jq -r '.assets[] | select(.name | test("ghidra.*public.*zip"; "i")) | .browser_download_url' \
        | head -1)
  [[ -n "$URL" ]] || { warn "could not resolve Ghidra URL"; exit 4; }

  say "downloading Ghidra (~500MB): $URL"
  curl -# -L "$URL" -o "$TOOLS/ghidra.zip"

  say "extracting"
  (cd "$TOOLS" && unzip -q ghidra.zip && rm ghidra.zip && mv ghidra_*PUBLIC* ghidra)
fi

ln -sf "$TOOLS/ghidra/ghidraRun" "$BIN/ghidraRun"
ln -sf "$TOOLS/ghidra/support/analyzeHeadless" "$BIN/ghidra-headless"
say "launchers: $BIN/ghidraRun + $BIN/ghidra-headless"

# ── 2. GhidraMCP (LaurieWired) ────────────────────────────────────
mkdir -p "$BRIDGE_DIR"
if [[ -f "$BRIDGE_DIR/GhidraMCP-release-1-4/bridge_mcp_ghidra.py" ]]; then
  say "GhidraMCP bridge already present"
else
  say "fetching GhidraMCP release"
  TAG=$(curl -sL "https://api.github.com/repos/LaurieWired/GhidraMCP/releases/latest" | jq -r .tag_name)
  ASSET_URL=$(curl -sL "https://api.github.com/repos/LaurieWired/GhidraMCP/releases/latest" \
              | jq -r '.assets[] | select(.name | test("release.*zip"; "i")) | .browser_download_url' | head -1)
  curl -sSL "$ASSET_URL" -o "$BRIDGE_DIR/release.zip"
  (cd "$BRIDGE_DIR" && unzip -oq release.zip && rm release.zip)
fi

# Find bridge + extension
BRIDGE_SCRIPT=$(find "$BRIDGE_DIR" -maxdepth 3 -name 'bridge_mcp_ghidra.py' | head -1)
EXT_ZIP=$(find "$BRIDGE_DIR" -maxdepth 3 -name 'GhidraMCP*.zip' | head -1)
[[ -f "$BRIDGE_SCRIPT" && -f "$EXT_ZIP" ]] || { warn "bridge or extension zip missing"; exit 5; }

# ── 3. Place extension in Ghidra ───────────────────────────────────
cp "$EXT_ZIP" "$TOOLS/ghidra/Extensions/Ghidra/"
say "extension placed: $(basename "$EXT_ZIP")"

# ── 4. Register MCP across AI CLIs ────────────────────────────────
say "registering 'ghidra' MCP across installed CLIs"

# Claude
if command -v claude >/dev/null; then
  claude mcp list 2>&1 | grep -q '^ghidra:' \
    || claude mcp add ghidra -- uv run "$BRIDGE_SCRIPT" >/dev/null 2>&1
  echo "   ✓ claude"
fi

# Goose
if command -v goose >/dev/null && [[ -f "$HOME/.config/goose/mcp.json" ]]; then
  python3 - "$BRIDGE_SCRIPT" <<'PY'
import json, sys, pathlib
p = pathlib.Path.home() / '.config/goose/mcp.json'
d = json.loads(p.read_text())
d.setdefault('mcpServers', {})
d['mcpServers']['ghidra'] = {'command': 'uv', 'args': ['run', sys.argv[1]]}
p.write_text(json.dumps(d, indent=2))
print('   ✓ goose')
PY
fi

# Gemini
if command -v gemini >/dev/null && [[ -f "$HOME/.gemini/settings.json" ]]; then
  python3 - "$BRIDGE_SCRIPT" <<'PY'
import json, sys, pathlib
p = pathlib.Path.home() / '.gemini/settings.json'
d = json.loads(p.read_text())
d.setdefault('mcpServers', {})
d['mcpServers']['ghidra'] = {'command': 'uv', 'args': ['run', sys.argv[1]]}
p.write_text(json.dumps(d, indent=2))
print('   ✓ gemini')
PY
fi

# OpenCode
if command -v opencode >/dev/null && [[ -f "$HOME/.config/opencode/opencode.json" ]]; then
  python3 - "$BRIDGE_SCRIPT" <<'PY'
import json, sys, pathlib
p = pathlib.Path.home() / '.config/opencode/opencode.json'
d = json.loads(p.read_text())
d.setdefault('mcp', {})
d['mcp']['ghidra'] = {'type': 'local', 'command': ['uv', 'run', sys.argv[1]], 'enabled': True}
p.write_text(json.dumps(d, indent=2))
print('   ✓ opencode')
PY
fi

# Kimi
if command -v kimi >/dev/null; then
  kimi mcp list 2>&1 | grep -q '^\s*ghidra\s' \
    || kimi mcp add ghidra -- uv run "$BRIDGE_SCRIPT" 2>&1 | tail -1 | sed 's/^/   /'
fi

# Codex
if command -v codex >/dev/null && [[ -f "$HOME/.codex/config.toml" ]]; then
  if ! grep -q '^\[mcp_servers\.ghidra\]' "$HOME/.codex/config.toml"; then
    cat >> "$HOME/.codex/config.toml" <<EOF

[mcp_servers.ghidra]
command = "uv"
args = ["run", "$BRIDGE_SCRIPT"]
EOF
    echo "   ✓ codex"
  fi
fi

cat <<'DONE'

✓ Ghidra + GhidraMCP installed across all CLIs.

MANUAL next steps (interactive):
  1. ghidraRun                  # launch Ghidra GUI once
  2. File → Install Extensions → tick "GhidraMCP" → OK → restart
  3. Open any program file (.exe/.so/.o/.bin)
  4. CodeBrowser → Tools → GhidraMCP → starts HTTP server on :8080
  5. In any of your AI CLIs, `ghidra` MCP tools will now work

Headless usage:
  ghidra-headless /tmp/project MyProject -import /path/to/binary
DONE
