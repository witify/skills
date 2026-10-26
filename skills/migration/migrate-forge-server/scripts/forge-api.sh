#!/usr/bin/env bash
# Thin, deterministic wrapper around the Laravel Forge API (v2, organization-scoped).
#
#   forge-api.sh GET    <path> [query]        # path is relative to /api/orgs/<org>/ unless it starts with "/"
#   forge-api.sh POST   <path> '<json>'
#   forge-api.sh PUT    <path> '<json>'
#   forge-api.sh PATCH  <path> '<json>'
#   forge-api.sh DELETE <path>
#   forge-api.sh wait   <path> '<jq filter>' '<expected>' [timeout_s] [interval_s]
#   forge-api.sh org                          # print the organization slug in use
#
# Token: $FORGE_API_TOKEN, else ~/laravel-forge-token, else ~/Desktop/laravel-forge-token.
# Org:   $FORGE_ORG, else the first organization returned by GET /orgs.
# The token is never printed. Output is pretty JSON (jq). Exit code 1 on HTTP >= 400.
set -euo pipefail

API="https://forge.laravel.com/api"

token() {
  if [ -n "${FORGE_API_TOKEN:-}" ]; then printf '%s' "$FORGE_API_TOKEN"; return; fi
  for f in "$HOME/laravel-forge-token" "$HOME/Desktop/laravel-forge-token"; do
    if [ -f "$f" ]; then tr -d '[:space:]' < "$f"; return; fi
  done
  echo "forge-api: no token. Set FORGE_API_TOKEN or create ~/laravel-forge-token" >&2
  exit 2
}

request() { # method url [json]
  local method="$1" url="$2" body="${3:-}"
  local tmp; tmp="$(mktemp)"
  local code
  if [ -n "$body" ]; then
    code="$(curl -sg -o "$tmp" -w '%{http_code}' -X "$method" \
      -H "Authorization: Bearer $(token)" -H "Accept: application/json" -H "Content-Type: application/json" \
      -d "$body" "$url")"
  else
    code="$(curl -sg -o "$tmp" -w '%{http_code}' -X "$method" \
      -H "Authorization: Bearer $(token)" -H "Accept: application/json" "$url")"
  fi
  # Forge sometimes returns raw control characters inside strings (deploy scripts,
  # nginx configs), which jq rejects: strip them before parsing.
  if [ -s "$tmp" ]; then LC_ALL=C tr -d '\000-\010\013\014\016-\037' < "$tmp" | jq . 2>/dev/null || cat "$tmp"; fi
  rm -f "$tmp"
  echo "HTTP $code" >&2
  [ "$code" -lt 400 ]
}

org() {
  if [ -n "${FORGE_ORG:-}" ]; then printf '%s' "$FORGE_ORG"; return; fi
  curl -sg -H "Authorization: Bearer $(token)" -H "Accept: application/json" "$API/orgs" | jq -r '.data[0].attributes.slug'
}

url_for() { # path [query]
  local path="$1" query="${2:-}"
  local base
  case "$path" in
    /*) base="$API$path" ;;
    *)  base="$API/orgs/$(org)/$path" ;;
  esac
  if [ -n "$query" ]; then printf '%s?%s' "$base" "$query"; else printf '%s' "$base"; fi
}

cmd="${1:-}"; shift || true
case "$cmd" in
  org) org; echo ;;
  GET)    request GET "$(url_for "$1" "${2:-}")" ;;
  DELETE) request DELETE "$(url_for "$1")" ;;
  POST|PUT|PATCH) request "$cmd" "$(url_for "$1")" "${2:-{\}}" ;;
  wait)
    path="$1"; filter="$2"; expected="$3"; timeout="${4:-900}"; interval="${5:-15}"
    start=$(date +%s)
    while :; do
      value="$(curl -sg -H "Authorization: Bearer $(token)" -H "Accept: application/json" "$(url_for "$path")" | LC_ALL=C tr -d '\000-\010\013\014\016-\037' | jq -r "$filter" 2>/dev/null || echo '?')"
      echo "$(date +%H:%M:%S) $path -> $value" >&2
      if [ "$value" = "$expected" ]; then exit 0; fi
      case "$value" in failed*|fatal|cancelled|failed-build) echo "forge-api: reached terminal state '$value'" >&2; exit 1 ;; esac
      if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then echo "forge-api: timeout after ${timeout}s" >&2; exit 1; fi
      sleep "$interval"
    done ;;
  *) sed -n '2,15p' "$0"; exit 2 ;;
esac
