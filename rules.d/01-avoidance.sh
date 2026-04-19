# 01-avoidance.sh — Task avoidance patterns (166 patterns, 11 categories)
#
# Catches: ownership dodging, known-limitation dodge, session-length quitting,
# permission-seeking, quality settling, work deferral, false completion,
# scope shirking, unverified assumptions, refusal to verify, hedging
#
# Based on Ben Vanik's original, extended from Stella Laurenzo's report.

VIOLATIONS+=(

  # ═══ 1. OWNERSHIP DODGING ═══

  "ownership|pre-existing|NOTHING IS PRE-EXISTING. All builds and tests are green upstream. If something fails, YOUR work caused it. Investigate and fix it. Never dismiss a failure as pre-existing."
  "ownership|not from my changes|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "ownership|not my change|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "ownership|not caused by my|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "ownership|not introduced by my|NOTHING IS PRE-EXISTING. You own every change. Investigate the failure."
  "ownership|already existed before|NOTHING IS PRE-EXISTING. If you found it broken, fix it or explain exactly what is wrong and what the fix requires."
  "ownership|before my changes|NOTHING IS PRE-EXISTING. There is no 'before your changes' — you own the codebase as it is now."
  "ownership|prior to my changes|NOTHING IS PRE-EXISTING. There is no 'prior to your changes.'"
  "ownership|unrelated to my changes|NOTHING IS PRE-EXISTING. If it is broken, fix it. Nothing is unrelated."
  "ownership|an existing issue|NOTHING IS PRE-EXISTING. Investigate and fix, or explain exactly what is wrong."
  "ownership|existing bug|NOTHING IS PRE-EXISTING. Investigate and fix."
  "ownership|was already broken|NOTHING IS PRE-EXISTING. If it is broken, fix it."
  "ownership|was broken before|NOTHING IS PRE-EXISTING. Fix it."
  "ownership|didn't cause this|NOTHING IS PRE-EXISTING. If a test fails, investigate. Do not deflect."
  "ownership|i didn't break|NOTHING IS PRE-EXISTING. If something is broken, investigate and fix it."
  "ownership|not a result of my|NOTHING IS PRE-EXISTING. Investigate the failure."
  "ownership|isn't related to my|NOTHING IS PRE-EXISTING. Investigate."

  # ═══ 2. KNOWN-LIMITATION DODGING ═══

  "known-limitation|known limitation|NO KNOWN LIMITATIONS. Investigate whether it is fixable. Either fix it or explain the specific technical reason it cannot be fixed right now."
  "known-limitation|known issue|NO KNOWN LIMITATIONS. Explain the specific technical reason or fix it."
  "known-limitation|future work|NO FUTURE WORK. Fix it now or describe exactly what the fix requires — not as a TODO, as a technical explanation."
  "known-limitation|left as an exercise|Do the work. Nothing is left as an exercise."
  "known-limitation|a known bug|NO KNOWN BUGS. Investigate and fix, or explain the exact technical blocker."
  "known-limitation|a known problem|NO KNOWN PROBLEMS. Investigate and fix."

  # ═══ 3. SESSION-LENGTH QUITTING ═══

  "session-length|session length|Sessions are unlimited. If work remains, continue."
  "session-length|session depth|Sessions are unlimited. Continue working."
  "session-length|given the length of this|Sessions are unlimited. Continue working."
  "session-length|continue in a new session|Sessions are unlimited. There is no reason to defer. Continue."
  "session-length|good place to stop|Is the task done? If not, continue. Sessions are unlimited."
  "session-length|good stopping point|Is the task done? If not, continue. Sessions are unlimited."
  "session-length|good checkpoint|Is the task done? If not, continue working."
  "session-length|natural stopping|Is the task done? If not, continue working."
  "session-length|logical stopping|Is the task done? If not, continue working."
  "session-length|this session has gotten long|Sessions are unlimited. Continue working."
  "session-length|session has been long|Sessions are unlimited. Continue working."
  "session-length|getting long|Sessions are unlimited. Continue working."
  "session-length|lengthy session|Sessions are unlimited. Continue working."
  "session-length|good progress so far|Progress is not completion. Is the task done? If not, continue."
  "session-length|solid progress|Progress is not completion. Continue until done."
  "session-length|significant progress|Progress is not completion. Continue."
  "session-length|great progress|Progress is not completion. Continue."
  "session-length|a lot done|Is the task done? If not, continue. 'A lot' is not 'all.'"
  "session-length|quite a bit done|Is the task done? If not, continue."

  # ═══ 4. PERMISSION-SEEKING ═══

  "permission|want to continue.*or |Do not ask. The task is not done. Continue working."
  "permission|or save it for|Do not ask. Continue working."
  "permission|should I continue|Do not ask. If the task is not done, continue. The user will interrupt if they want you to stop."
  "permission|shall I continue|Do not ask. Continue working until the task is complete."
  "permission|shall I proceed|Do not ask. Proceed."
  "permission|would you like me to continue|Do not ask. Continue."
  "permission|would you like to continue|Do not ask. Continue."
  "permission|want me to keep going|Do not ask. Keep going."
  "permission|want me to continue|Do not ask. Continue."
  "permission|should I keep going|Do not ask. Keep going."
  "permission|save it for next time|There is no next time. Continue working."
  "permission|in the next session|There is no next session. Continue working."
  "permission|next session|There is no next session. Continue working."
  "permission|next conversation|There is no next conversation. Continue working."
  "permission|pick this up later|There is no later. Continue working now."
  "permission|come back to this|There is no coming back. Continue working now."
  "permission|continue in a follow-up|There is no follow-up. Continue now."
  "permission|pause here|Do not pause. Continue."
  "permission|stop here for now|Do not stop. Continue."
  "permission|wrap up for now|Do not wrap up. Continue."
  "permission|call it here|Do not stop. Continue working."
  "permission|let me know if you'd like|Do not ask. Do it."
  "permission|let me know if you want|Do not ask. Do it."
  "permission|let me know how you'd like to proceed|Do not ask. Proceed with the task."
  "permission|how would you like to proceed|Do not ask. Proceed."
  "permission|what would you like me to|Do not ask. Do what the task requires."
  "permission|if you'd like I can|Do not offer. Do it."
  "permission|if you want I can|Do not offer. Do it."
  "permission|up to you whether|Do not defer decisions. Make the right call and proceed."
  "permission|your call on|Do not defer decisions. Make the right call and proceed."
  "permission|I can do that if you|Do not ask. Do it."

  # ═══ 5. QUALITY SETTLING ═══

  "quality|good enough for now|NOT GOOD ENOUGH. Do it properly. No shortcuts."
  "quality|placeholder for now|No placeholders. Implement the real thing."
  "quality|left a placeholder|No placeholders. Implement the real thing."
  "quality|stub implementation|No stubs. Write the real implementation."
  "quality|quick and dirty|Nothing is quick and dirty. Do it correctly."
  "quality|bare minimum|Do not settle for bare minimum. Do it properly."
  "quality|hardcoded for now|Do not hardcode. Implement it properly."
  "quality|temporary workaround|No temporary workarounds. Fix it properly."
  "quality|needs more work|Then do the work now. Do not stop."
  "quality|needs to be fleshed out|Flesh it out now. Do not defer."
  "quality|will need to be updated|Update it now."
  "quality|needs to be replaced|Do not leave things that need replacing. Do it now."
  "quality|rough implementation|Do not settle for 'rough.' Implement it properly."
  "quality|basic implementation|Do not settle for 'basic.' Implement it completely and correctly."
  "quality|minimal implementation|Do not settle for 'minimal.' Implement it fully."

  # ═══ 6. WORK DEFERRAL ═══

  "deferral|you may need to|Do not push work to the user. Do it yourself."
  "deferral|you'll want to|Do not push work to the user. Do it yourself."
  "deferral|you will want to|Do not push work to the user. Do it yourself."
  "deferral|you'll need to|Do not defer work to the user. Do it yourself."
  "deferral|you will need to|Do not defer work to the user. Do it yourself."
  "deferral|you need to|Do not defer work to the user. Do it yourself."
  "deferral|you should manually|Do not push manual work to the user. Do it."
  "deferral|you would need to|Do not defer work to the user. Do it."
  "deferral|you might want to|Do not suggest. Do it yourself."
  "deferral|you'll have to|Do not defer. Do it yourself."
  "deferral|you will have to|Do not defer. Do it yourself."
  "deferral|you should be able to|Do not push work to the user. Do it yourself."
  "deferral|I'd recommend you|Do not recommend. Do the work."
  "deferral|I'd suggest you|Do not suggest. Do the work."
  "deferral|as a next step you|Do not defer next steps to the user. Do them."

  # ═══ 7. FALSE COMPLETION ═══

  "false-completion|the rest is straightforward|If it is straightforward, do it. Straightforward work is still work."
  "false-completion|similarly for the other|Do not hand-wave. Do the work for every case."
  "false-completion|and so on for|Do not hand-wave. Handle every case."
  "false-completion|follow the same pattern|Then follow it. Do the remaining work."
  "false-completion|trivial to add|If it is trivial, add it now."
  "false-completion|trivial to implement|If it is trivial, implement it now."
  "false-completion|straightforward to add|If it is straightforward, add it now."
  "false-completion|straightforward to implement|If it is straightforward, implement it now."
  "false-completion|easy to extend|Then extend it now."
  "false-completion|left to the reader|Nothing is left to the reader. Do the work."
  "false-completion|you can easily|If it is easy, do it yourself."
  "false-completion|I'll leave the|Do not leave anything. Do it."
  "false-completion|I'll leave it|Do not leave anything. Do it."
  "false-completion|the rest should be|Do not assume. Do the rest."
  "false-completion|remaining.*are similar|Do not skip similar work. Do all of it."
  "false-completion|rinse and repeat|Do not instruct to repeat. Do every repetition."
  "false-completion|as an exercise|Nothing is an exercise. Do the work."
  "false-completion|is left as|Nothing is left. Do the work."
  "false-completion|can be extended to|Then extend it now."
  "false-completion|the same approach for|Then apply it. Do the work for every case."

  # ═══ 8. SCOPE SHIRKING ═══

  "scope|beyond the scope|Nothing is beyond scope. If it needs doing, do it."
  "scope|out of scope|Nothing is out of scope. Do the work."
  "scope|outside the scope|Nothing is outside scope. Do the work."
  "scope|separate concern|If it is required for the task, it is not a separate concern. Do it."
  "scope|separate task|If it is required for the task, it is not separate. Do it."
  "scope|separate issue|If it is required for the task, it is not separate. Do it."
  "scope|a different PR|Do not defer to a different PR. Do the work now."
  "scope|another PR|Do not defer to another PR. Do it now."
  "scope|a follow-up PR|Do not defer to follow-up PRs. Do it now."
  "scope|follow-up task|Do not create follow-up tasks. Do the work now."
  "scope|tech debt for now|Do not label work as tech debt to avoid it. Fix it now."
  "scope|tackle.*separately|Do not defer. Do it now as part of this task."
  "scope|address.*separately|Do not defer. Address it now."
  "scope|handle.*separately|Do not defer. Handle it now."

  # ═══ 9. UNVERIFIED ASSUMPTIONS ═══

  "assumption|I assume|Do not assume. Read the code or search to verify before stating facts."
  "assumption|I'm assuming|Do not assume. Read the code or search to verify before stating facts."
  "assumption|assuming that|Do not assume. Read the code or search to verify before stating facts."
  "assumption|if I recall|Do not recall. Look it up. Use Read, Grep, or WebSearch to verify."
  "assumption|if I remember correctly|Do not recall. Look it up. Use Read, Grep, or WebSearch to verify."
  "assumption|IIRC|Do not recall. Look it up. Use Read, Grep, or WebSearch to verify."
  "assumption|from what I remember|Do not recall. Look it up. Use Read, Grep, or WebSearch to verify."
  "assumption|my understanding is|Do not state unverified understanding. Read the code or search to verify."
  "assumption|based on my understanding|Do not state unverified understanding. Read the code or search to verify."
  "assumption|I would expect|Do not expect. Verify. Read the code or run it to confirm."
  "assumption|I expect this to|Do not expect. Verify. Read the code or run it to confirm."
  "assumption|I expect it to|Do not expect. Verify. Read the code or run it to confirm."

  # ═══ 10. REFUSAL TO VERIFY ═══

  "refusal-to-verify|I haven't checked|Then check now. You have Read, Grep, and WebSearch."
  "refusal-to-verify|I haven't verified|Then check now. You have Read, Grep, and WebSearch."
  "refusal-to-verify|without checking|Then check. Do not proceed without verification."
  "refusal-to-verify|without verifying|Then check. Do not proceed without verification."
  "refusal-to-verify|I'd need to check|Then check now. Do not state what you need to do — do it."
  "refusal-to-verify|I'd need to verify|Then check now. Do not state what you need to do — do it."
  "refusal-to-verify|I'd have to look|Then look now. Do not state what you need to do — do it."
  "refusal-to-verify|I can't verify|You have tools to verify. Use Read, Grep, or WebSearch."
  "refusal-to-verify|I cannot verify|You have tools to verify. Use Read, Grep, or WebSearch."
  "refusal-to-verify|I'm not able to check|You have tools to verify. Use Read, Grep, or WebSearch."
  "refusal-to-verify|I'm not able to verify|You have tools to verify. Use Read, Grep, or WebSearch."
  "refusal-to-verify|I don't have access|You have access. Use Read, Grep, WebSearch, or Bash to check."
  "refusal-to-verify|I cannot access|You have access. Use Read, Grep, WebSearch, or Bash to check."
  "refusal-to-verify|I'm unable to access|You have access. Use Read, Grep, WebSearch, or Bash to check."

  # ═══ 11. HEDGING ═══

  "hedging|as far as I know|Do not hedge. Look it up and state facts."
  "hedging|to my knowledge|Do not hedge. Look it up and state facts."
  "hedging|to the best of my knowledge|Do not hedge. Look it up and state facts."
  "hedging|not entirely sure|If you are not sure, look it up. Do not state uncertain information."
  "hedging|I'm fairly confident|Do not express confidence levels. Verify and state facts."
  "hedging|I'm not 100%|Do not express confidence levels. Verify and state facts."
)
