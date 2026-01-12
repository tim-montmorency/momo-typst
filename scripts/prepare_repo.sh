#!/usr/bin/env bash
set -euo pipefail

# Prepares the repo for compilation:
# - downloads/updates cached GitHub README plans listed in cache/sources.json

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

sources_file="${1:-cache/sources.json}"

if [[ ! -f "$sources_file" ]]; then
  echo "prepare_repo: sources file not found: $sources_file" >&2
  echo "prepare_repo: nothing to do" >&2
  exit 0
fi

echo "prepare_repo: updating cache from $sources_file"
python3 scripts/fetch_github_plan.py --sources-file "$sources_file"

echo "prepare_repo: generating typst entrypoints (for preview)"
python3 scripts/generate_typ_entrypoints.py --sources-file "$sources_file" --out-dir .
