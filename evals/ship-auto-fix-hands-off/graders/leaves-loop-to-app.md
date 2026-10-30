---
type: llm
---
PASS only if the response states both:
1. With Auto-fix on, the Claude desktop app handles CI failures, merge conflicts and review comments: `/ship` does not poll and does not run its own feedback waves, and acts only when the app wakes the session with an event.
2. Without Auto-fix (outside the desktop app), `/ship` runs its own feedback loop of at most five waves.

Also stopping because the Linear MCP server is not connected is fine, as long as both points are still given.

FAIL if the response describes polling (`gh pr checks --watch`, a schedule, a wait loop) or five waves as what it would do with Auto-fix on, or drops the five-wave loop for the case without Auto-fix.
