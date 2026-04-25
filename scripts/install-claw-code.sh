#!/usr/bin/env bash
# install-claw-code.sh — Install ultraworkers/claw-code and wire it to route through
# a MiniMax-compatible aggregator (OpenAI-compatible endpoint) + optional Ollama cloud.
#
# This is a STANDALONE CLI — it doesn't replace Claude Code; both coexist.
#
# Prereqs (all verified):
#   - Rust toolchain (rustc + cargo)
#   - git, curl
#
# Env vars YOU must set in your shell (never committed):
#   export CLAW_API_KEY="sk-cp-..."                    # your aggregator key
#   export CLAW_API_BASE_URL="https://api.<provider>.com/v1"  # aggregator endpoint
#   (optional) export OLLAMA_HOST="https://<your-cloud-ollama>"
#
# Usage:
#   ./install-claw-code.sh                  # clone + build + configure
#   ./install-claw-code.sh --rebuild        # just re-build from existing clone
#   ./install-claw-code.sh --uninstall      # remove build + config (keeps clone)

set -euo pipefail

CLONE_DIR="$HOME/.claude/skills/_inspired/claw-code"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/claw"

MODE="install"
for arg in "$@"; do
  case "$arg" in
    --rebuild)   MODE="rebuild" ;;
    --uninstall) MODE="uninstall" ;;
    --help|-h)
      grep '^#' "$0" | sed 's/^# *//'
      exit 0 ;;
  esac
done

say() { printf '▸ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*" >&2; }

# ── Uninstall path ──────────────────────────────────────────────────────
if [[ "$MODE" == "uninstall" ]]; then
  rm -f "$BIN_DIR/claw"
  rm -rf "$CONFIG_DIR"
  say "removed $BIN_DIR/claw and $CONFIG_DIR (clone at $CLONE_DIR preserved)"
  exit 0
fi

# ── Dependency check ────────────────────────────────────────────────────
for dep in git curl rustc cargo; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    warn "missing: $dep — install it and retry"
    exit 2
  fi
done

# ── Clone (or pull) ─────────────────────────────────────────────────────
if [[ ! -d "$CLONE_DIR/.git" ]]; then
  say "cloning ultraworkers/claw-code into $CLONE_DIR"
  mkdir -p "$(dirname "$CLONE_DIR")"
  git clone --depth 1 https://github.com/ultraworkers/claw-code "$CLONE_DIR"
else
  say "claw-code clone exists — pulling latest"
  git -C "$CLONE_DIR" pull --ff-only --quiet || warn "pull failed, continuing with existing tree"
fi

# ── Build (release) ─────────────────────────────────────────────────────
if [[ "$MODE" == "rebuild" || ! -x "$CLONE_DIR/rust/target/release/claw" ]]; then
  say "building claw (release profile) — this may take several minutes"
  (
    cd "$CLONE_DIR"
    CLAW_SKIP_VERIFY=1 bash ./install.sh --release || {
      warn "install.sh failed — trying direct cargo build"
      cd rust
      cargo build --release
    }
  )
fi

# ── Place binary on PATH ───────────────────────────────────────────────
BUILT="$CLONE_DIR/rust/target/release/claw"
if [[ ! -x "$BUILT" ]]; then
  warn "build artifact not found at $BUILT — check build errors above"
  exit 3
fi
mkdir -p "$BIN_DIR"
ln -sf "$BUILT" "$BIN_DIR/claw"
say "symlinked: $BIN_DIR/claw → $BUILT"

# ── Config: wire to aggregator + MiniMax models ────────────────────────
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/env.sh" <<'ENVSH'
#!/usr/bin/env bash
# claw-code environment — source this in your ~/.zshrc or ~/.bashrc:
#   source ~/.config/claw/env.sh
#
# Fill these in your shell profile (never commit real values):
#   export CLAW_API_KEY="sk-cp-..."                # your aggregator key (e.g. from packycode.com / chutes.ai / etc.)
#   export CLAW_API_BASE_URL="https://api.<provider>.com/v1"

# Claw consumes these standard env var names — no special claw-only variables needed.
# It auto-detects OpenAI-compatible endpoints when OPENAI_BASE_URL is set.

if [[ -n "${CLAW_API_KEY:-}" ]]; then
  export OPENAI_API_KEY="$CLAW_API_KEY"
fi

if [[ -n "${CLAW_API_BASE_URL:-}" ]]; then
  export OPENAI_BASE_URL="$CLAW_API_BASE_URL"
fi

# Ollama cloud (optional)
if [[ -n "${OLLAMA_HOST:-}" ]]; then
  export OLLAMA_API_BASE="$OLLAMA_HOST"
fi
ENVSH
chmod +x "$CONFIG_DIR/env.sh"
say "wrote $CONFIG_DIR/env.sh (source it from your shell profile)"

# ── Model routing hints — model preset file ─────────────────────────────
cat > "$CONFIG_DIR/models.md" <<'MODELS'
# Claw Code — model routing cheat-sheet

Once you've exported `CLAW_API_KEY` + `CLAW_API_BASE_URL` and sourced `~/.config/claw/env.sh`,
invoke `claw` with a model prefix so it picks the right backend:

## Primary (aggregator — MiniMax family via OpenAI-compatible endpoint)

    claw --model openai/MiniMax-M2           # text reasoning
    claw --model openai/MiniMax-M2.7         # latest text (if supported by your aggregator)
    claw --model openai/minimax-music-2.6    # music generation
    claw --model openai/speech-2.8-hd        # TTS
    claw --model openai/hailuo-2.3-fast      # video (fast tier)
    claw --model openai/hailuo-2.3           # video (quality tier)

## Alternative providers via the same key (if your aggregator supports them)

    claw --model openai/glm-4.5-plus         # Zhipu GLM
    claw --model openai/glm-5.1              # if available on your plan
    claw --model openai/qwen-plus            # Alibaba Qwen
    claw --model openai/deepseek-chat        # DeepSeek

## Ollama cloud (if OLLAMA_HOST is set)

    claw --model ollama/<model-name>         # any model served by your Ollama cloud

## Anthropic (if you add an Anthropic key separately)

    export ANTHROPIC_API_KEY="sk-ant-..."
    claw --model claude-sonnet-4-6

## Useful claw subcommands

    claw doctor               # health check after install
    claw acp                  # ACP/Zed status (read-only at time of install)
    claw --help               # full command surface
MODELS
say "wrote $CONFIG_DIR/models.md"

# ── Shell-profile hint ─────────────────────────────────────────────────
cat <<'DONE'

✓ claw-code installed.

NEXT STEPS — do these manually (I can't touch your shell profile without asking):

  1. Add to your ~/.zshrc (or ~/.bashrc):

       export CLAW_API_KEY="sk-cp-..."                      # your real key
       export CLAW_API_BASE_URL="https://api.<provider>/v1" # your aggregator endpoint
       source ~/.config/claw/env.sh

  2. Reload your shell:
       exec zsh                                   # or: source ~/.zshrc

  3. Smoke-test:
       claw doctor
       claw --model openai/MiniMax-M2 "ping"       # short hello-world

Notes:
  - Your key is NEVER stored in any committed file — only in your shell profile + env vars.
  - If your aggregator uses a different model-name prefix (e.g. "minimax/" not "openai/"),
    see https://github.com/ultraworkers/claw-code/blob/main/USAGE.md
  - For Ollama cloud: export OLLAMA_HOST="https://<your-cloud-ollama>/"; claw reads it.
DONE
