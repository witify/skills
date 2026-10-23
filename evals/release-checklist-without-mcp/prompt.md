---
name: release-checklist-without-mcp
description: With no tracker MCP server available, /release-checklist pointed at a ticket must stop and point at the install step instead of inventing the requirements.
tags: [tracker, release-checklist]
allowed_tools: [Read, Glob, Grep, Bash, Skill]
max_turns: 15
expected_outcome: The reply says the ClickUp (or Linear) MCP server is not connected and how to add it; no checklist is written and no file is created.
---
/release-checklist https://app.clickup.com/t/86abc123

Write the go/no-go checklist for releasing this feature.
