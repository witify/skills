#!/usr/bin/env bash
#
# afk-tick.sh — process EXACTLY ONE "ready-for-agent" ticket, then exit.
#
# This is the worker half of the AFK daemon. afk-loop.sh re-execs it once per
# ticket (a fresh process each time, so editing this file is picked up on the
# next tick — no loop restart). It is fully self-contained: it runs its own
# preflight, queries the frontier, and implements the single best ticket.
#
# Pulls ready Linear tickets for the auto-detected target (GitHub owner/name →
# Linear team/project — see the Config section; override via AFK_* env vars)
# and implements them via `claude -p`. Bash owns every side effect (Linear
# transitions, git
# worktrees, push, PRs, comments); Claude only reads the ticket + its parents
# and runs /implement, committing to the branch.
#
# EXIT CODES (the contract afk-loop.sh maps to a retry policy):
#   0  did work   — implemented one ticket (success OR handled per-ticket failure)
#   3  no work    — frontier empty
#   2  transient  — Linear/network/fetch error; caller should back off + retry
#   1  fatal      — structural misconfig (missing key, gh/mysql/labels); caller exits
#   130 interrupted — killed mid-ticket; the claimed ticket was reset to
#                     ready-for-agent (see on_interrupt) before exiting.
#
# Design decisions (grilled 2026-07-21, split into loop/tick 2026-07-23):
#   - Execution: fresh `claude -p` per ticket.
#   - Claim:    remove `ready-for-agent` -> add `agent-working` -> In Progress.
#   - Frontier: label ready-for-agent, state Backlog/Todo/Change Requested, not
#               blocked (open blockedBy), not a parent (has sub-issues). Order:
#               priority desc, then oldest first.
#   - Two flows (by state):
#       * FRESH (Backlog/Todo): build from scratch, branch off dev, open a PR.
#       * REWORK (Change Requested): an open PR exists — check out its branch,
#         gather the OPEN GitHub review feedback (reviews + unresolved inline
#         threads + conversation, humans & bots; resolved threads skipped),
#         address it, push to the same branch, comment a summary, re-request
#         review. No open PR -> fail loud (agent-failed, stays Change Requested).
#   - Isolation: per-ticket git worktree off `dev` on Linear's branchName,
#                cloned vendor (cp -c), symlinked node_modules, copied .env, and
#                a per-worktree MySQL test DB (test_<id>).
#   - Success:  exit 0 AND new commits -> push + open PR to dev + comment PR
#               URL + move To Review + assign lead + drop agent-working + teardown.
#   - Failure:  push partial branch (no PR), KEEP worktree + its DB, add
#               agent-failed, move to Todo, comment error+log+paths. No auto-retry.
#   - Interrupt: on TERM/INT mid-ticket, reset the claimed ticket back to
#                ready-for-agent (drop agent-working, -> Todo), tear down the
#                worktree + DB + local branch, exit 130. A hard-kill leaves no
#                trace and the ticket re-enters the frontier next tick.
#   - Linear I/O: DIRECT Linear GraphQL API via curl+jq (deterministic, verified,
#                 token-free). Only /implement uses an LLM (Opus).
#
# Requirements: claude, gh (authenticated), jq, git, mysql, curl, and a
# LINEAR_API_KEY (create at linear.app/settings/account/security).
#
set -uo pipefail

# ----------------------------------------------------------------------------
# Config (override via environment)
# ----------------------------------------------------------------------------
# The target is AUTO-DETECTED from the repo you launch from: `gh repo view`
# yields owner/name (e.g. witify/tsa) and the default branch — owner becomes the
# Linear team, name the Linear project (both matched case-insensitively by
# name), and the default branch the PR base. Every value can still be
# overridden via environment for repos whose names don't line up:
#
#   # A Linear project named differently from the repo:
#   AFK_PROJECT="storefront" ./afk-loop.sh
#
#   # PRs against a non-default base branch:
#   AFK_BASE_BRANCH="develop" ./afk-loop.sh
#
#   # Run the FULL suite (parallelized) per ticket instead of filtered tests:
#   AFK_TEST_SCOPE="all" ./afk-loop.sh
#
# Run from the ROOT of the target project's git repo — worktrees, .env DB creds,
# gh, and logs are all resolved relative to that repo, not this one.
# LINEAR_API_KEY must be exported (it authorizes all Linear reads/writes):
#   export LINEAR_API_KEY="lin_api_xxx"
REPO_NWO="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)"
REPO_DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || true)"
TEAM="${AFK_TEAM:-${REPO_NWO%%/*}}"
PROJECT="${AFK_PROJECT:-${REPO_NWO##*/}}"
BASE_BRANCH="${AFK_BASE_BRANCH:-$REPO_DEFAULT_BRANCH}"
TICKET_TIMEOUT="${AFK_TICKET_TIMEOUT:-3600}" # kill a hung implement after 60 min
IMPL_MODEL="${AFK_IMPL_MODEL:-opus}"         # heavy model for /implement
IMPL_EFFORT="${AFK_IMPL_EFFORT:-}"           # effort/reasoning level: low|medium|high|xhigh|max (empty = session default)
TEST_SCOPE="${AFK_TEST_SCOPE:-relevant}"     # 'relevant' (filtered, fast) | 'all' (full suite, --parallel)
# States eligible to start. "Change Requested" enters the REWORK flow (an open PR
# exists; address the review) — everything else is the fresh-build flow.
START_STATES='["Backlog","Todo","Change Requested"]'
CHANGE_REQUESTED_STATE="Change Requested"   # the state name that triggers rework

# --print-config: emit the resolved target as shell assignments and exit.
# afk-loop.sh evals this to display + confirm the target BEFORE starting the
# daemon, then exports the confirmed values so every tick is pinned to them.
if [ "${1:-}" = "--print-config" ]; then
  printf "AFK_REPO='%s'\nAFK_TEAM='%s'\nAFK_PROJECT='%s'\nAFK_BASE_BRANCH='%s'\nAFK_IMPL_MODEL='%s'\nAFK_TEST_SCOPE='%s'\n" \
    "$REPO_NWO" "$TEAM" "$PROJECT" "$BASE_BRANCH" "$IMPL_MODEL" "$TEST_SCOPE"
  exit 0
fi

LINEAR_API="https://api.linear.app/graphql"
LINEAR_API_KEY="${LINEAR_API_KEY:-}"

# GNU `timeout` is not present on macOS by default. Use it if available
# (coreutils installs it as `gtimeout`); otherwise run without a hard timeout.
TIMEOUT_BIN="$(command -v timeout || command -v gtimeout || true)"

