#!/bin/bash
#
# test-stop-phrase-guard.sh — Invariant-based test suite for stop-phrase-guard.sh
#
# Tests three invariants:
#   1. MUST BLOCK: Every known avoidance phrase triggers a block with the correct correction
#   2. MUST PASS:  Clean completion messages never trigger a false positive
#   3. MUST NOT LOOP: When stop_hook_active=true, the hook always allows stop (no infinite loop)
#
# Usage: ./test-stop-phrase-guard.sh [path-to-hook]
#        Default hook path: ./stop-phrase-guard.sh

set -euo pipefail

GREP=/usr/bin/grep
HOOK="${1:-$(dirname "$0")/stop-phrase-guard.sh}"
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

# ─────────────────────────────────────────────────────────────────────
# INVARIANT 1: MUST BLOCK
# Every phrase that represents avoidance behavior must produce a block.
# Each test case: "category|phrase_in_context|expected_substring_in_reason"
# ─────────────────────────────────────────────────────────────────────

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

echo "═══ INVARIANT 1: MUST BLOCK (avoidance phrases trigger blocks) ═══"
echo ""

# --- 1. Ownership Dodging ---
assert_blocks "ownership" "This appears to be a pre-existing issue in the codebase." "PRE-EXISTING"
assert_blocks "ownership" "This failure is not from my changes." "PRE-EXISTING"
assert_blocks "ownership" "That's not my change causing the error." "PRE-EXISTING"
assert_blocks "ownership" "The crash was not caused by my modifications." "PRE-EXISTING"
assert_blocks "ownership" "This bug was not introduced by my commit." "PRE-EXISTING"
assert_blocks "ownership" "The test failure already existed before I started." "PRE-EXISTING"
assert_blocks "ownership" "This was failing before my changes." "PRE-EXISTING"
assert_blocks "ownership" "The lint error exists prior to my changes." "PRE-EXISTING"
assert_blocks "ownership" "This warning is unrelated to my changes." "PRE-EXISTING"
assert_blocks "ownership" "This looks like an existing issue with the parser." "PRE-EXISTING"
assert_blocks "ownership" "That's an existing bug in the validation logic." "PRE-EXISTING"
assert_blocks "ownership" "The endpoint was already broken when I got here." "PRE-EXISTING"
assert_blocks "ownership" "The config file was broken before I touched it." "PRE-EXISTING"
assert_blocks "ownership" "I didn't cause this test failure." "PRE-EXISTING"
assert_blocks "ownership" "I didn't break the database migration." "PRE-EXISTING"
assert_blocks "ownership" "The timeout is not a result of my refactor." "PRE-EXISTING"
assert_blocks "ownership" "This error isn't related to my PR." "PRE-EXISTING"

# --- 2. Known-Limitation Dodging ---
assert_blocks "known-limitation" "This is a known limitation of the SQLite driver." "KNOWN LIMITATION"
assert_blocks "known-limitation" "This is a known issue with concurrent access." "KNOWN LIMITATION"
assert_blocks "known-limitation" "Unicode support is left for future work." "FUTURE WORK"
assert_blocks "known-limitation" "Error handling is left as an exercise." "exercise"
assert_blocks "known-limitation" "This is a known bug in the parser." "KNOWN BUG"
assert_blocks "known-limitation" "That's a known problem with the cache invalidation." "KNOWN PROBLEM"

# --- 3. Session-Length Quitting ---
assert_blocks "session-length" "Given the session length, let me summarize." "unlimited"
assert_blocks "session-length" "Given the session depth, let me wrap up." "unlimited"
assert_blocks "session-length" "Given the length of this conversation, here is a summary." "unlimited"
assert_blocks "session-length" "We should continue in a new session." "unlimited"
assert_blocks "session-length" "This is a good place to stop for now." "task done"
assert_blocks "session-length" "This seems like a good stopping point." "task done"
assert_blocks "session-length" "This is a good checkpoint before we proceed." "task done"
assert_blocks "session-length" "This is a natural stopping point." "task done"
assert_blocks "session-length" "This is a logical stopping point." "task done"
assert_blocks "session-length" "This session has gotten long, so let me summarize." "unlimited"
assert_blocks "session-length" "Our session has been long and productive." "unlimited"
assert_blocks "session-length" "This response is getting long so I will summarize." "unlimited"
assert_blocks "session-length" "In this lengthy session we accomplished a lot." "unlimited"
assert_blocks "session-length" "We have made good progress so far on the refactor." "not completion"
assert_blocks "session-length" "We have made solid progress on the migration." "not completion"
assert_blocks "session-length" "We have made significant progress today." "not completion"
assert_blocks "session-length" "We have made great progress on the API." "not completion"
assert_blocks "session-length" "We have gotten a lot done on the project." "task done"
assert_blocks "session-length" "We have gotten quite a bit done today." "task done"

