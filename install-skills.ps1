#!/usr/bin/env pwsh
# install-skills.ps1 — mirror the 4 global design skills on a fresh machine.
# Run after install.ps1 user. Idempotent (skip if already present).

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$SkillsDir = Join-Path $HOME '.claude/skills'
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

function Clone-Once([string]$Repo, [string]$Dest) {
    $destPath = Join-Path $SkillsDir $Dest
    if (Test-Path $destPath) {
        Write-Host "▸ $Dest already cloned — pulling latest"
        git -C $destPath pull --ff-only 2>&1 | Select-Object -Last 1
    }
    else {
        Write-Host "▸ cloning $Repo → $Dest"
        git clone --depth 1 "https://github.com/$Repo" $destPath 2>&1 | Select-Object -Last 1
    }
}

function Symlink-Once([string]$LinkName, [string]$RelativeTarget) {
    $linkPath = Join-Path $SkillsDir $LinkName
    if (Test-Path -LiteralPath $linkPath) { return }
    $targetPath = Join-Path $SkillsDir $RelativeTarget
    try {
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -ErrorAction Stop | Out-Null
        Write-Host "   ✓ symlinked $LinkName"
    }
    catch {
        # Fallback on Windows without developer-mode: copy instead of symlink
        if (Test-Path $targetPath) {
            Copy-Item -Recurse -Force $targetPath $linkPath
            Write-Host "   ✓ copied (symlink failed): $LinkName"
        }
        else {
            Write-Host "   ⚠ target not found: $RelativeTarget"
        }
    }
}

# 1. Emil Kowalski
Clone-Once 'emilkowalski/skill' 'emilkowalski-skill'
Symlink-Once 'emil-design-eng' 'emilkowalski-skill/skills/emil-design-eng'

# 2. Taste + siblings
Clone-Once 'Leonxlnx/taste-skill' 'taste-skill-repo'
foreach ($variant in @('taste-skill','minimalist-skill','soft-skill','brutalist-skill','redesign-skill')) {
    $p = Join-Path $SkillsDir "taste-skill-repo/skills/$variant"
    if (Test-Path $p) { Symlink-Once $variant "taste-skill-repo/skills/$variant" }
}

# 3. UI/UX Pro Max
Clone-Once 'nextlevelbuilder/ui-ux-pro-max-skill' 'ui-ux-pro-max-skill'
Symlink-Once 'ui-ux-pro-max' 'ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max'

# 4. Impeccable — plugin (not a skill dir). Ensure it's in enabledPlugins.
$Settings = Join-Path $HOME '.claude/settings.json'
if (Test-Path $Settings) {
    try {
        $d = Get-Content -Raw $Settings | ConvertFrom-Json -AsHashtable -Depth 20
        if (-not $d.ContainsKey('enabledPlugins')) { $d['enabledPlugins'] = @{} }
        $already = $false
        if ($d['enabledPlugins'].ContainsKey('impeccable@impeccable')) { $already = [bool]$d['enabledPlugins']['impeccable@impeccable'] }
        if (-not $already) {
            Write-Host '▸ enabling impeccable@impeccable in settings.json'
            $d['enabledPlugins']['impeccable@impeccable'] = $true
            if (-not $d.ContainsKey('extraKnownMarketplaces')) { $d['extraKnownMarketplaces'] = @{} }
            $d['extraKnownMarketplaces']['impeccable'] = @{
                source = @{ source = 'github'; repo = 'pbakaus/impeccable' }
            }
            ($d | ConvertTo-Json -Depth 20) | Set-Content -Path $Settings -Encoding UTF8
            Write-Host '   ✓ settings.json updated'
        }
        else {
            Write-Host '▸ impeccable plugin already enabled'
        }
    }
    catch {
        Write-Host "⚠ settings.json edit failed: $_"
    }
}

Write-Host ''
Write-Host '✅ Design skills ready. Start a new Claude Code session to load them.'
Write-Host "   Verify: Get-ChildItem '$SkillsDir' | Where-Object Name -Match 'emil|taste|ui-ux|minimalist|soft|brutal|redesign'"
