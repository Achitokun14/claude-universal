#!/usr/bin/env bash
# Stop — desktop notification when Claude Code finishes responding.
# Cross-OS: notify-send (Linux), osascript (macOS), Show-Notification (Windows/WSL).
# Silent if no notifier is available (e.g. headless session).

set -euo pipefail

project="$(basename "$PWD")"
title="Claude Code — done"
body="Session ready in $project"

case "$(uname -s)" in
  Linux*)
    command -v notify-send >/dev/null 2>&1 \
      && notify-send -u normal -i utilities-terminal "$title" "$body" 2>/dev/null \
      || true
    ;;
  Darwin*)
    command -v osascript >/dev/null 2>&1 \
      && osascript -e "display notification \"$body\" with title \"$title\"" 2>/dev/null \
      || true
    ;;
  CYGWIN*|MINGW*|MSYS*)
    command -v powershell.exe >/dev/null 2>&1 \
      && powershell.exe -NoProfile -Command \
         "Add-Type -AssemblyName System.Windows.Forms; \
          \$n = New-Object System.Windows.Forms.NotifyIcon; \
          \$n.Icon = [System.Drawing.SystemIcons]::Information; \
          \$n.Visible = \$true; \
          \$n.ShowBalloonTip(3000, '$title', '$body', 'Info'); \
          Start-Sleep -Seconds 4; \$n.Dispose()" 2>/dev/null \
      || true
    ;;
esac

exit 0
