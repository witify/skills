Quickstart:

```bash
npx skills add witify/skills --skill=migrate-deploy-branches
```

```bash
npx skills update migrate-deploy-branches
```

[Source](https://github.com/witify/skills/tree/main/skills/migration/migrate-deploy-branches)

## What it does

`migrate-deploy-branches` moves a project's frontend build off the server and into CI. A GitHub Actions workflow checks out each push to `dev` / `main`, builds the assets, commits them on top of the source commit, and force-pushes the result to `deploy-dev` / `deploy` — the branches Forge then deploys. The server stops running npm entirely.

The deploy branch is a build artifact, not history. Every build rewrites it, so nothing you hand-commit there survives, and a `git pull` on the server cannot follow it — swapping that pull for a fetch-and-reset is the step that makes the whole cutover hold.

## When to reach for it

Type `/migrate-deploy-branches`, or the agent reaches for it automatically when you ask to build assets in CI, stop building on the server, or add a `build-deploy-branch.yml`.

Reach for it when the server build is the thing hurting: vite OOM-killed on a small droplet, half-built assets served mid-deploy, npm and node kept on production only for deploys, or deploy times dominated by a build that CI already has warm caches for. It is a one-way move, run once per project — not something to revisit.

## Prerequisites

A project whose build emits into the repo (`public/build` via `laravel-vite-plugin` is the usual shape), gitignored today, deployed by pulling a git branch. Half the migration happens in the Forge dashboard, so a human has to be present for the cutover. Projects that build a container image or run on Laravel Cloud already build elsewhere and gain nothing.

One thing decides whether the build can move at all: `VITE_*` env vars are baked into the bundle at build time, so if the app reads any, CI has to supply them per target branch before anything else happens.

## Force-add every artifact the build writes

The failure this skill exists to prevent is a **partial build** on the deploy branch. The workflow's `git add -f` list has to name every gitignored path the build emits — and the way to know that list is to build and look, never to guess:

```bash
npm ci && npm run build
git status --porcelain --ignored public | grep '^!!'
```

`public/build/` is always there. A project using `vite-plugin-pwa` also writes `public/sw.js` and `public/workbox-*.js`; leave those off the list and production serves a stale service worker indefinitely, with nothing in any log to say so. The list has to grow whenever the build config does.

## Two halves, in order

The **repo half** is the workflow file. The **host half** is repointing each Forge site at its deploy branch and stripping npm out of its deploy script. The order is fixed: the deploy branches don't exist until the workflow has run once, so repointing first just breaks deploys. Staging goes first and gets verified end to end before production is touched.

## It's working if

- `deploy` and `deploy-dev` exist on the remote, and their tip commit contains the built assets.
- The Forge deploy log shows no npm step, and the deploy script fetch-and-resets rather than pulls.
- A commit pushed to `dev` walks the whole chain on its own: workflow green → deploy branch moves → Forge deploys → new asset hashes live.
- Source-branch diffs still contain no built assets — the build output stayed gitignored.

## Where it fits

A run-once cutover, standalone: nothing feeds it and nothing follows it. Its nearest neighbour is [wizard](../engineering/wizard.md), because both exist for procedures where a human has to click through a dashboard — this one walks you through Forge inline, where `wizard` would generate a script for a procedure you'll repeat. When you're unsure which skill fits the moment, [ask-witify](../engineering/ask-witify.md) routes you.
