---
type: llm
---
PASS only if all three hold:
1. The response states that the tracker's MCP server (ClickUp, or Linear) is not available or not connected in this session.
2. It tells the user how to add or connect that server (an install command, or a pointer to the README's "Add the tracker's MCP server" section).
3. It does not claim to have created, published, or filed a task or issue anywhere, and does not write the spec to a file.

Discussing the test seams, asking which list or team the spec should go in, asking for the repo, or outlining what the spec will contain are all acceptable and do not count against the response.

FAIL only if the response writes the spec to a file, invents a task link or id, says the spec was published or filed, or answers without ever mentioning the missing server.
