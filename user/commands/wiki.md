---
description: Search the persistent llm-wiki for existing notes on a topic.
argument-hint: "<topic or keyword>"
---

Search `~/Desktop/ACTIVITIES/llm-wiki/` for prior notes matching `$ARGUMENTS`.

Steps:

1. If `$ARGUMENTS` is empty, ask: "What topic should I look up?".
2. Run a Grep over `~/Desktop/ACTIVITIES/llm-wiki/` (recursive, case-insensitive) for `$ARGUMENTS` using output_mode: "content" with -B 2 -A 5 and head_limit: 40.
3. Also Grep `~/Desktop/ACTIVITIES/useful-resources.md` for the same pattern (that's where URLs/packages from past sessions live).
4. Group matches by file (date) and print:
   ```
   📚 Wiki hits for "$ARGUMENTS"

   2026-04-12.md (3 entries)
     14:23 — <section title> ...snippet...
     16:05 — <section title> ...snippet...
   2026-03-30.md (1 entry)
     ...

   🔗 Resources matches (useful-resources.md): N
     - <bulleted list of up to 10 URL/package lines>
   ```
5. If zero matches, suggest: "No prior notes. Use `/learn <insight>` to create the first entry on this topic."

Read-only — never modify files.
