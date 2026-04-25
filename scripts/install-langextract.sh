#!/usr/bin/env bash
# Install Google langextract (structured extraction with source grounding).
# Exposed to Claude via /extract slash command.
set -euo pipefail

if command -v langextract >/dev/null 2>&1; then
  echo "✓ langextract already installed: $(command -v langextract)"
  exit 0
fi

if command -v uvx >/dev/null 2>&1; then
  echo "▸ Installing langextract via uvx..."
  uvx --python 3.11 pip install langextract 2>&1 | tail -5 || true
elif command -v pipx >/dev/null 2>&1; then
  pipx install langextract 2>&1 | tail -5 || true
elif command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
  python3 -m pip install --user langextract 2>&1 | tail -5 || true
else
  echo "error: need pip, pipx, or uvx to install langextract" >&2
  exit 3
fi

echo ""
echo "✓ langextract should now be importable:"
python3 -c "import langextract; print('version:', langextract.__version__)" 2>/dev/null || \
  echo "⚠ Could not verify. Try: python3 -c 'import langextract'"
echo ""
echo "Note: langextract needs an LLM API key (GEMINI_API_KEY, OPENAI_API_KEY) at call time."
