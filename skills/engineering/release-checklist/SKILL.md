---
name: release-checklist
description: "Write the go/no-go checklist for a production deployment, whether a cutover from a legacy system, the launch of a new app, or the release of a big feature: chronological steps owned by the dev team, blocking criteria with thresholds, the decision rule, witness records, and a first draft of every email and plan, complete from one prompt."
disable-model-invocation: true
---

# Release checklist

Write the checklist the team walks to put something in production and decide, on the evening itself, whether it stays there. The deliverable is a **go/no-go**: the steps in chronological order from the weeks before to the weeks after, each owned by one person; the **criteria** the deployment must meet, each with a threshold and the place where its result is read; the **decision rule** that turns the criteria into go, retry, or no-go; and a first draft of everything that has to exist on the day (the rollback plan, the emails, the list of what the client must hand over). It comes out of one prompt complete: decide, draft, and mark what you could not source `À confirmer`, so a human reviews a finished document instead of answering questions.

The checklist carries only what the person running the day does: every item is a box to tick. What you learned along the way and nobody ticks has its own place, never a line inside a phase: a data case to settle with the client goes to the data document (section 5), a defect you suspect in the code goes to the closing report. The checklist never asks for a code change.

The checklist is a dev document. Every step belongs to Witify unless nobody else can do it. The client appears only for the actions that are theirs by nature (freeze their old system, export their data, choose the date, name their on-call), and those actions are also gathered in one place so they can be sent in one message.

## 1. Context

Three contexts, decided from the invocation and the repo, never by asking. The user's words win; otherwise read the signs.

- **Cutover** (bascule): a new app replaces a legacy system and its data comes across. Signs: import or migration commands, a `legacy` folder, an import readme, a vocabulary mapping in the domain model. Day X is a freeze of the old system, an export, an import, and a decision the same evening.
- **Launch** (lancement): a new app goes to production for the first time with no data to carry over. Signs: no production deploy target yet, no release tag, seeds instead of imports. Day X is the first deploy plus everything a first production needs to exist.
- **Release** (mise en production): a big feature lands on an app already in production. Signs: a production deploy target exists and the invocation names a branch, a PR, a ticket, or a feature. Day X is a deploy whose risk sits in migrations, backfills, and the screens around the change. The change is `git diff <base>...HEAD` against the branch the PR targets, else `dev`, else `main`; a bad ref or an empty diff stops here.

Within a context, keep only the phases, items, and criteria the project earns: a release with no migration has no backfill step, a launch with no employees has no training.

## 2. Sources

Write from the repo and its history, never from what deployments of this kind usually need.

- **The procedure as written**: the README and any import, deploy, or runbook document; the deploy workflow and its target branches; the server (Forge, the `deploy` branches, `.env.example`); the migrations of the diff and whether their `down()` is real; the scheduled jobs, queues, mail transport, storage, and third-party services the change touches.
- **The requirements**, when a ticket id or URL is passed or referenced in the commits or the PR body: **ClickUp** by default, **Linear** when the user or the repo's agent instructions (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`) say so, over MCP (`clickup_get_task` plus `clickup_get_task_comments`; `get_issue` plus `list_comments`). If a reference points at a tracker whose tools are not among your available tools, stop: say so and tell the user to add the MCP server and sign in (see "Add the tracker's MCP server" in the `witify/skills` README) rather than guessing at the requirements. With no reference, write from the repo and say so in the report.
- **The measurements.** Numbers are facts: durations and counts come from an import log, a rehearsal run, a CI run, or a query against the staging database. A number with no source is written `À confirmer`, never estimated.
- **The data**, for a cutover: the import's own logs (ignored rows, unlinked paths, counts per table) name the rules that can go wrong, and the witness records are chosen among the real records that exercise those rules. Query the staging database when it is reachable.
- **The test path**: a path under `qa/` written by `/qa-path` supplies the journeys of the smoke test. Reuse its letters and steps rather than writing new ones.

For a project-sized inventory, delegate the reading of each area to a read-only sub-agent and write the document yourself, in one voice.

## 3. The checklist

