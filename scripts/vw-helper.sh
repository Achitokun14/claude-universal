#!/usr/bin/env bash
# Safe Bitwarden/Vaultwarden secret retrieval for scripts/commands.
# - Never echoes the secret value
# - Accepts an item name + field (password/username/totp/notes)
# - Writes the value to stdout ONLY when called directly (so `$(vw-helper item-name)` works)
# - Bails with a clear message if `bw` CLI isn't installed or vault is locked
#
# Usage:
#   vw-helper.sh <item-name> [field]
#     field default = password
#
# Prereq:
#   sudo snap install bw   OR   brew install bitwarden-cli
#   export BW_SESSION="$(bw unlock --raw)"   (unlock once per terminal session)
set -euo pipefail

ITEM="${1:-}"
FIELD="${2:-password}"
[[ -z "$ITEM" ]] && { echo "usage: $0 <item-name> [password|username|totp|notes]" >&2; exit 2; }

if ! command -v bw >/dev/null 2>&1; then
  echo "error: bw CLI not installed. Install: sudo snap install bw  OR  brew install bitwarden-cli" >&2
  exit 3
fi

if [[ -z "${BW_SESSION:-}" ]]; then
  echo "error: BW_SESSION not set. Unlock once: export BW_SESSION=\"\$(bw unlock --raw)\"" >&2
  exit 4
fi

case "$FIELD" in
  password) bw get password "$ITEM" --session "$BW_SESSION" 2>/dev/null ;;
  username) bw get username "$ITEM" --session "$BW_SESSION" 2>/dev/null ;;
  totp)     bw get totp "$ITEM"     --session "$BW_SESSION" 2>/dev/null ;;
  notes)    bw get notes "$ITEM"    --session "$BW_SESSION" 2>/dev/null ;;
  uri)      bw get uri "$ITEM"      --session "$BW_SESSION" 2>/dev/null ;;
  *)        echo "error: unknown field '$FIELD'" >&2; exit 5 ;;
esac
