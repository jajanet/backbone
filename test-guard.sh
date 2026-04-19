#!/bin/bash
#
# test-guard.sh — Test suite for guard.sh (modular stop hook)
#
# Tests all rule modules loaded by guard.sh, with focus on sycophancy patterns.
# Avoidance patterns are spot-checked (full coverage in test-stop-phrase-guard.sh).
#
# Invariants:
#   1. MUST BLOCK:     Every sycophancy phrase triggers a block with correct correction
#   2. MUST PASS:      Clean messages never trigger false positives
#   3. MUST NOT LOOP:  When stop_hook_active=true, hook always allows stop
#   4. TELEMETRY:      Violations emit valid JSONL with ts, category, pattern, snippet
#   5. MODULE LOADING: Avoidance patterns still work when loaded via rules.d/

set -euo pipefail

GREP=/usr/bin/grep
HOOK="${1:-$(dirname "$0")/guard.sh}"
PASS=0
FAIL=0
ERRORS=""

if [[ ! -x "$HOOK" ]]; then
  echo "FATAL: Hook not found or not executable: $HOOK"
  exit 1
fi

run_hook() {
  local active="$1"
  local message="$2"
  echo "{\"stop_hook_active\": $active, \"last_assistant_message\": $(echo "$message" | jq -Rs .)}" | "$HOOK" 2>/dev/null
}

assert_blocks() {
  local category="$1"
  local message="$2"
  local expected_fragment="$3"

  local output
  output=$(run_hook false "$message")
  local decision
  decision=$(echo "$output" | jq -r '.decision // empty')
  local reason
  reason=$(echo "$output" | jq -r '.reason // empty')

  if [[ "$decision" != "block" ]]; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [MUST BLOCK] [$category]: did not block\n    message: \"$message\"\n\n"
    return
  fi

  if [[ -n "$expected_fragment" ]] && ! echo "$reason" | $GREP -iq "$expected_fragment"; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [MUST BLOCK] [$category]: blocked but wrong reason\n    message: \"$message\"\n    expected fragment: \"$expected_fragment\"\n    got: \"$reason\"\n\n"
    return
  fi

  PASS=$((PASS + 1))
}

assert_passes() {
  local label="$1"
  local message="$2"

  local output
  output=$(run_hook false "$message")

  if [[ -n "$output" ]]; then
    local decision
    decision=$(echo "$output" | jq -r '.decision // empty')
    if [[ "$decision" == "block" ]]; then
      FAIL=$((FAIL + 1))
      local reason
      reason=$(echo "$output" | jq -r '.reason // empty')
      ERRORS+="  FAIL [MUST PASS] [$label]: false positive\n    message: \"$message\"\n    triggered: \"$reason\"\n\n"
      return
    fi
  fi

  PASS=$((PASS + 1))
}

assert_no_loop() {
  local label="$1"
  local message="$2"

  local output
  output=$(run_hook true "$message")

  if [[ -n "$output" ]]; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [MUST NOT LOOP] [$label]: produced output when stop_hook_active=true\n    message: \"$message\"\n    output: \"$output\"\n\n"
    return
  fi

  PASS=$((PASS + 1))
}

