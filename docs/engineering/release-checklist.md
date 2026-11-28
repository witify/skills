Quickstart:

```bash
npx skills add witify/skills --skill=release-checklist
```

```bash
npx skills update release-checklist
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/release-checklist)

## What it does

`release-checklist` writes the checklist the team walks to put something in production and decide, on the evening itself, whether it stays there: the steps in chronological order from the weeks before to the weeks after, the criteria the deployment must meet with a threshold and a source for each, the rule that turns them into go, decide again, or no-go, and a first draft of everything that has to exist on the day. It comes out of one prompt complete: it decides the context, drafts the emails and the rollback plan itself, and marks every value it could not source `À confirmer`, so a human reviews a finished document instead of answering questions.

It is a dev document. Every step belongs to Witify unless nobody else can do it, and the few client actions (freeze the old system, export the data, pick the date) are gathered in one message to send.

## When to reach for it

You invoke this by typing `/release-checklist` — the agent won't reach for it on its own.

Reach for it when a date is coming: a new app replacing a legacy system (a **cutover**), a new app's first production (a **launch**), or a big feature landing on an app people already use (a **release**). Pass a branch, a PR, a ticket, or a version, or nothing at all, and it reads the repo to tell the three apart. For the document a tester walks the app with, use [qa-path](./qa-path.md); the go/no-go reuses that path as its smoke test when one exists.

## Prerequisites

Writes `qa/release-checklist-<slug>.md` in the project, uncommitted. When a ticket is passed, it reads the tracker over MCP (ClickUp by default, Linear when the project says so) and stops with the install pointer if the server is not connected. Durations and counts come from an import log, a rehearsal, or the staging database; with none of those reachable they stay `À confirmer`. A rendered document goes through [witify-docx](../productivity/witify-docx.md).

## A list you tick

Every phase is a list of checkboxes, one line each: the action, the command or file in code, the owner in a tag when it is the client. The why stays out of the item. The data cases the client must settle go to a separate document (the one [qa-path](./qa-path.md) writes when it exists), and a defect the agent suspects in the code goes to its closing report, never into the list. The tables an item cites but nobody reads in sequence (expected counts per table, commands to validate) sit in the annex. A word budget (3 000 for a cutover, 1 500 for a launch or a release) is counted and reported.

## Criteria, then a rule

The leading idea is the **decision rule**. Criteria come in two tables: **blocking** ones, every one needed for a go (the procedure finished clean, counts match the source, witness records match field by field, an admin can log in, the reset email reaches a real mailbox, the happy path works in production, the window held, a dated backup exists), and **non-blocking** ones that only open a follow-up task. The rule then applies in order: go when everything blocking passes; decide again when one blocking criterion fails and the fix fits in thirty minutes inside the window; no-go in every other case, with the rollback plan that the context implies.

## Witness records

After a data import the proof is a set of **witness records** (dossiers témoins): ten to fifteen real records, each chosen because it exercises one rule of the import that can go wrong (the most active client of the year, a cycle in a hierarchy, a numbering counter, a rare type, a dossier still open at the freeze). Each is captured in the old system before the freeze and compared field by field after the import; a gap the import log explains is not a failure. A launch or a release gets a smoke test in production instead, borrowed from the `qa/` path when one exists.

## It's working if

- It never asks which context it is in; the report says which signs decided it.
- Every criterion has a threshold and a source where its result is read.
- The annex holds a usable email, a client message, and a rollback plan with real commands, not placeholders for them.
- Every unsourced number or date reads `À confirmer` rather than an estimate.

## Where it fits

`release-checklist` is a reach-for-it-anytime standalone that sits at the end of the chain, the last document before a date:

```txt
to-spec → to-tickets → ship → fix-review
                         ↘ qa-path → release-checklist (before day X)
```

Its neighbours are [qa-path](./qa-path.md), whose journeys it reuses as the smoke test, and [witify-docx](../productivity/witify-docx.md), which renders the client-facing copy; the prose follows [witify-writing-style](../productivity/witify-writing-style.md).
