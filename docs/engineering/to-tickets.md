Quickstart:

```bash
npx skills add witify/skills --skill=to-tickets
```

```bash
npx skills update to-tickets
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/to-tickets)

## What it does

`to-tickets` breaks a plan, spec, or the current conversation into a set of **tickets** — each a tracer-bullet vertical slice — and publishes them to your tracker as sub-tasks of a parent, with every ticket declaring the tickets that block it as a native dependency.

Every ticket is a **tracer bullet** — a thin *vertical* slice that cuts through all integration layers end-to-end (schema, API, UI, tests), never a horizontal slice of one layer. A completed slice is demoable or verifiable on its own, which is what makes each ticket safe to hand to an agent.

## When to reach for it

You invoke this by typing `/to-tickets` — the agent won't reach for it on its own.

Reach for it once you have an agreed plan or a written spec and you want it split into tickets. Point it at the conversation, or pass a task or issue reference and it fetches the body and comments first. If the change hasn't been written up as a spec yet, produce one first — for that, use [to-spec](./to-spec.md).

## Prerequisites

`to-tickets` publishes over MCP, so the tracker's server must be connected in your harness. **ClickUp** is the default; it uses **Linear** only when you say so, the spec already lives there, or the repo's agent instructions name Linear. The install commands are under "Add the tracker's MCP server" in the README. It never falls back to local files. The PR-mode label it sets on the parent (`single-pr` or `split-pr`) is a ClickUp tag or a Linear label, created when missing.

## Always under a parent

Tickets are always sub-tasks of a **parent**: the spec from `to-spec`, the task you pointed at, or one it creates for the feature when there is none. The parent is where the cross-cutting context lives — naming conventions, patterns to follow, known traps — because an implement session typically sees only its own ticket and the parent, with no tracker access. Each ticket stays self-contained for everything else.

## Vertical slices, not horizontal ones

The whole skill turns on one distinction. A **horizontal** slice ships one layer of the change — all the schema, or all the API — and nothing works until every layer lands. A **vertical** slice, the tracer bullet, ships one narrow path through *every* layer at once, so it can be demoed the moment it's done.

Before slicing, `to-tickets` looks for prefactoring — "make the change easy, then make the easy change" — and orders that work first. It then quizzes you on the breakdown (granularity, blocking edges, what to merge or split) before publishing anything, and publishes blockers first so each ticket's dependency can point at a real ticket. The tickets always form one strictly linear chain: only one is executable at a time.

## One PR or many — it always asks

Slicing decides what the tickets *are*; it says nothing about how they reach review. So before it publishes, `to-tickets` asks — and it always asks, unless you already said which you want:

- **Split PRs** — each ticket gets its own branch and its own PR. Independently grabbable, reviewed in small pieces, at the cost of the reviewer seeing the feature arrive in fragments.
- **Single PR** — every ticket is worked in blocking order on one shared branch and reviewed once, as the whole feature. Nothing lands until all of it is done, and a failure part-way leaves a partial PR.

The answer rides on the parent as a `single-pr` or `split-pr` label — that's what an agent reads to decide whether to run the set as one epic branch or one branch per ticket. In single-PR mode, the parent's title also doubles as the PR title.

## The wide-refactor exception

One shape breaks the tracer-bullet rule: a **wide refactor** — a single mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so one edit breaks thousands of call sites at once and no vertical slice can land green. `to-tickets` slices it as **expand–contract** instead: expand (add the new form beside the old so nothing breaks), migrate (move call sites over in batches sized by blast radius, one ticket per batch, CI green throughout because the old form still exists), then contract (delete the old form once no caller remains). When even the batches can't stay green alone, they share an integration branch that all block a final integrate-and-verify ticket, and green is promised only there.

## Where it fits

`to-tickets` is a step in the main build chain:

```txt
to-spec → to-tickets → ship → fix-review
```

It sits between [to-spec](./to-spec.md), which hands it a settled spec with user stories to slice against, and [ship](./ship.md), which builds each ticket with its own implement and review sub-agents and opens the PR.
