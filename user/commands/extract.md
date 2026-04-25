---
description: Structured extraction from a URL or local file into JSON/markdown. Inspired by google/langextract.
argument-hint: "<url | file path> [schema hint]"
---

Extract structured data from a source using Claude itself (no Python dep required).

Steps:

1. Parse `$ARGUMENTS`:
   - First token = source (URL or local file path).
   - Rest = free-text schema hint (e.g. "people and their titles", "pricing tiers", "API endpoints").
   - If missing source: ask "What should I extract from (URL or path)?".

2. Fetch content:
   - URL → use WebFetch with prompt: "Return only the primary textual content, strip nav/footer/ads."
   - Local file → use Read. For PDFs pass pages 1-20 by default; warn if >20 pages.

3. If schema hint is empty, propose a sensible default based on the content (e.g. news article → {title, date, author, entities, summary}).

4. Produce structured output in this format:
   ```markdown
   # Extracted from <source>

   **Schema:** <inferred or user-provided>
   **Extracted at:** <today's date>

   ```json
   {
     ...structured data here...
   }
   ```

   ## Source grounding
   - <field>: "<exact quote from source>"
   - ...
   ```

5. Offer to save to `~/Desktop/ACTIVITIES/llm-wiki/extracts/<slug>-$(date +%Y%m%d).md` if user says "save" / "yes".

Keep each quote ≤ 200 chars. Do not hallucinate fields not present in the source.
