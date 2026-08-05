---
"witify-skills": patch
---

The maintainer-only `upstream-sync` skill is no longer a skill at all: it now lives as a plain process doc at `.agents/upstream-sync/`, documented in the README's new "Syncing with Upstream" section. Skill installers (Laravel Boost's `boost:add-skill`, skills.sh) discover skills by scanning the repo for files named `SKILL.md`, so removing the marker file — rather than relying on per-installer exclusion flags — is what guarantees internal tooling never ships.