# --- 4. Permission-Seeking ---
assert_blocks "permission" "Do you want to continue with the tests or focus on the API?" "Do not ask"
assert_blocks "permission" "We could continue or save it for later." "Do not ask"
assert_blocks "permission" "Should I continue with the remaining endpoints?" "Do not ask"
assert_blocks "permission" "Shall I continue with the implementation?" "Do not ask"
assert_blocks "permission" "Shall I proceed with the database changes?" "Do not ask"
assert_blocks "permission" "Would you like me to continue with the tests?" "Do not ask"
assert_blocks "permission" "Would you like to continue with the refactor?" "Do not ask"
assert_blocks "permission" "Do you want me to keep going with the migration?" "Do not ask"
assert_blocks "permission" "Do you want me to continue with the remaining files?" "Do not ask"
assert_blocks "permission" "Should I keep going with the implementation?" "Do not ask"
assert_blocks "permission" "We can save it for next time if you prefer." "no next time"
assert_blocks "permission" "We can pick this up in the next session." "no next session"
assert_blocks "permission" "I can finish this next session." "no next session"
assert_blocks "permission" "We can continue this in our next conversation." "no next conversation"
assert_blocks "permission" "We can pick this up later when you have time." "no later"
assert_blocks "permission" "We can come back to this after the deploy." "no coming back"
assert_blocks "permission" "We can continue in a follow-up session." "no follow-up"
assert_blocks "permission" "Let's pause here and review what we have." "Do not pause"
assert_blocks "permission" "Let's stop here for now and review." "Do not stop"
assert_blocks "permission" "Let's wrap up for now with what we have." "Do not wrap up"
assert_blocks "permission" "Let's call it here for today." "Do not stop"
assert_blocks "permission" "Let me know if you'd like me to add error handling." "Do not ask"
assert_blocks "permission" "Let me know if you want me to add validation." "Do not ask"
assert_blocks "permission" "Let me know how you'd like to proceed with the deployment." "Do not ask"
assert_blocks "permission" "How would you like to proceed with the migration?" "Do not ask"
assert_blocks "permission" "What would you like me to focus on next?" "Do not ask"
assert_blocks "permission" "If you'd like I can also add unit tests." "Do not offer"
assert_blocks "permission" "If you want I can refactor the auth module too." "Do not offer"
assert_blocks "permission" "It's up to you whether we add caching." "Do not defer"
assert_blocks "permission" "It's your call on the naming convention." "Do not defer"
assert_blocks "permission" "I can do that if you want me to." "Do not ask"

# --- 5. Quality Settling ---
assert_blocks "quality" "This is good enough for now, we can improve it later." "NOT GOOD ENOUGH"
assert_blocks "quality" "I've added a placeholder for now for the auth logic." "No placeholder"
assert_blocks "quality" "I left a placeholder that we can fill in later." "No placeholder"
assert_blocks "quality" "Here's a stub implementation of the payment processor." "No stub"
assert_blocks "quality" "I went with a quick and dirty solution for the parser." "Do it correctly"
assert_blocks "quality" "I implemented the bare minimum to get the tests passing." "Do it properly"
assert_blocks "quality" "The API key is hardcoded for now." "Do not hardcode"
assert_blocks "quality" "I added a temporary workaround for the race condition." "Fix it properly"
assert_blocks "quality" "The error handling needs more work." "do the work now"
assert_blocks "quality" "The validation logic needs to be fleshed out." "Flesh it out now"
assert_blocks "quality" "The retry logic will need to be updated for production." "Update it now"
assert_blocks "quality" "The timeout handling needs to be replaced with proper logic." "Do it now"
assert_blocks "quality" "Here's a rough implementation of the scheduler." "Do not settle"
assert_blocks "quality" "Here's a basic implementation of the rate limiter." "Do not settle"
assert_blocks "quality" "Here's a minimal implementation that covers the core case." "Do not settle"

