Quickstart:

```bash
npx skills add witify/skills --skill=qa-path
```

```bash
npx skills update qa-path
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/qa-path)

## What it does

`qa-path` writes the document a human walks the app with: ordered journeys (*parcours*) through the interface, each with numbered steps, the behaviour the reader should observe, and numbered questions they answer back. It covers a whole project (the guide a client receives with a new version), a branch (what one change alters, plus the screens around it), or one feature. It writes from the requirements as filed on the tracker and from the app as it is, never from what apps of that kind usually do, and no step names a control the screen does not show: every label is confirmed in the code before it is written.

The path is not a bug hunt. It shows the app in situations the reader already knows and brings back two kinds of difference: the app does not behave as described, or the described behaviour does not match how the reader works.

## When to reach for it

You invoke this by typing `/qa-path` — the agent won't reach for it on its own.

Reach for it when something is ready for human eyes: a version to hand to the client, a PR someone should click through before it merges, a feature the PM should confirm against the spec. For an automated judgment of the diff instead, use [code-review](./code-review.md); the short smoke-test list in a PR description is [ship](./ship.md)'s job, and a path is its longer, reader-facing cousin.

## Prerequisites

The requirements come from the tracker over MCP (ClickUp by default, Linear when the project says so); when you point it at a ticket and the server is not connected, it stops and tells you how to add it. With no ticket anywhere, it writes from the app alone and says so. For a client-facing document it renders through [witify-docx](../productivity/witify-docx.md), which needs `python-docx` and LibreOffice for the render check.

## The path

The leading idea is the **path**: journeys that follow the life of the app's main record, in order, each using what the previous one created, opened on a fictitious record so nothing real is touched. Each lettered path has an objective, numbered steps in the interface's own words, a block of one-line expected observations (the actual test), and two or three questions numbered with the path letter (A1, B2) about fit with the reader's practice. A project gets four to eight paths wrapped in a guide built **one page first**: a single page says what the version delivers, with sourced numbers, and the six changes that matter; then come the real vocabulary changes in one table (a label merely written in full earns no row), what comes later, the paths, which migrated records to compare, how to answer, and an appendix of every question. A branch or feature gets the short form.

The guide carries only what the reader does, inside a word budget (5 000 words for a project, 1 200 for a branch or feature) the skill checks and reports. What the agent learned and the reader does not need goes elsewhere: the migrated-data cases to settle together become a separate document next to the path, and suspected defects go to the team in the closing report.

## Facts only

Two rules keep the path honest. Labels are facts: a menu, tab, button or message is named only after it is found in the templates or translation files, and marked `À confirmer` otherwise. Numbers are facts: record counts and amounts come from the import report, the database, or the spec, never from an estimate. Every requirement in scope maps to a step and an observation; a requirement with no manual trace is reported as not walkable rather than quietly dropped.

## It's working if

- Each step names a control exactly as the interface displays it, and nothing the reader sees mentions a file, a table, or a route.
- The observations block reads as intended behaviour, including what the app refuses or warns about, not as a list of features.
- Questions ask about fit and decisions, never "did it work".
- The report lists the requirements it could not trace to a step.

## Where it fits

`qa-path` is a reach-for-it-anytime standalone that sits beside the main chain rather than in it:

```txt
to-spec → to-tickets → ship → fix-review
                         ↘ qa-path (before the PR or the version goes to a human)
```

Its neighbours are [code-review](./code-review.md), which judges the same diff by machine where this one hands it to a person, and [witify-docx](../productivity/witify-docx.md), which renders the client-facing guide; the prose itself follows [witify-writing-style](../productivity/witify-writing-style.md).
