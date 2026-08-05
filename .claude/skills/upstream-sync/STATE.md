# Upstream sync state

Data for [`upstream-sync`](SKILL.md). Updated at the end of every sync — the SKILL.md process never changes here, only the facts.

## Sync point

- Upstream: https://github.com/mattpocock/skills
- Last synced commit: `8b36d4fb2635b3c21998dcd8144439c9e5ba7302` (2026-08-05)

## Name and bucket mappings

Upstream path → local path. Anything not listed maps 1:1.

| Upstream | Local |
| --- | --- |
| `skills/engineering/ask-matt` | `skills/engineering/ask-witify` |
| `skills/engineering/setup-matt-pocock-skills` | `skills/engineering/setup-witify-skills` |
| `skills/productivity/wait-what` | `skills/in-progress/wait-what` (not yet promoted) |
| `skills/misc/`, `skills/deprecated/` | ignored — never vendored |
| `docs/` | consulted for phrasing only; local docs pages follow `.agents/writing-docs.md`, never copied verbatim |

Local-only skills (no upstream counterpart — upstream changes never touch them): `fix-review`, `sprintify-sync`, `sprintify-ui`, `frontend-development`, `frontend-design`, `audits`, `authorization`, `confirm-request`, `create-guideline`, `jobs-development`, `larastan`, `notification-development`, `translations`.

## Adaptation ledger

Files we deliberately diverge on. Everything vendored and not listed here is a **verbatim copy** of upstream at the sync point.

- `skills/engineering/ask-witify/` — full rebrand of `ask-matt`; routes only this repo's promoted set. Merge upstream flow changes by hand.
- `skills/engineering/setup-witify-skills/` — rebrand of `setup-matt-pocock-skills`; trackers limited to Linear, ClickUp, local files.
- `skills/engineering/code-review/SKILL.md` — keeps "PRD" terminology; `/setup-witify-skills` reference.
- `skills/engineering/to-spec/SKILL.md` — keeps "(you may know this document as a PRD)"; setup reference.
- `skills/engineering/to-tickets/SKILL.md` — **strict linear ticket chain** (parallel tickets never allowed) and the **PR-mode** step (`single-pr` / `split-pr` labels, recorded on the parent). Deliberate local features; upstream dropped neither knowingly — always merge around them.
- `skills/engineering/triage/SKILL.md` + `AGENT-BRIEF.md` — setup reference; brief is tracker-agnostic (upstream's is GitHub-specific).
- `skills/engineering/wayfinder/SKILL.md` — setup reference; `*` vs `_` emphasis style drift is cosmetic, either side fine.
- `skills/engineering/improve-codebase-architecture/` — reports in English **or French** depending on the user's prompt language.
- `skills/productivity/writing-for-agents/SKILL.md` — local **"Laravel Boost projects"** section appended at the end; re-append after any upstream copy.
- `skills/in-progress/claude-handoff/SKILL.md` — keeps "PRDs" in the artifact list.

## Ignore rules

- Upstream `in-progress/` skills we never vendored (`setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape`) stay unvendored until the maintainer opts in.
- Upstream repo scaffolding (`CHANGELOG.md`, `package.json`, `.changeset/`, `scripts/`, `CONTEXT.md`, `AGENTS.md`, `CLAUDE.md`) is never synced.
