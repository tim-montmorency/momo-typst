#!/usr/bin/env bash
set -euo pipefail

# Removes generated, non-versioned artifacts that live at repo root.
# Safe to run any time.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

rm -f cours-*.generated.typ

echo "clean_generated: removed cours-*.generated.typ"
