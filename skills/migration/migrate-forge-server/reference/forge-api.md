# Forge API v2 cheat sheet (what the migration uses)

Base URL `https://forge.laravel.com/api`. Every resource is scoped to an organization: `/orgs/{org}/...`. Headers: `Authorization: Bearer <token>`, `Accept: application/json`, `Content-Type: application/json`. Responses are JSON:API (`data.id`, `data.attributes`, `included`). Lists are cursor-paginated: `page[size]=100`, follow `meta.next_cursor` with `page[cursor]=`. Pass `-g` to curl (brackets). Writes are mostly **async** (`202 Accepted`): poll the resource until it reaches the expected state. The v1 API (`/api/v1/...`) is deprecated and 404s. Full spec: `GET https://forge.laravel.com/api/docs.openapi`.

`scripts/forge-api.sh` wraps all of this: `forge-api.sh GET servers`, `forge-api.sh POST 'servers/ID/sites' '{...}'`, `forge-api.sh wait 'servers/ID' '.data.attributes.is_ready' true`.

Two traps:

- **Transient 404 on a write.** A `POST .../deployments` or `POST .../certificates` sometimes answers `404` on a valid path and creates nothing; the same call a minute later works. Never send the HTTP status to `/dev/null` when you extract `data.id`: an id of `null` passed to `wait` polls a dead path until the timeout. On `404`, list the collection (`GET .../deployments`, `GET .../certificates`) to make sure nothing was created, then resend.
- **Raw control characters in lists.** The org-wide `GET sites` returns strings with unescaped control characters (deploy scripts, notes), which `jq` refuses (`Invalid string: control characters…`), so `forge-api.sh` falls back to the raw body. Parse those pages with Python's `json.loads(..., strict=False)` (send a `User-Agent`, Cloudflare answers 403 to urllib's default). The org-scoped site has no `relationships`: the server id is not in it, go through `GET servers/{s}/sites` instead.

## Discovery

