---
name: qa-path
description: "Write a guided test path for a whole project, a branch, or one feature: journeys a tester walks through the app in its own words, each with numbered steps, what they should observe, and numbered questions to answer back. Markdown in the project, rendered as a Witify document when it goes to the client."
disable-model-invocation: true
---

# QA path

Write the document a human walks the app with to confirm it does what was asked and fits how they work. The deliverable is a **path**: ordered journeys (*parcours*) through the app, each with numbered steps in the interface's own words, the behaviour the reader should observe, and numbered questions they answer back by email or in a Word document. It is written for a reader who never sees the code: the client's team by default, or the Witify tester before a delivery.

The path is not a bug hunt, and it says so. The team tested the app before handing it over; the path shows the app in situations the reader knows and brings back what to adjust before go-live. A difference in either direction is what it collects: the app does not behave as described, or the described behaviour does not match the reader's practice.

The document carries only what the reader does. **One page first**: the first page says what to do and what changed; everything after it is a path to walk or a reference to consult. What you learned along the way and the reader does not need (the data to clean up, the defects you suspect) goes to its own place (section 4 and section 7), never into the path.

## 1. Scope

Decide the scope from the invocation; never ask which it is.

- **Project** — no argument while on `dev` or `main`, or the user names the whole app or a version ("version 1", "the whole project"). The path covers everything the version delivers, following the life of the app's main record from its creation to its last stage.
- **Branch** — a branch, PR, or fixed point as argument, or no argument on any other branch. The change is `git diff <base>...HEAD` (three-dot, against the merge-base), where the base is the branch the PR targets, else `dev`, else `main`. Confirm the base resolves (`git rev-parse <base>`) and the diff is non-empty before anything else; a bad ref or an empty diff stops here. The path covers what the change adds or alters, plus the neighbouring screens it touches, so a regression shows up.
- **Feature** — a ticket id or URL, or a feature named in words. Locate it by its domain words across routes, controllers, pages, and components. The path covers the feature as it exists now, whichever commits built it.

The **audience** is the client's users unless the user says the path is for the team. Same shape either way: for the team, every observation carries a checkbox and the questions keep only what a tester must judge.

## 2. Sources

Write from two things only: the requirements as written, and the app as it is. Never from memory of what an app of this kind usually does.

**The requirements.** The spec lives on the tracker: **ClickUp** by default, **Linear** when the user or the repo's agent instructions (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`) say so, reached over MCP (`clickup_get_task` plus `clickup_get_task_comments`; `get_issue` plus `list_comments`). Find it in this order: the ticket the user passed; ticket references in the commits of the diff; the PR body; a spec under `docs/` or `specs/` matching the branch or feature; the parent ticket's description and comments, where `/to-tickets` keeps the decisions a set shares. If a spec reference points at a tracker whose tools are not among your available tools, stop: say so and tell the user to add the MCP server and sign in (see "Add the tracker's MCP server" in the `witify/skills` README) rather than guessing at the spec. With no spec reference at all, write from the app and say in the report that no requirements were available to trace against.

**The app as it is.** Routes and navigation (menus, tabs), pages and components, translation files, policies and roles, models and their computed values, jobs, notifications, generated documents, reports, and the import or migration scripts when the app replaces a legacy system. Read the domain model (`CONTEXT.md`, the README) for the vocabulary. For a project, delegate the inventory of each area to a read-only sub-agent (screens, labels, rules, roles, side effects), then write the document yourself so it reads in one voice.

**Labels are facts.** Every menu, tab, button, field, status, and message named in a step is confirmed in the templates or translation files before it is written. Never name a control the screen does not have; a label that cannot be confirmed is written and marked `À confirmer`. When the app runs locally and a browser tool is available, walk each path once and correct any step that does not match the screen.

**Numbers are facts.** Record counts, migrated totals, dates, and amounts come from the import report, a query against the seeded or migrated database, or the spec. A number that cannot be sourced is written `À confirmer`, never estimated.

**Automated tests** tell you what is already covered. The path does not restate unit-level assertions, but it always walks the critical happy path: the reader must see it work.

## 3. The paths

Paths follow the **life of the main record**, in order, and each uses what the previous one created: create the client, open what it holds, start the first dossier, move it to its next stage, close the cycle, then run the daily work (search, statuses, lists, reports). A project gets four to eight paths; a branch or feature one to three, placed where they fall in that life. Open on a fictitious record ("Test <Client> inc.") so no real data is touched; close on a real record the reader knows wherever comparing against reality is the point (a computed total, a migrated dossier).

Each path, lettered A, B, C…:

