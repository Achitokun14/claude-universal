#!/usr/bin/env bash
# SessionStart(startup|resume) — write a compact inventory of available tools so
# Claude/Codex/OpenCode know what's locally available and what to substitute.
# Output goes to stdout and is injected into session context.
#
# Keep output under ~25 lines — this goes into every prompt window.

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1 && echo "y" || echo "n"; }

# Only check tools that actually affect routing decisions
cat <<HDR
# Local Tool Inventory (auto-injected)

Use this to pick the right tool first, fall back to web search if missing.

HDR

# --- Core agents ---
echo "## Agents"
echo "- claude: $(have claude), kimi: $(have kimi), opencode: $(have opencode), zeroclaw: $(have zeroclaw), gemini: $(have gemini)"

# --- Formatters / linters (router for auto-format hook) ---
echo "## Code Quality"
echo "- biome: $(have biome), ruff: $(have ruff), prettier: $(have npx), rustfmt: $(have rustfmt), gofmt: $(have gofmt), eslint: $(have eslint)"

# --- Dev runtimes ---
echo "## Runtimes"
echo "- node: $(have node), bun: $(have bun), python3: $(have python3), rustc: $(have rustc), go: $(have go), deno: $(have deno)"

# --- Infra / CLI ---
echo "## Infra"
echo "- docker: $(have docker), kubectl: $(have kubectl), terraform: $(have terraform), railway: $(have railway), vercel: $(have vercel), gh: $(have gh), zrok: $(have zrok)"

# --- Modern terminal utilities ---
echo "## Terminal"
echo "- bat/batcat: $(have batcat), eza: $(have eza), fd/fdfind: $(have fdfind), rg: $(have rg), fzf: $(have fzf), jq: $(have jq), zoxide: $(have zoxide), lazygit: $(have lazygit), lazydocker: $(have lazydocker), delta: $(have delta)"

# --- Git context (optional, cheap) ---
if git -C . rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  last="$(git log -1 --pretty=format:'%h %s' 2>/dev/null || echo '-')"
  echo ""
  echo "## Git"
  echo "- branch: $branch · dirty: $dirty · last: $last"
fi

exit 0
