# Upstream sync state

Data for [`upstream-sync`](PROCESS.md). Updated at the end of every sync — the PROCESS.md process never changes here, only the facts.

## Sync point

- Upstream: https://github.com/mattpocock/skills
- Last synced commit: `6654f6b60cd9d5be8b54c6fafe44346dabeb3b76` (2026-08-24)

## Name and bucket mappings

Upstream path → local path. Anything not listed maps 1:1.

| Upstream | Local |
| --- | --- |
| `skills/engineering/ask-matt` | `skills/engineering/ask-witify` |
| `skills/engineering/setup-matt-pocock-skills` | `skills/engineering/setup-witify-skills` |
| `skills/productivity/wait-what` | `skills/in-progress/wait-what` (not yet promoted) |
| `skills/misc/`, `skills/deprecated/` | ignored — never vendored |
| `docs/` | consulted for phrasing only; local docs pages follow `.agents/writing-docs.md`, never copied verbatim |

Local-only skills (no upstream counterpart — upstream changes never touch them): `audits`, `authorization`, `confirm-request`, `create-guideline`, `fix-review`, `frontend-development`, `jobs-development`, `larastan`, `loom`, `migrate-deploy-branches`, `notification-development`, `ship`, `sprintify-sync`, `sprintify-ui`, `translations`, `witify-docx`.

## Adaptation ledger

Files we deliberately diverge on. Everything vendored and not listed here is a **verbatim copy** of upstream at the sync point.

Entries marked **copy + re-apply** are upstream-verbatim except for the one line named: take upstream's file wholesale, then re-apply that line.

- `skills/engineering/ask-witify/` — full rebrand of `ask-matt`; routes only this repo's promoted set, and its "Crossing sessions" section replaces upstream's "Phase boundaries" section, so `PHASE-BOUNDARIES.md` is deliberately **not vendored**. Merge upstream flow changes by hand.
- `skills/engineering/setup-witify-skills/SKILL.md` — rebrand of `setup-matt-pocock-skills`; trackers limited to Linear, ClickUp, local files, so `issue-tracker-github.md` and `issue-tracker-gitlab.md` are deliberately **not vendored**.
- `skills/engineering/setup-witify-skills/issue-tracker-local.md` — **copy + re-apply**: "Issues and specs (you may know a spec as a PRD) for this repo…".
- `skills/engineering/code-review/SKILL.md` — keeps "PRD" terminology; `/setup-witify-skills` reference.
- `skills/engineering/to-spec/SKILL.md` — keeps "(you may know this document as a PRD)"; setup reference.
- `skills/engineering/to-tickets/SKILL.md` — **strict linear ticket chain** (parallel tickets never allowed) and the **PR-mode** step (`single-pr` / `split-pr` labels, recorded on the parent). Deliberate local features; upstream dropped neither knowingly — always merge around them.
- `skills/engineering/triage/SKILL.md` — setup reference only.
- `skills/engineering/triage/AGENT-BRIEF.md` — **copy + re-apply**: the brief is tracker-agnostic (upstream's is GitHub-specific) — the opening "posted on a tracker issue (or PR, where the tracker treats PRs as a request surface)" line, and the **Good:** example phrased as "Listing tracker issues labelled `needs-triage`…" rather than a `gh` command.
- `skills/engineering/wayfinder/SKILL.md` — setup reference; the **Grilling** ticket-type bullet keeps the local "one question at a time" phrasing; `*` vs `_` emphasis style drift is cosmetic, either side fine.
- `skills/engineering/improve-codebase-architecture/SKILL.md` — reports in English **or French** depending on the user's prompt language.
- `skills/engineering/improve-codebase-architecture/HTML-REPORT.md` — **copy + re-apply**: the Tone section's "Plain English or French depending on user prompt language".
- `skills/productivity/writing-for-agents/SKILL.md` — **copy + re-apply**: the local **"Laravel Boost projects"** section appended at the end.
- `skills/in-progress/claude-handoff/SKILL.md` — keeps "PRDs" in the artifact list.

### Em-dash drift

Upstream removed every em-dash from its prose in 2026-08 (`3216582`) and added a no-em-dash rule to its own `CLAUDE.md`/`AGENTS.md` — repo scaffolding this repo never syncs. Verbatim files therefore carry upstream's colon/parenthesis phrasing, while local-only skills and ledger prose keep em-dashes. **This is cosmetic drift, not an adaptation**: never port em-dash-only hunks into a ledger file, and never rewrite a local skill to match. One consequence worth remembering: upstream had to quote SKILL.md `description:` values whose em-dash became a colon (`5c89081`); local descriptions keeping the em-dash need no quoting.

## Ignore rules

- Upstream `in-progress/` skills we never vendored (`setup-ts-deep-modules`, `writing-beats`, `writing-fragments`, `writing-shape`) stay unvendored until the maintainer opts in.
- Upstream repo scaffolding (`CHANGELOG.md`, `package.json`, `.changeset/`, `scripts/`, `CONTEXT.md`, `AGENTS.md`, `CLAUDE.md`) is never synced.
- Upstream's bucket `README.md`s are never copied: local ones describe this repo's own set.
