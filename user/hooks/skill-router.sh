#!/usr/bin/env bash
# skill-router.sh — UserPromptSubmit hook.
#
# Scans user prompt against curated keyword→skill map, emits a compact
# skill-hint block. Model still uses the `Skill` tool to actually load
# a skill; this hook only nudges which ones are relevant.
#
# Design goals
#   • Zero output when no skill matches (most prompts get nothing)
#   • Hard cap: ≤ 5 hints per prompt (worst-case ~80 tokens)
#   • Dedup: same hint signature twice in a row → skip second
#   • Config-driven: triggers live in ~/.claude/hooks/skill-router.conf
#   • No plug-in calls, no LLM calls, pure bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer user-scope conf; fall back to script-adjacent (test runs + fresh installs)
if [[ -f "${HOME}/.claude/hooks/skill-router.conf" ]]; then
  ROUTER_CONF="${HOME}/.claude/hooks/skill-router.conf"
else
  ROUTER_CONF="${SCRIPT_DIR}/skill-router.conf"
fi
STATE_DIR="${HOME}/.claude/hooks/.state"
STATE_FILE="${STATE_DIR}/skill-router.last"
MAX_HINTS=5
MIN_PROMPT_LEN=10

mkdir -p "$STATE_DIR"

# Read hook input: Claude hook protocol passes JSON on stdin.
# Fields we care about: .prompt  (or .user_prompt  for older versions).
INPUT="$(cat)"
PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // .user_prompt // .hook_event_name // ""' 2>/dev/null)"

# Fallback: if not JSON, treat whole stdin as prompt (defensive).
[[ -z "$PROMPT" && -n "$INPUT" ]] && PROMPT="$INPUT"

# Too short or empty → silent exit.
if [[ ${#PROMPT} -lt $MIN_PROMPT_LEN ]]; then exit 0; fi

# Config missing → silent exit.
if [[ ! -f "$ROUTER_CONF" ]]; then exit 0; fi

PROMPT_LC="$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')"

# Parse config. Format per line:
#   pattern|||skill_name|||one-line purpose
# Lines starting with # or blank are ignored.
# Indexed array (bash 3.2+) — no associative arrays so we work on macOS /bin/bash too.
HINTS=()
SEEN_NAMES=":"  # colon-delimited list, e.g. ":plan:nextjs:"
HINT_COUNT=0
while IFS='' read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  # Skip comment lines (leading whitespace + #). Bash 3.2 compatible.
  trimmed="${line#"${line%%[![:space:]]*}"}"
  case "$trimmed" in '#'*) continue ;; esac
  pat="${line%%|||*}"
  rest="${line#*|||}"
  name="${rest%%|||*}"
  purpose="${rest#*|||}"
  [[ -z "$pat" || -z "$name" ]] && continue

  # Use grep (not bash =~) so the regex engine is consistent across BSD + GNU.
  if printf '%s' "$PROMPT_LC" | grep -Eq -- "$pat"; then
    # Dedup within this invocation (string-list, no associative array).
    case "$SEEN_NAMES" in *":${name}:"*) continue ;; esac
    SEEN_NAMES="${SEEN_NAMES}${name}:"
    HINTS[HINT_COUNT]="${name}|||${purpose}"
    HINT_COUNT=$((HINT_COUNT + 1))
    [[ $HINT_COUNT -ge $MAX_HINTS ]] && break
  fi
done < "$ROUTER_CONF"

# No matches → silent exit.
[[ ${#HINTS[@]} -eq 0 ]] && exit 0

# Build output signature (for dedup across prompts). Use shasum (portable) over
# sha1sum (linux-only). Fall back to md5sum/md5 if neither is available.
_hash() {
  if command -v shasum  >/dev/null 2>&1; then shasum -a 1
  elif command -v sha1sum >/dev/null 2>&1; then sha1sum
  elif command -v md5sum  >/dev/null 2>&1; then md5sum
  elif command -v md5     >/dev/null 2>&1; then md5
  else cat  # no hash; dedup degraded but functional
  fi
}
SIG="$(printf '%s\n' "${HINTS[@]}" | _hash | cut -c1-12)"
LAST_SIG="$(cat "$STATE_FILE" 2>/dev/null || echo '')"

# Same hints as last prompt → skip (user saw them already).
if [[ "$SIG" == "$LAST_SIG" ]]; then
  exit 0
fi
printf '%s' "$SIG" > "$STATE_FILE"

# Emit compact block. Claude Code injects stdout into context.
echo "## Skill hints (consider invoking via Skill tool)"
for h in "${HINTS[@]}"; do
  n="${h%%|||*}"
  p="${h#*|||}"
  printf -- '- `%s` — %s\n' "$n" "$p"
done

exit 0
