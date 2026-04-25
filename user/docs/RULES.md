# Rules

The canonical set of behavioral rules Claude Code follows on your machine. These are **non-negotiable** — tested via hooks where possible, documented here for the rest.

## 1. Karpathy's Four Principles

See `CLAUDE.md` managed block. Summary:
1. **Think before coding** — state assumptions, ask on ambiguity.
2. **Simplicity first** — no speculative features, no abstractions for single-use code.
3. **Surgical changes** — touch only what's needed, match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.

## 2. Commit Rules

| Rule | Enforcement |
|------|-------------|
| No `Co-Authored-By: Claude` | `~/.claude/hooks/block-ai-attribution.sh` (PreToolUse/Bash, exit 2) |
| No `Generated with [Claude Code]` / `🤖 Generated with` | Same hook |
| Conventional Commits: `<type>: <desc>` | CLAUDE.md preference; not hook-enforced |
| Subject ≤ 70 chars, imperative mood | CLAUDE.md preference |
| One logical change per commit | CLAUDE.md preference |
| No `--amend` on pushed commits | Via `ask` tier for `git push --force` |

## 3. Secret Rules

| Rule | Enforcement |
|------|-------------|
| Never write to `.env*` (except `.env.example`) | `~/.claude/hooks/block-secret-writes.sh` (PreToolUse/Write\|Edit, exit 2) |
| Never write `*.key`, `*.pem`, `*.enc`, `*.crt`, `*.p12`, `*.pfx` | Same hook |
| Never write files under `.ssh/` or `.gnupg/` | Same hook |
| Never write `.credentials.json`, `auth.json`, files with "secret" in name | Same hook |
| Never print/echo secrets | CLAUDE.md preference |

## 4. Destructive-Action Rules

| Action | Tier | Behavior |
|--------|------|----------|
| `rm -rf /`, `sudo rm -rf`, `mkfs*`, `dd if=*`, `> /dev/sda*`, `curl \| bash` | `deny` | Blocked — never runs |
| `rm`, `mv`, `sudo`, `docker`, `docker-compose`, `kubectl delete` | `ask` | One-keystroke approval |
| `git push`, `git reset --hard`, `git rebase`, `git clean -fd` | `ask` | Approval required |
| `npm publish`, `cargo publish`, `gh pr merge`, `gh release create` | `ask` | Approval required |
| `terraform apply`, `terraform destroy`, `railway up`, `vercel deploy` | `ask` | Approval required |
| Everything else (reads, builds, tests, lints) | `allow` | Runs silently |

## 5. Workflow Rules

1. **Plan first** for any change touching 2+ files.
2. **Auto-format after edit** — `biome`/`ruff`/`rustfmt`/`gofmt` via PostToolUse hook.
3. **Update docs in the same commit as the code** (`ARCHITECTURE.md`, `SERVICES.md`, `ROADMAP.md`).
4. **Never auto-push or auto-deploy** — explicit instruction required.
5. **Trash over delete** — prefer `gio trash` / `trash-put` to `rm`.

## 6. Output-Style Rules

- Default: explanatory + learning modes.
- Use `★ Insight ─────────────────` blocks for non-obvious patterns.
- Keep final responses ≤ 100 words unless the task needs depth.
- Never narrate internal deliberation. State decisions and results.

## Changing a rule

Edit the relevant file (`settings.json` for tiers, `hooks/*.sh` for enforcement, `CLAUDE.md` for preferences), then:
1. Add a `CHANGELOG.md` entry.
2. Rerun `install.sh user` to redeploy.
3. Start a new Claude Code session so the rules reload.
