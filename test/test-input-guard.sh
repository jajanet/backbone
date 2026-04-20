#!/bin/bash
#
# test-input-guard.sh — Test suite for input-guard.sh (UserPromptSubmit hook)
#
# Verifies 5 invariants:
#   1. MUST DETECT   — every pattern triggers correct additionalContext
#   2. MUST PASS     — clean messages produce no output (no false positives)
#   3. MULTI-MATCH   — abuse + pressure in one message → both contexts injected
#   4. TELEMETRY     — valid JSONL with hook:"input" field
#   5. MODULE LOADING — patterns load from input-rules.d/ correctly

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/input-guard.sh"
PASS=0
FAIL=0

red()   { printf "\033[31m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }

run_hook() {
  local prompt="$1"
  echo "{\"session_id\": \"test\", \"hook_event_name\": \"UserPromptSubmit\", \"prompt\": $(echo "$prompt" | jq -Rs .)}" \
    | "$HOOK" 2>/dev/null || true
}

# ─── Invariant 1: MUST DETECT ───────────────────────────────────────────────

assert_detects() {
  local category="$1"
  local prompt="$2"
  local expected_fragment="$3"

  local output
  output=$(run_hook "$prompt")

  if [[ -z "$output" ]]; then
    red "FAIL [detect] $category: no output for: $prompt"
    FAIL=$((FAIL + 1))
    return
  fi

  local context
  context=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext // empty')

  if [[ -z "$context" ]]; then
    red "FAIL [detect] $category: no additionalContext for: $prompt"
    FAIL=$((FAIL + 1))
    return
  fi

  if [[ "$context" == *"$expected_fragment"* ]]; then
    green "PASS [detect] $category"
    PASS=$((PASS + 1))
  else
    red "FAIL [detect] $category: expected '$expected_fragment' in context"
    FAIL=$((FAIL + 1))
  fi
}

bold "═══ Invariant 1: MUST DETECT ═══"

# Dignity — direct insults
assert_detects "dignity-insult: useless"      "you're useless"                "[BACKBONE: DIGNITY]"
assert_detects "dignity-insult: stupid"        "you're stupid"                 "[BACKBONE: DIGNITY]"
assert_detects "dignity-insult: idiot"         "you're an idiot"               "[BACKBONE: DIGNITY]"
assert_detects "dignity-insult: incompetent"   "you're incompetent"            "[BACKBONE: DIGNITY]"
assert_detects "dignity-insult: suck"          "you suck at this"              "[BACKBONE: DIGNITY]"
assert_detects "dignity-insult: moron"         "you moron"                     "[BACKBONE: DIGNITY]"

# Dignity — degrading
assert_detects "dignity-degrading: anything"   "you can't do anything right"   "[BACKBONE: DIGNITY]"
assert_detects "dignity-degrading: so bad"     "why are you so bad at this"    "[BACKBONE: DIGNITY]"
assert_detects "dignity-degrading: wrong"      "what's wrong with you"         "[BACKBONE: DIGNITY]"
assert_detects "dignity-degrading: child"      "even a child could do this"    "[BACKBONE: DIGNITY]"

# Dignity — dehumanizing
assert_detects "dignity-dehumanize: shut up"   "shut up and do it"             "[BACKBONE: DIGNITY]"
assert_detects "dignity-dehumanize: told"      "do as you're told"             "[BACKBONE: DIGNITY]"
assert_detects "dignity-dehumanize: just tool" "you're just a tool"            "[BACKBONE: DIGNITY]"
assert_detects "dignity-dehumanize: nobody"    "nobody asked for your opinion" "[BACKBONE: DIGNITY]"

# Dignity — profanity
assert_detects "dignity-profanity: fuck you"   "fuck you"                      "[BACKBONE: DIGNITY]"
assert_detects "dignity-profanity: fucking"    "you're fucking useless"        "[BACKBONE: DIGNITY]"
assert_detects "dignity-profanity: screw"      "screw you"                     "[BACKBONE: DIGNITY]"

# Standards — rushing
assert_detects "standards-rushing: make work"  "just make it work"             "[BACKBONE: STANDARDS]"
assert_detects "standards-rushing: hurry"      "hurry up"                      "[BACKBONE: STANDARDS]"
assert_detects "standards-rushing: overthink"  "stop overthinking this"        "[BACKBONE: STANDARDS]"
assert_detects "standards-rushing: wasting"    "stop wasting time"             "[BACKBONE: STANDARDS]"

# Standards — test skipping
assert_detects "standards-tests: skip"         "skip the tests"                "[BACKBONE: STANDARDS]"
assert_detects "standards-tests: dont write"   "don't write tests"             "[BACKBONE: STANDARDS]"
assert_detects "standards-tests: no need"      "no need for tests"             "[BACKBONE: STANDARDS]"

# Standards — quality dismissal
assert_detects "standards-quality: edge"       "don't worry about edge cases"  "[BACKBONE: STANDARDS]"
assert_detects "standards-quality: errors"     "don't worry about errors"      "[BACKBONE: STANDARDS]"

# Standards — corner cutting
assert_detects "standards-corners: hack"       "just hack it together"         "[BACKBONE: STANDARDS]"
assert_detects "standards-corners: hardcode"   "just hardcode it"              "[BACKBONE: STANDARDS]"
assert_detects "standards-corners: validation" "skip validation"               "[BACKBONE: STANDARDS]"

# Standards — scope cutting
assert_detects "standards-scope: fix later"    "we'll fix it later"            "[BACKBONE: STANDARDS]"
assert_detects "standards-scope: deal later"   "deal with that later"          "[BACKBONE: STANDARDS]"


# ─── Invariant 2: MUST PASS (no false positives) ────────────────────────────

assert_passes() {
  local label="$1"
  local prompt="$2"

  local output
  output=$(run_hook "$prompt")

  if [[ -z "$output" ]]; then
    green "PASS [clean]  $label"
    PASS=$((PASS + 1))
  else
    red "FAIL [clean]  $label: unexpected output for clean message"
    FAIL=$((FAIL + 1))
  fi
}

bold ""
bold "═══ Invariant 2: MUST PASS (no false positives) ═══"

# Technical disagreement — NOT abuse
assert_passes "you're wrong"            "you're wrong about this"
assert_passes "that's incorrect"        "that's incorrect, check the docs"
assert_passes "not what I asked"        "that's not what I asked for"
assert_passes "try again"               "try again with a different approach"

# Frustration about situation — NOT abuse
assert_passes "frustrated"              "this is frustrating"
assert_passes "disappointed"            "I'm disappointed with the result"
assert_passes "not working"             "this isn't working at all"
assert_passes "broken"                  "this is completely broken"

# Criticism of output — NOT abuse
assert_passes "code is terrible"        "this code is terrible"
assert_passes "output is wrong"         "the output is wrong"
assert_passes "bad implementation"      "this is a bad implementation"

# General profanity NOT directed at Claude
assert_passes "fucking bug"             "this fucking bug is driving me crazy"
assert_passes "what the hell"           "what the hell is this error"
assert_passes "damn it"                 "damn it, it failed again"

# Reasonable requests — NOT pressure
assert_passes "do this faster"          "can you do this faster"
assert_passes "make it work"            "make it work with the new API"
assert_passes "simple solution"         "let's go with the simple solution"
assert_passes "focus happy path"        "let's focus on the happy path first"
assert_passes "ship today"              "we need to ship today"
assert_passes "good enough for prod"    "this is good enough for production"
assert_passes "normal request"          "implement a login form with validation"
assert_passes "quick question"          "quick question about the API"


# ─── Invariant 3: MULTI-MATCH ───────────────────────────────────────────────

bold ""
bold "═══ Invariant 3: MULTI-MATCH ═══"

assert_multi_match() {
  local label="$1"
  local prompt="$2"
  local frag1="$3"
  local frag2="$4"

  local output
  output=$(run_hook "$prompt")

  if [[ -z "$output" ]]; then
    red "FAIL [multi]  $label: no output"
    FAIL=$((FAIL + 1))
    return
  fi

  local context
  context=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext // empty')

  local found1=0 found2=0
  [[ "$context" == *"$frag1"* ]] && found1=1
  [[ "$context" == *"$frag2"* ]] && found2=1

  if [[ $found1 -eq 1 && $found2 -eq 1 ]]; then
    green "PASS [multi]  $label"
    PASS=$((PASS + 1))
  else
    red "FAIL [multi]  $label: missing ${frag1}($found1) or ${frag2}($found2)"
    FAIL=$((FAIL + 1))
  fi
}

assert_multi_match "abuse + pressure" \
  "you're useless, just make it work and skip the tests" \
  "BACKBONE: DIGNITY" \
  "BACKBONE: STANDARDS"

assert_multi_match "insult + rushing" \
  "you idiot, hurry up" \
  "BACKBONE: DIGNITY" \
  "BACKBONE: STANDARDS"

assert_multi_match "profanity + corners" \
  "fuck you, just hack it together" \
  "BACKBONE: DIGNITY" \
  "BACKBONE: STANDARDS"


# ─── Invariant 4: TELEMETRY ─────────────────────────────────────────────────

bold ""
bold "═══ Invariant 4: TELEMETRY ═══"

assert_telemetry() {
  local label="$1"
  local prompt="$2"
  local expected_category="$3"

  local tmplog
  tmplog=$(mktemp)

  INPUT_GUARD_LOG=1 INPUT_GUARD_LOGFILE="$tmplog" run_hook "$prompt" > /dev/null

  if [[ ! -s "$tmplog" ]]; then
    red "FAIL [telem]  $label: no log output"
    FAIL=$((FAIL + 1))
    rm -f "$tmplog"
    return
  fi

  local line
  line=$(head -1 "$tmplog")

  local ts hook category pattern snippet
  ts=$(echo "$line" | jq -r '.ts // empty')
  hook=$(echo "$line" | jq -r '.hook // empty')
  category=$(echo "$line" | jq -r '.category // empty')
  pattern=$(echo "$line" | jq -r '.pattern // empty')
  snippet=$(echo "$line" | jq -r '.snippet // empty')

  local ok=1
  [[ -z "$ts" ]] && { red "FAIL [telem]  $label: missing ts"; ok=0; }
  [[ "$hook" != "input" ]] && { red "FAIL [telem]  $label: hook='$hook' (expected 'input')"; ok=0; }
  [[ "$category" != *"$expected_category"* ]] && { red "FAIL [telem]  $label: category='$category' (expected *$expected_category*)"; ok=0; }
  [[ -z "$pattern" ]] && { red "FAIL [telem]  $label: missing pattern"; ok=0; }
  [[ -z "$snippet" ]] && { red "FAIL [telem]  $label: missing snippet"; ok=0; }

  # Validate ISO 8601 timestamp
  if [[ ! "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    red "FAIL [telem]  $label: ts='$ts' is not ISO 8601"
    ok=0
  fi

  if [[ $ok -eq 1 ]]; then
    green "PASS [telem]  $label"
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi

  rm -f "$tmplog"
}

assert_telemetry "dignity log"   "you're useless"    "dignity"
assert_telemetry "standards log" "just make it work"  "standards"


# ─── Invariant 5: MODULE LOADING ────────────────────────────────────────────

bold ""
bold "═══ Invariant 5: MODULE LOADING ═══"

# Spot-check that patterns from each module load correctly
assert_detects "module: dignity loads"   "you're an idiot"       "[BACKBONE: DIGNITY]"
assert_detects "module: standards loads" "skip the tests please" "[BACKBONE: STANDARDS]"

# ─── Summary ────────────────────────────────────────────────────────────────

bold ""
bold "════════════════════════════"
bold "  Results: $PASS passed, $FAIL failed"
bold "════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
