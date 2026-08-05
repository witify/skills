---
name: sprintify-sync
description: Sync the latest sprintify base code for one feature area (Herald notifications, audits, confirm-request, …) from the ../sprintify reference repo into the current project — backend, frontend, and tests — without introducing breaking changes.
disable-model-invocation: true
---

# Sprintify Sync

Every sprintify-derived project forked the base code at some point and has drifted since. The base-code skills (`/audits`, `/authorization`, `/confirm-request`, `/jobs-development`, `/notification-development`, `/translations`) check applicability first and skip themselves when the fork predates the feature they document. This skill closes that gap: it brings the project's copy of **one feature area** up to the latest sprintify base code, so the corresponding skill fully applies.

Code flows **from sprintify into the project, never the other way**. Project-only files are never deleted, and project customizations are merged around, not overwritten.

## Process

### 1. Scope the sync

The argument names a base-code skill or feature area (e.g. `/sprintify-sync notification-development`, `/sprintify-sync audits`). No argument: ask which area to sync.

Anchor paths per area — starting points, **never** an exhaustive list:

| Area | Sprintify anchors |
| --- | --- |
| notification-development | `modules/Notification/`, `modules/NotificationPreview/` (incl. `Herald/`) |
| audits | `modules/Audit/`, `src/Support/Audit/`, audit display components under `resources/js/` |
| authorization | `src/Support/Controller/`, `src/Support/Resource/`, `resources/js/components/Gate*.vue`, `resources/js/stores/permissions.ts` |
| confirm-request | `src/Support/Http/Confirmation/`, the `resources/js/services/http` replay interceptor, the `modules/Account` confirm endpoint |
| jobs-development | base job support classes under `src/Support/`, `config/horizon.php` conventions |
| translations | `lang/` layout, shared Vue/Laravel JSON files, their loading code |

Complete the picture from two sources: the target skill's `SKILL.md` (its Key Classes / referenced paths) and the actual sprintify tree (`ls`, `grep` for the namespaces involved). A module's `vue/`, `lang/`, `routes/`, `Tests/`, and its `database/migrations/` entries are part of the area — backend, frontend, and tests always travel together.

### 2. Locate and refresh the reference repo

- Look for the sprintify repo at `../sprintify` relative to the project root. Missing? Ask the user where it lives; never guess another sibling.
- **Confirm with the user before touching it**: you are about to `git checkout dev && git pull` in their sprintify clone.
- If `git status --porcelain` shows a dirty tree in sprintify, stop and let the user decide — never stash or discard someone else's work.
- Record the branch sprintify is currently on, then check out `dev` and pull. Restore that original branch when the sync ends, success or not.

### 3. Map the gap

Diff every related path between sprintify and the project, and sort each file into:

- **Missing** — exists in sprintify, absent in the project. Copied whole.
- **Diverged** — exists in both but differs. Read both sides; separate upstream improvements from project customizations.
- **Project-only** — local files with no sprintify counterpart. Left alone.

Then widen beyond the file tree:

- **Call sites** — grep the project for usages of APIs the new code removes or renames (e.g. an old `Preview` class replaced by `Herald`). Every stale call site is part of the gap.
- **Schema** — find the sprintify migrations behind the area's tables and compare against the project's actual schema/migrations.
- **Dependencies** — composer/npm packages the new code imports that the project lacks.
- **Registration** — service providers (`bootstrap/providers.php`), route files, enum registries (e.g. `Modules\Notification\Notifications`).

Present the plan — files to copy, files to merge, call sites to migrate, migrations to create, packages to add — and **get the user's approval before writing anything**.

### 4. Apply

- Copy missing files verbatim, keeping the same paths.
- For diverged files, merge sprintify's changes **into** the project's version: upstream improvements come in, project-specific behavior stays. When the two genuinely conflict, ask.
- Never edit a migration that has already run. Schema the area needs lands as **new** dated migrations in the project.
- Adapt copied code that references sprintify modules the project doesn't have (e.g. `Architect`, `Comment`): strip or stub those seams; don't drag in unrelated modules.
- Migrate every stale call site found in step 3 to the new APIs.
- Register what the area needs: providers, routes, enum cases, frontend imports.

### 5. Verify — no breaking changes

- Run the area's tests plus every project test touching the changed code; then the project's static analysis (larastan) and frontend build/typecheck.
- A failure introduced by the sync: fix it and rerun until green. A failure that predates the sync: note it in the report and leave it.
- Re-run the target skill's applicability check (e.g. `modules/NotificationPreview/Herald/` exists) — the sync isn't done until it passes.

### 6. Restore and report

- Restore sprintify's original branch.
- Report: files copied, files merged (with what was preserved), call sites migrated, migrations created, packages added, test/analysis results, and any pre-existing failures left alone.
- Point the user at the now-applicable skill for their next change in the area.