- **Title and objective.** An imperative title ("Créer un client") and one sentence saying what the reader will have at the end.
- **Étapes.** Numbered, one action each, in the imperative, naming the control as the screen shows it (« Nouveau client », onglet « Cautions »), with the data to enter stated concretely (two contacts, a limit starting next month, a credit premium). Four to eight steps, each one line.
- **Ce que vous devriez constater.** One line per intended behaviour the steps produce, 20 words at most: what appears, what is computed and from what, what is refused and how, what is sent or generated. Each line traces to a requirement, and the requirements' unhappy paths are here too: a validation, a refusal by role, an alert that warns without blocking. This block is the test; the reader reports any line that differs. Five to eight lines.
- **Questions pour vous.** Two or three, numbered with the path letter (A1, A2), on fit with the reader's practice and on the decisions that could have gone either way. When a decision needs its why, the question carries it in one sentence. Never "did it work": the observations already cover that.

The before and after of a path is not restated under it: *L'essentiel* (section 4) already says it.

**Cover every requirement.** Keep a private map from each requirement in scope to the path and line that exercises it. Roles get their own step or path when behaviour differs by role. A requirement with no manual trace (a nightly job, a calculation with no screen) gets an observation of its visible effect, or is listed in the report as not walkable.

## 4. The document

A **project** path is a full guide, in this order:

1. **Cover**: title, the app and the version presented, prepared for, prepared by, date.
2. **Comment utiliser ce document**: five lines. The three moves with their time (read, walk, answer), what the paths are for, what they are not. No table of contents: the rendered document carries its own.
3. **L'essentiel en une page**: what the version delivers, with the sourced numbers; what stays the same, in one line; what changes, six items at most, each a bold title and two sentences (before, now, and the why when there is one). This page is the whole "what changed" of the document: nothing restates it further down.
4. **Le vocabulaire** (only when a legacy system is replaced): **one table** of the real changes, columns *Avant*, *Maintenant*, *Ce qui change*, the last one a few words. A row is earned by a notion that is new, one that is gone, a label that now names something else, two things merged into one or one split in two, or a thing that moved to another screen. A label written in full, an abbreviation expanded, an accent or a capital added, a shortened label, or the same thing on the same screen is not a change and gets no row. Twenty to thirty rows; a table that grows past that is listing labels, not changes.
5. **Ce qui viendra plus tard**: what is deferred to the next version, one line each, so nobody looks for it.
6. **Les parcours**, as in section 3, preceded by a one-table overview (letter, title, what it covers).
7. **Vos données** (only when data was migrated): one table of the known records to open and what to compare on each, one line per record. The data cases to settle together (records without an owner, duplicates, empty numbers, with their counts) are **a separate document**, `qa/<scope-slug>-donnees.md`, with the same reader and the same style: one line in *Vos données* announces it. It is rendered alongside the path when the path is.
8. **Vos réponses**: how to answer (email or Word, question number then answer, one example), and three closing questions: what pleases most, what would prevent daily use, whether the version is ready for go-live.
9. **Annexe**: every question, grouped by path, ready to copy.

A **branch** or **feature** path is the short form: a title block, *Ce qui change* (before, after, why, and what is deferred, in bullets), the paths, and *Vos réponses* with its appendix.

**Budget.** A project path is 5 000 words at most before the appendix (4 000 with fewer than six paths); a branch or feature path 1 200. A step, an observation, or a line of a table is one line; a question is one sentence, two when it carries its why; an item of *L'essentiel* is two sentences. When the draft is over, cut until it holds: a restated change, an observation that lists a feature instead of a behaviour, a fourth question, a vocabulary row that is only a label. Count words, not punctuation (guillemets and table pipes are not words), and report the count:

```bash
awk '/^## .*Annexe/{exit} {print}' qa/<scope-slug>.md | tr -s ' ' '\n' | grep -cE '[[:alnum:]]'
```

## 5. Language and style

Write in the language of the app's interface. Witify's clients read French, so the path is in French unless the interface is English only. Run the `/witify-writing-style` skill and apply it to every sentence: vouvoiement, one idea per sentence, no dashes, no semicolons, Québec numbers and dates, the preferred French terms. No code reaches the reader: no identifier, file path, table name, route, or HTTP verb. The app's objects are named as its screens name them.

## 6. Output

Write the Markdown to `qa/<scope-slug>.md` in the project (`qa/version-1.md`, `qa/WIT-42-stripe-webhook-retry.md`), creating the folder if needed, and never commit it: the user decides whether it lives in the repo, the PR, or the ticket. When the user asks for it on the PR or the ticket, post it there (`gh pr comment`; a comment on the ticket over MCP).

When the audience is the client, or the user asks for a document, render it with the `/witify-docx` skill: the Markdown is the content, the cover values come from section 4, and the Table des matières is `oui` for a project path.

## 7. Report

Close with: the scope and its base; the requirements source (ticket ids, spec files) or that none was available; the paths, letter and title; requirements not walkable and why; labels and numbers marked `À confirmer`; the word count against the budget; the defects you suspect from walking the app, for the team, which the path never carries; where the files are (the path, the data document when there is one), and whether a document was rendered.
