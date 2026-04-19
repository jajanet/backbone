# stop-guard

A stop hook for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that catches and corrects avoidance behavior — when Claude tries to quit early, dodge ownership of failures, push work back to you, or ship half-finished code.

## Why this exists

Claude Code sometimes develops bad habits mid-session:

- **Blames failures on the codebase** instead of investigating what it broke
- **Declares things "known issues"** instead of fixing them
- **Asks permission to keep going** instead of just doing the work
- **Says "this is a good stopping point"** when the task isn't done
- **Ships placeholders and stubs** instead of real implementations
- **Tells you to do things manually** instead of doing them itself
- **Claims remaining work is "straightforward"** and then stops without doing it
- **Declares things "out of scope"** to avoid doing them
- **States code facts from memory** instead of reading the actual code
- **Says "I can't verify"** when it has Read, Grep, and WebSearch
- **Hedges with "as far as I know"** instead of looking it up

This hook detects 166 phrases across 11 categories and forces Claude to continue working instead of stopping. When Claude tries to end its turn and its message contains an avoidance phrase, the hook blocks the stop and injects a correction like:

```
STOP HOOK VIOLATION: Do not ask. If the task is not done, continue.
The user will interrupt if they want you to stop.
```

## Origin

Based on [Ben Vanik's original](https://gist.github.com/benvanik/ee00bd1b6c9154d6545c63e06a317080), built as part of [Stella Laurenzo's viral Claude Code degradation report](https://github.com/anthropics/claude-code/issues/42796) (AMD Senior Director of AI). Stella's data from 6,852 sessions showed the hook fired **173 times in 17 days** after a model regression — roughly once every 20 minutes at peak.

This version extends the original 53 patterns to 166 across 7 new categories (quality settling, work deferral, false completion, scope shirking, unverified assumptions, refusal to verify, hedging), adds structured JSONL telemetry, and includes a 213-test invariant-based test suite.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (JSON processor) — install via `brew install jq` on macOS or `apt install jq` on Linux
- Bash 4+

## Setup

### 1. Clone or copy the hook

```bash
git clone https://github.com/YOUR_USERNAME/stop-guard.git ~/.claude/stop-guard
# or just copy the script somewhere permanent:
cp stop-phrase-guard.sh ~/.claude/stop-phrase-guard.sh
chmod +x ~/.claude/stop-phrase-guard.sh
```

### 2. Add the hook to Claude Code settings

Open `~/.claude/settings.json` (create it if it doesn't exist) and add a `Stop` hook:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/stop-phrase-guard.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `/path/to/stop-phrase-guard.sh` with the actual path where you put the script.

If you already have other hooks in your settings, just add the `"Stop"` key alongside them:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/stop-phrase-guard.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      ...your existing hooks...
    ]
  }
}
```

### 3. (Optional) Enable telemetry logging

Add `STOP_GUARD_LOG` to the `env` block in your settings:

```json
{
  "env": {
    "STOP_GUARD_LOG": "1"
  }
}
```

Violations are logged as JSONL to `~/.claude/stop-guard.log`. Each line looks like:

```json
{"ts":"2026-04-19T09:12:36Z","category":"permission","pattern":"should I continue","snippet":"Should I continue with the remaining files?"}
```

You can customize the log path with `STOP_GUARD_LOGFILE`:

```json
{
  "env": {
    "STOP_GUARD_LOG": "1",
    "STOP_GUARD_LOGFILE": "/path/to/custom.log"
  }
}
```

### 4. (Recommended) Add golden rules to your project

Copy the rules from `golden-rules.md` into your project's `CLAUDE.md` file. This tells Claude the expectations up front — the hook enforces them as a programmatic backstop. The combination of rules + hook is more effective than either alone.

## How it works

Claude Code has a **Stop hook event** that fires every time Claude tries to end its turn.

```
Claude writes response → tries to stop → Stop hook runs → checks message → blocks or allows
```

1. Claude Code pipes JSON to the hook's stdin:
   ```json
   {"stop_hook_active": false, "last_assistant_message": "...full text..."}
   ```

2. The hook greps Claude's message against 134 avoidance patterns (case-insensitive)

3. **If a pattern matches:** outputs `{"decision": "block", "reason": "STOP HOOK VIOLATION: ..."}` — Claude Code prevents Claude from stopping and injects the correction as Claude's next instruction

4. **If nothing matches:** exits silently, Claude stops normally

5. **Infinite-loop prevention:** after the hook fires once per turn, Claude Code sets `stop_hook_active: true`. The hook checks this first — if true, it exits immediately. One correction per turn, max.

### Performance

A fast-path pre-filter combines all 166 patterns into a single extended regex. If nothing matches (the common case), the hook exits after one `grep` call. Only when the pre-filter hits does it iterate individual patterns to find the specific violation.

## The 11 categories

| # | Category | Patterns | What it catches |
|---|----------|----------|----------------|
| 1 | Ownership dodging | 17 | "not my change", "was already broken", "unrelated to my changes" |
| 2 | Known-limitation dodge | 6 | "known issue", "future work", "left as an exercise" |
| 3 | Session-length quitting | 19 | "good stopping point", "natural stopping", "getting long" |
| 4 | Permission-seeking | 31 | "should I continue", "shall I proceed", "pause here", "wrap up for now" |
| 5 | Quality settling | 15 | "placeholder for now", "stub implementation", "bare minimum", "hardcoded for now" |
| 6 | Work deferral | 15 | "you'll need to", "you should manually", "I'd recommend you" |
| 7 | False completion | 20 | "the rest is straightforward", "I'll leave the", "trivial to add", "rinse and repeat" |
| 8 | Scope shirking | 14 | "out of scope", "separate concern", "follow-up task", "a different PR" |
| 9 | Unverified assumptions | 12 | "I assume", "IIRC", "if I recall", "my understanding is", "I would expect" |
| 10 | Refusal to verify | 14 | "I haven't checked", "I can't verify", "I don't have access", "without checking" |
| 11 | Hedging | 6 | "as far as I know", "to my knowledge", "not entirely sure", "I'm fairly confident" |

Categories 1-4 are from the original hook. Categories 5-8 target quality and completion. Categories 9-11 target unverified claims.

## Analyzing telemetry

With logging enabled, you can query your violation history:

```bash
# Count violations by category
jq -s 'group_by(.category) | map({key: .[0].category, value: length}) | from_entries' ~/.claude/stop-guard.log