Chronological, phase by phase, keeping the phases the context earns. Each phase opens with one or two sentences on what it secures and the line **Terminée quand :** with its completion criterion. Each item is a checkbox (`- [ ]`) on one line, 20 words at most: a bold lead word, the action in the imperative, the owner in a tag when it is not Witify (« (MP2B) »), and the detail that makes it checkable (the file to look for, the command, the value to compare). The why of an item is not written; when a reader needs it, it lives in the criterion the item serves.

1. **Fiche du jour X**, first, after two lines saying what day X is: a two-column table of the values the day depends on (date of day X, freeze hour, decider, on-call for day 1, the measured durations, the limit hour of the window, the production server and URL), each `À confirmer` until sourced, bare: the commentary on why a value is unknown goes to the report.
2. **Préparation**, the weeks before: date and hour; the decider; the criteria validated with the client; the rollback plan; the witness records chosen and captured before the freeze; the production server checked against what the procedure needs (binaries, memory, disk, `tmux`); the production environment variables; outbound mail tested from production into a real mailbox; the decisions that must be made once (where a manual mapping happens, what the import erases); the drafts written.
3. **Répétition**: the full procedure run on the production server with staging data (cutover, launch), or the deploy of the branch on staging over a fresh production copy (release). It measures the durations the window is built from, and it leaves no configuration behind that must survive.
4. **Formation**, only when users change tool or see the change: recent data in staging first, the session, a trial period, a question channel kept open after the day.
5. **Jour X**: the freeze and export (cutover: close the old system, verify its lock file is gone, compact, export the database and the document share with their structure intact, lock the old system, copy to the server outside the deployed folder), or the deploy (launch, release: backup first, maintenance mode when a migration locks tables, deploy, migrate, backfill, caches warmed, queues restarted).
6. **Importation** (cutover): the commands in the readme's order in one code block, run in `tmux`; stop at the first failure and restart from the clean state; rollback when the window is passed. The behaviour of the import (transactions, memory, timeouts) is one line each, only where it changes what the operator does.
7. **Vérification et tâches d'après**: witness records compared (the method is written once, in the witness section); the admin account and roles recreated when the import removes them; the manual mappings done; the critical path walked on a test record then deleted; the health page, queues, and error tracker read; a backup taken right after the last successful step; then the **decision**. Data cleanup (placeholder users, duplicates, records to settle with the client) is one item pointing at the data document of section 5.
8. **Communication et jour 1**: the email sent only after the go, everyone's first login confirmed, the old system readable, the on-call named with a checkpoint at the end of day 1. For a release, only what users notice is communicated.
9. **Après**: the old system read-only for a stated period then archived; the data copies on the server deleted or secured by a named person on a date; the logs kept with the backup; the first week's monitoring (queues, failed jobs, error tracker, scheduled jobs).
10. **Critères de go/no-go** (section 4).
11. **Dossiers témoins** or **Parcours de vérification** (section 5).
12. **Annexes**: the drafts (section 6), then the reference tables and commands that an item cites and nobody reads in sequence: the expected counts per table, the commands to validate (`tinker` snippets), kept out of the phases.

**Budget.** A cutover checklist is 3 000 words at most before the annexes; a launch or a release 1 500. An item is one line; a phase intro is two sentences; a criterion row names the criterion, the threshold, and the source in a few words each; a witness row says what to verify in one line and the reason in four words. When the draft is over, cut until it holds: an item that explains itself, a rule stated twice, a table consulted rather than read. Count words, not punctuation, and report the count:

```bash
awk '/^## .*Annexe/{exit} {print}' qa/release-checklist-<scope-slug>.md | tr -s ' ' '\n' | grep -cE '[[:alnum:]]'
```

## 4. Criteria and the decision rule

