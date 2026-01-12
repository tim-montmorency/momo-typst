#!/usr/bin/env bash
set -euo pipefail

# Compiles all root-level .typ entrypoints as a smoke test.
# Keeps logic repo-local (usable in CI or locally).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

font_path="${TYPST_REPO_FONT_PATH:-fonts}"

# Ensure cached GitHub plans exist before compiling any entrypoints that rely on them.
./scripts/prepare_repo.sh

# Root-level entrypoints only.
shopt -s nullglob
entries=( *.typ )

if [[ ${#entries[@]} -eq 0 ]]; then
  echo "test_all: no .typ files found at repo root" >&2
  exit 2
fi

for entry in "${entries[@]}"; do
  # Skip library facade.
  if [[ "$entry" == "lib.typ" ]]; then
    continue
  fi

  args=("--font-path" "$font_path")

  # Special case: wrapper that needs md input.
  if [[ "$entry" == "cours-md.typ" ]]; then
    # Use a stable in-repo markdown example.
    args+=("--input" "md=cours-582-999-mo.md")
  fi

  # Be explicit for the GitHub cached example, even though it has a default.
  if [[ "$entry" == "cours-582-601-mo-github.typ" ]]; then
    args+=("--input" "md=cache/582-601/plan.md")
  fi

  echo "test_all: typst compile $entry"
  typst compile "${args[@]}" "$entry"
done

echo "test_all: OK"
