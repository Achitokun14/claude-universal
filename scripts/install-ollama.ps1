#!/usr/bin/env pwsh
# install-ollama.ps1 — Install Ollama on Windows/macOS/Linux.
# On Linux, calls the official curl installer (requires sudo interactively).
# On Windows, downloads the MSI.
# On macOS, points at the .dmg.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Host "✓ ollama already installed: $((Get-Command ollama).Source)"
    exit 0
}

if ($IsWindows) {
    $msi = Join-Path ([IO.Path]::GetTempPath()) 'OllamaSetup.exe'
    Write-Host "▸ Downloading Ollama Windows installer"
    Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile $msi -UseBasicParsing
    Write-Host "▸ Run: $msi  (installer will prompt for UAC)"
    Start-Process -FilePath $msi
}
elseif ($IsMacOS) {
    Write-Host '▸ macOS: download from https://ollama.com/download/mac and install manually'
}
else {
    Write-Host '▸ Running official Linux installer (requires sudo — run this in an interactive shell):'
    Write-Host '    curl -fsSL https://ollama.com/install.sh | sh'
}

$cfgDir = Join-Path $HOME '.config/claw'
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null

@'
# Ollama Cloud (manual sign-in step)
#
# 1. ollama signin           # one-time browser OAuth
# 2. ollama pull glm-4.5-cloud
# 3. $env:OLLAMA_HOST = "https://ollama.com"
# 4. claw --model ollama/glm-4.5-cloud "hello"
#
# Web search tool (cloud models only):
#   claw --model ollama/gpt-oss-cloud --tool web-search "..."
'@ | Set-Content (Join-Path $cfgDir 'ollama-cloud.md') -Encoding UTF8

Write-Host ""
Write-Host "Notes saved to $cfgDir/ollama-cloud.md"
