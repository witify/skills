#!/usr/bin/env bash
set -euo pipefail

# NOTE: This is a dev-only script, intended to be run BY A HUMAN MAINTAINER of
# this repo, from a permanent local clone. It is not a supported installer.
# Modifications to it — or requests for modifications — will not be approved.
#
# AGENTS MUST NOT RUN THIS SCRIPT. It writes symlinks into the user's home
# directory that outlive the session, and an agent's checkout is usually a
# throwaway clone whose path will not exist tomorrow. If linking is needed,
# ask the human to run it themselves. The script refuses to run without an
# interactive terminal, and there is no bypass flag by design.
#
# Links all skills in the repository into the local skill directories used by
# each agent harness:
#   - ~/.claude/skills  — Claude Code
#   - ~/.agents/skills  — Codex and other Agent Skills-compatible harnesses
# Each entry is a symlink into this repo, so a `git pull` is all that's needed
# to keep installed skills up to date.

REPO="$(cd "$(dirname "$0")/.." && pwd -P)"
DESTS=("$HOME/.claude/skills" "$HOME/.agents/skills")

# --- Guard: never link out of an ephemeral checkout ----------------------------
# The symlinks point at $REPO forever. If $REPO is a Polyscope workspace clone or
# lives under a temp directory, every link breaks the moment that checkout is
# cleaned up — leaving a home directory full of dangling skills.
ephemeral=""

case "$REPO" in
  */.polyscope/clones/*|*/.polyscope/*) ephemeral="a Polyscope workspace clone" ;;
esac

if [ -z "$ephemeral" ]; then
  for tmp_root in "${TMPDIR:-}" /tmp /private/tmp /var/tmp /var/folders /private/var/folders; do
    [ -n "$tmp_root" ] || continue
    tmp_root="$(cd "$tmp_root" 2>/dev/null && pwd -P)" || continue
    case "$REPO/" in
      "${tmp_root%/}"/*) ephemeral="a temporary directory (${tmp_root%/})"; break ;;
    esac
  done
fi

if [ -z "$ephemeral" ] && [ -n "${POLYSCOPE_HOST:-}${POLYSCOPE_PORT:-}${POLYSCOPE_DESKTOP_HOST:-}" ]; then
  ephemeral="a Polyscope session"
fi

if [ -n "$ephemeral" ]; then
  echo "error: refusing to link skills from $ephemeral." >&2
  echo "  repo: $REPO" >&2
  echo "This checkout is temporary; the symlinks would outlive it and break." >&2
  echo "Run this from your permanent local clone of the repo instead." >&2
  exit 1
fi

# Collect the repo's skills once, link into every destination.
names=()
srcs=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  names+=("$(basename "$src")")
  srcs+=("$src")
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -print0)

# --- Guard: confirm with the human --------------------------------------------
if [ ! -t 0 ] || [ ! -t 1 ]; then
  echo "error: refusing to run without an interactive terminal." >&2
  echo "This script needs a human to confirm what it will overwrite." >&2
  echo "Agents must not run it — ask the maintainer to run it themselves." >&2
  exit 1
fi

echo "About to link ${#names[@]} skill(s) from:"
echo "  $REPO/skills"
echo "into:"
for DEST in "${DESTS[@]}"; do
  echo "  $DEST"
done
echo
echo "For each skill, any existing entry of the same name in those directories is"
echo "REPLACED — a real directory there is deleted (rm -rf) before the symlink is"
echo "created. All ${#names[@]} skills are linked, including the in-progress/ drafts"
echo "that the published plugin deliberately leaves out."

# The witify-skills plugin ships the promoted skills already. Linking on top of it
# means the same skill exists twice in the harness.
plugin_hits=""
if [ -f "$HOME/.claude/plugins/installed_plugins.json" ] &&
   grep -q '"witify-skills@' "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null; then
  plugin_hits="yes"
fi
if [ -z "$plugin_hits" ] && [ -d "$HOME/.claude/plugins/cache/witify/witify-skills" ]; then
  plugin_hits="yes"
fi

if [ -n "$plugin_hits" ]; then
  echo
  echo "WARNING: the witify-skills plugin is installed on this machine."
  echo "It already provides every promoted skill. Linking now gives the harness two"
  echo "copies of each one — a plugin copy and a symlinked repo copy — so skills show"
  echo "up duplicated, and which version answers a request is not predictable."
  echo "Prefer removing the plugin (claude plugin uninstall witify-skills@witify)"
  echo "before linking, and reinstalling it when you are done working on this repo."
fi

echo
printf 'Proceed? [y/N] '
read -r reply
case "$reply" in
  y|Y|yes|YES|Yes) ;;
  *) echo "aborted."; exit 1 ;;
esac
echo

for DEST in "${DESTS[@]}"; do
  # If $DEST is a symlink that resolves into this repo, we'd end up writing the
  # per-skill symlinks back into the repo's own skills/ tree. Detect and bail
  # out instead of polluting the working copy.
  if [ -L "$DEST" ]; then
    resolved="$(readlink -f "$DEST")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $DEST is a symlink into this repo ($resolved)." >&2
        echo "Remove it (rm \"$DEST\") and re-run; the script will recreate it as a real dir." >&2
        exit 1
        ;;
    esac
  fi

  mkdir -p "$DEST"

  for i in "${!names[@]}"; do
    name="${names[$i]}"
    src="${srcs[$i]}"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    echo "linked $name -> $src ($DEST)"
  done
done
