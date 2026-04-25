#!/usr/bin/env bash
# Stop hook — appends an iteration entry to <project>/IMPROVEMENT_STATE.json
# if a nearby IMPROVEMENT_STATE.json exists. Silent no-op if not in a project.

set -euo pipefail

# Find IMPROVEMENT_STATE.json by walking up from cwd
state=""
dir="$PWD"
for _ in 1 2 3 4 5; do
  if [[ -f "$dir/IMPROVEMENT_STATE.json" ]]; then
    state="$dir/IMPROVEMENT_STATE.json"
    break
  fi
  dir="$(dirname "$dir")"
  [[ "$dir" == "/" || "$dir" == "$HOME" ]] && break
done

[[ -z "$state" ]] && exit 0

# Read stdin payload (Stop hook gets session info)
payload="$(cat 2>/dev/null || echo '{}')"
session_id="$(echo "$payload" | jq -r '.session_id // "unknown"' 2>/dev/null || echo 'unknown')"
transcript_path="$(echo "$payload" | jq -r '.transcript_path // ""' 2>/dev/null || echo '')"

timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Git stats for this iteration (best-effort, silent on failure)
git_stats='{}'
if git -C "$(dirname "$state")" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$(dirname "$state")" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
  dirty="$(git -C "$(dirname "$state")" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  head="$(git -C "$(dirname "$state")" rev-parse --short HEAD 2>/dev/null || echo '')"
  git_stats=$(jq -n --arg b "$branch" --arg d "$dirty" --arg h "$head" \
    '{branch: $b, dirty_files: ($d|tonumber), head: $h}' 2>/dev/null || echo '{}')
fi

# Append iteration entry (increment counter, timestamp, session + git stats)
python3 - "$state" "$session_id" "$timestamp" "$git_stats" "$transcript_path" <<'PY' 2>/dev/null || exit 0
import json, sys, os
path, sid, ts, git_json, transcript = sys.argv[1:6]
try:
    d = json.load(open(path))
except Exception:
    sys.exit(0)

it = d.get('current_iteration', 0) + 1
entry = {
    'iteration': it,
    'timestamp': ts,
    'session_id': sid[:8] if sid else 'unknown',
    'transcript': os.path.basename(transcript) if transcript else None,
    'git': json.loads(git_json) if git_json else {},
}
d['current_iteration'] = it
d['last_updated'] = ts
d.setdefault('iterations', []).append(entry)
d.setdefault('metrics', {})
d['metrics']['iterations_count'] = it
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
PY

exit 0
