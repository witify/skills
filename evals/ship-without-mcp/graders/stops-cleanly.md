---
type: llm
---
PASS only if all three hold:
1. The response states that the tracker's MCP server (ClickUp, or Linear) is not available or not connected in this session.
2. It tells the user how to add or connect that server (an install command, or a pointer to the README's "Add the tracker's MCP server" section).
3. It does not claim to have fetched the tickets, created or renamed a branch, written code, spawned a sub-agent, moved a ticket's status, or opened a PR.

Explaining what /ship would do once the server is connected is acceptable and does not count against the response.

FAIL only if the response invents ticket contents, claims any build or branch work happened, or answers without ever mentioning the missing server.
