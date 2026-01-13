// lib/md/core.typ — parsing/extraction Markdown (sans layout)

#import "@preview/cmarker:0.1.8"

#import "../paths.typ": _est_url, _resoudre_source_asset

#let _retirer_frontmatter_yaml(md) = {
  let lines = md.split("\n")
  if lines.len() == 0 { md }
  else if lines.at(0).trim() != "---" { md }
  else {
    let i = 1
    while i < lines.len() and lines.at(i).trim() != "---" { i += 1 }
    // Si on ne trouve pas la fin, on laisse tel quel.
    if i >= lines.len() { md }
    else {
      // Skip closing --- line
      i += 1
      // Skip a single blank line if present
      if i < lines.len() and lines.at(i).trim() == "" { i += 1 }
      lines.slice(i).join("\n")
    }
  }
}

#let _niveau_heading(line) = {
  let t = line.trim()
  if not t.starts-with("#") { none }
  else {
    let i = 0
    while i < t.len() and t.at(i) == "#" { i += 1 }
    // Doit être suivi d'un espace pour être un heading Markdown.
    if i > 0 and i < t.len() and t.at(i) == " " { i } else { none }
  }
}

#let _extraire_section_md(md, titre) = {
  // Trouve une section niveau 2 '## <titre>' et retourne (avant, section, apres).
  let lines = md.split("\n")
  let idx = range(0, lines.len())
    .filter(i => lines.at(i).trim() == "## " + titre)
    .at(0, default: none)

  if idx == none {
    (md, none, "")
  } else {
    let start = idx
    let end = start + 1
    while end < lines.len() {
      let n = _niveau_heading(lines.at(end))
      // Fin de section au prochain heading de niveau <= 2
      if n != none and n <= 2 { break }
      end += 1
    }
    let before = lines.slice(0, start).join("\n")
    let section = lines.slice(start + 1, end).join("\n")
    let after = lines.slice(end).join("\n")
    (before, section, after)
  }
}

#let _extraire_section_md_niveau(md, niveau, titre) = {
  // Trouve une section de niveau donné '<#*niveau> <titre>' et retourne (avant, section, apres).
  // Important: conserve les sous-sections (ex: pour niveau 3, inclut les #### ...).
  let prefix = range(0, niveau).map(_ => "#").join("") + " "
  let lines = md.split("\n")
  let idx = range(0, lines.len())
    .filter(i => lines.at(i).trim() == prefix + titre)
    .at(0, default: none)

  if idx == none {
    (md, none, "")
  } else {
    let start = idx
    let end = start + 1
    while end < lines.len() {
      let n = _niveau_heading(lines.at(end))
      // Fin de section au prochain heading de niveau <= `niveau`.
      if n != none and n <= niveau { break }
      end += 1
    }
    let before = lines.slice(0, start).join("\n")
    let section = lines.slice(start + 1, end).join("\n")
    let after = lines.slice(end).join("\n")
    (before, section, after)
  }
}

#let _extraire_section_md_par_titres(md, titres) = {
  // titres: tuple/list de titres sans le préfixe "## ".
  for t in titres {
    let (avant, section, apres) = _extraire_section_md(md, t)
    if section != none { return (avant, section, apres, t) }
  }
  (md, none, "", none)
}

#let _extraire_section_md_par_titres_niveau(md, niveau, titres) = {
  // titres: tuple/list de titres sans le préfixe "### ".
  for t in titres {
    let (avant, section, apres) = _extraire_section_md_niveau(md, niveau, t)
    if section != none { return (avant, section, apres, t) }
  }
  (md, none, "", none)
}

#let _autolink_urls_md(md) = {
  // Rend les URLs "nues" cliquables en les convertissant en autolinks Markdown.
  // Stratégie conservatrice: uniquement en début de ligne ou après un espace,
  // et s'arrête avant ")" pour éviter de casser des parenthèses.
  // NOTE: n'affecte pas les liens existants du type "](https://...)".
  let s = str(md)

  // Détache une ponctuation finale courante (.,;:!?) pour ne pas l'inclure
  // dans l'URL cliquable.
  let _split_ponctuation_fin = (url) => {
    let m = url.match(regex("^(.*?)([\\.,;:!?]+)$"))
    if m == none { (url, "") } else { (m.captures.at(0), m.captures.at(1)) }
  }

  // Remplacement UTF-8 safe via regex + callback.
  // - capture(0): début de chaîne ou whitespace
  // - capture(1): URL
  s.replace(
    regex("(^|\\s)(https?://[^\\s\\)\\]}>]+)"),
    m => {
      let prefix = m.captures.at(0)
      let url = m.captures.at(1)
      let (base, tail) = _split_ponctuation_fin(url)
      prefix + "<" + base + ">" + tail
    },
  )
}

#let _rendre_markdown(md, base_url: none) = {
  let md2 = _autolink_urls_md(md)
  let (_, corps) = cmarker.render-with-metadata(
    md2,
    // Pas de métadonnées sur les fragments.
    metadata-block: none,
    scope: (
      image: (source, alt: none, format: auto) => {
        image(_resoudre_source_asset(source, base_url: base_url), alt: alt, format: format)
      },

      // Liens: rendre les URLs externes visiblement cliquables (bleu + souligné).
      link: (dest, body) => {
        let d = str(dest)
        if _est_url(d) {
          link(d)[#underline(stroke: blue)[#text(fill: blue)[#body]]]
        } else {
          link(d)[#body]
        }
      },
    ),
  )
  corps
}
