# Migration

One-way moves from one setup to another — a linter swap, a deploy model change. Each runs once per project and then stops being relevant, which is why they live apart from the daily skills.

## User-invoked

Reachable only when you type them (Claude Code: `disable-model-invocation: true`; Codex: `policy.allow_implicit_invocation: false` in `agents/openai.yaml`).

- **[migrate-forge-server](./migrate-forge-server/SKILL.md)** — Move a Laravel site from an obsolete Forge server to a new one through the Forge API: upgrade branch with deep verification, new server and site, `.env` and deploy script carried over, rehearsal transfer on `*.on-forge.com`, real cutover with the old site down, cron/daemons/integrations moved, DNS and SSL.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[migrate-deploy-branches](./migrate-deploy-branches/SKILL.md)** — Move a project to deploy branches: a GitHub Actions workflow builds the frontend assets and force-pushes source + build to `deploy` / `deploy-dev`, and Forge deploys those instead of building on the server.