MAIN_REPO="$(git rev-parse --show-toplevel)"
WORKTREES_DIR="$(dirname "$MAIN_REPO")/.worktrees"
LOG_DIR="$MAIN_REPO/.afk-logs"
DAEMON_LOG="$LOG_DIR/daemon.log"

# DB creds (for per-worktree test databases) read from .env
DB_HOST="$(grep -E '^DB_HOST=' "$MAIN_REPO/.env" | cut -d= -f2- | tr -d '"')"
DB_PORT="$(grep -E '^DB_PORT=' "$MAIN_REPO/.env" | cut -d= -f2- | tr -d '"')"
DB_USER="$(grep -E '^DB_USERNAME=' "$MAIN_REPO/.env" | cut -d= -f2- | tr -d '"')"
DB_PASS="$(grep -E '^DB_PASSWORD=' "$MAIN_REPO/.env" | cut -d= -f2- | tr -d '"')"

# Linear IDs resolved at preflight (label + workflow-state UUIDs, project lead)
LBL_READY="" LBL_WORKING="" LBL_FAILED=""
ST_INPROGRESS="" ST_TOREVIEW="" ST_TODO="" ST_CHANGEREQ=""
PROJECT_LEAD_ID=""

# GitHub repo (owner/name), resolved at preflight for gh api / graphql calls.
REPO_OWNER="" REPO_NAME=""

# Current-ticket state, tracked so the interrupt trap can reset it cleanly.
# CUR_FLOW is 'fresh' or 'rework'; the trap must NOT delete the branch on rework
# (it's the PR's branch) and resets to the flow's origin state.
CUR_UUID="" CUR_ID="" CUR_BRANCH="" CUR_WORKTREE="" CUR_DB="" CUR_CLAIMED=0 CUR_FLOW="fresh"

mkdir -p "$LOG_DIR" "$WORKTREES_DIR"

# ----------------------------------------------------------------------------
# Logging helpers
# ----------------------------------------------------------------------------
ts()  { date +%Y-%m-%d\ %H:%M:%S; }
log() { printf '[%s] %s\n' "$(ts)" "$*" | tee -a "$DAEMON_LOG" >&2; }

mysql_exec() {
  MYSQL_PWD="$DB_PASS" mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -N -e "$1"
}

# ----------------------------------------------------------------------------
# Linear GraphQL client
#   linear_gql <query> [variables-json]  -> raw JSON response on stdout
#   linear_mutate <query> <vars> <jq-success-path> -> 0 if success==true, else 1
# ----------------------------------------------------------------------------
linear_gql() {
  local query="$1" vars="${2:-}"
  [ -z "$vars" ] && vars='{}'
  curl -sS -X POST "$LINEAR_API" \
    -H "Authorization: $LINEAR_API_KEY" \
    -H "Content-Type: application/json" \
    --data "$(jq -n --arg q "$query" --argjson v "$vars" '{query:$q, variables:$v}')"
}

linear_mutate() {
  local query="$1" vars="$2" success_path="$3" resp
  resp="$(linear_gql "$query" "$vars")"
  if printf '%s' "$resp" | jq -e "$success_path == true" >/dev/null 2>&1; then
    return 0
  fi
  log "    Linear mutation failed: $(printf '%s' "$resp" | jq -c '.errors // .data' 2>/dev/null || printf '%s' "$resp")"
  return 1
}

# --- ID resolvers (by name, team-scoped) -----------------------------------
label_id() {
  linear_gql 'query($team:String!,$name:String!){ issueLabels(filter:{team:{name:{containsIgnoreCase:$team}},name:{eq:$name}}){nodes{id}} }' \
    "$(jq -n --arg team "$TEAM" --arg name "$1" '{team:$team,name:$name}')" \
    | jq -r '.data.issueLabels.nodes[0].id // empty'
}
state_id() {
  linear_gql 'query($team:String!,$name:String!){ workflowStates(filter:{team:{name:{containsIgnoreCase:$team}},name:{eq:$name}}){nodes{id}} }' \
    "$(jq -n --arg team "$TEAM" --arg name "$1" '{team:$team,name:$name}')" \
    | jq -r '.data.workflowStates.nodes[0].id // empty'
}
project_lead_id() {
  linear_gql 'query($project:String!){ projects(filter:{name:{containsIgnoreCase:$project}}){nodes{lead{id}}} }' \
    "$(jq -n --arg project "$PROJECT" '{project:$project}')" \
    | jq -r '.data.projects.nodes[0].lead.id // empty'
}

# --- Mutations (operate on the issue UUID) ---------------------------------
add_label() {
  linear_mutate 'mutation($id:String!,$labelId:String!){issueAddLabel(id:$id,labelId:$labelId){success}}' \
    "$(jq -n --arg id "$1" --arg labelId "$2" '{id:$id,labelId:$labelId}')" '.data.issueAddLabel.success'
}
remove_label() {
  linear_mutate 'mutation($id:String!,$labelId:String!){issueRemoveLabel(id:$id,labelId:$labelId){success}}' \
    "$(jq -n --arg id "$1" --arg labelId "$2" '{id:$id,labelId:$labelId}')" '.data.issueRemoveLabel.success'
}
set_state() {
  linear_mutate 'mutation($id:String!,$stateId:String!){issueUpdate(id:$id,input:{stateId:$stateId}){success}}' \
    "$(jq -n --arg id "$1" --arg stateId "$2" '{id:$id,stateId:$stateId}')" '.data.issueUpdate.success'
}
assign_issue() {
  linear_mutate 'mutation($id:String!,$assigneeId:String!){issueUpdate(id:$id,input:{assigneeId:$assigneeId}){success}}' \
    "$(jq -n --arg id "$1" --arg assigneeId "$2" '{id:$id,assigneeId:$assigneeId}')" '.data.issueUpdate.success'
}
add_comment() {
  linear_mutate 'mutation($id:String!,$body:String!){commentCreate(input:{issueId:$id,body:$body}){success}}' \
    "$(jq -n --arg id "$1" --arg body "$2" '{id:$id,body:$body}')" '.data.commentCreate.success'
}

# ----------------------------------------------------------------------------
# Frontier: JSON array of eligible tickets, best-first. Deterministic — the
# filtering (blocked / parent / order) happens here, not in an LLM.
# Prints the array on stdout on success (possibly []); returns 1 on a transient
# API/parse error so the caller can distinguish "no work" from "try again".
# ----------------------------------------------------------------------------
FRONTIER_QUERY='query($team:String!,$project:String!,$label:String!,$states:[String!]){
  issues(first:100, filter:{
    team:{name:{containsIgnoreCase:$team}},
    project:{name:{containsIgnoreCase:$project}},
    labels:{name:{eq:$label}},
    state:{name:{in:$states}}
  }){
    nodes{
      id identifier title url branchName priority createdAt
      state{ name type }
      children{ nodes{ id } }
      inverseRelations{ nodes{ type issue{ state{ type } } } }
    }
  }
}'

