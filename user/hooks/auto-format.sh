#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit) — auto-format the file Claude just touched.
# Uses: biome (JS/TS/JSON/CSS), ruff (Python), rustfmt (Rust), gofmt (Go), prettier fallback.
# Never blocks — formatting failures are logged to stderr but exit 0.

set -euo pipefail

payload="$(cat)"
file_path="$(echo "$payload" | jq -r '.tool_input.file_path // ""')"
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

ext="${file_path##*.}"

format_safe() {
  # Run formatter; swallow errors so we never block the edit loop
  "$@" 2>&1 | head -5 >&2 || true
}

case "$ext" in
  ts|tsx|js|jsx|mjs|cjs|json|jsonc|css)
    if command -v biome >/dev/null 2>&1; then
      format_safe biome format --write "$file_path"
    elif command -v npx >/dev/null 2>&1; then
      format_safe npx --no-install prettier --write "$file_path"
    fi
    ;;
  py|pyi)
    if command -v ruff >/dev/null 2>&1; then
      format_safe ruff format "$file_path"
      format_safe ruff check --fix --unsafe-fixes "$file_path"
    fi
    ;;
  rs)
    command -v rustfmt >/dev/null 2>&1 && format_safe rustfmt "$file_path"
    ;;
  go)
    command -v gofmt >/dev/null 2>&1 && format_safe gofmt -w "$file_path"
    ;;
  md|markdown)
    # prettier if installed; otherwise leave alone
    command -v prettier >/dev/null 2>&1 && format_safe prettier --write "$file_path"
    ;;
esac

exit 0
