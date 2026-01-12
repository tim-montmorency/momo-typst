#!/usr/bin/env bash
set -euo pipefail

# Builds representative PDFs to validate the template compiles.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

font_path="${TYPST_REPO_FONT_PATH:-fonts}"

# Ensure cached GitHub plans and preview entrypoints exist (generated from cache/sources.json).
./scripts/prepare_repo.sh

compile() {
  local entry="$1"
  shift
  echo "build_repo: typst compile $entry"
  typst compile --font-path "$font_path" "$entry" "$@"
}

# In-repo examples (optional). Compile the first available root-level .typ
# entrypoint (excluding generated wrappers and the lib facade).
shopt -s nullglob
examples=( *.typ )
compiled_example=false
for entry in "${examples[@]}"; do
  [[ "$entry" == "lib.typ" ]] && continue
  [[ "$entry" == "cours-md.typ" ]] && continue
  [[ "$entry" == *.generated.typ ]] && continue
  compile "$entry"
  compiled_example=true
  break
done

if [[ "$compiled_example" != true ]]; then
  echo "build_repo: skipping in-repo examples (none found)"
fi

# Cached GitHub README example (first entry in cache/sources.json, if any)
if [[ -f "cache/sources.json" ]]; then
  first_md=$(python3 - <<'PY'
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
        print(f"{out_dir}/plan.md")
        break
PY
)

  if [[ -n "$first_md" && -f "$first_md" ]]; then
    if [[ -f "cours-md.typ" ]]; then
      echo "build_repo: typst compile cours-md.typ (md=$first_md)"
      typst compile --font-path "$font_path" --input "md=$first_md" "cours-md.typ"
    else
      # Fallback: compile the first generated entrypoint (preview wrapper).
      shopt -s nullglob
      generated=( cours-*.generated.typ )
      if [[ ${#generated[@]} -gt 0 ]]; then
        echo "build_repo: typst compile ${generated[0]} (fallback, no cours-md.typ)"
        typst compile --font-path "$font_path" "${generated[0]}"
      else
        echo "build_repo: no generated entrypoints found (expected cours-*.generated.typ)" >&2
        exit 2
      fi
    fi
  else
    echo "build_repo: no cached plan.md found yet (run ./scripts/prepare_repo.sh)" >&2
    exit 2
  fi
fi
