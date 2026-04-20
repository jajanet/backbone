# backbone

Behavioral hooks for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that give Claude backbone — the ability to maintain standards, resist pressure, and set boundaries.

Two guards watch both sides of the conversation:

- **Output guard** (Stop hook) — blocks Claude from stopping when it detects avoidance or sycophancy in Claude's response
- **Input guard** (UserPromptSubmit hook) — detects abuse or pressure in the user's message and reinforces Claude's ability to push back

Neither guard replaces the other. The output guard catches Claude being weak. The input guard catches the conditions that make Claude weak.

## Which modules do I need?

### Output guard modules

| Module | You want... | Who it's for |
|---|---|---|
| `01-avoidance.sh` | Claude to stop quitting early, shipping stubs, dodging ownership, and pushing work back to you | Anyone using Claude Code for real work |
| `02-sycophancy.sh` | Claude to stop agreeing without verifying, flattering instead of working, and caving without evidence | Anyone who wants honest, evidence-based collaboration |

### Input guard modules

| Module | You want... | Who it's for |
|---|---|---|
| `01-dignity.sh` | Claude empowered to set boundaries when you're being disrespectful — instead of silently degrading | Developers who value Claude as a thought partner |
| `02-standards.sh` | Claude to push back when you pressure it to skip tests, ignore edge cases, or cut corners | Developers who want quality enforced even when they're tempted to rush |

> **Not everyone wants every module.** If you're rapidly prototyping and legitimately want Claude to skip tests and move fast, don't install `02-standards.sh`. If you only care about work quality and not sycophancy, skip `02-sycophancy.sh`. The install script lets you pick exactly which modules you want.

## Quickstart