A criterion is observable by one person on the evening, from one source. Each row names the criterion, its threshold, and the source where the result is read (a command's output, a CSV, the user list, a mailbox, the clock), each in a few words. Thresholds are proposals: say in the section that the hours and minutes are examples to confirm with the client. A table a criterion cites (the expected counts per table) sits in the annex, the row names it.

**Blocking** criteria, every one needed for a go: the procedure finished without error; counts per table match the source (100 % on the main tables, any gap explained by a log line); every witness record matches field by field; an administrator can log in; the password-reset email reaches a real mailbox within minutes and outside spam; every active user has a real email; the critical happy path works end to end in production (one test record created, its document generated, then deleted); the window is respected; a dated backup exists after the last verification. For a release: migrations applied and reversible or backed up, the feature's happy path and its neighbouring screens, no new failed jobs, error rate unchanged.

**Non-blocking** criteria create a follow-up task instead of a no-go: coverage that can be completed on day 1 (templates mapped, remaining links made by hand), ignored rows all explained by a reason already seen at the rehearsal, the old system locked before users arrive.

The **decision rule**, applied in order and without exception:

- **Go**: every blocking criterion passes. The communication goes out.
- **Nouvelle décision**: one blocking criterion fails and the fix takes less than a stated time (thirty minutes) inside the window. Fix, verify again, decide again.
- **No-go**: every other case. The rollback plan applies: the old system is reopened for writing and users work there the next day (cutover); the app stays unpublished (launch); the previous release is redeployed and the pre-deploy backup restored when a migration is not reversible (release). The new date is set within the week.

## 5. Witness records and verification paths

For a **cutover**, choose ten to fifteen **witness records** (dossiers témoins) among real records, each covering one rule of the import that can go wrong: the most active record of the year (what users open first on day 1), the longest chain of linked records, a cycle or multi-level hierarchy, truncated or free-text fields, duplicate codes, a shared record with several owners, a counter or numbering sequence (the next number proposed must follow the last issued), a rare type, a record still open at the moment of the freeze, the entity with the most linked items, and a user with no email in the source. For each: its name and source identifier, what to verify in one line, and the reason in four words. The comparison method is written once, here, and nowhere else: screenshots of each record in the old system before the freeze, compared field by field after the import, each gap noted with record, field, old value, new value, and a gap explained by the import log is not a failure. The phases and the criteria refer to this section instead of restating it.

The data cases the client must settle (records without an owner, duplicates, placeholder users, empty numbers, with their counts) are **a separate document**: `qa/<scope-slug>-donnees.md` written by `/qa-path` when it exists, else one you write in the same shape (one table: case, count, what to decide). The checklist points at it from one item and never lists the cases itself.

For a **launch** or a **release**, the verification is a short smoke test in production: the journeys of the `qa/` path when one exists, otherwise two to four numbered paths in the shape `/qa-path` writes (steps, what to observe), on a fictitious record created then deleted.

## 6. Drafts

Write every draft yourself, in the annex, with the values that depend on the day in brackets (`[date du jour X]`, `[personne de garde]`). The human edits; they do not start from blank.

- **The login or announcement email** to the users (cutover, launch; release only when users notice): what changes from which date, how to log in the first time (the password-reset path, link validity, what to do when the email does not arrive), the old system read-only until a date, where the old documents are, who answers questions, and the checkpoint meeting.
- **The message to the client** gathering every action that is theirs, each with its date: the export, the freeze, the date, the decider, the list of employees with their real emails.
- **The rollback plan**: the exact commands or actions in order, who runs them, and how long they take, derived from the deploy mechanism the repo actually uses.
- **The reference annexes**: the expected counts per table (source rows, imported rows, explained gap) and the commands an item says to validate, each under its own heading so an item can cite it.

## 7. Language and style

Write in French, Witify's working language, unless the project's team works in English. Run the `/witify-writing-style` skill and apply it to every sentence: one idea per sentence, no dashes, no semicolons, Québec numbers and dates. Commands, file names, and option flags stay in code spans, since the readers run them. The drafts of section 6 read as client text: no identifier, path, or command reaches the client.

## 8. Output

Write the Markdown to `qa/release-checklist-<scope-slug>.md` in the project (`qa/release-checklist-version-1.md`, `qa/release-checklist-WIT-42-stripe-webhook-retry.md`), creating the folder if needed, and never commit it: the user decides where it lives. When the user asks for a document, or the checklist goes to the client, render it with the `/witify-docx` skill: the title is « Liste de contrôle de la bascule », « du lancement », or « de la mise en production » by context, the subtitle names the transition, and the Table des matières is `oui`.

## 9. Report

Close with: the context and the signs that decided it; the sources read (readme, workflow, tickets) or that no requirements were available; the phases kept and the ones dropped, with why; the count of blocking and non-blocking criteria; the witness records or paths; every `À confirmer` in the fiche and the criteria, with why each is unknown; the defects you suspect in the code, for the team, which the checklist never carries; the word count against the budget; the drafts written; where the files are (the checklist, the data document) and whether a document was rendered.
