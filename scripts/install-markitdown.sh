#!/usr/bin/env bash
# install-markitdown.sh — Install Microsoft markitdown (file → markdown converter).
#
# Supports: PDF, DOCX, XLSX, PPTX, images (with OCR), audio, HTML, JSON, XML, ZIP, CSV.
# Idempotent. Uses pip --user; falls back to pipx if available.

set -euo pipefail
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
say() { printf '▸ %s\n' "$*"; }

if command -v markitdown >/dev/null 2>&1; then
  say "${GREEN}markitdown already installed: $(markitdown --version 2>&1 | head -1)${NC}"
  exit 0
fi

if command -v pipx >/dev/null 2>&1; then
  say "installing via pipx"
  pipx install 'markitdown[all]'
elif command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
  PIP=$(command -v pip3 || command -v pip)
  say "installing via $PIP --user"
  $PIP install --user --break-system-packages 'markitdown[all]' 2>&1 | tail -5
else
  say "${RED}neither pipx nor pip found — install Python first${NC}"
  exit 1
fi

if command -v markitdown >/dev/null 2>&1; then
  say "${GREEN}✓ markitdown installed: $(markitdown --version 2>&1 | head -1)${NC}"
  echo "  Use: markitdown <file.pdf|docx|xlsx|pptx|...> > output.md"
  echo "  Or:  cat file.pdf | markitdown > output.md"
else
  say "${YELLOW}install completed but markitdown not on PATH — check ~/.local/bin or pipx env${NC}"
  exit 1
fi
