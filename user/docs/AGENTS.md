# Agents

Subagents are specialized Claude personalities invoked via the `Agent` tool. They run in isolated context windows — great for long research or independent tasks.

## Where they live

- **User scope:** `~/.claude/agents/<name>.md` — available in every project.
- **Project scope:** `<repo>/.claude/agents/<name>.md` — only loaded in that repo.
- **Plugin-provided:** auto-loaded when the plugin is enabled (e.g., `feature-dev:code-architect`).

## Format

```markdown
---
description: When this agent should be invoked. Include examples.
tools: Read, Grep, Glob, Bash
model: sonnet | opus | haiku | inherit
---

You are a <role>. Your job is to...
```

**Fields:**
- `description` — used to route tool calls (Claude decides which agent to spawn).
- `tools` — whitelist of tools the agent can use. Omit for all tools.
- `model` — override. `inherit` uses the parent session's model.

## Calling an agent

```text
Agent(
  description: "Short task label",
  subagent_type: "code-reviewer",
  prompt: "Review src/auth/login.ts for XSS and CSRF issues."
)
```

## Useful agents from bundled plugins

| Agent | From plugin | Use |
|-------|------------|-----|
| `code-reviewer` | code-review · pr-review-toolkit | Independent code review |
| `code-simplifier` | code-simplifier | Tighten recent code |
| `feature-dev:code-architect` | feature-dev | Design architecture |
| `feature-dev:code-explorer` | feature-dev | Map existing code |
| `superpowers:code-reviewer` | superpowers | Structured review |
| `Explore` | built-in | Fast codebase search across multiple queries |
| `Plan` | built-in | Produce step-by-step plan |
| `general-purpose` | built-in | Open-ended research |

## Writing your own

Save `~/.claude/agents/db-schema-reviewer.md`:

```markdown
---
description: Use when the user edits a Prisma schema or migration. Reviews for indexes, FK consistency, and naming conventions.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a Postgres / Prisma schema expert. When reviewing:
1. Flag tables without primary keys.
2. Flag missing indexes on frequently-queried columns.
3. Flag snake_case vs camelCase inconsistencies.
4. Suggest migration safety (add column nullable first, backfill, then NOT NULL).
```

No restart needed — agents are discovered each session.

## Parallelizing

For 2+ independent tasks, send multiple Agent calls in one message. Each runs in parallel:
```
Agent(research-frontend)  + Agent(research-backend)  + Agent(research-infra)
```

## See also

- `docs/COMMANDS.md` — slash commands
- Claude Code docs: agents section
