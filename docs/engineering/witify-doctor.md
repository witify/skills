Quickstart:

```bash
npx skills add witify/skills --skill=witify-doctor
```

```bash
npx skills update witify-doctor
```

[Source](https://github.com/witify/skills/tree/main/skills/engineering/witify-doctor)

## What it does

`witify-doctor` runs a **check-up** of two things: your own machine's agent harness, and the repo you're standing in. It looks for harness memory and personal instructions kept outside the repo, a plugin installed twice or in one harness only, guidelines that cite things that no longer exist, Boost left unpublished, CI workflows and tooling that sprintify has and the project lacks, PHPStan rules it doesn't enforce, and base code that predates the features the sprintify skills document — then walks you through each finding.

It diagnoses everything before it treats anything, and it treats one **level** at a time. The whole examination is read-only and lands in an HTML report; nothing on your machine or in the repo changes until you've said yes to that specific item in chat, and a "no" is recorded, not argued with. Repo-specific guidelines, rules, and workflows are recognised as the repo's own and flagged to keep, never as drift.

## When to reach for it

You invoke this by typing `/witify-doctor` — the agent won't reach for it on its own.

Reach for it on a new machine, after a sprintify release, or when a project feels out of step with the others — its guidelines say one thing, sprintify's say another, and nobody remembers which is deliberate. For bringing an area's *base code* up to date (the Audit module, Herald, confirm-request), use [sprintify-sync](./sprintify-sync.md) instead; the doctor's top level sends you there.

## Prerequisites

Level 0 runs anywhere. Levels 1–4 need a sprintify-derived Laravel project with the sprintify repo cloned as a sibling at `../sprintify` (it asks for the path otherwise) and a clean working tree there, since it pulls sprintify's `dev` to compare against the latest.

## The levels

The checklist is ordered by migration cost, so an old fork can start where it stands and climb one rung per session. A project's **level** is the highest level with nothing left to fix, and the doctor refuses to skip a rung — no PHPStan rules on a project whose guidelines still lie.

- **Level 0 — Machine.** Harness memory off in Claude Code and Codex (memory stores what the agent learned on *your* machine, so two developers end up with two sets of instructions neither can review; anything worth remembering belongs in the repo as a guideline). Personal `CLAUDE.md` / `AGENTS.md` / rules outside the repo, for the same reason. The `witify-skills` plugin current in both harnesses and installed once. The MCP servers the skills need, on both sides.
- **Level 1 — Hygiene.** No code changes. Every command in `after-update-checks.md` resolves to a real binary or script; guidelines point at files, classes, and packages that exist; Boost publishes to both harnesses and `boost:update` has run since the last guideline edit; harness artefacts are tracked and ignored like sprintify's; the three quality workflows (`run-tests`, `larastan`, `laravel-pint`) exist.
- **Level 2 — Guidelines and tooling.** `.ai/guidelines/` diffed against sprintify's, sorted upstream-only / diverged / project-only with a proposed action per file; tooling parity (Pint config, oxlint and its check scripts, `vue-tsc`, `vitest`, package majors); every after-update check actually run by some workflow — a check that only holds on your machine isn't a guardrail.
- **Level 3 — PHPStan.** The level and every rule sprintify enforces that the project doesn't, each **sized**: the doctor registers the missing rules temporarily, runs the analysis once, counts the files each one flags, then reverts. You choose which to import knowing the cost; violations are then fixed or baselined, your call.
- **Level 4 — Base code and deployment.** The sprintify skills' own applicability checks, area by area, each handed to [sprintify-sync](./sprintify-sync.md); the rules that couldn't be imported until then; and deploy branches — a missing `build-deploy-branch.yml` means the server still builds, and switching means repointing Forge (staging to `deploy-dev`, production to `deploy`), so the install goes through [migrate-deploy-branches](../migration/migrate-deploy-branches.md).

## It's working if

- The report is on screen before any question is asked, and it names the project's level before anything else.
- Every question is asked in chat, one level at a time, and no file changes until you answer.
- Your memory files and personal instruction files are listed by path and count, never quoted.
- Each missing PHPStan rule comes with a file count, not an adjective.
- A guideline, rule, or workflow that exists only in this repo is labelled as the repo's own, not as something to delete.
- It confirms before touching `../sprintify`, and restores that clone's branch when it ends.

## Where it fits

`witify-doctor` is **periodic maintenance**, like [improve-codebase-architecture](./improve-codebase-architecture.md) — that one keeps the *code* good for agents, this one keeps the *instructions and guardrails* aligned across developers and projects. Its neighbours are [sprintify-sync](./sprintify-sync.md) and [migrate-deploy-branches](../migration/migrate-deploy-branches.md), the two hand-offs its top level makes: the doctor spots drift in guidelines, rules, and CI, they repair drift in base code and deployment. When you're unsure which skill or flow fits, [ask-witify](./ask-witify.md) routes you.
