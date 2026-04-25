# Security Policy

## Reporting a vulnerability

**Do not open a public issue for security bugs.** Instead, email **ali@jets.partners** with:

1. A short description (1-2 sentences)
2. Reproduction steps
3. Affected versions / commit SHA
4. Your assessment of severity (Low / Medium / High / Critical)

Expected response time: **3 business days** for acknowledgement, **14 days** for a fix or mitigation plan.

## Scope

In scope:

- Scripts in `install.sh`, `install-skills.sh`, `scripts/*.sh`, `user/hooks/*.sh`
- Settings templates that could leak credentials if mishandled
- Default permission allow-lists that could grant unintended access

Out of scope:

- Vulnerabilities in upstream tools (Ollama, Goose, Codex, Kimi, OpenCode, Claude Code, Gemini CLI, Claw, npm packages) — report those upstream
- Misconfigurations on the user's machine (e.g. world-readable `~/.zshrc`)
- Social engineering of contributors

## What we do with reports

1. Acknowledge within 3 business days
2. Verify the issue privately
3. Develop a fix on a private branch
4. Coordinate disclosure: fix → release → public CVE/advisory (if warranted)
5. Credit the reporter in `CHANGELOG.md` (unless they opt out)

## Hardening best practices for users

- Run `bash install.sh --dry-run user` before applying changes
- Keep `~/.claude/settings.json` set to `chmod 600`
- Store secrets in env vars (`~/.zshrc`), never in committed files
- Read `CREDS.md.template` and `SECRETS.md.template` for guidance on local secret storage
- Audit `permissions.allow` in `user/settings.json` before deploying — the bundle ships safe defaults but your usage may differ
- Review `permissions.ask` and `permissions.deny` lists — destructive commands prompt by default
