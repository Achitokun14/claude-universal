#!/usr/bin/env bash
# PostToolUse hook — extracts URLs/packages/repos from tool calls and appends
# deduplicated entries to ~/Desktop/ACTIVITIES/useful-resources.md.
# Silent no-op on any error.

set -euo pipefail

RESOURCES_FILE="$HOME/Desktop/ACTIVITIES/useful-resources.md"
mkdir -p "$(dirname "$RESOURCES_FILE")"

if [[ ! -f "$RESOURCES_FILE" ]]; then
  cat > "$RESOURCES_FILE" <<'HEADER'
# Useful Resources — Auto-collected

Auto-maintained by `track-resources.sh`. Every URL, package name, or GitHub repo mentioned in tool calls is deduplicated here.

| Date | Source | Category | Resource | Context |
|---|---|---|---|---|
HEADER
fi

# Read the hook payload from stdin into a variable, then pass via env so the
# heredoc'd Python can still read its script body.
PAYLOAD="$(cat 2>/dev/null || true)"
[[ -z "$PAYLOAD" ]] && exit 0

export _PAYLOAD="$PAYLOAD"
export _RESOURCES_FILE="$RESOURCES_FILE"
export _DATE="$(date -u +%Y-%m-%d)"
export _PROJ="$(basename "$PWD")"

python3 <<'PY' 2>/dev/null || exit 0
import sys, re, os, json

path = os.environ['_RESOURCES_FILE']
ts   = os.environ['_DATE']
proj = os.environ['_PROJ']
payload_raw = os.environ.get('_PAYLOAD', '')

try:
    payload = json.loads(payload_raw) if payload_raw.strip() else {}
except Exception:
    sys.exit(0)

tool_name = payload.get('tool_name', '')
haystack  = json.dumps(payload.get('tool_input', {})) + json.dumps(payload.get('tool_response', {}))
haystack  = haystack[:50000]
if not haystack:
    sys.exit(0)

url_re   = re.compile(r'https?://[^\s\)"\'<>`]+')
npm_re   = re.compile(r'(?:npm|npx|pnpm|bun|yarn)\s+(?:(?:-[a-zA-Z]+|--[\w-]+|install|add|run|exec)\s+)*(@?[A-Za-z][\w\-./]+)')
pip_re   = re.compile(r'(?:pip|pipx|uv|uvx)\s+(?:(?:-[a-zA-Z]+|install|run|tool)\s+)*([A-Za-z][\w\-.]+)')
cargo_re = re.compile(r'cargo\s+install\s+(?:--?\w+\s+)*([A-Za-z][\w\-]+)')
brew_re  = re.compile(r'brew\s+install\s+(?:--?\w+\s+)*([A-Za-z][\w\-./]+)')
apt_re   = re.compile(r'apt(?:-get)?\s+install\s+(?:(?:-y|--[\w-]+)\s+)*([A-Za-z][\w\-]+)')
go_re    = re.compile(r'go\s+install\s+([A-Za-z][\w\-./@]+)')
gh_re    = re.compile(r'github\.com/([A-Za-z][\w\-]+/[A-Za-z][\w\-.]+)')

NOISE_URL = ['localhost', '127.0.0.1', '0.0.0.0', 'example.com', 'test.com', 'file:///', '/tmp/']
NOISE_PKG = {'-g', '-y', '-D', '--', 'install', 'add', 'run', '-', '&', '|', '\\'}

existing = set()
try:
    with open(path) as f:
        for line in f:
            cols = [c.strip() for c in line.split('|')]
            if len(cols) >= 5:
                existing.add(cols[4])
except FileNotFoundError:
    pass

rows = []
def add(cat, resource):
    r = resource.strip().rstrip('.,);:"\'')
    if not r or r in existing or len(r) < 4 or len(r) > 200 or r in NOISE_PKG:
        return
    existing.add(r)
    r_esc = r.replace('|', '\\|')
    rows.append(f"| {ts} | {proj} | {cat} | {r_esc} | {tool_name[:40]} |")

for m in url_re.findall(haystack):
    if not any(bad in m for bad in NOISE_URL):
        add('url', m)
for m in npm_re.findall(haystack):    add('npm', m)
for m in pip_re.findall(haystack):    add('pypi', m)
for m in cargo_re.findall(haystack):  add('cargo', m)
for m in brew_re.findall(haystack):   add('brew', m)
for m in apt_re.findall(haystack):    add('apt', m)
for m in go_re.findall(haystack):     add('go', m)
for m in gh_re.findall(haystack):     add('github-repo', m)

if rows:
    with open(path, 'a') as f:
        for r in rows:
            f.write(r + '\n')
PY

exit 0
