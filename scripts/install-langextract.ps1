#!/usr/bin/env pwsh
# Install Google langextract (structured extraction with source grounding).
# Exposed to Claude via /extract slash command.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

function Test-Cmd([string]$name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

if (Test-Cmd 'langextract') {
    Write-Host "✓ langextract already installed: $((Get-Command langextract).Source)"
    exit 0
}

$installed = $false
try {
    if (Test-Cmd 'uvx') {
        Write-Host '▸ Installing langextract via uvx...'
        uvx --python 3.11 pip install langextract 2>&1 | Select-Object -Last 5
        $installed = ($LASTEXITCODE -eq 0)
    }
    elseif (Test-Cmd 'pipx') {
        Write-Host '▸ Installing langextract via pipx...'
        pipx install langextract 2>&1 | Select-Object -Last 5
        $installed = ($LASTEXITCODE -eq 0)
    }
    elseif ((Test-Cmd 'pip') -or (Test-Cmd 'pip3') -or (Test-Cmd 'python3') -or (Test-Cmd 'python')) {
        $py = if (Test-Cmd 'python3') { 'python3' } else { 'python' }
        Write-Host "▸ Installing langextract via $py -m pip --user..."
        & $py -m pip install --user langextract 2>&1 | Select-Object -Last 5
        $installed = ($LASTEXITCODE -eq 0)
    }
    else {
        [Console]::Error.WriteLine('need pip, pipx, uvx, or python to install langextract')
        exit 3
    }
}
catch {
    Write-Host "⚠ install attempt threw: $_"
}

Write-Host ''
$py = if (Test-Cmd 'python3') { 'python3' } elseif (Test-Cmd 'python') { 'python' } else { $null }
if ($py) {
    $v = & $py -c 'import langextract; print(langextract.__version__)' 2>$null
    if ($LASTEXITCODE -eq 0 -and $v) {
        Write-Host "✓ langextract importable — version: $v"
    } else {
        Write-Host "⚠ Could not verify. Try: $py -c 'import langextract'"
    }
}
Write-Host ''
Write-Host 'Note: langextract needs an LLM API key (GEMINI_API_KEY, OPENAI_API_KEY) at call time.'
