#!/usr/bin/env bash
# PreToolUse(Bash) — block git commits that include AI attribution lines.
# Why: matches the user's feedback_no_coauthored rule — no Co-Authored-By,
# no "Generated with Claude Code", no 🤖 footer.
#
# Exit 2 = block, message goes back to Claude for self-correction.

set -euo pipefail

# Hooks receive JSON on stdin
payload="$(cat)"
command="$(echo "$payload" | jq -r '.tool_input.command // ""')"

# Only intercept git commit commands
if ! echo "$command" | grep -qE 'git[[:space:]]+commit'; then
  exit 0
fi

# Scan the command for banned phrases
banned_pattern='(Co-Authored-By:[[:space:]]*Claude|Generated with \[?Claude Code|🤖[[:space:]]*Generated with|claude\.com/claude-code)'
if echo "$command" | grep -qiE "$banned_pattern"; then
  cat <<MSG >&2
BLOCKED: commit message contains AI attribution.

This user's rule is: no Co-Authored-By, no "Generated with Claude Code" footer,
no 🤖 emoji. Rewrite the commit message without those lines and try again.

Detected in: $(echo "$command" | grep -oiE "$banned_pattern" | head -3)
MSG
  exit 2
fi

exit 0