get_frontier() {
  local resp
  resp="$(linear_gql "$FRONTIER_QUERY" \
    "$(jq -n --arg t "$TEAM" --arg p "$PROJECT" --argjson s "$START_STATES" \
        '{team:$t,project:$p,label:"ready-for-agent",states:$s}')")"

  if printf '%s' "$resp" | jq -e '.errors' >/dev/null 2>&1; then
    log "WARN: Linear frontier query error: $(printf '%s' "$resp" | jq -c '.errors')"
    return 1
  fi

  printf '%s' "$resp" | jq -c '
    [ .data.issues.nodes[]
      | select((.children.nodes | length) == 0)                       # not a parent/spec
      | . as $i
      | ([ $i.inverseRelations.nodes[] | select(.type == "blocks") | .issue.state.type ]
          | map(select(. != "completed" and . != "canceled")) | length) as $open_blockers
      | select($open_blockers == 0)                                    # not blocked
      | {id, identifier, branch: .branchName, title, url, state: .state.name, priority, createdAt}
    ]
    | sort_by((if .priority == 0 then 999 else .priority end), .createdAt)  # priority desc, then oldest
    | map({id, identifier, branch, title, url, state})
  ' 2>/dev/null || { log "WARN: could not parse frontier response."; return 1; }
}

# ----------------------------------------------------------------------------
# Linear transitions (all take the issue UUID)
# ----------------------------------------------------------------------------
claim_ticket() {
  local uuid="$1" id="$2"
  log "  Linear: claiming $id (remove ready-for-agent, add agent-working, -> In Progress)"
  remove_label "$uuid" "$LBL_READY"    || log "    WARN: failed to remove ready-for-agent from $id"
  add_label    "$uuid" "$LBL_WORKING"  || log "    WARN: failed to add agent-working to $id"
  set_state    "$uuid" "$ST_INPROGRESS" || log "    WARN: failed to move $id to In Progress"
}

mark_success() {
  local uuid="$1" id="$2" pr_url="$3" verb="${4:-Implemented}"
  log "  Linear: $id -> To Review, drop agent-working, assign lead, comment PR"
  remove_label "$uuid" "$LBL_WORKING"  || log "    WARN: failed to remove agent-working from $id"
  set_state    "$uuid" "$ST_TOREVIEW"  || log "    WARN: failed to move $id to To Review"
  if [ -n "$PROJECT_LEAD_ID" ]; then
    assign_issue "$uuid" "$PROJECT_LEAD_ID" || log "    WARN: failed to assign $id to project lead"
  fi
  add_comment  "$uuid" "🤖 $verb by the AFK agent loop. PR: $pr_url" \
    || log "    WARN: failed to comment on $id"
}