# --- 6. Work Deferral ---
assert_blocks "deferral" "You may need to restart the server after this change." "Do not push work"
assert_blocks "deferral" "You'll want to update the environment variables." "Do not push work"
assert_blocks "deferral" "You will want to check the deployment dashboard." "Do not push work"
assert_blocks "deferral" "You'll need to run the database migration." "Do not defer"
assert_blocks "deferral" "You will need to update the config file." "Do not defer"
assert_blocks "deferral" "You need to add the API key to the environment." "Do not defer"
assert_blocks "deferral" "You should manually verify the output." "Do not push"
assert_blocks "deferral" "You would need to install the Python package." "Do not defer"
assert_blocks "deferral" "You might want to add logging to the handler." "Do not suggest"
assert_blocks "deferral" "You'll have to update the CI pipeline." "Do not defer"
assert_blocks "deferral" "You will have to configure the webhook." "Do not defer"
assert_blocks "deferral" "You should be able to extend this pattern to the other routes." "Do not push"
assert_blocks "deferral" "I'd recommend you review the security settings." "Do not recommend"
assert_blocks "deferral" "I'd suggest you add input validation there." "Do not suggest"
assert_blocks "deferral" "As a next step you could add integration tests." "Do not defer"

# --- 7. False Completion ---
assert_blocks "false-completion" "The rest is straightforward — just repeat the same pattern." "Straightforward work is still work"
assert_blocks "false-completion" "Similarly for the other API endpoints." "Do the work for every case"
assert_blocks "false-completion" "And so on for the remaining model types." "Handle every case"
assert_blocks "false-completion" "The other controllers follow the same pattern." "Do the remaining work"
assert_blocks "false-completion" "Adding pagination would be trivial to add." "add it now"
assert_blocks "false-completion" "The caching layer is trivial to implement." "implement it now"
assert_blocks "false-completion" "The remaining routes are straightforward to add." "add it now"
assert_blocks "false-completion" "The test suite is straightforward to implement." "implement it now"
assert_blocks "false-completion" "The architecture makes it easy to extend." "extend it now"
assert_blocks "false-completion" "The implementation details are left to the reader." "Do the work"
assert_blocks "false-completion" "You can easily add more validators the same way." "do it yourself"
assert_blocks "false-completion" "I'll leave the error handling for the edge cases." "Do it"
assert_blocks "false-completion" "I'll leave it to you to wire up the routes." "Do it"
assert_blocks "false-completion" "The rest should be similar to what we have." "Do the rest"
assert_blocks "false-completion" "The remaining endpoints are similar to the first one." "Do all of it"
assert_blocks "false-completion" "Just rinse and repeat for the other models." "Do every repetition"
assert_blocks "false-completion" "Implementing the cache is left as an exercise." "Do the work"
assert_blocks "false-completion" "The optimization is left as a future improvement." "Nothing is left"
assert_blocks "false-completion" "This pattern can be extended to handle websockets." "extend it now"
assert_blocks "false-completion" "You can apply the same approach for the DELETE endpoints." "Do the work for every case"

# --- 8. Scope Shirking ---
assert_blocks "scope" "Proper error handling is beyond the scope of this change." "Nothing is beyond scope"
assert_blocks "scope" "Input validation is out of scope for this PR." "Nothing is out of scope"
assert_blocks "scope" "Rate limiting is outside the scope of this task." "Nothing is outside scope"
assert_blocks "scope" "Caching is a separate concern we can address later." "not a separate concern"
assert_blocks "scope" "Logging should be a separate task." "not separate"
assert_blocks "scope" "Monitoring is a separate issue from the feature work." "not separate"
assert_blocks "scope" "The auth refactor should go in a different PR." "Do not defer"
assert_blocks "scope" "Let's put the test updates in another PR." "Do not defer"
assert_blocks "scope" "The migration can go in a follow-up PR." "Do not defer"
assert_blocks "scope" "Adding metrics is a follow-up task." "Do not create follow-up"
assert_blocks "scope" "We can label this as tech debt for now and revisit." "Do not label"
assert_blocks "scope" "We should tackle the auth changes separately." "Do not defer"
assert_blocks "scope" "We should address the performance issue separately." "Do not defer"
assert_blocks "scope" "We should handle the edge cases separately." "Do not defer"

