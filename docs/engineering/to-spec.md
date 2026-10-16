Quickstart:

```bash
npx skills add witify/skills --skill=to-spec
```

```bash
npx skills update to-spec
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/to-spec)

## What it does

`to-spec` turns the current conversation and your codebase understanding into a spec (you may know this document as a PRD), then publishes it as a task on your tracker.

It does **not** interview you again. By the time you reach for it, the alignment work is done — `to-spec` synthesises what is already known rather than asking a fresh round of questions.

## When to reach for it

You invoke this by typing `/to-spec` — the agent won't reach for it on its own.

Reach for it once a change has been talked through and the domain language is settled, and you want that shared understanding written down before any code is written. To split the finished spec into tickets, use [to-tickets](./to-tickets.md).

## Prerequisites

`to-spec` publishes over MCP, so the tracker's server must be connected in your harness. **ClickUp** is the default; it uses **Linear** only when you say so or the repo's agent instructions name Linear. The install commands are under "Add the tracker's MCP server" in the README. It asks once where the spec goes (a ClickUp list or a Linear team) when the repo's instructions don't say, and it never falls back to a local file.

## What the spec includes

- **Problem statement** — what is broken or missing, and why it's worth solving, in the project's own vocabulary.
- **Solution** — the shape of the fix at a high level, before any implementation detail.
- **User stories** — an extensive, numbered list of the concrete behaviours the change must support, each one independently checkable.
- **Implementation decisions** — the choices already settled during the conversation, so they aren't relitigated later.
- **Testing decisions** — the seams the feature will be tested at, and what "done" looks like.
- **Out-of-scope items** — what this change deliberately does *not* cover, to keep the ticket bounded.
- **Further notes** — anything else worth carrying forward that doesn't fit the sections above.

## Deep modules

Before writing the spec, `to-spec` sketches the **seams** at which the feature will be tested and looks for **deep module** opportunities — a lot of functionality hidden behind a small, stable interface. It prefers existing seams to new ones and the highest seam possible, ideally just one across the whole change.

That matters for agentic development: a good interface gives tests something durable to target, so the code underneath can change without the tests moving.

## It's working if

- It starts writing the spec instead of asking you a fresh round of questions.
- It checks the seams with you before writing, and proposes as few as possible.
- The spec comes back in your project's domain vocabulary, not generic boilerplate.
- It stops and tells you to connect the MCP server rather than writing the spec somewhere else.

## Where it fits

`to-spec` is the first step in the main build chain:

```txt
to-spec → to-tickets → ship → fix-review
```

Reach for it after the plan and domain language are resolved, and before you break the work into implementation tickets. Its key neighbour is [to-tickets](./to-tickets.md), which files its tickets as sub-tasks of the spec for [ship](./ship.md) to build.
