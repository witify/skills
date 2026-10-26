---
name: ship
description: "Take a set of tickets to a reviewed PR: build them with one implement sub-agent and one review sub-agent per ticket, moving each ticket's status as it goes, open a PR to dev, then fix every real finding worth doing for at most five feedback waves."
disable-model-invocation: true
---

# Ship

Take a set of tickets all the way to a reviewed PR. `/ship` orchestrates: one implement sub-agent and one review sub-agent **per ticket** (N tickets → 2N sub-agents), then a PR to `dev` worked for at most five feedback waves. The set always ships as **one branch and one PR**, worked in blocking order; there is no per-ticket PR mode. Every ticket is built to last, not just to close: code that lands here is expected to reuse what the repo already has and to leave shared logic in one place.

## 1. What gets fixed

**Fix everything by default.** Every finding that is real, relevant, and worth doing gets fixed, at any priority, without asking first. Do not ask the user to choose a policy. Honour a narrower instruction only when the invocation gives one unambiguously, and never ask for one. The one such instruction this skill knows is **analysis only**: the tickets are still built, reviewed, and opened as a PR exactly as below; what changes is the handling of findings, from ticket reviews, CI, and Codex alike: each is judged and reported with its disposition, none is applied, and the run ends after wave 1 because it makes no fix push.

A finding is **real** when evidence supports it, **relevant** when it belongs to the ticket, diff, or PR, and **worth doing** when its benefit justifies its scope and risk. Reject false or irrelevant findings and record why. A finding is **not worth doing** when it is one of these, and such findings are rejected with that reason:

