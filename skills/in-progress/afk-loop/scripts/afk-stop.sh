#!/usr/bin/env bash
#
# afk-stop.sh — stop a running afk-loop.sh supervisor.
#
#   ./afk-stop.sh          Graceful: the loop finishes the CURRENT ticket
#                          (opens its PR, moves it To Review), then exits.
#   ./afk-stop.sh --now    Hard: the loop kills the running tick immediately;
#                          that ticket is reset to ready-for-agent (no half-done
#                          trace) and re-enters the frontier next run.
#
set -uo pipefail

MAIN_REPO="$(git rev-parse --show-toplevel)"
LOG_DIR="$MAIN_REPO/.afk-logs"
STOP_FILE="$LOG_DIR/STOP"
PID_FILE="$LOG_DIR/afk-loop.pid"

if [ "${1:-}" = "--now" ]; then
  [ -f "$PID_FILE" ] || { echo "afk-stop: no PID file at $PID_FILE — is the loop running?" >&2; exit 1; }
  pid="$(cat "$PID_FILE")"
  if kill -0 "$pid" 2>/dev/null; then
    kill -USR1 "$pid"
    echo "afk-stop: sent hard stop (SIGUSR1) to afk-loop pid $pid."
    echo "          The current ticket will be reset to ready-for-agent."
  else
    echo "afk-stop: loop pid $pid is not alive; removing stale PID file." >&2
    rm -f "$PID_FILE"
    exit 1
  fi
else
  mkdir -p "$LOG_DIR"
  touch "$STOP_FILE"
  echo "afk-stop: graceful stop requested."
  echo "          The loop will finish the current ticket, then exit."
fi
