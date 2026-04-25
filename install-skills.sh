#!/usr/bin/env bash
# install-skills.sh — mirror the 4 global design skills on a fresh machine.
# Run after install.sh user. Idempotent (skip if already present).
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"

clone_once() {
  local repo="$1" dest="$2"
  if [[ -d "$SKILLS_DIR/$dest" ]]; then
    echo "▸ $dest already cloned — pulling latest"
    git -C "$SKILLS_DIR/$dest" pull --ff-only 2>&1 | tail -1
  else
    echo "▸ cloning $repo → $dest"
    git clone --depth 1 "https://github.com/$repo" "$SKILLS_DIR/$dest" 2>&1 | tail -1
  fi
}

symlink_once() {
  local link="$1" target="$2"
  if [[ ! -e "$SKILLS_DIR/$link" ]]; then
    ln -s "$target" "$SKILLS_DIR/$link"
    echo "   ✓ symlinked $link"
  fi
}

# 1. Emil Kowalski
clone_once "emilkowalski/skill" "emilkowalski-skill"
symlink_once "emil-design-eng" "emilkowalski-skill/skills/emil-design-eng"

# 2. Taste + siblings
clone_once "Leonxlnx/taste-skill" "taste-skill-repo"
for variant in taste-skill minimalist-skill soft-skill brutalist-skill redesign-skill; do
  if [[ -d "$SKILLS_DIR/taste-skill-repo/skills/$variant" ]]; then
    symlink_once "$variant" "taste-skill-repo/skills/$variant"
  fi
done

# 3. UI/UX Pro Max
clone_once "nextlevelbuilder/ui-ux-pro-max-skill" "ui-ux-pro-max-skill"
symlink_once "ui-ux-pro-max" "ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max"

# 4. Impeccable — plugin (not a skill dir). Ensure it's in enabledPlugins.
SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  enabled="$(python3 -c "
import json
try:
  d = json.load(open('$SETTINGS'))
  print(d.get('enabledPlugins', {}).get('impeccable@impeccable', False))
except Exception as e:
  print('false')
" 2>/dev/null)"
  if [[ "$enabled" != "True" ]]; then
    echo "▸ enabling impeccable@impeccable in settings.json"
    python3 - <<PY
import json, os
p = "$SETTINGS"
d = json.load(open(p))
d.setdefault('enabledPlugins', {})['impeccable@impeccable'] = True
# Also ensure the marketplace is registered
d.setdefault('extraKnownMarketplaces', {})['impeccable'] = {'source': {'source': 'github', 'repo': 'pbakaus/impeccable'}}
json.dump(d, open(p, 'w'), indent=2)
print('   ✓ settings.json updated')
PY
  else
    echo "▸ impeccable plugin already enabled"
  fi
fi

echo ""
echo "✅ Design skills ready. Start a new Claude Code session to load them."
echo "   Verify: ls -la $SKILLS_DIR | grep -E 'emil|taste|ui-ux|minimalist|soft|brutal|redesign'"
