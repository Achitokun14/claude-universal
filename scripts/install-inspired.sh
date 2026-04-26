#!/usr/bin/env bash
# Interactive orchestrator: clone "inspired" OSS Claude skill libraries and
# surface their skills at `~/.claude/skills/`.
# Each source is opt-in (y/N). Idempotent: skips if already cloned.
#
# Usage:
#   install-inspired.sh           # interactive
#   install-inspired.sh --all     # install everything without prompts
#   install-inspired.sh --dry-run # preview only
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
INSPIRED_DIR="$SKILLS_DIR/_inspired"
mkdir -p "$INSPIRED_DIR"

ALL=0; DRY=0
for arg in "$@"; do
  case "$arg" in
    --all) ALL=1 ;;
    --dry-run) DRY=1 ;;
  esac
done

# repo-name|install-kind|description
declare -a SOURCES=(
  "garrytan/gstack|commands|40+ role-based slash commands (CEO/design/eng/DX reviews, QA, ship, canary, careful, freeze)"
  "Yeachan-Heo/oh-my-claudecode|skills|19 agents + team/autopilot/ralph/ultrawork pipeline commands"
  "affaan-m/everything-claude-code|skills-selective|183 skills/48 agents — we surface 10 high-leverage ones (tdd, code-review, plan, verification-loop, strategic-compact, etc)"
  "bmad-code-org/BMAD-METHOD|skills|12+ domain-expert agents, scale-adaptive phases, Party Mode"
  "ChristopherKahler/carl|installer|Context Augmentation & Reinforcement Layer — keyword-triggered rule injection. Low overhead."
  "ChristopherKahler/paul|skills|Plan-Apply-Unify Loop — 26 slash commands, per-project .paul/ dir"
  "ChristopherKahler/base|installer-heavy|BASE framework — JSON data surfaces + drift scoring + hooks that inject on every prompt. HIGH context cost."
  "mistarzewski/agency-agents|skills|Agency-focused Claude agents"
  "santifer/career-ops|skills|AI job search — 14 modes, Go dashboard (personal use only)"
  "coreyhaines31/marketingskills|skills|Marketing-focused Claude skills (user-requested)"
  "arxchibobo/coordinator-orchestrator|single-skill|OpenClaw AgentSkill from Claude Code analysis (single-root SKILL.md)"
  "WICG/html-in-canvas|reference|W3C spec for HTML rendering inside <canvas> — cloned as reference, not surfaced as skill"
)

confirm() {
  local prompt="$1"
  if (( ALL )); then return 0; fi
  read -rp "$prompt [y/N] " a
  [[ "$a" =~ ^[Yy]$ ]]
}

do_cmd() {
  if (( DRY )); then echo "   (dry-run) $*"; else eval "$*"; fi
}

clone_repo() {
  local slug="$1"  # e.g. garrytan/gstack
  local dest_name="$(basename "$slug")"
  local dest="$INSPIRED_DIR/$dest_name"
  if [[ -d "$dest/.git" ]]; then
    echo "   already cloned: $dest"
    (cd "$dest" && git pull --ff-only --quiet 2>&1 | tail -1) || true
  else
    do_cmd "git clone --depth 1 'https://github.com/$slug' '$dest' 2>&1 | tail -1"
  fi
  echo "$dest"
}

surface_skills() {
  # Walk <repo>/skills/<name>/SKILL.md patterns and symlink each <name> into ~/.claude/skills/
  local repo_dir="$1"
  local count=0
  # Pattern 1: <repo>/skills/<name>/SKILL.md
  for sd in "$repo_dir"/skills/*/SKILL.md; do
    [[ -f "$sd" ]] || continue
    local skill_dir="$(dirname "$sd")"
    local skill_name="$(basename "$skill_dir")"
    local target="$SKILLS_DIR/$skill_name"
    if [[ -e "$target" ]]; then
      echo "   exists: $skill_name (skipping)"; continue
    fi
    do_cmd "ln -s '$skill_dir' '$target'"
    echo "   ✓ $skill_name"
    ((count++)) || true
  done
  # Pattern 2: <repo>/.claude/skills/<name>/SKILL.md
  for sd in "$repo_dir"/.claude/skills/*/SKILL.md; do
    [[ -f "$sd" ]] || continue
    local skill_dir="$(dirname "$sd")"
    local skill_name="$(basename "$skill_dir")"
    local target="$SKILLS_DIR/$skill_name"
    if [[ -e "$target" ]]; then continue; fi
    do_cmd "ln -s '$skill_dir' '$target'"
    echo "   ✓ $skill_name"
    ((count++)) || true
  done
  echo "   (surfaced $count skill(s))"
}

