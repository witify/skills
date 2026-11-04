Quickstart:

```bash
npx skills add witify/skills --skill=pr-summary
```

```bash
npx skills update pr-summary
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/pr-summary)

## What it does

`pr-summary` writes the briefing a reviewer reads before opening the code of a GitHub PR, and posts it at the top of the PR description. Four short sections, all bullets: what the PR changes and why; the features to validate by hand, each with a priority (🔴 must look, 🟡 worth a look, 🟢 covered by tests, skip if pressed); a side-by-side before/after video of every visual change, with the sentence of what changed under it and a frame around the changed element; and the impacts to flag (breaking changes, migrations, config and env, permissions, jobs, dependencies). It shows rather than argues: a feature to validate is a path to click, a visual change is a video of the same clicks on both sides, a priority is a reason in a few words.

The briefing is assembled from the whole PR, not the description the author wrote: every changed file is read in full with its tests, the ticket is fetched when the tracker is connected, and the project's business rules say what was asked. What it leaves out is deliberate: no project reminder beyond one line, no glossary, no list of decisions, no reading order. A reviewer who wants that context asks the agent directly; the briefing stays readable in two minutes.

## When to reach for it

You invoke this by typing `/pr-summary` — the agent won't reach for it on its own, because it edits a PR description your colleagues will read.

Reach for it when a PR is ready for review and the reviewer should know where to look first: a large PR, a PR with visual changes worth seeing side by side, a PR that deviates from its ticket somewhere. Run it from the PR's branch, or pass a PR number/URL and it checks the branch out over a clean working tree. For judging the code rather than briefing its reviewer, use [code-review](./code-review.md).

## Prerequisites

A GitHub-hosted PR and an authenticated `gh` CLI. Screenshots need Claude in Chrome connected and the app reachable (a Herd-served Laravel project already is, at `https://<folder>.test`): the extension is the only way an image gets into the PR without a human, and it signs in with the test user the project seeds for local use. The recordings are merged side by side into an mp4 by a script the skill carries, which needs ffmpeg (`brew install ffmpeg`) and Pillow (`python3 -m pip install --user Pillow`); without ffmpeg the skill falls back to a side-by-side GIF with no dissolve. Without the extension the briefing ships without the image table and the report says so. The tracker's MCP server is optional: when it is connected the ticket supplies the *why*; when it isn't, the briefing ships without it and the report says so.

## Before and after

The defining move is the **before/after** video. For each screen the PR changes, the same path of clicks is replayed and recorded on the base commit first, then on the PR head with its migrations applied, in the same window and state. The order is deliberate: migrations only go forward in this skill, so a before taken after them would not be a before. The two recordings are laid side by side, « Avant » on the left and « Après » on the right, into one short video with a dissolve between states, which the PR plays inline with a scrubber. The video says what to look at: the sentence describing the change runs under it, and the changed element is framed on the final « Après » state. A new screen gets its before too, the index without the entry or the blank page at the address. Only a screen whose recording fails falls back to two stills, and the briefing says why.

GitHub's API cannot upload images, so the skill drops the files into the PR's edit form through Claude in Chrome to obtain `user-attachments` URLs, then cancels that edit and writes the description through `gh`. Nothing is left for you to drag in.

## Idempotent on the description

The briefing sits between two HTML markers at the top of the description; whatever the description held before stays below, intact. Re-running replaces the block and touches nothing else, so the author's notes and a `/ship`-written body survive.

## It's working if

- It stops on a branch with no PR, a closed PR, or a dirty working tree, and posts nothing.
- Every changed file ends up in a feature to validate, an impact, or stated plumbing.
- Most checks are green; every red or yellow one says why in a few words, and a deviation from the ticket is always red.
- The before recordings come from the base commit, not from the PR branch with the feature flagged off.
- Every screen has a side-by-side video with its caption, or two stills and a stated reason.
- A check the reviewer ticked stays ticked after a re-run.
- The description's previous content is still there below the briefing after the run.
- Skips are stated in the report: ticket not read, Claude in Chrome not available, app not reachable, screens not captured.

## Where it fits

`pr-summary` is a chain step between opening the PR and its human review: it prepares the reviewer the way [ship](./ship.md) prepares the PR, and it sits just before [fix-review](./fix-review.md), which services the comments the briefed reviewer leaves.

```txt
to-spec → to-tickets → ship → pr-summary → (PR reviewed by humans) → fix-review
```

Its closest neighbour is [code-review](./code-review.md), which judges the diff where this skill explains it.
