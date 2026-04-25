#!/usr/bin/env bash
# Stop hook — distills the ending session into a markdown entry appended to
# ~/Desktop/ACTIVITIES/llm-wiki/YYYY-MM-DD.md. Deterministic (no LLM call):
#   - reads the transcript path from the hook payload
#   - extracts: completed TodoWrite items, git diff summary, agent spawns,
#     top 3 URLs fetched, IMPROVEMENT_STATE iteration number if nearby
# Karpathy-style llm-wiki pattern.
# Silent no-op on error.

set -euo pipefail

WIKI_DIR="$HOME/Desktop/ACTIVITIES/llm-wiki"
mkdir -p "$WIKI_DIR"

PAYLOAD="$(cat 2>/dev/null || true)"
[[ -z "$PAYLOAD" ]] && exit 0

export _PAYLOAD="$PAYLOAD"
export _WIKI_DIR="$WIKI_DIR"
export _PWD="$PWD"

python3 <<'PY' 2>/dev/null || exit 0
import os, json, re, subprocess, datetime
from pathlib import Path

wiki_dir = Path(os.environ['_WIKI_DIR'])
cwd      = Path(os.environ['_PWD'])

try:
    payload = json.loads(os.environ.get('_PAYLOAD', '{}'))
except Exception:
    payload = {}

transcript = payload.get('transcript_path', '')
session_id = (payload.get('session_id') or 'unknown')[:8]

# Harvest from transcript if available
todos_done = []
agents_spawned = []
urls = []
files_edited = set()

if transcript and os.path.exists(transcript):
    try:
        with open(transcript, errors='ignore') as f:
            for line in f:
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                content = json.dumps(rec)[:30000]
                # Completed todos
                for m in re.finditer(r'"status":\s*"completed"[^}]{0,300}"content":\s*"([^"]{4,200})"', content):
                    todos_done.append(m.group(1))
                # Agent calls
                for m in re.finditer(r'"subagent_type":\s*"([^"]{3,60})"[^}]{0,300}"description":\s*"([^"]{4,120})"', content):
                    agents_spawned.append(f'{m.group(1)}: {m.group(2)}')
                # URLs — strip JSONL-escape artifacts (trailing \ from escaped newlines in transcript)
                for m in re.findall(r'https?://[^\s\)"\'<>`\\]+', content[:10000]):
                    if 'localhost' not in m and len(m) < 150:
                        urls.append(m.rstrip('.,);:"\'\\'))
                # File edits (best-effort)
                for m in re.finditer(r'"file_path":\s*"(/[^"]+)"', content):
                    files_edited.add(m.group(1))
    except Exception:
        pass

# Dedup and cap
todos_done = list(dict.fromkeys(todos_done))[:10]
agents_spawned = list(dict.fromkeys(agents_spawned))[:5]
urls = list(dict.fromkeys(urls))[:5]

# Git info
git_summary = ''
try:
    inside = subprocess.run(['git', '-C', str(cwd), 'rev-parse', '--is-inside-work-tree'],
                             capture_output=True, text=True, timeout=2).returncode == 0
    if inside:
        branch = subprocess.run(['git', '-C', str(cwd), 'rev-parse', '--abbrev-ref', 'HEAD'],
                                capture_output=True, text=True, timeout=2).stdout.strip() or '?'
        stat = subprocess.run(['git', '-C', str(cwd), 'diff', '--stat', 'HEAD'],
                              capture_output=True, text=True, timeout=3).stdout.strip().splitlines()
        summary_line = stat[-1] if stat else ''
        git_summary = f'{branch} — {summary_line[:120]}'
except Exception:
    pass

# Iteration number
iteration = None
for up in [cwd, *cwd.parents][:5]:
    s = up / 'IMPROVEMENT_STATE.json'
    if s.exists():
        try:
            iteration = json.load(open(s)).get('current_iteration')
            break
        except Exception:
            pass

# Bail early if there's nothing meaningful to record
if not (todos_done or agents_spawned or urls or files_edited or git_summary):
    raise SystemExit(0)

# Build entry
today = datetime.date.today().isoformat()
ts = datetime.datetime.now().strftime('%H:%M')
entry_path = wiki_dir / f'{today}.md'

proj = cwd.name
lines = []
if not entry_path.exists():
    lines.append(f'# {today}\n')
lines.append(f'\n## {ts} · {proj} · session {session_id}\n')
if iteration is not None:
    lines.append(f'_iteration #{iteration}_\n')
if git_summary:
    lines.append(f'- **git:** {git_summary}\n')
if files_edited:
    sample = sorted(files_edited)[:5]
    lines.append('- **files touched:** ' + ', '.join(f'`{Path(f).name}`' for f in sample) +
                 (f' (+{len(files_edited)-5} more)' if len(files_edited) > 5 else '') + '\n')
if todos_done:
    lines.append('- **todos completed:**\n')
    for t in todos_done:
        lines.append(f'  - {t}\n')
if agents_spawned:
    lines.append('- **agents spawned:**\n')
    for a in agents_spawned:
        lines.append(f'  - {a}\n')
if urls:
    lines.append('- **urls:**\n')
    for u in urls:
        lines.append(f'  - {u}\n')

with open(entry_path, 'a') as f:
    f.writelines(lines)
PY

exit 0
