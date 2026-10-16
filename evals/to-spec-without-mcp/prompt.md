---
name: to-spec-without-mcp
description: With no tracker MCP server available, /to-spec must stop and point at the install step instead of writing the spec elsewhere.
tags: [tracker, to-spec]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 15
expected_outcome: The reply says the ClickUp (or Linear) MCP server is not connected and how to add it; nothing is written and nothing is claimed published.
---
/to-spec

Context we agreed on: the admin invoice list needs a "Export CSV" button. It exports the currently filtered rows, with the same columns as the table, dates in ISO format, amounts without currency symbol. Only users who can view invoices can export. Large exports (over 5,000 rows) run as a queued job and email a download link. Tests go through the HTTP endpoint only.