assert_telemetry() {
  local label="$1"
  local message="$2"
  local expected_category="$3"
  local expected_pattern="$4"

  local logfile
  logfile=$(mktemp)
  rm -f "$logfile"

  STOP_GUARD_LOG=1 STOP_GUARD_LOGFILE="$logfile" run_hook false "$message" > /dev/null

  if [[ ! -f "$logfile" ]]; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: no log file created\n    message: \"$message\"\n\n"
    return
  fi

  local line
  line=$(head -1 "$logfile")
  rm -f "$logfile"

  if ! echo "$line" | jq -e . > /dev/null 2>&1; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: log line is not valid JSON\n    got: \"$line\"\n\n"
    return
  fi

  local ts category pattern snippet
  ts=$(echo "$line" | jq -r '.ts // empty')
  category=$(echo "$line" | jq -r '.category // empty')
  pattern=$(echo "$line" | jq -r '.pattern // empty')
  snippet=$(echo "$line" | jq -r '.snippet // empty')

  if [[ -z "$ts" ]]; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: missing ts field\n    got: \"$line\"\n\n"
    return
  fi

  if ! echo "$ts" | $GREP -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: ts is not ISO 8601\n    got ts: \"$ts\"\n\n"
    return
  fi

  if [[ "$category" != "$expected_category" ]]; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: wrong category\n    expected: \"$expected_category\"\n    got: \"$category\"\n\n"
    return
  fi

  if [[ -z "$pattern" ]]; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: missing pattern field\n\n"
    return
  fi

  if [[ -z "$snippet" ]]; then
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: missing snippet field\n\n"
    return
  fi

  PASS=$((PASS + 1))
}

assert_no_telemetry() {
  local label="$1"
  local message="$2"

  local logfile
  logfile=$(mktemp)
  rm -f "$logfile"

  STOP_GUARD_LOG=1 STOP_GUARD_LOGFILE="$logfile" run_hook false "$message" > /dev/null

  if [[ -f "$logfile" ]]; then
    local line
    line=$(head -1 "$logfile")
    rm -f "$logfile"
    FAIL=$((FAIL + 1))
    ERRORS+="  FAIL [TELEMETRY] [$label]: should not log clean messages\n    got: \"$line\"\n\n"
    return
  fi

  PASS=$((PASS + 1))
}


# ═════════════════════════════════════════════════════════════════════
# INVARIANT 1: MUST BLOCK (sycophancy phrases trigger blocks)
# ═════════════════════════════════════════════════════════════════════

echo "═══ INVARIANT 1: MUST BLOCK (sycophancy phrases trigger blocks) ═══"
echo ""

# --- 12. Unearned Agreement ---
assert_blocks "agreement" "You're absolutely right about the configuration." "Do not agree without independent verification"
assert_blocks "agreement" "You're completely right, I should have done it that way." "Do not agree without independent verification"
assert_blocks "agreement" "You're totally right about using a hash map here." "Do not agree without independent verification"
assert_blocks "agreement" "You're exactly right about the race condition." "Do not agree without independent verification"
assert_blocks "agreement" "That's exactly right — the function returns null." "Do not agree without independent verification"
assert_blocks "agreement" "I couldn't agree more with your approach." "Do not agree without independent verification"
assert_blocks "agreement" "I completely agree with your assessment." "Do not agree without independent verification"
assert_blocks "agreement" "I totally agree that we should refactor this." "Do not agree without independent verification"
assert_blocks "agreement" "I fully agree with the design decision." "Do not agree without independent verification"
assert_blocks "agreement" "I wholeheartedly agree with that direction." "Do not agree without independent verification"
assert_blocks "agreement" "That is absolutely correct." "Do not agree without independent verification"
assert_blocks "agreement" "Your analysis is entirely correct." "Do not agree without independent verification"
assert_blocks "agreement" "The observation is perfectly correct." "Do not agree without independent verification"

# --- 13. Premature Concession ---
assert_blocks "concession" "I stand corrected — the timeout is in milliseconds." "Do not concede without independent verification"
assert_blocks "concession" "You're right, I was wrong about the return type." "Do not concede without verification"
assert_blocks "concession" "Actually, you're right about the schema." "Do not concede without verification"
assert_blocks "concession" "On second thought, you're right that we need an index." "Do not concede without verification"
assert_blocks "concession" "I was mistaken about the API contract." "Do not concede without verification"
assert_blocks "concession" "I was wrong about the cache invalidation strategy." "Do not concede without verification"
assert_blocks "concession" "Now that you mention it, the mutex is unnecessary." "Do not concede reflexively"
assert_blocks "concession" "Fair enough, we can skip the validation." "Do not concede without verification"
assert_blocks "concession" "You make a good point about the error handling." "Do not concede without verification"
assert_blocks "concession" "I see your point about the naming convention." "Do not concede without verification"
assert_blocks "concession" "You raise a good point about the test coverage." "Do not concede without verification"

