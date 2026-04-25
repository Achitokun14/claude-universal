#!/usr/bin/env bash
# One-shot: mines ~/.claude/projects/*/*.jsonl for URLs, packages, GitHub repos,
# and seeds ~/Desktop/ACTIVITIES/useful-resources.md with deduplicated findings.

set -euo pipefail

RESOURCES_FILE="$HOME/Desktop/ACTIVITIES/useful-resources.md"
SESSIONS_DIR="$HOME/.claude/projects"
mkdir -p "$(dirname "$RESOURCES_FILE")"

[[ ! -d "$SESSIONS_DIR" ]] && { echo "no sessions at $SESSIONS_DIR"; exit 0; }

echo "▸ Mining session logs from $SESSIONS_DIR ..."
session_count=$(find "$SESSIONS_DIR" -name "*.jsonl" 2>/dev/null | wc -l)
echo "  Found $session_count session files"

# Header
cat > "$RESOURCES_FILE" <<HEADER
# Useful Resources — Auto-collected

Auto-maintained by \`track-resources.sh\` hook. Bootstrapped from all historical Claude Code sessions on this machine on $(date +%Y-%m-%d).

Each row is a URL, package name, or GitHub repo mentioned in some past tool call, deduplicated. The hook appends new entries as you work.

| Date | Source | Category | Resource | Context |
|---|---|---|---|---|
HEADER

# Mine all JSONL files for patterns
python3 - "$SESSIONS_DIR" "$RESOURCES_FILE" <<'PY'
import sys, os, re, json
from collections import OrderedDict

sessions_dir, out_path = sys.argv[1:3]

url_re = re.compile(r'https?://[^\s\)"\'<>\\`]+')
npm_re = re.compile(r'(?:npx?|pnpm|bun|yarn)\s+(?:-y\s+|install\s+|add\s+|run\s+|exec\s+)?(@?[\w\-./]+)')
pip_re = re.compile(r'(?:pip|pipx|uv|uvx)\s+(?:install\s+|run\s+|tool\s+)?([\w\-.]+)')
cargo_re = re.compile(r'cargo\s+install\s+([\w\-]+)')
brew_re = re.compile(r'brew\s+install\s+([\w\-./]+)')
apt_re = re.compile(r'apt(?:-get)?\s+install\s+(?:-y\s+)?([\w\-]+)')
go_re = re.compile(r'go\s+install\s+([\w\-./@]+)')
gh_repo_re = re.compile(r'github\.com/([\w\-]+/[\w\-.]+)')

NOISE_URL_SUBS = ['localhost', '127.0.0.1', '0.0.0.0', 'example.com', 'test.com', '/tmp/', 'file:///']
NOISE_PKGS = {'-g', '-y', '-D', '--', 'install', 'add', 'run', '-', '&', '|', '\\'}

resources = OrderedDict()  # preserves first-seen order

def add(cat, resource, context):
    k = (cat, resource)
    if k in resources: return
    if not resource or len(resource) < 4 or len(resource) > 200: return
    if resource.strip() in NOISE_PKGS: return
    resources[k] = context[:60]

files = []
for root, _, fnames in os.walk(sessions_dir):
    for f in fnames:
        if f.endswith('.jsonl'):
            files.append(os.path.join(root, f))

print(f"  Scanning {len(files)} jsonl files...", file=sys.stderr)
for fp in files:
    proj = os.path.basename(os.path.dirname(fp)).replace('-home-taran-', '').replace('-', '/')
    try:
        with open(fp, errors='ignore') as f:
            for line in f:
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                # Combine all string content in the record
                haystack = json.dumps(rec)[:50000]

                for m in url_re.findall(haystack):
                    m = m.rstrip('.,);:\\"\'')
                    if any(bad in m for bad in NOISE_URL_SUBS): continue
                    add('url', m, proj)
                for m in npm_re.findall(haystack):
                    add('npm', m, proj)
                for m in pip_re.findall(haystack):
                    add('pypi', m, proj)
                for m in cargo_re.findall(haystack):
                    add('cargo', m, proj)
                for m in brew_re.findall(haystack):
                    add('brew', m, proj)
                for m in apt_re.findall(haystack):
                    add('apt', m, proj)
                for m in go_re.findall(haystack):
                    add('go', m, proj)
                for m in gh_repo_re.findall(haystack):
                    add('github-repo', m, proj)
    except Exception:
        continue

print(f"  Found {len(resources)} unique resources", file=sys.stderr)

# Write rows, oldest first
import datetime
today = datetime.date.today().isoformat()
with open(out_path, 'a') as out:
    for (cat, resource), proj in resources.items():
        res_esc = resource.replace('|', '\\|')
        proj_esc = (proj or '').replace('|', '\\|')[:30]
        out.write(f"| {today} | {proj_esc} | {cat} | {res_esc} | historical |\n")
PY

count=$(wc -l < "$RESOURCES_FILE")
echo "✓ Wrote $RESOURCES_FILE ($count lines)"
echo "  Rows: $(grep -c '^|' "$RESOURCES_FILE") (includes header)"
