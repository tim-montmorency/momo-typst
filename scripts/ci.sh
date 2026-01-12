#!/usr/bin/env bash
set -euo pipefail

# CI entrypoint (repo-local):
# - prepares cache content
# - builds representative documents

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

./scripts/prepare_repo.sh
./scripts/build_repo.sh

echo "ci: OK"
