#!/usr/bin/env bash
# PostToolUse(WebFetch|WebSearch) — "graphiti-lite":
# Extracts title + first paragraph from fetched URLs and appends one JSONL row per URL
# to ~/Desktop/ACTIVITIES/entities.jsonl. Deduplicated by URL.
# No LLM call, no external DB — pure regex + text slicing.

set -euo pipefail

ENTITIES_FILE="$HOME/Desktop/ACTIVITIES/entities.jsonl"
mkdir -p "$(dirname "$ENTITIES_FILE")"
touch "$ENTITIES_FILE"

PAYLOAD="$(cat 2>/dev/null || true)"
[[ -z "$PAYLOAD" ]] && exit 0

export _PAYLOAD="$PAYLOAD"
export _ENTITIES_FILE="$ENTITIES_FILE"
export _PROJ="$(basename "$PWD")"

python3 <<'PY' 2>/dev/null || exit 0
import os, json, re, datetime

path = os.environ['_ENTITIES_FILE']
proj = os.environ['_PROJ']

try:
    payload = json.loads(os.environ.get('_PAYLOAD', '{}'))
except Exception:
    import sys; sys.exit(0)

tool = payload.get('tool_name', '')
if tool not in ('WebFetch', 'WebSearch'):
    import sys; sys.exit(0)

# URL lives in tool_input; content lives in tool_response (often a long string)
tool_input  = payload.get('tool_input', {})
tool_resp   = payload.get('tool_response', {})

url = ''
if tool == 'WebFetch':
    url = tool_input.get('url', '')
elif tool == 'WebSearch':
    # WebSearch returns multiple; we'll log the aggregate as a single row
    url = tool_input.get('query', '')[:200]

if not url:
    import sys; sys.exit(0)

# Already seen?
existing_urls = set()
try:
    with open(path) as f:
        for line in f:
            try:
                d = json.loads(line)
                if d.get('url'):
                    existing_urls.add(d['url'])
            except Exception:
                pass
except FileNotFoundError:
    pass

if url in existing_urls:
    import sys; sys.exit(0)

# Extract content snippet from tool_response
content = ''
if isinstance(tool_resp, dict):
    for key in ('result', 'output', 'content', 'text'):
        if key in tool_resp and isinstance(tool_resp[key], str):
            content = tool_resp[key]
            break
elif isinstance(tool_resp, str):
    content = tool_resp

content = content[:8000]

# Title: first markdown h1 or html title
title = ''
m = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
if m:
    title = m.group(1).strip()[:200]
else:
    m = re.search(r'<title[^>]*>([^<]{4,200})</title>', content, re.IGNORECASE)
    if m:
        title = m.group(1).strip()

# First real paragraph (non-empty line after first h1, min 40 chars)
first_para = ''
for line in content.split('\n'):
    s = line.strip()
    if len(s) >= 40 and not s.startswith('#') and not s.startswith('|'):
        first_para = s[:400]
        break

entity = {
    'url': url,
    'title': title,
    'summary': first_para,
    'tool': tool,
    'project': proj,
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
}

with open(path, 'a') as f:
    f.write(json.dumps(entity, ensure_ascii=False) + '\n')
PY

exit 0
