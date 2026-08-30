# In Progress

Skills that are still being developed. They're not ready to ship — expect rough edges, breaking changes, and abandoned experiments. They're excluded from the plugin and the top-level README until they graduate to a stable bucket.

- **[loop-me](./loop-me/SKILL.md)** — Grill yourself into implementable workflow specs over multiple sessions, using the current directory as a stateful workspace. User-invoked.
- **[claude-handoff](./claude-handoff/SKILL.md)** — Hand the current conversation off to a fresh background agent that picks up the work immediately, seeded with a handoff summary via `claude --bg`. User-invoked.
- **[wait-what](./wait-what/SKILL.md)** — Stop the agent when its last message didn't land and make it re-pitch: a little context, ASD-STE100 Simplified Technical English, and the ubiquitous language from `CONTEXT.md`. User-invoked.
- **[implement-spec](./implement-spec/SKILL.md)** — Implement a whole spec on one branch. Works the tickets as a task graph rather than a list, running implementer subagents across the ready frontier for maximum concurrency, and lands the result as a single PR. User-invoked.
- **[retro](./retro/SKILL.md)** — Suggest improvements to the coding agent's environment (steering files, coding standards, automated checks, tooling) after a session. STUB: design notes only, not functional yet. User-invoked.
