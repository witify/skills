#!/usr/bin/env bash
set -euo pipefail

# Re-syncs every vendored skill from its upstream repo.
#
# A vendored skill carries an UPSTREAM file next to its SKILL.md:
#
#   repo: <github org/repo>
#   path: <dir inside that repo holding the skill files>
#   files: <space-separated files to copy, e.g. "SKILL.md LICENSE.txt">
#   commit: <sha the local copy was last synced to>
#   synced: <date of last sync>
#
# Only the listed files are overwritten — repo-local additions
# (agents/openai.yaml, UPSTREAM itself) are never touched. After copying,
# the commit/synced lines are rewritten to the upstream HEAD, so `git diff`
# shows exactly what changed and the commit history records each sync.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
changed=0

while IFS= read -r -d '' upstream_file; do
  skill_dir="$(dirname "$upstream_file")"
  name="$(basename "$skill_dir")"

  src_repo="$(sed -n 's/^repo: //p' "$upstream_file")"
  src_path="$(sed -n 's/^path: //p' "$upstream_file")"
  files="$(sed -n 's/^files: //p' "$upstream_file")"
  pinned="$(sed -n 's/^commit: //p' "$upstream_file")"

  head_sha="$(git ls-remote "https://github.com/$src_repo" HEAD | cut -f1)"
  if [ "$head_sha" = "$pinned" ]; then
    echo "$name: up to date ($pinned)"
    continue
  fi

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth 1 --filter=blob:none --sparse \
    "https://github.com/$src_repo" "$tmp/clone"
  git -C "$tmp/clone" sparse-checkout set --no-cone "$src_path"

  for f in $files; do
    cp "$tmp/clone/$src_path/$f" "$skill_dir/$f"
  done
  rm -rf "$tmp"
  trap - EXIT

  # Portable in-place edit (BSD and GNU sed disagree on -i)
  pin_tmp="$(mktemp)"
  sed \
    -e "s/^commit: .*/commit: $head_sha/" \
    -e "s/^synced: .*/synced: $(date +%Y-%m-%d)/" \
    "$upstream_file" > "$pin_tmp"
  mv "$pin_tmp" "$upstream_file"

  echo "$name: synced $pinned -> $head_sha"
  changed=1
done < <(find "$REPO/skills" -name UPSTREAM -not -path '*/node_modules/*' -print0)

if [ "$changed" = 1 ]; then
  echo
  echo "Review with: git diff -- skills/"
fi
