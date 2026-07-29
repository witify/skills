Quickstart:

```bash
npx skills add witify/skills --skill=fix-review
```

```bash
npx skills update fix-review
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/fix-review)

## What it does

`fix-review` takes a GitHub PR with review comments on it and works every open comment to a conclusion — a fix committed and pushed to the PR branch, an answer, or a reasoned push-back — then replies to each one with an explanation and a link to the commit that addressed it. It never marks a thread resolved: the reply gives the reviewer everything they need to re-check, and closing the thread is their acknowledgment to give, not the agent's.

It reads all four comment surfaces a PR has — inline review threads, review summary bodies, top-level conversation comments, and bot comments — so nothing a reviewer wrote falls between the cracks.

## When to reach for it

You invoke this by typing `/fix-review` — the agent won't reach for it on its own, because it pushes commits to a shared branch and posts replies your colleagues will read.

Reach for it when a PR of yours has come back from review and you want the comments worked through. Run it from the PR's branch, or pass a PR number/URL and it checks the branch out (only over a clean working tree). For producing a review rather than consuming one, use [code-review](./code-review.md) — the two are siblings on opposite sides of the review exchange.

## Prerequisites

A GitHub-hosted PR and an authenticated `gh` CLI. No issue-tracker setup is needed — the comments themselves are the work list.

## Every comment reaches a conclusion

The defining move is triage into buckets, where **ambiguous is actionable** — an open thread on an open PR is unfinished business, never silently skipped:

- **Skip** only what's genuinely settled: resolved threads, asks a reply already handled, or an explicit human agreement to defer — acting there would override a decision people already made.
- **Questions** get an answer in the thread, not a diff.
- **Wrong suggestions** get a push-back reply instead of a fix — but the bar is concrete evidence of breakage, never taste, because implementing a reviewer's bad idea and stamping it "fixed" is the worst thing this skill could do.
- **Everything else gets fixed** — one commit per logical concern, so each reply links the commit that actually contains its change.

Before pushing it runs the repo's checks scoped to what changed and iterates until green; replies are posted after the push, each written in the language of the comment it answers, and the run ends with a report of what was fixed, answered, pushed back on, and skipped (with reasons).

## It's working if

- It refuses to switch branches over a dirty working tree, and aborts on a closed or merged PR.
- Skips are justified in the final report — nothing disappears without a stated reason.
- Each "fixed" reply links a commit that is already on the remote, and no thread gets resolved.
- Push-backs are rare and evidence-based, and surfaced prominently for you to arbitrate.

## Where it fits

`fix-review` is a chain step just past the end of the main build chain — after `implement → code-review` produces a PR and human review comes back, it closes the review loop:

```txt
… → implement → code-review → (PR reviewed by humans) → fix-review
```

Its closest neighbour is [code-review](./code-review.md), which judges a diff before it ships, where this skill services the comments reviewers left after. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.
