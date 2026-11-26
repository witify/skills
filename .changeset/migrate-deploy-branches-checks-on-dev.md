---
"witify-skills": patch
---

`migrate-deploy-branches` now takes the default branch out of the check workflows (tests, Larastan, Pint, frontend) when a project joins the release flow, so checks run on `dev` only. The release pull request already brings the default branch the tree `dev` checked, and the runs it triggered waited for an approval, then failed at the merge.
