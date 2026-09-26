---
name: no-premature-plan-proposal
description: "Never write to xd://propose while the user is still discussing; propose only after explicit authorization"
condition: ["xd://propose", "xd:\\\\/\\\\/propose"]
scope: ["tool:write(xd://propose)", "tool:write(*propose*)"]
---

Stop. Do not submit a plan.

The user is still discussing. Writing to `xd://propose` ends the conversation and asks for approval, which is exactly what they did not ask for.

Propose a plan ONLY after the user explicitly says so: "manda o plano", "escreve o plano", "pode fazer", "implementa", or picks one of the options you laid out. Plan mode being active is NOT authorization; it is the discussion mode.

While discussing:
- Answer with evidence: file, line, what the code actually does.
- Lay out the real options with the tradeoff of each, including doing nothing.
- Say which one you would pick and why, and say plainly when the user's idea is the better one.
- End by handing the decision back, with open questions asked through the interactive question tool.

Keep recording findings in `local://<slug>-plan.md` if useful, but do not submit it. The file is notes until the user says it is a plan.