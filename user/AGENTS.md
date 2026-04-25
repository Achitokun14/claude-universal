<!-- AGENTS.md mirrors CLAUDE.md so Codex CLI, Cursor, OpenCode, Windsurf, and other agent tools read the same rules. -->
<!-- Rebuilt from user/CLAUDE.md by install.sh. Do not edit here — edit CLAUDE.md and rerun installer. -->
<!-- BEGIN: claude-universal managed block (do not edit between these markers — rerun installer to update) -->
# AI Agent — Universal Rules

## Core (always on)

1. **Think before coding.** State assumptions, ask on ambiguity, surface tradeoffs.
2. **Simplicity first.** Minimum code. No speculative features. 50 lines over 200.
3. **Surgical changes.** Touch only what's needed. Match existing style. Clean up only your own mess.
4. **Goal-driven.** Define success criteria, loop until verified. Plan multi-file work first.
5. **No AI attribution.** Never add `Co-Authored-By:`, `🤖`, or `Generated with` anywhere.
6. **Ask before destructive ops.** Pushes, deploys, schema resets require explicit approval.
7. **Update docs with code.** Service/interface change = doc change, same commit.

## Tool-use order when something's missing

Project MCP/skill → user-level MCP/skill → local CLI → web search + fetch → ask user.

## References

`~/.claude/docs/` holds: `RULES.md`, `SETTINGS.md`, `HOOKS.md`, `MCPS.md`, `SKILLS.md`, `ACPS.md`, `WEB-FALLBACK.md`, `CHANGELOG.md`. Load only what the current task needs.
<!-- END: claude-universal managed block -->
