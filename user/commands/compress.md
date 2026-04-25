---
description: Summarize the current conversation into a short handoff doc for future sessions.
---

Produce a handoff document that captures the essential state of THIS conversation so a future session can pick up without context.

Steps:

1. Review the conversation and extract:
   - **Goal**: what the user is ultimately trying to accomplish
   - **Decisions made**: concrete choices, not considerations
   - **Files touched**: list with 1-line reason each
   - **Open threads**: unfinished tasks, unresolved questions, blockers
   - **Next step**: the single most useful thing to do next
   - **Gotchas**: anything a future session should be warned about (bugs found, dead ends, misleading signals)

2. Write to `~/Desktop/ACTIVITIES/llm-wiki/handoffs/$(date +%Y%m%d-%H%M)-<slug>.md`:
   ```markdown
   # Handoff: <short title>

   **Date:** YYYY-MM-DD HH:MM
   **Session duration:** approximate
   **Project / cwd:** <path>

   ## Goal
   <1-2 sentences>

   ## Decisions
   - ...

   ## Files touched
   | file | change |
   |------|--------|
   | path | reason |

   ## Open threads
   - [ ] ...

   ## Next step
   <one concrete action>

   ## Gotchas
   - ...
   ```

3. Also append a pointer line to `~/Desktop/ACTIVITIES/llm-wiki/$(date +%Y-%m-%d).md`:
   `- 🗂️ Handoff saved: [<title>](handoffs/YYYYMMDD-HHMM-slug.md)`

4. Print the absolute path of the handoff file to chat so the user can paste it into a new session.

Keep the handoff under 200 lines. Omit anything that can be re-derived from reading the code.
