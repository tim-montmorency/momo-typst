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

# Optional: pick an in-repo course Markdown file to exercise cours-md.typ.
# (Avoid using README.md or other non-course markdown.)
md_examples=( cours-*.md )
md_example=""
if [[ ${#md_examples[@]} -gt 0 ]]; then
  md_example="${md_examples[0]}"
fi

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
    if [[ -n "$md_example" ]]; then
      args+=("--input" "md=$md_example")
    else
      echo "test_all: skipping cours-md.typ (no root-level .md available)"
      continue
    fi
  fi

  echo "test_all: typst compile $entry"
  typst compile "${args[@]}" "$entry"
done

# Optionnel: compiler tous les cours listés dans cache/sources.json.
# - si cours-md.typ est présent: on compile via --input md=...
# - sinon: on compile les entrypoints *.generated.typ générés par prepare_repo.sh
if [[ -f "cache/sources.json" ]]; then
  echo "test_all: compiling cached courses from cache/sources.json"

  if [[ -f "cours-md.typ" ]]; then
    tmp_list="$(mktemp)"
    python3 - <<'PY' > "$tmp_list"
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
        semestre = derive_semestre(str(cid))
        out_dir = derive_out_dir(str(cid), annee)
    print(f"{annee}\t{semestre}\t{str(cid).strip().lower()}\t{out_dir}")
PY

    while IFS=$'\t' read -r annee semestre cid cache_dir; do
      [[ -z "$cid" ]] && continue
      md_in="$cache_dir/plan.md"
      if [[ ! -f "$md_in" ]]; then
        echo "test_all: missing $md_in" >&2
        rm -f "$tmp_list"
        exit 2
      fi
      label="$annee-$semestre-$cid"
      echo "test_all: typst compile cours-md.typ (course=$label)"
      typst compile --font-path "$font_path" --input "md=$md_in" "cours-md.typ" "/tmp/momo-typst-$label.pdf"
    done < "$tmp_list"

    rm -f "$tmp_list"
  else
    shopt -s nullglob
    generated=( cours-*.generated.typ )
    if [[ ${#generated[@]} -eq 0 ]]; then
      echo "test_all: no cours-md.typ and no cours-*.generated.typ found" >&2
      exit 2
    fi
    for entry in "${generated[@]}"; do
      echo "test_all: typst compile $entry (generated)"
      typst compile --font-path "$font_path" "$entry" "/tmp/momo-typst-${entry%.generated.typ}.pdf"
    done
  fi
fi

echo "test_all: OK"
