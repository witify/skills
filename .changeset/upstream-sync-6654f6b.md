---
"witify-skills": minor
---

Synced the vendored skills with upstream [mattpocock/skills](https://github.com/mattpocock/skills) up to `6654f6b`.

The change you're most likely to feel is in how skills reach for each other. A skill will no longer silently fire a user-invoked skill on your behalf — `code-review`, `to-spec`, `to-tickets`, `triage`, and `wayfinder` now tell you to run `/setup-witify-skills` when the issue-tracker config is missing, instead of running it themselves. Where a skill does reach for another, it says so explicitly ("call the Skill tool with …"), which makes the hand-off visible in the transcript.

Subagent dispatch is now harness-neutral: `code-review` and `improve-codebase-architecture` no longer name Claude Code's `Agent` tool or its agent types, so they behave the same on Codex.

`domain-modeling` gets a sharper trigger — it now fires on codebase terminology being discussed, and on a `CONTEXT.md` or ADR being written or edited, rather than on the vaguer "wants to pin down terminology". `diagnosing-bugs` redacts secrets before it reports. `grilling` separates the questions in a round with a rule. `wizard` stopped guessing at how many minutes a step takes.

Two upstream drafts arrive in `in-progress/`, unpromoted and undocumented for now: `implement-spec` (work a spec's tickets as a task graph, running implementer subagents across the ready frontier into one PR) and `retro` (suggest improvements to the agent's environment after a session — upstream flags it as design notes, not yet functional).
