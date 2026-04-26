#!/usr/bin/env bash
# lib/ui.sh — colors, prompts, helpers. Sourced by setup.sh.

# Colors (only when stdout is a TTY)
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; DIM=''; BOLD=''; NC=''
fi

say()  { printf '%s▸%s %s\n' "$BLUE" "$NC" "$*"; }
ok()   { printf '%s✓%s %s\n' "$GREEN" "$NC" "$*"; }
warn() { printf '%s⚠%s %s\n' "$YELLOW" "$NC" "$*" >&2; }
err()  { printf '%s✗%s %s\n' "$RED" "$NC" "$*" >&2; }
die()  { err "$@"; exit 1; }
step() { printf '\n%s═══ %s ═══%s\n' "$BOLD" "$*" "$NC"; }
hint() { printf '%s  %s%s\n' "$DIM" "$*" "$NC"; }

# confirm "Question?" — returns 0 (yes) or 1 (no). Auto-yes if SETUP_YES=1.
confirm() {
  local prompt="$1"
  if [[ "${SETUP_YES:-0}" -eq 1 ]]; then
    echo "$prompt [Y/n] (auto-yes)"
    return 0
  fi
  local reply
  read -r -p "$prompt [Y/n] " reply
  [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# Run a command, but skip in dry-run mode (just print).
run() {
  if [[ "${SETUP_DRY:-0}" -eq 1 ]]; then
    printf '%s  (dry-run)%s %s\n' "$DIM" "$NC" "$*"
  else
    eval "$*"
  fi
}
