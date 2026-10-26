Quickstart:

```bash
npx skills add witify/skills --skill=migrate-forge-server
```

```bash
npx skills update migrate-forge-server
```

[Source](https://github.com/witify/skills/tree/main/skills/migration/migrate-forge-server)

## What it does

`migrate-forge-server` moves a Laravel site off a Forge server whose PHP, MySQL or Ubuntu is too old and onto a fresh one, through the Forge API. It upgrades the code on a branch and verifies it deeply first, creates the new server and site, carries the `.env` and the deploy script over, rehearses the data transfer onto the `*.on-forge.com` name, then runs the real cutover with the old site down, moves cron, daemons and integrations, switches DNS and issues SSL.

Nine phases, each opened by a banner (`PHASE 3/9 · NOUVEAU SERVEUR`) and closed by a checkpoint in the same shape every time: a short result table, one status line (🟢 nothing to read, 🟡 worth reading, 🔴 your attention or your decision), the next phase in plain French sentences, and one question. The agent speaks in words, never in endpoints, and it never runs two phases on one « go ». The old server is read-only until the real transfer, and the choices that are yours (server size and region, server and on-forge names, database name, the rehearsal, DNS and archiving gates) are asked, never guessed. For the size, it reads the old server's live capacity and lists the equivalent sizes on DigitalOcean and Laravel VPS with indicative monthly prices, or searches them from words like `premium intel 8gb 4vcpu`.

## When to reach for it

You invoke this by typing `/migrate-forge-server` — the agent won't reach for it on its own.

Reach for it when a Forge server has to be replaced, not patched: an Ubuntu or MySQL version at end of life, a PHP version the project must leave behind, a droplet that must change provider or size with a clean install. For moving the asset build off the server, use [migrate-deploy-branches](./migrate-deploy-branches.md) instead.

## Prerequisites

A Forge API token in `~/laravel-forge-token` (or `FORGE_API_TOKEN`), SSH access as `forge` to the old server, `jq`, `dig` and `gh`, and the project checked out in the cwd with its GitHub remote. The skill writes its state and temporary secrets under `~/.forge-migrations/<project>/` and keeps copies of the exports in `~/Downloads`.

## Rehearse, then cut over

The migration is two transfers of the same data. The **rehearsal** leaves the old site online and lets you test the new one on its on-forge name with real records; nothing on the old server changes. The **cutover** stops the old site's scheduler and daemons, puts it in maintenance, exports, and only then starts the automation on the new site. The downtime spans the cutover and the DNS phase, so they run back to back, and the skill tells you the one moment to change DNS: after the old certificate and the production `.env` are on the new site, never before. Let's Encrypt follows once `dig` answers with the new IP, and the copied certificate is removed.

The new server also gets a `reader` MySQL user with a generated password and `SELECT` only, created with the server so that its IP, sudo, database and reader secrets land in one file and go into the password manager in one go; the last phase has you verify all four from the password manager before the file is deleted.

## It's working if

- Every phase opens with a `PHASE N/9` banner and ends with one 🟢, 🟡 or 🔴 status line; a 🟢 means you can answer « go » without reading.
- The announcements are sentences, not API calls; ids and payloads stay in the tool calls.
- Nothing is sent to the old server before you approve the real transfer, and the sentence asking for it names it as such.
- The DNS change is asked once, in red, in phase 8, and the agent says so from phase 1.
- The `.env` diff shows key names and domain values, never a secret.
- The transfer script prints its own rollback commands at the end.

## Where it fits

A run-once cutover, standalone. Its sibling is [migrate-deploy-branches](./migrate-deploy-branches.md), which changes how the site is built, not where it runs; a project can take both, in either order.
