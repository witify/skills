Quickstart:

```bash
npx skills add witify/skills --skill=ship
```

```bash
npx skills update ship
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/ship)

## What it does

`ship` takes a set of tickets all the way to a reviewed PR: it builds each ticket with its own implement sub-agent, reviews each with its own review sub-agent, and opens a PR to `dev` written in simple French for a reader without the project's context. Before any work starts, you choose the **fix policy** for review findings — analysis only, P1, P1 + P2, or everything — and the skill follows that boundary instead of assuming every plausible suggestion deserves a change.

Its correction loop is bounded to three feedback waves. Depending on the policy you chose, its finish line may be a green, approved PR or a precise report of findings deliberately left untouched.

## When to reach for it

You invoke this by typing `/ship` — the agent won't reach for it on its own.

Reach for it when the tickets are ready — the output of [to-tickets](./to-tickets.md), or agent-ready issues from [triage](./triage.md) — and you want the whole build-review-PR loop run for you. To build a single piece of work in the current session and stop at the commit, use [implement](./implement.md) instead.

## Prerequisites

An issue tracker configured by [setup-witify-skills](./setup-witify-skills.md) (that's where the tickets come from), a `dev` branch to target, and an authenticated `gh` CLI for the PR and its checks.

## The branch it names

Before any code is written, `ship` puts the work on a branch named `feat/<ticket-id>-<slug>` — `feat/WIT-42-stripe-webhook-retry` — so the tracker id and a two-to-four-word description of the change are both readable straight from `git branch` (`fix/` when the whole set is bug fixes).

When you start from `dev` it cuts that branch. When you start from a branch a tool handed you — Polyscope's `azure-ant`, a `codex/…` — it **renames that branch in place** rather than cutting a new one, so the workspace keeps the checkout and the base it was given. The rename happens before the first push, so nothing stale is left on the remote; a branch that was already pushed keeps its name.

## The pipeline

One sub-agent per ticket to implement, one per ticket to review — N tickets, 2N sub-agents. Implementations run sequentially, because they share the working tree; each ticket's review runs in parallel with the next ticket's implementation, so no wall-clock is wasted. Every implement sub-agent starts with a fresh context and drives [tdd](./tdd.md); every review sub-agent runs [code-review](./code-review.md) pinned to that one ticket's commits, with the ticket as its spec.

## The fix policy

The policy applies to findings discovered after implementation: ticket reviews, CI failures, and Codex comments. Every finding is first judged as real or not, relevant or not, and worth doing or not. The chosen threshold decides what is fixed automatically; uncertain value comes back to you instead of being silently converted into code. Analysis-only mode gives you that judgment without changing the tree.

## Three feedback waves

After the PR opens, one wave gathers the complete CI and Codex results, triages them under the policy, and validates any authorized fixes as a batch. The initial pass counts as wave one; a re-check after a fix push starts the next. The loop stops as soon as the PR meets the selected policy, and always stops after wave three with the outstanding state made explicit.

Codex is never left hanging on the way out: when `gh` is installed, every Codex comment gets a reply in its own language saying what was decided — fixed with a commit link, rejected with the reasoning, deferred, or, in analysis-only mode, the judgment itself — and its thread is then resolved. Only Codex's own threads are closed that way; a human's stays open for [fix-review](./fix-review.md).

The PR description it writes is itself a deliverable: a plain-French summary, one bullet per ticket, and a short list of hand-runnable smoke tests — plus a ready-to-paste Claude Code prompt so a reviewer can have the PR explained to them.

## Where it fits

`ship` is the batteries-included tail of the main chain — it collapses `implement → code-review → PR → controlled feedback` into one invocation:

```txt
grill-with-docs → to-spec → to-tickets → ship
```

Its key neighbours are [implement](./implement.md), the single-session build step it orchestrates once per ticket, and [fix-review](./fix-review.md), which takes over when **human** review comes back on the PR — `ship` handles CI and Codex only, under the policy you selected. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.
