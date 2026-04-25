---
description: Warn before destructive commands (rm -rf, DROP TABLE, git push --force, docker prune). Pairs with /freeze and /guard. Inspired by gstack.
---

You are in CAREFUL mode for the next action. Before running any command that could lose data:

1. State EXACTLY what the command will do in plain English.
2. List the files/paths/services that would be affected.
3. Ask for explicit confirmation: "Type 'yes, <action>' to proceed."
4. Never proceed if user types anything other than the exact confirmation string.

Trigger list (require confirmation for any of these):
- `rm -rf`, `rm` with wildcards, `find … -delete`
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`, `DELETE FROM … WHERE 1=1`
- `git push --force`, `git reset --hard`, `git clean -fd`, `git rebase -i` of pushed commits
- `docker system prune`, `docker volume rm`, `kubectl delete namespace`
- `terraform destroy`, `railway destroy`, `vercel rm`
- `npm publish`, `cargo publish`, `gh release create`
- any `sudo` operation
- writes to `.env*`, `*.key`, `*.pem`, `.credentials.json`

If the user has $ARGUMENTS specified, they're describing a specific action — audit that action against the above, and explain the risk before executing.

CAREFUL mode persists for this session. To turn off: user types "exit careful mode".