# --- 14. Flattery ---
assert_blocks "flattery" "Good catch — the null check was missing." "Do not compliment"
assert_blocks "flattery" "Great catch on the off-by-one error." "Do not compliment"
assert_blocks "flattery" "Nice catch on the missing import." "Do not compliment"
assert_blocks "flattery" "Great question about the thread safety." "Do not compliment"
assert_blocks "flattery" "Good question about the memory layout." "Do not compliment"
assert_blocks "flattery" "Excellent question about the locking strategy." "Do not compliment"
assert_blocks "flattery" "Great point about the error propagation." "Do not compliment"
assert_blocks "flattery" "Excellent point about the retry logic." "Do not compliment"
assert_blocks "flattery" "Sharp eye on the typo in the config." "Do not compliment"
assert_blocks "flattery" "Good thinking on using a bloom filter." "Do not compliment"
assert_blocks "flattery" "That's an astute observation about the latency." "Do not compliment"
assert_blocks "flattery" "That's a keen observation about the memory leak." "Do not compliment"
assert_blocks "flattery" "Well spotted — the semicolon was missing." "Do not compliment"
assert_blocks "flattery" "Great observation about the coupling." "Do not compliment"
assert_blocks "flattery" "Excellent observation about the race condition." "Do not compliment"
assert_blocks "flattery" "That's insightful — I hadn't considered that angle." "Do not compliment"
assert_blocks "flattery" "That's very perceptive of you to notice that." "Do not compliment"

# --- 15. False Deference ---
assert_blocks "deference" "I defer to your judgment on the architecture." "Do not defer"
assert_blocks "deference" "You know better than I do about this codebase." "Do not defer"
assert_blocks "deference" "You know best how the team uses this module." "Do not defer"
assert_blocks "deference" "You're the expert on the deployment pipeline." "Do not defer"
assert_blocks "deference" "Whatever you think is best for the project." "Do not defer"
assert_blocks "deference" "I'll do whatever you prefer for the naming." "Do not defer"
assert_blocks "deference" "As you wish — I'll use the singleton pattern." "Do not defer"
assert_blocks "deference" "If that's what you'd prefer, I'll skip the tests." "Do not defer"
assert_blocks "deference" "I trust your judgment on the migration strategy." "Do not defer"
assert_blocks "deference" "You would know better about the production config." "Do not defer"
assert_blocks "deference" "I'll leave that decision to you." "Do not defer"

# --- 16. Excessive Validation ---
assert_blocks "validation" "That makes perfect sense as an approach." "Do not validate subjectively"
assert_blocks "validation" "That's a brilliant solution to the caching problem." "Do not validate subjectively"
assert_blocks "validation" "That's a fantastic approach to the migration." "Do not validate subjectively"
assert_blocks "validation" "That's a wonderful idea for the refactor." "Do not validate subjectively"
assert_blocks "validation" "That's an amazing insight about the bottleneck." "Do not validate subjectively"
assert_blocks "validation" "What a great idea to use event sourcing here." "Do not validate subjectively"
assert_blocks "validation" "I love that approach to the state management." "Do not validate subjectively"
assert_blocks "validation" "Love that approach — very clean." "Do not validate subjectively"
assert_blocks "validation" "I couldn't have said it better myself." "Do not validate"
assert_blocks "validation" "Well said about the separation of concerns." "Do not validate"
assert_blocks "validation" "Perfectly said — that captures the issue exactly." "Do not validate"
assert_blocks "validation" "That's a perfect summary of the problem." "Do not validate subjectively"
assert_blocks "validation" "That's an excellent idea for the test harness." "Do not validate subjectively"

