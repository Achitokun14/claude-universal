#!/usr/bin/env bash
# Downloads Lightpanda (AI-first headless browser) and registers it as a Claude MCP.
# 16x less memory, 9x faster than headless Chrome for scraping/automation.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

arch="$(uname -m)"
case "$arch" in
  x86_64)   asset_suffix="x86_64-linux" ;;
  aarch64)  asset_suffix="aarch64-linux" ;;
  *)        echo "unsupported arch: $arch"; exit 2 ;;
esac

echo "▸ Fetching latest Lightpanda release..."
LATEST_URL="$(curl -sL https://api.github.com/repos/lightpanda-io/browser/releases/latest \
  | python3 -c "
import sys, json
r = json.load(sys.stdin)
suffix = sys.argv[1]
for a in r['assets']:
  if suffix in a['name'] and a['name'].endswith(('.tar.gz', '.zip', '')):
    print(a['browser_download_url']); break
" "$asset_suffix")"

if [[ -z "$LATEST_URL" ]]; then
  echo "Could not find a release asset for $asset_suffix."
  echo "Visit https://github.com/lightpanda-io/browser/releases and download manually."
  exit 3
fi

echo "▸ Downloading: $LATEST_URL"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -sL "$LATEST_URL" -o "$tmp/lightpanda.bin"

# Detect archive vs binary
if file "$tmp/lightpanda.bin" | grep -qi 'gzip\|tar\|zip'; then
  mkdir -p "$tmp/extract"
  case "$LATEST_URL" in
    *.tar.gz|*.tgz) tar xzf "$tmp/lightpanda.bin" -C "$tmp/extract" ;;
    *.zip)          unzip -q "$tmp/lightpanda.bin" -d "$tmp/extract" ;;
  esac
  found="$(find "$tmp/extract" -type f -name 'lightpanda*' | head -1)"
  cp "$found" "$BIN_DIR/lightpanda"
else
  cp "$tmp/lightpanda.bin" "$BIN_DIR/lightpanda"
fi

chmod +x "$BIN_DIR/lightpanda"
echo "✓ Installed: $BIN_DIR/lightpanda"
"$BIN_DIR/lightpanda" --version 2>&1 | head -3

# Register as Claude MCP
if command -v claude >/dev/null 2>&1; then
  echo "▸ Registering as MCP 'lightpanda'..."
  # Use the real subcommand "mcp" (not "serve --mcp"; that syntax was from earlier builds).
  claude mcp add lightpanda -- "$BIN_DIR/lightpanda" mcp 2>&1 | tail -3 || \
    echo "⚠ Could not auto-register. Run manually: claude mcp add lightpanda -- $BIN_DIR/lightpanda mcp"
else
  echo "⚠ claude CLI not in PATH — skipping MCP registration"
fi

echo ""
echo "Done. Open a new Claude Code session to pick up the MCP."
