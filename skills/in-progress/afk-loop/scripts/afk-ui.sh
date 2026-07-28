#!/usr/bin/env bash
#
# afk-ui.sh — shared terminal output for the AFK loop scripts (sourced, not run).
#
# One log() serves every script: the terminal (stderr) gets a colorized,
# level-styled line; $DAEMON_LOG (when the sourcing script has set it) gets the
# same line as plain text, so the file stays grep-friendly. Styling is derived
# from the message itself (FATAL:/ERROR:/WARN:/✓/✗/==> prefixes, indentation =
# sub-detail rendered dim), so existing call sites need no changes. Colors
# engage only when stderr is a TTY and NO_COLOR (no-color.org) is unset.

if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_CYAN=$'\033[36m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''
  C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''
fi

ts() { date +%Y-%m-%d\ %H:%M:%S; }

# ui_emit <terminal-line> <file-line> — styled to stderr; plain to the daemon
# log if the sourcing script defined DAEMON_LOG (afk-stop.sh doesn't).
ui_emit() {
  printf '%s\n' "$1" >&2
  if [ -n "${DAEMON_LOG:-}" ]; then
    printf '%s\n' "$2" >>"$DAEMON_LOG" 2>/dev/null || true
  fi
}

log() {
  local msg="$*" t trimmed lead styled
  t="$(ts)"
  trimmed="${msg#"${msg%%[![:space:]]*}"}"   # msg without leading whitespace
  lead="${msg%"$trimmed"}"                    # the leading whitespace itself
  case "$trimmed" in
    FATAL:*)         styled="${lead}${C_RED}${C_BOLD}${trimmed}${C_RESET}" ;;
    ERROR:*|✗*)      styled="${lead}${C_RED}${trimmed}${C_RESET}" ;;
    WARN:*)          styled="${lead}${C_YELLOW}${trimmed}${C_RESET}" ;;
    ✓*)              styled="${lead}${C_GREEN}${trimmed}${C_RESET}" ;;
    ==\>*)           styled="${C_BOLD}${C_CYAN}${trimmed}${C_RESET}" ;;
    *) if [ -n "$lead" ]; then styled="${lead}${C_DIM}${trimmed}${C_RESET}"
       else styled="$msg"; fi ;;
  esac
  ui_emit "${C_DIM}${t}${C_RESET}  ${styled}" "[$t] $msg"
}

# Structured blocks for the startup banner: a bold title, aligned key/value
# rows, and a dim horizontal rule.
ui_title() { ui_emit "${C_BOLD}${C_CYAN}$*${C_RESET}" "[$(ts)] == $* =="; }
ui_kv()    { ui_emit "  $(printf "${C_DIM}%-13s${C_RESET}" "$1")${C_BOLD}$2${C_RESET}" "[$(ts)]   $(printf '%-13s' "$1")$2"; }
ui_rule()  { ui_emit "${C_DIM}────────────────────────────────────────────${C_RESET}" ''; }

# ui_confirm <question> — styled y/N prompt on stderr; 0 = yes.
ui_confirm() {
  local ans
  printf '%s %s ' "${C_BOLD}$1${C_RESET}" "${C_DIM}[y/N]${C_RESET}" >&2
  read -r ans
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}
