---
"witify-skills": minor
---

Formalize repo maintenance flows:

- New repo-local **`/upstream-sync`** skill (`.claude/skills/upstream-sync/`) that pulls updates from the upstream mattpocock/skills repo. Its `STATE.md` records the sync point (last-synced upstream commit), the name/bucket mappings, and the adaptation ledger of deliberate local divergences — ledger files are hand-merged, everything else is copied verbatim.
- Repo-local skills are exposed to Codex through a `.agents/skills` symlink to `.claude/skills`.
- `CLAUDE.md` now documents the changeset-per-change convention and the release flow (`CHANGELOG.md` is generated, never hand-edited).
