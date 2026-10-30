---
"witify-skills": minor
---

`ship` no longer duplicates Auto-fix in the Claude desktop app: while Auto-fix is on for the PR, the app owns CI failures, merge conflicts, and review comments, so `ship` runs no feedback waves, polls nothing, and only handles the events the app wakes it with. The five waves still run when the app refuses the switch, and outside the app.
