#!/usr/bin/env python3

import argparse
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path


IMAGE_LINK_RE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")


def derive_numero_cours(entry_id: str) -> str:
    """Derive Typst `numero_cours` from an entry id.

    Accepted forms:
      - 582-601
      - 582-601-mo
      - 582-601-MO

    By default, assumes the program suffix is MO when missing.
    """

    s = str(entry_id).strip()
    m = re.match(r"^(?P<a>\d{3})[- _]?(?P<b>\d{3})(?:[- _]?(?P<suffix>[A-Za-z]{2}))?$", s)
    if not m:
        raise ValueError(f"invalid id format: {entry_id!r} (expected 582-601 or 582-601-mo)")

    a = m.group("a")
    b = m.group("b")
    suffix = (m.group("suffix") or "MO").upper()
    return f"{a} {b} {suffix}"


def derive_semestre(entry_id: str) -> str:
    """Derive semestre from the 4th digit of the numeric course id.

    Spec: 4th digit odd => automne, even => hiver.
    Uses the concatenation of the first 6 digits found in the id.
    """

    digits = re.findall(r"\d", str(entry_id))
    if len(digits) < 4:
        raise ValueError(f"cannot derive semestre from id: {entry_id!r}")
    fourth = int(digits[3])
    return "automne" if (fourth % 2 == 1) else "hiver"


def derive_out_dir(entry_id: str, annee: int | str | None) -> str:
    if annee is None or str(annee).strip() == "":
        raise ValueError(f"missing 'annee' for id: {entry_id!r}")
    annee_s = str(annee).strip()
    semestre = derive_semestre(entry_id)
    safe_id = str(entry_id).strip().lower()
    safe_id = re.sub(r"[^a-z0-9_-]+", "-", safe_id).strip("-")
    return f"cache/{annee_s}/{semestre}/{safe_id}"


def _slice_section(lines: list[str], start_idx: int, stop_prefixes: tuple[str, ...]) -> list[str]:
    out: list[str] = []
    i = start_idx
    while i < len(lines):
        line = lines[i]
        if any(line.startswith(p) for p in stop_prefixes):
            break
        out.append(line)
        i += 1
    return out


def _extract_bullets(lines: list[str]) -> list[str]:
    out: list[str] = []
    for line in lines:
        s = line.strip()
        if s.startswith("- "):
            out.append(s[2:].strip())
    return out


def extract_presentation_fields(markdown: str) -> dict:
    lines = markdown.splitlines()

    def find_heading(exact: str) -> int | None:
        try:
            return lines.index(exact)
        except ValueError:
            return None

    pres_idx = find_heading("## Présentation du cours")
    if pres_idx is None:
        return {}

    def sub_section(title: str) -> list[str]:
        idx = find_heading(f"### {title}")
        if idx is None:
            return []
        return _slice_section(lines, idx + 1, stop_prefixes=("### ", "## ", "# "))

    description_lines = sub_section("Description du cours")
    objectif_lines = sub_section("Objectif intégrateur")
    competences_lines = sub_section("Compétence(s) ministérielle(s)")
    objectifs_lines = sub_section("Objectifs d'apprentissage")
    cours_lies_lines = sub_section("Cours liés")

    def norm_paragraph_text(xs: list[str]) -> str | None:
        # keep blank lines, but strip trailing spaces
        text = "\n".join([x.rstrip() for x in xs]).strip()
        return text if text else None

    def extract_cours_lies(xs: list[str]) -> dict:
        # Looks for labeled blocks + bullet lists.
        blocks = {
            "prealables_absolus": [],
            "prealables_relatifs": [],
            "corequis": [],
        }
        current: str | None = None
        for raw in xs:
            s = raw.strip()
            if not s:
                continue
            low = s.lower()
            if "préalables absolus" in low:
                current = "prealables_absolus"
                continue
            if "préalables relatifs" in low:
                current = "prealables_relatifs"
                continue
            if "corequis" in low:
                current = "corequis"
                continue
            if s.startswith("- ") and current:
                blocks[current].append(s[2:].strip())
        # drop empties
        return {k: v for k, v in blocks.items() if v}

    data: dict = {}
    desc = norm_paragraph_text(description_lines)
    if desc:
        data["description_du_cours"] = desc
    obj = norm_paragraph_text(objectif_lines)
    if obj:
        data["objectif_integrateur"] = obj

    comps = _extract_bullets(competences_lines)
    if comps:
        data["competences_ministerielles"] = comps

    objs = _extract_bullets(objectifs_lines)
    if objs:
        data["objectifs_apprentissage"] = objs

    cours_lies = extract_cours_lies(cours_lies_lines)
    if cours_lies:
        data["cours_lies"] = cours_lies

    return data


