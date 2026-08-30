---
"witify-skills": minor
---

`ship` now names the branch it works on: `feat/<ticket-id>-<slug>` (or `fix/` for a set of bug fixes), so the tracker id and a short description of the change are both readable from `git branch`. When the session already starts on a branch created by a workspace tool — Polyscope's `azure-ant`, a `codex/…` — it renames that branch in place instead of cutting a new one off `dev`, keeping the checkout and base that tool set up.
