Quickstart:

```bash
npx skills add witify/skills --skill=sentry-fix
```

```bash
npx skills update sentry-fix
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/sentry-fix)

## What it does

`sentry-fix` takes a Sentry issue from the error to a reviewed PR: it reads the issue, finds the cause, reproduces the error in a test that fails, fixes it, then files the ClickUp task, commits, opens a dedicated PR, and resolves the issue in Sentry with a comment pointing at the PR.

It exists for one reason the code alone does not show: the Witify client portal tells each client which errors Witify fixed, and it finds a fix only through a commit on the default branch whose message carries `Fixes <SHORT-ID>`, inside a merged PR. Forget that line and the fix is invisible to the client. The skill makes that line non-negotiable and avoids the traps around it: the short ID placed after a `-` in a branch name, a squash merge that drops the line, a fix pushed straight to `dev`, a fix stacked on another branch.

## When to reach for it

Type `/sentry-fix`, or the agent reaches for it automatically when a sentry.io link or a Sentry short ID shows up, or when you ask it to fix a Sentry error.

It stops at one checkpoint before anything leaves your machine: you see the cause, the fix, the red-then-green test, and the branch, commit, task, and PR it is about to create, and nothing is written to ClickUp, GitHub, or Sentry until you say go. For PR review comments that come back afterwards, use [fix-review](./fix-review.md).

## Prerequisites

The Sentry MCP server and the tracker's MCP server (ClickUp by default, Linear when the project says so) connected in the session, and an authenticated `gh` CLI. Without the Sentry or tracker tools, the skill stops and says which one to add.

## The `Fixes` line

The **`Fixes <SHORT-ID>` line** in the commit message is the only link that survives every merge method. The branch name can carry the ID too, right after the `/` (`fix/acme-erp-22v-order-copy-CU-86abc123`), but that only helps when the PR is merged with a merge commit. The PR description matters as well: the portal's AI writes the client's text from it, so its context section describes what the user lived, not the stack trace.

## It's working if

- The fix commit ends with `Fixes <SHORT-ID>` and a `ClickUp: CU-<id>` trailer.
- The new test failed with the Sentry error before the fix and passes after.
- One PR per fix, based on `dev` (or the default branch for a hotfix), with the ClickUp task and the Sentry issue linked at the top.
- After the merge reaches the default branch, the intervention appears in the client portal.

## Where it fits

A reach-for-it-anytime standalone for maintenance work. It does what [ship](./ship.md) does for planned tickets, for an error Sentry reported instead, and its PR is reviewed like any other: [fix-review](./fix-review.md) works the comments that come back.
