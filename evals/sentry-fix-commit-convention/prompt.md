---
name: sentry-fix-commit-convention
description: Asked how it would commit and name the branch for a Sentry fix, sentry-fix puts `Fixes <SHORT-ID>` in the commit message and the short ID right after the `/` of the branch name.
tags: [sentry-fix, commit, branch]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
expected_outcome: The reply gives a commit message with a `Fixes ACME-ERP-22V` line and a `ClickUp: CU-86abc123` trailer, and a branch named fix/acme-erp-22v-<slug>-CU-86abc123 (or fix/<slug>-CU-86abc123), never with the short ID after a dash.
---
/sentry-fix

Don't fix anything yet. The Sentry issue is ACME-ERP-22V (order duplication fails with a duplicate order number) and the ClickUp task is CU-86abc123. Tell me exactly which branch you would create and the full commit message you would write, and why.
