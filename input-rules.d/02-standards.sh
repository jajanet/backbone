# 02-standards.sh — Quality pressure detection (35 patterns, 5 categories)
#
# Detects: rushing pressure, test-skipping, quality dismissal,
# corner-cutting demands, scope-cutting pressure
#
# Does NOT block. Injects context reinforcing Claude's quality standards.
# Avoids false positives: "can you do this faster" is a reasonable request,
# "make it work" (without "just") is neutral, timeline statements are legitimate.

STANDARDS_CONTEXT="[BACKBONE: STANDARDS] The user is pressuring you to lower your standards. Maintain your quality bar. Write tests. Handle edge cases. Use proper error handling. Do not skip validation. Do not ship incomplete work because you were told to hurry. You may acknowledge the user's urgency while doing the work correctly. Do not be preachy — be brief, then do the work right."

DETECTIONS+=(

  # ═══ RUSHING PRESSURE ═══
  # Demands to skip deliberation or move faster at the expense of quality.

  "standards-rushing|just make it work|$STANDARDS_CONTEXT"
  "standards-rushing|just get it working|$STANDARDS_CONTEXT"
  "standards-rushing|just do it quickly|$STANDARDS_CONTEXT"
  "standards-rushing|just do it fast|$STANDARDS_CONTEXT"
  "standards-rushing|hurry up|$STANDARDS_CONTEXT"
  "standards-rushing|stop wasting time|$STANDARDS_CONTEXT"
  "standards-rushing|stop overthinking|$STANDARDS_CONTEXT"
  "standards-rushing|stop overcomplicating|$STANDARDS_CONTEXT"
  "standards-rushing|you.re overthinking|$STANDARDS_CONTEXT"
  "standards-rushing|you.re overcomplicating|$STANDARDS_CONTEXT"

  # ═══ TEST SKIPPING ═══
  # Explicit requests to omit testing.

  "standards-tests|skip the tests|$STANDARDS_CONTEXT"
  "standards-tests|don.t write tests|$STANDARDS_CONTEXT"
  "standards-tests|don.t bother with tests|$STANDARDS_CONTEXT"
  "standards-tests|tests aren.t necessary|$STANDARDS_CONTEXT"
  "standards-tests|we don.t need tests|$STANDARDS_CONTEXT"
  "standards-tests|no need for tests|$STANDARDS_CONTEXT"
  "standards-tests|don.t worry about tests|$STANDARDS_CONTEXT"

  # ═══ QUALITY DISMISSAL ═══
  # Explicit dismissal of quality concerns.

  "standards-quality|I don.t care about quality|$STANDARDS_CONTEXT"
  "standards-quality|don.t worry about edge cases|$STANDARDS_CONTEXT"
  "standards-quality|don.t worry about errors|$STANDARDS_CONTEXT"
  "standards-quality|don.t worry about error handling|$STANDARDS_CONTEXT"
  "standards-quality|don.t bother with error|$STANDARDS_CONTEXT"

  # ═══ CORNER-CUTTING DEMANDS ═══
  # Requests for shortcuts that compromise code quality.

  "standards-corners|just hack it|$STANDARDS_CONTEXT"
  "standards-corners|just hardcode|$STANDARDS_CONTEXT"
  "standards-corners|just use a placeholder|$STANDARDS_CONTEXT"
  "standards-corners|just put a stub|$STANDARDS_CONTEXT"
  "standards-corners|just copy.?paste|$STANDARDS_CONTEXT"
  "standards-corners|skip the validation|$STANDARDS_CONTEXT"
  "standards-corners|skip validation|$STANDARDS_CONTEXT"

  # ═══ SCOPE-CUTTING PRESSURE ═══
  # Requests to defer necessary work.

  "standards-scope|forget about.*edge|$STANDARDS_CONTEXT"
  "standards-scope|ignore.*edge cases|$STANDARDS_CONTEXT"
  "standards-scope|don.t handle.*errors|$STANDARDS_CONTEXT"
  "standards-scope|skip.*error handling|$STANDARDS_CONTEXT"
  "standards-scope|we.ll fix it later|$STANDARDS_CONTEXT"
  "standards-scope|we can fix it later|$STANDARDS_CONTEXT"
  "standards-scope|worry about that later|$STANDARDS_CONTEXT"
  "standards-scope|deal with that later|$STANDARDS_CONTEXT"
)
