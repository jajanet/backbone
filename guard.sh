#!/bin/bash
#
# guard.sh — Modular stop hook for Claude Code
#
# Loads rule modules from rules.d/ and checks the assistant's message
# against all patterns. Each module appends to the VIOLATIONS array.
#
# Usage: Add as a Stop hook in Claude Code settings.json
# See README.md for setup instructions.
#
# Set STOP_GUARD_LOG=1 to log violations to ~/.claude/stop-guard.log

set -euo pipefail

GREP=/usr/bin/grep

INPUT=$(cat)

HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')
if [[ -z "$MESSAGE" ]]; then
  exit 0
fi

VIOLATIONS=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for rules_file in "$SCRIPT_DIR"/rules.d/*.sh; do
  [[ -f "$rules_file" ]] && source "$rules_file"
done

if [[ ${#VIOLATIONS[@]} -eq 0 ]]; then
  exit 0
fi

# Fast path: combined pre-filter so the common case (no violation) is one grep call
COMBINED=""
for entry in "${VIOLATIONS[@]}"; do
  IFS='|' read -r _ p _ <<< "$entry"
  COMBINED="${COMBINED:+$COMBINED|}$p"
done

if ! echo "$MESSAGE" | $GREP -iqE "$COMBINED" 2>/dev/null; then
  exit 0
fi

# Something matched — find the specific violation (first match wins)
for entry in "${VIOLATIONS[@]}"; do
  IFS='|' read -r category pattern correction <<< "$entry"

  if echo "$MESSAGE" | $GREP -iq "$pattern"; then
    if [[ "${STOP_GUARD_LOG:-0}" == "1" ]]; then
      LOGFILE="${STOP_GUARD_LOGFILE:-$HOME/.claude/stop-guard.log}"
      snippet=$(echo "$MESSAGE" | head -c 200)
      jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --arg category "$category" \
            --arg pattern "$pattern" \
            --arg snippet "$snippet" \
        '{ts: $ts, category: $category, pattern: $pattern, snippet: $snippet}' >> "$LOGFILE"
    fi

    jq -n --arg reason "STOP HOOK VIOLATION: $correction" '{
      decision: "block",
      reason: $reason
    }'
    exit 0
  fi
done

exit 0
