---
"witify-skills": minor
---

New `sentry-fix` skill (model-invoked, fires on a sentry.io link or a Sentry short ID). It takes a Sentry issue to a reviewed PR: it reads the issue, finds the cause, reproduces the error in a test that fails without the fix, fixes it, then, after your go, files the ClickUp task, commits with `Fixes <SHORT-ID>`, opens one PR per fix, and resolves the issue in Sentry with a comment pointing at the PR. The `Fixes` line is what makes the fix appear as an intervention in the Witify client portal, so the skill enforces it and explains the traps that hide a fix from the client: the short ID after a `-` in a branch name, a squash merge that drops the line, a fix pushed straight to `dev`, or a fix stacked on another unmerged branch.
