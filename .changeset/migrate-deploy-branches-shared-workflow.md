---
"witify-skills": minor
---

`migrate-deploy-branches` now writes a small caller of the shared Deploy branch workflow of witify/workflows instead of copying the build steps into each project: the build command, the built paths, composer and the Node version become inputs, and a fix to the build lands once for every project. It also covers Laravel Mix projects, the Laravel Pint auto-commit, a dry run before merging, and ends by pointing at the release flow (release pull request, organization rulesets).
