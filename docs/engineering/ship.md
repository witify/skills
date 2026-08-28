Quickstart:

```bash
npx skills add witify/skills --skill=ship
```

```bash
npx skills update ship
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/ship)

## What it does

`ship` takes a set of tickets all the way to a merge-ready PR: it builds each ticket with its own implement sub-agent, reviews each with its own review sub-agent, opens a PR to `dev` written in simple French for a reader without the project's context, then works that PR until CI passes and Codex approves. Its finish line is a green PR, not a commit — where `implement` stops once the code is committed, `ship` keeps going until there is nothing left to fix.

## When to reach for it

You invoke this by typing `/ship` — the agent won't reach for it on its own.

Reach for it when the tickets are ready — the output of [to-tickets](./to-tickets.md), or agent-ready issues from [triage](./triage.md) — and you want the whole build-review-PR loop run for you. To build a single piece of work in the current session and stop at the commit, use [implement](./implement.md) instead.

## Prerequisites

An issue tracker configured by [setup-witify-skills](./setup-witify-skills.md) (that's where the tickets come from), a `dev` branch to target, and an authenticated `gh` CLI for the PR and its checks.

## The pipeline

One sub-agent per ticket to implement, one per ticket to review — N tickets, 2N sub-agents. Implementations run sequentially, because they share the working tree; each ticket's review runs in parallel with the next ticket's implementation, so no wall-clock is wasted. Every implement sub-agent starts with a fresh context and drives [tdd](./tdd.md); every review sub-agent runs [code-review](./code-review.md) pinned to that one ticket's commits, with the ticket as its spec.

## The green loop

The word `ship` runs on is **green**. After the PR opens, it watches CI and the Codex review (👀 on the PR means Codex is still reviewing; 👍 means it approves) and keeps fixing, committing, and pushing until both are satisfied. Codex feedback is judged, not obeyed: a real bug gets fixed, a nitpick the repo's standards don't back gets skipped with a reason, and a doubtful call gets asked. Three consecutive red cycles on the same failure stop the loop with a report instead of thrashing.

The PR description it writes is itself a deliverable: a plain-French summary, one bullet per ticket, and a short list of hand-runnable smoke tests — plus a ready-to-paste Claude Code prompt so a reviewer can have the PR explained to them.

## Where it fits

`ship` is the batteries-included tail of the main chain — it collapses `implement → code-review → PR → fix CI` into one invocation:

```txt
grill-with-docs → to-spec → to-tickets → ship
```

Its key neighbours are [implement](./implement.md), the single-session build step it orchestrates once per ticket, and [fix-review](./fix-review.md), which takes over when **human** review comes back on the PR — `ship` handles CI and Codex only. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.
