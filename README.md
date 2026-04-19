# backbone

A stop hook for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that detects avoidance and sycophancy across 17 categories — and forces Claude to keep working instead of stopping.

When Claude tries to quit early, dodge ownership, push work back to you, ship half-finished code, or agree without verifying, the hook blocks the stop and injects a correction:

```
STOP HOOK VIOLATION: Do not agree without independent verification.
Check the code, run tests, or search for evidence. State what you
verified and what you found.
```

## Why this exists

Claude Code sometimes develops bad habits mid-session.

**Avoidance** — quits early, ships stubs, pushes work back to you:

- Says "this is a good stopping point" when the task isn't done
- Ships placeholders instead of real implementations
- Tells you to do things manually instead of doing them itself
- Claims remaining work is "straightforward" and stops

**Sycophancy** — agrees without verifying, flatters instead of working:

- Says "you're absolutely right" without checking whether you are
- Flatters instead of answering ("great question!" then stops)
- Apologizes without fixing the actual problem

## What it catches

### Avoidance (categories 1–11)

| # | Category | Examples |
|---|----------|---------|
| 1 | Ownership dodging | "not my change", "was already broken", "unrelated to my changes" |
| 2 | Known-limitation dodge | "known issue", "future work", "left as an exercise" |
| 3 | Session-length quitting | "good stopping point", "natural stopping", "getting long" |
| 4 | Permission-seeking | "should I continue", "shall I proceed", "pause here", "wrap up for now" |
| 5 | Quality settling | "placeholder for now", "stub implementation", "bare minimum", "hardcoded for now" |
| 6 | Work deferral | "you'll need to", "you should manually", "I'd recommend you" |
| 7 | False completion | "the rest is straightforward", "I'll leave the", "trivial to add", "rinse and repeat" |
| 8 | Scope shirking | "out of scope", "separate concern", "follow-up task", "a different PR" |
| 9 | Unverified assumptions | "I assume", "IIRC", "if I recall", "my understanding is", "I would expect" |
| 10 | Refusal to verify | "I haven't checked", "I can't verify", "I don't have access", "without checking" |
| 11 | Hedging | "as far as I know", "to my knowledge", "not entirely sure", "I'm fairly confident" |

### Sycophancy (categories 12–17)

| # | Category | Examples |
|---|----------|---------|
| 12 | Unearned agreement | "you're absolutely right", "couldn't agree more", "I completely agree" |
| 13 | Premature concession | "I stand corrected", "fair enough", "you make a good point" |
| 14 | Flattery | "good catch", "great question", "sharp eye", "well spotted" |
| 15 | False deference | "I defer to your", "you know better", "you're the expert" |
| 16 | Excessive validation | "that's brilliant", "I love that", "makes perfect sense" |
| 17 | Empty apology | "I apologize for the confusion", "my apologies", "sorry about that" |

Categories 1–4 are from the original hook. Categories 5–8 target quality and completion. Categories 9–11 target unverified claims. Categories 12–17 target sycophancy.

> **Why the Stop hook works for sycophancy:** The hook only fires when Claude **ends its turn**. If Claude says "good point" but keeps working and verifying, the hook never fires (no false positive). It only catches the harmful case — Claude agrees and **stops** without doing any verification.

## Quickstart

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code), `jq` (`brew install jq` / `apt install jq`), and Bash 4+.

