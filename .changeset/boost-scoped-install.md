---
"witify-skills": patch
---

Stop the repo-internal `upstream-sync` dev skill from being installed by skill installers. The README's Laravel Boost instructions now use bucket-scoped paths (`witify/skills/skills/engineering` and `witify/skills/skills/productivity`) — Boost's `boost:add-skill` matches every `SKILL.md` in a repo with no exclusion mechanism, so the previous bare `witify/skills` form also installed `.claude/skills/upstream-sync` and unfinished `in-progress/` drafts. For skills.sh, `upstream-sync` is now marked `metadata.internal: true`, which hides it from discovery.
