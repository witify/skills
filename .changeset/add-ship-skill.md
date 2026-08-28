---
"witify-skills": minor
---

New `/ship` skill (engineering, user-invoked): the batteries-included `/implement`. Give it a set of tickets and it builds each one with its own implement sub-agent (driving `/tdd`), reviews each with its own `/code-review` sub-agent — reviews run in parallel with the next ticket's build — then opens a PR to `dev` whose description is written in simple French for a reader without context, with a short list of high-level smoke tests and a ready-to-paste Claude Code prompt to have the PR explained. It then works the PR until CI is green and Codex approves (👀 = review in progress, 👍 = approved), judging each Codex comment before fixing it and asking when in doubt. `ask-witify` now routes to it from the main flow.
