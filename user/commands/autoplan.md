---
description: Run full review pipeline (CEO → design → engineering → DX) on a feature idea before coding. Inspired by gstack.
argument-hint: "<short feature description>"
---

You're running an AUTOPLAN on: **$ARGUMENTS**

Dispatch 4 agents **in parallel** (single message, multiple Agent tool calls), each with Explore subagent type, and summarize their findings:

1. **CEO/Founder review** — Agent with prompt:
   "Scope-and-strategy critique of this feature: '$ARGUMENTS'. Should we build it? What's the expected user impact vs engineering cost? Are there cheaper alternatives (existing library, 3rd party SaaS, manual process)? Produce a 3-paragraph verdict with either 'GO' or 'KILL' or 'DEFER' at the top."

2. **Engineering review** — Agent with prompt:
   "Architecture critique of '$ARGUMENTS' in THIS codebase (read key files first). List: affected modules, API contracts, data migrations needed, breaking changes, test coverage gaps, performance risks, deployment ordering. Call out anything that must happen BEFORE implementation starts."

3. **Design review** — Agent with prompt:
   "UX/design critique of '$ARGUMENTS'. What does the user flow look like? What new screens/components? How does this interact with existing design patterns? Rate 0-10 on: clarity, consistency, accessibility, delight. Surface risks."

4. **Developer-Experience review** — Agent with prompt:
   "DX critique of '$ARGUMENTS' for the next engineer. Is the ergonomics good? What needs documenting? What gets harder? What friction exists? Provide 3 concrete DX improvements the implementation should include from day 1."

After all 4 complete, synthesize into a **GO/KILL/DEFER decision**, a bullet list of BLOCKERS, and a bullet list of NON-BLOCKING IMPROVEMENTS. Ask the user if they want to proceed to `/paul:plan` (or a manual plan) for the GO path.
