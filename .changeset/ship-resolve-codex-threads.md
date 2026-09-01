---
"witify-skills": minor
---

`/ship` now closes the loop on Codex instead of leaving its comments hanging. When `gh` is installed, each feedback wave ends by replying to every Codex comment — in the comment's own language — with what was decided (fixed, with a commit link; rejected, with why; deferred; or, in analysis-only mode, the judgment itself), then resolving that thread.

Only threads Codex authored are resolved. A human's thread stays open for `/fix-review`, which still never closes anyone's thread.
