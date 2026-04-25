# Skills

Skills are markdown files (optionally with supporting scripts) that Claude loads on-demand via the Skill tool. Live at `~/.claude/skills/<name>/SKILL.md`.

## Format

```markdown
---
description: Short trigger description — when Claude should load this skill.
---

# Skill Title

Body: the instructions Claude follows when invoked.
```

## Core skills (already installed locally)

Your existing set under `~/.claude/skills/` (detected — kept as-is):

- `callstack-skills` · `supabase-skills` · `makepad-skills` · `Skill_Seekers` · `sentry-skills`
- `n8n-skills` · `terraform-skill` · `claude-win11-speckit-update-skill`
- `marketingskills` · `neon-skills` · `vercel-next-skills`
- `AI-research-SKILLs` · `recursive-decomposition-skill` · `aws-skills`
- `claude-bootstrap` · `ios-simulator-skill` · `agent-skills`
- `trailofbits-skills` · `expo-skills` · `ui-ux-pro-max-skill`
- `stripe-ai` · `claude-speed-reader` · `clarity-gate` · `Claude-Ally-Health`

The bundle does **not** redistribute these — they're yours. `install.sh` never touches `~/.claude/skills/`.

## Loading a skill

Claude loads a skill either:
- Automatically when the `description` field matches the current task intent.
- Manually via `Skill` tool: `Skill(skill="stripe-ai")`.

## Creating your own

```bash
mkdir -p ~/.claude/skills/my-skill
cat > ~/.claude/skills/my-skill/SKILL.md <<'EOF'
---
description: Explain what triggers loading this skill.
---

# My Skill

Instructions...
EOF
```

No restart needed — skills are discovered each session.

## Project-scoped skills

`<repo>/.claude/skills/<name>/SKILL.md` — loaded only when working in that repo. Useful for domain-specific rules (e.g., "how our monorepo's custom CLI works").

## Design/UI skills in use (global)

These 4 are installed globally — available in every project on this machine.

| Skill name(s) | Source | Install |
|---|---|---|
| `emil-design-eng` | [emilkowalski/skill](https://github.com/emilkowalski/skill) | `git clone https://github.com/emilkowalski/skill ~/.claude/skills/emilkowalski-skill && ln -s emilkowalski-skill/skills/emil-design-eng ~/.claude/skills/emil-design-eng` |
| `taste-skill`, `minimalist-skill`, `soft-skill`, `brutalist-skill`, `redesign-skill` | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | `git clone https://github.com/Leonxlnx/taste-skill ~/.claude/skills/taste-skill-repo` — then symlink each variant from `skills/<variant>/` into `~/.claude/skills/<variant>/` |
| `impeccable:*` (20 commands: polish, critique, audit, bolder, quieter, ...) | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Installed as plugin; enable in `settings.json`: `"impeccable@impeccable": true` |
| `ui-ux-pro-max` | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | `git clone https://github.com/nextlevelbuilder/ui-ux-pro-max-skill ~/.claude/skills/ui-ux-pro-max-skill && ln -s ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max ~/.claude/skills/ui-ux-pro-max` |

**Updating:** `cd ~/.claude/skills/<repo-name> && git pull` — symlinks resolve automatically.

**Why symlink instead of copy:** repos have their own project layout (e.g., `skills/emil-design-eng/SKILL.md`), but Claude Code only scans `~/.claude/skills/<name>/SKILL.md` at the top level. Symlinks surface the right folder without restructuring the upstream repo, so `git pull` just works.

## Skill discovery sources

- [antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) — 1,370+ community skills
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — 232+ engineering/marketing/PM
- [mcpmarket.com](https://mcpmarket.com) — curated marketplace

## See also

- `~/Desktop/Claude-Code-Ecosystem.md` for skill collections and plugins.
