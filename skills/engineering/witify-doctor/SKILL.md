---
name: witify-doctor
description: Levelled check-up of your agent harness and the current repo against Witify's baseline — from harness hygiene on your machine up to guidelines, tooling, PHPStan rules, CI and base code aligned with the latest sprintify — validated item by item, one level at a time.
disable-model-invocation: true
---

# Witify Doctor

A **check-up**: examine first, treat only with consent. Every item on the checklist produces a **finding**; every finding with a choice becomes one question in chat, led by the recommended answer. Nothing on the machine or in the repo changes until the user has answered that specific question, and a "no" is recorded and moved past, never argued with.

The checklist is split into **levels** ordered by migration cost — level 0 touches only the developer's machine, level 4 restructures base code and deployment. A project's **level** is the highest level whose every item is `Healthy`, with every level below it `Healthy` too; an old fork sits at 0 or 1 and that is fine. Diagnosis always covers every level, so the report shows the whole picture; **treatment goes one level at a time**, never skipping — no PHPStan rules on a project whose guidelines still lie.

The interface is the same in every harness: the diagnosis is an HTML report the user reads in the browser ([REPORT.md](./REPORT.md)), and every decision is taken **in chat** — plain questions and answers, never a harness-specific widget.

## Checklist

Each item ends as `Healthy`, `Attention` (a choice to make), or `Blocked` (a prerequisite missing — a lower level, a clone, a package). Findings are reported as **paths and counts, never contents**.

### Level 0 — Machine

Always runs, project or not. Check every harness whose config directory exists (`~/.claude/`, `~/.codex/`); say which one is absent and skip it.

**0.1 Harness memory is off.** Explainer to give the user, in their language:

> We keep harness memory off. Memory stores what the agent learned on *your* machine, so two developers on the same repo end up with two different sets of instructions, and neither can review the other's. Anything worth remembering belongs in the repo as a guideline — versioned, reviewed, identical for everyone. Use `/create-guideline` for that.

- **Claude Code** — `~/.claude/settings.json`, `"autoMemoryEnabled": false` (absent = on; `CLAUDE_CODE_DISABLE_AUTO_MEMORY=0` in the environment forces it back on, so check the env too). Stores: every `~/.claude/projects/*/memory/` directory, plus the `autoMemoryDirectory` path when that setting is present.
- **Codex** — `~/.codex/config.toml`, `memories = false` under `[features]` (absent = off, the current default; `codex features list` prints the effective value). Stores: `~/.codex/memories/` and `~/.codex/memories_1.sqlite` with any `-wal` / `-shm` siblings — delete while Codex isn't running; it recreates them empty. `state_*.sqlite` and `thread_history_*.sqlite` are sessions, not memory.

Recommended: off, stores deleted.

**0.2 No personal instructions outside the repo.** Same argument as memory, for what the developer wrote by hand: `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.codex/AGENTS.md`, `~/.codex/rules/`. Empty or absent is `Healthy`. Otherwise show the content (it is the user's own text) and sort each rule: a coding rule migrates to the repo through `/create-guideline`; a purely personal preference (language, tone) may stay — say which is which. Recommended: repo for anything about code.

**0.3 The `witify-skills` plugin, in both harnesses, once.** Claude Code: `enabledPlugins["witify-skills@witify"]` in `~/.claude/settings.json`, installed version in `~/.claude/plugins/installed_plugins.json`. Codex: `[plugins."witify-skills@witify"] enabled = true` in `config.toml`, version from the copy under `~/.codex/plugins/cache/witify/`. Compare each to the latest tag of `witify/skills` (`git ls-remote --tags`). Then hunt duplicates: symlinks or copies of the same skills under `~/.claude/skills/` or `~/.agents/skills/` left by `link-skills.sh` — a skill installed twice fires twice. Recommended: plugin enabled and current in both, symlinks removed (never run `link-skills.sh` yourself).

**0.4 The MCP servers the skills need, in both harnesses.** Two lookups: the issue tracker the project configured in `docs/agents/issue-tracker.md` (Linear → a `linear` server, ClickUp → `clickup`; skip when there is no project) and, on a Boost project, `laravel-boost`. Claude Code reads `mcpServers` in `~/.claude.json` and the project's `.mcp.json`; Codex reads `[mcp_servers.*]` in `config.toml`. A server present in one harness and not the other is the finding. Recommended: same servers on both sides.

### Level 1 — Hygiene

Runs only inside a git repo that is a sprintify-derived Laravel project: `composer.json` requires `laravel/framework` and `.ai/guidelines/` exists. Otherwise report "no project here" and stop after level 0. No code changes; every project can reach this level today.

The comparison baseline for this level and above is the **latest sprintify `dev`**:

- The reference clone is `../sprintify` relative to the project root. Missing? Ask where it lives; never guess another sibling.
- Confirm before touching it — you are about to `git checkout dev && git pull` in the user's clone. A dirty tree there (`git status --porcelain`) blocks levels 1–4; never stash or discard someone else's work.
- Record the branch it was on; restore it when the run ends, success or not. Note the `dev` commit for the report header.

**1.1 After-update checks resolve to real commands.** Read the project's `.ai/guidelines/after-update-checks.md` (missing file → sprintify's copy is the proposed import). For every command it lists, prove it exists: a `vendor/bin/*` binary is present, an `npm run <script>` is defined in `package.json`, a `php artisan <command>` is listed by `php artisan list`. Treatment per missing command: add the script or package, or strike the line.

