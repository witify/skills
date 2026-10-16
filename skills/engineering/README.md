# Engineering

Skills for daily code work.

## User-invoked

Reachable only when you type them (Claude Code: `disable-model-invocation: true`; Codex: `policy.allow_implicit_invocation: false` in `agents/openai.yaml`).

- **[to-spec](./to-spec/SKILL.md)** — Turn the current conversation into a spec and publish it to ClickUp (or Linear) over MCP.
- **[to-tickets](./to-tickets/SKILL.md)** — Break any plan, spec, or conversation into a set of tracer-bullet tickets, filed as sub-tasks on ClickUp (or Linear) with native blocking links, plus the PR mode on the parent.
- **[ship](./ship/SKILL.md)** — Take a set of tickets to a reviewed PR: one implement and one review sub-agent per ticket, then a PR to `dev` whose feedback is handled under a user-chosen fix policy for at most three waves.
- **[fix-review](./fix-review/SKILL.md)** — Work through the open review comments on a GitHub PR — triage, confirm the approach with you, then fix, commit, push, and reply with commit links. Never resolves threads; reviewers close their own.
- **[sprintify-sync](./sprintify-sync/SKILL.md)** — Sync the latest sprintify base code for one feature area from `../sprintify` into the current project — backend, frontend, and tests — so the matching base-code skill fully applies.
- **[witify-doctor](./witify-doctor/SKILL.md)** — Levelled check-up you validate item by item, one level at a time: harness memory and personal instructions off your machine, plugin and MCP servers in both harnesses, then guidelines, tooling, CI workflows, PHPStan rules (each sized by the files it would touch) and base code aligned with the latest sprintify.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[code-review](./code-review/SKILL.md)** — Two-axis review of the diff since a fixed point: **Standards** (does it follow the repo's coding standards, plus a Fowler smell baseline?) and **Spec** (does it faithfully implement the originating issue/PRD?), run as parallel sub-agents.
- **[frontend-development](./frontend-development/SKILL.md)** — Vue 3 + Tailwind frontend patterns: reactivity after emits, sub-forms that emit copies, orphan validation errors, and responsive layouts that collapse to a single column — plus sprintify app conventions (shared backend data, settings store, `resource_data`, `tabulation` tables).
- **[sprintify-ui](./sprintify-ui/SKILL.md)** — Reference for the `sprintify-ui` component library: what every `Base*` component is, and the props, events and slots it takes. Only useful in projects that depend on the package.
- **[audits](./audits/SKILL.md)** — Record model audit trails with the sprintify Audit module: staging API, readable labels, retention, and the display layer. Falls back to core principles on older forks.
- **[authorization](./authorization/SKILL.md)** — Authorization patterns for sprintify-derived projects: policies, nested controllers, `canDo()`, and `<Gate>` components on the frontend.
- **[confirm-request](./confirm-request/SKILL.md)** — Add server-enforced confirmation dialogs (optionally password-protected) before sensitive endpoints with `confirmRequest()`. Skipped when the project predates the flow.
- **[create-guideline](./create-guideline/SKILL.md)** — Create or update concise coding guidelines in `.ai/guidelines/`, synced with Laravel Boost.
- **[jobs-development](./jobs-development/SKILL.md)** — Conventions for Laravel jobs on Redis + Horizon: idempotence, uniqueness, timeouts, and queue selection read from the project's own Horizon config.
- **[larastan](./larastan/SKILL.md)** — PHPStan/Larastan patterns for Laravel: relationship generics, custom builders, factories, collections, and fixing type-level errors at the project's configured level.
- **[notification-development](./notification-development/SKILL.md)** — Create and manage Herald notifications: explicit channels, builder content, previews, and user settings. Skipped when the project predates Herald.
- **[translations](./translations/SKILL.md)** — Translation conventions for sprintify-derived projects: key placement (PHP vs JSON), flat JSON files where enforced, cleanup rules, and interpolation syntax.
