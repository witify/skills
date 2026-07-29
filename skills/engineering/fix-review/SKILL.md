---
name: fix-review
description: Work through the open review comments on a GitHub PR — fix, commit, push, and reply with commit links. Never resolves threads; reviewers close their own.
disable-model-invocation: true
---

Work every open comment on a GitHub PR to a conclusion: a fix pushed to the PR branch, an answer, or a reasoned push-back — each closed out with a reply. **This skill never marks a thread resolved**; the reply with a commit link gives the reviewer everything they need, and closing the thread is their acknowledgment to give, not yours.

GitHub only, via the `gh` CLI. The natural sibling of `/code-review`: one produces review findings, this one consumes a review's comments.

## Process

### 1. Locate the PR

- **No argument** — infer from the current branch: `gh pr view --json number,state,headRefName,url`. If the branch has no PR, stop and say so.
- **Argument (PR number or URL)** — verify the working tree is clean (`git status --porcelain`); if it isn't, stop — never switch branches over uncommitted work. Then announce the switch and `gh pr checkout <number>`.

Either way, abort cleanly if the PR is closed or merged — there is nothing to fix.

### 2. Gather every comment

Four surfaces, humans **and** bots alike:

1. **Inline review threads** — fetch via GraphQL so each thread carries `isResolved` and `isOutdated`:

   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!){
     repository(owner:$owner,name:$repo){pullRequest(number:$pr){
       reviewThreads(first:100){nodes{isResolved isOutdated path
         comments(first:50){nodes{id databaseId author{login} body createdAt}}}}}}}' \
     -f owner=<owner> -f repo=<repo> -F pr=<number>
   ```

2. **Review summary bodies** — `gh api repos/<owner>/<repo>/pulls/<number>/reviews` (the text submitted with an Approve / Request changes / Comment review).
3. **Top-level conversation comments** — `gh api repos/<owner>/<repo>/issues/<number>/comments`.
4. **Bot comments** on any of the above surfaces (CI, CodeRabbit, Dependabot, …) are in scope like any other author.

Paginate if any surface may exceed the first page.

### 3. Triage each comment

Sort every comment into exactly one bucket:

- **Skip** — the thread is already resolved; a reply in the thread shows it was already handled ("done", "fixed in `<sha>`", the reviewer retracted); or the participants explicitly agreed to defer ("follow-up PR", "out of scope, ticket created") — acting would override a decision humans already made. Every skip is listed in the final report with its reason.
- **Ambiguous is actionable.** An open thread on an open PR is unfinished business — a fizzled discussion or an unanswered dispute goes into one of the buckets below, never silently into Skip.
- **Question** — the comment wants an answer, not a diff ("why a queue here?"). Reply with the answer; change no code.
- **Disagree** — the suggested change would demonstrably break behaviour, contradict the repo's documented standards, or undo something intentional. The bar is **concrete evidence of breakage, not taste** — implementing a reviewer's bad idea and stamping it "fixed" is the worst outcome this skill can produce, but so is a skill that argues instead of working. Reply with the reasoning, change nothing, and flag it prominently in the final report.
- **Fix** — everything else. Make the change the comment asks for.

### 4. Fix, one commit per concern

Group comments that touch the same code into one logical concern; independent comments get their own. One commit per concern, so each reply can link the commit that actually contains its fix. Name what the commit addresses, e.g.:

```
review: null-check user lookup (addresses @alice's comments)
```

### 5. Verify, then push

Before pushing, run the repo's standard checks scoped to what changed — affected tests plus the linter/formatter if the repo has one. A check that fails **because of a fix**: iterate until green. A check that was already failing **before this skill touched anything**: note it in the final report and push anyway — pre-existing breakage isn't this skill's to own.

Push to the PR branch with a plain `git push` — never force-push.

### 6. Reply to every non-skipped comment

Push first, reply second — a reply must never link a commit that isn't on the remote yet.

- **Fixed** — explain what changed and link the specific commit that contains the fix (`https://github.com/<owner>/<repo>/pull/<number>/commits/<sha>`).
- **Question** — the answer.
- **Disagree** — the push-back reasoning.

Write each reply **in the language of the comment it answers** — a French comment gets a French reply.

Reply mechanics per surface:

- Inline thread: `gh api repos/<owner>/<repo>/pulls/<number>/comments/<databaseId>/replies -f body='…'`
- Review summary body or top-level comment (no threaded reply exists): post a top-level PR comment (`gh pr comment`) that quotes or @-mentions what it answers.

Do **not** resolve any thread, on any surface, ever.

### 7. Final report

Close with four sections:

- **Fixed** — each comment with its commit.
- **Answered** — questions replied to.
- **Pushed back** — disagreements, flagged for the user to arbitrate.
- **Skipped** — each with its reason.

Plus any pre-existing check failures noted in step 5.