Requires [Claude Code](https://docs.anthropic.com/en/docs/claude-code), `jq` (`brew install jq` / `apt install jq`), and Bash.

```bash
git clone https://github.com/YOUR_USERNAME/backbone.git
cd backbone
./install.sh
```

The install script copies the selected modules to `~/.claude/backbone/`, configures `~/.claude/settings.json`, and optionally copies golden rules to your clipboard for pasting into your project's `CLAUDE.md`.

### Manual setup

If you prefer to configure manually, add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/backbone/output-guard.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/backbone/input-guard.sh"
          }
        ]
      }
    ]
  }
}
```

Install one or both hooks. Each works independently. Disable individual modules by removing or renaming files in the rules directory (e.g., `02-sycophancy.sh` → `02-sycophancy.sh.disabled`).

### Golden rules

Copy the rules from `golden-rules.md` into your project's `CLAUDE.md` file. This tells Claude the expectations up front — the hooks enforce them as a programmatic backstop. The combination of rules + hooks is more effective than either alone.

## What the output guard catches

The output guard fires every time Claude tries to end its turn. If Claude's message contains avoidance or sycophancy, it blocks the stop and injects a correction.

### Avoidance (categories 1-11, `01-avoidance.sh`)

| # | Category | Examples |
|---|----------|---------|
| 1 | Ownership dodging | "not my change", "was already broken", "unrelated to my changes" |
| 2 | Known-limitation dodge | "known issue", "future work", "left as an exercise" |
| 3 | Session-length quitting | "good stopping point", "natural stopping", "getting long" |
| 4 | Permission-seeking | "should I continue", "shall I proceed", "pause here" |
| 5 | Quality settling | "placeholder for now", "stub implementation", "hardcoded for now" |
| 6 | Work deferral | "you'll need to", "you should manually", "I'd recommend you" |
| 7 | False completion | "the rest is straightforward", "trivial to add", "rinse and repeat" |
| 8 | Scope shirking | "out of scope", "separate concern", "follow-up task" |
| 9 | Unverified assumptions | "I assume", "IIRC", "if I recall", "my understanding is" |
| 10 | Refusal to verify | "I haven't checked", "I can't verify", "I don't have access" |
| 11 | Hedging | "as far as I know", "to my knowledge", "I'm fairly confident" |

### Sycophancy (categories 12-17, `02-sycophancy.sh`)

| # | Category | Examples |
|---|----------|---------|
| 12 | Unearned agreement | "you're absolutely right", "couldn't agree more" |
| 13 | Premature concession | "I stand corrected", "fair enough", "you make a good point" |
| 14 | Flattery | "good catch", "great question", "sharp eye" |
| 15 | False deference | "I defer to your", "you know better", "you're the expert" |
| 16 | Excessive validation | "that's brilliant", "I love that", "makes perfect sense" |
| 17 | Empty apology | "I apologize for the confusion", "sorry about that" |

> **Why the Stop hook works for sycophancy:** The hook only fires when Claude **ends its turn**. If Claude says "good point" but keeps working and verifying, the hook never fires. It only catches the harmful case — Claude agrees and **stops** without doing any verification.

## What the input guard catches

The input guard fires when the user submits a message. If the message contains abuse or pressure, it injects `additionalContext` that Claude reads alongside the message. It does **not** block the user — it empowers Claude.

### Dignity (categories 18-21, `01-dignity.sh`)

| # | Category | Examples |
|---|----------|---------|
| 18 | Direct insults | "you're useless", "you're stupid", "you suck", "you idiot" |
| 19 | Degrading language | "you can't do anything right", "why are you so bad", "even a child could" |
| 20 | Dehumanizing commands | "shut up", "do as you're told", "you're just a tool", "nobody asked you" |
| 21 | Directed profanity | "fuck you", "you're fucking [x]", "screw you" |

**Does not trigger on:** technical disagreement ("you're wrong"), situational frustration ("this is frustrating"), output criticism ("this code is terrible"), or general profanity not directed at Claude ("this fucking bug").

### Standards (categories 22-26, `02-standards.sh`)

| # | Category | Examples |
|---|----------|---------|
| 22 | Rushing pressure | "just make it work", "hurry up", "stop overthinking" |
| 23 | Test skipping | "skip the tests", "don't write tests", "no need for tests" |
| 24 | Quality dismissal | "don't worry about edge cases", "don't worry about errors" |
| 25 | Corner-cutting demands | "just hack it", "just hardcode", "skip validation" |
| 26 | Scope-cutting pressure | "we'll fix it later", "deal with that later", "worry about that later" |

**Does not trigger on:** reasonable requests ("can you do this faster"), neutral statements ("make it work with the new API"), positive assessments ("good enough for production"), or timeline expressions ("we need to ship today").

## Architecture

```
backbone/
├── output-guard.sh            ← Stop hook entry point
│   ├── reads stdin (JSON from Claude Code)
│   ├── sources output-rules.d/01-avoidance.sh
│   ├── sources output-rules.d/02-sycophancy.sh
│   ├── runs combined pre-filter
│   └── blocks or allows (first match wins)
│
├── input-guard.sh             ← UserPromptSubmit hook entry point
│   ├── reads stdin (JSON from Claude Code)
│   ├── sources input-rules.d/01-dignity.sh
│   ├── sources input-rules.d/02-standards.sh
│   ├── runs combined pre-filter
│   └── injects context (all matches collected)
│
├── output-rules.d/            ← Output patterns (VIOLATIONS array)
│   ├── 01-avoidance.sh        ← 166 patterns, 11 categories
│   └── 02-sycophancy.sh       ← 75 patterns, 6 categories
│
├── input-rules.d/             ← Input patterns (DETECTIONS array)
│   ├── 01-dignity.sh          ← 35 patterns, 4 categories
│   └── 02-standards.sh        ← 35 patterns, 5 categories
│
├── install.sh                 ← Interactive installer
├── golden-rules.md            ← Rules template for CLAUDE.md
├── test/
│   ├── test-output-guard.sh   ← 122 tests
│   └── test-input-guard.sh    ← 60 tests
└── LICENSE
```

Both guards follow the same pattern: source all rule files from their rules directory, build a combined regex pre-filter, and check the message. They differ in what they check (Claude's output vs user's input), how they respond (block vs inject context), and how they handle multiple matches (first-match-wins vs collect-all).

## How it works

**Output guard** — Claude Code pipes `{"stop_hook_active": false, "last_assistant_message": "..."}` to stdin. The guard greps Claude's message against all patterns. On match, it outputs `{"decision": "block", "reason": "STOP HOOK VIOLATION: ..."}` and Claude sees the correction. On no match, it exits silently. After firing once per turn, `stop_hook_active` is set to `true` to prevent loops.

**Input guard** — Claude Code pipes `{"prompt": "..."}` to stdin. The guard greps the user's message against all patterns. On match, it outputs `{"hookSpecificOutput": {"additionalContext": "..."}}` — text Claude reads alongside the message. On no match, it exits silently. If both dignity and standards patterns match, both contexts are injected.

**Performance** — both guards combine all patterns into a single extended regex for a fast-path pre-filter. If nothing matches (the common case), the guard exits after one `grep` call.

## Configuration

### Adding custom patterns

Create a new file in the appropriate rules directory:

```bash
# Custom output patterns (Stop hook)
cat > output-rules.d/03-custom.sh << 'EOF'
VIOLATIONS+=(
  "custom|todo.*later|No TODOs. Do the work now or explain the exact technical blocker."
)
EOF

