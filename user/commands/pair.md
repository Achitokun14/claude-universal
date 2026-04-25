---
description: Dispatch parallel Explore + Plan agents on a question. Inspired by obra/superpowers.
argument-hint: "<question or task>"
---

Pair-programming pattern: run an Explore agent (gathers facts) and a Plan agent (designs approach) **concurrently** on the same question, then synthesize.

Steps:

1. If `$ARGUMENTS` is empty, ask: "What's the question or task to pair on?".

2. Dispatch in a SINGLE message with two Agent tool calls in parallel:
   - **Explore agent** (`subagent_type: "Explore"`, thoroughness: "medium"):
     ```
     Explore the current codebase in service of this question: "$ARGUMENTS".
     Return: relevant files with line refs, existing patterns that apply, prior art,
     and concrete constraints (framework version, language, conventions). Facts only,
     no recommendations. Under 400 words.
     ```
   - **Plan agent** (`subagent_type: "Plan"`):
     ```
     Design an implementation approach for: "$ARGUMENTS". Assume the codebase will be
     explored separately — you focus on trade-offs, step ordering, and risk. Produce:
     2-3 viable approaches, 1 recommendation with rationale, explicit dependencies
     and sequencing. Under 400 words.
     ```

3. When both return, synthesize into:
   ```markdown
   # Pair result: $ARGUMENTS

   ## Explore (facts)
   <bullet distillation from Explore agent>

   ## Plan (approach)
   <bullet distillation from Plan agent>

   ## Synthesis
   **Recommended path:** <one sentence>
   **Key risks:** <bullets>
   **First step:** <one concrete action>
   ```

4. Ask if the user wants to proceed with the recommended path, pick an alternative, or dig deeper.

Do not start implementing until the user chooses.
