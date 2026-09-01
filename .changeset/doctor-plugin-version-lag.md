---
"witify-skills": patch
---

`witify-doctor` now sizes the `witify-skills` version gap at level 0 before reporting it. Both harnesses re-resolve the plugin at the next session start, and a `/plugin` update mid-session leaves the other scopes behind until then, so a single release behind is churn that closes itself — the doctor calls it `Healthy` and says why, instead of opening a decision the user has to answer to make nothing happen.

More than one release behind still reports: that is a cache that has stopped moving, not a session-start lag. Whether the plugin is enabled, and whether the same skills are installed twice, remain findings at any version.
