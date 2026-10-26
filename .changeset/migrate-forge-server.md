---
"witify-skills": minor
---

New `migrate-forge-server` skill: move a Laravel site from an obsolete Forge server to a new one through the Forge API. Upgrade branch with deep verification (PHP 8.3, MySQL 8.4, Node), new server and site, `.env` and deploy script carried over, rehearsal data transfer on `*.on-forge.com`, real cutover with the old site down, cron/daemons/integrations moved, DNS switch on the Witify A record, SSL without a gap. Phase by phase, each ending at a checkpoint. Nine phases with a fixed banner, a fixed checkpoint layout (result table, one 🟢/🟡/🔴 status line, next phase in plain French, one question), the DNS change asked at one explicit moment, a `reader` MySQL user with a generated password stored with the other server secrets, zero-downtime and push-to-deploy on by default, and the copied certificate removed once Let's Encrypt is active.
