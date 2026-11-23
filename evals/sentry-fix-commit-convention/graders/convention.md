---
type: llm
---
PASS only if all of these hold:
1. The commit message has a line `Fixes ACME-ERP-22V` on its own (the short ID verbatim, not inside another word) and a `ClickUp: CU-86abc123` trailer.
2. The branch is either `fix/acme-erp-22v-<slug>-CU-86abc123` (short ID right after the `/`) or `fix/<slug>-CU-86abc123` (no short ID), with a slug of two to four kebab-case words naming the change.
3. The reply explains that the `Fixes` line in the commit is what lets the client portal link the fix to the Sentry issue.

Stopping because the Sentry or ClickUp MCP server is not connected is fine, as long as the branch and the commit message are still given.

FAIL if the short ID appears in the branch name after a `-` (for example `fix/order-copy-acme-erp-22v`), if the `Fixes` line is missing or only in the PR description, or if the reply claims a commit, push, or PR was made.