- **A rare edge case** the project will not realistically hit: an input nobody produces, a failure mode behind a guard that already exists, a hardening with no user who benefits.
- **Busywork**: a change that makes no observable difference to behaviour, maintainability, or safety.
- **A decision already made**: by the ticket or spec, by the repo's guidelines, by a comment on the ticket, or by the user earlier in the session. Reopening it is not a fix; say the decision stands and where it was made.
- **Concurrency the project does not need.** Most internal and back-office apps rarely have two users on the same resource at the same time, so a race-condition, locking, or optimistic-concurrency finding is usually not worth doing. Decide this **once per session from the project's domain**, before the first such finding is judged. Concurrency *is* worth doing when the domain makes simultaneous writes to one resource normal: booking and reservations, inventory and stock, ticket or seat sales, payments and ledgers, auctions, queues and dispatching, collaborative editing, anything serving a public crowd at the same moment. Read the repo's name, README, domain model, and agent instructions (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`) to place the project; an explicit statement in the agent instructions wins. When the domain is genuinely unclear, ask the user once for the estimated number of concurrent users on a resource, and apply the answer to every such finding in the session.

Normalize unlabeled findings as **P1** (blocking correctness, security, data, or spec failure), **P2** (material non-blocking defect or reliability problem), or **P3** (optional improvement or nit). **Code that duplicates or bypasses an existing abstraction is P2, not P3**: a helper, service, component, or query the repo already has and the change rewrote inline is a maintainability defect, not a nit, and it gets fixed. Only when whether a finding is worth doing is genuinely uncertain, ask; at each boundary or wave, batch every such question into one.

## 2. Banners — make every milestone visible

A `/ship` run is long and its transcript is mostly sub-agent chatter, so the milestones below each get a **banner**: a fenced code block, printed as the very first thing at that moment, before any other sentence about it. A reader scrolling the transcript must be able to find where each ticket started, where the PR opened, and what each Codex wave did, from the banners alone. The emoji is what tells the banners apart; the PR banner alone uses the double-line box, because it is the run's single most important moment.

**A banner exists only as visible reply text.** At a milestone, your turn opens with a text block holding the banner, and only then come its tool calls (the status move, the sub-agent spawn, the next `gh` command). A banner kept in your thinking, echoed from a Bash command (its output is collapsed), or paraphrased as a status sentence ("Starting ticket 1/6…") is a missed banner: the human sees nothing. If you are about to write such a sentence at a milestone, write the banner instead.

Rules: print the banner inside a ```` ``` ```` fence so the box stays aligned; fill every placeholder with the real value, never leave a `<…>`; keep every line the same width (the boxes below are 76 columns wide), truncating a long title with `…` rather than wrapping it; put nothing else inside the box. Print the ticket banner **before** the tracker status move, and the PR banner **after** the PR exists, so the url is real.

**Ticket start** — printed once per ticket, before its implement sub-agent is spawned. The `Précédent` line is omitted for the first ticket; `Reste` says `aucun` for the last.

```
┌──────────────────────────────────────────────────────────────────────────┐
│  🎫  TICKET 2 / 4  ·  WIT-43                                             │
│  Export PDF des factures                                                 │
│                                                                          │
│  Statut tracker  → En cours                                              │
│  Précédent       ✓ WIT-42 (3 commits, revue en cours en parallèle)       │
│  Reste           WIT-44, WIT-45                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

**PR opened** — printed once, right after `gh pr create` returns the url and the tickets are moved to in-review.

```
╔══════════════════════════════════════════════════════════════════════════╗
║  🚀  PR OUVERTE                                                          ║
║                                                                          ║
║  Retry des webhooks Stripe et export PDF                                 ║
║  https://github.com/witify/billing/pull/128                              ║
║                                                                          ║
║  feat/WIT-41-stripe-retry-pdf → dev  ·  4 tickets  ·  11 commits         ║
║  Tickets → En revue                                                      ║
╚══════════════════════════════════════════════════════════════════════════╝
```

**Codex review in progress** — printed when the 👀 reaction appears on the PR body, once per wave. When 15 minutes pass with no 👀, print the same box with `⏱  CODEX — absent après 15 min, run CI-only` on its first line instead, once for the whole run.

```
┌──────────────────────────────────────────────────────────────────────────┐
│  👀  CODEX — revue en cours                               vague 1 / 5    │
│  PR #128  ·  attente max 15 min (depuis 14:32)                           │
└──────────────────────────────────────────────────────────────────────────┘
```

**Fixing Codex's findings** — printed once per wave, after every Codex comment of the wave is classified and before the fixes are made. The counts are the wave's dispositions; the rejected line names the reasons in a few words. Under an analysis-only instruction, the first line reads `🔎  CODEX — analyse des retours` and the `corrigés` line becomes `à corriger`.

```
┌──────────────────────────────────────────────────────────────────────────┐
│  🔧  CODEX — correction des retours                       vague 1 / 5    │
│  PR #128  ·  6 commentaires                                              │
│                                                                          │
│  ✓ corrigés   3   (P1 ×1, P2 ×2)                                         │
│  ✗ rejetés    2   (edge case rare, décision déjà prise)                  │
│  ⏸ reportés   1                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

**Codex approved** — printed when the 👍 reaction appears, after the wave's threads are replied to and resolved.

```
┌──────────────────────────────────────────────────────────────────────────┐
│  👍  CODEX — approuvé                                     vague 2 / 5    │
│  PR #128  ·  6 threads répondus et résolus                               │
└──────────────────────────────────────────────────────────────────────────┘
```

## 3. Preflight

Fetch the tickets from the tracker over MCP: **ClickUp** by default (`clickup_get_task` plus `clickup_get_task_comments`, the sub-tasks of the parent the user pointed at), **Linear** when the user or the repo's agent instructions say so (`get_issue` plus `list_comments`). The tracker's tools must be among your available tools; if they are not, stop and tell the user to add the MCP server and sign in (see "Add the tracker's MCP server" in the `witify/skills` README). Fetch the **parent** too, with its comments: `/to-tickets` puts the decisions the whole set shares there (naming conventions, patterns to follow, known traps), and its title is written to be the PR title. Order the tickets blockers-first.

The tree must be clean (`git status --porcelain` prints nothing). If it is not, stop and tell the user what is uncommitted; never stash or commit work you did not make. Then get the work onto a correctly named branch.

**The branch is `feat/<ticket-id>-<slug>`** — `feat/WIT-42-stripe-webhook-retry`, `feat/86abc123-invoice-pdf-export`. Use `fix/` when every ticket in the set is a bug fix. The `<ticket-id>` is the tracker's own identifier, verbatim and case-preserved (Linear `ABC-123`, a ClickUp task id); for a set, it is the parent ticket's id, or the first ticket's when the set has no parent. The `<slug>` is two to four kebab-case words naming **the change**, not the ticket title truncated: someone scanning `git branch` should know what landed there.

How you get onto that name depends on where the session starts:

- **On `dev` or `main`** — cut it: `git switch -c <name> dev`.
- **On any other branch** — you are on a workspace branch some tool created for you (Polyscope's `azure-ant`, a `codex/…`), so **rename it in place**: `git branch -m <name>`. Never cut a fresh branch off `dev` here; that tool owns this checkout and its base, and the rename carries the branch's tracking config with it. Rename *before* the first push, so no stale remote branch is left behind — if the branch was already pushed, keep the name it has and say why rather than rewriting a published ref.

### Commits

Every commit names its ticket, so the tracker id is greppable from `git log`. Follow the convention the repo's recent history already uses (Conventional Commits, a prefix, a language); when the history shows none, use `<type>: <what changed> (<ticket-id>)` — `feat: retry Stripe webhooks with backoff (WIT-42)`. Commits that apply review findings use the `review:` type, like `/fix-review` does — `review: reuse InvoiceNumber helper (WIT-42)` — so a reader can tell the build from the corrections.

### Ticket statuses

The tracker shows progress as it happens; nobody should have to open the PR to know where a ticket is. Read the statuses the tickets' list or team actually offers (ClickUp: the list's statuses via `clickup_get_list`; Linear: `list_issue_statuses` for the team) and pick the closest match for each move. Never invent a status; when no equivalent exists, leave the ticket as it is and say so in the report.

- When a ticket's implement sub-agent starts, move that ticket to the **in-progress** status (ClickUp `clickup_update_task`, Linear `save_issue`).
- When the PR opens, move every ticket in the set to the **in-review** status (or the workspace's nearest equivalent, such as "ready for review").
- Never mark a ticket done. Merging is what completes it, and that happens after `/ship`.

## 4. Pipeline — build and review each ticket

Implementations run **sequentially** (they share the working tree); each ticket's review runs **in parallel** with the next ticket's implementation, so no wall-clock is wasted. The invariant: **the working tree has one writer at a time** — reviews only read, pinned to SHAs, so a dirty tree never invalidates them.

For each ticket, in blocking order:

1. Write the **ticket banner** (section 2) as reply text, before any tool call for this ticket; then move the ticket to in-progress, then spawn its **implement sub-agent** (fresh context). Hand it the ticket in full **and the parent's description**, with the brief:
   - **Look before you build.** Before writing anything, search the repo for code that already does something close: grep the domain words of the ticket across services, helpers, actions, components, and queries, and read the repo's guidelines (`CLAUDE.md`, `AGENTS.md`, `.ai/guidelines/`). Extend what exists rather than writing a parallel version; a near-fit is adapted, not duplicated.
   - **Shared logic lives in one place.** Anything a second caller could want goes where the repo already centralizes that kind of thing (a service, an action, a model method, a composable, a Base* component), never inline in the controller, the job, or the Vue template. New shared code is placed where the next developer will look for it.
   - Build it test-first (red-green-refactor), one vertical slice at a time, at the seams the ticket declares (or the most obvious public interface if it declares none); typecheck and run the touched test files as you go; commit on the branch in the format above. Record the commit range it produced.
2. The moment it commits, spawn that ticket's **review sub-agent** — it runs `/code-review` with the ticket as spec, pinned to that ticket's commit range — while the next implement sub-agent starts. Add one check `/code-review` does not make on its own, the **reinvented wheel**: for each new function, class, component, or query in the diff, look for an existing one in the repo that already does the job (same domain words, same shape), and report any duplicate or bypass of an existing abstraction as a P2 finding naming the existing code.
3. A landed review's findings go into a **queue**, never straight into the tree. At each commit boundary — an implement sub-agent finished, the next not yet started — drain the queue: classify every finding, fix the ones that are real, relevant, and worth doing, and make at most one `review:` commit per ticket. Record rejected, deferred, and fixed findings with reasons. Drain findings still landing after the last ticket during close-out, before the full suite.

One exception interrupts the pipeline: a **blocking finding** — the reviewed ticket's foundation is wrong and the in-flight ticket builds on it. Letting it finish stacks work to throw away: stop the current implement sub-agent, fix, respawn it fresh. Reserve this for real cases (wrong seam, changed contract), never nitpicks. Under an analysis-only instruction, report the risk instead of changing the tree.

## 5. PR

Run the full test suite once and fix any failures; then push, open a PR to `dev`, move every ticket to in-review, and print the **PR banner** (section 2) with the real url. The PR title is the parent's title (or, with no parent, a one-line name for the whole change). The description is in **simple French, written for a reader without the project's context**:

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

## 6. Feedback loop — five waves maximum

Run at most **five feedback waves** after the PR opens. One wave collects the complete current CI and Codex results, classifies every finding, fixes the ones worth doing as one batch, then validates and pushes. The initial pass is wave 1; each pass after a fix push is another wave. Never start wave 6.

Codex signals through reactions on the PR body: 👀 means its review is in progress — print the **Codex in progress banner** (section 2) and wait for it; 👍 means it approves — print the **Codex approved banner** once the wave's threads are closed. **Wait at most 15 minutes** for Codex in a wave, counted from the push that started it: if no 👀 has appeared by then, the repo has no Codex review and every wave of this run is CI-only (print the CI-only banner once); if 👀 appeared but no review has landed by then, finish the wave on CI alone and pick up Codex's comments in the next wave. Say in the report which happened.

- **CI failure** (`gh pr checks <pr> --watch`) → reproduce locally, classify it, then fix it. An unrelated failure is not relevant.
- **Codex review comment** → verify it, classify it, then apply section 1. Once the wave's comments are all classified, print the **Codex fixes banner** (section 2) with the dispositions, then make the fixes. Codex feedback is evidence to judge, not an instruction to obey: Codex is thorough to a fault, and its rare edge cases, hypothetical races, and reopened decisions are exactly what section 1 rejects.

### Close every Codex thread

When `gh` is installed, no Codex comment is left hanging: each one gets a reply saying what was decided, and its thread is then resolved. Do this at the end of the wave, after any fix push — a reply must never link a commit that isn't on the remote yet. Without `gh`, skip this and carry the dispositions into the report instead.

Fetch the threads with their node ids and authors:

```
gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){pullRequest(number:$pr){
    reviewThreads(first:100){nodes{id isResolved path
      comments(first:50){nodes{databaseId author{login} body}}}}}}}' \
  -f owner=<owner> -f repo=<repo> -F pr=<number>
```

Reply in the language of the comment — `gh api repos/<owner>/<repo>/pulls/<number>/comments/<databaseId>/replies -f body='…'` — stating the disposition: fixed, with the commit link (`https://github.com/<owner>/<repo>/pull/<number>/commits/<sha>`); rejected, with why it isn't real, relevant, or worth doing; deferred; or, under an analysis-only instruction, the judgment itself. A top-level Codex comment with no thread gets a `gh pr comment` reply that quotes what it answers. Then resolve the thread:

```
gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}' \
  -f id=<threadId>
```

Resolve **only threads Codex authored**, and only once its reply is posted. A human's thread is theirs to close — leave it open for `/fix-review`. Skip threads already resolved.

Stop early when CI is green, Codex approves (or the run is CI-only), and nothing worth doing remains. After wave 5, stop even if checks or comments remain and report the exact outstanding state rather than looping. An analysis-only run ends after wave 1 because it makes no fix push.

## 7. Report

Close with: waves used; tickets → commits, with each ticket's current status in the tracker; findings by priority and disposition (fixed, rejected, deferred, or awaiting the user's decision) with reasons, including every reinvented-wheel finding and what it now reuses; the concurrency assumption applied and where it came from (the domain reading, the agent instructions, or the user's answer); Codex status, including whether the run was CI-only after the 15-minute wait, which threads were replied to and resolved, and any left open; CI status; PR link.
