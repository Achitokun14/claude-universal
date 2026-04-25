#!/usr/bin/env bash
# SessionStart(startup|resume) — delegates to tool-inventory.sh for a compact context injection.
# Kept as a separate entry point so users can replace/disable the heavier inventory if they want
# a minimal context and still have git info.

set -euo pipefail

# If the tool-inventory script exists and is executable, prefer it (it already includes git info).
if [[ -x "$HOME/.claude/hooks/tool-inventory.sh" ]]; then
  exec "$HOME/.claude/hooks/tool-inventory.sh"
fi

# Fallback: just git context (original behavior)
if git -C . rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  dirty="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  recent="$(git log -3 --pretty=format:'  - %h %s' 2>/dev/null)"
  cat <<CTX
# Session Context (auto-injected)
- Branch: $branch · Uncommitted: $dirty file(s)
- Recent commits:
$recent
CTX
fi

exit 0
