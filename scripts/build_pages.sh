#!/usr/bin/env bash
set -euo pipefail

# Builds PDFs and generates a GitHub Pages-friendly site under ./docs
# (static HTML + PDFs). Intended to be repo-local (usable locally or in CI).

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

out_dir="docs"
mkdir -p "$out_dir"

font_path="${TYPST_REPO_FONT_PATH:-fonts}"

# Refresh caches for remote README plans.
./scripts/prepare_repo.sh

# Clean old site output.
rm -rf "$out_dir"/*

mkdir -p "$out_dir/exemples"

echo "build_pages: compiling in-repo examples"

# Compile root-level .typ examples (excluding generated wrappers and lib facade).
shopt -s nullglob
examples=( *.typ )
for entry in "${examples[@]}"; do
  [[ "$entry" == "lib.typ" ]] && continue
  [[ "$entry" == "cours-md.typ" ]] && continue
  [[ "$entry" == *.generated.typ ]] && continue

  out_pdf="$out_dir/exemples/${entry%.typ}.pdf"
  echo "build_pages: typst compile $entry -> $out_pdf"
  typst compile --font-path "$font_path" "$entry" "$out_pdf"
done

# If we have a root-level course Markdown file, also compile cours-md.typ as a generic example.
md_examples=( cours-*.md )
if [[ -f "cours-md.typ" && ${#md_examples[@]} -gt 0 ]]; then
  md_example="${md_examples[0]}"
  echo "build_pages: typst compile cours-md.typ (md=$md_example)"
  typst compile --font-path "$font_path" --input "md=$md_example" "cours-md.typ" "$out_dir/exemples/cours-md.pdf"
else
  echo "build_pages: skipping example cours-md.typ (no cours-md.typ and/or no root-level .md)"
fi

sources_file="cache/sources.json"

if [[ -f "$sources_file" ]]; then
  echo "build_pages: compiling cached courses from $sources_file"

  # Print tab-separated lines: annee\tsemestre\tid\tout_dir
  while IFS=$'\t' read -r annee semestre cid cache_dir; do
    [[ -z "$cid" ]] && continue
    mkdir -p "$out_dir/$annee/$semestre"
    pdf_out="$out_dir/$annee/$semestre/$cid.pdf"
    md_in="$cache_dir/plan.md"
    echo "build_pages: typst compile $cid -> $pdf_out"
    if [[ -f "cours-md.typ" ]]; then
      typst compile --font-path "$font_path" --input "md=$md_in" "cours-md.typ" "$pdf_out"
    else
      entry="cours-$annee-$semestre-$cid.generated.typ"
      if [[ ! -f "$entry" ]]; then
        echo "build_pages: missing $entry (run ./scripts/prepare_repo.sh)" >&2
        exit 2
      fi
      typst compile --font-path "$font_path" "$entry" "$pdf_out"
    fi
  done < <(
    python3 - <<'PY'
import json, re
from pathlib import Path

def derive_semestre(entry_id: str) -> str:
    digits = re.findall(r"\d", str(entry_id))
    if len(digits) < 4:
        raise ValueError(entry_id)
    fourth = int(digits[3])
    return "automne" if (fourth % 2 == 1) else "hiver"

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
    if not cid or annee is None:
        continue
    semestre = derive_semestre(str(cid))
    out_dir = derive_out_dir(str(cid), annee)
    print(f"{annee}\t{semestre}\t{str(cid).strip().lower()}\t{out_dir}")
PY
  )
else
  echo "build_pages: no $sources_file found; skipping cached course compilation"
fi

# Generate docs/index.html
index="$out_dir/index.html"
{
  echo "<!doctype html>"
  echo "<html lang=\"en\">"
  echo "<head>"
  echo "  <meta charset=\"utf-8\"/>"
  echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>"
  echo "  <title>momo-typst PDFs</title>"
  echo "  <style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:900px;margin:40px auto;padding:0 16px}h1{margin:0 0 12px}ul{padding-left:18px}li{margin:6px 0}code{background:#f2f2f2;padding:2px 4px;border-radius:4px}</style>"
  echo "</head>"
  echo "<body>"
  echo "  <h1>PDFs compilés</h1>"
  echo "  <p>Généré par <code>./scripts/build_pages.sh</code>.</p>"

  echo "  <h2>Exemples</h2>"
  if ls -1 "$out_dir/exemples"/*.pdf >/dev/null 2>&1; then
    echo "  <ul>"
    while IFS= read -r p; do
      rel="${p#${out_dir}/}"
      echo "    <li><a href=\"./$rel\">$rel</a></li>"
    done < <(find "$out_dir/exemples" -type f -name '*.pdf' | LC_ALL=C sort)
    echo "  </ul>"
  else
    echo "  <p><em>Aucun exemple compilé.</em></p>"
  fi

  if ls -1 "$out_dir"/*/*/*.pdf >/dev/null 2>&1; then
    echo "  <h2>Cours (cache/sources.json)</h2>"
    echo "  <ul>"
    while IFS= read -r p; do
      rel="${p#${out_dir}/}"
      echo "    <li><a href=\"./$rel\">$rel</a></li>"
    done < <(find "$out_dir" -type f -name '*.pdf' ! -path "$out_dir/exemples/*" | LC_ALL=C sort)
    echo "  </ul>"
  else
    echo "  <p><em>Aucun cours compilé depuis cache/sources.json.</em></p>"
  fi
  echo "</body>"
  echo "</html>"
} > "$index"

echo "build_pages: wrote $index"
