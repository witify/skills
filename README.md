# Witify Skills

[![skills.sh](https://skills.sh/b/witify/skills)](https://skills.sh/witify/skills)

Witify's agent skills for doing real engineering.

Developing real applications is hard. Approaches like GSD, BMAD, and Spec-Kit try to help by owning the process. But while doing so, they take away your control and make bugs in the process hard to resolve.

These skills are designed to be small, easy to adapt, and composable. They work with any model. They're based on decades of engineering experience. Hack around with them. Make them your own. Enjoy.

## Installation

Two steps: install the skills, then connect your issue tracker's MCP server.

### 1. Install the skills

**Default: the native plugins, on both harnesses.** The repo is one plugin marketplace serving Claude Code *and* Codex — a managed, read-only bundle on each. One install covers all your projects, and updates ship automatically when we release — no per-project copies to keep in sync. Install on every harness you use:

**[Claude Code plugin](https://code.claude.com/docs/en/plugins)** — from inside a session:

```
/plugin marketplace add witify/skills
/plugin install witify-skills@witify
```

**[Codex plugin](https://developers.openai.com/codex/plugins)** (Codex ≥ 0.147) — pull later releases with `codex plugin marketplace upgrade`:

```bash
codex plugin marketplace add witify/skills
codex plugin add witify-skills@witify
```

To make Claude Code automatic for a whole team, commit this to a project's `.claude/settings.json` — everyone who trusts the project gets the marketplace registered automatically, and `autoUpdate` keeps the plugin current as we release (see [team marketplaces](https://code.claude.com/docs/en/discover-plugins#configure-team-marketplaces)):

```json
{
  "extraKnownMarketplaces": {
    "witify": {
      "source": { "source": "github", "repo": "witify/skills" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "witify-skills@witify": true
  }
}
```

The two alternatives below copy skill files **into a project**. Reach for one only when neither plugin covers you: agents other than Claude Code and Codex (Cursor, …), or a project that deliberately forks a skill to adapt it. A copied skill goes stale until you re-sync it — the plugins never do.

<details>
<summary><strong><a href="https://skills.sh/witify/skills">skills.sh</a></strong> — editable skill files in your project, for Codex and other agents</summary>

```bash
npx skills@latest add witify/skills
```

Pick the skills you want and which agents to install them on. Update when you want with `npx skills update`.

</details>

<details>
<summary><strong><a href="https://laravel.com/docs/boost">Laravel Boost</a></strong> — your project uses Boost and needs the skills in-repo</summary>

Boost fetches the skills from GitHub into `.ai/skills/` — the source of truth — and syncs them to every configured agent. Install each bucket with its scoped path (a bare `witify/skills` would also pull in this repo's internal dev tooling and unfinished drafts):

```bash
php artisan boost:add-skill --all witify/skills/skills/engineering
php artisan boost:add-skill --all witify/skills/skills/productivity
php artisan boost:add-skill --all witify/skills/skills/migration
```

Use `--skill <name>` instead of `--all` to cherry-pick. To pull newer versions later, re-run the commands with `--force`. After editing a skill locally, republish with `php artisan boost:update` — never edit the published copies or `CLAUDE.md` / `AGENTS.md`; Boost regenerates them.

</details>

### 2. Add the tracker's MCP server

`to-spec`, `to-tickets`, and `ship` read and write tickets over MCP. **ClickUp is the default**; the skills use Linear instead when you say so or when the project's agent instructions (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`) name Linear as its tracker. There is no setup step and no local-file fallback: if the server isn't connected, the skill stops and says so. Add the official hosted server, then authenticate (OAuth in the browser on first connection).

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

## Recommended Companions

A few skills we lean on aren't ours and aren't vendored here — they're maintained better where they live, and a copy in this repo would only go stale. Install them alongside the Witify plugin; they compose with these skills rather than competing with them.

### [frontend-design](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/frontend-design) — Anthropic

Visual direction when building or reshaping UI: palette, typography, layout choices that don't read as templated defaults. Where [frontend-development](./skills/engineering/frontend-development/SKILL.md) holds the **correctness patterns** for Vue code, this holds the **aesthetics** — reach for it when a screen works but looks generic.

**Claude Code** — from inside a session:

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install frontend-design@claude-plugins-official
```

**Codex** — the plugin is Claude-Code-only, so pull the skill files in with [skills.sh](https://skills.sh) instead:

```bash
npx skills@latest add anthropics/claude-plugins-official --skill=frontend-design
```

Update it later with `npx skills update frontend-design`.

### [diagram-design](https://github.com/cathrynlavery/diagram-design) — Cathryn Lavery

Editorial diagrams the model hand-writes as self-contained HTML with inline SVG: architecture, flowcharts, sequence, ER, Gantt, and some forty types in all, on a design system that avoids the generic Mermaid look. It is model-invoked, so it triggers on its own whenever a diagram is asked for. [witify-docx](./skills/productivity/witify-docx/SKILL.md) draws its **figures** with it (draw the diagram here, export it to PNG, drop it in the document), and the Witify brand profile it uses ships inside that skill: the docx build script installs it to `~/.diagram-design/profiles/witify.md` and writes a `.diagram-design` marker (`profile: witify`) in the document folder, so for a branded diagram outside a Word document, write that same marker in your working folder once the profile is installed.

**Claude Code** — from inside a session:

```
/plugin marketplace add cathrynlavery/diagram-design
/plugin install diagram-design@diagram-design
```

**Codex** — it ships as a native Codex plugin too:

```bash
codex plugin marketplace add cathrynlavery/diagram-design
codex plugin add diagram-design@diagram-design
```

SVG export needs nothing extra; PNG export (what embedding a figure in a document needs) rasterizes through Playwright, so run `pip install playwright && playwright install chromium` once. Installs for Factory Droid, Pi, Kiro, and OpenCode are in the [upstream README](https://github.com/cathrynlavery/diagram-design#install).

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

`to-spec`, `to-tickets`, and `code-review` descend from [mattpocock/skills](https://github.com/mattpocock/skills), each adapted (they reach ClickUp or Linear straight over MCP). To pull upstream updates into them, ask your agent to follow [.agents/upstream-sync/PROCESS.md](./.agents/upstream-sync/PROCESS.md) (e.g. "sync with upstream") — it's a plain maintainer doc rather than a slash command, on purpose: skill installers pick up any `SKILL.md` in the repo, and this process is internal. Its sibling [STATE.md](./.agents/upstream-sync/STATE.md) records the last-synced upstream commit and the adaptation ledger — the files that deliberately diverge and must never be blindly overwritten. A sync lands like any other change: with a changeset, released through the flow above.

## Reference

These split on one axis — who can invoke them. **User-invoked** skills are reachable only when you type them (e.g. `/to-spec`); their job is to orchestrate. **Model-invoked** skills can be invoked by you _or_ reached for automatically by the agent when the task fits; they hold the reusable discipline. A user-invoked skill may invoke model-invoked skills, but never another user-invoked one.

### Engineering

Skills for daily code work.

**User-invoked**

- **[to-spec](./skills/engineering/to-spec/SKILL.md)** — Turn the current conversation into a spec and publish it to ClickUp (or Linear) over MCP. No interview — just synthesizes what you've already discussed.
- **[to-tickets](./skills/engineering/to-tickets/SKILL.md)** — Break any plan, spec, or conversation into a set of tracer-bullet tickets, filed as sub-tasks on ClickUp (or Linear) with native blocking links, and record whether the set ships as one PR or one PR per ticket.
- **[ship](./skills/engineering/ship/SKILL.md)** — Take a set of tickets to a reviewed PR: one implement and one review sub-agent per ticket, then a PR to `dev` whose feedback is handled under a user-chosen fix policy for at most three waves.
- **[fix-review](./skills/engineering/fix-review/SKILL.md)** — Work through the open review comments on a GitHub PR — triage, confirm the approach with you, then fix, commit, push, and reply with commit links. Never resolves threads; reviewers close their own.
- **[sprintify-sync](./skills/engineering/sprintify-sync/SKILL.md)** — Sync the latest sprintify base code for one feature area from `../sprintify` into the current project — backend, frontend, and tests — so the matching base-code skill fully applies.
- **[witify-doctor](./skills/engineering/witify-doctor/SKILL.md)** — Levelled check-up you validate item by item, one level at a time: harness memory and personal instructions off your machine, plugin and MCP servers in both harnesses, then guidelines, tooling, CI workflows, PHPStan rules (each sized by the files it would touch) and base code aligned with the latest sprintify.

**Model-invoked**

- **[code-review](./skills/engineering/code-review/SKILL.md)** — Two-axis review of the diff since a fixed point: **Standards** (does it follow the repo's coding standards, plus a Fowler smell baseline?) and **Spec** (does it faithfully implement the originating issue/PRD?), run as parallel sub-agents so neither pollutes the other.
- **[frontend-development](./skills/engineering/frontend-development/SKILL.md)** — Vue 3 + Tailwind frontend patterns: reactivity after emits, sub-forms that emit copies, orphan validation errors, and responsive layouts — plus sprintify app conventions (shared backend data, settings store, `resource_data`, `tabulation` tables).
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

**Model-invoked**

- **[loom](./skills/productivity/loom/SKILL.md)** — Analyze a Loom video in detail: transcript with speakers, chapters, and actual frames inspected via ffmpeg. Fires whenever a loom.com link shows up in a task, grill, or conversation and its content matters.
- **[witify-docx](./skills/productivity/witify-docx/SKILL.md)** — Generate a Witify-branded Word document: dark cover page, Helvetica text with Archivo bold headings, logo header, paginated footer. Fires when a deliverable needs to ship as a branded .docx.
- **[witify-writing-style](./skills/productivity/witify-writing-style/SKILL.md)** — Witify's writing rules for client-facing French copy: no dashes or semicolons, one idea per sentence, Québec number and amount formats, vouvoiement, preferred French terms, and a final grep check. It is the single source of those rules, so every document skill invokes it rather than carrying its own. Fires when writing or editing any text a client will read, and whenever another skill generates a document.
- **[figma-brief](./skills/productivity/figma-brief/SKILL.md)** — Write a concise brief (a prompt) for generating interface mockups with an AI design tool such as Figma Make: business purpose per screen, fr-CA vocabulary, one primary action, the business rules that shape the UI, and how the screens link. Labels, not data; intent, not pixels. Fires when screens are being described so a tool can render them.