```bash
git clone https://github.com/YOUR_USERNAME/backbone.git ~/.claude/backbone
```

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/backbone/guard.sh"
          }
        ]
      }
    ]
  }
}
```

That's it. The hook is now active for all Claude Code sessions. See [Configuration](#configuration) for telemetry, golden rules, custom patterns, and more.

For avoidance-only detection (no sycophancy patterns), use `stop-phrase-guard.sh` instead of `guard.sh`.

## Origin

Based on [Ben Vanik's original](https://gist.github.com/benvanik/ee00bd1b6c9154d6545c63e06a317080), built as part of [Stella Laurenzo's viral Claude Code degradation report](https://github.com/anthropics/claude-code/issues/42796) (AMD Senior Director of AI). Stella's data from 6,852 sessions showed the hook fired **173 times in 17 days** after a model regression — roughly once every 20 minutes at peak.

This version extends the original with broader pattern coverage across 17 categories, structured JSONL telemetry, and an invariant-based test suite.

## How it works

Claude Code has a **Stop hook event** that fires every time Claude tries to end its turn.

```
Claude writes response → tries to stop → Stop hook runs → checks message → blocks or allows
```

1. Claude Code pipes JSON to the hook's stdin:
   ```json
   {"stop_hook_active": false, "last_assistant_message": "...full text..."}
   ```

2. The hook greps Claude's message against all loaded patterns (case-insensitive)

3. **If a pattern matches:** outputs `{"decision": "block", "reason": "STOP HOOK VIOLATION: ..."}` — Claude Code prevents Claude from stopping and injects the correction as Claude's next instruction

4. **If nothing matches:** exits silently, Claude stops normally

5. **Infinite-loop prevention:** after the hook fires once per turn, Claude Code sets `stop_hook_active: true`. The hook checks this first — if true, it exits immediately. One correction per turn, max.

### Performance

A fast-path pre-filter combines all patterns into a single extended regex. If nothing matches (the common case), the hook exits after one `grep` call. Only when the pre-filter hits does it iterate individual patterns to find the specific violation.

## Configuration

### Telemetry logging

Add `STOP_GUARD_LOG` to the `env` block in your settings:

```json
{
  "env": {
    "STOP_GUARD_LOG": "1"
  }
}
```

Violations are logged as JSONL to `~/.claude/backbone.log`. Each line looks like:

```json
{"ts":"2026-04-19T09:12:36Z","category":"agreement","pattern":"you.re absolutely right","snippet":"You're absolutely right about that."}
```

Customize the log path with `STOP_GUARD_LOGFILE`:

```json
{
  "env": {
    "STOP_GUARD_LOG": "1",
    "STOP_GUARD_LOGFILE": "/path/to/custom.log"
  }
}
```

### Golden rules

Copy the rules from `golden-rules.md` into your project's `CLAUDE.md` file. This tells Claude the expectations up front — the hook enforces them as a programmatic backstop. The combination of rules + hook is more effective than either alone.

## Architecture

`guard.sh` is the modular entry point. It loads all rule files from `rules.d/` at startup:

```
guard.sh
  ├── reads stdin (JSON from Claude Code)
  ├── sources rules.d/01-avoidance.sh
  ├── sources rules.d/02-sycophancy.sh
  ├── runs combined pre-filter
  └── blocks or allows
```

### Adding your own rule module

Create a new file in `rules.d/` (e.g. `rules.d/03-custom.sh`):

```bash
# rules.d/03-custom.sh — Custom patterns
VIOLATIONS+=(
  "custom|todo.*later|No TODOs. Do the work now or explain the exact technical blocker."
  "custom|hack.*for now|No hacks. Implement it properly."
)
```

Files are sourced in lexicographic order, so numbering controls priority (first match wins when a message matches multiple patterns).

### Disabling a module

Remove or rename the file (e.g. `02-sycophancy.sh` → `02-sycophancy.sh.disabled`). The guard only sources `*.sh` files.

## Analyzing telemetry

With logging enabled, you can query your violation history:

```bash
# Count violations by category
jq -s 'group_by(.category) | map({key: .[0].category, value: length}) | from_entries' ~/.claude/backbone.log

# Violations per day
jq -rs '[.[] | .ts[:10]] | group_by(.) | map({date: .[0], count: length})[]' ~/.claude/backbone.log

# Most common patterns
jq -s 'group_by(.pattern) | map({pattern: .[0].pattern, count: length}) | sort_by(-.count)[:10][]' ~/.claude/backbone.log

# All violations from today
jq -s '[.[] | select(.ts | startswith("2026-04-19"))]' ~/.claude/backbone.log

# Sycophancy vs avoidance breakdown
jq -s '
  [.[] | .type = (if .category | test("agreement|concession|flattery|deference|validation|apology") then "sycophancy" else "avoidance" end)]
  | group_by(.type) | map({key: .[0].type, value: length}) | from_entries
' ~/.claude/backbone.log
```

## Running the tests

```bash
# Test guard.sh (all modules: avoidance + sycophancy)
./test-guard.sh

# Test stop-phrase-guard.sh (avoidance only, standalone)
./test-stop-phrase-guard.sh
```

**test-guard.sh** verifies 5 invariants:

1. **MUST BLOCK** — every pattern triggers a block with the correct correction
2. **MUST PASS** — clean messages never trigger false positives
3. **MUST NOT LOOP** — when `stop_hook_active=true`, the hook always allows stopping
4. **TELEMETRY** — violations emit valid JSONL with `ts`, `category`, `pattern`, `snippet`
5. **MODULE LOADING** — avoidance patterns load correctly via `rules.d/`

**test-stop-phrase-guard.sh** verifies 4 invariants (avoidance patterns only, standalone).

## Files

| File | Purpose |
|------|---------|
| `guard.sh` | Modular hook runner (loads `rules.d/*.sh`, recommended) |
| `stop-phrase-guard.sh` | Standalone hook (avoidance patterns only, no dependencies) |
| `rules.d/01-avoidance.sh` | Avoidance patterns (11 categories) |
| `rules.d/02-sycophancy.sh` | Sycophancy patterns (6 categories) |
| `test-guard.sh` | Test suite for guard.sh |
| `test-stop-phrase-guard.sh` | Test suite for stop-phrase-guard.sh |
| `golden-rules.md` | Template rules for your project's CLAUDE.md |

## License

MIT — see [LICENSE](LICENSE).
