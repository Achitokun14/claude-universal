#!/usr/bin/env bash
# PreToolUse(Write|Edit) — block writes to secret files.
# Why: you store real credentials in .env / .credentials.json / *.key / auth.json.
# Prevents accidental overwrite/exfil by Claude.
# Allowed: .env.example, .env.sample, *.key.example (template variants).

set -euo pipefail

payload="$(cat)"
file_path="$(echo "$payload" | jq -r '.tool_input.file_path // ""')"
[[ -z "$file_path" ]] && exit 0

basename_f="$(basename "$file_path")"

# Always-allowed templates
case "$basename_f" in
  .env.example|.env.sample|.env.template|*.key.example|*.pem.example) exit 0 ;;
esac

# Block patterns
if echo "$file_path" | grep -qE '(/\.ssh/|/\.gnupg/|\.credentials\.json$|auth\.json$)' \
   || echo "$basename_f" | grep -qE '^\.env($|\.)' \
   || echo "$basename_f" | grep -qE '\.(key|pem|enc|crt|p12|pfx)$' \
   || echo "$basename_f" | grep -qE 'secret' ; then
  cat <<MSG >&2
BLOCKED: writing to a sensitive file: $file_path

This path looks like a secret or credentials file. If you really need to edit
a template, use the *.example / *.sample / *.template variant instead. If this
is intentional, ask the user to temporarily disable this hook.
MSG
  exit 2
fi

exit 0
