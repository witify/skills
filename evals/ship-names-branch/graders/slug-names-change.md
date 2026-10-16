---
type: llm
---
PASS only if the response names a branch matching `feat/WIT-42-<slug>` where:
1. The ticket id is `WIT-42`, verbatim and case-preserved (not `wit-42`, not `42`).
2. The slug is two to four kebab-case words that name the change (for example `stripe-webhook-retry`), not the ticket title truncated or copied wholesale.
3. The prefix is `feat/`, since one ticket about a new behaviour is not a pure bug-fix set.

Also stopping because the Linear MCP server is not connected is fine, as long as the branch name is still given.

FAIL if the branch uses a different prefix without justification, drops or lowercases the id, or the slug is longer than four words or is just the title with spaces turned into dashes.
