---
"witify-skills": minor
---

New `witify-doctor` skill (engineering, user-invoked): a check-up you validate item by item, organised in **levels** by migration cost so an old fork can start where it stands and climb one rung per session — the doctor never skips a level.

Level 0 is your machine: Claude Code / Codex memory and personal `CLAUDE.md` / `AGENTS.md` off (we keep instructions in the repo, where every developer sees the same ones), the `witify-skills` plugin current in both harnesses and installed once, the MCP servers the skills need on both sides. Level 1 is hygiene inside a sprintify-derived project: every command in `after-update-checks.md` exists, guidelines point at files and classes that still exist, Boost publishes to both harnesses and is up to date, harness artefacts are tracked and ignored like sprintify's, the three quality workflows are present. Level 2 diffs `.ai/guidelines/` and the tooling against the latest sprintify `dev` (upstream-only, diverged, project-only — with the repo's own rules flagged to keep) and checks that every after-update check runs in CI. Level 3 sizes each PHPStan rule sprintify has that the project lacks by the number of files it would touch, so you pick which to import. Level 4 hands off: base code that predates a sprintify feature goes to `/sprintify-sync`, deploy branches to `/migrate-deploy-branches` (with the Forge repoint spelled out).

Findings land in an HTML report; every decision is taken in chat, so it works the same on Claude Code and Codex.
