#!/usr/bin/env bash
# prune-skills.sh — Safely disable Tier-D skills by moving their symlinks to ~/.claude/skills/_disabled/<category>/
#
# NON-DESTRUCTIVE: moves, doesn't delete. Reverse with:
#   mv ~/.claude/skills/_disabled/<cat>/* ~/.claude/skills/
#
# Usage:
#   prune-skills.sh              # execute all prunes
#   prune-skills.sh --dry-run    # preview without moving
#   prune-skills.sh --category <cat>   # only one category
#
# Categories:
#   off-stack-langs    — Java/Kotlin/Swift/Dart/Perl/.NET/C++/Django/Laravel/Rails
#   mobile-dev         — iOS/Android/Flutter/Compose
#   off-domain         — healthcare, energy, manufacturing, logistics, DeFi
#   framework-selfmgmt — OMC-*, ECC-*, BMAD-self, career-ops-self
#   duplicates         — document-skills:* twins of example-skills:*
#   niche              — visa-doc-translate, openclaw-persona-forge, etc.

set -euo pipefail

SKILLS="$HOME/.claude/skills"
DISABLED="$SKILLS/_disabled"

DRY=0
ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --category) ONLY="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# *//'
      exit 0 ;;
    *) shift ;;
  esac
done

declare -A CATEGORIES=(
  [off-stack-langs]="java-coding-standards jpa-patterns springboot-patterns springboot-security springboot-tdd springboot-verification kotlin-patterns kotlin-testing kotlin-coroutines-flows kotlin-exposed-patterns kotlin-ktor-patterns compose-multiplatform-patterns perl-patterns perl-security perl-testing cpp-coding-standards cpp-testing dotnet-patterns csharp-testing clickhouse-io django-patterns django-security django-tdd django-verification laravel-patterns laravel-security laravel-tdd laravel-verification laravel-plugin-discovery hexagonal-architecture"
  [mobile-dev]="swift-actor-persistence swift-concurrency-6-2 swift-protocol-di-testing swiftui-patterns dart-flutter-patterns flutter-dart-code-review android-clean-architecture foundation-models-on-device liquid-glass-design"
  [off-domain]="healthcare-phi-compliance healthcare-emr-patterns healthcare-cdss-patterns healthcare-eval-harness hipaa-compliance energy-procurement production-scheduling quality-nonconformance carrier-relationship-management customs-trade-compliance returns-reverse-logistics logistics-exception-management inventory-demand-planning visa-doc-translate evm-token-decimals nodejs-keccak256 agent-payment-x402 llm-trading-agent-security defi-amm-security"
  [framework-selfmgmt]="omc-doctor omc-setup omc-reference omc-teams configure-ecc ecc-tools-cost-audit nanoclaw-repl openclaw-persona-forge career-ops ralphinho-rfc-pipeline"
  [niche]="free-tool-strategy opensource-pipeline investor-outreach investor-materials connections-optimizer social-graph-ranker x-api customer-research videodb pytorch-patterns nutrient-document-processing ai-first-engineering remotion-video-creation agent-payment-x402 gan-style-harness"
)

moved_total=0

move_one() {
  local name="$1" cat="$2"
  local src="$SKILLS/$name"
  if [[ ! -e "$src" ]]; then return 0; fi
  local dst_dir="$DISABLED/$cat"
  local dst="$dst_dir/$name"
  if (( DRY )); then
    echo "  [dry-run] mv $name → _disabled/$cat/"
  else
    mkdir -p "$dst_dir"
    mv "$src" "$dst"
    echo "  moved: $name → _disabled/$cat/"
  fi
  moved_total=$((moved_total + 1))
}

echo "════════════════════════════════════════"
echo " prune-skills.sh"
(( DRY )) && echo " MODE: --dry-run (no changes)" || echo " MODE: live"
[[ -n "$ONLY" ]] && echo " CATEGORY: $ONLY"
echo "════════════════════════════════════════"

for cat in "${!CATEGORIES[@]}"; do
  if [[ -n "$ONLY" && "$cat" != "$ONLY" ]]; then continue; fi
  echo
  echo "── $cat ──"
  for n in ${CATEGORIES[$cat]}; do
    move_one "$n" "$cat"
  done
done

# Dupes: document-skills:* and example-skills:* are identical. Keep document-skills, disable example-skills.
# These are plugin-namespaced, so they live as `example-skills` dir (if symlinked) — not typical.
# We skip plugin-namespaced dupes because they're plugin-managed, not user-scope.

echo
echo "════════════════════════════════════════"
(( DRY )) && echo " would move: $moved_total skills" || echo " moved: $moved_total skills"
echo "════════════════════════════════════════"
echo
if (( ! DRY )) && (( moved_total > 0 )); then
  echo "Reverse any time:"
  echo "  mv ~/.claude/skills/_disabled/<category>/* ~/.claude/skills/"
fi
