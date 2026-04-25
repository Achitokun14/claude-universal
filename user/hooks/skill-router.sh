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

ROUTER_CONF="${HOME}/.claude/hooks/skill-router.conf"
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
declare -a HINTS=()
declare -A SEEN=()
while IFS='' read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  pat="${line%%|||*}"
  rest="${line#*|||}"
  name="${rest%%|||*}"
  purpose="${rest#*|||}"
  [[ -z "$pat" || -z "$name" ]] && continue

  if [[ "$PROMPT_LC" =~ $pat ]]; then
    # Dedup within this invocation.
    [[ -n "${SEEN[$name]:-}" ]] && continue
    SEEN["$name"]=1
    HINTS+=("$name|||$purpose")
    [[ ${#HINTS[@]} -ge $MAX_HINTS ]] && break
  fi
done < "$ROUTER_CONF"

# No matches → silent exit.
[[ ${#HINTS[@]} -eq 0 ]] && exit 0

# Build output signature (for dedup across prompts).
SIG="$(printf '%s\n' "${HINTS[@]}" | sha1sum | cut -c1-12)"
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
