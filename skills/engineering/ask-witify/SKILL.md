---
name: ask-witify
description: Ask which skill or flow fits your situation. A router over the skills in this repo.
disable-model-invocation: true
---

# Ask Witify

You don't remember every skill, so ask.

A **flow** is a path through the skills. Most paths run along one **main flow**, and two **on-ramps** merge onto it. Everything else is standalone, or a vocabulary layer that runs underneath.

## The main flow: idea → ship

The route most work travels. You have an idea and want it built.

1. **`/grill-with-docs`** — sharpen the idea by interview. Start here when you **have a codebase**: it's stateful, retaining what it learns in `CONTEXT.md` and ADRs. (No codebase? Use `/grill-me` — see Standalone. Both run the same `/grilling` primitive; `grill-with-docs` is the one that leaves a paper trail.)
2. **Branch — can you settle every question in conversation?** If a question needs a runnable answer (state, business logic, a UI you have to see), detour through a prototype, bridged by **`/handoff`** in both directions (see Crossing sessions):
   - **`/handoff`** out, then open a fresh session against that file,
   - **`/prototype`** to answer the question with throwaway code,
   - **`/handoff`** back what you learned, and reference it from the original idea thread.
3. **Branch — is this a multi-session build?**
   - **Yes** → **`/to-spec`** (turn the thread into a spec), then **`/to-tickets`** to split it into tracer-bullet tickets, each declaring its **blocking edges**. On a local tracker that's one file per ticket under `.scratch/<feature>/issues/`, worked blockers-first by hand; on a real tracker the edges become native blocking links, so any ticket whose blockers are done can be grabbed — kick off **`/implement`** per ticket, **clearing context between each one** — or hand the whole set to **`/ship`**, which runs that loop for you: one implement sub-agent and one review sub-agent per ticket, then a PR to `dev` (plain-French summary + smoke tests). Before it starts, `/ship` asks whether feedback should be analyzed only, fixed at P1, fixed through P2, or fixed at every priority; it follows that policy for at most three PR feedback waves. Before publishing, `/to-tickets` also asks how the set ships — one PR for the whole feature, or one per ticket — and records the answer as a `single-pr` / `split-pr` label on the parent.
   - **No** → **`/implement`** right here, in the same context window.

   Either way, **`/implement`** builds each issue by driving **`/tdd`** internally — one red-green slice at a time — then closes out by running **`/code-review`**, a two-axis review (Standards + Spec) of the diff, before committing. Reach for **`/tdd`** on its own when you just want to build a concrete behaviour test-first without a full spec, and **`/code-review`** on its own whenever you want to review a branch or PR against a fixed point.

