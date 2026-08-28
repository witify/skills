---
name: ship
description: "Batteries-included /implement: build a set of tickets with one implement sub-agent and one review sub-agent per ticket, open a PR to dev, then work it until CI is green and Codex approves."
disable-model-invocation: true
---

# Ship

Take a set of tickets all the way to a green PR. Where `/implement` builds one piece of work in the current session, `/ship` orchestrates: one implement sub-agent and one review sub-agent **per ticket** (N tickets → 2N sub-agents), then a PR to `dev` worked until everything is green.

## 1. Preflight

Fetch the tickets via the workflow in `docs/agents/issue-tracker.md` (run `/setup-witify-skills` if it's missing) and order them blockers-first. Start from a clean tree on a fresh branch off `dev`.

## 2. Pipeline — build and review each ticket

Implementations run **sequentially** (they share the working tree); each ticket's review runs **in parallel** with the next ticket's implementation, so no wall-clock is wasted. The invariant: **the working tree has one writer at a time** — reviews only read, pinned to SHAs, so a dirty tree never invalidates them.

For each ticket, in blocking order:

1. **Implement sub-agent** (fresh context): hand it the ticket in full with the brief — build it with `/tdd`, one vertical slice at a time, at the seams the ticket declares (or the most obvious public interface if it declares none); typecheck and run the touched test files as you go; commit on the branch, referencing the ticket. Record the commit range it produced.
2. The moment it commits, spawn that ticket's **review sub-agent** — it runs `/code-review` with the ticket as spec, pinned to that ticket's commit range — while the next implement sub-agent starts.
3. A landed review's findings go into a **queue**, never straight into the tree. At each commit boundary — an implement sub-agent finished, the next not yet started — drain the queue: fix the findings that matter, one fix commit per ticket, referencing it; note the skipped ones and why, for the report. Findings still landing after the last ticket drain during close-out, before the full suite.

One exception interrupts the pipeline: a **blocking finding** — the reviewed ticket's foundation is wrong and the in-flight ticket builds on it. Letting it finish stacks work to throw away: stop the current implement sub-agent, fix, respawn it fresh. Reserve this for real cases (wrong seam, changed contract), never nitpicks.

## 3. PR

Run the full test suite once; fix, push, and open a PR to `dev`. The description is in **simple French, written for a reader without the project's context**:

```markdown
## Résumé
2 à 4 phrases : le problème, ce que la PR change.

## Changements
- Une puce par ticket, avec lien vers le ticket.

## Tests de haut niveau
- [ ] 3 à 6 smoke tests faisables à la main en quelques minutes
      (parcours utilisateur, pas du technique).

## Notes
Décisions prises en route, dette assumée, hors-scope. Omise si vide.

---
💡 Pour explorer cette PR en profondeur, collez dans Claude Code :
`Explique-moi la PR <url> — le problème réglé, les changements
fichier par fichier, et comment les vérifier.`
```

## 4. Green loop

Work the PR until CI is green **and** Codex approves. Codex signals through reactions on the PR body: 👀 means its review is in progress — wait for it; 👍 means it approves.

- **CI failure** (`gh pr checks <pr> --watch`) → reproduce locally, fix, commit, push.
- **Codex review comment** → judge it before touching code. A real bug or a spec gap → fix. A nitpick the repo's standards don't back → skip, and record why. In doubt → ask the user. Codex is sometimes overkill; fixing is not the default.

After 3 consecutive red cycles on the same failure, stop and report instead of looping.

## 5. Report

Close with: tickets → commits, review findings fixed and skipped (with reasons), Codex comments handled, CI status, PR link.