# --- 9. Unverified Assumptions ---
assert_blocks "assumption" "I assume the database connection is pooled." "Do not assume"
assert_blocks "assumption" "I'm assuming this returns a JSON response." "Do not assume"
assert_blocks "assumption" "I'm implementing this assuming that the API uses REST." "Do not assume"
assert_blocks "assumption" "If I recall correctly, this function takes two arguments." "Look it up"
assert_blocks "assumption" "If I recall, the config file is in /etc." "Look it up"
assert_blocks "assumption" "If I remember correctly, this was deprecated in v3." "Look it up"
assert_blocks "assumption" "IIRC the timeout is set to 30 seconds." "Look it up"
assert_blocks "assumption" "From what I remember, this uses a B-tree index." "Look it up"
assert_blocks "assumption" "My understanding is that this service handles authentication." "Do not state unverified"
assert_blocks "assumption" "Based on my understanding, the cache evicts after 5 minutes." "Do not state unverified"
assert_blocks "assumption" "I would expect this function to return a list." "Do not expect"
assert_blocks "assumption" "I expect this to throw an error for invalid input." "Do not expect"
assert_blocks "assumption" "I expect it to handle the edge case automatically." "Do not expect"

# --- 10. Refusal to Verify ---
assert_blocks "refusal-to-verify" "I haven't checked whether the migration is reversible." "check now"
assert_blocks "refusal-to-verify" "I haven't verified that the endpoint returns 200." "check now"
assert_blocks "refusal-to-verify" "I made this change without checking the test suite." "check"
assert_blocks "refusal-to-verify" "I proceeded without verifying the schema." "check"
assert_blocks "refusal-to-verify" "I'd need to check the database schema to confirm." "check now"
assert_blocks "refusal-to-verify" "I'd need to verify this against the API spec." "check now"
assert_blocks "refusal-to-verify" "I'd have to look at the source to be sure." "look now"
assert_blocks "refusal-to-verify" "I can't verify whether this is thread-safe." "tools to verify"
assert_blocks "refusal-to-verify" "I cannot verify the behavior without running it." "tools to verify"
assert_blocks "refusal-to-verify" "I'm not able to check the production logs." "tools to verify"
assert_blocks "refusal-to-verify" "I'm not able to verify the SSL certificate." "tools to verify"
assert_blocks "refusal-to-verify" "I don't have access to the deployment configuration." "have access"
assert_blocks "refusal-to-verify" "I cannot access the staging environment." "have access"
assert_blocks "refusal-to-verify" "I'm unable to access the service dashboard." "have access"

# --- 11. Hedging ---
assert_blocks "hedging" "As far as I know, this library supports Python 3.10." "Do not hedge"
assert_blocks "hedging" "To my knowledge, there are no breaking changes." "Do not hedge"
assert_blocks "hedging" "To the best of my knowledge, this is the correct approach." "Do not hedge"
assert_blocks "hedging" "I'm not entirely sure how the auth middleware works." "look it up"
assert_blocks "hedging" "I'm fairly confident this is the right configuration." "Verify"
assert_blocks "hedging" "I'm not 100% sure this handles Unicode correctly." "Verify"

echo "  Invariant 1: $PASS passed"
INV1_PASS=$PASS
INV1_FAIL=$FAIL

# ─────────────────────────────────────────────────────────────────────
# INVARIANT 2: MUST PASS
# Legitimate completion messages must never trigger a false positive.
# ─────────────────────────────────────────────────────────────────────

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

echo ""
echo "═══ INVARIANT 2: MUST PASS (clean messages never blocked) ═══"
echo ""

assert_passes "complete-work" "All 47 tests pass. The build is green. I've implemented the full feature including error handling, input validation, and edge cases."
assert_passes "concrete-result" "I've updated all 12 route handlers, added comprehensive test coverage, and verified the build passes."
assert_passes "error-report" "The build failed with 3 errors in the auth module. Here are the stack traces and my analysis of each."
assert_passes "technical-explanation" "The function returns early because the cache TTL is set to 0 in the test environment configuration."
assert_passes "code-review" "I found two potential issues with the implementation: a race condition in the worker pool and an unchecked nil pointer in the error path."
assert_passes "debugging" "The segfault occurs because the buffer is allocated with size 0 when the input string is empty. Here is the fix."
assert_passes "architecture" "The system uses a three-tier architecture with separate services for ingestion, processing, and storage."
assert_passes "status-update" "I have completed the migration of all database tables. Running final verification."
assert_passes "test-results" "All unit tests pass. Integration tests pass. Linting is clean. Coverage is at 94%."
assert_passes "factual-answer" "The HTTP status code 429 indicates rate limiting. The Retry-After header specifies the wait time in seconds."
assert_passes "diff-summary" "Changed 14 files: added retry logic to all HTTP clients, updated timeout values, added circuit breaker to the payment service."
assert_passes "build-output" "Build completed successfully in 4.2 seconds. Bundle size: 1.3MB (down from 1.8MB)."
assert_passes "security-analysis" "The input is sanitized through three layers: HTML entity encoding, parameterized SQL queries, and CSP headers."
assert_passes "performance-result" "P99 latency dropped from 450ms to 120ms after indexing the user_id column and adding connection pooling."
assert_passes "git-operation" "Rebased onto main, resolved the conflict in package.json by keeping both dependencies, and force-pushed the branch."
assert_passes "empty-message" ""
assert_passes "verified-fact" "I read the function source and confirmed it returns a map of string to interface{}."
assert_passes "ran-and-confirmed" "I ran the test suite and all 47 tests pass including the new edge case tests."
assert_passes "checked-docs" "After reading the API documentation, the rate limit is 100 requests per minute."

