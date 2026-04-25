---
description: Multi-source research on a topic (WebSearch + WebFetch + context7 + duckduckgo). Produces a cited brief.
argument-hint: "<research topic>"
---

Run a parallel research pass on `$ARGUMENTS` and produce a cited brief.

Steps:

1. If `$ARGUMENTS` is empty, ask: "What's the research topic?".

2. Dispatch these calls **in parallel** (single message, multiple tool calls):
   - `WebSearch` for `$ARGUMENTS` (broad)
   - `mcp__duckduckgo__duckduckgo_web_search` for `$ARGUMENTS` (cross-check)
   - If the topic mentions a library/framework/SDK, also:
     - `mcp__plugin_context7_context7__resolve-library-id` then `query-docs`

3. From the search results, pick the top 3-5 distinct, high-quality URLs and dispatch parallel `WebFetch` on each (prompt: "Extract: main claim, key data points, limitations, date published, author credibility.").

4. Synthesize into this format:
   ```markdown
   # Research: $ARGUMENTS

   **Date:** YYYY-MM-DD | **Sources consulted:** N

   ## TL;DR
   <3-bullet summary>

   ## Key findings
   - <claim> — <source 1>
   - <claim> — <source 2>
   ...

   ## Contradictions / gaps
   - <where sources disagree or are silent>

   ## Sources
   1. <title> — <url> — <date> — <credibility note>
   2. ...
   ```

5. Offer to save the brief to `~/Desktop/ACTIVITIES/llm-wiki/research/<slug>-$(date +%Y%m%d).md`.

Never present unsourced claims as fact. If context7 has docs on the topic, cite them first.
