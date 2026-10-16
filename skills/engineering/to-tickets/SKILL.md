---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to ClickUp (or Linear) over MCP as sub-tasks with native blocking links — and record whether the set ships as one PR or one PR per ticket.
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

## Tracker

Tickets live on **ClickUp** by default, reached over its MCP server. Use **Linear** instead only when the user says so, the source spec already lives there, or the repo's agent instructions (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`) name Linear as the project's tracker.

Before publishing, confirm two things:

1. **The MCP server is connected.** The tracker's tools must be in your available tools — `clickup_create_task` for ClickUp, `save_issue` for Linear. If they are not, stop and tell the user to add the server and sign in (the install commands are under "Add the tracker's MCP server" in the `witify/skills` README). Never write tickets to local files instead, and never claim to have published.
2. **Where they go.** Tickets are always filed as sub-tasks of a **parent**: the spec or task the user pointed at, or one this skill creates (step 6). A new parent needs a ClickUp list or a Linear team — resolve it from the repo's agent instructions, or ask the user once, and confirm before creating anything.

Operations, per tracker:

- **ClickUp** — read a task with `clickup_get_task` plus `clickup_get_task_comments`; create a ticket with `clickup_create_task` giving the parent; record a blocking edge with `clickup_add_task_dependency`, the ticket *waiting on* its blocker; the PR-mode label is a tag, `clickup_add_tag_to_task`.
- **Linear** — read an issue with `get_issue` plus `list_comments`; create a ticket with `save_issue` giving the parent; use Linear's native **blocked by** relation where the tooling at hand can set it, otherwise put a `Blocked by: ABC-123` line at the top of the description; the PR-mode label is an issue label set through `save_issue`, created first with `create_issue_label` if missing.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a ClickUp task id or URL, a Linear identifier or URL, a spec path) as an argument, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

</vertical-slice-rules>

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. **Tickets must always form one strictly linear chain; parallel tickets are never allowed.** The first ticket has no blocker, and every subsequent ticket is blocked by the ticket immediately before it, even when there is no technical dependency. Only one ticket may be executable at a time.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change — rename a column, retype a shared symbol — whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Ask how the work ships — split PRs or one PR

**Always ask this, unless the user already said which they want.** Never assume a default and never infer one from the size of the breakdown.

- **Split PRs** — each ticket is worked on its own branch and reviewed as its own PR. Independently grabbable, reviewed in small pieces, but the reviewer sees the feature arrive in fragments.
- **Single PR** — every ticket is worked in order on one shared branch and reviewed as one PR. One review of the whole feature, but nothing lands until all of it is done, and a failure part-way leaves a partial PR.

The breakdown itself does not change either way — the same tickets, the same blocking edges. Only how they get branched and reviewed changes.

### 6. Publish the tickets

First settle the **parent**. If the source was an existing task or issue (typically a spec from `/to-spec`), use it. Otherwise create one for the feature — title and one-paragraph summary of what the whole set delivers. Never close or otherwise modify a pre-existing source beyond the two additions below (the PR-mode label and the shared context).

Then publish one ticket per slice as a sub-task of the parent, **in dependency order (blockers first)** so each ticket's blocking edge can point at a real identifier. Record every edge with the tracker's native dependency (see Tracker above). Use the issue template below. Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

#### Recording the PR mode

The answer from step 5 rides on the **parent**, as a label — `single-pr` or `split-pr`. It is what tells an agent whether to run the set as one epic branch or one branch per ticket, so it must be set explicitly even when it matches the agent's default. In Single PR mode the parent is what gets picked up and its sub-tasks are worked in blocking order on one branch; in Split PR mode each sub-task is picked up on its own.

#### Writing for the agent that implements

An implement session typically receives two descriptions as text: the ticket's own and its direct parent's. It may have no tracker access — a link in a description resolves to nothing, and anything beyond that pair is invisible. So put the cross-cutting decisions a ticket set shares — naming conventions, patterns to follow, known traps — in the parent's description, and make each ticket self-contained for everything else. In Single PR mode, the parent's title becomes the PR title; name it like one.

<issue-template>

## Parent

A reference to the parent task or issue.

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective — not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None — can start immediately".

</issue-template>

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.