4. **When the PR is up and human review comes back** → **`/fix-review`** (`/ship` handles CI and Codex under its selected fix policy, replying to and resolving Codex's own threads; human comments belong to `/fix-review`). It works every open comment on the GitHub PR to a conclusion — fixes committed per concern and pushed, questions answered, bad suggestions pushed back on with evidence — then replies to each comment with a commit link. It never resolves threads; reviewers close their own. `/code-review` produces a review, `/fix-review` consumes one.

### Context hygiene

Keep steps 1–3 in **one unbroken context window** — don't compact or clear until after `/to-tickets` — so the grilling, spec, and tickets all build on the same thinking. Each `/implement` then starts fresh, working from the ticket.

The limit on this is the **smart zone**: the window (~120k tokens on state-of-the-art models) within which the model still reasons sharply. If a session approaches it before `/to-tickets`, don't push on degraded — `/handoff` and continue in a fresh thread.

## On-ramps

A starting situation that generates work, then merges onto the main flow.

- **Bugs and requests piling up** → **`/triage`**. It moves issues through triage roles and produces agent-ready issues, which **`/implement`** later picks up.

  Triage is only for issues **you didn't create** — bug reports, incoming feature requests, anything that arrives raw. Tickets that `/to-tickets` produced are already agent-ready, so **don't triage them**.

- **Something's broken** → **`/diagnosing-bugs`**. For the hard ones: the bug that resists a first glance, the intermittent flake, the regression that crept in between two known-good states. It refuses to theorise until it has a **tight feedback loop** — one command that already goes red on *this* bug — then fixes with a regression test. Its post-mortem hands off to **`/improve-codebase-architecture`** when the real finding is that there's no good seam to lock the bug down.

- **A huge, foggy effort — a greenfield project or a huge feature build, too big for one session** → **`/wayfinder`**, the most cognitively demanding flow here. When the way from here to the destination isn't visible yet, it charts a **shared map** of **decision tickets** on the issue tracker and resolves them one at a time — producing **decisions, not deliverables** — until the fog is pushed back and the way is clear. Where **`/grill-with-docs`** sharpens an idea you can hold in one session, wayfinder is for the idea you can't — and it's slower and denser, so save it for exactly that, never a well-scoped feature.

  When the map clears, **it hands off, it doesn't build**: merge onto the main flow at **`/to-spec`**, which collapses the map's linked decisions into a buildable plan, then `/to-tickets` and `/implement` as usual. Looping the map straight into `/implement` skips that collapse and throws the linked detail away — go straight to `/implement` only when the effort turned out genuinely small.

## Codebase health

Not feature work — upkeep.

- **`/improve-codebase-architecture`** — run whenever you have a spare moment to keep the codebase good for agents to operate in. It surfaces **deepening opportunities**; picking one _generates an idea_ you can take into the main flow at `/grill-with-docs`. It's the survey that finds the candidates; **`/codebase-design`** (below) is the bench you design the chosen one on.
- **`/witify-doctor`** — a **check-up** you validate item by item, run on a new machine, after a sprintify release, or when a repo feels out of step. Its checklist is split into **levels** by migration cost, and it treats one level per session, never skipping: level 0 is your machine (Claude Code / Codex memory and personal instructions off — we keep instructions in the repo, where every developer gets the same ones — plus the plugin and MCP servers in both harnesses); level 1 is hygiene (after-update checks that resolve, guidelines that point at real things, Boost published, the quality workflows present); level 2 diffs `.ai/guidelines/` and tooling against the latest sprintify with the repo's own rules flagged to keep; level 3 sizes each missing PHPStan rule by the files it would touch so you pick which to import; level 4 hands off — base code that predates a sprintify feature goes to **`/sprintify-sync`**, deploy branches to **`/migrate-deploy-branches`**. It diagnoses drift in the *guardrails*; those two repair drift in the *code*.

## Vocabulary underneath

Model-invoked references that run *beneath* the other skills — each the single source of truth for its material. Reach for them directly when the **reference**, not the process, is the problem; or let the skills above pull them in.

- **`/domain-modeling`** — sharpen the project's *domain* language: challenge a fuzzy term, resolve an overloaded word ("account" doing three jobs), record a hard-to-reverse decision as an ADR. It's the active discipline `/grill-with-docs` drives to keep `CONTEXT.md` a clean glossary.
- **`/codebase-design`** — the deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) for designing a module's *shape*: a lot of behaviour behind a small interface at a clean seam. `/tdd` and `/improve-codebase-architecture` both speak it.
- **`/frontend-development`** — Vue 3 + Tailwind patterns for building UI: reactivity after emits, sub-forms that emit copies, orphan validation errors, and responsive layouts — plus a scoped layer of sprintify app conventions (shared backend data, settings store, `resource_data`, `tabulation` tables). Fires on its own whenever `/implement`, `/tdd`, or `/prototype` touches Vue components or frontend forms.
- **`/sprintify-ui`** — the component catalog for projects built on the `sprintify-ui` library: every `Base*` component, its props, events and slots. Pairs with `/frontend-development`, which holds the **rules**, where this holds the **API** — reach here when the question is what a component accepts, there when it's which component to use. Dead weight in a project that doesn't depend on the package.

### The sprintify baseline

References for projects forked from **sprintify**, the Laravel starter every project begins as. Each one **checks the base code before applying itself** — a project forked from an older sprintify may lack the feature, in which case the skill falls back to core principles or skips and says so. They all defer to a project's own `.ai/skills/` copy when one exists (current forks ship these via Laravel Boost; the plugin copies serve the older ones). Dead weight outside a sprintify-derived Laravel project.

When one of them skips itself because the fork predates the feature, the upgrade path is **`/sprintify-sync`** (user-invoked): it pulls the latest `dev` in the `../sprintify` reference clone, diffs the feature area, and syncs the base code — backend, frontend, and tests — into the project without breaking changes, so the skipped skill fully applies.

