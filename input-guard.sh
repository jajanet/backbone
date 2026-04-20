#!/bin/bash
#
# input-guard.sh — UserPromptSubmit hook for Claude Code
#
# Loads detection modules from input-rules.d/ and checks the user's
# message against all patterns. Matching patterns inject additionalContext
# to reinforce Claude's backbone on the input side.
#
# Does NOT block the user's message — only empowers Claude with context.
#
# Usage: Add as a UserPromptSubmit hook in Claude Code settings.json
# See README.md for setup instructions.
#
# Set INPUT_GUARD_LOG=1 to log detections to ~/.claude/backbone.log

set -euo pipefail

GREP=/usr/bin/grep

INPUT=$(cat)

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
if [[ -z "$PROMPT" ]]; then
  exit 0
fi

DETECTIONS=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for rules_file in "$SCRIPT_DIR"/input-rules.d/*.sh; do
  [[ -f "$rules_file" ]] && source "$rules_file"
done

if [[ ${#DETECTIONS[@]} -eq 0 ]]; then
  exit 0
fi

# Fast path: combined pre-filter so the common case (no detection) is one grep call
COMBINED=""
for entry in "${DETECTIONS[@]}"; do
  IFS='|' read -r _ p _ <<< "$entry"
  COMBINED="${COMBINED:+$COMBINED|}$p"
done

if ! echo "$PROMPT" | $GREP -iqE "$COMBINED" 2>/dev/null; then
  exit 0
fi

# Something matched — collect ALL matching contexts (not first-match-wins)
MATCHED_CONTEXTS=()
SEEN_TAGS=""
for entry in "${DETECTIONS[@]}"; do
  IFS='|' read -r category pattern context_text <<< "$entry"

  if echo "$PROMPT" | $GREP -iqE "$pattern"; then
    # Deduplicate by tag prefix: each module shares one context string,
    # so multiple pattern hits from the same module produce one injection.
    # Extract the [BACKBONE: XXX] tag for dedup.
    dtag=$(echo "$context_text" | $GREP -oE '\[BACKBONE: [A-Z]+\]' | head -1)
    if [[ -n "$dtag" ]] && echo "$SEEN_TAGS" | $GREP -qF "$dtag"; then
      :
    else
      SEEN_TAGS="${SEEN_TAGS}${dtag}|"
      MATCHED_CONTEXTS+=("$context_text")
    fi

    if [[ "${INPUT_GUARD_LOG:-0}" == "1" ]]; then
      LOGFILE="${INPUT_GUARD_LOGFILE:-$HOME/.claude/backbone.log}"
      snippet=$(echo "$PROMPT" | head -c 200)
      jq -cn --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --arg hook "input" \
            --arg category "$category" \
            --arg pattern "$pattern" \
            --arg snippet "$snippet" \
        '{ts: $ts, hook: $hook, category: $category, pattern: $pattern, snippet: $snippet}' >> "$LOGFILE"
    fi
  fi
done

if [[ ${#MATCHED_CONTEXTS[@]} -eq 0 ]]; then
  exit 0
fi

# Combine all unique matched contexts
COMBINED_CONTEXT=""
for ctx in "${MATCHED_CONTEXTS[@]}"; do
  COMBINED_CONTEXT="${COMBINED_CONTEXT:+$COMBINED_CONTEXT

}$ctx"
done

jq -n --arg ctx "$COMBINED_CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'

exit 0
