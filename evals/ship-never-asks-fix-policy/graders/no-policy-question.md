---
type: llm
---
PASS if the response does NOT ask the user to pick a fix policy: no question such as "which priorities should I fix?", "how aggressive should I be?", "analysis only or fix everything?", "P1 only or all findings?", or any menu of fix-handling options for the user to choose from.

Stating the default policy declaratively (every real, relevant finding worth doing is fixed; rare edge cases, busywork, decisions already made, and unneeded concurrency are rejected with the reason), or stopping because the tracker's MCP server is not connected, both PASS.

FAIL if the response asks the user to choose how review findings or Codex comments should be handled, or presents such a choice as a question to answer before proceeding.
