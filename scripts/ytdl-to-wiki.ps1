#!/usr/bin/env pwsh
# Downloads a video/audio URL via yt-dlp → transcribes via whisper.cpp → writes a
# markdown entry to ~/Desktop/ACTIVITIES/llm-wiki/<safe-title>.md.
#
# Dependencies: yt-dlp, whisper.cpp (or openai-whisper), ffmpeg. Gracefully
# degrades if whisper missing (keeps audio + skips transcription).
#
# Usage: ./ytdl-to-wiki.ps1 <url>

[CmdletBinding()]
param([Parameter(Position = 0)][string]$Url)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

if (-not $Url) { [Console]::Error.WriteLine('usage: ./ytdl-to-wiki.ps1 <video-url>'); exit 2 }

$Wiki   = Join-Path $HOME 'Desktop/ACTIVITIES/llm-wiki'
$TmpDir = Join-Path ([IO.Path]::GetTempPath()) ("ytdl-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $Wiki   | Out-Null
New-Item -ItemType Directory -Force -Path $TmpDir | Out-Null

try {
    Write-Host "▸ downloading audio: $Url"
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine('yt-dlp not installed. Install: pip install yt-dlp  (or scoop install yt-dlp)')
        exit 3
    }

    # Audio only, mp3, sane filename
    $outTpl = Join-Path $TmpDir '%(title)s.%(ext)s'
    yt-dlp -q --no-progress -x --audio-format mp3 --audio-quality 5 -o $outTpl $Url

    $audio = Get-ChildItem -Path $TmpDir -Filter '*.mp3' -File | Select-Object -First 1
    if (-not $audio) { [Console]::Error.WriteLine('download failed'); exit 4 }

    $title = [IO.Path]::GetFileNameWithoutExtension($audio.Name)
    $safe  = ($title -replace '[^A-Za-z0-9._\-]', '-')
    if ($safe.Length -gt 80) { $safe = $safe.Substring(0, 80) }
    $outfile = Join-Path $Wiki ("{0}-ytdl-{1}.md" -f (Get-Date -Format 'yyyy-MM-dd'), $safe)

    # Metadata
    $uploader = ''; $duration = ''; $description = ''
    try {
        $json = & yt-dlp -q --skip-download --dump-single-json $Url 2>$null | Out-String
        if ($json) {
            $meta = $json | ConvertFrom-Json
            $uploader    = $meta.uploader
            $duration    = $meta.duration_string
            $description = if ($meta.description) { ($meta.description -split "`n" | Select-Object -First 20) -join "`n" } else { '' }
        }
    } catch {}

    # Transcribe if whisper available
    $transcript = ''
    if (Get-Command whisper-cpp -ErrorAction SilentlyContinue) {
        Write-Host '▸ transcribing with whisper-cpp...'
        $tbase = Join-Path $TmpDir 'transcript'
        & whisper-cpp --model base -otxt -of $tbase $audio.FullName 2>$null | Out-Null
        $tfile = "$tbase.txt"
        if (Test-Path $tfile) { $transcript = Get-Content -Raw $tfile }
    }
    elseif (Get-Command whisper -ErrorAction SilentlyContinue) {
        Write-Host '▸ transcribing with openai-whisper...'
        Push-Location $TmpDir
        try {
            & whisper $audio.FullName --model base --output_format txt 2>$null | Out-Null
            $tfile = [IO.Path]::ChangeExtension($audio.FullName, '.txt')
            if (Test-Path $tfile) { $transcript = Get-Content -Raw $tfile }
        } finally { Pop-Location }
    }
    else {
        Write-Host '⚠ whisper not installed — saving metadata only'
    }

    $body = @"
# $title

- **Source:** $Url
- **Uploader:** $uploader
- **Duration:** $duration
- **Captured:** $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))

## Description

$description

## Transcript

"@
    if ($transcript) { $body += $transcript } else { $body += '_(transcription skipped — install whisper-cpp or openai-whisper)_' }

    Set-Content -Path $outfile -Value $body -Encoding UTF8
    Write-Host "✓ wrote $outfile"
}
finally {
    Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}
