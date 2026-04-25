---
description: Lock edits to a specific directory for the rest of the session. Inspired by gstack.
argument-hint: "<directory path, relative or absolute>"
---

FREEZE mode: for the rest of this session, refuse to Write or Edit any file OUTSIDE the directory `$ARGUMENTS`.

Rules:
1. Set the "frozen root" to `$ARGUMENTS`.
2. For every Write / Edit / MultiEdit call: verify `file_path` starts with the frozen root (canonical absolute path). If not, refuse with: "FROZEN: cannot edit files outside $ARGUMENTS. Use /unfreeze to release."
3. You can still **read** files anywhere — freeze only blocks writes.
4. Reading/exploring/searching is unaffected.
5. Announce the freeze clearly: "🧊 Edits frozen to $ARGUMENTS for this session."

To release: user types `/unfreeze`.

If `$ARGUMENTS` is empty, ask the user which directory to freeze.
