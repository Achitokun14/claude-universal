#!/usr/bin/env pwsh
# Create ~/Desktop/ACTIVITIES/llm-wiki/ with Karpathy-style templates.
# Idempotent: skips files that already exist.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$Wiki = Join-Path $HOME 'Desktop/ACTIVITIES/llm-wiki'
New-Item -ItemType Directory -Force -Path $Wiki | Out-Null

$README = @'
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
'@

$TEMPLATE = @'
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
'@

$INDEX = @'
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
'@

function Write-IfAbsent([string]$Path, [string]$Content) {
    if (-not (Test-Path $Path)) {
        Set-Content -Path $Path -Value $Content -Encoding UTF8 -NoNewline
    }
}

Write-IfAbsent (Join-Path $Wiki 'README.md')   $README
Write-IfAbsent (Join-Path $Wiki 'TEMPLATE.md') $TEMPLATE
Write-IfAbsent (Join-Path $Wiki 'index.md')    $INDEX

Write-Host "✓ llm-wiki scaffold at $Wiki"
Get-ChildItem -Force $Wiki | Format-Table -AutoSize
