# Issue tracker: Linear

Issues and PRDs for this repo live in Linear. Use the Linear MCP server for all operations.

**Workspace**: team `<TEAM>`, project `<PROJECT or none>`. _(Filled in by setup; all creates go here.)_

## Conventions

- **Create an issue**: `save_issue` in the team above; set labels at creation.
- **Read an issue**: `get_issue` (accepts the `ABC-123` identifier), plus `list_comments` for the discussion.
- **List issues**: `list_issues` filtered by team, label, and state.
- **Comment on an issue**: `save_comment`.
- **Apply / remove labels**: update the issue's labels via `save_issue`; create missing labels with `create_issue_label`.
- **Close**: `save_issue` moving the issue to the team's Done (or Canceled) state — look up state names with `list_issue_statuses`.

Reference issues by their Linear identifier (`ABC-123`) in commits and PRs so `code-review` can trace them.

## When a skill says "publish to the issue tracker"

Create a Linear issue in the workspace above.

## When a skill says "fetch the relevant ticket"

`get_issue` with the identifier, plus `list_comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** sub-issues as tickets.

- **Map**: an issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: a sub-issue of the map (create with the map as parent). Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: Linear's native **blocked by** relation between issues. Where the tooling at hand can't set relations, fall back to a `Blocked by: ABC-123` line at the top of the child description. A ticket is unblocked when every blocker is Done.
- **Frontier query**: list the map's open sub-issues, drop any with an open blocker or an assignee; first in map order wins.
- **Claim**: assign the issue to yourself — the session's first write.
- **Resolve**: comment the answer, move the issue to Done, then append a context pointer (gist + link) to the map's Decisions-so-far.
