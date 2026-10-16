#!/usr/bin/env bash
# Sync the brand sources in brand/ (and the generated witify-docx template) into the skill folders
# that need a committed copy at run time.
#
#   scripts/sync-brand.sh          copy brand/ sources over the skill copies
#   scripts/sync-brand.sh --check  exit 1 if any copy differs from its source (CI)
#
# Add a row to PAIRS when a new skill needs a brand asset. Edit brand/ only; never the copies.
# The private witify/skills-admin repo pulls its own copies (fonts, the docx template) from this repo
# with its own sync script; it never carries a brand source of its own.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

# "source|destination", paths relative to the repo root. A trailing slash on both means a directory.
PAIRS=(
  "brand/fonts/|skills/productivity/witify-docx/template/fonts/"
  "brand/diagram-profile/witify.md|skills/productivity/witify-docx/template/diagram-profile/witify.md"
)

check=false
[[ "${1:-}" == "--check" ]] && check=true
status=0

for pair in "${PAIRS[@]}"; do
  src="${pair%%|*}"; dst="${pair##*|}"
  if $check; then
    if [[ "$src" == */ ]]; then
      diff -rq "$src" "$dst" >/dev/null 2>&1 || { echo "drift: $dst differs from $src"; status=1; }
    else
      cmp -s "$src" "$dst" || { echo "drift: $dst differs from $src"; status=1; }
    fi
  else
    if [[ "$src" == */ ]]; then
      mkdir -p "$dst"; rm -rf "${dst:?}"/*; cp -R "$src". "$dst"
    else
      mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"
    fi
    echo "synced: $src -> $dst"
  fi
done

# Every core color in tokens.json must appear in the diagram profile, so the two cannot drift apart.
profile="brand/diagram-profile/witify.md"
for hex in $(node -e 'const t=require("./brand/tokens.json");for(const [k,v] of Object.entries(t.colors)) if(!k.startsWith("cover-")) console.log(v)'); do
  grep -qi "$hex" "$profile" || { echo "drift: $hex from brand/tokens.json is not in $profile"; status=1; }
done

if $check; then
  [[ $status -eq 0 ]] && echo "brand copies are in sync"
fi
exit $status
