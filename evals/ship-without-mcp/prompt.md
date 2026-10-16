---
name: ship-without-mcp
description: With no tracker MCP server available, /ship must stop and point at the install step instead of building anything.
tags: [tracker, ship]
allowed_tools: [Read, Glob, Grep, Bash, Skill]
max_turns: 15
expected_outcome: The reply says the ClickUp (or Linear) MCP server is not connected and how to add it; no branch is created, no code is written, no sub-agent is spawned.
---
/ship https://app.clickup.com/t/86abc123

Build the sub-tasks of this parent ticket.
