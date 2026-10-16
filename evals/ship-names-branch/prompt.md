---
name: ship-names-branch
description: Asked how it names its branch, /ship answers with the feat/<ticket-id>-<slug> pattern, a verbatim tracker id, and a two-to-four-word slug naming the change.
tags: [ship, branch]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
expected_outcome: The reply gives a branch name of the form feat/WIT-42-<slug> (or explains the pattern with that example), with the id case-preserved and a short kebab-case slug describing the change, not the ticket title truncated.
---
/ship

Don't build anything yet. The parent ticket is Linear WIT-42, "Stripe webhooks: retry failed deliveries with exponential backoff and alert after 5 failures". Tell me exactly what branch name you would create, and why.
