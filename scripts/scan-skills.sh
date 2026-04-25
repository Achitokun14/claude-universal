#!/usr/bin/env bash
# scan-skills.sh — Build a JSON inventory of every Claude Code skill discoverable on this machine.
#
# Walks:
#   - ~/.claude/skills/<name>/SKILL.md              (user-scope top-level)
#   - ~/.claude/skills/_inspired/<repo>/skills/<name>/SKILL.md          (inspired repos - layout 1)
#   - ~/.claude/skills/_inspired/<repo>/.claude/skills/<name>/SKILL.md  (inspired repos - layout 2)
#   - ~/.claude/plugins/**/skills/<name>/SKILL.md   (plugin-provided)
#
# Output: JSON array at $1 (default: ~/Desktop/ACTIVITIES/skills-inventory.json)
# Each entry:
#   { name, path, source_repo, source_kind, description, is_symlink, symlink_target, line_count }

set -euo pipefail

OUT="${1:-$HOME/Desktop/ACTIVITIES/skills-inventory.json}"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

mkdir -p "$(dirname "$OUT")"

python3 - "$TMP" <<'PY'
import sys, os, re, json, glob
from pathlib import Path

HOME   = Path.home()
SKILLS = HOME / '.claude' / 'skills'
PLUGINS = HOME / '.claude' / 'plugins'

entries = []

def read_frontmatter(path):
    """Extract YAML frontmatter fields from a SKILL.md."""
    try:
        text = path.read_text(errors='ignore')
    except Exception:
        return {}
    if not text.startswith('---'):
        return {}
    # naive frontmatter split (good enough for Claude skills)
    try:
        _, fm, _body = text.split('---', 2)
    except ValueError:
        return {}
    fields = {}
    # very small YAML parser — handles 'key: value' one-line form
    for line in fm.splitlines():
        line = line.rstrip()
        if not line or line.startswith('#'):
            continue
        m = re.match(r'^([A-Za-z0-9_\-]+):\s*(.*)$', line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            # strip surrounding quotes if present
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            fields[key] = val
    return fields

def add(skill_md, source_kind, source_repo):
    """Record one skill entry."""
    if not skill_md.is_file():
        return
    skill_dir = skill_md.parent
    name = skill_dir.name
    fm = read_frontmatter(skill_md)
    try:
        line_count = sum(1 for _ in skill_md.open())
    except Exception:
        line_count = 0
    is_link = skill_dir.is_symlink()
    target = None
    if is_link:
        try:
            target = str(skill_dir.readlink())
        except Exception:
            pass
    entries.append({
        'name': fm.get('name', name),
        'path': str(skill_md),
        'source_kind': source_kind,       # user | inspired | plugin
        'source_repo': source_repo,       # gstack | everything-claude-code | posthog | ...
        'description': fm.get('description', ''),
        'is_symlink': is_link,
        'symlink_target': target,
        'line_count': line_count,
    })

# 1. User-scope top-level skills
if SKILLS.is_dir():
    for entry in SKILLS.iterdir():
        if entry.name in ('_inspired', '_disabled'):
            continue
        sm = entry / 'SKILL.md'
        if sm.is_file():
            # if it's a symlink, trace back to figure the real source_repo
            repo = 'user'
            if entry.is_symlink():
                try:
                    t = str(entry.readlink())
                    # target might be 'taste-skill-repo/skills/minimalist-skill' or similar
                    if '_inspired/' in t:
                        repo = t.split('_inspired/')[1].split('/')[0]
                    elif '/taste-skill-repo/' in t or 'taste-skill-repo' in t:
                        repo = 'taste-skill-repo'
                    elif '/emilkowalski' in t:
                        repo = 'emilkowalski-skill'
                    elif '/ui-ux-pro-max' in t:
                        repo = 'ui-ux-pro-max-skill'
                except Exception:
                    pass
            add(sm, 'user', repo)

# 2. Inspired repos — two possible layouts
for repo_dir in (SKILLS / '_inspired').glob('*/'):
    repo_name = repo_dir.name
    for sm in repo_dir.glob('skills/*/SKILL.md'):
        add(sm, 'inspired', repo_name)
    for sm in repo_dir.glob('.claude/skills/*/SKILL.md'):
        add(sm, 'inspired', repo_name)

# 3. Plugin-provided skills
if PLUGINS.is_dir():
    for sm in PLUGINS.glob('**/skills/*/SKILL.md'):
        # plugin path like: plugins/cache/marketplace/plugin-name/version/skills/<name>/SKILL.md
        parts = sm.parts
        repo_name = 'plugin:unknown'
        for i, p in enumerate(parts):
            if p == 'plugins' and i + 2 < len(parts):
                # Try to find the plugin name — it's often the element right before 'skills'
                for j, q in enumerate(parts):
                    if q == 'skills' and j >= 1:
                        repo_name = f"plugin:{parts[j-1]}"
                        break
                break
        add(sm, 'plugin', repo_name)

# Dedupe: if the same path appears twice, keep only the first
seen_paths = set()
out = []
for e in entries:
    if e['path'] in seen_paths:
        continue
    seen_paths.add(e['path'])
    out.append(e)

out_path = sys.argv[1]
with open(out_path, 'w') as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

print(f"scanned {len(out)} unique skill entries", file=sys.stderr)
PY

mv "$TMP" "$OUT"
echo "✓ inventory written: $OUT ($(jq length "$OUT") entries)"
