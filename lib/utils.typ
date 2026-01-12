// lib/utils.typ — helpers réutilisables (contenu, listes, normalisation)

#let _normaliser_choix(s) = {
  // Normalisation tolérante pour matcher les items, sans être trop magique.
  let x = str(s)
    .replace("’", "'")
    .replace("…", "")
    .replace(".", "")
    .replace(",", "")
    .replace(":", "")
    .replace(";", "")
    .replace("(", "")
    .replace(")", "")
    .trim()

  // Espaces normalisés
  let y = x.split(" ").filter(w => w != "").join(" ")
  y
}

#let _case_a_cocher(label, coche: false) = {
  [
    #box(
      width: 1.05em,
      height: 1.05em,
      stroke: 1pt,
      inset: 0pt,
    )[#align(center, if coche { [×] } else { [] })]
    #h(0.35em)
    #label
  ]
}

#let _joindre(items, sep: [, ], dernier_sep: [ et ]) = {
  if items == none { none }
  else if items.len() == 0 { none }
  else if items.len() == 1 { items.at(0) }
  else {
    let out = []
    for i in range(0, items.len()) {
      if i > 0 {
        out = out + (if i == items.len() - 1 { dernier_sep } else { sep })
      }
      out = out + items.at(i)
    }
    out
  }
}

#let _lignes(items) = {
  if items == none { none }
  else if items.len() == 0 { none }
  else { stack(spacing: 0.25em, ..items) }
}

#let _joindre_chaine(items, sep: ", ", dernier_sep: " et ") = {
  if items == none { none }
  else if items.len() == 0 { none }
  else if items.len() == 1 { items.at(0) }
  else {
    let out = ""
    for i in range(0, items.len()) {
      if i > 0 {
        out = out + (if i == items.len() - 1 { dernier_sep } else { sep })
      }
      out = out + items.at(i)
    }
    out
  }
}

#let _uniques(items) = {
  let seen = (:)
  let out = ()
  for item in items {
    if item != none and seen.at(item, default: none) == none {
      seen = seen.insert(item, true)
      out = out.push(item)
    }
  }
  out
}

#let _colonnes_auto(n) = {
  range(0, n).map(_ => auto)
}

#let _colonnes_fr(n) = {
  range(0, n).map(_ => 1fr)
}

#let _texte_paragraphes(x) = {
  if x == none { none }
  else if type(x) == content { x }
  else {
    let s = str(x)
    let parts = s.split("\n\n").map(p => p.trim()).filter(p => p != "")
    if parts.len() <= 1 {
      s
    } else {
      let out = []
      for i in range(0, parts.len()) {
        if i > 0 { out = out + parbreak() }
        out = out + parts.at(i)
      }
      out
    }
  }
}

#let _liste_lignes(items) = {
  if items == none { none }
  else {
    let _emit(x, out, first) = {
      if x == none {
        (out, first)
      } else if type(x) == array {
        let o = out
        let f = first
        for y in x {
          let (o2, f2) = _emit(y, o, f)
          o = o2
          f = f2
        }
        (o, f)
      } else if type(x) == content {
        let o = if first { out + x } else { out + v(0.25em) + x }
        (o, false)
      } else {
        let s = str(x)
        if s == "" { (out, first) }
        else {
          let o = if first { out + s } else { out + v(0.25em) + s }
          (o, false)
        }
      }
    }

    let (out, first) = _emit(items, [], true)
    if first { none } else { out }
  }
}
