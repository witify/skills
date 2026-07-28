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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/afk-ui.sh"   # colors only — afk-stop has no daemon log of its own

MAIN_REPO="$(git rev-parse --show-toplevel)"
LOG_DIR="$MAIN_REPO/.afk-logs"
STOP_FILE="$LOG_DIR/STOP"
PID_FILE="$LOG_DIR/afk-loop.pid"

if [ "${1:-}" = "--now" ]; then
  [ -f "$PID_FILE" ] || { printf '%s\n' "${C_RED}✗ afk-stop: no PID file at $PID_FILE — is the loop running?${C_RESET}" >&2; exit 1; }
  pid="$(cat "$PID_FILE")"
  if kill -0 "$pid" 2>/dev/null; then
    kill -USR1 "$pid"
    printf '%s\n' "${C_GREEN}✓ afk-stop: sent hard stop (SIGUSR1) to afk-loop pid $pid.${C_RESET}"
    printf '%s\n' "  ${C_DIM}The current ticket will be reset to ready-for-agent.${C_RESET}"
  else
    printf '%s\n' "${C_YELLOW}WARN: afk-stop: loop pid $pid is not alive; removing stale PID file.${C_RESET}" >&2
    rm -f "$PID_FILE"
    exit 1
  fi
else
  mkdir -p "$LOG_DIR"
  touch "$STOP_FILE"
  printf '%s\n' "${C_GREEN}✓ afk-stop: graceful stop requested.${C_RESET}"
  printf '%s\n' "  ${C_DIM}The loop will finish the current ticket, then exit.${C_RESET}"
fi
