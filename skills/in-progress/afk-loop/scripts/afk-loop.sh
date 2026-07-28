#!/usr/bin/env bash
#
# afk-loop.sh — supervisor for the AFK "ready-for-agent" daemon.
#
# A thin loop that re-execs afk-tick.sh once per ticket. Because each tick is a
# FRESH process, editing afk-tick.sh is picked up on the very next ticket — no
# restart needed. This file owns only the lifecycle: the poll cadence, the retry
# policy (from tick's exit code), and how you stop the daemon.
#
# STOPPING:
#   ./afk-stop.sh          graceful — writes a STOP sentinel; the loop finishes
#                          the CURRENT ticket, then exits at the next checkpoint.
#   ./afk-stop.sh --now    hard — signals the loop (SIGUSR1) to kill the running
#                          tick immediately; tick resets that ticket back to
#                          ready-for-agent (leaves no half-done trace) and exits.
#   Ctrl-C (foreground)    behaves like --now (the INT reaches the tick child,
#                          whose trap resets the ticket cleanly).
#
# tick exit codes -> policy:
#   0  did work    -> re-tick immediately (drain fast)
#   3  no work     -> sleep AFK_POLL_INTERVAL, then re-tick
#   2  transient   -> back off AFK_BACKOFF, then re-tick
#   1  fatal       -> log and exit (misconfig; spinning won't help)
#
# Config: the TARGET (Linear team/project, PR base branch) is auto-detected from
# the repo you launch from (GitHub owner/name + default branch via `gh repo
# view`), shown, and CONFIRMED before the loop starts — interactively at a TTY,
# or via AFK_YES=1 for unattended launches (nohup). AFK_* env vars override any
# detected value; the full list lives in afk-tick.sh. The loop itself only reads
# AFK_POLL_INTERVAL + AFK_BACKOFF.
# Run from the ROOT of the target project's git repo, with LINEAR_API_KEY exported.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TICK="$SCRIPT_DIR/afk-tick.sh"
. "$SCRIPT_DIR/afk-ui.sh"   # ts/log/ui_* — colored on a TTY, plain in daemon.log

POLL_INTERVAL="${AFK_POLL_INTERVAL:-300}"   # sleep when the frontier is empty
BACKOFF="${AFK_BACKOFF:-45}"                # sleep after a transient error

MAIN_REPO="$(git rev-parse --show-toplevel)"
LOG_DIR="$MAIN_REPO/.afk-logs"
DAEMON_LOG="$LOG_DIR/daemon.log"
STOP_FILE="$LOG_DIR/STOP"
PID_FILE="$LOG_DIR/afk-loop.pid"
mkdir -p "$LOG_DIR"

[ -x "$TICK" ] || { log "FATAL: afk-tick.sh not found or not executable at $TICK"; exit 1; }

# Resolve the target from THIS repo (the tick auto-detects GitHub owner/name →
# Linear team/project and the default branch → PR base) and CONFIRM it before
# daemonizing. The confirmed values are then exported so every tick runs against
# the same target even if the repo's GitHub metadata changes mid-run.
TARGET_CONFIG="$("$TICK" --print-config)" || { log "FATAL: could not resolve the target config."; exit 1; }
eval "$TARGET_CONFIG"
if [ -z "${AFK_TEAM:-}" ] || [ -z "${AFK_PROJECT:-}" ] || [ -z "${AFK_BASE_BRANCH:-}" ]; then
  log "FATAL: could not auto-detect the target (repo='${AFK_REPO:-}'). Run from a repo with a GitHub remote, or set AFK_TEAM/AFK_PROJECT/AFK_BASE_BRANCH."
  exit 1
fi
export AFK_TEAM AFK_PROJECT AFK_BASE_BRANCH

ui_rule
ui_title "AFK loop — target"
ui_kv "Repo"        "${AFK_REPO:-?}"
ui_kv "Linear team" "$AFK_TEAM"
ui_kv "Project"     "$AFK_PROJECT"
ui_kv "PR base"     "$AFK_BASE_BRANCH"
ui_kv "Model"       "${AFK_IMPL_MODEL:-?}"
ui_kv "Tests"       "${AFK_TEST_SCOPE:-?}"
ui_rule

if [ -n "${AFK_YES:-}" ]; then
  log "afk-loop: target pre-confirmed via AFK_YES=1."
elif [ -t 0 ]; then
  ui_confirm "Start the AFK loop against this target?" \
    || { log "afk-loop: target not confirmed — exiting."; exit 1; }
else
  log "FATAL: no TTY to confirm the target. Run once in a terminal to check it, then relaunch with AFK_YES=1 (inspect first via: $TICK --print-config)."
  exit 1
fi

# Hard stop: SIGUSR1 (from `afk-stop --now`) or a foreground INT/TERM. Kill the
# running tick's whole process group so claude + children die, let tick's own
# trap reset the ticket, then exit.
TICK_PID=""
hard_stop() {
  log "afk-loop: hard stop — terminating current tick and exiting."
  if [ -n "$TICK_PID" ]; then
    kill -TERM -"$TICK_PID" 2>/dev/null || kill -TERM "$TICK_PID" 2>/dev/null
    wait "$TICK_PID" 2>/dev/null
  fi
  rm -f "$PID_FILE"
  exit 130
}
trap hard_stop USR1 INT TERM

# Job control so each backgrounded tick becomes its own process group (its PGID
# equals its PID), letting hard_stop signal the whole tree with `kill -- -PID`.
set -m

echo $$ > "$PID_FILE"
rm -f "$STOP_FILE"   # clear any stale sentinel from a previous run
log "afk-loop supervisor started (pid $$). Stop: ./afk-stop.sh   |   Stop now: ./afk-stop.sh --now"

while true; do
  if [ -f "$STOP_FILE" ]; then
    log "afk-loop: STOP sentinel found — exiting gracefully."
    rm -f "$STOP_FILE" "$PID_FILE"
    exit 0
  fi

  "$TICK" &
  TICK_PID=$!
  wait "$TICK_PID"
  rc=$?
  TICK_PID=""

  case "$rc" in
    0)  ;;                                              # did work — re-tick now
    3)  sleep "$POLL_INTERVAL" || true ;;              # no work — poll
    2)  log "afk-loop: transient error — backing off ${BACKOFF}s."
        sleep "$BACKOFF" || true ;;
    1)  log "afk-loop: fatal error from tick — exiting."
        rm -f "$PID_FILE"; exit 1 ;;
    130|143)
        log "afk-loop: tick was interrupted (rc=$rc) — exiting."
        rm -f "$PID_FILE"; exit "$rc" ;;
    *)  log "afk-loop: unexpected tick exit (rc=$rc) — backing off ${BACKOFF}s."
        sleep "$BACKOFF" || true ;;
  esac
done
