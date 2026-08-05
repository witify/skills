Quickstart:

```bash
npx skills add witify/skills --skill=sprintify-sync
```

```bash
npx skills update sprintify-sync
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/sprintify-sync)

## What it does

`sprintify-sync` upgrades one feature area of a sprintify-derived project — Herald notifications, audits, confirm-request, authorization, jobs, translations — to the latest sprintify base code, copying backend, frontend, and tests together from the `../sprintify` reference clone. Code flows one way only, from sprintify into the project: project-only files are never deleted, diverged files are merged around your local customizations rather than overwritten, and nothing is written until you've approved the plan it presents.

It exists because forks drift. The base-code skills check applicability first and skip themselves on a fork that predates their feature; this skill closes that gap so they apply again.

## When to reach for it

You invoke this by typing `/sprintify-sync <area>` — the agent won't reach for it on its own, because it checks out and pulls branches in your sprintify clone and lands a large multi-file change.

Reach for it when a base-code skill reports the project predates its feature ("this project predates Herald"), or when you know an area's base code is stale and want the latest version. For working *within* an already-current area, use the matching base-code skill ([notification-development](./notification-development.md), [audits](./audits.md), …) — this skill upgrades the floor they stand on.

## Prerequisites

A sprintify-derived Laravel project, with the sprintify repo cloned as a sibling at `../sprintify` (it asks for the path otherwise). The sync pulls sprintify's `dev` branch, so the clone needs a clean working tree.

## The gap, mapped before it's touched

The defining move is mapping the **gap** before writing anything: every related file is sorted into missing (copied whole), diverged (merged, customizations preserved), or project-only (left alone) — then the map widens past the file tree to stale call sites on removed APIs, schema differences (landed as new dated migrations, never edits to run ones), missing packages, and unregistered providers or enum cases. The plan is shown for approval first.

The sync isn't done until it proves no breaking changes: the area's tests, larastan, and the frontend build run green, and the target skill's own applicability check passes. Sprintify's original branch is restored either way.

## It's working if

- It confirms before touching `../sprintify`, and stops on a dirty tree there instead of stashing.
- No file is written before you approve the mapped plan.
- Vue components, lang files, and tests arrive with the backend — never the backend alone.
- Schema changes appear as new migrations; existing migrations are untouched.
- The run ends with the previously-skipped skill's applicability check passing.

## Where it fits

`sprintify-sync` is a run-when-needed upgrade step underneath the sprintify baseline skills: they detect the drift and skip; it repairs the drift so they apply. Its neighbours are the base-code skills themselves — each names the applicability check this skill must make pass. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.
