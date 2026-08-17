---
"witify-skills": minor
---

New `migration/` bucket for one-way moves that run once per project, starting with **migrate-deploy-branches**: it takes a project's frontend build off the server, adding a GitHub Actions workflow that builds the assets and force-pushes source + build to `deploy` / `deploy-dev`, then walks you through repointing Forge at those branches and stripping npm out of the deploy script. It enumerates the artifacts to commit by building rather than guessing (a PWA's `sw.js` is the one that gets missed), and swaps the deploy script's `git pull` for a fetch-and-reset, without which a force-pushed deploy branch breaks every deploy.
