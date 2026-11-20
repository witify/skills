---
name: sentry-fix
description: Fix a Sentry issue end to end so the fix shows up as an intervention in the Witify client portal — read the issue, find the cause, reproduce it in a failing test, fix it, then file the ClickUp task, commit with `Fixes <SHORT-ID>`, open a dedicated PR, and resolve the issue in Sentry. Use when the user shares a sentry.io link or a Sentry short ID (like `ACME-ERP-22V`), mentions a "Sentry bug" or "Sentry error", or asks to fix, resolve, or look into a Sentry issue.
---

# Sentry fix

Witify's client portal shows each client the Sentry errors Witify fixed for them. It finds a fix through git only: a commit whose message names the issue's short ID, inside a merged pull request, on the default branch. A fix that misses this link is real work the client never sees. This skill runs the whole path from the Sentry issue to a reviewed PR, and its one non-negotiable is the **`Fixes <SHORT-ID>` line** in the commit message.

## How the portal links a fix to an issue

1. When an issue turns **resolved** in Sentry, the portal searches GitHub for commits whose message contains the short ID. GitHub's commit search reads the **default branch only** (`main` or `master`), so a fix counts once it is released there, not when it lands on `dev`.
2. The ID must stand alone, case-insensitive: **not preceded** by a letter, a digit, or `-`, and **not followed** by a letter or a digit.
3. The commit must belong to a **merged PR**. The earliest-merged PR containing it is the fix. The portal's AI writes the client's text from that PR's **title and description** and the commit messages, and dates the intervention at the merge.
4. A fix that reaches the default branch after the issue is resolved is caught by a daily job, for issues whose **last occurrence** is less than 14 days old. Past that window, an issue resolved before its fix is released never gets an intervention.

| Where the short ID is | Found? | Why |
| --- | --- | --- |
| Commit message: `Fixes ACME-ERP-22V` | ✅ always | The case the portal is built for |
| Branch `fix/acme-erp-22v-order-copy`, PR merged with a merge commit | ✅ | The merge commit reads `Merge pull request #… from witify/<branch>`; the ID follows a `/` |
| Branch `fix/order-copy-acme-erp-22v` | ❌ | The ID follows a `-` |
| Branch with the ID, PR merged by squash or rebase | ❌ | The branch name is not in any commit message |
| Squash merge whose message drops the `Fixes` line | ❌ | The only commit on the default branch no longer names the issue |
| `Fixes …` commit pushed straight to `dev` | ✅ but badly described | The only PR containing it is the generic `dev` → `master` release, so the client reads a text written from that release |
| Fix stacked on another unmerged branch | ⚠️ | Its PR carries the other fix's commits, so the portal can credit the wrong PR to one of the two issues |

## 1. Preflight

- **Sentry**: the Sentry MCP tools (`get_sentry_resource`, `get_issue_breadcrumbs`, `update_issue`) must be available. If they are not, stop and tell the user to add the server (`claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`, then `/mcp` to sign in).
- **Tracker**: ClickUp by default, Linear when the user or the repo's agent instructions say so, always over MCP. If its tools are missing, stop and point at "Add the tracker's MCP server" in the `witify/skills` README.
- **Repo**: the working tree is clean (`git status --porcelain` prints nothing); never stash or commit work you did not make. The app frames of the stack trace exist in this repo; if they do not, the issue belongs to another project, so stop and say so.
- **Base branch**: `dev` when the repo has one, else the default branch (`gh repo view --json defaultBranchRef`). A hotfix the user asks for goes on the default branch, and the report reminds them to bring it back into `dev`. Never base the fix on another unmerged branch. `git fetch` and start from the remote base.

## 2. Read the issue

Use `get_sentry_resource` on the link or short ID: title, culprit, first and last seen, event count, affected users, environment, release. Then read the latest event in full: stack trace, request (method, URL, payload), user, tags, and `get_issue_breadcrumbs` for what led to the error. When the issue has many events, compare a few to check they share one cause.

Copy the **short ID exactly as Sentry prints it**. Check it was not fixed already: `git log --all -i --grep=<SHORT-ID>`. If a fix exists, report it and stop.

## 3. Find the cause

Read the app frames, not the vendor ones, and follow the input from the request to the failing line. State the cause in one or two sentences, then:

- **Regression or old defect**: `git log -L` or `git blame` on the failing line.
- **Siblings**: the same defect elsewhere (other call sites, the same pattern in a sibling class). They are part of this fix.

If the evidence does not establish the cause, say what is missing. Never guess a fix.

## 4. Reproduce in a test (red)