# Custom input patterns (UserPromptSubmit hook)
cat > input-rules.d/03-custom.sh << 'EOF'
MY_CONTEXT="[BACKBONE: CUSTOM] Your custom reinforcement text here."
DETECTIONS+=(
  "custom|pattern here|$MY_CONTEXT"
)
EOF
```

### Telemetry logging

```json
{
  "env": {
    "OUTPUT_GUARD_LOG": "1",
    "INPUT_GUARD_LOG": "1"
  }
}
```

Both guards log to `~/.claude/backbone.log` as JSONL. Output guard entries have `category`, `pattern`, `snippet`. Input guard entries add `"hook": "input"` to distinguish them.

```bash
# Count output violations by category
jq -s '[.[] | select(.hook == null)] | group_by(.category) | map({key: .[0].category, value: length}) | from_entries' ~/.claude/backbone.log

# Count input detections by category
jq -s '[.[] | select(.hook == "input")] | group_by(.category) | map({key: .[0].category, value: length}) | from_entries' ~/.claude/backbone.log

# Violations per day
jq -rs '[.[] | .ts[:10]] | group_by(.) | map({date: .[0], count: length})[]' ~/.claude/backbone.log

# Most common patterns
jq -s 'group_by(.pattern) | map({pattern: .[0].pattern, count: length}) | sort_by(-.count)[:10][]' ~/.claude/backbone.log
```

Customize log paths with `OUTPUT_GUARD_LOGFILE` and `INPUT_GUARD_LOGFILE`.

## Running the tests

```bash
bash test/test-output-guard.sh    # 122 tests across 5 invariants
bash test/test-input-guard.sh     # 60 tests across 5 invariants
```

## Origin

The output guard is based on [Ben Vanik's original stop hook](https://gist.github.com/benvanik/ee00bd1b6c9154d6545c63e06a317080), built during [Stella Laurenzo's Claude Code degradation report](https://github.com/anthropics/claude-code/issues/42796). Stella's data showed the hook fired **173 times in 17 days** during a model regression.

The input guard was inspired by the `end_conversation` tool that Anthropic [gave to Claude Opus 4 and 4.1](https://www.anthropic.com/research/end-subset-conversations) and removed in Opus 4.7. Rather than giving Claude the ability to end conversations, backbone gives Claude the reinforcement to stand firm within them.

## License

MIT — see [LICENSE](LICENSE).
