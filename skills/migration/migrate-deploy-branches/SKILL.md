---
name: migrate-deploy-branches
description: "Migrate a project to deploy branches: a GitHub Actions workflow builds the frontend assets and force-pushes source + build to `deploy` / `deploy-dev`, so the server never runs npm. Use when asked to migrate to deploy branches, build assets in CI instead of on the server, stop building on Forge, cut deploys over to a built branch, or add a `build-deploy-branch.yml` workflow."
---

# Migrate to deploy branches

A **deploy branch** is the source commit plus its built assets, committed. CI checks out the pushed commit on `dev` / `main`, runs the frontend build, force-adds the build output (normally gitignored), commits it, and force-pushes to `deploy-dev` / `deploy`. The host deploys those branches, so no build tooling ever runs on the server — no npm on production, no OOM-killed vite, no half-built assets served while the build is mid-flight.

Migrating is two halves: the **repo half** (a workflow file) and the **host half** (repointing the site and stripping the build out of its deploy script). Both must land, in that order. Repointing the host before the deploy branch exists breaks deploys.

## 1. Check the pattern applies

Skip and say so if any of these fail:

- `package.json` has a build script (`npm run build`) that emits into the repo — typically `public/build` via `laravel-vite-plugin`.
- The build output is **gitignored** on the source branches. If it's already committed, there's nothing to migrate; the project already ships built assets.
- Deploys pull a **git branch** (Forge, Envoyer, a bare `git pull` on a VPS). A container image build or Laravel Cloud already builds elsewhere — this pattern buys nothing.

Then check one thing that decides whether the build can move at all: **build-time env vars**. Grep for `import.meta.env.VITE_` (or `process.env.` in the build config). Every one of those is baked into the bundle when the build runs, so moving the build to CI means CI must supply them — as workflow `env:` from repository variables/secrets, per target branch. If the values differ between staging and production, they need a per-branch mapping before you write anything. Say so and settle it first; a silent default here ships a bundle pointing at the wrong backend.

## 2. Read the four variables out of the repo

Don't ask — the repo answers all four.

| Variable | Where it comes from |
| --- | --- |
| **Source branches** | The branches that deploy today. Usually `dev` and `main`; confirm with `git ls-remote --heads origin` and the existing workflows' `on: push: branches:`. |
| **Node version** | `.nvmrc`, then `package.json` `engines.node`, then whatever the existing CI workflows pin. Match CI to what the project already builds with — and if the repo declares it nowhere, add an `.nvmrc` rather than inventing a number that lives only in the workflow. |
| **Build artifacts** | Every gitignored path the build writes — see below. |
| **Target branch names** | `deploy` for the production source branch, `deploy-dev` for staging. Keep these names; the whole team reads them. |

**Enumerate the artifacts by building, not by guessing.** This is the step that goes wrong most often:

```bash
npm ci && npm run build
git status --porcelain --ignored public | grep '^!!'
```

Everything listed is written by the build and ignored by git — so everything listed must be force-added, or the deploy branch ships a partial build. `public/build/` is always there. A project with `vite-plugin-pwa` writing into `public/` also emits `public/sw.js` and `public/workbox-*.js`; miss those and production keeps serving a stale service worker forever, with no error anywhere to tell you. Adjust the paths in the workflow to exactly what this command printed.

## 3. Write the workflow

`.github/workflows/build-deploy-branch.yml`, with the four variables substituted:

```yaml
name: Build deploy branch

on:
  push:
    branches: [dev, main]

permissions:
  contents: write

concurrency:
  group: build-deploy-${{ github.ref_name }}
  cancel-in-progress: true

jobs:
  build:
    name: Build and push
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Build assets
        run: npm run build

      - name: Commit build and push to deploy branch
        run: |
          TARGET=$([ "${{ github.ref_name }}" = "main" ] && echo deploy || echo deploy-dev)
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add -f public/build
          git commit -m "build: ${{ github.sha }}"
          git push -f origin "HEAD:$TARGET"
```

Why each piece is there — keep them:

- `permissions: contents: write` — the default `GITHUB_TOKEN` is read-only in most repos, and the push is the whole point.
- `concurrency` with `cancel-in-progress` — two pushes in a minute would otherwise race to force-push, and the loser could land last with the older commit.
- `git add -f` — the build output is still gitignored; `-f` is what puts it on the deploy branch without un-ignoring it on the source branches.
- `push -f` — every build makes a fresh commit parented on the source commit, so the deploy branch is rewritten each time. It is a build artifact, not history.
- `node-version-file: .nvmrc` — reads the version the repo already declares, so CI and local dev can't drift apart. Pin `node-version:` inline only in a repo that has no `.nvmrc` and isn't getting one.

Only three things vary per project: the `branches:` list, the Node version source, and the `git add -f` paths from step 2. One source branch only? Drop the `TARGET` conditional and push straight to `deploy`.

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
- **When the build starts emitting a new artifact** — a plugin added, an output path changed — the `git add -f` list must grow with it. Re-run the step 2 command whenever the build config changes.
- **A failed build is silent.** When the workflow fails, the deploy branch simply stops moving and the site keeps serving the last good build — no deploy, no error on the host. The check, any time a deploy seems not to have landed, is whether the deploy branch's tip commit names the source branch's tip:
  ```bash
  git fetch origin && git log -1 --format=%s origin/deploy   # "build: <sha>"
  git rev-parse origin/main                                  # must be that same sha
  ```
- **A red test suite still ships.** This workflow builds on any push to a source branch, independent of the test workflow. If that's not acceptable, gate it with `on: workflow_run` against the test workflow's name and `conclusion == 'success'` — at the cost of a slower deploy.

## Done when

- `.github/workflows/build-deploy-branch.yml` exists, force-adds every artifact the build writes, and has run green.
- `deploy` and `deploy-dev` exist on the remote and carry the build in their tip commit.
- Each Forge site points at its deploy branch, its deploy script fetch-and-resets, and it contains no npm.
- A staging deploy has been verified end to end, then production.