def is_remote_url(s: str) -> bool:
    return s.startswith("http://") or s.startswith("https://")


def read_url_text(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": "momo-typst-fetch/1.0"})
    with urllib.request.urlopen(req) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(charset, errors="replace")


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "momo-typst-fetch/1.0"})
    with urllib.request.urlopen(req) as resp:
        dest.write_bytes(resp.read())


def write_plan_md(out_dir: Path, readme_markdown: str, frontmatter: dict) -> None:
    # Minimal YAML frontmatter (simple scalars only).
    lines: list[str] = ["---"]
    for key, value in frontmatter.items():
        if value is None:
            continue
        s = str(value)
        # Quote if it contains ':' or starts with '{[' etc.
        if any(ch in s for ch in [":", "\n", "#"]) or s.strip() != s:
            s = json.dumps(s, ensure_ascii=False)
        lines.append(f"{key}: {s}")
    lines.append("---")
    lines.append("")
    lines.append(readme_markdown)
    (out_dir / "plan.md").write_text("\n".join(lines), encoding="utf-8")


def extract_image_targets(markdown: str) -> list[str]:
    out: list[str] = []
    for raw in IMAGE_LINK_RE.findall(markdown):
        # strip optional title: (path "title")
        target = raw.strip()
        if " " in target and not target.startswith("http"):
            target = target.split(" ", 1)[0].strip()
        target = target.strip("<>")
        if target:
            out.append(target)
    # dedupe while preserving order
    seen: set[str] = set()
    deduped: list[str] = []
    for x in out:
        if x not in seen:
            seen.add(x)
            deduped.append(x)
    return deduped


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Download a raw GitHub README.md and its relative images for Typst compilation."
    )

    ap.add_argument(
        "readme_url",
        nargs="?",
        help="Raw README URL (https://raw.githubusercontent.com/.../README.md)",
    )
    ap.add_argument(
        "out_dir",
        nargs="?",
        help="Output directory (e.g. cache/582-601)",
    )
    ap.add_argument(
        "--sources-file",
        default=None,
        help="JSON file listing multiple README URLs to cache (e.g. cache/sources.json)",
    )

    args = ap.parse_args()

    def cache_one(readme_url: str, out_dir: Path, frontmatter: dict | None = None) -> int:
        if not is_remote_url(readme_url):
            print(f"readme_url must be http(s): {readme_url}", file=sys.stderr)
            return 2

        base_url = readme_url.rsplit("/", 1)[0] + "/"

        print(f"Fetching README: {readme_url}")
        md = read_url_text(readme_url)

        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "README.md").write_text(md, encoding="utf-8")

        if frontmatter:
            write_plan_md(out_dir, md, frontmatter)

        extracted = extract_presentation_fields(md)
        if extracted:
            (out_dir / "cours_data.extracted.json").write_text(
                json.dumps(extracted, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )

            # Convenience Typst snippet for data/cours.typ
            snippet_lines: list[str] = []
            if "description_du_cours" in extracted:
                snippet_lines.append(f"description_du_cours: {json.dumps(extracted['description_du_cours'], ensure_ascii=False)},")
            if "objectif_integrateur" in extracted:
                snippet_lines.append(f"objectif_integrateur: {json.dumps(extracted['objectif_integrateur'], ensure_ascii=False)},")
            if "competences_ministerielles" in extracted:
                snippet_lines.append("competences_ministerielles: (")
                for x in extracted["competences_ministerielles"]:
                    snippet_lines.append(f"  {json.dumps(x, ensure_ascii=False)},")
                snippet_lines.append("),")
            if "objectifs_apprentissage" in extracted:
                snippet_lines.append("objectifs_apprentissage: (")
                for x in extracted["objectifs_apprentissage"]:
                    snippet_lines.append(f"  {json.dumps(x, ensure_ascii=False)},")
                snippet_lines.append("),")
            if "cours_lies" in extracted:
                cl = extracted["cours_lies"]
                snippet_lines.append("cours_lies: (")
                for key in ["prealables_absolus", "prealables_relatifs", "corequis"]:
                    if key in cl:
                        snippet_lines.append(f"  {key}: (")
                        for x in cl[key]:
                            snippet_lines.append(f"    {json.dumps(x, ensure_ascii=False)},")
                        snippet_lines.append("  ),")
                snippet_lines.append("),")

            (out_dir / "cours_data.snippet.typ").write_text("\n".join(snippet_lines) + "\n", encoding="utf-8")

        images = extract_image_targets(md)
        rel_images = [x for x in images if not is_remote_url(x) and not x.startswith("/")]

        if rel_images:
            print(f"Found {len(rel_images)} relative image(s)")
        else:
            print("No relative images found")

        for rel in rel_images:
            abs_url = urllib.parse.urljoin(base_url, rel)
            dest = out_dir / rel
            print(f"- {rel} <- {abs_url}")
            try:
                download(abs_url, dest)
            except Exception as e:
                print(f"  WARN: failed to download {abs_url}: {e}", file=sys.stderr)

        print(f"Done. Local README: {out_dir / 'README.md'}")
        return 0

    if args.sources_file:
        sources_path = Path(args.sources_file)
        if not sources_path.exists():
            print(f"sources file not found: {sources_path}", file=sys.stderr)
            return 2

        raw = sources_path.read_text(encoding="utf-8")
        data = json.loads(raw)
        entries = data["entries"] if isinstance(data, dict) and "entries" in data else data
        if not isinstance(entries, list):
            print("sources file must be a JSON list or an object with an 'entries' list", file=sys.stderr)
            return 2

        rc = 0
        for idx, entry in enumerate(entries, start=1):
            if not isinstance(entry, dict):
                print(f"Skipping entry #{idx}: not an object", file=sys.stderr)
                rc = 2
                continue

            readme_url = entry.get("readme_url") or entry.get("url")
            out_dir = entry.get("out_dir")
            entry_id = entry.get("id")
            numero_cours = entry.get("numero_cours")
            annee = entry.get("annee")

            if not readme_url:
                print(
                    f"Skipping entry #{idx}{' (' + str(entry_id) + ')' if entry_id else ''}: missing readme_url",
                    file=sys.stderr,
                )
                rc = 2
                continue

            if not entry_id:
                print(f"Skipping entry #{idx}: missing id", file=sys.stderr)
                rc = 2
                continue

            # Nouveau format: out_dir et numero_cours sont dérivés.
            try:
                if not out_dir:
                    out_dir = derive_out_dir(str(entry_id), annee)
                if not numero_cours:
                    numero_cours = derive_numero_cours(str(entry_id))
            except Exception as e:
                print(
                    f"Skipping entry #{idx}{' (' + str(entry_id) + ')' if entry_id else ''}: {e}",
                    file=sys.stderr,
                )
                rc = 2
                continue

            print("\n== Caching" + (f" {entry_id}" if entry_id else "") + " ==")
            fm: dict | None = None
            if numero_cours:
                fm = {"numero_cours": numero_cours}
            one_rc = cache_one(str(readme_url), Path(str(out_dir)), fm)
            rc = max(rc, one_rc)

        return rc

    if args.readme_url and args.out_dir:
        return cache_one(args.readme_url, Path(args.out_dir))

    ap.print_help(sys.stderr)
    print("\nERROR: provide either readme_url+out_dir, or --sources-file", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
