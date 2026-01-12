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

  echo "test_all: typst compile $entry"
  typst compile "${args[@]}" "$entry"
done

# Optionnel: compile tous les cours listés dans cache/sources.json via le wrapper cours-md.typ.
if [[ -f "cache/sources.json" ]]; then
  echo "test_all: compiling cached courses from cache/sources.json"
  while IFS=$'\t' read -r cid cache_dir; do
    [[ -z "$cid" ]] && continue
    md_in="$cache_dir/plan.md"
    if [[ ! -f "$md_in" ]]; then
      echo "test_all: missing $md_in" >&2
      exit 2
    fi
    echo "test_all: typst compile cours-md.typ (course=$cid)"
    typst compile --font-path "$font_path" --input "md=$md_in" "cours-md.typ" "/tmp/momo-typst-$cid.pdf"
  done < <(
    python3 - <<'PY'
import json, re
from pathlib import Path

def derive_semestre(entry_id: str) -> str:
    digits = re.findall(r"\d", str(entry_id))
    if len(digits) < 4:
        raise ValueError(entry_id)
    return "automne" if (int(digits[3]) % 2 == 1) else "hiver"

def derive_out_dir(entry_id: str, annee):
    annee_s = str(annee).strip()
    semestre = derive_semestre(entry_id)
    safe_id = str(entry_id).strip().lower()
    safe_id = re.sub(r"[^a-z0-9_-]+", "-", safe_id).strip("-")
    return f"cache/{annee_s}/{semestre}/{safe_id}"

data = json.loads(Path("cache/sources.json").read_text(encoding="utf-8"))
entries = data.get("entries") if isinstance(data, dict) and "entries" in data else data
for e in entries:
    if not isinstance(e, dict):
        continue
    cid = e.get("id")
    annee = e.get("annee")
    if cid and annee is not None:
        out_dir = derive_out_dir(str(cid), annee)
        print(f"{str(cid).strip().lower()}\t{out_dir}")
PY
  )
fi

echo "test_all: OK"
