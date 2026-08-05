---
"witify-skills": minor
---

Sync with upstream mattpocock/skills and promote two skills:

- `grilling` now interviews in **rounds**: each round asks the whole frontier of the design tree (every question whose prerequisites are settled), with facts delegated to sub-agents instead of asked. `grill-me`, `grill-with-docs`, `triage`, and `loop-me` inherit the new cadence.
- `prototype`'s logic branch now builds a **single shareable HTML file** — free-play buttons plus tabbed guided walkthroughs — instead of a terminal app, so non-developers can drive the state model.
- `writing-great-skills` is renamed to **`writing-for-agents`** and widened to cover anything an agent reads (skills, `AGENTS.md` / `CLAUDE.md`, pointed-at docs). It is now model-invoked; skill-specific mechanics moved to a linked `SKILL-MECHANICS.md`.
- **`wizard`** is promoted to `engineering/` (model-invoked): the agent generates an interactive bash wizard when it hits steps only a human can perform — infra provisioning, credentials, CI secrets, one-off migrations.
- **`to-questionnaire`** is promoted to `productivity/`: turn a decision blocked on someone else's knowledge into a Markdown questionnaire for them to fill in.
- New in-progress skill **`wait-what`**: make the agent re-pitch a message that didn't land, in ASD-STE100 Simplified Technical English and the project's ubiquitous language.
- `batch-grill-me` is removed — its rounds/frontier behaviour is now `grilling`'s default.
