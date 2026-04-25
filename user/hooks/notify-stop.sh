#!/usr/bin/env bash
# Stop — desktop notification when Claude Code finishes responding.
# Silent if notify-send isn't available (e.g. headless session).

set -euo pipefail

if ! command -v notify-send >/dev/null 2>&1; then
  exit 0
fi

# Only notify for sessions that lasted long enough to matter.
# Hooks run in the session cwd; project name = basename.
project="$(basename "$PWD")"

notify-send -u normal -i utilities-terminal \
  "Claude Code — done" \
  "Session ready in $project" 2>/dev/null || true

exit 0
