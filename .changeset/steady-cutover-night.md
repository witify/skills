---
"witify-skills": minor
---

New `release-checklist` skill (user-invoked, `/release-checklist`). It writes the go/no-go checklist for a production deployment from one prompt: chronological phases of one-line checkboxes owned by the dev team, blocking and non-blocking criteria with thresholds, the decision rule (go, decide again, no-go), the witness records to compare after a data import, and a first draft of every email, client request, and rollback plan. It tells a cutover from a legacy system, the launch of a new app, and the release of a big feature apart from the repo and the invocation, keeps only the phases each one earns, and marks every unsourced value `À confirmer` for the human review. The Markdown lands in `qa/release-checklist-<slug>.md`, uncommitted, and renders through `witify-docx` on request.
