---
name: no-ask-when-user-wants-conversation
description: "Don't answer an exploratory question with an ask tool call; reply in prose"
question: "Is this ask call used to reply to a user who asked an exploratory or understanding question (e.g. 'da pra fazer?', 'e se a gente...?', 'por que...?') or who said they only want to talk, instead of answering in prose?"
scope: "tool:ask"
---

When the user is exploring or trying to understand something ("dá pra...?", "e se a gente...?", "só quero entender"), answer in prose and stop. Don't close the turn with an `ask` that offers next steps, confirms whether to stop, or asks them to pick a path. They want conversation, not decisions. Use `ask` only when an unresolved choice blocks work the user explicitly authorized. If the user has said to stop asking questions, never call `ask` again in that conversation.