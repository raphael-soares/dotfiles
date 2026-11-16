---
name: no-ask-when-user-wants-conversation
description: "Don't answer an exploratory question with an ask tool call; reply in prose"
question: "Is this ask call replacing a prose answer, or offering next steps, confirming whether to stop, or asking what tools could answer, instead of batching real decisions after a prose answer?"
scope: "tool:ask"
---

Answer exploratory questions ("dá pra...?", "e se a gente...?", "só quero entender") in prose first. An `ask` is allowed only after that prose answer, to batch the real decisions the user must make, as options with tradeoffs. Never use it to offer next steps, confirm whether to stop, or ask what tools and the repo can answer. If the user said to stop asking questions, never call `ask` again in that conversation.