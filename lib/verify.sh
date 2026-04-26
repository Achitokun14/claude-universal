#!/usr/bin/env bash
# lib/verify.sh — post-install smoke checks. One PASS/FAIL line per agent.

verify_one() {
  local name="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    ok "$name"
  else
    warn "$name (not installed or failing)"
  fi
}

verify_all() {
  step "7/8 — verify"

  # Bundle artefacts
  verify_one "manifest exists"          "test -f $HOME/.claude/.claude-universal-manifest.json"
  verify_one "settings.json present"    "test -f $HOME/.claude/settings.json"
  verify_one "managed CLAUDE.md block"  "grep -q 'BEGIN: claude-universal managed block' $HOME/.claude/CLAUDE.md"
  verify_one "skill-router hook wired"  "jq -e '.hooks.UserPromptSubmit[].hooks[]?.command | select(test(\"skill-router.sh\"))' $HOME/.claude/settings.json"

  # AI CLIs (only if present)
  command -v claude   >/dev/null 2>&1 && verify_one "claude --version"   "claude --version"
  command -v codex    >/dev/null 2>&1 && verify_one "codex --version"    "codex --version"
  command -v goose    >/dev/null 2>&1 && verify_one "goose --version"    "goose --version"
  command -v gemini   >/dev/null 2>&1 && verify_one "gemini --version"   "gemini --version"
  command -v kimi     >/dev/null 2>&1 && verify_one "kimi --version"     "kimi --version"
  command -v opencode >/dev/null 2>&1 && verify_one "opencode --version" "opencode --version"

  # Add-ons (only if installed)
  command -v obsidian-cli >/dev/null 2>&1 && verify_one "obsidian-cli list-vaults" "obsidian-cli list-vaults"
  command -v markitdown   >/dev/null 2>&1 && verify_one "markitdown --version"     "markitdown --version"
}

verify_doctor() {
  # Doctor mode: same as verify, but also report missing CLIs and suggest installs.
  verify_all
  step "Doctor — suggested next steps"
  command -v claude   >/dev/null 2>&1 || hint "Claude Code not found. Install: https://docs.claude.com/claude-code"
  command -v codex    >/dev/null 2>&1 || hint "Codex not found. Install: npm i -g @openai/codex"
  command -v goose    >/dev/null 2>&1 || hint "Goose not found. Install: curl -fsSL https://block.github.io/goose/install.sh | sh"
  command -v gemini   >/dev/null 2>&1 || hint "Gemini CLI not found. Install: npm i -g @google/gemini-cli"
  command -v kimi     >/dev/null 2>&1 || hint "Kimi CLI not found. Install: pipx install kimi-cli"
  command -v opencode >/dev/null 2>&1 || hint "OpenCode not found. Install: curl -fsSL https://opencode.ai/install | sh"
  command -v ollama   >/dev/null 2>&1 || hint "Ollama not found. Install: bash $BUNDLE_DIR/scripts/install-ollama.sh"
}
