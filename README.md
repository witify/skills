# Witify Skills

[![skills.sh](https://skills.sh/b/witify/skills)](https://skills.sh/witify/skills)

Witify's agent skills for doing real engineering.

Developing real applications is hard. Approaches like GSD, BMAD, and Spec-Kit try to help by owning the process. But while doing so, they take away your control and make bugs in the process hard to resolve.

These skills are designed to be small, easy to adapt, and composable. They work with any model. They're based on decades of engineering experience. Hack around with them. Make them your own. Enjoy.

## Installation

Three steps: install the skills, set them up to talk to your issue tracker, then connect the tracker's MCP server.

### 1. Install the skills

Pick the first option that matches your setup — and only one:

<details>
<summary><strong><a href="https://laravel.com/docs/boost">Laravel Boost</a></strong> — your project uses Boost; it owns skill distribution</summary>

Boost fetches the skills from GitHub into `.ai/skills/` — the source of truth — and syncs them to every configured agent. Install each bucket with its scoped path (a bare `witify/skills` would also pull in this repo's internal dev tooling and unfinished drafts):

```bash
php artisan boost:add-skill --all witify/skills/skills/engineering
php artisan boost:add-skill --all witify/skills/skills/productivity
php artisan boost:add-skill --all witify/skills/skills/migration
```

Use `--skill <name>` instead of `--all` to cherry-pick. To pull newer versions later, re-run the commands with `--force`. After editing a skill locally, republish with `php artisan boost:update` — never edit the published copies or `CLAUDE.md` / `AGENTS.md`; Boost regenerates them.

</details>

<details>
<summary><strong><a href="https://skills.sh/witify/skills">skills.sh</a></strong> — editable skill files in your project, for Codex, Claude Code, and other agents</summary>

```bash
npx skills@latest add witify/skills
```

Pick the skills you want (**make sure `setup-witify-skills` is one of them**) and which agents to install them on. Update when you want with `npx skills update`.

</details>

<details>
<summary><strong><a href="https://code.claude.com/docs/en/plugins">Claude Code plugin</a></strong> — a managed, read-only bundle that updates when we ship</summary>

From inside a session, add the marketplace once, then install:

```
/plugin marketplace add witify/skills
/plugin install witify-skills@witify
```

</details>

### 2. Set up the issue tracker

The engineering skills read and write issues. Run `/setup-witify-skills` once per repo to wire them up — it asks where your issues live (Linear, ClickUp, or local files), which triage labels you use, and where to save the docs it creates.

### 3. Add the tracker's MCP server

If you picked Linear or ClickUp, the agent talks to it over MCP. Add the official hosted server, then authenticate (OAuth in the browser on first connection).

**Claude Code**

```bash
claude mcp add --transport http linear-server https://mcp.linear.app/mcp  # Linear
claude mcp add --transport http clickup https://mcp.clickup.com/mcp      # ClickUp

# Then run `/mcp` inside a Claude session to sign in.
```

**Codex**

```bash
codex mcp add linear --url https://mcp.linear.app/mcp    # Linear
codex mcp add clickup --url https://mcp.clickup.com/mcp  # ClickUp
codex mcp login <name>
```

Remote MCP servers require `experimental_use_rmcp_client = true` under `[features]` in `~/.codex/config.toml`.

## Making Changes & Releasing

`CHANGELOG.md` and version numbers are generated — never edit them by hand. The flow:

1. **Make the change** — edit skills, docs, whatever.
2. **Add a changeset** — a small file in `.changeset/` naming the bump and describing the change for the person reading the changelog:

   ```markdown
   ---
   "witify-skills": minor
   ---

   One or two sentences describing the change.
   ```

   Pick the bump: **`patch`** for fixes and small corrections, **`minor`** for a new skill or a real change to how one behaves (most changes land here), **`major`** for something breaking — a removed or renamed skill, a changed setup requirement.
3. **Push to `main`.** CI opens (or updates) a PR called **"chore: version skills"** — a shopping cart that accumulates every pending changeset and always shows the release that would happen: the next version number and the assembled changelog entry. It can sit open while changes pile up; that's normal.
4. **Merge that PR when you want users to get the update.** Merging is the release: it bumps `package.json` and `.claude-plugin/plugin.json` together, writes `CHANGELOG.md`, and CI tags the version. Plugin users see the update on their next Claude Code session.

If several changesets are pending, the highest bump wins — one `minor` among five `patch`es makes it a minor release — and they all share the one release's changelog entry. Never run `changeset version` locally on `main`; it races the PR and leaves it stale.

## Syncing with Upstream

Most skills here are vendored from [mattpocock/skills](https://github.com/mattpocock/skills), some with deliberate local adaptations. To pull upstream updates, ask your agent to follow [.agents/upstream-sync/PROCESS.md](./.agents/upstream-sync/PROCESS.md) (e.g. "sync with upstream") — it's a plain maintainer doc rather than a slash command, on purpose: skill installers pick up any `SKILL.md` in the repo, and this process is internal. Its sibling [STATE.md](./.agents/upstream-sync/STATE.md) records the last-synced upstream commit and the adaptation ledger — the files that deliberately diverge and must never be blindly overwritten. A sync lands like any other change: with a changeset, released through the flow above.

## Reference

These split on one axis — who can invoke them. **User-invoked** skills are reachable only when you type them (e.g. `/grill-me`); their job is to orchestrate. **Model-invoked** skills can be invoked by you _or_ reached for automatically by the agent when the task fits; they hold the reusable discipline. A user-invoked skill may invoke model-invoked skills, but never another user-invoked one.

### Engineering

Skills for daily code work.

**User-invoked**

- **[ask-witify](./skills/engineering/ask-witify/SKILL.md)** — Ask which skill or flow fits your situation. A router over the user-invoked skills in this repo.
- **[grill-with-docs](./skills/engineering/grill-with-docs/SKILL.md)** — Grilling session that also builds your project's domain model, sharpening terminology and updating `CONTEXT.md` and ADRs inline.
- **[triage](./skills/engineering/triage/SKILL.md)** — Move issues through a state machine of triage roles.
- **[improve-codebase-architecture](./skills/engineering/improve-codebase-architecture/SKILL.md)** — Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
- **[setup-witify-skills](./skills/engineering/setup-witify-skills/SKILL.md)** — Configure this repo for the engineering skills (issue tracker, triage labels, domain doc layout). Run once per repo before using the other engineering skills.
- **[to-spec](./skills/engineering/to-spec/SKILL.md)** — Turn the current conversation into a spec and publish it to the issue tracker. No interview — just synthesizes what you've already discussed.
- **[to-tickets](./skills/engineering/to-tickets/SKILL.md)** — Break any plan, spec, or conversation into a set of tracer-bullet tickets, each declaring its blocking edges — written as text in a local file, or as native blocking links on a real tracker.
- **[implement](./skills/engineering/implement/SKILL.md)** — Build the work described by a spec or set of tickets, driving `/tdd` at pre-agreed seams and closing out with `/code-review` before committing.
- **[wayfinder](./skills/engineering/wayfinder/SKILL.md)** — Plan a huge chunk of work, more than one agent session can hold, as a shared map of investigation tickets on the issue tracker — resolve them one at a time until the way to the destination is clear.
- **[fix-review](./skills/engineering/fix-review/SKILL.md)** — Work through the open review comments on a GitHub PR — fix, commit, push, and reply with commit links. Never resolves threads; reviewers close their own.
- **[sprintify-sync](./skills/engineering/sprintify-sync/SKILL.md)** — Sync the latest sprintify base code for one feature area from `../sprintify` into the current project — backend, frontend, and tests — so the matching base-code skill fully applies.

**Model-invoked**

- **[prototype](./skills/engineering/prototype/SKILL.md)** — Build a throwaway prototype to answer a design question — a single shareable HTML demo for state/logic questions, or several radically different UI variations toggleable from one route.
- **[diagnosing-bugs](./skills/engineering/diagnosing-bugs/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[research](./skills/engineering/research/SKILL.md)** — Investigate a question against high-trust primary sources and capture the findings as a cited Markdown file in the repo, run as a background agent.
- **[tdd](./skills/engineering/tdd/SKILL.md)** — Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **[domain-modeling](./skills/engineering/domain-modeling/SKILL.md)** — Actively build and sharpen a project's domain model — challenge terms against the glossary, stress-test with edge-case scenarios, and update `CONTEXT.md` and ADRs inline.
- **[codebase-design](./skills/engineering/codebase-design/SKILL.md)** — Shared discipline and vocabulary for designing deep modules: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface.
- **[code-review](./skills/engineering/code-review/SKILL.md)** — Two-axis review of the diff since a fixed point: **Standards** (does it follow the repo's coding standards, plus a Fowler smell baseline?) and **Spec** (does it faithfully implement the originating issue/PRD?), run as parallel sub-agents so neither pollutes the other.
- **[resolving-merge-conflicts](./skills/engineering/resolving-merge-conflicts/SKILL.md)** — Work through an in-progress git merge or rebase conflict hunk by hunk, resolving by intent traced to each side's primary source, then finish the operation — never `--abort`.
- **[wizard](./skills/engineering/wizard/SKILL.md)** — Generate an interactive bash wizard that walks a human through steps only they can perform: provisioning infrastructure, credentials and CI secrets, unfamiliar third-party dashboards, one-off migrations or cutovers.
- **[frontend-development](./skills/engineering/frontend-development/SKILL.md)** — Vue 3 + Tailwind frontend patterns: reactivity after emits, sub-forms that emit copies, orphan validation errors, and responsive layouts — plus sprintify app conventions (shared backend data, settings store, `resource_data`, `tabulation` tables).
- **[frontend-design](./skills/engineering/frontend-design/SKILL.md)** — Distinctive, intentional visual design for new or reshaped UI: aesthetic direction, typography, and choices that don't read as templated defaults. Vendored from Anthropic's [claude-plugins-official](https://github.com/anthropics/claude-plugins-official).
- **[sprintify-ui](./skills/engineering/sprintify-ui/SKILL.md)** — Reference for the [sprintify-ui](https://www.npmjs.com/package/sprintify-ui) component library: what every `Base*` component is, and the props, events and slots it takes. Only useful in projects that depend on the package.
- **[audits](./skills/engineering/audits/SKILL.md)** — Record model audit trails with the sprintify Audit module: staging API, readable labels, retention, and the display layer. Falls back to core principles on older forks.
- **[authorization](./skills/engineering/authorization/SKILL.md)** — Authorization patterns for sprintify-derived projects: policies, nested controllers, `canDo()`, and `<Gate>` components on the frontend.
- **[confirm-request](./skills/engineering/confirm-request/SKILL.md)** — Add server-enforced confirmation dialogs (optionally password-protected) before sensitive endpoints with `confirmRequest()`. Skipped when the project predates the flow.
- **[create-guideline](./skills/engineering/create-guideline/SKILL.md)** — Create or update concise coding guidelines in `.ai/guidelines/`, synced with Laravel Boost.
- **[jobs-development](./skills/engineering/jobs-development/SKILL.md)** — Conventions for Laravel jobs on Redis + Horizon: idempotence, uniqueness, timeouts, and queue selection read from the project's own Horizon config.
- **[larastan](./skills/engineering/larastan/SKILL.md)** — PHPStan/Larastan patterns for Laravel: relationship generics, custom builders, factories, collections, and fixing type-level errors at the project's configured level.
- **[notification-development](./skills/engineering/notification-development/SKILL.md)** — Create and manage Herald notifications: explicit channels, builder content, previews, and user settings. Skipped when the project predates Herald.
- **[translations](./skills/engineering/translations/SKILL.md)** — Translation conventions for sprintify-derived projects: key placement (PHP vs JSON), flat JSON files where enforced, cleanup rules, and interpolation syntax.

### Migration

One-way moves from one setup to another. Each runs once per project, then stops being relevant.

**Model-invoked**

- **[migrate-deploy-branches](./skills/migration/migrate-deploy-branches/SKILL.md)** — Move a project to deploy branches: a GitHub Actions workflow builds the frontend assets and force-pushes source + build to `deploy` / `deploy-dev`, and Forge deploys those instead of building on the server.

### Productivity

General workflow tools, not code-specific.

**User-invoked**

- **[grill-me](./skills/productivity/grill-me/SKILL.md)** — Get relentlessly interviewed about a plan or design until every branch of the decision tree is resolved.
- **[handoff](./skills/productivity/handoff/SKILL.md)** — Compact the current conversation into a handoff document so another agent can continue the work.
- **[teach](./skills/productivity/teach/SKILL.md)** — Teach the user a new skill or concept over multiple sessions, using the current directory as a stateful teaching workspace.
- **[to-questionnaire](./skills/productivity/to-questionnaire/SKILL.md)** — Turn a decision you can't fully answer into a Markdown questionnaire for someone else to fill in async, or over a meeting. It grills you about the send (who it's for, what you need back), not the subject.

**Model-invoked**

- **[grilling](./skills/productivity/grilling/SKILL.md)** — Interview the user relentlessly about a plan, decision, or idea until every branch of the decision tree is resolved. The reusable loop behind `grill-me` and `grill-with-docs`.
- **[writing-for-agents](./skills/productivity/writing-for-agents/SKILL.md)** — Reference for writing any document an agent consumes — skills, `AGENTS.md` / `CLAUDE.md`, docs reached by pointers — with the levers that make each one predictable.