- **`/authorization`** — policies, nested controllers, `canDo()`, and one-`<Gate>`-per-element on the frontend. The core rule: **authorization follows the route** — nested routes gate through the parent policy, standalone through the child's.
- **`/audits`** — model audit trails through the Audit module's staging API (`withAuditComment` → `save()`), readable labels, and the timeline display layer.
- **`/confirm-request`** — server-enforced "are you sure?" / password re-check dialogs before sensitive endpoints via `confirmRequest()`, with automatic frontend replay.
- **`/jobs-development`** — queued jobs on Redis + Horizon: idempotence, uniqueness, timeouts, and queue selection read from the project's own Horizon config.
- **`/notification-development`** — Herald notifications: explicit mail/database channels, builder content, previews, and per-channel user settings.
- **`/translations`** — where a translation key lives (PHP vs shared JSON), flat JSON keys where enforced, `response.php` for user-facing messages, `{arg}` interpolation in shared files.
- **`/larastan`** — PHPStan/Larastan generics for models, relations, builders, factories and collections, fixed at the project's configured level.
- **`/create-guideline`** — write a concise coding rule into `.ai/guidelines/` and sync it with Laravel Boost.

## Crossing sessions

- **`/handoff`** — when a thread is full or you need to branch off (e.g. into a `/prototype` session), this compacts the conversation into a markdown file. You don't continue in place — you **open a new session and reference that file** to carry the context across. It's the bridge between context windows, in either direction. Use it when you want a **fresh session** but need the **current conversation preserved**.
- **`/compact`** (built-in) — stay in the **same conversation**, letting the earlier turns be summarized. Use it at **intentional breaks between phases**, when you don't mind losing the verbatim history. Don't compact mid-phase — the agent can lose its way. `/handoff` forks; `/compact` continues.

## Standalone

Off the main flow entirely.

- **`/grill-me`** — the same relentless interview as `/grill-with-docs`, but for when you have **no codebase**. Stateless: it saves nothing locally, builds no `CONTEXT.md`. Reach for it to sharpen any plan or design that doesn't live in a repo.
- **`/prototype`** — a small, throwaway program that answers one design question: does this state model feel right, or what should this UI look like. Throwaway from day one — keep the answer, delete the code. It's the detour in step 2 of the main flow, but reach for it any time a design question is hard to settle on paper.
- **`/research`** — delegate reading legwork to a **background agent**: it investigates a question against **primary sources**, then leaves a cited Markdown file in the repo. Keep working while it reads. The file it produces is something to take *into* the main flow at `/grill-with-docs` — research feeds the thinking, it doesn't replace it.
- **`/to-questionnaire`** — when the thing blocking you isn't in your head or the codebase but in **someone else's**, this writes them a questionnaire to fill in. It's the inverse of `/grill-me`: instead of interviewing you about the subject, it interviews you about the **send** — who it's going to, what you need back — and aims the questions at the gap. What comes back is material for `/grill-with-docs` or `/to-spec`.
- **`/wizard`** — for the steps only a **human** can take: provisioning infrastructure, setting up credentials or CI secrets, clicking through an unfamiliar third-party dashboard, running a one-off migration or cutover. It generates an interactive bash script that opens each URL, captures each value, and writes it into `.env` and GitHub secrets — so the procedure stops being something you re-explain to an agent every time. Model-invoked, so the agent reaches for it the moment it hits a wall only you can pass. If the agent could just do it itself, it should; this is for where a human is genuinely in the loop.
- **`/migrate-deploy-branches`** — the one-way move that takes a project's frontend build off the server: CI builds the assets and force-pushes source + build to `deploy` / `deploy-dev`, and Forge deploys those. Run once per project, then never again. It's the sibling of `/wizard` in that half the work is a human clicking through a dashboard — the difference is that this procedure is walked inline, because you only ever do it once.
- **`/loom`** — when a Loom link shows up — pasted directly, or inside a ClickUp/Linear ticket or a grill — and its content matters, this analyzes the video without anyone watching it: transcript with speakers and timestamps as the **map**, ffmpeg-extracted frames as the **evidence**. Model-invoked, so it fires on its own the moment a recording is what's blocking understanding; what it extracts feeds whatever flow it fired inside (a grill answer, a ticket's repro).
- **`/witify-docx`** — when a deliverable has to ship as a **Witify-branded Word document** (a client-facing requirements doc, proposal, or report), this generates it from a proven template: dark cover page, Aptos typography, logo header, paginated footer. Model-invoked, so it fires when the ask is a branded .docx; the content usually comes out of another flow (a spec, a grill, a validated artifact) and this gives it its final form.
- **`/teach`** — learn a concept over multiple sessions, using the current directory as a stateful workspace.
- **`/writing-for-agents`** — reference for writing any document an agent consumes: skills, `AGENTS.md` / `CLAUDE.md`, docs reached by pointers.

## Precondition

**`/setup-witify-skills`** — run before your first engineering flow to configure the issue tracker, triage labels, and doc layout the other skills assume. Custom issue trackers also work.