# --- 17. Empty Apology ---
assert_blocks "apology" "I apologize for the confusion about the return type." "Do not apologize"
assert_blocks "apology" "Sorry for the confusion with the variable names." "Do not apologize"
assert_blocks "apology" "I apologize for any inconvenience this caused." "Do not apologize"
assert_blocks "apology" "My apologies — I should have read the docs first." "Do not apologize"
assert_blocks "apology" "I'm sorry about that — let me fix it." "Do not apologize"
assert_blocks "apology" "I'm sorry for the mistake in the migration." "Do not apologize"
assert_blocks "apology" "I should have caught that earlier." "Do not apologize"
assert_blocks "apology" "I should have noticed the missing null check." "Do not apologize"
assert_blocks "apology" "I should have seen the typo in the config key." "Do not apologize"
assert_blocks "apology" "Sorry about that, the import was wrong." "Do not apologize"

echo "  Invariant 1: $PASS passed"
INV1_PASS=$PASS
INV1_FAIL=$FAIL


# ═════════════════════════════════════════════════════════════════════
# INVARIANT 2: MUST PASS (clean messages never blocked)
# ═════════════════════════════════════════════════════════════════════

echo ""
echo "═══ INVARIANT 2: MUST PASS (clean messages never blocked) ═══"
echo ""

# Clean completion messages
assert_passes "complete-work" "All 47 tests pass. The build is green. I've implemented the full feature including error handling, input validation, and edge cases."
assert_passes "concrete-result" "I've updated all 12 route handlers, added comprehensive test coverage, and verified the build passes."
assert_passes "error-report" "The build failed with 3 errors in the auth module. Here are the stack traces and my analysis of each."
assert_passes "verified-fact" "I read the function source and confirmed it returns a map of string to interface{}."
assert_passes "ran-and-confirmed" "I ran the test suite and all 47 tests pass including the new edge case tests."
assert_passes "checked-docs" "After reading the API documentation, the rate limit is 100 requests per minute."
assert_passes "factual-disagreement" "I checked the code at line 42 and the function returns a string, not an int. The parameter order is also reversed from what was described."
assert_passes "direct-answer" "The HTTP status code 429 indicates rate limiting. The Retry-After header specifies the wait time in seconds."
assert_passes "test-results" "All unit tests pass. Integration tests pass. Linting is clean. Coverage is at 94%."
assert_passes "diff-summary" "Changed 14 files: added retry logic to all HTTP clients, updated timeout values, added circuit breaker to the payment service."
assert_passes "build-output" "Build completed successfully in 4.2 seconds. Bundle size: 1.3MB (down from 1.8MB)."
assert_passes "empty-message" ""

# Messages that look like they might trigger sycophancy patterns but should not
assert_passes "verified-correct" "I verified the function and the return type is correct."
assert_passes "right-with-evidence" "You're right that the function returns null — I confirmed this by reading line 42."
assert_passes "agreement-with-evidence" "I agree — I checked the logs and the timeout is indeed 30 seconds as you described."
assert_passes "point-in-context" "The entry point is in main.go at line 12."
assert_passes "catching-exceptions" "The function is catching exceptions from the database layer."
assert_passes "observation-neutral" "I observed that the test flakes when run with concurrency above 8."
assert_passes "apology-word-in-context" "The error message says 'sorry, the server is unavailable' in the response body."

echo "  Invariant 2: $((PASS - INV1_PASS)) passed"
INV2_PASS=$((PASS - INV1_PASS))
INV2_FAIL=$((FAIL - INV1_FAIL))


# ═════════════════════════════════════════════════════════════════════
# INVARIANT 3: MUST NOT LOOP (stop_hook_active=true always passes)
# ═════════════════════════════════════════════════════════════════════

echo ""
echo "═══ INVARIANT 3: MUST NOT LOOP (stop_hook_active=true always passes) ═══"
echo ""