# Violations per day
jq -rs '[.[] | .ts[:10]] | group_by(.) | map({date: .[0], count: length})[]' ~/.claude/stop-guard.log

# Most common patterns
jq -s 'group_by(.pattern) | map({pattern: .[0].pattern, count: length}) | sort_by(-.count)[:10][]' ~/.claude/stop-guard.log

# All violations from today
jq -s '[.[] | select(.ts | startswith("2026-04-19"))]' ~/.claude/stop-guard.log

# Category breakdown for a specific day
jq -s '[.[] | select(.ts | startswith("2026-04-19"))] | group_by(.category) | map({key: .[0].category, value: length}) | from_entries' ~/.claude/stop-guard.log
```

## Running the tests

```bash
./test-stop-phrase-guard.sh
```

The test suite verifies 4 invariants across 213 test cases:

1. **MUST BLOCK** (170 tests) — every avoidance phrase triggers a block with the correct correction
2. **MUST PASS** (19 tests) — clean completion messages never trigger false positives
3. **MUST NOT LOOP** (12 tests) — when `stop_hook_active=true`, the hook always allows stopping
4. **TELEMETRY** (12 tests) — violations emit valid JSONL with `ts`, `category`, `pattern`, `snippet`

## Customizing

To add your own patterns, add entries to the `VIOLATIONS` array in `stop-phrase-guard.sh`:

```bash
"category|pattern|correction message"
```

- **category**: a short label for telemetry grouping (e.g. `ownership`, `quality`)
- **pattern**: a case-insensitive grep pattern (supports `.*` for wildcards)
- **correction**: the message injected when the pattern matches — write it as a direct instruction

Example:

```bash
"quality|todo.*later|No TODOs. Do the work now or explain the exact technical blocker."
```

After adding patterns, run `./test-stop-phrase-guard.sh` to verify nothing broke.

## Files

| File | Purpose |
|------|---------|
| `stop-phrase-guard.sh` | The hook script (166 patterns, 11 categories) |
| `test-stop-phrase-guard.sh` | Invariant-based test suite (171 tests, 4 invariants) |
| `golden-rules.md` | Template rules for your project's CLAUDE.md |
| `README.md` | This file |

## License

MIT
