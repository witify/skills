# Migration

One-way moves from one setup to another — a linter swap, a deploy model change. Each runs once per project and then stops being relevant, which is why they live apart from the daily skills.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[migrate-deploy-branches](./migrate-deploy-branches/SKILL.md)** — Move a project to deploy branches: a GitHub Actions workflow builds the frontend assets and force-pushes source + build to `deploy` / `deploy-dev`, and Forge deploys those instead of building on the server.