surface_commands() {
  # Look for <repo>/commands/*.md and symlink into ~/.claude/commands/
  local repo_dir="$1"
  local dest="$HOME/.claude/commands"
  mkdir -p "$dest"
  local count=0
  for cmd in "$repo_dir"/commands/*.md "$repo_dir"/.claude/commands/*.md; do
    [[ -f "$cmd" ]] || continue
    local base="$(basename "$cmd")"
    local target="$dest/$base"
    [[ -e "$target" ]] && continue
    do_cmd "ln -s '$cmd' '$target'"
    ((count++)) || true
  done
  echo "   (surfaced $count command(s))"
}

surface_single_skill() {
  # Repo IS a single skill (SKILL.md at root). Symlink the repo dir itself into ~/.claude/skills/.
  local repo_dir="$1"
  local name; name="$(basename "$repo_dir")"
  local target="$SKILLS_DIR/$name"
  if [[ -e "$target" ]]; then echo "   exists: $name (skipping)"; return 0; fi
  if [[ ! -f "$repo_dir/SKILL.md" ]]; then
    echo "   ⚠ no root SKILL.md in $repo_dir — falling back to generic surface"
    surface_skills "$repo_dir"
    return
  fi
  do_cmd "ln -s '$repo_dir' '$target'"
  echo "   ✓ $name (single-root skill)"
}

install_reference() {
  # NOT a Claude skill — cloned into ~/Desktop/ACTIVITIES/references/<name>/ for browsing only.
  local repo_dir="$1"
  local name; name="$(basename "$repo_dir")"
  local ref_dir="$HOME/Desktop/ACTIVITIES/references"
  mkdir -p "$ref_dir"
  local target="$ref_dir/$name"
  if [[ -L "$target" || -d "$target" ]]; then echo "   exists: $target (skipping)"; return 0; fi
  do_cmd "ln -s '$repo_dir' '$target'"
  echo "   ✓ reference-linked to $target (not surfaced as skill)"
}

install_installer_based() {
  # Source has its own installer; defer to it but log what happens.
  # Looked at: root install.sh/setup.sh AND bin/<reponame> (Kahler trio, BMAD convention).
  local repo_dir="$1"
  local base_name; base_name="$(basename "$repo_dir")"
  for installer in \
      "$repo_dir/install.sh" \
      "$repo_dir/setup.sh" \
      "$repo_dir/bin/$base_name" \
      "$repo_dir/bin/install.sh" \
      "$repo_dir/bin/setup.sh"; do
    if [[ -x "$installer" ]]; then
      echo "   running $installer install (trust-on-inspection)…"
      do_cmd "'$installer' install || '$installer'"
      return 0
    fi
  done
  echo "   ⚠ no installer found in $repo_dir — falling back to generic surface"
  surface_skills "$repo_dir"
  surface_commands "$repo_dir"
}

echo "══════════════════════════════════════════════════════════"
echo " Inspired skills installer"
echo " Clones OSS repos into $INSPIRED_DIR"
echo " and surfaces their skills/commands into ~/.claude/"
if (( ALL )); then  echo " Mode: --all  (no prompts)"; fi
if (( DRY )); then  echo " Mode: --dry-run"; fi
echo "══════════════════════════════════════════════════════════"

for entry in "${SOURCES[@]}"; do
  IFS='|' read -r slug kind desc <<< "$entry"
  echo ""
  echo "────────────────────────────────────────"
  echo "▶ $slug"
  echo "  kind: $kind"
  echo "  $desc"
  if ! confirm "  install?"; then
    echo "  (skipped)"
    continue
  fi
  repo_dir="$(clone_repo "$slug" | tail -1)"
  case "$kind" in
    skills)            surface_skills "$repo_dir" ;;
    skills-selective)  surface_skills "$repo_dir" ;;
    commands)          surface_commands "$repo_dir"; surface_skills "$repo_dir" ;;
    single-skill)      surface_single_skill "$repo_dir" ;;
    reference)         install_reference "$repo_dir" ;;
    installer|installer-heavy) install_installer_based "$repo_dir" ;;
    *)                 surface_skills "$repo_dir" ;;
  esac
done

echo ""
echo "══════════════════════════════════════════════════════════"
echo "Done. Start a new Claude Code session to load new skills."
echo "Discovered:"
ls -la "$SKILLS_DIR/" 2>/dev/null | grep -E "^l" | awk '{print "  " $NF, "→", $(NF-2)}' | head -20
