---
name: upstream-sync
description: Sync this repo's skills with the upstream mattpocock/skills repo — pull upstream changes since the recorded sync point, preserve local adaptations, do the promotion bookkeeping, and advance the sync point.
disable-model-invocation: true
---

# Upstream sync

This repo vendors and adapts skills from [mattpocock/skills](https://github.com/mattpocock/skills). Sync is **ledger-driven**: [`STATE.md`](STATE.md) records the **sync point** (the last upstream commit already merged) and the **adaptation ledger** (the files we deliberately diverge on, and how). Every file that came from upstream and is *not* in the ledger is a verbatim copy — upstream's new version replaces it without inspection.

## Process

### 1. Load the state

Read [`STATE.md`](STATE.md): the sync point, the name/bucket mappings, and the ledger.

### 2. Compute what changed upstream

Clone upstream (full clone — the repo is small and the sync point must be reachable) into the scratchpad, then:

```bash
git log <sync-point>..HEAD --oneline
git diff <sync-point>..HEAD --stat -- skills/ docs/
```

Done when **every changed upstream path is classified** into exactly one of: verbatim copy, ledger merge, new skill, rename/move, or ignore (per STATE.md's ignore rules). An unclassified path is an unfinished step.

### 3. Apply, by classification

- **Verbatim copy** — overwrite the local file with upstream's (map the path through STATE.md first).
- **Ledger merge** — port the upstream hunks around the recorded adaptations; the adaptation survives, the upstream improvement lands. Never blind-copy a ledger file.
- **New skill** — copy into `skills/in-progress/` and add its entry to that bucket's README. Promotion is the maintainer's call, not yours — surface it in the report.
- **Rename / bucket move** — mirror it with `git mv`, then treat content as verbatim or ledger merge as usual. If the file is verbatim locally but the ledger notes an appended local section (e.g. `writing-for-agents`'s Laravel Boost section), re-append it after copying.
- Upstream deleting a skill only deletes locally if the skill came from upstream — never a local-only skill.

### 4. Bookkeeping

`CLAUDE.md` is the source of truth for what a promoted-skill change drags along (READMEs, `plugin.json` + validate, docs pages per `.agents/writing-docs.md`, `ask-witify`, `scripts/link-skills.sh`); follow it. On top of that, a sync adds:

- After any rename or delete: grep the repo for the old name (zero hits outside changelogs = done) and remove dangling symlinks the relink left in `~/.claude/skills` and `~/.agents/skills`.
- Docs pages whose prose describes replaced behaviour (not just the changed skill's own page — grep the old behaviour's key phrases across `docs/`).
- One changeset in `.changeset/` summarising the sync.

### 5. Advance the sync point

Update [`STATE.md`](STATE.md): new sync-point SHA and date, plus every ledger change this sync produced — a newly adapted file enters the ledger with its why; a file whose adaptation was dropped leaves it. Done when re-running step 2 against the new sync point would report nothing to do.

### 6. Report

Summarise what landed, what was merged around which adaptations, and the decisions left to the maintainer (promotions, deletions). Commit only when asked; a release afterwards follows the changeset flow documented in the repo's `CLAUDE.md`.