Write a test that triggers the error through the most realistic entry point: the request from the event, the job, the command. Follow the repo's test conventions (`CLAUDE.md`, `AGENTS.md`, `.ai/`). Run it **without the fix**: it must fail with the error Sentry recorded (same exception, same message). A test that passes without the fix reproduces nothing, so rewrite it. When the error cannot be reproduced in a test (a third-party outage, an infrastructure fault), say why and write the narrowest test that protects the fix.

## 5. Fix (green)

Change the code at the cause, not around it: catching the exception higher up hides the error, it does not fix it. Fix the siblings found in step 3. Run the new test (green), the related tests, and the checks the repo's agent instructions list (linter, static analysis, formatter).

## 6. Checkpoint: wait for a go

Nothing has left the machine yet. Show the user, in one message:

- the cause and the fix, the test output red before and green after;
- the branch name, the commit message, the ClickUp task (title and list), and the PR title.

Then wait for an explicit go. The go covers steps 7 to 10. Without it, stop here.

## 7. ClickUp task

Reuse a task before creating one: the one the user gave, or one found by searching the tracker for the short ID. Otherwise create it in the project's maintenance list (ask once when it is not obvious which list). Title: what failed, in the user's words, suffixed ` (Sentry)`. Description in simple French:

```markdown
## Contexte
Ce que l'utilisateur faisait, ce qu'il a vu, quand.
- Sentry : [<SHORT-ID>](<url de l'issue>)
Régression ou défaut ancien.

## Mesures
Occurrences, utilisateurs touchés, première et dernière occurrence, environnement.

## Cause
En mots simples, sans code.

## Correctif
1. Ce qui change, en liste numérotée.

## Hors correctif
Ce qui n'est pas réglé ici, et pourquoi. Omis si vide.

+++ Notes techniques
Classes, méthodes, requêtes, test ajouté.
+++
```

## 8. Branch and commit

**Branch**: `fix/<short-id>-<slug>-CU-<task-id>`, all lowercase except the ClickUp prefix, with the short ID **right after the `/`**: `fix/acme-erp-22v-order-copy-CU-86abc123`. Without the ID: `fix/<slug>-CU-<task-id>`. Never put the ID anywhere else in the name. The `<slug>` is two to four words naming the change. On a workspace branch some tool created for you (Polyscope, `codex/…`), rename it in place with `git branch -m` before the first push.

**Commit**: the subject follows the repo's history (Conventional Commits, language). The body says the cause and the fix in a few lines, then ends with the trailers, one `Fixes` line per issue the fix covers:

```
fix: retry an order insert when its generated number was just taken

The ORD number is derived from MAX(id) and checked before the insert,
so an order created at the same time can take the same number. A
generated number is now regenerated and the insert retried.

Fixes ACME-ERP-22V
ClickUp: CU-86abc123
```

With Linear, the tracker trailer is `Linear: <ID>`. Before pushing, verify the message names the issue the way the portal matches it:

```
git log -1 --format=%B | grep -iE '(^|[^A-Za-z0-9-])<SHORT-ID>([^A-Za-z0-9]|$)'
```

## 9. Pull request

**One PR per fix**, from the branch to its base: `gh pr create --base <base>`. Title: the commit subject. The portal's AI writes the client's text from this description, so `Contexte` describes the impact as the user lived it. Body in simple French:

```markdown
## Contexte

Tâche ClickUp : [<titre>](<url>)

Sentry : [<SHORT-ID>](<url de l'issue>)

Ce que l'utilisateur a vu, quand, combien de fois. Régression ou non.

## Cause

## Changement

## Tests

- Nouveau test : sans le correctif, il reproduit l'erreur Sentry (`<erreur>`). Avec, il passe.
- Tests liés qui passent.

## Hors de cette PR

Omis si vide.
```

The Sentry link also keeps the short ID in the squash commit when the repo squashes with the PR description. Move the task to the list's in-review status when one exists; never invent a status.

## 10. Resolve in Sentry

Resolve each issue the fix covers with `update_issue` (`status: resolved`), and pass a `reason`, which Sentry posts as a comment: `Corrigé par <url de la PR> (tâche <url>).`

One exception: when the issue's **last occurrence is more than 7 days old** and the fix reaches the default branch only at the next release, the portal's catch-up window can close first. Then leave the issue unresolved, add the comment with `add_issue_note`, and add `Résoudre l'issue Sentry après la mise en production.` to the task's technical notes.

## 11. Report

Links to the task, the PR, and each Sentry issue, and whether each issue is resolved or waits for the release. Then the merge reminder for whoever merges:

> Au merge : commit de merge, ou squash qui garde la ligne `Fixes <SHORT-ID>`. L'intervention apparaît dans le portail quand le correctif arrive sur `<branche par défaut>`.

For a hotfix, add that the fix must be brought back into `dev`.