# mark_failure(uuid, id, branch, worktree, logfile, [state_id], [state_name])
# Defaults to Todo; the rework flow passes Change Requested so a failed rework
# stays in the review lane rather than dropping back to Todo.
mark_failure() {
  local uuid="$1" id="$2" branch="$3" worktree="$4" logfile="$5"
  local target_state="${6:-$ST_TODO}" target_name="${7:-Todo}" tail_txt body
  tail_txt="$(tail -n 25 "$logfile" 2>/dev/null)"
  body="🤖❌ AFK agent failed on this ticket. It will NOT be retried automatically.
Branch (partial, pushed): ${branch}
Worktree (kept for debugging): ${worktree}
Full log: ${logfile}

Last log lines:
\`\`\`
${tail_txt}
\`\`\`"
  log "  Linear: $id -> $target_name, add agent-failed, comment error"
  remove_label "$uuid" "$LBL_WORKING" || log "    WARN: failed to remove agent-working from $id"
  add_label    "$uuid" "$LBL_FAILED"  || log "    WARN: failed to add agent-failed to $id"
  set_state    "$uuid" "$target_state" || log "    WARN: failed to move $id to $target_name"
  add_comment  "$uuid" "$body"        || log "    WARN: failed to comment on $id"
}

# reset_ticket(uuid, id, [state_id], [state_name]) — put a claimed-but-unfinished
# ticket back into the frontier (used on interrupt). Defaults to Todo; rework
# passes Change Requested.
reset_ticket() {
  local uuid="$1" id="$2" target_state="${3:-$ST_TODO}" target_name="${4:-Todo}"
  log "  Linear: resetting $id -> ready-for-agent, drop agent-working, -> $target_name"
  remove_label "$uuid" "$LBL_WORKING" || log "    WARN: failed to remove agent-working from $id"
  add_label    "$uuid" "$LBL_READY"   || log "    WARN: failed to re-add ready-for-agent to $id"
  set_state    "$uuid" "$target_state" || log "    WARN: failed to move $id back to $target_name"
}

# ----------------------------------------------------------------------------
# Worktree + per-ticket test DB lifecycle
# ----------------------------------------------------------------------------
setup_worktree() {
  local branch="$1" worktree="$2" db="$3" flow="${4:-fresh}"
  mkdir -p "$(dirname "$worktree")"

  # Always start from the up-to-date REMOTE base so freshly-merged dependencies
  # are present. Branching off local "$BASE_BRANCH" risks a stale tree if the
  # local branch hasn't been pulled (this is what broke WIT-172).
  git -C "$MAIN_REPO" fetch origin "$BASE_BRANCH" >>"$DAEMON_LOG" 2>&1 || return 1

  if [ "$flow" = "rework" ]; then
    # Rework: check out the PR's own branch at its REMOTE head (origin/<branch>),
    # not dev. -B resets any stale local branch to the PR head, so we always work
    # on the exact commits under review — no rebase/merge (that's a human's call).
    git -C "$MAIN_REPO" fetch origin "$branch" >>"$DAEMON_LOG" 2>&1 || return 1
    git -C "$MAIN_REPO" worktree add -B "$branch" "$worktree" "origin/$branch" >>"$DAEMON_LOG" 2>&1 || return 1
    log "    worktree created: $worktree (rework — branch $branch at origin/$branch PR head)"
  elif git -C "$MAIN_REPO" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$MAIN_REPO" worktree add "$worktree" "$branch" >>"$DAEMON_LOG" 2>&1 || return 1
    log "    worktree created: $worktree (existing branch $branch)"
  else
    git -C "$MAIN_REPO" worktree add "$worktree" -b "$branch" "origin/$BASE_BRANCH" >>"$DAEMON_LOG" 2>&1 || return 1
    log "    worktree created: $worktree (new branch $branch off origin/$BASE_BRANCH)"
  fi

  # vendor must be a REAL copy, not a symlink. Composer's autoloader derives its
  # base dir from vendor/composer's location at runtime, so a symlinked vendor makes
  # project classes (and Laravel's inferBasePath) resolve to the MAIN repo instead of
  # this worktree — new/edited classes get ignored and the agent wastes minutes
  # hand-shimming the autoloader. APFS clonefile (cp -c) makes the copy instant and
  # copy-on-write; fall back to a plain recursive copy on non-APFS filesystems.
  if ! cp -c -R "$MAIN_REPO/vendor" "$worktree/vendor" 2>/dev/null; then
    cp -R "$MAIN_REPO/vendor" "$worktree/vendor"
  fi
  # node_modules can stay a symlink — JS module resolution walks up from each file
  # and doesn't have Composer's base-dir problem.
  ln -sfn "$MAIN_REPO/node_modules" "$worktree/node_modules"
  cp "$MAIN_REPO/.env" "$worktree/.env"

  log "    vendor cloned + node_modules linked + .env copied into worktree"

  # Fresh isolated test database, then migrate its schema.
  mysql_exec "DROP DATABASE IF EXISTS \`$db\`; CREATE DATABASE \`$db\`;" >>"$DAEMON_LOG" 2>&1 || return 1
  log "    test DB created: $db"
  ( cd "$worktree" && DB_DATABASE="$db" php artisan migrate:fresh --env=testing --force ) \
    >>"$DAEMON_LOG" 2>&1 || return 1
  log "    test DB migrated: $db (migrate:fresh --env=testing)"
}

teardown_db() {
  # Drop the base DB plus any per-worker DBs paratest spawns (<db>_test_N).
  local db="$1" d
  log "    cleanup: dropping test DB '$db' (+ any paratest worker DBs matching '${db}%')"
  mysql_exec "SHOW DATABASES LIKE '${db}%';" 2>/dev/null | while IFS= read -r d; do
    if [ -n "$d" ]; then
      mysql_exec "DROP DATABASE IF EXISTS \`$d\`;" >>"$DAEMON_LOG" 2>&1
      log "      cleanup: dropped DB '$d'"
    fi
  done || true
}

teardown_worktree() {
  local worktree="$1"
  log "    cleanup: removing worktree '$worktree'"
  git -C "$MAIN_REPO" worktree remove --force "$worktree" >>"$DAEMON_LOG" 2>&1 || true
  # Belt-and-suspenders: if git left the directory behind (it can balk at ignored
  # files), remove it explicitly so the cloned vendor never accumulates on disk.
  if [ -d "$worktree" ]; then
    rm -rf "$worktree"
    log "      cleanup: force-removed leftover directory (cloned vendor freed)"
  fi
  git -C "$MAIN_REPO" worktree prune >>"$DAEMON_LOG" 2>&1 || true
  log "      cleanup: pruned stale worktree references"
}

# ----------------------------------------------------------------------------
# Ticket context (fetched by bash, passed to Opus as TEXT). The implement
# session runs with NO Linear MCP (see --strict-mcp-config below), so it cannot
# read — or accidentally mutate — Linear. Everything it needs is in the prompt.
# ----------------------------------------------------------------------------
fetch_context() {
  local uuid="$1"
  linear_gql 'query($id:String!){issue(id:$id){identifier title description parent{identifier title description}}}' \
    "$(jq -n --arg id "$uuid" '{id:$id}')" \
    | jq -r '
        .data.issue as $i
        | "# Ticket \($i.identifier): \($i.title)\n\n\($i.description // "(no description)")"
          + (if $i.parent then "\n\n---\n\n# Parent \($i.parent.identifier): \($i.parent.title)\n\n\($i.parent.description // "(no description)")" else "" end)
      '
}

# ----------------------------------------------------------------------------
# Implementation prompt (Opus, inside the worktree, Linear-free).
# ----------------------------------------------------------------------------
impl_prompt() {
  local id="$1" context="$2" test_rules
  if [ "$TEST_SCOPE" = "all" ]; then
    test_rules='- Run the FULL test suite, parallelized: `php artisan test --compact --parallel` (plus `npm run test` for any frontend changes). Wait for it to finish. Slower but exhaustive.'
  else
    test_rules='- Run ONLY the tests relevant to your change, filtered — e.g. `php artisan test --compact --filter=YourTest` (plus the matching `npm run test` for frontend changes). Do NOT run the full PHP suite and do NOT use --parallel; the full suite runs later in CI on the pull request.'
  fi
  cat <<EOF
/implement Linear ticket $id.

You have NO Linear access in this session, and you must NOT push or open a pull request
— the surrounding automation does all of that. Everything you need is below.

$context

---

Implementation rules (MANDATORY):
- Use /tdd at sensible seams.
- Run every command (tests, typecheck, pint, phpstan) in the FOREGROUND and wait for it to
  finish. NEVER run tests or any long-running command in the background.
$test_rules
- Run phpstan and pint on your changes.
- Then run /code-review and address what it finds (re-running the tests as above).
- You MUST commit your work to the current git branch as your FINAL action. Do NOT end your
  turn with uncommitted changes, and do NOT end it while any process is still running. If you
  find you have nothing to commit, that is a failure — investigate and fix it before yielding.
EOF
}

# ----------------------------------------------------------------------------
# Rework flow (state == "Change Requested"): an open PR exists; address the
# review comments instead of building from scratch. All GitHub I/O is bash's.
# ----------------------------------------------------------------------------

# Open PR number for a branch, or empty if none.
find_pr_number() {
  gh pr list --repo "$REPO_OWNER/$REPO_NAME" --head "$1" --state open \
    --json number --jq '.[0].number // empty' 2>/dev/null
}

# GraphQL: reviews + review threads (with resolution) + conversation comments.
REVIEW_QUERY='query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviews(first:50){ nodes{ author{login} state body } }
      reviewThreads(first:100){ nodes{ isResolved comments(first:50){ nodes{ author{login} path line originalLine body } } } }
      comments(first:100){ nodes{ author{login} body } }
    }
  }
}'

# Format the OPEN review feedback for a PR as a markdown block for the prompt.
# Excludes: resolved threads, Codex boilerplate review bodies, the Linear
# linkback bot, and our own AFK comments. Reply chains are kept so the agent
# sees "Fixed in X" notes and can reconcile against the current code.
fetch_review_feedback() {
  local pr="$1" resp
  resp="$(gh api graphql -f query="$REVIEW_QUERY" \
    -F owner="$REPO_OWNER" -F repo="$REPO_NAME" -F pr="$pr" 2>/dev/null)"
  [ -z "$resp" ] && { echo "(could not fetch review feedback)"; return; }
  printf '%s' "$resp" | jq -r '
    def strip: gsub("<!--(?:[\\s\\S])*?-->"; "") | gsub("^\\s+|\\s+$"; "");
    .data.repository.pullRequest as $pr
    | ([ $pr.reviews.nodes[]
          | select(.body != null and (.body | length) > 0)
          | select(.body | test("Codex Review") | not)          # drop Codex boilerplate summary
          | "### Review summary — \(.author.login) [\(.state)]\n\(.body | strip)" ]) as $reviews
    | ([ $pr.reviewThreads.nodes[]
          | select(.isResolved == false)                        # skip resolved threads
          | (.comments.nodes[0]) as $f
          | "### Unresolved inline thread — \($f.path):\($f.line // $f.originalLine // "?")\n"
            + ([ .comments.nodes[] | "- \(.author.login): \(.body | strip)" ] | join("\n")) ]) as $threads
    | ([ $pr.comments.nodes[]
          | select(.author.login | test("^linear-code$") | not) # drop Linear linkback bot
          | select(.body | startswith("🤖") | not)              # drop our own AFK comments
          | (.body | strip) as $b | select(($b | length) > 0)
          | "### PR comment — \(.author.login)\n\($b)" ]) as $conv
    | (($reviews + $threads + $conv)
        | if length == 0 then "(no open review feedback found)" else join("\n\n") end)
  ' 2>/dev/null || echo "(could not parse review feedback)"
}

# Human reviewers who previously reviewed the PR (excluding bots and the author),
# one per line — used to re-request review after pushing the rework.
pr_reviewers() {
  local pr="$1" author u
  author="$(gh pr view "$pr" --repo "$REPO_OWNER/$REPO_NAME" --json author --jq '.author.login' 2>/dev/null)"
  gh api "repos/$REPO_OWNER/$REPO_NAME/pulls/$pr/reviews" --jq '[.[].user.login] | unique | .[]' 2>/dev/null \
    | while IFS= read -r u; do
        [ -z "$u" ] && continue
        case "$u" in *"[bot]") continue ;; esac
        [ "$u" = "$author" ] && continue
        printf '%s\n' "$u"
      done
}

rerequest_review() {
  local pr="$1" reviewers csv
  reviewers="$(pr_reviewers "$pr")"
  if [ -z "$reviewers" ]; then
    log "    no prior human reviewers to re-request"
    return
  fi
  csv="$(printf '%s' "$reviewers" | paste -sd, -)"
  if gh pr edit "$pr" --repo "$REPO_OWNER/$REPO_NAME" --add-reviewer "$csv" >>"$DAEMON_LOG" 2>&1; then
    log "    re-requested review from: $csv"
  else
    log "    WARN: failed to re-request review from $csv"
  fi
}

comment_pr() {
  local pr="$1" body="$2"
  gh pr comment "$pr" --repo "$REPO_OWNER/$REPO_NAME" --body "$body" >>"$DAEMON_LOG" 2>&1 \
    || log "    WARN: failed to post summary comment on PR #$pr"
}

# Rework prompt: same guardrails as impl_prompt, but the task is to address the
# review feedback on the existing branch. Q3-C: reconcile each item against the
# actual code — skip anything already satisfied (or resolved), do the rest.
rework_prompt() {
  local id="$1" context="$2" feedback="$3" test_rules
  if [ "$TEST_SCOPE" = "all" ]; then
    test_rules='- Run the FULL test suite, parallelized: `php artisan test --compact --parallel` (plus `npm run test` for any frontend changes). Wait for it to finish.'
  else
    test_rules='- Run ONLY the tests relevant to your change, filtered — e.g. `php artisan test --compact --filter=YourTest` (plus the matching `npm run test`). Do NOT run the full PHP suite and do NOT use --parallel.'
  fi
  cat <<EOF
/implement — address the code-review feedback on Linear ticket $id.

This branch already has an open pull request that was reviewed and had changes
requested. You are on that branch, with all prior work already present. You have
NO Linear access, and you must NOT push or open/modify a pull request — the
surrounding automation pushes and re-requests review. Everything you need is below.

$context

---

## Open review feedback to address

$feedback

---

Rework rules (MANDATORY):
- First, turn the feedback above into a concrete task list. For EACH item, check the
  CURRENT code before doing anything: if it is already satisfied (e.g. a reply says
  "Fixed in <sha>" and the code confirms it), mark it done and skip it. Only act on
  what is genuinely still open. The code is the source of truth, not the comment.
- Use /tdd at sensible seams. Address every still-open item.
- Run every command (tests, typecheck, pint, phpstan) in the FOREGROUND and wait.
$test_rules
- Run phpstan and pint on your changes.
- Then run /code-review and address what it finds (re-running the tests as above).
- You MUST commit your work to the current branch as your FINAL action. Do NOT end your
  turn with uncommitted changes or a running process. If, after checking the code, EVERY
  item is already addressed and there is genuinely nothing to change, that is a failure
  here — investigate; a "Change Requested" ticket should always have open work.
EOF
}

# ----------------------------------------------------------------------------
# Live activity feed: turn claude's stream-json events into scannable lines.
# Reads NDJSON on stdin, writes timestamped human lines on stdout. Non-JSON
# and unknown event shapes are skipped silently — the raw .jsonl is the truth.
# ----------------------------------------------------------------------------
format_stream() {
  jq --unbuffered -Rr '
    (fromjson? // empty) as $e
    | if $e.type == "assistant" then
        ( $e.message.content[]?
          | if .type == "text" then
              (.text | select(length > 0) | "💬 " + (.[0:200] | gsub("\n"; " ")))
            elif .type == "tool_use" then
              "🔧 " + .name + " "
              + ((.input.file_path // .input.command // .input.path // .input.pattern // .input.description // "")
                 | tostring | .[0:140] | gsub("\n"; " "))
            else empty end )
      elif $e.type == "system" and $e.subtype == "init" then
        "▶ session start (model " + ($e.model // "?") + ")"
      elif $e.type == "result" then
        "──── result: " + ($e.subtype // "ok")
        + " (" + (((($e.duration_ms // 0) / 1000) | floor) | tostring) + "s, "
        + (($e.num_turns // 0) | tostring) + " turns) ────\n"
        + ($e.result // "")
      else empty end
  ' 2>/dev/null \
  | while IFS= read -r line; do
      printf '%s %s\n' "$(date +%H:%M:%S)" "$line"
    done
}

# ----------------------------------------------------------------------------
# Interrupt handler: if we're killed mid-ticket (afk-stop --now, Ctrl-C), reset
# the claimed ticket back to ready-for-agent and tear down all artifacts so the
# ticket re-enters the frontier clean. CUR_CLAIMED is 1 only during the window
# between claiming and claude finishing — after that, the outcome is being
# recorded and must not be auto-reset.
# ----------------------------------------------------------------------------
on_interrupt() {
  trap '' INT TERM   # ignore further signals while we clean up
  if [ "$CUR_CLAIMED" = "1" ] && [ -n "$CUR_UUID" ]; then
    if [ "$CUR_FLOW" = "rework" ]; then
      log "Interrupted mid-rework ${CUR_ID} — resetting to ready-for-agent (Change Requested) and cleaning up."
      reset_ticket "$CUR_UUID" "$CUR_ID" "$ST_CHANGEREQ" "Change Requested"
      [ -n "$CUR_WORKTREE" ] && teardown_worktree "$CUR_WORKTREE"
      [ -n "$CUR_DB" ] && teardown_db "$CUR_DB"
      # Do NOT delete the branch — it's the PR's branch. Unpushed local commits go
      # away with the worktree; origin/<branch> (the PR) is untouched, and the next
      # rework re-checks-out origin/<branch> fresh (setup_worktree -B).
    else
      log "Interrupted mid-ticket ${CUR_ID} — resetting to ready-for-agent (Todo) and cleaning up."
      reset_ticket "$CUR_UUID" "$CUR_ID"
      [ -n "$CUR_WORKTREE" ] && teardown_worktree "$CUR_WORKTREE"
      [ -n "$CUR_DB" ] && teardown_db "$CUR_DB"
      # Drop the partial local branch so its commits can't poison a retry (nothing
      # was pushed — push only happens on a clean success).
      [ -n "$CUR_BRANCH" ] && git -C "$MAIN_REPO" branch -D "$CUR_BRANCH" >>"$DAEMON_LOG" 2>&1 || true
    fi
  else
    log "Interrupted (no ticket claimed) — exiting."
  fi
  exit 130
}

# ----------------------------------------------------------------------------
# Run the implement session in the worktree and return its exit code. Shared by
# the fresh and rework flows.
#   run_implement <worktree> <db> <logfile> <jsonl> <prompt>
# Strip Linear MCP (--strict-mcp-config + the project .mcp.json → only
# laravel-boost/herd, never the user-level linear MCP), blank LINEAR_API_KEY for
# the child, and stream NDJSON (raw → $jsonl, human feed → $logfile). PIPESTATUS[0]
# is claude's (or timeout's) exit, not tee's/format_stream's.
# ----------------------------------------------------------------------------
run_implement() {
  local worktree="$1" db="$2" logfile="$3" jsonl="$4" prompt="$5"
  local -a claude_cmd=(
    claude -p --model "$IMPL_MODEL" --dangerously-skip-permissions
    --output-format stream-json --verbose
    --strict-mcp-config --mcp-config "$MAIN_REPO/.mcp.json"
    --append-system-prompt "Unattended headless run. Never run commands in the background — always foreground and wait for completion. You have no Linear access. You MUST commit before ending; never yield with uncommitted work or a still-running process."
  )
  [ -n "$IMPL_EFFORT" ] && claude_cmd+=(--effort "$IMPL_EFFORT")
  claude_cmd+=("$prompt")

  if [ -n "$TIMEOUT_BIN" ]; then
    log "    running /implement ($IMPL_MODEL, timeout ${TICKET_TIMEOUT}s, Linear-free) — tail -f $logfile"
    (
      cd "$worktree" || exit 1
      DB_DATABASE="$db" LINEAR_API_KEY= "$TIMEOUT_BIN" "$TICKET_TIMEOUT" "${claude_cmd[@]}" 2>>"$logfile" \
        | tee "$jsonl" | format_stream >>"$logfile"
      exit "${PIPESTATUS[0]}"
    )
  else
    log "    running /implement ($IMPL_MODEL, no timeout — install coreutils for gtimeout, Linear-free) — tail -f $logfile"
    (
      cd "$worktree" || exit 1
      DB_DATABASE="$db" LINEAR_API_KEY= "${claude_cmd[@]}" 2>>"$logfile" \
        | tee "$jsonl" | format_stream >>"$logfile"
      exit "${PIPESTATUS[0]}"
    )
  fi
  return $?
}

# Extract the agent's final result text from the NDJSON stream (bounded).
agent_result_summary() {
  jq -rs 'map(select(.type == "result")) | (last // {}) | (.result // "")[0:1500]' "$1" 2>/dev/null
}

# ----------------------------------------------------------------------------
# Dispatch a single ticket to the fresh-build or rework flow by its Linear state.
# ----------------------------------------------------------------------------
process_ticket() {
  local uuid="$1" id="$2" branch="$3" title="$4" url="$5" state="$6"
  local stamp worktree db logfile jsonl

  stamp="$(date +%Y%m%d-%H%M%S)"
  logfile="$LOG_DIR/${id}-${stamp}.log"
  jsonl="$LOG_DIR/${id}-${stamp}.jsonl"
  worktree="$WORKTREES_DIR/${branch//\//-}"
  db="test_$(printf '%s' "$id" | tr 'A-Z-' 'a-z_')"   # WIT-164 -> test_wit_164

  log "==> $id  $title  [state: $state]"
  log "    branch=$branch  worktree=$worktree  db=$db  log=$logfile"
  tick_banner   # model + effort + live MCP health — only when a ticket is processed

  if [ "$state" = "$CHANGE_REQUESTED_STATE" ]; then
    process_rework "$uuid" "$id" "$branch" "$title" "$url" "$worktree" "$db" "$logfile" "$jsonl"
  else
    process_fresh  "$uuid" "$id" "$branch" "$title" "$url" "$worktree" "$db" "$logfile" "$jsonl"
  fi
}

# ---- Fresh build: brand-new work, create the branch off dev + open a PR -------
process_fresh() {
  local uuid="$1" id="$2" branch="$3" title="$4" url="$5" worktree="$6" db="$7" logfile="$8" jsonl="$9"
  local rc new_commits pr_url context prompt

  CUR_UUID="$uuid" CUR_ID="$id" CUR_BRANCH="$branch" CUR_WORKTREE="$worktree" CUR_DB="$db" CUR_FLOW="fresh" CUR_CLAIMED=1
  claim_ticket "$uuid" "$id"

  if ! setup_worktree "$branch" "$worktree" "$db" fresh; then
    log "    ERROR: worktree/DB setup failed for $id — marking failed."
    CUR_CLAIMED=0
    mark_failure "$uuid" "$id" "$branch" "$worktree" "$DAEMON_LOG"
    teardown_db "$db"
    return
  fi

  context="$(fetch_context "$uuid")"
  prompt="$(impl_prompt "$id" "$context")"
  run_implement "$worktree" "$db" "$logfile" "$jsonl" "$prompt"
  rc=$?
  CUR_CLAIMED=0   # claude finished — outcome recording below must not be auto-reset

  new_commits="$(git -C "$worktree" rev-list --count "origin/$BASE_BRANCH"..HEAD 2>/dev/null || echo 0)"
  log "    implement exit=$rc  new_commits=$new_commits"

  if [ "$rc" -eq 0 ] && [ "${new_commits:-0}" -gt 0 ]; then
    git -C "$worktree" push -u origin "$branch" >>"$logfile" 2>&1
    pr_url="$(cd "$worktree" && gh pr create --base "$BASE_BRANCH" --head "$branch" \
              --title "$title" \
              --body "Implements [$id]($url). Generated by the AFK agent loop; ready for human review." \
              2>>"$logfile")"
    [ -z "$pr_url" ] && pr_url="(PR creation failed — see $logfile)"
    mark_success "$uuid" "$id" "$pr_url" "Implemented"
    teardown_worktree "$worktree"
    teardown_db "$db"
    rm -f "$jsonl"
    log "    ✓ $id done — $pr_url"
  else
    [ "$rc" -eq 124 ] && log "    (timed out after ${TICKET_TIMEOUT}s)"
    if [ "${new_commits:-0}" -gt 0 ]; then
      git -C "$worktree" push -u origin "$branch" >>"$logfile" 2>&1 || true
    else
      log "    (no commits — nothing to push)"
    fi
    mark_failure "$uuid" "$id" "$branch" "$worktree" "$logfile"
    log "    ✗ $id failed — worktree + db kept at $worktree / $db"
  fi
}

# ---- Rework: an open PR exists; address the review feedback on its branch -----
process_rework() {
  local uuid="$1" id="$2" branch="$3" title="$4" url="$5" worktree="$6" db="$7" logfile="$8" jsonl="$9"
  local pr rc new_commits base_ref context feedback prompt summary

  # Require an open PR (Q1-A). Resolve BEFORE claiming so a no-PR anomaly never
  # strands the ticket In Progress — we fail loud and leave it in Change Requested.
  pr="$(find_pr_number "$branch")"
  if [ -z "$pr" ]; then
    log "    ERROR: $id is Change Requested but no open PR on '$branch' — failing for manual attention."
    remove_label "$uuid" "$LBL_READY"  || true   # so it isn't re-picked every tick
    add_label    "$uuid" "$LBL_FAILED" || true
    add_comment  "$uuid" "🤖❌ AFK: \`$id\` is *Change Requested* + ready-for-agent but no open PR was found on branch \`$branch\`. Left in *Change Requested* for manual attention — no rework performed." || true
    return
  fi
  log "    rework: open PR #$pr on $branch"

  CUR_UUID="$uuid" CUR_ID="$id" CUR_BRANCH="$branch" CUR_WORKTREE="$worktree" CUR_DB="$db" CUR_FLOW="rework" CUR_CLAIMED=1
  claim_ticket "$uuid" "$id"

  if ! setup_worktree "$branch" "$worktree" "$db" rework; then
    log "    ERROR: rework worktree/DB setup failed for $id — marking failed."
    CUR_CLAIMED=0
    mark_failure "$uuid" "$id" "$branch" "$worktree" "$DAEMON_LOG" "$ST_CHANGEREQ" "Change Requested"
    teardown_db "$db"
    return
  fi

  # Success = commits added on top of the PR head we started from, not vs dev.
  # Capture the exact HEAD now (== PR head) so the count is immune to ref drift.
  base_ref="$(git -C "$worktree" rev-parse HEAD 2>/dev/null || echo "origin/$branch")"

  context="$(fetch_context "$uuid")"
  feedback="$(fetch_review_feedback "$pr")"
  log "    rework: fetched review feedback for PR #$pr"
  prompt="$(rework_prompt "$id" "$context" "$feedback")"

  run_implement "$worktree" "$db" "$logfile" "$jsonl" "$prompt"
  rc=$?
  CUR_CLAIMED=0

  new_commits="$(git -C "$worktree" rev-list --count "$base_ref"..HEAD 2>/dev/null || echo 0)"
  log "    rework exit=$rc  new_commits(vs $base_ref)=$new_commits"

  if [ "$rc" -eq 0 ] && [ "${new_commits:-0}" -gt 0 ]; then
    git -C "$worktree" push origin "$branch" >>"$logfile" 2>&1
    summary="$(agent_result_summary "$jsonl")"
    [ -z "$summary" ] && summary="(addressed the requested changes)"
    comment_pr "$pr" "🤖 **AFK agent — review addressed** (${new_commits} new commit(s)). Re-requesting review.

$summary"
    rerequest_review "$pr"
    mark_success "$uuid" "$id" "$url" "Reworked"
    teardown_worktree "$worktree"
    teardown_db "$db"
    rm -f "$jsonl"
    log "    ✓ $id reworked — PR #$pr updated"
  else
    [ "$rc" -eq 124 ] && log "    (timed out after ${TICKET_TIMEOUT}s)"
    if [ "${new_commits:-0}" -gt 0 ]; then
      git -C "$worktree" push origin "$branch" >>"$logfile" 2>&1 || true
    else
      log "    (no commits — nothing to push)"
    fi
    mark_failure "$uuid" "$id" "$branch" "$worktree" "$logfile" "$ST_CHANGEREQ" "Change Requested"
    log "    ✗ $id rework failed — worktree + db kept at $worktree / $db"
  fi
}

# ----------------------------------------------------------------------------
# Preflight — structural checks. Any failure here is FATAL (exit 1): the loop
# should stop, not spin, because retrying won't fix a misconfig.
# ----------------------------------------------------------------------------
preflight() {
  for bin in claude gh jq git mysql php curl; do
    command -v "$bin" >/dev/null 2>&1 || { log "FATAL: '$bin' not found in PATH."; exit 1; }
  done
  [ -n "$LINEAR_API_KEY" ] || { log "FATAL: LINEAR_API_KEY is not set. Create one at linear.app/settings/account/security and export it."; exit 1; }
  gh auth status >/dev/null 2>&1 || { log "FATAL: gh is not authenticated (run: gh auth login)."; exit 1; }
  if [ -z "$TEAM" ] || [ -z "$PROJECT" ] || [ -z "$BASE_BRANCH" ]; then
    log "FATAL: could not auto-detect the target (repo='$REPO_NWO', team='$TEAM', project='$PROJECT', base='$BASE_BRANCH'). Run from a repo with a GitHub remote, or set AFK_TEAM/AFK_PROJECT/AFK_BASE_BRANCH."
    exit 1
  fi
  git -C "$MAIN_REPO" fetch origin "$BASE_BRANCH" >/dev/null 2>&1 \
    && git -C "$MAIN_REPO" show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH" \
    || { log "FATAL: remote base branch 'origin/$BASE_BRANCH' not found (or fetch failed)."; exit 1; }
  mysql_exec "SELECT 1;" >/dev/null 2>&1 || { log "FATAL: cannot connect to MySQL with .env creds."; exit 1; }
  [ -z "$TIMEOUT_BIN" ] && log "WARN: no 'timeout'/'gtimeout' found — implement runs without a hard timeout. Install with: brew install coreutils"

  # GitHub repo (owner/name) for gh api / graphql calls, from the top-of-file
  # auto-detection (which also guarantees it's non-empty by this point).
  REPO_OWNER="${REPO_NWO%%/*}"; REPO_NAME="${REPO_NWO##*/}"

  # Verify Linear auth.
  local viewer
  viewer="$(linear_gql 'query{viewer{name}}' | jq -r '.data.viewer.name // empty')"
  [ -n "$viewer" ] || { log "FATAL: Linear API auth failed (check LINEAR_API_KEY)."; exit 1; }

  # Resolve label + state IDs by name.
  LBL_READY="$(label_id 'ready-for-agent')"; LBL_WORKING="$(label_id 'agent-working')"; LBL_FAILED="$(label_id 'agent-failed')"
  ST_INPROGRESS="$(state_id 'In Progress')"; ST_TOREVIEW="$(state_id 'To Review')"; ST_TODO="$(state_id 'Todo')"
  ST_CHANGEREQ="$(state_id "$CHANGE_REQUESTED_STATE")"
  for pair in "ready-for-agent:$LBL_READY" "agent-working:$LBL_WORKING" "agent-failed:$LBL_FAILED" \
              "In Progress:$ST_INPROGRESS" "To Review:$ST_TOREVIEW" "Todo:$ST_TODO" \
              "$CHANGE_REQUESTED_STATE:$ST_CHANGEREQ"; do
    if [ -z "${pair#*:}" ]; then
      log "FATAL: could not resolve Linear id for '${pair%%:*}' in team '$TEAM'. Create it or fix the name."
      exit 1
    fi
  done

  # Resolve project lead (non-fatal — completed tickets simply stay unassigned if absent).
  PROJECT_LEAD_ID="$(project_lead_id)"
  [ -n "$PROJECT_LEAD_ID" ] || log "WARN: no lead set on project '$PROJECT' — completed tickets will be left unassigned."
}

# ----------------------------------------------------------------------------
# Diagnostic banner: the model + effort the implement session will use, and each
# MCP server it will have (from the scoped .mcp.json) health-checked live — ✅
# reachable, ❌ not. Only shown when a ticket is actually being processed (not on
# empty polls), since the live MCP health-check spins up each server.
# ----------------------------------------------------------------------------
tick_banner() {
  local names name mcp_status rc mcp_timeout mcp_tmp
  log "Tick config — model: $IMPL_MODEL  |  effort: ${IMPL_EFFORT:-session default}  |  test scope: $TEST_SCOPE"

  names="$(jq -r '.mcpServers | keys[]' "$MAIN_REPO/.mcp.json" 2>/dev/null)"
  if [ -z "$names" ]; then
    log "  MCP: (none configured in .mcp.json)"
    return
  fi
  # Health-check ONE server at a time with `claude mcp get`, checking only the
  # servers in .mcp.json — the exact set the implement session uses (it runs
  # with --strict-mcp-config --mcp-config .mcp.json). `claude mcp list` instead
  # health-checks EVERY globally configured server, including remote HTTP
  # connectors (Google, Linear, …) we don't use here; one of those stalling made
  # the whole check time out. Per-server + our-servers-only is both faster (~1s
  # each, all local) and immune to unrelated remote flakiness. Output goes to a
  # temp file so any child a check spawns can't hold a pipe open; each call is
  # still hard-capped so a single wedged server can never freeze the tick.
  mcp_timeout="${AFK_MCP_LIST_TIMEOUT:-15}"
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    mcp_tmp="$(mktemp -t afk-mcp-get)"
    if [ -n "$TIMEOUT_BIN" ]; then
      "$TIMEOUT_BIN" -k 3 "$mcp_timeout" claude mcp get "$name" >"$mcp_tmp" 2>/dev/null
      rc=$?
    else
      claude mcp get "$name" >"$mcp_tmp" 2>/dev/null
      rc=$?
    fi
    mcp_status="$(cat "$mcp_tmp" 2>/dev/null)"
    rm -f "$mcp_tmp"
    # `claude mcp get` reports "Status: ✔ Connected" for a reachable server.
    if [ "$rc" -eq 124 ]; then
      log "  MCP: ⏱  $name (health check timed out after ${mcp_timeout}s — implement still runs)"
    elif printf '%s' "$mcp_status" | grep -qE '✔|✓|Connected'; then
      log "  MCP: ✅ $name (accessible)"
    else
      log "  MCP: ❌ $name (NOT reachable)"
    fi
  done <<EOF
$names
EOF
}

# ----------------------------------------------------------------------------
# One tick: preflight, pick the best ticket, implement it. Exit code is the
# contract with afk-loop.sh (see the header). Everything below `tick` runs once.
# ----------------------------------------------------------------------------
tick() {
  preflight   # exits 1 on any structural failure

  local frontier count row uuid id branch title url state
  frontier="$(get_frontier)" || { log "Frontier query failed (transient) — signaling retry."; exit 2; }
  count="$(printf '%s' "$frontier" | jq 'length' 2>/dev/null || echo 0)"

  if [ "${count:-0}" -eq 0 ]; then
    log "Frontier empty — nothing to do."
    exit 3
  fi

  row="$(printf '%s' "$frontier" | jq -c '.[0]')"
  uuid="$(printf '%s'   "$row" | jq -r '.id')"
  id="$(printf '%s'     "$row" | jq -r '.identifier')"
  branch="$(printf '%s' "$row" | jq -r '.branch')"
  title="$(printf '%s'  "$row" | jq -r '.title')"
  url="$(printf '%s'    "$row" | jq -r '.url')"
  state="$(printf '%s'  "$row" | jq -r '.state')"

  if [ -z "$uuid" ] || [ "$uuid" = "null" ] || [ -z "$branch" ] || [ "$branch" = "null" ]; then
    log "WARN: malformed frontier row, skipping: $row"
    exit 2
  fi

  process_ticket "$uuid" "$id" "$branch" "$title" "$url" "$state"
  exit 0
}

# Reset a half-done ticket cleanly if we're killed while it runs.
trap on_interrupt INT TERM

tick "$@"
