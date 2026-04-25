#!/usr/bin/env bash
# Create ~/Desktop/ACTIVITIES/llm-wiki/ with Karpathy-style templates.
# Idempotent: skips files that already exist.
set -euo pipefail

WIKI="$HOME/Desktop/ACTIVITIES/llm-wiki"
mkdir -p "$WIKI"

if [[ ! -f "$WIKI/README.md" ]]; then
  cat > "$WIKI/README.md" <<'MD'
# LLM Wiki

Personal compounding knowledge base. Auto-populated by the `memory-compiler` hook on session end, manually extended via `/learn` and `/wiki` slash commands.

## Structure

- `YYYY-MM-DD.md` — one file per day; each session appends a timestamped block
- `TEMPLATE.md` — entry template
- `index.md` — topic index (hand-curated)
- `README.md` — this file

## Conventions

- **Don't overthink it.** Each entry is a quick note; you'll re-read and promote the good ones later.
- **Tag liberally.** `#learning #bug #pattern #insight #library #gotcha #question`
- **Link freely.** `[[concept]]` for wiki-links, URLs for external.
- **Stay honest.** Record what didn't work alongside what did.

## Growing it

- Every session auto-adds a block to today's file via `memory-compiler.sh`.
- Use `/learn <insight>` mid-session to capture a specific takeaway.
- Use `/wiki <topic>` to recall what you've seen on a subject.
- Weekly: run `/retro` to distill the past week into `weekly/YYYY-WW.md`.

## Karpathy-inspired

The pattern mirrors Andrej Karpathy's LLM wiki: small, frequent, searchable, compound over time. Keep it lean.
MD
fi

if [[ ! -f "$WIKI/TEMPLATE.md" ]]; then
  cat > "$WIKI/TEMPLATE.md" <<'MD'
# <Topic or question>

**Date:** YYYY-MM-DD
**Project:** <name>
**Tags:** #tag1 #tag2

## Context
Why this came up.

## What I learned
Core insight in 2-3 sentences.

## Evidence / how I verified
Tests run, sources, or the specific behaviour observed.

## Links
- [[related-wiki-entry]]
- https://external.source
MD
fi

if [[ ! -f "$WIKI/index.md" ]]; then
  cat > "$WIKI/index.md" <<'MD'
# Topic Index

Hand-curated. Update as you notice recurring themes.

## Patterns
- (empty)

## Libraries / Tools
- (empty)

## Gotchas
- (empty)

## Open Questions
- (empty)
MD
fi

echo "✓ llm-wiki scaffold at $WIKI"
ls -la "$WIKI"
