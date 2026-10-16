# Upstream sync state

Data for [`upstream-sync`](PROCESS.md). Updated at the end of every sync — the PROCESS.md process never changes here, only the facts.

## Sync point

- Upstream: https://github.com/mattpocock/skills
- Last synced commit: `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76` (2026-08-24)

## What is still vendored

Three skills descend from upstream, all **adapted**: `skills/engineering/to-spec`, `skills/engineering/to-tickets`, and `skills/engineering/code-review` (same paths upstream). Every other skill in this repo is local-only and upstream changes never touch it. On 2026-10-16 every other vendored skill was removed, including upstream's verbatim copies; do not re-vendor them during a sync — a new or returning upstream skill is a maintainer decision, surfaced in the report, never copied in.

## Adaptation ledger

All three remaining files are ledger files: **never blind-copy**, always merge upstream hunks by hand around the local design.

- `skills/engineering/to-spec/SKILL.md` — publishes directly to ClickUp (default) or Linear over MCP, with a "Tracker" section that checks the MCP tools are available and resolves the destination; no setup skill, no triage label, no local-file fallback; keeps "(you may know this document as a PRD)".
- `skills/engineering/to-tickets/SKILL.md` — same "Tracker" section; tickets are always sub-tasks of a parent with native dependencies (`clickup_add_task_dependency` / Linear blocked-by); **strict linear ticket chain** (parallel tickets never allowed); no PR-mode step (a set always ships as one PR, `/ship`'s only mode); no local-file ticket template, no triage label. Deliberate local features; upstream dropped none of them knowingly — always merge around them.
- `skills/engineering/code-review/SKILL.md` — closest to upstream: keeps "PRD" terminology; the setup pointer is replaced by the same tracker rule as the other two (ClickUp default, Linear on request, spec fetched over MCP, no `.scratch/` lookup). Everything else, in particular the smell baseline and the two-sub-agent process, is upstream's — take upstream's hunks, re-apply the tracker paragraph and the spec-source step.

### Em-dash drift

Upstream removed every em-dash from its prose in 2026-08 (`3216582`). Local prose keeps em-dashes. **This is cosmetic drift, not an adaptation**: never port em-dash-only hunks, and never rewrite a local skill to match.

## Ignore rules

- Every upstream skill other than `to-spec`, `to-tickets`, and `code-review` is ignored, including ones this repo used to vendor.
- Upstream repo scaffolding (`CHANGELOG.md`, `package.json`, `.changeset/`, `scripts/`, `CONTEXT.md`, `AGENTS.md`, `CLAUDE.md`) is never synced.
- Upstream's bucket `README.md`s and `docs/` are never copied: local ones describe this repo's own set.
