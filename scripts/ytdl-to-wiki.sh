#!/usr/bin/env bash
# Downloads a video/audio URL via yt-dlp → transcribes via whisper.cpp → writes a
# markdown entry to ~/Desktop/ACTIVITIES/llm-wiki/<safe-title>.md.
#
# Dependencies: yt-dlp, whisper.cpp (or openai-whisper), ffmpeg. Gracefully
# degrades if whisper missing (keeps the audio + skips transcription).
#
# Usage: ytdl-to-wiki.sh <url>
set -euo pipefail

URL="${1:-}"
[[ -z "$URL" ]] && { echo "usage: $0 <video-url>"; exit 2; }

WIKI="$HOME/Desktop/ACTIVITIES/llm-wiki"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$WIKI"

echo "▸ downloading audio: $URL"
if ! command -v yt-dlp >/dev/null 2>&1; then
  echo "yt-dlp not installed. Install: sudo apt install yt-dlp  (or pip install yt-dlp)"
  exit 3
fi

# Audio only, mp3, sane filename
yt-dlp -q --no-progress -x --audio-format mp3 --audio-quality 5 \
  -o "$TMPDIR/%(title)s.%(ext)s" "$URL"

audio_file="$(ls "$TMPDIR"/*.mp3 2>/dev/null | head -1)"
[[ -z "$audio_file" ]] && { echo "download failed"; exit 4; }

title="$(basename "${audio_file%.mp3}")"
safe="$(echo "$title" | tr -c '[:alnum:]._-' '-' | head -c 80)"
outfile="$WIKI/$(date +%Y-%m-%d)-ytdl-${safe}.md"

# Metadata from yt-dlp
info_json="$TMPDIR/info.json"
yt-dlp -q --skip-download --dump-single-json "$URL" > "$info_json" 2>/dev/null || echo '{}' > "$info_json"

uploader="$(jq -r '.uploader // ""' "$info_json" 2>/dev/null)"
duration="$(jq -r '.duration_string // ""' "$info_json" 2>/dev/null)"
description="$(jq -r '.description // ""' "$info_json" 2>/dev/null | head -20)"

# Transcribe if whisper available
transcript=""
if command -v whisper-cpp >/dev/null 2>&1; then
  echo "▸ transcribing with whisper-cpp..."
  whisper-cpp --model base -otxt -of "$TMPDIR/transcript" "$audio_file" >/dev/null 2>&1 || true
  [[ -f "$TMPDIR/transcript.txt" ]] && transcript="$(cat "$TMPDIR/transcript.txt")"
elif command -v whisper >/dev/null 2>&1; then
  echo "▸ transcribing with openai-whisper..."
  (cd "$TMPDIR" && whisper "$audio_file" --model base --output_format txt >/dev/null 2>&1 || true)
  txt="${audio_file%.mp3}.txt"
  [[ -f "$txt" ]] && transcript="$(cat "$txt")"
else
  echo "⚠ whisper not installed — saving metadata only"
fi

cat > "$outfile" <<MD
# $title

- **Source:** $URL
- **Uploader:** $uploader
- **Duration:** $duration
- **Captured:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Description

$description

## Transcript

MD

if [[ -n "$transcript" ]]; then
  echo "$transcript" >> "$outfile"
else
  echo '_(transcription skipped — install whisper-cpp or openai-whisper)_' >> "$outfile"
fi

echo "✓ wrote $outfile"
