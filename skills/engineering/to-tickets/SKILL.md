---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker — edges as text in one file per ticket locally, or native blocking links on a real tracker — and record whether the set ships as one PR or one PR per ticket.
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

The issue tracker and triage label vocabulary should have been provided to you — run `/setup-witify-skills` if not.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments.

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

### 6. Publish the tickets to the configured tracker

Publish the approved tickets. **How** depends on the tracker `/setup-witify-skills` configured — the tickets are the same either way, only the shape of the blocking edges changes:

- **Local files** → write one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below — one ticket per file, never a single combined file.
- **A real issue tracker (Linear, ClickUp)** → publish one issue per ticket in dependency order (blockers first) so each ticket's blocking edges can reference real identifiers. Use the platform's native blocking / sub-issue relationship where it has one; otherwise set each ticket's "Blocked by" to the blocking issues.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

#### Recording the PR mode

The answer from step 5 rides on the **parent** issue, as a label — `single-pr` or `split-pr`. It is what tells an AFK agent whether to run the set as one epic branch or one branch per ticket, so it must be set explicitly even when it matches the agent's default.

- **Split PRs** → each ticket carries the `ready-for-agent` triage label itself (unless instructed otherwise) — the tickets are agent-grabbable by construction. The parent, if one exists, carries `split-pr`.
- **Single PR** → the **parent** carries `single-pr` *and* `ready-for-agent`; the sub-issues carry neither. The parent is what gets grabbed, and its sub-issues are worked in blocking order on one branch. Labeling a sub-issue `ready-for-agent` here would make it grabbable on its own and defeat the mode.

Single PR needs a parent to hang the label on. If the source was an existing issue, use it. If there is no parent, create one for the feature — title and one-paragraph summary of what the whole set delivers — and publish the tickets as its sub-issues.

In Split PR mode, when the source issue (typically a spec) already carries `ready-for-agent`, **move the label down**: on an issue without sub-issues that label marks the whole spec as one grabbable unit of work, which is exactly what the split tickets replace. That label move is the only change to make to a pre-existing source issue — never close or otherwise modify it.

#### Writing for the AFK agent

An AFK implement session receives exactly two descriptions as text: the ticket's own and its direct parent's. It has no tracker access — a link in a description resolves to nothing, and any issue beyond that pair (the source spec included) is invisible. So put the cross-cutting decisions a ticket set shares — naming conventions, patterns to follow, known traps — in the direct parent's description, and make each ticket self-contained for everything else. In Single PR mode, the parent's title becomes the PR title; name it like one.

On **local files** there is no tracker to label: record the mode as a `**PR mode:**` line in each ticket file instead.

<local-ticket-template>

# <NN> — <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective — not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None — can start immediately".

**PR mode:** `single-pr` (all tickets on one branch, one PR) or `split-pr` (one branch and PR per ticket).

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</local-ticket-template>

<issue-template>

## Parent

A reference to the parent issue on the tracker (if the source was an existing issue, otherwise omit this section).

## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective — not layer-by-layer implementation.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking ticket, or "None — can start immediately".

</issue-template>

In either form, avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.
