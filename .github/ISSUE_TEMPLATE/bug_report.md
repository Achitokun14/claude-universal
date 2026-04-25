---
name: Bug report
about: Something doesn't work as documented
title: 'bug: <one-line summary>'
labels: bug
assignees: Achitokun14
---

## What happened

<clear, factual description>

## What you expected

<contrast to what actually happened>

## Reproduction

```bash
# exact commands you ran
```

## Environment

- OS: <linux/macos/windows + version>
- Bundle commit: `git rev-parse --short HEAD`
- AI CLI(s) and version: <claude --version, etc.>
- Shell: <bash 5.x / zsh 5.9 / fish>

## Logs

```
<paste any relevant output, scrubbed of secrets>
```

## Tried already

- [ ] Re-ran with `--dry-run` and inspected output
- [ ] Checked `~/.claude/settings.json.bak.*` for clean rollback
- [ ] Searched existing issues
