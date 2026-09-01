---
"witify-skills": minor
---

`witify-doctor` now checks the Polyscope workspace at level 1. `polyscope.json`, `polyscope-db.sh`, and `polyscope-env.sh` join the artefacts a project should track like sprintify does, and `polyscope.json`'s contents are read: every command in its `setup`, `archive`, and `run` has to resolve, and every `bash <name>.sh` has to name a script the fork actually copied — a workspace that can't be created is a broken onboarding, not a style difference.

The steps are never compared verbatim. A project with no Horizon to start, another PHP version to isolate, or `npm run production` where sprintify runs `npm run dev` keeps its own shape; only a sprintify step with nothing in its place — a missing `boost:update` leaving a fresh workspace without published guidelines, a missing `migrate-test` leaving its test database unmigrated — is reported as drift.
