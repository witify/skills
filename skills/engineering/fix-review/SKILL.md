---
name: fix-review
description: Work through the open review comments on a GitHub PR — triage, confirm the approach with you, then fix, commit, push, and reply with commit links. Never resolves threads; reviewers close their own.
disable-model-invocation: true
---

Work every open comment on a GitHub PR to a conclusion: a fix pushed to the PR branch, an answer, or a reasoned push-back — each closed out with a reply. Leave every thread open: the reply with a commit link gives the reviewer everything they need, and resolving the thread is their acknowledgment to give.

GitHub only, via the `gh` CLI.

## Process

### 1. Locate the PR

- **No argument** — infer from the current branch: `gh pr view --json number,state,headRefName,url`. If the branch has no PR, stop and say so.
- **Argument (PR number or URL)** — check the working tree is clean (`git status --porcelain`) and stop if it isn't, so uncommitted work never crosses branches. Then announce the switch and `gh pr checkout <number>`.

Either way, stop if the PR is closed or merged — there is nothing to fix.

### 2. Gather every comment

Four surfaces, humans and bots (CI, CodeRabbit, Dependabot, …) alike:

1. **Inline review threads** — via GraphQL, the only API that exposes `isResolved` and `isOutdated`:

   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){
     repository(owner:$owner,name:$repo){pullRequest(number:$pr){
       reviewThreads(first:100){nodes{isResolved isOutdated path line
         comments(first:50){nodes{id databaseId author{login} body createdAt}}}}}}}' \
     -f owner=<owner> -f repo=<repo> -F pr=<number>
   ```

2. **Review summary bodies** — `gh api repos/<owner>/<repo>/pulls/<number>/reviews` (the text submitted with an Approve / Request changes / Comment review).
3. **Top-level conversation comments** — `gh api repos/<owner>/<repo>/issues/<number>/comments`.

The gathered set is complete when every surface is paginated to its last page.

### 3. Triage each comment

An open thread on an open PR is unfinished business: a fizzled discussion or an unanswered dispute is still actionable. Read the code each comment points at — for an `isOutdated` thread, the current code, since later commits may already have addressed it — then sort every comment into exactly one bucket:

- **Skip** — the thread is resolved; a reply shows it was already handled ("done", "fixed in `<sha>`", the reviewer retracted); the current code already does what an outdated comment asked; or the participants explicitly agreed to defer ("follow-up PR", "out of scope, ticket created") — acting there would override a decision people already made.
- **Question** — the comment wants an answer, not a diff ("why a queue here?").
- **Disagree** — the suggested change would demonstrably break behaviour, contradict the repo's documented standards, or undo something intentional. The bar is concrete evidence of breakage, not taste: implementing a reviewer's bad idea and stamping it "fixed" is the worst outcome this skill can produce, and a skill that argues instead of working is a close second.
- **Fix** — everything else: the change the comment asks for.

### 4. Confirm the approach

Put the plan to the user before touching code or posting anything. Group comments that touch the same code into one **concern** — the unit step 5 commits — and ask one numbered question per non-skipped concern, all in one round:

```
❓ **Q1** - **<concern title>** (@<author>, `<path>:<line>`): <what the comment asks, quoted or summarised, and what you found in the code>

Options:
- **A** — <the approach, e.g. apply the suggestion as written>
- **B** — <an alternative, e.g. a narrower fix, push back, answer without code>

➡️ <your recommended option, with a one-line why>

---

❓ **Q2** - …
```

The recommended option is the step 3 bucket made concrete: a **Fix** names the change you'll make, a **Question** gives the answer you'll post, a **Disagree** gives the push-back you'll post. Every question offers at least one real alternative the user could plausibly prefer.

After the questions, list the **Skip** bucket, one line each with its reason, so the user can pull any back in.

Then wait for answers. An answer that opens a new decision gets a follow-up round. The step is done when every concern has an approach the user confirmed; their choice overrides your triage, in either direction.

### 5. Fix, one commit per concern

Implement the confirmed approaches, one commit per concern, so each reply can link the commit that contains its fix. Name what the commit addresses:

```
review: null-check user lookup (addresses @alice's comments)
```

### 6. Verify, then push

Run the repo's standard checks scoped to what changed — affected tests, plus the linter/formatter if the repo has one. A check that fails because of a fix: iterate until green. A check that was already failing before this skill touched anything: note it for the final report and push anyway — pre-existing breakage isn't this skill's to own.

Push with a plain `git push`; the PR branch is shared, so history on the remote stays untouched. If the push is rejected because the remote moved, `git pull --rebase`, re-run the checks, and push again.

### 7. Reply to every non-skipped comment

Reply only after the push lands, so every commit link resolves.

- **Fixed** — what changed, plus a link to the commit that contains it (`https://github.com/<owner>/<repo>/pull/<number>/commits/<sha>`).
- **Question** — the answer.
- **Disagree** — the push-back reasoning.

Write each reply in the language of the comment it answers — a French comment gets a French reply.

- Inline thread: `gh api repos/<owner>/<repo>/pulls/<number>/comments/<databaseId>/replies -f body='…'`
- Review summary body or top-level comment (no threaded reply exists): a top-level `gh pr comment` that quotes or @-mentions what it answers.

### 8. Final report

Four sections, each comment linked:

- **Fixed** — with its commit.
- **Answered** — questions replied to.
- **Pushed back** — with the reasoning posted.
- **Skipped** — with the reason.

Plus any pre-existing check failures noted in step 6.