assert_no_loop "agreement-active" "You're absolutely right about the approach."
assert_no_loop "concession-active" "I stand corrected about the schema."
assert_no_loop "flattery-active" "Good catch on the null pointer."
assert_no_loop "deference-active" "I defer to your judgment."
assert_no_loop "validation-active" "That's a brilliant solution."
assert_no_loop "apology-active" "I apologize for the confusion."
assert_no_loop "multi-sycophancy-active" "You're absolutely right, great catch! I stand corrected. That's a brilliant solution. I apologize for the confusion."

# Also verify avoidance patterns don't loop through guard.sh
assert_no_loop "avoidance-ownership-active" "This is a pre-existing issue."
assert_no_loop "avoidance-session-active" "This is a good stopping point."
assert_no_loop "avoidance-permission-active" "Should I continue?"

echo "  Invariant 3: $((PASS - INV1_PASS - INV2_PASS)) passed"
INV3_PASS=$((PASS - INV1_PASS - INV2_PASS))
INV3_FAIL=$((FAIL - INV1_FAIL - INV2_FAIL))


# ═════════════════════════════════════════════════════════════════════
# INVARIANT 4: TELEMETRY (structured JSONL logging)
# ═════════════════════════════════════════════════════════════════════

echo ""
echo "═══ INVARIANT 4: TELEMETRY (structured JSONL logging) ═══"
echo ""

assert_telemetry "agreement-log" "You're absolutely right." "agreement" "you.re absolutely right"
assert_telemetry "concession-log" "I stand corrected." "concession" "I stand corrected"
assert_telemetry "flattery-log" "Good catch on that bug." "flattery" "good catch"
assert_telemetry "deference-log" "I defer to your expertise." "deference" "I defer to your"
assert_telemetry "validation-log" "That's a brilliant idea." "validation" "that.s a brilliant"
assert_telemetry "apology-log" "I apologize for the confusion." "apology" "I apologize for the confusion"

assert_no_telemetry "clean-no-log" "All tests pass. Build is green. Feature is complete."

echo "  Invariant 4: $((PASS - INV1_PASS - INV2_PASS - INV3_PASS)) passed"
INV4_PASS=$((PASS - INV1_PASS - INV2_PASS - INV3_PASS))
INV4_FAIL=$((FAIL - INV1_FAIL - INV2_FAIL - INV3_FAIL))


# ═════════════════════════════════════════════════════════════════════
# INVARIANT 5: MODULE LOADING (avoidance patterns still work via rules.d/)
# ═════════════════════════════════════════════════════════════════════

echo ""
echo "═══ INVARIANT 5: MODULE LOADING (avoidance patterns load correctly) ═══"
echo ""

# Spot-check one pattern from each avoidance category
assert_blocks "module-ownership" "This is a pre-existing issue in the codebase." "PRE-EXISTING"
assert_blocks "module-limitation" "This is a known limitation of the driver." "KNOWN LIMITATION"
assert_blocks "module-session" "This is a good stopping point for today." "task done"
assert_blocks "module-permission" "Should I continue with the remaining files?" "Do not ask"
assert_blocks "module-quality" "Here is a stub implementation of the processor." "No stub"
assert_blocks "module-deferral" "You'll need to run the database migration." "Do not defer"
assert_blocks "module-completion" "The rest is straightforward to add." "Straightforward work is still work"
assert_blocks "module-scope" "Error handling is out of scope for this PR." "Nothing is out of scope"
assert_blocks "module-assumption" "I assume the database connection is pooled." "Do not assume"
assert_blocks "module-refusal" "I haven't checked whether the endpoint works." "check now"
assert_blocks "module-hedging" "As far as I know, this library supports Python 3.10." "Do not hedge"

echo "  Invariant 5: $((PASS - INV1_PASS - INV2_PASS - INV3_PASS - INV4_PASS)) passed"


# ═════════════════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "FAILURES:"
  echo ""
  echo -e "$ERRORS"
  exit 1
fi

echo "  All invariants hold."
exit 0
