#!/usr/bin/env bash
# lib/apply.sh — idempotent apply phase. Calls existing scripts in order.

# Internal: should we skip a named step?
_should_skip() {
  local step="$1"
  [[ ",${SETUP_SKIP:-}," == *",${step},"* ]]
}

# Internal: is "only=user" set?
_only_user() {
  [[ "${SETUP_ONLY:-}" = "user" ]]
}

apply_user_scope() {
  step "1/8 — apply user-scope config"
  if [[ "$SETUP_DRY" -eq 1 ]]; then
    bash "$BUNDLE_DIR/install.sh" --dry-run user 2>&1 | sed 's/^/    /' | tail -10
  else
    bash "$BUNDLE_DIR/install.sh" user 2>&1 | tail -10
  fi
}

apply_skills() {
  _only_user && { hint "skip skills (--only=user)"; return; }
  _should_skip skills && { hint "skip skills (--skip)"; return; }
  step "2/8 — install design-skill family"
  if [[ "$SETUP_DRY" -eq 1 ]]; then
    hint "(dry-run) bash install-skills.sh"
  else
    bash "$BUNDLE_DIR/install-skills.sh" 2>&1 | tail -5 || warn "install-skills exited non-zero"
  fi
}

apply_scaffolding() {
  _only_user && { hint "skip scaffolding (--only=user)"; return; }
  _should_skip scaffolding && { hint "skip scaffolding (--skip)"; return; }
  step "3/8 — init llm-wiki + improvement-state"
  for s in init-llm-wiki.sh init-improvement-state.sh bootstrap-resources.sh; do
    if [[ "$SETUP_DRY" -eq 1 ]]; then
      hint "(dry-run) bash scripts/$s"
    else
      bash "$BUNDLE_DIR/scripts/$s" 2>&1 | tail -2 || warn "$s exited non-zero"
    fi
  done
}

apply_cross_tool_sync() {
  _only_user && { hint "skip agent sync (--only=user)"; return; }
  _should_skip sync && { hint "skip agent sync (--skip)"; return; }
  step "4/8 — wire detected AI CLIs"
  if [[ "$SETUP_DRY" -eq 1 ]]; then
    hint "(dry-run) bash scripts/sync-cross-tool.sh"
    hint "(dry-run) bash scripts/sync-cross-tool-native.sh"
  else
    bash "$BUNDLE_DIR/scripts/sync-cross-tool.sh"        2>&1 | tail -5 || true
    bash "$BUNDLE_DIR/scripts/sync-cross-tool-native.sh" 2>&1 | tail -5 || true
  fi
}

apply_addons() {
  _only_user && { hint "skip add-ons (--only=user)"; return; }
  local with="${SETUP_WITH:-}"
  [[ -z "$with" ]] && { hint "no add-ons requested"; return; }
  step "5/8 — opt-in add-ons: $with"
  IFS=',' read -ra addons <<< "$with"
  for addon in "${addons[@]}"; do
    addon="$(echo "$addon" | xargs)"  # trim
    local script="$BUNDLE_DIR/scripts/install-${addon}.sh"
    if [[ ! -x "$script" ]]; then
      warn "add-on '$addon' not found ($script)"
      continue
    fi
    say "installing add-on: $addon"
    if [[ "$SETUP_DRY" -eq 1 ]]; then
      hint "(dry-run) bash $script"
    else
      bash "$script" 2>&1 | tail -10 || warn "$addon installer exited non-zero"
    fi
  done
}

apply_manifest() {
  step "6/8 — write manifest"
  local manifest="$HOME/.claude/.claude-universal-manifest.json"
  if [[ "$SETUP_DRY" -eq 1 ]]; then
    hint "(dry-run) write $manifest"
    return
  fi
  mkdir -p "$HOME/.claude"
  cat > "$manifest" <<EOF
{
  "version": "$VERSION",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "bundle_dir": "$BUNDLE_DIR",
  "addons": "${SETUP_WITH:-}",
  "host": {
    "os": "$OS",
    "distro": "$DISTRO",
    "arch": "$ARCH"
  }
}
EOF
  ok "manifest: $manifest"
}

apply_all() {
  apply_user_scope
  apply_skills
  apply_scaffolding
  apply_cross_tool_sync
  apply_addons
  apply_manifest
}
