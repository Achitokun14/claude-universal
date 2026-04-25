#!/usr/bin/env bash
# sync-cross-tool-native.sh — Deep per-tool native-format sync.
# Covers Kimi, OpenCode, Gemini, Codex. (Goose + Claude already match; Claw uses env vars.)
#
# Idempotent. Reads canonical sources from ~/.claude/{CLAUDE.md,commands,hooks,skills}
# and writes each tool's native format.

set -euo pipefail

BUNDLE="$HOME/Desktop/ACTIVITIES/claude-universal"
CAT="$HOME/Desktop/ACTIVITIES/SKILLS-CATALOG.md"
INV="$HOME/Desktop/ACTIVITIES/skills-inventory.json"

say() { printf '▸ %s\n' "$*"; }

# Explicit browser-act/skills list (forced into every coding agent that
# supports skills). These sit in catalog Tier-S/A already but ensure
# they're present regardless of ranking drift.
BROWSER_SKILLS=(
  "${HOME}/.claude/skills/_inspired/everything-claude-code/skills/browser-qa"
  "${HOME}/.claude/skills/firecrawl-browser"
  "${HOME}/.claude/skills/playwright-skill/skills/playwright-skill"
)

# ═══════════════════════════════════════════════════════════════════
# Browser-act skills — deploy to every agent that supports skills
# ═══════════════════════════════════════════════════════════════════
sync_browser_skills() {
  say "browser-act/skills: forcing 3 skills into every agent"

  # Codex
  mkdir -p "$HOME/.codex/skills"
  local c_count=0
  for src in "${BROWSER_SKILLS[@]}"; do
    local name; name=$(basename "$src")
    local dst="$HOME/.codex/skills/$name"
    [[ -e "$dst" ]] || { ln -s "$src" "$dst" 2>/dev/null && c_count=$((c_count+1)); }
  done
  say "  codex: $c_count new browser skills linked"

  # Goose (user-scope skills dir already exists)
  mkdir -p "$HOME/.config/goose/skills"
  local g_count=0
  for src in "${BROWSER_SKILLS[@]}"; do
    local name; name=$(basename "$src")
    local dst="$HOME/.config/goose/skills/$name"
    [[ -e "$dst" ]] || { ln -s "$src" "$dst" 2>/dev/null && g_count=$((g_count+1)); }
  done
  say "  goose: $g_count new browser skills linked"

  # Gemini (via CLI, auto-accept prompt)
  if command -v gemini >/dev/null 2>&1; then
    for src in "${BROWSER_SKILLS[@]}"; do
      yes "" | timeout 15 gemini skills link "$src" >/dev/null 2>&1 || true
    done
    say "  gemini: 3 browser skills linked via CLI"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# Gemini — hooks migrate + skills link (Tier-S+A curated)
# ═══════════════════════════════════════════════════════════════════
sync_gemini() {
  if ! command -v gemini >/dev/null 2>&1; then say "gemini missing — skip"; return; fi

  # First-party Claude→Gemini hook migration
  say "gemini: migrating Claude hooks"
  gemini hooks migrate 2>&1 | tail -5 | sed 's/^/    /' || true

  # Link Tier-S + Tier-A skills (avoid bloat from 1,488 total)
  say "gemini: linking Tier-S/A skills from catalog"
  if [[ -f "$INV" ]]; then
    # Extract names from catalog Tier-S + Tier-A tables
    local names; names=$(awk '
      /^## Tier S /,/^## Tier A /    { if ($1 == "|" && $2 ~ /^`/) { gsub(/`/, "", $2); print $2 } }
      /^## Tier A /,/^## Tier B /    { if ($1 == "|" && $2 ~ /^`/) { gsub(/`/, "", $2); print $2 } }
    ' "$CAT" | sort -u)
    local count=0
    for name in $names; do
      # Only link if user-scope skill dir exists (not plugin:)
      if [[ -d "$HOME/.claude/skills/$name" ]]; then
        yes "" | timeout 15 gemini skills link "$HOME/.claude/skills/$name" >/dev/null 2>&1 || true
        count=$((count+1))
      fi
    done
    say "gemini: $count skills linked"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# Codex — mirror skills + hooks + commands
# ═══════════════════════════════════════════════════════════════════
sync_codex() {
  if ! command -v codex >/dev/null 2>&1; then say "codex missing — skip"; return; fi
  mkdir -p ~/.codex/skills ~/.codex/commands ~/.codex/hooks

  # Link Tier-S+A skills (Codex reads ~/.codex/skills/<name>/SKILL.md)
  say "codex: linking Tier-S/A skills"
  if [[ -f "$CAT" ]]; then
    local names; names=$(awk '
      /^## Tier S /,/^## Tier B /    { if ($1 == "|" && $2 ~ /^`/) { gsub(/`/, "", $2); print $2 } }
    ' "$CAT" | sort -u)
    local count=0
    for name in $names; do
      local src="$HOME/.claude/skills/$name"
      local dst="$HOME/.codex/skills/$name"
      if [[ -d "$src" && ! -e "$dst" ]]; then
        ln -s "$src" "$dst" 2>/dev/null && count=$((count+1)) || true
      fi
    done
    say "codex: linked $count new skills (total now $(ls ~/.codex/skills/ | wc -l))"
  fi

  # Copy commands (13)
  local cmd_count=0
  for c in "$HOME/.claude/commands"/*.md; do
    [[ -f "$c" ]] || continue
    local n="$(basename "$c")"
    if [[ ! -f "$HOME/.codex/commands/$n" ]]; then
      cp "$c" "$HOME/.codex/commands/$n"
      cmd_count=$((cmd_count+1))
    fi
  done
  say "codex: copied $cmd_count commands"

  # Link hooks (portable bash)
  local hook_count=0
  for h in "$HOME/.claude/hooks"/*.sh; do
    [[ -f "$h" ]] || continue
    local n="$(basename "$h")"
    if [[ ! -e "$HOME/.codex/hooks/$n" ]]; then
      ln -s "$h" "$HOME/.codex/hooks/$n" 2>/dev/null || true
      hook_count=$((hook_count+1))
    fi
  done
  say "codex: linked $hook_count hooks"
}

# ═══════════════════════════════════════════════════════════════════
# OpenCode — 13 slash commands as agents + custom providers
# ═══════════════════════════════════════════════════════════════════
sync_opencode() {
  if ! command -v opencode >/dev/null 2>&1; then say "opencode missing — skip"; return; fi

  # Add MiniMax aggregator provider + Ollama to opencode.json
  local oc_json="$HOME/.config/opencode/opencode.json"
  [[ -f "$oc_json" ]] || echo '{"$schema":"https://opencode.ai/config.json","mcp":{}}' > "$oc_json"

  python3 - "$oc_json" <<'PY'
import json, sys, os
path = sys.argv[1]
cfg = json.load(open(path))

cfg.setdefault('provider', {})

# MiniMax aggregator — user exports MINIMAX_API_KEY / CLAW_API_KEY
cfg['provider'].setdefault('minimax-aggregator', {
    'npm': '@ai-sdk/openai-compatible',
    'name': 'MiniMax Aggregator',
    'options': {
        'baseURL': 'https://api.minimaxi.chat/v1',
        'apiKey': '{env:MINIMAX_API_KEY}',
    },
    'models': {
        'MiniMax-M2':     {'name': 'MiniMax-M2'},
        'MiniMax-M1':     {'name': 'MiniMax-M1'},
        'abab6.5-chat':   {'name': 'abab6.5-chat'},
    },
})

# Ollama cloud
cfg['provider'].setdefault('ollama-cloud', {
    'npm': '@ai-sdk/openai-compatible',
    'name': 'Ollama Cloud',
    'options': {
        'baseURL': '{env:OLLAMA_HOST:-https://ollama.com}/v1',
        'apiKey': 'ollama',
    },
    'models': {
        'gpt-oss:120b-cloud':    {'name': 'gpt-oss:120b-cloud'},
        'qwen3-coder:480b-cloud':{'name': 'qwen3-coder:480b-cloud'},
        'glm-4.5-cloud':          {'name': 'glm-4.5-cloud'},
    },
})

json.dump(cfg, open(path, 'w'), indent=2)
print(f"  ✓ opencode.json: {len(cfg.get('provider',{}))} custom providers")
PY

  # Port 13 commands as OpenCode agents (file-based, ~/.config/opencode/agent/<name>.md)
  local agent_dir="$HOME/.config/opencode/agent"
  mkdir -p "$agent_dir"
  local port_count=0
  for c in "$HOME/.claude/commands"/*.md; do
    [[ -f "$c" ]] || continue
    local n="$(basename "${c%.md}")"
    local dst="$agent_dir/$n.md"
    if [[ ! -f "$dst" ]]; then
      local desc; desc="$(grep -oP '^description:\s*\K.*' "$c" | head -1 | tr -d '"')"
      local body; body="$(sed '/^---$/,/^---$/d' "$c")"
      cat > "$dst" <<EOF
---
description: ${desc:-Bundled command $n}
mode: primary
---

$body
EOF
      port_count=$((port_count+1))
    fi
  done
  say "opencode: ported $port_count commands as agents"
}

# ═══════════════════════════════════════════════════════════════════
# Kimi — TOML providers + models
# ═══════════════════════════════════════════════════════════════════
sync_kimi() {
  if ! command -v kimi >/dev/null 2>&1; then say "kimi missing — skip"; return; fi

  local cfg="$HOME/.kimi/config.toml"
  [[ -f "$cfg" ]] || { say "kimi: no config.toml — skip"; return; }

  # Idempotent append: only add blocks not already present
  if ! grep -q '"minimax-aggregator"' "$cfg"; then
    say "kimi: adding minimax-aggregator provider + models"
    cat >> "$cfg" <<'TOML'

# ── Added by claude-universal sync-cross-tool-native.sh ──────────────
[providers."minimax-aggregator"]
type = "openai"
base_url = "https://api.minimaxi.chat/v1"
# API key read from $MINIMAX_API_KEY environment variable
api_key_env = "MINIMAX_API_KEY"

[models."minimax-aggregator/MiniMax-M2"]
provider = "minimax-aggregator"
model = "MiniMax-M2"
max_context_size = 200000
capabilities = ["thinking"]

[models."minimax-aggregator/MiniMax-M1"]
provider = "minimax-aggregator"
model = "MiniMax-M1"
max_context_size = 1000000
capabilities = ["thinking"]

[providers."ollama-cloud"]
type = "openai"
base_url_env = "OLLAMA_HOST"
api_key = "ollama"

[models."ollama-cloud/gpt-oss-120b"]
provider = "ollama-cloud"
model = "gpt-oss:120b-cloud"

[models."ollama-cloud/qwen3-coder-480b"]
provider = "ollama-cloud"
model = "qwen3-coder:480b-cloud"

[models."ollama-cloud/glm-4.5"]
provider = "ollama-cloud"
model = "glm-4.5-cloud"
TOML
    say "kimi: appended 2 providers + 5 models"
  else
    say "kimi: providers already present — skip"
  fi
}

echo "═══════════════════════════════════════════════════════════"
echo " Cross-tool NATIVE sync (deep)"
echo "═══════════════════════════════════════════════════════════"
sync_browser_skills
echo
sync_gemini
echo
sync_codex
echo
sync_opencode
echo
sync_kimi
echo
echo "═══════════════════════════════════════════════════════════"
echo " Done. Goose already synced (358 skills + hooks present)."
echo " Claude-universal sync: use sync-cross-tool.sh for portable subset."
echo "═══════════════════════════════════════════════════════════"