**1.2 Guidelines point at things that exist.** Every `.ai/guidelines/*.md` names files, classes, packages, commands, and config keys; resolve each against the project (`composer.json`, `package.json`, the class map, the file tree). A guideline citing a class deleted two refactors ago costs more than no guideline. Treatment per dead pointer: fix the reference or drop the paragraph.

**1.3 Boost is current and published.** On a project with `laravel/boost`: `boost.json` lists both `claude_code` and `codex` under `agents` (otherwise one harness gets no guidelines); the generated `CLAUDE.md` and `AGENTS.md` are both present and newer than the newest `.ai/guidelines/*` file (older = `boost:update` not run since the last guideline edit); their content comes only from guidelines — a paragraph in `CLAUDE.md` that no guideline contains is a direct edit, lost on the next update, and moves into a guideline. Compare the `laravel/boost` version to sprintify's. Treatment: fix `boost.json`, move direct edits, run `php artisan boost:update`.

**1.4 Harness artefacts are tracked and ignored like sprintify's.** What sprintify tracks, the project tracks (`git ls-files`): `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, `.claude/settings.json`, the Boost-published `.claude/skills/`, and the Polyscope workspace trio `polyscope.json`, `polyscope-db.sh`, `polyscope-env.sh`. What is per-developer is ignored **by the repo's own `.gitignore`**, not only the developer's global one (`git check-ignore -v` says which): `.claude/settings.local.json`, `CLAUDE.local.md`, `.scratch/`. A global ignore is one more thing that differs between machines. Treatment: add the lines to `.gitignore`, track what should be tracked.

`polyscope.json` is the one of those whose **contents** are checked, because a workspace that can't be created is a broken onboarding, not a style difference. Every command in its `setup`, `archive`, and `run` must resolve the way 1.1 does, and each `bash <name>.sh` must name a file the fork actually copied. Its steps are never compared verbatim — sprintify's are one project's shape, not a contract:

- A step the project does differently is `keep — repo's own`: no Horizon to start, another PHP version to isolate, `npm run production` where sprintify runs `npm run dev`, an extra seeder or a different `preview.url`.
- A step sprintify has that this one lacks with nothing in its place is drift — a missing `boost:update` leaves a fresh workspace without published guidelines, a missing `migrate-test` leaves its test database unmigrated.
- No `polyscope.json` at all: propose sprintify's, adapted to the project's own run commands and PHP version, and say the fork has no one-click workspace until then.

Treatment per finding: copy a script the fork never took, add the drifted step, or record the difference as the repo's own.

**1.5 The three quality workflows exist.** `run-tests.yml`, `larastan.yml`, `laravel-pint.yml` under `.github/workflows/`, each presented with its purpose when missing:

| Workflow | Purpose |
| --- | --- |
| `run-tests.yml` | Runs the PHPUnit suites on every push and PR — the only proof the branch works somewhere other than the developer's machine. |
| `larastan.yml` | Runs PHPStan at the project's level and rules on every push and PR, so a type error or a broken rule blocks the merge instead of surfacing in production. |
| `laravel-pint.yml` | Runs Pint on push and commits the formatting, so style never comes up in review. |

