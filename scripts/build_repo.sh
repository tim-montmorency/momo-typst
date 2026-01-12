#!/usr/bin/env bash
set -euo pipefail

# Builds representative PDFs to validate the template compiles.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

font_path="${TYPST_REPO_FONT_PATH:-fonts}"

compile() {
  local entry="$1"
  shift
  echo "build_repo: typst compile $entry"
  typst compile --font-path "$font_path" "$entry" "$@"
}

# Local markdown example (in-repo)
compile "cours-582-999-mo.typ"

# Cached GitHub README example
# (Uses default: cache/582-601/plan.md, but we also pass --input to make it explicit.)
compile "cours-582-601-mo-github.typ" "--input" "md=cache/582-601/plan.md"
