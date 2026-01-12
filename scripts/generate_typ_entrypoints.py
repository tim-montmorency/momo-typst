#!/usr/bin/env python3

import argparse
import json
import re
from pathlib import Path


def derive_semestre(entry_id: str) -> str:
    digits = re.findall(r"\d", str(entry_id))
    if len(digits) < 4:
        raise ValueError(f"cannot derive semestre from id: {entry_id!r}")
    fourth = int(digits[3])
    return "automne" if (fourth % 2 == 1) else "hiver"


def normalize_id(entry_id: str) -> str:
    safe_id = str(entry_id).strip().lower()
    safe_id = re.sub(r"[^a-z0-9_-]+", "-", safe_id).strip("-")
    return safe_id


def read_sources(sources_file: Path) -> list[dict]:
    data = json.loads(sources_file.read_text(encoding="utf-8"))
    if isinstance(data, dict) and "entries" in data:
        entries = data["entries"]
    else:
        entries = data
    if not isinstance(entries, list):
        raise ValueError("sources file must be a JSON list (or {entries:[...]})")
    return [e for e in entries if isinstance(e, dict)]


def render_entrypoint(md_path: str) -> str:
    # NOTE: This file is intended for editor preview (Tinymist) and local compilation.
    return (
        '#import "lib.typ": plan_de_cours, charger_plan_de_cours_md\n\n'
        f'#let (params, corps) = charger_plan_de_cours_md("{md_path}")\n'
        '#show: plan_de_cours.with(..params)\n'
        '#corps\n'
    )


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Generate per-course Typst entrypoints (for editor preview) from cache/sources.json"
    )
    ap.add_argument(
        "--sources-file",
        default="cache/sources.json",
        help="JSON sources file (default: cache/sources.json)",
    )
    ap.add_argument(
        "--out-dir",
        default=".",
        help="Directory to write .typ entrypoints into (default: repo root)",
    )

    args = ap.parse_args()

    sources_file = Path(args.sources_file)
    if not sources_file.exists():
        print(f"sources file not found: {sources_file}")
        return 0

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    entries = read_sources(sources_file)

    expected_files: set[Path] = set()

    written = 0
    for e in entries:
        entry_id = e.get("id")
        annee = e.get("annee")
        if not entry_id or annee is None:
            continue

        cid = normalize_id(entry_id)
        semestre = derive_semestre(cid)
        md_path = f"cache/{str(annee).strip()}/{semestre}/{cid}/plan.md"

        typ_name = f"cours-{annee}-{semestre}-{cid}.generated.typ"
        typ_path = out_dir / typ_name
        expected_files.add(typ_path)
        typ_path.write_text(render_entrypoint(md_path), encoding="utf-8")
        written += 1

    # Remove stale generated entrypoints (when an entry is removed from sources.json).
    for p in out_dir.glob("cours-*.generated.typ"):
        if p not in expected_files:
            try:
                p.unlink()
            except OSError:
                # Non-fatal; keeps the generator usable even on restrictive FS.
                pass

    # Helpful for CI logs / dev confirmation
    print(f"generated {written} entrypoint(s) in {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
