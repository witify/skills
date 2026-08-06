---
"witify-skills": minor
---

`to-tickets` and `to-spec` now capture the AFK-agent publishing rules learned from a real run against firstmate:

- **Label move**: when a source spec carries `ready-for-agent`, splitting it into independently grabbable tickets moves the label down onto those tickets — a childless spec with that label is itself grabbable as one giant unit of work.
- **Writing for the AFK agent**: an implement session sees only its ticket's description plus its direct parent's, with no tracker access — cross-cutting decisions go in the parent description, every ticket stays self-contained, and a single-PR parent's title doubles as the PR title.

`to-spec` now states that the `ready-for-agent` label it applies makes the spec the unit an AFK agent implements whole, and points at `/to-tickets` as the pass that moves the label down when Split PR mode is chosen.
