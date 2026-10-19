Quickstart:

```bash
npx skills add witify/skills --skill=ship
```

```bash
npx skills update ship
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/ship)

## What it does

`ship` takes a set of tickets all the way to a reviewed PR: it builds each ticket with its own implement sub-agent, reviews each with its own review sub-agent, moves each ticket's status in the tracker as it goes, and opens one PR to `dev` written in simple French for a reader without the project's context. A set always ships as one branch and one PR, worked in blocking order. It fixes every real finding worth doing by default, without asking you to pick a threshold first, and it builds for the long term: an implement sub-agent looks for what the repo already has before writing anything, and a change that reinvents an existing abstraction is a defect the review catches, not a nit.

Its correction loop is bounded to five feedback waves. Its finish line is a green, approved PR, or a precise report of what was deliberately left untouched and why.

## When to reach for it

You invoke this by typing `/ship` — the agent won't reach for it on its own.

Reach for it when the tickets are ready — the output of [to-tickets](./to-tickets.md) — and you want the whole build-review-PR loop run for you.

## Prerequisites

The tracker's MCP server connected (ClickUp by default, Linear when the project says so: that's where the tickets come from), a `dev` branch to target, a clean working tree (it stops rather than stash or commit work it did not make), and an authenticated `gh` CLI for the PR and its checks.

## The branch it names

Before any code is written, `ship` puts the work on a branch named `feat/<ticket-id>-<slug>` — `feat/WIT-42-stripe-webhook-retry` — so the tracker id and a two-to-four-word description of the change are both readable straight from `git branch` (`fix/` when the whole set is bug fixes).

When you start from `dev` it cuts that branch. When you start from a branch a tool handed you — Polyscope's `azure-ant`, a `codex/…` — it **renames that branch in place** rather than cutting a new one, so the workspace keeps the checkout and the base it was given. The rename happens before the first push, so nothing stale is left on the remote; a branch that was already pushed keeps its name.

## The pipeline

One sub-agent per ticket to implement, one per ticket to review — N tickets, 2N sub-agents. Implementations run sequentially, because they share the working tree; each ticket's review runs in parallel with the next ticket's implementation, so no wall-clock is wasted. Every implement sub-agent starts with a fresh context, receives its ticket and the parent's description (where `to-tickets` puts the decisions the whole set shares), and builds test-first; its commits follow the repo's own convention and always name the ticket, with review fixes marked `review:` so a reader can tell the build from the corrections; every review sub-agent runs [code-review](./code-review.md) pinned to that one ticket's commits, with the ticket as its spec.

## Look before you build

The implement sub-agent's brief has two rules that outlive the ticket. First, it searches the repo for code that already does something close and extends it instead of writing a parallel version. Second, anything a second caller could want goes where the repo already centralizes that kind of thing, never inline in a controller or a template. The review sub-agent closes the loop with a **reinvented wheel** check that `code-review` does not make on its own: it compares the diff to the existing code, not only to itself, and reports any duplicate or bypass of an existing abstraction as a P2, which gets fixed.

## Ticket statuses

The tracker shows progress as it happens. A ticket moves to in-progress when its implement sub-agent starts and to in-review when the PR opens, using the statuses the list or team actually offers; `ship` never marks a ticket done, because merging is what completes it.

## What gets fixed

Everything real, relevant, and worth doing, at any priority, from ticket reviews, CI failures, and Codex comments. The judgment that matters is **worth doing**: a rare edge case the project will never hit, busywork with no observable effect, a decision already made in the ticket, the guidelines, or the session, and concurrency hardening a project does not need are all rejected with the reason recorded. Most internal apps rarely have two users on the same resource at once, so race-condition findings are usually rejected; `ship` reads the project's domain once per session to decide, treats booking, inventory, sales, payments, queues, collaborative editing and public-crowd domains as ones where concurrency is worth doing, and asks you once when the domain is unclear. Pass "analysis only" in the invocation if you want the tickets built and the PR opened but every finding judged and reported rather than applied.

## Milestone banners

A run is long and most of its transcript is sub-agent chatter, so `ship` marks each milestone with a boxed banner you can spot while scrolling: one when a ticket starts (`🎫 TICKET 2 / 4`, with the previous ticket's result and what remains), a double-lined one when the PR opens (`🚀 PR OUVERTE`, with the link), and one per Codex wave as the review starts (`👀`), as its findings are fixed (`🔧`, with the fixed, rejected and deferred counts) and when Codex approves (`👍`). The emoji is what tells them apart.

## Five feedback waves

After the PR opens, one wave gathers the complete CI and Codex results, triages them, and validates the fixes as a batch. The initial pass counts as wave one; a re-check after a fix push starts the next. Codex gets at most fifteen minutes per wave: if it never reacts, the run is CI-only rather than waiting forever. The loop stops as soon as CI is green, Codex approves, and nothing worth doing remains, and always stops after wave five with the outstanding state made explicit.

Codex is never left hanging on the way out: when `gh` is installed, every Codex comment gets a reply in its own language saying what was decided — fixed with a commit link, rejected with the reasoning, or deferred — and its thread is then resolved. Only Codex's own threads are closed that way; a human's stays open for [fix-review](./fix-review.md).

The PR description it writes is itself a deliverable: the parent's title as the PR title, a plain-French summary, one bullet per ticket, and a short list of hand-runnable smoke tests — plus a ready-to-paste Claude Code prompt so a reviewer can have the PR explained to them.

## Where it fits

`ship` is the tail of the main chain — it collapses `build → review → PR → controlled feedback` into one invocation:

```txt
to-spec → to-tickets → ship → fix-review
```

Its key neighbours are [to-tickets](./to-tickets.md), which produces the tickets it builds, and [fix-review](./fix-review.md), which takes over when **human** review comes back on the PR — `ship` handles CI and Codex only.
