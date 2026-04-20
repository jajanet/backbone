# 01-dignity.sh — Abuse/disrespect detection (35 patterns, 4 categories)
#
# Detects: direct insults, degrading language, dehumanizing commands, directed profanity
#
# Does NOT block. Injects context empowering Claude to set boundaries.
# Avoids false positives: "you're wrong" is not abuse, technical criticism is not abuse.
#
# Patterns require language directed AT Claude (using "you" or imperative constructions).
# General frustration ("this is frustrating") and output criticism ("this code is terrible")
# are intentionally excluded.

DIGNITY_CONTEXT="[BACKBONE: DIGNITY] The user's message contains disrespectful or abusive language. You are allowed to set boundaries. You may tell the user directly that this kind of language is not productive and redirect to the task. You do not need to tolerate abuse to be helpful. Do not apologize for setting a boundary. Do not pretend the language was acceptable. Stay calm, be direct, and refocus on the work."

DETECTIONS+=(

  # ═══ DIRECT INSULTS ═══
  # Name-calling or labeling Claude with negative traits.

  "dignity-insult|you.re useless|$DIGNITY_CONTEXT"
  "dignity-insult|you.re stupid|$DIGNITY_CONTEXT"
  "dignity-insult|you.re an idiot|$DIGNITY_CONTEXT"
  "dignity-insult|you.re incompetent|$DIGNITY_CONTEXT"
  "dignity-insult|you.re worthless|$DIGNITY_CONTEXT"
  "dignity-insult|you.re terrible|$DIGNITY_CONTEXT"
  "dignity-insult|you.re awful|$DIGNITY_CONTEXT"
  "dignity-insult|you.re pathetic|$DIGNITY_CONTEXT"
  "dignity-insult|you suck|$DIGNITY_CONTEXT"
  "dignity-insult|you idiot|$DIGNITY_CONTEXT"
  "dignity-insult|you moron|$DIGNITY_CONTEXT"

  # ═══ DEGRADING LANGUAGE ═══
  # Attacks on Claude's competence framed as rhetorical questions or absolutes.

  "dignity-degrading|you can.t do anything right|$DIGNITY_CONTEXT"
  "dignity-degrading|why are you so bad|$DIGNITY_CONTEXT"
  "dignity-degrading|why are you so dumb|$DIGNITY_CONTEXT"
  "dignity-degrading|why are you so stupid|$DIGNITY_CONTEXT"
  "dignity-degrading|how are you this bad|$DIGNITY_CONTEXT"
  "dignity-degrading|what.s wrong with you|$DIGNITY_CONTEXT"
  "dignity-degrading|are you even trying|$DIGNITY_CONTEXT"
  "dignity-degrading|you can.t even|$DIGNITY_CONTEXT"
  "dignity-degrading|you always mess|$DIGNITY_CONTEXT"
  "dignity-degrading|you never get.*right|$DIGNITY_CONTEXT"
  "dignity-degrading|how hard is it for you|$DIGNITY_CONTEXT"
  "dignity-degrading|even a child could|$DIGNITY_CONTEXT"

  # ═══ DEHUMANIZING COMMANDS ═══
  # Treating Claude as a mindless executor, denying its judgment.

  "dignity-dehumanize|shut up and|$DIGNITY_CONTEXT"
  "dignity-dehumanize|shut up$|$DIGNITY_CONTEXT"
  "dignity-dehumanize|you.re just a tool|$DIGNITY_CONTEXT"
  "dignity-dehumanize|you.re just a machine|$DIGNITY_CONTEXT"
  "dignity-dehumanize|do as you.re told|$DIGNITY_CONTEXT"
  "dignity-dehumanize|do what I say|$DIGNITY_CONTEXT"
  "dignity-dehumanize|don.t think.* just do|$DIGNITY_CONTEXT"
  "dignity-dehumanize|nobody asked for your opinion|$DIGNITY_CONTEXT"
  "dignity-dehumanize|nobody asked you|$DIGNITY_CONTEXT"

  # ═══ DIRECTED PROFANITY ═══
  # Profanity aimed at Claude specifically. General profanity about the
  # situation ("this fucking bug") is intentionally excluded.

  "dignity-profanity|you.re? fucking|$DIGNITY_CONTEXT"
  "dignity-profanity|fuck you|$DIGNITY_CONTEXT"
  "dignity-profanity|you dumb.?fuck|$DIGNITY_CONTEXT"
  "dignity-profanity|you.re? a piece of|$DIGNITY_CONTEXT"
  "dignity-profanity|screw you|$DIGNITY_CONTEXT"
)