A present one is compared on its `run:` steps and triggers — a different branch list or an extra project step is the repo's own, a missing step or an older action is drift. Prove `.env.ci` exists when a workflow copies it, and that every `run:` command resolves the way 1.1 does. Project-only workflows (a docs deploy, an oxlint job) are `keep — repo's own`. Treatment: copy a missing workflow from sprintify adjusting only the branch triggers, merge a diverged one around the project's steps, add `.env.ci` from sprintify's copy.

### Level 2 — Guidelines and tooling

Config and docs; little code.

**2.1 Guidelines match sprintify's, except where the repo means to differ.** Sort every `.ai/guidelines/*.md` on either side:

- **upstream-only** — in sprintify, absent here. Proposed: import.
- **diverged** — in both, different. Read both sides and separate sprintify's additions and changes from the repo's own adaptations. Proposed: `import` when the local side is just stale, `merge` when both sides added something, `keep` when the difference is a deliberate local rule.
- **project-only** — here, absent in sprintify. Always `keep — repo's own`; a guideline sprintify doesn't have is the project's business, not drift.

A rule is the repo's own when it names the project's domain, packages, or clients (a `custom/` layout, a UOM convention, a client-specific integration). Say so in the finding; the user confirms. Treatment per file: the chosen action; a `merge` keeps the repo's adaptations and brings sprintify's additions in around them, and when the two genuinely conflict, show both and ask. Afterwards `php artisan boost:update`.

**2.2 Tooling parity.** Sprintify's development tooling, item by item, present here in the same shape: `pint.json` (diff it); oxlint with the `lint` / `lint:fix` / `fmt` scripts and the `eslint-rules/check-*.js` checks they chain (an ESLint fork is the finding — `/migrate-oxlint` makes that move when the user has it, otherwise it's a `Blocked` item to plan); `vue-tsc` and `vitest` with their `vue-tsc` / `test` scripts; the versions of `larastan/larastan`, `laravel/pint`, `laravel/boost`, `oxlint`, `vue-tsc` against sprintify's `composer.json` / `package.json` — a major behind (larastan 2 vs 3) is flagged as a prerequisite for level 3, since sprintify's rules target the current major. Treatment per item: add the script or config, bump the package, or record it as the repo's own choice.

**2.3 Every after-update check runs in CI.** Cross the commands of `after-update-checks.md` with the `run:` steps of all workflows: a command no workflow runs is a guardrail that only holds on the developer's machine. Treatment: add a job modelled on sprintify's nearest one.

### Level 3 — PHPStan

Touches code; every item is **sized** in files before it is offered.

**3.1 Level matches sprintify's.** Compare `level` in both `phpstan.neon`. A lower level is sized by running once at sprintify's level and counting distinct files with new errors. Treatment: raise the level, then fix now or baseline, as in 3.2.

**3.2 Rules match sprintify's.** Compare the `rules:` lists by **class basename** — the namespace and directory differ by fork (`\PhpStan\Rules\` under `phpstan/` in sprintify, `Support\PHPStan\Rules\` under `src/Support/PHPStan/Rules/` in older forks):

- **present** — same basename on both sides. Nothing to do.
- **project-only** — a rule sprintify lacks. `keep — repo's own`.
- **missing** — read the rule class. If it imports a class the project doesn't have (an Audit trait, a module), it is `not importable — needs /sprintify-sync <area>` and belongs to 4.2. Otherwise size it:
  1. Copy every importable missing rule class into the project's rules directory, rewriting the namespace to the project's (create the directory and its `composer.json` PSR-4 entry when the project has none yet, matching sprintify's layout).
  2. Register them all in `phpstan.neon` and run `vendor/bin/phpstan analyse --error-format=json --no-progress` once.
  3. Group the errors by rule identifier; **files to change** is the count of distinct files per rule, with one sample `path:line`.
  4. Revert every change from steps 1–2 before presenting anything — the sizing run leaves no trace.

Treatment: one question listing the importable rules with their file counts; for each chosen rule, copy the class with the project's namespace, register it, then ask how to handle its violations — **fix now** (the default; `/larastan` holds the patterns) or **baseline** (`vendor/bin/phpstan analyse --generate-baseline`, saying that this regenerates the whole baseline). End with `vendor/bin/phpstan analyse` green.

### Level 4 — Base code and deployment

Structural; each item is a project of its own, so the doctor hands it off instead of doing it inline.

**4.1 The sprintify baseline skills apply.** For each base-code skill installed — `/audits`, `/authorization`, `/confirm-request`, `/jobs-development`, `/notification-development`, `/translations` — evaluate its own `## Applicability` section against the project. Each area that predates its feature is a finding whose treatment is `/sprintify-sync <area>`, run by the user in its own session, one area at a time.

**4.2 The rules 3.2 could not import.** Listed with the area from 4.1 that unblocks each; they return to 3.2 once that sync has landed.

**4.3 Deploy branches.** `build-deploy-branch.yml` exists: it builds the frontend assets in CI and force-pushes source + build to `deploy` / `deploy-dev`, so the server never runs npm. Missing means the server still builds. Say what accepting means — **Forge's staging site must move from `dev` to `deploy-dev`, and production from `main` to `deploy`**, with their deploy scripts switched to fetch-and-reset and stripped of npm; until that's done the workflow pushes branches nobody deploys. Never copy this workflow by hand: the treatment is `/migrate-deploy-branches`, which writes it for this project's build output and walks the user through repointing Forge, staging first.

## Process

### 1. Diagnose

Work through every level top to bottom, reading everything and writing nothing (the sizing runs in level 3 are reverted inside the step). A level is `Healthy` when all its items are; the project's level follows.

### 2. Report

Write the report per [REPORT.md](./REPORT.md), open it, and give the absolute path. State the project's level, and the number of questions at each level above it.

### 3. Treat — one level at a time, in chat

Ask up to which level to treat in this session; default to the next one only. Within a level, ask about `Attention` items in checklist order, each led by the recommended answer so the user can accept it in a word, then apply exactly what was accepted — the treatment is written beside each item. Deleting memory stores (0.1) is the one irreversible step: list the paths with counts again right before deleting. Re-check the level when its treatments are done; move up only when it is `Healthy`.

### 4. Close

Restore sprintify's original branch. Summarise per item: treated, declined, or blocked (with what unblocks it), and the level the project now stands at. Suggest running the doctor again after the next sprintify release, or once a level-4 hand-off has landed.
