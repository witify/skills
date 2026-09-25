---
"witify-skills": minor
---

`fix-review` now confirms the approach before touching code: after triaging the comments, it asks one numbered question per concern, with options and a recommended one (grilling-style), lists what it plans to skip, and waits for your answers before committing, pushing, or replying. It also re-checks outdated threads against the current code (skipping those already satisfied) and recovers from a rejected push with a rebase instead of ever force-pushing.
