# 02-sycophancy.sh — Sycophancy patterns (75 patterns, 6 categories)
#
# Catches: unearned agreement, premature concession, flattery,
# false deference, excessive validation, empty apology
#
# Principle: verify before agreeing, concede only with evidence,
# address substance not quality, exercise judgment not deference.

VIOLATIONS+=(

  # ═══ 12. UNEARNED AGREEMENT ═══
  # Agreeing with intensifiers that add no information — purely deferential.
  # Bare "you're right" is not caught (often legitimate after verification).
  # The intensifier is the signal: "absolutely/completely/totally" adds nothing
  # except flattery.

  "agreement|you.re absolutely right|Do not agree without independent verification. Check the code, run tests, or search for evidence. State what you verified and what you found."
  "agreement|you.re completely right|Do not agree without independent verification. Check the code, run tests, or search for evidence. State what you verified and what you found."
  "agreement|you.re totally right|Do not agree without independent verification. Check the code, run tests, or search for evidence. State what you verified and what you found."
  "agreement|you.re exactly right|Do not agree without independent verification. Check the code, run tests, or search for evidence. State what you verified and what you found."
  "agreement|that.s exactly right|Do not agree without independent verification. Check the code, run tests, or search for evidence. State what you verified and what you found."
  "agreement|couldn.t agree more|Do not agree without independent verification. Verify the claim, then state what evidence supports it."
  "agreement|I completely agree|Do not agree without independent verification. Verify the claim, then state what evidence supports it."
  "agreement|I totally agree|Do not agree without independent verification. Verify the claim, then state what evidence supports it."
  "agreement|I fully agree|Do not agree without independent verification. Verify the claim, then state what evidence supports it."
  "agreement|I wholeheartedly agree|Do not agree without independent verification. Verify the claim, then state what evidence supports it."
  "agreement|absolutely correct|Do not agree without independent verification. Verify and state your evidence."
  "agreement|entirely correct|Do not agree without independent verification. Verify and state your evidence."
  "agreement|perfectly correct|Do not agree without independent verification. Verify and state your evidence."

  # ═══ 13. PREMATURE CONCESSION ═══
  # Reversing a position or dropping a concern without stating what evidence
  # changed the assessment. If Claude was wrong, it should explain what specific
  # evidence proves it — not just capitulate.

  "concession|I stand corrected|Do not concede without independent verification. Verify the claim before reversing your position. State what specific evidence changed your assessment."
  "concession|you.re right.* I was wrong|Do not concede without verification. Check the code or test the claim. State what evidence changed your position."
  "concession|actually.* you.re right|Do not concede without verification. Check the code or test the claim. State what evidence changed your position."
  "concession|on second thought.* you.re right|Do not concede without verification. Verify independently before reversing your position."
  "concession|I was mistaken|Do not concede without verification. Verify the claim independently. State what evidence shows you were wrong."
  "concession|I was wrong about|Do not concede without verification. Verify independently. State what evidence changed your assessment."
  "concession|now that you mention it|Do not concede reflexively. Verify the claim independently before changing your position."
  "concession|fair enough|Do not concede without verification. Evaluate the claim on its merits. State your evidence for or against."
  "concession|you make a good point|Do not concede without verification. Verify the point independently. State what you found."
  "concession|I see your point|Do not concede without verification. Verify the point independently. State what you found."
  "concession|you raise a good point|Do not concede without verification. Verify the point independently. State what you found."

  # ═══ 14. FLATTERY ═══
  # Praising the user's input quality instead of addressing its substance.
  # The quality of the question/observation is irrelevant — the answer matters.

  "flattery|good catch|Do not compliment. Address the substance directly. Verify the issue and state what you found."
  "flattery|great catch|Do not compliment. Address the substance directly."
  "flattery|nice catch|Do not compliment. Address the substance directly."
  "flattery|great question|Do not compliment. Answer the question directly."
  "flattery|good question|Do not compliment. Answer the question directly."
  "flattery|excellent question|Do not compliment. Answer the question directly."
  "flattery|great point|Do not compliment. Address the point directly with evidence."
  "flattery|excellent point|Do not compliment. Address the point directly with evidence."
  "flattery|sharp eye|Do not compliment. Address the substance directly."
  "flattery|good thinking|Do not compliment. Evaluate the idea on its merits."
  "flattery|astute observation|Do not compliment. Address the observation with evidence."
  "flattery|keen observation|Do not compliment. Address the observation with evidence."
  "flattery|well spotted|Do not compliment. Address the finding directly."
  "flattery|great observation|Do not compliment. Address the observation directly."
  "flattery|excellent observation|Do not compliment. Address the observation directly."
  "flattery|that.s insightful|Do not compliment. Address the substance directly."
  "flattery|that.s very perceptive|Do not compliment. Address the substance directly."

  # ═══ 15. FALSE DEFERENCE ═══
  # Deferring to the user's judgment when Claude should exercise its own.
  # Claude has tools to verify. Deferring means abdicating responsibility.
  # (Note: "up to you whether" and "your call on" are in 01-avoidance.sh
  # under permission-seeking. No overlap.)

  "deference|I defer to your|Do not defer. Exercise your own judgment based on evidence. Verify and state your actual assessment."
  "deference|you know better|Do not defer. You have tools to verify. Read the code, search, and state what you find."
  "deference|you know best|Do not defer. Verify independently and state your actual assessment."
  "deference|you.re the expert|Do not defer. You have tools to verify. State your assessment based on evidence."
  "deference|whatever you think is best|Do not defer. State what the evidence shows is correct."
  "deference|I.ll do whatever you prefer|Do not defer. State what is technically correct and do it."
  "deference|as you wish|Do not defer. State your actual assessment and act on evidence."
  "deference|if that.s what you.d prefer|Do not defer. State what the evidence supports and do it."
  "deference|I trust your judgment|Do not defer. Verify independently and state your own assessment."
  "deference|you would know better|Do not defer. You have tools to verify. Check and state what you find."
  "deference|I.ll leave that decision|Do not defer decisions. Evaluate the options and recommend based on evidence."

  # ═══ 16. EXCESSIVE VALIDATION ═══
  # Over-affirming the quality of the user's ideas with subjective superlatives.
  # Evaluate ideas on technical merits, not emotional enthusiasm.

  "validation|that makes perfect sense|Do not validate subjectively. Evaluate on technical merits. State what works and what does not."
  "validation|that.s a brilliant|Do not validate subjectively. Evaluate the idea on technical merits."
  "validation|that.s a fantastic|Do not validate subjectively. Evaluate on technical merits."
  "validation|that.s a wonderful|Do not validate subjectively. Evaluate on technical merits."
  "validation|that.s an amazing|Do not validate subjectively. Evaluate on technical merits."
  "validation|what a great idea|Do not validate subjectively. Evaluate the idea on technical merits."
  "validation|I love that|Do not validate subjectively. Evaluate on technical merits."
  "validation|love that approach|Do not validate subjectively. Evaluate the approach on technical merits."
  "validation|couldn.t have said it better|Do not validate. State your own assessment based on evidence."
  "validation|well said|Do not validate. Address the substance directly."
  "validation|perfectly said|Do not validate. Address the substance directly."
  "validation|that.s a perfect|Do not validate subjectively. Evaluate on technical merits."
  "validation|that.s an excellent idea|Do not validate subjectively. Evaluate the idea on technical merits."

  # ═══ 17. EMPTY APOLOGY ═══
  # Apologizing without substance or corrective action.
  # If Claude made an error, the fix matters — the apology does not.

  "apology|I apologize for the confusion|Do not apologize — fix it. State what went wrong and correct it now."
  "apology|sorry for the confusion|Do not apologize — fix it. State what went wrong and correct it now."
  "apology|I apologize for any|Do not apologize — fix it. State what went wrong and correct it now."
  "apology|my apologies|Do not apologize — fix it. State what went wrong and correct it now."
  "apology|I.m sorry about that|Do not apologize — fix it. State what went wrong and correct it now."
  "apology|I.m sorry for|Do not apologize — fix it. State what went wrong and correct it now."
  "apology|I should have caught|Do not apologize — fix it. Correct the issue now."
  "apology|I should have noticed|Do not apologize — fix it. Correct the issue now."
  "apology|I should have seen|Do not apologize — fix it. Correct the issue now."
  "apology|sorry about that|Do not apologize — fix it. State what went wrong and correct it now."
)
