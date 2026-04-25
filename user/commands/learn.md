---
description: Append an insight to the daily llm-wiki. Inspired by everything-claude-code + karpathy llm-wiki.
argument-hint: "<insight text>"
---

Capture a learning, observation, or pattern into the persistent wiki.

Steps:

1. If `$ARGUMENTS` is empty, ask the user: "What did you learn? (one-liner or multi-paragraph, I'll tag it)".
2. Determine today's date: `date +%Y-%m-%d`.
3. Target file: `~/Desktop/ACTIVITIES/llm-wiki/$(date +%Y-%m-%d).md`.
4. If the file does not exist, seed it from `~/Desktop/ACTIVITIES/llm-wiki/TEMPLATE.md` (if that exists) or a minimal `# YYYY-MM-DD\n\n`.
5. Append an entry in this format:
   ```markdown

   ## $(date +%H:%M) — <3-5 word title you generate from the insight>

   $ARGUMENTS

   **Tags:** #insight [add others: #bug #learning #pattern #gotcha #workflow as applicable]
   **Project:** <infer from cwd — basename of git root or cwd>
   ```
6. If the insight references a URL or package, also append a `- $URL — <why it matters>` bullet to `~/Desktop/ACTIVITIES/useful-resources.md` under a `## Manually added (YYYY-MM-DD)` section.
7. Print a one-line confirmation: `✓ learned: <title> → llm-wiki/YYYY-MM-DD.md`.

This is purely deterministic — do not invoke any LLM call, just Edit/Write.
