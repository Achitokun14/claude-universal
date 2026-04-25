#!/usr/bin/env pwsh
# Safe Bitwarden/Vaultwarden secret retrieval for scripts/commands.
# - Never echoes the secret value (writes to stdout only when invoked directly).
# - Bails cleanly if `bw` CLI isn't installed or vault is locked.
#
# Usage:
#   ./vw-helper.ps1 <item-name> [field]
#     field default = password (other: username, totp, notes, uri)
#
# Prereq:
#   scoop install bitwarden-cli   OR   brew install bitwarden-cli
#   $env:BW_SESSION = (bw unlock --raw)

[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Item,
    [Parameter(Position = 1)][ValidateSet('password','username','totp','notes','uri')][string]$Field = 'password'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

# Use [Console]::Error.WriteLine + exit so messages go to stderr WITHOUT
# triggering the Stop preference (which would throw before exit runs).
function Fail([int]$Code, [string]$Msg) {
    [Console]::Error.WriteLine($Msg)
    exit $Code
}

if (-not $Item) {
    Fail 2 "usage: $($MyInvocation.MyCommand.Name) <item-name> [password|username|totp|notes|uri]"
}

if (-not (Get-Command bw -ErrorAction SilentlyContinue)) {
    Fail 3 'bw CLI not installed. Install: scoop install bitwarden-cli  OR  brew install bitwarden-cli'
}

if (-not $env:BW_SESSION) {
    Fail 4 'BW_SESSION not set. Unlock once: $env:BW_SESSION = (bw unlock --raw)'
}

& bw get $Field $Item --session $env:BW_SESSION 2>$null
exit $LASTEXITCODE
