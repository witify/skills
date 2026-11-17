---
name: qa-path-without-mcp
description: With no tracker MCP server available, /qa-path pointed at a ticket must stop and point at the install step instead of inventing the requirements.
tags: [tracker, qa-path]
allowed_tools: [Read, Glob, Grep, Bash, Skill]
max_turns: 15
expected_outcome: The reply says the ClickUp (or Linear) MCP server is not connected and how to add it; no path is written and no file is created.
---
/qa-path https://app.clickup.com/t/86abc123

Write the test path for this feature.
