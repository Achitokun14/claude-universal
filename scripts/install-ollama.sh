#!/usr/bin/env bash
# install-ollama.sh — Install Ollama (local + cloud) and wire it for use with claw-code.
#
# After install:
#   - Local Ollama daemon listens on http://127.0.0.1:11434
#   - Cloud Ollama (Turbo) requires `ollama signin` (interactive — needs your account)
#   - Then you can pull cloud-hosted models like glm-4.5, qwen3-coder, gpt-oss, etc.
#   - Built-in web-search tool is auto-available to compatible models on cloud

set -euo pipefail

say() { printf '▸ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*" >&2; }

if command -v ollama >/dev/null 2>&1; then
  say "ollama already installed: $(command -v ollama) ($(ollama --version 2>&1 | head -1))"
else
  say "Installing Ollama (official installer)"
  if ! command -v curl >/dev/null 2>&1; then
    warn "curl required"; exit 2
  fi
  curl -fsSL https://ollama.com/install.sh | sh
  command -v ollama || { warn "install failed"; exit 3; }
  say "installed: $(command -v ollama)"
fi

# ── Cloud config note (interactive — can't auto-sign-in) ──────────────
mkdir -p ~/.config/claw

cat > ~/.config/claw/ollama-cloud.md <<'CLOUD'
# Ollama Cloud setup (manual step — needs your interactive sign-in)

## 1. Sign in (one-time)

    ollama signin

This opens a browser window for ollama.com OAuth. After auth, ~/.ollama/id_ed25519 is generated.

## 2. Use a cloud-hosted model

    ollama run glm-4.5-cloud         # GLM 4.5 via cloud (or 5.1 when available)
    ollama run qwen3-coder-cloud
    ollama run gpt-oss-cloud

The `-cloud` suffix routes to Ollama's hosted compute (Turbo). No local GPU needed.

## 3. From claw-code

After you've exported CLAW_API_BASE_URL etc., also export:

    export OLLAMA_HOST="https://ollama.com"

Then route via the ollama prefix:

    claw --model ollama/glm-4.5-cloud "explain saga choreography"
    claw --model ollama/gpt-oss-cloud --tool web-search "what's new in PostgreSQL 17"

## 4. Web search tool

Cloud-hosted models support `--tool web-search` (a built-in tool Ollama exposes server-side).
Local-only models don't get this — search is a cloud-side capability.

## 5. List installed/cloud models

    ollama list                       # locally pulled
    ollama search glm                 # find cloud-available models
CLOUD

cat <<'DONE'

✓ Ollama installer complete.

NEXT (manual — needs your interactive sign-in):
  ollama signin                          # browser OAuth — opens once
  ollama pull qwen3-coder-cloud           # or any cloud model
  ollama run glm-4.5-cloud "ping"         # smoke-test

For claw-code routing:
  export OLLAMA_HOST="https://ollama.com"
  claw --model ollama/glm-4.5-cloud "..."

Full notes: ~/.config/claw/ollama-cloud.md
DONE
