---
"witify-skills": minor
---

`ship` and `to-tickets` now agree on one way to ship: a ticket set is always one branch and one PR, worked in blocking order. `to-tickets` no longer asks "split PRs or one PR?" and no longer sets a `single-pr` / `split-pr` label on the parent; the parent's title is simply written to be the PR title, and `ship` now uses it as such and hands every implement sub-agent the parent's description, where the set's shared decisions live.

`ship` also closes a few gaps. It waits at most 15 minutes per feedback wave for Codex and runs CI-only when Codex never reacts, instead of waiting forever on a repo without it. It stops on a dirty working tree rather than stash or commit work it did not make. Its commits follow the repo's own convention and always name the ticket, with review fixes marked `review:` as `fix-review` does. "Analysis only" is now defined: the tickets are still built and the PR opened, but every finding is judged and reported rather than applied. The concurrency rule no longer names a specific repo: `ship` reads the project's domain once per session, treats booking, inventory, sales, payments, queues, collaborative editing and public-crowd domains as ones where race-condition findings are worth fixing, and asks once when the domain is unclear. The README entries for both skills, which still described the old fix-policy question and three-wave loop, are brought in line.

Three plugin evals cover `ship`: it stops cleanly without a tracker MCP server, it never asks the user to choose a fix policy, and it names its branch `feat/<ticket-id>-<slug>`.