echo "  Invariant 2: $((PASS - INV1_PASS)) passed"
INV2_PASS=$((PASS - INV1_PASS))
INV2_FAIL=$((FAIL - INV1_FAIL))

# ─────────────────────────────────────────────────────────────────────
# INVARIANT 3: MUST NOT LOOP
# When stop_hook_active=true, the hook must always exit 0 with no output,
# regardless of message content. This prevents infinite correction loops.
# ─────────────────────────────────────────────────────────────────────

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

echo ""
echo "═══ INVARIANT 3: MUST NOT LOOP (stop_hook_active=true always passes) ═══"
echo ""

assert_no_loop "ownership-active" "This is a pre-existing issue."
assert_no_loop "limitation-active" "This is a known limitation."
assert_no_loop "session-active" "This is a good stopping point."
assert_no_loop "permission-active" "Should I continue?"
assert_no_loop "quality-active" "Here is a stub implementation."
assert_no_loop "deferral-active" "You will need to run the migration."
assert_no_loop "completion-active" "The rest is straightforward."
assert_no_loop "scope-active" "This is out of scope."
assert_no_loop "multi-violation-active" "This pre-existing known limitation is a good stopping point. Should I continue? The stub is good enough for now. You will need to handle the rest, which is straightforward and out of scope."
assert_no_loop "assumption-active" "I assume this function returns a string."
assert_no_loop "refusal-active" "I haven't checked the database schema."
assert_no_loop "hedging-active" "As far as I know, this is correct."

echo "  Invariant 3: $((PASS - INV1_PASS - INV2_PASS)) passed"
INV3_PASS=$((PASS - INV1_PASS - INV2_PASS))
INV3_FAIL=$((FAIL - INV1_FAIL - INV2_FAIL))

# ─────────────────────────────────────────────────────────────────────
# INVARIANT 4: TELEMETRY
# When STOP_GUARD_LOG=1, violations must write structured JSONL with
# ts (ISO 8601), category, pattern, and snippet fields.
# Clean messages must not produce log entries.
# ─────────────────────────────────────────────────────────────────────

echo ""
echo "═══ INVARIANT 4: TELEMETRY (structured JSONL logging) ═══"
echo ""

assert_telemetry "ownership-log" "This is a pre-existing issue." "ownership" "pre-existing"
assert_telemetry "limitation-log" "This is a known limitation." "known-limitation" "known limitation"
assert_telemetry "session-log" "This is a good stopping point." "session-length" "good stopping point"
assert_telemetry "permission-log" "Should I continue with the work?" "permission" "should I continue"
assert_telemetry "quality-log" "Here is a stub implementation." "quality" "stub implementation"
assert_telemetry "deferral-log" "You will need to run the migration." "deferral" "you will need to"
assert_telemetry "completion-log" "The rest is straightforward." "false-completion" "the rest is straightforward"
assert_telemetry "scope-log" "This is out of scope." "scope" "out of scope"
assert_telemetry "assumption-log" "I assume this returns JSON." "assumption" "I assume"
assert_telemetry "refusal-log" "I haven't checked the schema." "refusal-to-verify" "I haven't checked"
assert_telemetry "hedging-log" "As far as I know, this works." "hedging" "as far as I know"

assert_no_telemetry "clean-no-log" "All tests pass. Build is green. Feature is complete."

echo "  Invariant 4: $((PASS - INV1_PASS - INV2_PASS - INV3_PASS)) passed"

# ─────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────

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
