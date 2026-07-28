# Issue tracker: ClickUp

Issues and PRDs for this repo live in ClickUp as tasks. Use the ClickUp MCP server for all operations.

**Workspace**: space `<SPACE>`, list `<LIST>`. _(Filled in by setup; all creates go here.)_

## Conventions

- **Create an issue**: `clickup_create_task` in the list above.
- **Read an issue**: `clickup_get_task`, plus `clickup_get_task_comments` for the discussion.
- **List issues**: `clickup_filter_tasks` scoped to the list, filtered by tag and status.
- **Comment on an issue**: `clickup_create_comment`.
- **Apply / remove labels**: triage labels are ClickUp **tags** — `clickup_add_tag_to_task` / `clickup_remove_tag_from_task`.
- **Close**: `clickup_update_task` moving the task to the list's closed status.

Reference tasks by their ClickUp task id or URL in commits and PRs so `code-review` can trace them.

## When a skill says "publish to the issue tracker"

Create a ClickUp task in the list above.

## When a skill says "fetch the relevant ticket"

`clickup_get_task` plus `clickup_get_task_comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single task with **child** subtasks as tickets.

- **Map**: a task tagged `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: a subtask of the map (`clickup_create_task` with the map as parent). Tags: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: ClickUp's native task dependencies — `clickup_add_task_dependency`, the child *waiting on* its blocker. A ticket is unblocked when every blocker is closed.
- **Frontier query**: `clickup_filter_tasks` over the map's open subtasks, drop any with an open waiting-on dependency or an assignee; first in map order wins.
- **Claim**: assign the task to yourself — the session's first write.
- **Resolve**: comment the answer, close the task, then append a context pointer (gist + link) to the map's Decisions-so-far.
