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

Boost fetches the skills from GitHub into `.ai/skills/` — the source of truth — and syncs them to every configured agent:

```bash
php artisan boost:add-skill --all witify/skills
```

Use `--skill <name>` instead of `--all` to cherry-pick. To pull newer versions later, re-run the command with `--force`. After editing a skill locally, republish with `php artisan boost:update` — never edit the published copies or `CLAUDE.md` / `AGENTS.md`; Boost regenerates them.

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

## Why These Skills Exist

We built these skills to fix common failure modes we see with Claude Code, Codex, and other coding agents.

### #1: The Agent Didn't Do What I Want

> "No-one knows exactly what they want"
>
> David Thomas & Andrew Hunt, [The Pragmatic Programmer](https://www.amazon.co.uk/Pragmatic-Programmer-Anniversary-Journey-Mastery/dp/B0833F1T3V)

**The Problem**. The most common failure mode in software development is misalignment. You think the dev knows what you want. Then you see what they've built - and you realize it didn't understand you at all.

This is just the same in the AI age. There is a communication gap between you and the agent. The fix for this is a **grilling session** - getting the agent to ask you detailed questions about what you're building.

**The Fix** is to use:

- [`/grill-me`](./skills/productivity/grill-me/SKILL.md) - for non-code uses
- [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md) - same as [`/grill-me`](./skills/productivity/grill-me/SKILL.md), but adds more goodies (see below)

These are the most popular skills in the set. They help you align with the agent before you get started, and think deeply about the change you're making. Use them _every_ time you want to make a change.

### #2: The Agent Is Way Too Verbose

> With a ubiquitous language, conversations among developers and expressions of the code are all derived from the same domain model.
>
> Eric Evans, [Domain-Driven-Design](https://www.amazon.co.uk/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)

**The Problem**: At the start of a project, devs and the people they're building the software for (the domain experts) are usually speaking different languages.

The same tension exists with agents. Agents are usually dropped into a project and asked to figure out the jargon as they go. So they use 20 words where 1 will do.

**The Fix** for this is a shared language. It's a document that helps agents decode the jargon used in the project.

<details>
<summary>
Example
</summary>

Here's an example from a course-video-manager project's `CONTEXT.md`. Which one is easier to read?

- **BEFORE**: "There's a problem when a lesson inside a section of a course is made 'real' (i.e. given a spot in the file system)"
- **AFTER**: "There's a problem with the materialization cascade"

This concision pays off session after session.

</details>

This is built into [`/grill-with-docs`](./skills/engineering/grill-with-docs/SKILL.md). It's a grilling session, but that helps you build a shared language with the AI, and document hard-to-explain decisions in ADR's.

It's hard to explain how powerful this is. It might be the single coolest technique in this repo. Try it, and see.

> [!TIP]
> A shared language has many other benefits than reducing verbosity:
>
> - **Variables, functions and files are named consistently**, using the shared language
> - As a result, the **codebase is easier to navigate** for the agent
> - The agent also **spends fewer tokens on thinking**, because it has access to a more concise language

### #3: The Code Doesn't Work

> "Always take small, deliberate steps. The rate of feedback is your speed limit. Never take on a task that’s too big."
>
> David Thomas & Andrew Hunt, [The Pragmatic Programmer](https://www.amazon.co.uk/Pragmatic-Programmer-Anniversary-Journey-Mastery/dp/B0833F1T3V)

**The Problem**: Let's say that you and the agent are aligned on what to build. What happens when the agent _still_ produces crap?

It's time to look at your feedback loops. Without feedback on how the code it produces actually runs, the agent will be flying blind.

**The Fix**: You need the usual tranche of feedback loops: static types, browser access, and automated tests.

For automated tests, a red-green-refactor loop is critical. This is where the agent writes a failing test first, then fixes the test. This helps give the agent a consistent level of feedback that results in far better code.

The **[`/tdd`](./skills/engineering/tdd/SKILL.md) skill** slots into any project. It encourages red-green-refactor and gives the agent plenty of guidance on what makes good and bad tests.

For debugging, the **[`/diagnosing-bugs`](./skills/engineering/diagnosing-bugs/SKILL.md)** skill wraps best debugging practices into a simple loop.

### #4: We Built A Ball Of Mud

> "Invest in the design of the system _every day_."
>
> Kent Beck, [Extreme Programming Explained](https://www.amazon.co.uk/Extreme-Programming-Explained-Embrace-Change/dp/0321278658)

> "The best modules are deep. They allow a lot of functionality to be accessed through a simple interface."
>
> John Ousterhout, [A Philosophy Of Software Design](https://www.amazon.co.uk/Philosophy-Software-Design-2nd/dp/173210221X)

**The Problem**: Most apps built with agents are complex and hard to change. Because agents can radically speed up coding, they also accelerate software entropy. Codebases get more complex at an unprecedented rate.

**The Fix** for this is a radical new approach to AI-powered development: caring about the design of the code.

This is built in to every layer of these skills:

- [`/to-spec`](./skills/engineering/to-spec/SKILL.md) quizzes you about which modules you're touching before creating a spec

And crucially, [`/improve-codebase-architecture`](./skills/engineering/improve-codebase-architecture/SKILL.md) helps you rescue a codebase that has become a ball of mud. We recommend running it on your codebase once every few days.

### Summary

Software engineering fundamentals matter more than ever. These skills are our best effort at condensing these fundamentals into repeatable practices, to help you ship the best apps of your career. Enjoy.

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

- **[prototype](./skills/engineering/prototype/SKILL.md)** — Build a throwaway prototype to answer a design question — a runnable terminal app for state/logic questions, or several radically different UI variations toggleable from one route.
- **[diagnosing-bugs](./skills/engineering/diagnosing-bugs/SKILL.md)** — Disciplined diagnosis loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test.
- **[research](./skills/engineering/research/SKILL.md)** — Investigate a question against high-trust primary sources and capture the findings as a cited Markdown file in the repo, run as a background agent.
- **[tdd](./skills/engineering/tdd/SKILL.md)** — Test-driven development with a red-green-refactor loop. Builds features or fixes bugs one vertical slice at a time.
- **[domain-modeling](./skills/engineering/domain-modeling/SKILL.md)** — Actively build and sharpen a project's domain model — challenge terms against the glossary, stress-test with edge-case scenarios, and update `CONTEXT.md` and ADRs inline.
- **[codebase-design](./skills/engineering/codebase-design/SKILL.md)** — Shared discipline and vocabulary for designing deep modules: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface.
- **[code-review](./skills/engineering/code-review/SKILL.md)** — Two-axis review of the diff since a fixed point: **Standards** (does it follow the repo's coding standards, plus a Fowler smell baseline?) and **Spec** (does it faithfully implement the originating issue/PRD?), run as parallel sub-agents so neither pollutes the other.
- **[resolving-merge-conflicts](./skills/engineering/resolving-merge-conflicts/SKILL.md)** — Work through an in-progress git merge or rebase conflict hunk by hunk, resolving by intent traced to each side's primary source, then finish the operation — never `--abort`.
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

### Productivity

General workflow tools, not code-specific.

**User-invoked**

- **[grill-me](./skills/productivity/grill-me/SKILL.md)** — Get relentlessly interviewed about a plan or design until every branch of the decision tree is resolved.
- **[handoff](./skills/productivity/handoff/SKILL.md)** — Compact the current conversation into a handoff document so another agent can continue the work.
- **[teach](./skills/productivity/teach/SKILL.md)** — Teach the user a new skill or concept over multiple sessions, using the current directory as a stateful teaching workspace.
- **[writing-great-skills](./skills/productivity/writing-great-skills/SKILL.md)** — Reference for writing and editing skills well: the vocabulary and principles that make a skill predictable.

**Model-invoked**

- **[grilling](./skills/productivity/grilling/SKILL.md)** — Interview the user relentlessly about a plan, decision, or idea until every branch of the decision tree is resolved. The reusable loop behind `grill-me` and `grill-with-docs`.
