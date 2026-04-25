#!/usr/bin/env pwsh
# install-claw-code.ps1 — PowerShell twin of install-claw-code.sh.
# Clones ultraworkers/claw-code, builds with cargo, wires env-var config.

[CmdletBinding()]
param(
    [switch]$Rebuild,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$CloneDir = Join-Path $HOME '.claude/skills/_inspired/claw-code'
$BinDir   = Join-Path $HOME '.local/bin'
$CfgDir   = Join-Path $HOME '.config/claw'

function Fail([int]$Code, [string]$Msg) { [Console]::Error.WriteLine($Msg); exit $Code }

if ($Uninstall) {
    $binName = if ($IsWindows) { 'claw.exe' } else { 'claw' }
    Remove-Item -Force (Join-Path $BinDir $binName) -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $CfgDir -ErrorAction SilentlyContinue
    Write-Host "removed $BinDir/$binName and $CfgDir"
    exit 0
}

foreach ($dep in 'git','curl','rustc','cargo') {
    if (-not (Get-Command $dep -ErrorAction SilentlyContinue)) { Fail 2 "missing: $dep" }
}

# Check rustc version (claw needs >= 1.88)
$rustMajor = (rustc --version 2>$null) -replace 'rustc (\d+\.\d+).*','$1'
$rustMinor = [double]$rustMajor
if ($rustMinor -lt 1.88) {
    Write-Host "⚠ rustc $rustMajor < 1.88 required — upgrading via rustup"
    if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
        Fail 3 "rustup not installed — get it from https://rustup.rs then retry"
    }
    rustup update stable
}

if (-not (Test-Path (Join-Path $CloneDir '.git'))) {
    Write-Host "▸ cloning ultraworkers/claw-code"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $CloneDir) | Out-Null
    git clone --depth 1 https://github.com/ultraworkers/claw-code $CloneDir
} else {
    Write-Host "▸ pulling latest"
    git -C $CloneDir pull --ff-only --quiet
}

$builtBin = Join-Path $CloneDir 'rust/target/release/claw'
if ($IsWindows) { $builtBin += '.exe' }

if ($Rebuild -or -not (Test-Path $builtBin)) {
    Write-Host "▸ building claw (release) — several minutes"
    Push-Location (Join-Path $CloneDir 'rust')
    try { cargo build --release --workspace } finally { Pop-Location }
}

if (-not (Test-Path $builtBin)) { Fail 4 "build artifact not found at $builtBin" }

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$linkPath = Join-Path $BinDir ($(if ($IsWindows) { 'claw.exe' } else { 'claw' }))
try {
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $builtBin -Force | Out-Null
} catch {
    Copy-Item -Force $builtBin $linkPath
}
Write-Host "✓ symlinked: $linkPath → $builtBin"

New-Item -ItemType Directory -Force -Path $CfgDir | Out-Null

# PowerShell env-profile (sourced via pwsh profile or shell-init)
@'
# claw-code environment for PowerShell
# Add to your $PROFILE:
#   . ~/.config/claw/env.ps1
#
# Fill in your profile (never commit real values):
#   $env:CLAW_API_KEY       = "sk-cp-..."
#   $env:CLAW_API_BASE_URL  = "https://api.<provider>.com/v1"
#   $env:OLLAMA_HOST        = "https://ollama.com"    # optional

if ($env:CLAW_API_KEY)      { $env:OPENAI_API_KEY  = $env:CLAW_API_KEY }
if ($env:CLAW_API_BASE_URL) { $env:OPENAI_BASE_URL = $env:CLAW_API_BASE_URL }
if ($env:OLLAMA_HOST)       { $env:OLLAMA_API_BASE = $env:OLLAMA_HOST }
'@ | Set-Content (Join-Path $CfgDir 'env.ps1') -Encoding UTF8

Write-Host "✓ wrote $CfgDir/env.ps1"
Write-Host ""
Write-Host "NEXT (manual):"
Write-Host "  Add to `$PROFILE:"
Write-Host "    `$env:CLAW_API_KEY = 'sk-cp-...'"
Write-Host "    `$env:CLAW_API_BASE_URL = 'https://api.<provider>/v1'"
Write-Host "    . ~/.config/claw/env.ps1"
Write-Host "  Then: claw doctor"
