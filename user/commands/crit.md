---
description: Cross-model adversarial review — spawn kimi + opencode (or codex) for second opinions on a piece of code or decision.
argument-hint: "<what to review — file path, PR URL, or decision summary>"
---

Get second opinions from other AI coding tools installed on this machine.

Steps:

1. If `$ARGUMENTS` is empty, ask: "What should I crit? (file path, PR description, or plain-text decision)".

2. Prepare the review prompt:
   ```
   Give a critical, adversarial review of the following. Call out bugs, security issues,
   design flaws, and simpler alternatives. Do not be polite — be useful. Under 250 words.

   <CONTENT>
   ```
   If `$ARGUMENTS` is a file path, Read it and embed. If a URL, WebFetch it. Otherwise use it verbatim.

3. Check availability of external reviewers with Bash:
   - `command -v kimi`  → run `kimi -p "<prompt>"` in background via run_in_background
   - `command -v opencode` → run `opencode run "<prompt>"`
   - `command -v codex` → run `codex exec "<prompt>"`
   - `command -v aider` → skip (interactive only)
   Dispatch all available in parallel. Skip silently if a tool is missing.

4. Also generate Claude's own review so there are always ≥2 opinions.

5. Synthesize into:
   ```markdown
   # Crit: <short title>

   ## Claude (self)
   <review>

   ## Kimi
   <review or "not installed">

   ## OpenCode
   <review or "not installed">

   ## Codex
   <review or "not installed">

   ## Consensus
   - **All agree:** <shared concerns>
   - **Claude unique:** <only Claude flagged>
   - **Others unique:** <only external tools flagged>

   ## Recommendation
   <what to act on first>
   ```

6. If any external tool returned nothing or errored, note it but don't fail the command.

Never pipe secrets or .env contents into external tools.
