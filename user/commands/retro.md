---
description: Weekly retrospective based on IMPROVEMENT_STATE.json across all projects. Inspired by gstack.
argument-hint: "[days, default 7]"
---

Run a retrospective for the last N days (default: 7, pass a number via $ARGUMENTS to override).

Steps:

1. Find every `IMPROVEMENT_STATE.json` on this machine (user Desktop projects):
   ```bash
   find ~/Desktop -maxdepth 5 -name IMPROVEMENT_STATE.json -not -path "*/node_modules/*" 2>/dev/null
   ```

2. For each, read the `iterations` array and filter entries where `timestamp` is within the last N days.

3. Aggregate and produce a report:
   - **Projects worked on this period:** count by project, sorted by iteration count
   - **Biggest-delta projects:** top 3 projects by total git line changes (sum `dirty_files` etc.)
   - **Quiet projects:** projects with state files but 0 iterations in N days (candidates for archive)
   - **Session hot-streaks:** days with 5+ total iterations across all projects

4. Read the relevant slice of `~/Desktop/ACTIVITIES/llm-wiki/YYYY-MM-DD.md` files for the same N-day window. Extract:
   - Top tagged patterns (`#bug`, `#insight`, `#learning`)
   - Recurring URLs or packages from `useful-resources.md`

5. End with 3 recommendations:
   - one thing to **double down on** (highest-velocity area)
   - one thing to **investigate** (suspicious pattern)
   - one thing to **drop** (graveyard candidate)

Format the output as a concise markdown report, <300 lines. Save it to `~/Desktop/ACTIVITIES/llm-wiki/weekly/$(date +%Y-W%V).md` and print a summary to chat.
