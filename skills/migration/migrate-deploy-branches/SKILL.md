---
name: migrate-deploy-branches
description: "Migrate a project to deploy branches: a GitHub Actions workflow builds the frontend assets and force-pushes source + build to `deploy` / `deploy-dev`, so the server never runs npm. Use when asked to migrate to deploy branches, build assets in CI instead of on the server, stop building on Forge, cut deploys over to a built branch, or add a `build-deploy-branch.yml` workflow."
---

# Migrate to deploy branches

A **deploy branch** is the source commit plus its built assets, committed. CI checks out the pushed commit on `dev` / `main`, runs the frontend build, force-adds the build output (normally gitignored), commits it, and force-pushes to `deploy-dev` / `deploy`. The host deploys those branches, so no build tooling ever runs on the server — no npm on production, no OOM-killed vite, no half-built assets served while the build is mid-flight.

The CI side is not written per project: every Witify project calls the shared **Deploy branch** workflow of [witify/workflows](https://github.com/witify/workflows#deploy-branch) with a few inputs, so a fix lands once for all of them. Never copy the build steps into the project.

Migrating is two halves: the **repo half** (a small caller workflow) and the **host half** (repointing the site and stripping the build out of its deploy script). Both must land, in that order. Repointing the host before the deploy branch exists breaks deploys.

## 1. Check the pattern applies

Skip and say so if any of these fail:

- `package.json` has a build script that emits into the repo — typically `npm run build` into `public/build` via `laravel-vite-plugin`, or `npm run production` into `public/css`, `public/js` and `public/mix-manifest.json` with Laravel Mix.
- The build output is **gitignored** on the source branches. If it's already committed, there's nothing to migrate; the project already ships built assets.
- Deploys pull a **git branch** (Forge, Envoyer, a bare `git pull` on a VPS). A container image build or Laravel Cloud already builds elsewhere — this pattern buys nothing.

Then check one thing that decides whether the build can move at all: **build-time env vars**. Grep for `import.meta.env.VITE_` (or `process.env.` in the build config). Every one of those is baked into the bundle when the build runs, so moving the build to CI means CI must supply them — as workflow `env:` from repository variables/secrets, per target branch. If the values differ between staging and production, they need a per-branch mapping before you write anything. Say so and settle it first; a silent default here ships a bundle pointing at the wrong backend.

## 2. Read the variables out of the repo

Don't ask — the repo answers all of them. Each one becomes an input of the shared workflow only when it differs from the default.

| Variable | Where it comes from |
| --- | --- |
| **Source branches** | The branches that deploy today. Usually `dev` and `main`; confirm with `git ls-remote --heads origin` and the existing workflows' `on: push: branches:`. |
| **Node version** | `.nvmrc`, then `package.json` `engines.node`, then whatever the existing CI workflows pin. The shared workflow reads `.nvmrc` by default — if the repo declares the version nowhere, add an `.nvmrc` rather than passing `node-version`. |
| **Build command** | `npm run build` (the default), or `npm run production` for Laravel Mix → `build-command`. |
| **Build artifacts** | Every gitignored path the build writes — see below → `paths`. |
| **Composer before the build** | Needed when the frontend imports from `vendor/` (Ziggy, the Vue pages of the `witify/*` packages): grep the JS for `vendor/` → `composer: true`, plus `php-version` when it isn't `8.4`. |
| **Laravel Pint auto-commit** | A workflow (usually named "Laravel Pint") that pushes a "Fix styling" commit. A push made with `GITHUB_TOKEN` starts no `push` run, so the caller also listens to that workflow with `workflow_run`. |
| **Target branch names** | `deploy` for the production source branch, `deploy-dev` for staging. Keep these names; the whole team reads them. |

**Enumerate the artifacts by building, not by guessing.** This is the step that goes wrong most often:

```bash
npm ci && npm run build
git status --porcelain --ignored public | grep '^!!'
```

Everything listed is written by the build and ignored by git — so everything listed must be force-added, or the deploy branch ships a partial build. A project with `vite-plugin-pwa` writing into `public/` also emits `public/sw.js` and `public/workbox-*.js`; miss those and production keeps serving a stale service worker forever, with no error anywhere to tell you. The default `paths` (`public/build public/sw.js public/workbox-*.js`, missing ones skipped) covers a Vite project with or without the PWA plugin; pass `paths` only when the command printed something else.

## 3. Write the caller workflow

`.github/workflows/build-deploy-branch.yml`, on `dev` and on the production branch:

```yaml
name: Build deploy branch

on:
  push:
    branches: [dev, main]
  workflow_run:
    workflows: ["Laravel Pint"]
    types: [completed]
    branches: [dev, main]

permissions:
  contents: write

jobs:
  build:
    uses: witify/workflows/.github/workflows/deploy-branch.yml@v1
    with:
      build-command: npm run production
      paths: public/css public/js public/mix-manifest.json
```

Adjust it to what step 2 found:

- `branches:` — `master` instead of `main` in both lists when that is the production branch. One source branch only? Keep it alone and pass `staging-branch: ""`.
- `workflow_run` — keep it only when the repo has the Pint auto-commit, with that workflow's exact `name`. Otherwise drop the block.
- `with:` — only the inputs that differ from the defaults (`build-command`, `paths`, `composer`, `php-version`, `node-version`; the full list is in the [witify/workflows README](https://github.com/witify/workflows#deploy-branch)). The example above is a Laravel Mix project; a standard Vite project has no `with:` at all.
- `production-branch` — pass it only while the repository's default branch is not the production branch (a default branch still on `dev`).

The shared workflow carries the rest: `contents: write`, a per-branch `concurrency` that cancels the older build so two pushes cannot race their force-pushes, `git add -f` of the existing paths (it fails when none exists, so a wrong `paths` shows as a red run), and the force-push. Call `@v1`, never `@main`.

To check the inputs before merging, push a throwaway branch whose caller sets `staging-branch` to that branch and `dry_run: true`: the run builds, lists the files it would commit, and pushes nothing. Delete the branch afterwards.

If the repo has rulesets or branch protection, exclude `deploy` and `deploy-dev` from anything that forbids force-pushes or requires PRs — otherwise the workflow fails on the push, after a green build.

## 4. Merge, and let the branches be born

The workflow only runs on push to a source branch, so the deploy branches do not exist until it has run once. Merge to `dev` (and `main`), then verify **before touching the host**:

```bash
git ls-remote --heads origin 'refs/heads/deploy*'
git fetch origin && git show --stat origin/deploy-dev -- public | head
```

The second command must show the build files in the branch's tip commit. If it shows nothing, the `git add -f` paths are wrong — fix them and push again.

## 5. Repoint Forge (human steps)

You cannot do this; the human does it in the Forge dashboard. Walk them through it one item at a time and wait for confirmation on each. Do the staging site first, verify it, then production.

1. **Site → Git repository → change the branch** to `deploy-dev` (staging site) or `deploy` (production site).
2. **Site → Deployments → edit the deploy script.** Two edits:
   - Replace `git pull origin $FORGE_SITE_BRANCH` with a fetch + reset. **This is mandatory, not a preference** — the deploy branch is force-pushed on every build, so a `pull` merge fails on divergent history and the deploy dies with the site on the old assets:
     ```bash
     git fetch origin $FORGE_SITE_BRANCH
     git reset --hard origin/$FORGE_SITE_BRANCH
     ```
   - Delete the asset build lines — `npm ci` / `npm install` / `npm run build` / `npm run prod`. Leave `composer install`, `php artisan migrate --force`, the cache commands, and the FPM reload exactly as they are.
3. **Quick Deploy stays on.** It fires on a push to the site's branch, which is now the deploy branch — so a merge to `dev` triggers the CI build, and the CI push triggers the deploy.
4. **Deploy once manually** from the dashboard and read the output.

If that first deploy fails with `untracked working tree files would be overwritten`, the server still holds a locally-built copy of the assets. Have them delete it on the server (`rm -rf public/build`, plus any other artifact path from step 2) and redeploy.

## 6. Verify the first deploy

- Deploy log shows no npm step and no build.
- The site loads: no `Vite manifest not found`, no 404s on `/build/assets/*` in the browser network tab.
- The asset hashes in the page source match `public/build/manifest.json` on the deploy branch.
- Push a trivial commit to the source branch and watch the full chain fire: workflow green → deploy branch moves → Forge deploys → new hashes live.

Verify staging end to end before repointing production.

## Rules that keep it working

- **Never commit to a deploy branch by hand.** The next build force-pushes over it and the change is gone.
- **Never open a PR against a deploy branch**, and never merge one into a source branch — it would drag the built assets into the source history, which is exactly what this pattern avoids.
- **Keep the build output gitignored** on the source branches. `git add -f` is doing the work; un-ignoring it would put built assets back in every feature branch diff.
- **When the build starts emitting a new artifact** — a plugin added, an output path changed — the `paths` input must grow with it. Re-run the step 2 command whenever the build config changes.
- **A failed build is silent.** When the workflow fails, the deploy branch simply stops moving and the site keeps serving the last good build — no deploy, no error on the host. The check, any time a deploy seems not to have landed, is whether the deploy branch's tip commit names the source branch's tip:
  ```bash
  git fetch origin && git log -1 --format=%s origin/deploy   # "build: <sha>"
  git rev-parse origin/main                                  # must be that same sha
  ```
- **A red test suite still ships.** This workflow builds on any push to a source branch, independent of the test workflow. If that's not acceptable, gate it with `on: workflow_run` against the test workflow's name and `conclusion == 'success'` — at the cost of a slower deploy.

## 7. Join the release flow

A project with `dev` and a production branch also uses the shared release workflows and the organization rulesets, so every repo works the same way. Point the human at the [witify/workflows README](https://github.com/witify/workflows#release-pr): add `release-pr.yml` and `release.yml`, make the production branch the repository's default branch, and turn on the custom property `release_flow`. Then take the default branch out of the check workflows (tests, Larastan, Pint, frontend): their `push` and `pull_request` triggers get a `branches` filter without it, or `branches-ignore: [<default branch>]`, so checks run on `dev` only. The release pull request brings the default branch the tree `dev` already checked, and the runs it would trigger wait for an approval nobody gives, then fail at the merge. Keep the checks on a repo with no `dev`, and on one whose default branch requires status checks. Skip all of this while `dev` is far ahead of the production branch (dozens of unreleased commits): merge them with a merge commit first, then join, so the first changelog stays readable.

## Done when

- `.github/workflows/build-deploy-branch.yml` calls `witify/workflows/.github/workflows/deploy-branch.yml@v1`, its inputs force-add every artifact the build writes, and it has run green.
- `deploy` and `deploy-dev` exist on the remote and carry the build in their tip commit.
- Each Forge site points at its deploy branch, its deploy script fetch-and-resets, and it contains no npm.
- A staging deploy has been verified end to end, then production.
