#!/usr/bin/env pwsh
# Interactive orchestrator: clone "inspired" OSS Claude skill libraries and
# surface their skills at ~/.claude/skills/.
# Each source is opt-in (y/N). Idempotent: skips if already cloned.
#
# Usage:
#   ./install-inspired.ps1            # interactive
#   ./install-inspired.ps1 -All       # install everything without prompts
#   ./install-inspired.ps1 -DryRun    # preview only

[CmdletBinding()]
param(
    [switch]$All,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$SkillsDir   = Join-Path $HOME '.claude/skills'
$InspiredDir = Join-Path $SkillsDir '_inspired'
$CommandsDir = Join-Path $HOME '.claude/commands'
New-Item -ItemType Directory -Force -Path $InspiredDir | Out-Null
New-Item -ItemType Directory -Force -Path $CommandsDir | Out-Null

$Sources = @(
    @{ slug = 'garrytan/gstack';                    kind = 'commands';          desc = '40+ role-based slash commands (CEO/design/eng/DX reviews, QA, ship, canary, careful, freeze)' }
    @{ slug = 'Yeachan-Heo/oh-my-claudecode';       kind = 'skills';            desc = '19 agents + team/autopilot/ralph/ultrawork pipeline commands' }
    @{ slug = 'affaan-m/everything-claude-code';    kind = 'skills-selective';  desc = '183 skills/48 agents — surface 10 high-leverage ones' }
    @{ slug = 'bmad-code-org/BMAD-METHOD';          kind = 'skills';            desc = '12+ domain-expert agents, scale-adaptive phases, Party Mode' }
    @{ slug = 'ChristopherKahler/carl';             kind = 'installer';         desc = 'Context Augmentation & Reinforcement Layer — keyword-triggered rule injection. Low overhead.' }
    @{ slug = 'ChristopherKahler/paul';             kind = 'skills';            desc = 'Plan-Apply-Unify Loop — 26 slash commands, per-project .paul/ dir' }
    @{ slug = 'ChristopherKahler/base';             kind = 'installer-heavy';   desc = 'BASE framework — JSON data surfaces + drift scoring + hooks that inject on every prompt. HIGH context cost.' }
    @{ slug = 'mistarzewski/agency-agents';         kind = 'skills';            desc = 'Agency-focused Claude agents' }
    @{ slug = 'santifier/career-ops';               kind = 'skills';            desc = 'AI job search — 14 modes, Go dashboard (personal use only)' }
    @{ slug = 'coreyhaines31/marketingskills';      kind = 'skills';            desc = 'Marketing-focused Claude skills (user-requested)' }
)

function Confirm-Install([string]$Prompt) {
    if ($All) { return $true }
    $ans = Read-Host "$Prompt [y/N]"
    return ($ans -match '^[Yy]$')
}

function Do-Cmd([scriptblock]$Block, [string]$Label) {
    if ($DryRun) { Write-Host "   (dry-run) $Label"; return }
    & $Block
}

function Clone-Repo([string]$Slug) {
    $destName = Split-Path -Leaf $Slug
    $dest = Join-Path $InspiredDir $destName
    if (Test-Path (Join-Path $dest '.git')) {
        Write-Host "   already cloned: $dest"
        Do-Cmd { git -C $dest pull --ff-only --quiet 2>&1 | Select-Object -Last 1 } "git -C $dest pull"
    }
    else {
        Do-Cmd { git clone --depth 1 "https://github.com/$Slug" $dest 2>&1 | Select-Object -Last 1 } "git clone https://github.com/$Slug $dest"
    }
    return $dest
}

function New-LinkOrCopy([string]$LinkPath, [string]$Target) {
    try {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $Target -ErrorAction Stop | Out-Null
    }
    catch {
        # Windows without dev-mode: copy instead
        Copy-Item -Recurse -Force $Target $LinkPath
    }
}

function Surface-Skills([string]$RepoDir) {
    $count = 0
    $patterns = @(
        (Join-Path $RepoDir 'skills')
        (Join-Path $RepoDir '.claude/skills')
    )
    foreach ($root in $patterns) {
        if (-not (Test-Path $root)) { continue }
        Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $skillDir  = $_.FullName
            $skillFile = Join-Path $skillDir 'SKILL.md'
            if (-not (Test-Path $skillFile)) { return }
            $name   = $_.Name
            $target = Join-Path $SkillsDir $name
            if (Test-Path -LiteralPath $target) {
                Write-Host "   exists: $name (skipping)"; return
            }
            Do-Cmd { New-LinkOrCopy $target $skillDir } "link $target -> $skillDir"
            Write-Host "   ✓ $name"
            $count++
        }
    }
    Write-Host "   (surfaced $count skill(s))"
}

function Surface-Commands([string]$RepoDir) {
    $count = 0
    $patterns = @(
        (Join-Path $RepoDir 'commands')
        (Join-Path $RepoDir '.claude/commands')
    )
    foreach ($root in $patterns) {
        if (-not (Test-Path $root)) { continue }
        Get-ChildItem -Path $root -Filter '*.md' -File -ErrorAction SilentlyContinue | ForEach-Object {
            $target = Join-Path $CommandsDir $_.Name
            if (Test-Path -LiteralPath $target) { return }
            Do-Cmd { New-LinkOrCopy $target $_.FullName } "link $target -> $($_.FullName)"
            $count++
        }
    }
    Write-Host "   (surfaced $count command(s))"
}

function Install-InstallerBased([string]$RepoDir) {
    foreach ($name in 'install.sh','setup.sh','install.ps1','setup.ps1') {
        $installer = Join-Path $RepoDir $name
        if (Test-Path $installer) {
            Write-Host "   running $installer (trust-on-inspection)…"
            Do-Cmd {
                if ($installer -like '*.ps1') { & pwsh -File $installer }
                else                          { & bash $installer }
            } "exec $installer"
            return
        }
    }
    Write-Host "   ⚠ no installer found — falling back to generic surface"
    Surface-Skills $RepoDir
    Surface-Commands $RepoDir
}

Write-Host '══════════════════════════════════════════════════════════'
Write-Host ' Inspired skills installer'
Write-Host " Clones OSS repos into $InspiredDir"
Write-Host ' and surfaces their skills/commands into ~/.claude/'
if ($All)    { Write-Host ' Mode: -All  (no prompts)' }
if ($DryRun) { Write-Host ' Mode: -DryRun' }
Write-Host '══════════════════════════════════════════════════════════'

foreach ($src in $Sources) {
    Write-Host ''
    Write-Host '────────────────────────────────────────'
    Write-Host "▶ $($src.slug)"
    Write-Host "  kind: $($src.kind)"
    Write-Host "  $($src.desc)"
    if (-not (Confirm-Install '  install?')) { Write-Host '  (skipped)'; continue }
    $repoDir = Clone-Repo $src.slug
    switch ($src.kind) {
        'skills'            { Surface-Skills   $repoDir }
        'skills-selective'  { Surface-Skills   $repoDir }
        'commands'          { Surface-Commands $repoDir; Surface-Skills $repoDir }
        'installer'         { Install-InstallerBased $repoDir }
        'installer-heavy'   { Install-InstallerBased $repoDir }
        default             { Surface-Skills   $repoDir }
    }
}

Write-Host ''
Write-Host '══════════════════════════════════════════════════════════'
Write-Host 'Done. Start a new Claude Code session to load new skills.'
Write-Host 'Discovered:'
Get-ChildItem -Force $SkillsDir -ErrorAction SilentlyContinue |
    Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint } |
    Select-Object -First 20 |
    ForEach-Object { Write-Host "  $($_.Name) → $($_.Target)" }