| Need | Call |
| --- | --- |
| Org slug | `GET /orgs` → `data[0].attributes.slug` |
| All sites (find the one deploying this repo) | `GET /orgs/{org}/sites?page[size]=100` → `attributes.repository.url`, `relationships.server.data.id` |
| Server | `GET /orgs/{org}/servers/{server}` → `php_version`, `database_type`, `ubuntu_version`, `size`, `region`, `ip_address`, `provider`, `credential_id`, `is_ready` |
| Site | `GET /orgs/{org}/sites/{site}` → `name`, `root_directory`, `web_directory`, `zero_downtime_deployments`, `shared_paths`, `deployment_retention`, `quick_deploy`, `repository{url,branch,status}`, `database`, `aliases`, `https`. **Org-scoped only**: `GET .../servers/{s}/sites/{site}` answers with null attributes (and `wait` on it runs to its timeout). Sub-resources (`environment`, `deployments`, `domains`, `certificates`, `commands`, `integrations`, `scheduled-jobs`) are server-scoped. |
| Domains of a site | `GET .../servers/{s}/sites/{site}/domains` → `name`, `type` (primary/alias), `www_redirect_type` (from-www/to-www/none), `allow_wildcard_subdomains` |
| Certificates | `GET .../sites/{site}/certificates` → `type`, `status`, `active`; each `links.self` contains the domain id |
| .env | `GET .../sites/{site}/environment` → `attributes.content` |
| Deploy script | `GET .../sites/{site}/deployments/script` → `content`, `auto_source` |
| PHP settings (server) | `GET .../servers/{s}/php/max-upload-size`, `.../php/max-execution-time`, `.../php/opcache`, `.../php/versions` |
| Scheduled jobs | `GET .../servers/{s}/scheduled-jobs` (all) and `GET .../sites/{site}/scheduled-jobs` (site's) |
| Background processes (daemons) | `GET .../servers/{s}/background-processes` → `command`, `directory`, `user`, `processes`, `status` |
| Integrations | `GET .../sites/{site}/integrations/{horizon,laravel-scheduler,reverb,pulse,octane}` → `enabled` |
| Providers | `GET /providers` (ids: `1` DigitalOcean `ocean2`, `12` Laravel VPS `laravel`), `GET /providers/{p}/regions`, `GET /providers/{p}/sizes?page[size]=100` (several pages; no prices. `scripts/find-size.sh` searches both catalogs, finds equivalents of an existing server and adds indicative monthly prices (Laravel VPS: Business tier) from `https://vps.forge.laravel.com/api/prices` and DigitalOcean's pricing page) |
| Credentials | `GET /orgs/{org}/server-credentials` → pick the one whose `provider` matches |
| DigitalOcean VPCs | `GET /orgs/{org}/server-credentials/{credential}/regions/{region code}/vpcs` → `id` (uuid), `name` (`laravel-forge-tor1` is Forge's own; `default-tor1` DigitalOcean's) |
| Request schemas | `GET https://forge.laravel.com/api/docs.openapi` → `components.schemas.CreateServerRequest`, `CreateSiteRequest`, `SiteType` (`laravel, symfony, statamic, wordpress, phpmyadmin, php, nextjs, nuxtjs, static-html, other, custom`), `CreateBackgroundProcessRequest`. Read it when a `422` names a field the cheat sheet does not. |

## Create

**Server** `POST /orgs/{org}/servers` (async, then poll `is_ready`):

```json
{
  "name": "la-erp", "provider": "laravel", "credential_id": 244065, "type": "app",
  "ubuntu_version": "26.04", "php_version": "php83", "database_type": "mysql84",
  "laravel": { "region_id": "tor1", "size_id": "8" }
}
```

Laravel VPS takes the **codes** too (`tor1`, size code `8`), not the numeric ids that `find-size.sh` prints as `SIZE_ID`: those answer `404 No query results for model [ProviderRegion]` (region) or `[ProviderSize]` (size), and nothing is created.

DigitalOcean takes the **codes**, and a VPC is mandatory:

```json
{
  "name": "boursify-play-2", "provider": "ocean2", "credential_id": 52421, "type": "app",
  "ubuntu_version": "26.04", "php_version": "php83", "database_type": "mysql84",
  "ocean2": { "region_id": "tor1", "size_id": "s-1vcpu-1gb", "vpc_uuid": "<from the vpcs listing>", "enable_weekly_backups": false }
}
```

Numeric ids on `ocean2` answer `422 The selected region is invalid` plus `The private network field is required`. (`find-size.sh` prints both `SIZE_ID` and `CODE`; the server resource later reports `size` as the numeric id.) The `202` response's `data.meta` holds `sudo_password` and `database_password` in clear: store them in `new-secrets.txt` (600) first, never `cat` the raw response.

**Database** `POST .../servers/{s}/database/schemas` `{"name": "<project>_production"}` → poll `status == installed`. The `forge` user has access to every schema. Set its password with `PUT .../servers/{s}/database/password` `{"password": "..."}`.

**Database user** `POST .../servers/{s}/database/users` `{"name": "reader", "password": "...", "database_ids": [1804271, 1804273], "read_only": true}` → poll `GET .../database/users/{u}` until `status == installed`. `read_only` is ignored: the user gets `ALL PRIVILEGES ... WITH GRANT OPTION` on each schema. Fix it in MySQL as `forge` (`REVOKE ALL PRIVILEGES, GRANT OPTION FROM reader@'%'`, then `GRANT SELECT, SHOW VIEW ON <db>.* TO reader@'%'`).

**Nginx config of a site** `GET .../servers/{s}/sites/{site}/nginx` → `attributes.content`; `PUT` the same path with `{"config": "<full file>"}` (the field is `config`; `content` answers `422 The config field is required`). Forge validates and reloads nginx.

**Site** `POST .../servers/{s}/sites` (async, poll `status == installed` then `repository.status == installed`):

```json
{
  "type": "laravel", "domain_mode": "on-forge", "name": "<slug>",
  "php_version": "php83",
  "zero_downtime_deployments": true, "shared_paths": [{"from": "storage", "to": "storage"}],
  "source_control_provider": "github", "repository": "witify/<repo>", "branch": "<migration branch>",
  "database_id": 1799391, "push_to_deploy": false
}
```

`domain_mode: on-forge` gives `<name>.on-forge.com`. Omit `shared_paths` when the old site is not zero-downtime. Keep `push_to_deploy: false` until the end. The site comes up with `web_directory` at the site root (nginx 403): `PUT .../servers/{s}/sites/{site}` `{"directory": "/public"}` right after install. `mark-as-primary` on a custom domain later renames the whole site directory to `/home/forge/<domain>`.

**Update site** `PUT .../servers/{s}/sites/{site}` `{"deployment_retention": 4}` (also `php_version`, `push_to_deploy`, `directory`). The org-scoped `PUT /orgs/{org}/sites/{site}` answers `405`.

**Git** `PUT .../sites/{site}/git` `{"source_control_provider": "github", "repository": "witify/<repo>", "branch": "master"}`.

**.env** `PUT .../sites/{site}/environment` `{"environment": "<full content>", "cache": true, "queues": true}` — `cache` reruns the config cache, `queues` restarts the queue workers. Async (`202`): read it back with `GET` before the first deployment.

**Deploy script** `PUT .../sites/{site}/deployments/script` `{"content": "<script>", "auto_source": false}` (sync).

**Deploy** `POST .../sites/{site}/deployments` → `data.id`; poll `GET .../deployments/{id}` until `status` ∈ `finished | failed | failed-build | cancelled`; log at `GET .../deployments/{id}/log` → `attributes.output`. `GET .../deployments/status` shows the in-flight deployment. `POST .../deployments/push-to-deploy` enables quick deploy, `DELETE` disables it.

**Command on the site** `POST .../sites/{site}/commands` `{"command": "node -v"}` → poll `GET .../commands/{id}` until `status == finished`, output at `.../commands/{id}/output`.

**Domain** `POST .../sites/{site}/domains` `{"name": "app.client.com", "allow_wildcard_subdomains": false, "www_redirect_type": "none"}` → poll `status == enabled`. Then `POST .../domains/{d}/actions` `{"action": "mark-as-primary"}` (also `enable`, `disable`). `PATCH .../domains/{d}` `{"www_redirect_type": "from-www"}` changes the www behaviour.

**Certificate** `POST .../domains/{d}/certificates`:

- Let's Encrypt: `{"type": "letsencrypt", "letsencrypt": {"verification_method": "http-01", "key_type": "ecdsa"}}` — DNS must already resolve to the server.
- Existing: `{"type": "existing", "enable": true, "existing": {"key": "<pem>", "certificate": "<pem chain>"}}`.

Poll `GET .../domains/{d}/certificates/{c}` until `status == installed` and `active == true`. `POST .../certificates/{c}/actions` `{"action": "enable"}`.

**PHP settings (server-wide)** `PUT .../servers/{s}/php/max-upload-size` and `PUT .../php/max-execution-time` both take `{"max_upload_size": 50, "max_execution_time": 300, "memory_limit": 256, "opcache": true}` (all optional). `POST .../php/opcache` enables OPcache, `DELETE` disables it. `POST .../php/versions` `{"version": "php83", "cli_default": true, "site_default": true}` installs another version.

**Scheduled job** `POST .../sites/{site}/scheduled-jobs` `{"name": "...", "command": "...", "user": "forge", "frequency": "custom", "cron": "* * * * *"}` (`frequency`: minutely, hourly, nightly, weekly, monthly, reboot, custom). Delete with `DELETE .../scheduled-jobs/{job}`; there is no disable.

**Background process** `POST .../servers/{s}/background-processes` `{"name": "...", "command": "php8.3 artisan horizon", "directory": "/home/forge/<site>/current", "user": "forge", "processes": 1, "site_id": 123}`. Actions: `POST .../background-processes/{p}/actions` `{"action": "stop"}` (`start`, `restart`, `empty-log`). `DELETE` removes it. Its output is in `/home/forge/.forge/daemon-<id>.log` on the server.

**Integrations** (site):

- `POST .../integrations/laravel-scheduler` (no body) creates the "Laravel Scheduler" cron for the site; `DELETE` removes it.
- `POST .../integrations/horizon` (no body) creates the Horizon daemon; `DELETE` removes it.
- `POST .../integrations/reverb` `{"host": "ws.app.client.com", "port": "8080", "connections": 1000}`; `DELETE`.
- `POST .../integrations/pulse` (no body); `DELETE`.
- `POST .../integrations/laravel-maintenance` `{"status": 503}` puts the site in maintenance through Forge; `DELETE` brings it up. The transfer script uses `php artisan down` directly instead.

**Services** `POST .../servers/{s}/services/php/actions` `{"action": "reload", "version": "php83"}`, `.../services/supervisor/actions` `{"action": "reboot"}`, `.../services/nginx/actions` `{"action": "restart"}`.

## Redis transfer

When phase 1 found application data in Redis (keys without TTL outside `laravel_cache`/sessions), it moves as a whole database, after the MySQL transfer, in both the rehearsal and the cutover:

1. On the new server, `redis-cli config get appendonly` must be `no` (otherwise Redis ignores `dump.rdb` at startup).
2. On the old server, a client-side snapshot, no sudo, Redis stays online: `redis-cli -a <REDIS_PASSWORD> --no-auth-warning --rdb /home/forge/redis-old.rdb` (the password is in the site's `.env`). Note `dbsize` and three keys with their values (`--scan --pattern 'd:*' | head -3`, then `get`).
3. `scp` to `~/Downloads/redis-<date>.rdb`, delete it on the old server, `scp` to `/home/forge/redis-old.rdb` on the new one.
4. On the new server, a script run with `echo <sudo password> | sudo -S -p '' bash <script>` (the password from the `Sudo` line of `new-secrets.txt`; quote nothing else on that line): `systemctl stop redis-server`, keep `/var/lib/redis/dump.rdb` as `dump.rdb.before`, copy the file in, `chown redis:redis`, `chmod 660`, `systemctl start redis-server`, `systemctl is-active redis-server`. Delete the script and the copy.
5. `redis-cli dbsize` equals the old count (give or take the sessions that expired meanwhile) and the three sampled keys return the same values.

RDB files from Redis 5 load in Redis 8. The key prefix (`database.redis.options.prefix`) must be the same in both deployments, which it is when the `.env` was carried over.

## Non-Laravel site

A Node process (pm2, `server.js`) that lived next to the Laravel site moves as a Forge site plus a daemon:

1. `POST .../servers/{s}/sites` `{"type": "other", "domain_mode": "custom", "name": "<name>", "www_redirect_type": "none", "source_control_provider": "github", "repository": "<owner/repo>", "branch": "master", "push_to_deploy": false, "install_composer_dependencies": false}`; wait `status` and `repository.status` installed. Root is `/home/forge/<name>`.
2. `PUT .../environment` with the old site's `.env`; `PUT .../deployments/script` with `cd /home/forge/<name>`, `git pull origin $FORGE_SITE_BRANCH`, `npm ci --omit=dev`, `pkill -u forge -f "node server.js" || true` (supervisor restarts the daemon). Deploy, then over SSH `timeout 4 node server.js` must print its startup lines.
3. On the old server, `pm2 stop <name> && pm2 save` (`ps -u forge -o pid,cmd | grep node` must be empty afterwards; a bare `pgrep -f` matches its own shell).
4. `POST .../servers/{s}/background-processes` `{"name": "<name>", "command": "node server.js", "directory": "/home/forge/<name>", "user": "forge", "processes": 1, "site_id": <new site>}`; wait `running`; read `/home/forge/.forge/daemon-<id>.log`.
5. `POST .../deployments/push-to-deploy` when the old site had quick deploy.

Stop the old process before starting the new one when the process has side effects (a clock that advances game time ticks twice otherwise).
