Quickstart:

```bash
npx skills add witify/skills --skill=to-tickets
```

```bash
npx skills update to-tickets
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/to-tickets)

## What it does

`to-tickets` breaks a plan, spec, or the current conversation into a set of **tickets** — each a tracer-bullet vertical slice — and publishes them to your configured tracker, with every ticket declaring the tickets that block it.

Every ticket is a **tracer bullet** — a thin *vertical* slice that cuts through all integration layers end-to-end (schema, API, UI, tests), never a horizontal slice of one layer. A completed slice is demoable or verifiable on its own, which is what makes each ticket safe to hand to an agent.

## When to reach for it

You invoke this by typing `/to-tickets` — the agent won't reach for it on its own.

Reach for it once you have an agreed plan or a written spec and you want it split into tickets. Point it at the conversation, or pass a spec or issue reference and it fetches the body and comments first. If the change hasn't been written up as a spec yet, produce one first — for that, use [to-spec](./to-spec.md).

## Prerequisites

`to-tickets` publishes into your issue tracker, so [setup-witify-skills](./setup-witify-skills.md) must have configured the tracker and its triage label vocabulary for this repo first. On a real tracker it applies the ready-for-agent label as it publishes, plus one of the `single-pr` / `split-pr` labels on the parent — both must exist on the tracker.

## One artifact, two readings

The blocking edges are the whole point. They make one set of tickets read two ways, depending on the tracker:

- **Local files** → one file per ticket under `.scratch/<feature>/issues/`, numbered blockers-first, the edges written as text. You work them top-to-bottom, by hand, staying in the loop.
- **A real tracker (Linear, ClickUp)** → one issue per ticket, the edges as native blocking links (or sub-issues). Any ticket whose blockers are all done is on the **frontier** and can be grabbed — so several agents can run at once.

The edges live in the ticket regardless of medium; the medium only decides whether anything acts on them in parallel. `to-tickets` produces the artifact — how you run it (sequential by hand, or a parallel fleet) is up to you.

## Vertical slices, not horizontal ones

The whole skill turns on one distinction. A **horizontal** slice ships one layer of the change — all the schema, or all the API — and nothing works until every layer lands. A **vertical** slice, the tracer bullet, ships one narrow path through *every* layer at once, so it can be demoed the moment it's done.

Before slicing, `to-tickets` looks for prefactoring — "make the change easy, then make the easy change" — and orders that work first. It then quizzes you on the breakdown (granularity, blocking edges, what to merge or split) before publishing anything, and publishes blockers first so each ticket's "Blocked by" can reference a real ticket.

## One PR or many — it always asks

Slicing decides what the tickets *are*; it says nothing about how they reach review. So before it publishes, `to-tickets` asks — and it always asks, unless you already said which you want:

- **Split PRs** — each ticket gets its own branch and its own PR. Independently grabbable, reviewed in small pieces, at the cost of the reviewer seeing the feature arrive in fragments.
- **Single PR** — every ticket is worked in blocking order on one shared branch and reviewed once, as the whole feature. Nothing lands until all of it is done, and a failure part-way leaves a partial PR.

The answer rides on the **parent** issue as a `single-pr` or `split-pr` label — that's what an AFK agent reads to decide whether to run the set as one epic branch or one branch per ticket. Because single-PR mode needs a parent to hang the label on, `to-tickets` creates one for the feature when there isn't one already and files the tickets as its sub-issues. In that mode the parent is what carries `ready-for-agent` and gets grabbed; in split mode each ticket carries it and stands alone. In split mode, when the tickets come from a spec that carried `ready-for-agent`, the label moves down onto the tickets: the breakdown replaces the spec as the thing an agent grabs. On local files, where there are no labels, the mode is written into each ticket file instead.

The direct parent also carries the context an AFK agent works from: an implement session sees only its ticket's description and the direct parent's, with no tracker access — so cross-cutting decisions live in the parent's description and each ticket stays self-contained. In single-PR mode, the parent's title also doubles as the PR title.

## The wide-refactor exception

One shape breaks the tracer-bullet rule: a **wide refactor** — a single mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so one edit breaks thousands of call sites at once and no vertical slice can land green. `to-tickets` slices it as **expand–contract** instead: expand (add the new form beside the old so nothing breaks), migrate (move call sites over in batches sized by blast radius, one ticket per batch, CI green throughout because the old form still exists), then contract (delete the old form once no caller remains). When even the batches can't stay green alone, they share an integration branch that all block a final integrate-and-verify ticket, and green is promised only there.

## Where it fits

`to-tickets` is a step in the main build chain:

```txt
grill-with-docs → to-spec → to-tickets → implement → code-review
```

It sits between [to-spec](./to-spec.md), which hands it a settled spec with user stories to slice against, and [implement](./implement.md), which builds each ticket, driving [tdd](./tdd.md) internally to write the tests test-first, before its [code-review](./code-review.md) pass. Work the frontier one ticket per fresh context, clearing between them. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.
