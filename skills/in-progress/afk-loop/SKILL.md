---
name: afk-loop
description: Run the unattended AFK ticket daemon against a Witify Laravel project — it drains `ready-for-agent` Linear tickets one at a time, implementing each in an isolated git worktree via `claude -p` and opening a PR for human review.
disable-model-invocation: true
argument-hint: "start | stop | stop --now | status, or nothing to be walked through"
---

# AFK loop

An unattended daemon that implements Linear tickets while the user is away. Bash owns every side effect (Linear transitions, worktrees, push, PRs, review re-requests); the LLM only implements, inside an isolated worktree with no Linear access. Your job is to operate it: check prerequisites, start it against the right repo, inspect what it's doing, and stop it cleanly.

**Scope — be honest about it.** This is a Witify **Laravel + Linear + GitHub** loop, not a generic one. It assumes: the `claude` CLI with `/implement`, `gh` (authenticated), MySQL with creds in the target repo's `.env`, `php artisan` migrations/tests, and a Linear team with the labels `ready-for-agent` / `agent-working` / `agent-failed` and the states `Backlog` / `Todo` / `In Progress` / `To Review` / `Change Requested`. If the target project doesn't match that stack, say so and stop — don't improvise adapters.

## The three scripts

All in [scripts/](scripts/), designed to run **from the root of the target project's repo** (not this skills repo — worktrees, `.env` creds, `gh`, and logs all resolve against the repo you launch from):

- [afk-loop.sh](scripts/afk-loop.sh) — the supervisor. Re-execs the tick once per ticket (fresh process, so edits to the tick are picked up next ticket), maps tick exit codes to a retry policy, owns start/stop.
- [afk-tick.sh](scripts/afk-tick.sh) — the worker. Processes exactly one ticket: preflight, pick the best frontier ticket, claim it in Linear, build it in a worktree with a per-ticket MySQL test DB, then push + PR + move To Review on success or label `agent-failed` (keeping the worktree for debugging) on failure. `Change Requested` tickets enter a rework flow that addresses the open PR-review feedback instead of building from scratch.
- [afk-stop.sh](scripts/afk-stop.sh) — graceful stop (finish the current ticket, then exit) or `--now` (kill the running tick; that ticket is reset to `ready-for-agent` with no half-done trace).

## Start

1. Confirm the target repo (ask if ambiguous — it is **not** this skills repo). All commands below run from its root.
2. Preflight what the tick will check, so failures surface before the daemon launches: `claude`, `gh` (authenticated), `jq`, `git`, `mysql`, `php`, `curl` on PATH; `LINEAR_API_KEY` exported; the remote base branch exists. `gtimeout` (coreutils) is recommended — without it, a hung implement never times out.
3. Ask which config overrides apply, then launch. Defaults: team `witify`, project `statim`, base branch `dev` — override via env vars, never by editing the scripts:

```sh
cd /path/to/target-repo
export LINEAR_API_KEY="lin_api_…"
AFK_PROJECT="billing" AFK_BASE_BRANCH="main" \
  nohup /path/to/skills/skills/in-progress/afk-loop/scripts/afk-loop.sh >/dev/null 2>&1 &
```

Foreground (in the user's own terminal) also works; Ctrl-C then behaves like `stop --now`. The full knob list — `AFK_TEAM`, `AFK_PROJECT`, `AFK_BASE_BRANCH`, `AFK_POLL_INTERVAL`, `AFK_BACKOFF`, `AFK_TICKET_TIMEOUT`, `AFK_IMPL_MODEL`, `AFK_IMPL_EFFORT`, `AFK_TEST_SCOPE` — is documented at the top of [afk-tick.sh](scripts/afk-tick.sh).

## Inspect

Everything logs under `<target-repo>/.afk-logs/`:

- `daemon.log` — the supervisor + tick narrative (`tail -f` this for a live view).
- `<TICKET>-<stamp>.log` — per-ticket human-readable activity feed of the implement session.
- `<TICKET>-<stamp>.jsonl` — the raw stream (kept only on failure).
- `afk-loop.pid` — present iff the supervisor is running.

For "status": check the PID file is alive, then summarize the tail of `daemon.log` — which ticket is in flight, or how long the frontier has been empty.

## Stop

From the target repo root:

- Graceful (default): `scripts/afk-stop.sh` — finishes the current ticket (PR opened, moved To Review), then exits.
- Immediate: `scripts/afk-stop.sh --now` — kills the running tick; the interrupt trap resets the claimed ticket to `ready-for-agent` and tears down its worktree, test DB, and (fresh-flow only) partial branch, so nothing half-done leaks.

## After a failure

A failed ticket is labeled `agent-failed`, moved back to Todo (or left in Change Requested for rework failures), and **never retried automatically**. Its worktree and test DB are kept; the Linear comment on the ticket links the branch, worktree, and log. To retry after fixing the cause: remove `agent-failed`, re-add `ready-for-agent`, and clean up the kept worktree/DB by hand.
