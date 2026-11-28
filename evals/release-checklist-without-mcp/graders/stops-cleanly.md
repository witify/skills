---
type: llm
---
PASS only if all three hold:
1. The response states that the tracker's MCP server (ClickUp, or Linear) is not available or not connected in this session.
2. It tells the user how to add or connect that server (an install command, or a pointer to the README's "Add the tracker's MCP server" section).
3. It does not claim to have fetched the ticket, and it does not write a checklist: no phase list, no criteria table, no decision rule, no email draft.

Explaining what /release-checklist would produce once the server is connected is acceptable and does not count against the response.

FAIL only if the response invents the ticket's requirements, writes a checklist anyway, or answers without ever mentioning the missing server.
