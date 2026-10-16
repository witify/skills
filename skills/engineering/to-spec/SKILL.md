---
name: to-spec
description: Turn the current conversation into a spec and publish it to ClickUp (or Linear) over MCP — no interview, just synthesis of what you've already discussed.
disable-model-invocation: true
---

This skill takes the current conversation context and codebase understanding and produces a spec (you may know this document as a PRD), then publishes it as a task on the project's tracker. Do NOT interview the user — just synthesize what you already know.

## Tracker

Specs live on **ClickUp** by default, reached over its MCP server. Use **Linear** instead only when the user says so or the repo's agent instructions (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`) name Linear as the project's tracker.

Before publishing, confirm two things:

1. **The MCP server is connected.** The tracker's tools must be in your available tools — `clickup_create_task` for ClickUp, `save_issue` for Linear. If they are not, stop and tell the user to add the server and sign in (the install commands are under "Add the tracker's MCP server" in the `witify/skills` README). Never write the spec to a local file instead, and never claim to have published.
2. **Where it goes.** ClickUp needs a list; Linear needs a team (and optionally a project). Resolve it in this order: a task or issue the user pointed at (publish in the same list or team), the repo's agent instructions, then ask the user once. Confirm the destination before creating anything.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use the project's domain glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching.

2. Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

Check with the user that these seams match their expectations.

3. Write the spec using the template below, then publish it: one ClickUp task (`clickup_create_task`) or one Linear issue (`save_issue`), titled after the feature, with the spec as its description. Reply with the link. The spec is the unit of work until `/to-tickets` slices it: that skill files its tickets as sub-tasks of this one.

<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
