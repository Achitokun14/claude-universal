#!/usr/bin/env bash
# tests/smoke.sh — basic smoke test for setup.sh.
# Runs ./setup --doctor and ./setup --dry-run --yes against an isolated $HOME.
# Exits 0 if all expected lines are present, non-zero otherwise.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMPHOME="$(mktemp -d -t cu-smoke-XXXXXX)"
TMPOUT="$(mktemp -t cu-smoke-out-XXXXXX)"
PASS=0
FAIL=0

cleanup() { rm -rf "$TMPHOME" "$TMPOUT"; }
trap cleanup EXIT

ok()   { printf '  ✓ %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  ✗ %s\n' "$1" >&2; FAIL=$((FAIL+1)); }
contains() {
  local label="$1" file="$2" needle="$3"
  if grep -qF -- "$needle" "$file" 2>/dev/null; then ok "$label"; else bad "$label"; fi
}

echo "=== claude-universal smoke test ==="
echo "  REPO:    $REPO_DIR"
echo "  TMPHOME: $TMPHOME"

# T1 — version
echo
echo "--- T1: --version ---"
if "$REPO_DIR/setup" --version > "$TMPOUT" 2>&1; then ok "version exits 0"; else bad "version exits 0"; fi
expected="claude-universal $(cat "$REPO_DIR/VERSION")"
if [[ "$(cat "$TMPOUT")" = "$expected" ]]; then ok "version matches VERSION file"; else bad "version matches VERSION file"; fi

# T2 — help
echo
echo "--- T2: --help ---"
if "$REPO_DIR/setup" --help > "$TMPOUT" 2>&1; then ok "help exits 0"; else bad "help exits 0"; fi
contains "help contains Usage:" "$TMPOUT" "Usage:"

# T3 — doctor (isolated HOME)
echo
echo "--- T3: --doctor ---"
if HOME="$TMPHOME" "$REPO_DIR/setup" --doctor > "$TMPOUT" 2>&1; then ok "doctor exits 0"; else bad "doctor exits 0"; fi
contains "doctor reports environment" "$TMPOUT" "Detected environment"

# T4 — dry-run + yes through all 8 phases
echo
echo "--- T4: --dry-run --yes ---"
if HOME="$TMPHOME" "$REPO_DIR/setup" --dry-run --yes > "$TMPOUT" 2>&1; then ok "dry-run exits 0"; else bad "dry-run exits 0"; fi
contains "dry-run reaches phase 1" "$TMPOUT" "1/8"
contains "dry-run reaches phase 8" "$TMPOUT" "8/8"
if [[ ! -f "$TMPHOME/.claude/.claude-universal-manifest.json" ]]; then ok "dry-run did NOT write manifest"; else bad "dry-run did NOT write manifest"; fi

# T5 — install.sh user --dry-run
echo
echo "--- T5: install.sh user --dry-run ---"
if HOME="$TMPHOME" bash "$REPO_DIR/install.sh" --dry-run user > "$TMPOUT" 2>&1; then ok "install.sh exits 0"; else bad "install.sh exits 0"; fi
contains "install.sh reports user scope" "$TMPOUT" "User scope"

# T6 — skill-router on a known prompt (use isolated HOME so dedup state is fresh)
echo
echo "--- T6: skill-router.sh ---"
HOME="$TMPHOME" printf '%s' '{"prompt":"plan a railway deployment"}' \
  | HOME="$TMPHOME" "$REPO_DIR/user/hooks/skill-router.sh" > "$TMPOUT" 2>&1 || true
contains "router emits Skill hints header" "$TMPOUT" "Skill hints"
contains "router suggests plan skill"      "$TMPOUT" "\`plan\`"

# T7 — skill-router silent on short prompts (also isolated HOME)
echo
echo "--- T7: skill-router silent on short prompt ---"
HOME="$TMPHOME/t7" mkdir -p "$TMPHOME/t7"
HOME="$TMPHOME/t7" printf '%s' '{"prompt":"hi"}' \
  | HOME="$TMPHOME/t7" "$REPO_DIR/user/hooks/skill-router.sh" > "$TMPOUT" 2>&1 || true
if [[ ! -s "$TMPOUT" ]]; then ok "router silent on short prompt"; else bad "router silent on short prompt"; fi

# Summary
echo
echo "=== summary: $PASS pass, $FAIL fail ==="
[[ "$FAIL" -eq 0 ]]
