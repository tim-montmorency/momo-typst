// lib/md/sections_contexte.typ — section Contexte d’apprentissage

#import "../utils.typ": _normaliser_choix

// Normalisation dédiée aux listes à cases:
// - minuscules
// - retire ponctuation (via _normaliser_choix) + apostrophes
// - retire quelques mots vides fréquents
// Objectif: éviter des "doublons" quand le Markdown varie légèrement
// (ex: "de" vs "en", ou une fin de phrase tronquée).
#let _mots_vides = (
  "de",
  "du",
  "des",
  "d",
  "en",
  "a",
  "à",
  "au",
  "aux",
  "et",
  "ou",
  "la",
  "le",
  "les",
  "un",
  "une",
  "dans",
  "pour",
)

#let _cle_choix_case(s) = {
  let x = lower(_normaliser_choix(s))
  x = x.replace("\"", "")
  x = x.replace("'", "")
  x = x.replace("[", "")
  x = x.replace("]", "")

  // Si le libellé contient un lien Markdown, on élimine l'URL pour ne garder
  // que le texte descriptif.
  if x.contains("http") {
    x = x.split("http").at(0)
  }
  let mots = x.split(" ")
    .map(w => w.trim())
    .filter(w => w != "")
    .filter(w => not (w in _mots_vides))
  mots.join(" ")
}

#let _rendre_libelle_md(s) = {
  // Rend un libellé comme du contenu. Supporte un lien Markdown inline:
  //   "... [texte](https://exemple.com) ..."
  // Si aucun lien n'est détecté, retourne le texte brut.
  if type(s) == content {
    s
  } else {
    let raw = str(s)
    if raw.contains("](") and raw.contains("[") {
      let parts = raw.split("[")
      let prefix = parts.at(0, default: "")
      let rest = parts.slice(1).join("[")
      let segs = rest.split("](")
      if segs.len() >= 2 {
        let link_text = segs.at(0)
        let after = segs.at(1)
        let after_parts = after.split(")")
        let url = after_parts.at(0, default: "")
        let suffix = after_parts.slice(1).join(")")
        [
          #prefix
          #link(url)[#underline(stroke: blue)[#text(fill: blue)[#link_text]]]
          #suffix
        ]
      } else {
        [#raw]
      }
    } else {
      [#raw]
    }
  }
}

#let _trouver_cle_canonique(cle, cles_canoniques) = {
  if cle in cles_canoniques {
    cle
  } else {
    // Tolère un libellé tronqué (substring), ex: "... pour des rendus"
    // vs "... pour des rendus complexes".
    cles_canoniques
      .filter(k => k.contains(cle) or cle.contains(k))
      .at(0, default: none)
  }
}

#let _case_contexte(coche: false) = box(
  width: 1.1em,
  height: 1.1em,
  stroke: 1pt,
  inset: 0pt,
)[#align(center, if coche { [X] } else { [] })]

#let _choix_depuis_md(md_section) = {
  // Extrait une liste d’items sélectionnés depuis une section markdown.
  // - Supporte task-list: [x]/[ ]
  // - Si pas de task-list, l’item est considéré sélectionné.
  let _item(line) = {
    let t = line.trim()
    if not (t.starts-with("- ") or t.starts-with("* ") or t.starts-with("+ ")) {
      none
    } else {
      let rest = t.slice(2).trim()
      let coche = true
      if rest.starts-with("[x] ") or rest.starts-with("[X] ") {
        coche = true
        rest = rest.slice(4).trim()
      } else if rest.starts-with("[ ] ") {
        coche = false
        rest = rest.slice(4).trim()
      }
      if rest == "" { none } else { (coche, rest) }
    }
  }

  md_section.split("\n").map(_item).filter(x => x != none)
}

#let _rendre_liste_cases_corps(
  items_canoniques,
  md_section,
) = {
  let cles_canoniques = items_canoniques.map(x => _cle_choix_case(x)).dedup()

  let choix = _choix_depuis_md(md_section)
  let selection = (:)
  let libelles_par_cle = (:)
  for it in choix {
    let coche = it.at(0)
    let lib = it.at(1)
    let cle_brute = _cle_choix_case(lib)
    let cle = _trouver_cle_canonique(cle_brute, cles_canoniques)
    let cle_finale = if cle != none { cle } else { cle_brute }
    selection.insert(cle_finale, coche)
    // Conserve le libellé Markdown original pour préserver des détails (ex: liens).
    if libelles_par_cle.at(cle_finale, default: none) == none {
      libelles_par_cle.insert(cle_finale, lib)
    }
  }

  // Inconnus: ceux dans le markdown qui ne matchent aucun canonique.
  let inconnus = choix
    .filter(it => it.at(0))
    .filter(it => {
      let cle_brute = _cle_choix_case(it.at(1))
      _trouver_cle_canonique(cle_brute, cles_canoniques) == none
    })
    .map(it => it.at(1))
    .dedup()

  let rows = (items_canoniques + inconnus).map(label => {
    let key = _cle_choix_case(label)
    let coche = selection.at(key, default: false)
    let lib_affiche = libelles_par_cle.at(key, default: label)
    grid(
      columns: (auto, 1fr),
      gutter: 1.1em,
      align: (left, left),
      // Aligne la case sur la première ligne des libellés multi-lignes.
      align(top)[#move(dy: -0.12em)[#_case_contexte(coche: coche)]],
      _rendre_libelle_md(lib_affiche),
    )
  })

  // Légèrement plus compact pour éviter un saut de page.
  stack(spacing: 0.55em, ..rows)
}

#let _items_contexte_canoniques = (
  "Exposés magistraux",
  "En laboratoire informatique",
  "En studio",
  "Apprentissage et utilisation de logiciels sous forme de démonstrations, d'exercices, de travaux pratiques",
  "Projets multimédias",
  "Exposés interactifs",
  "Écoute de pistes sonores",
  "Activités coopératives",
  "Tutorat individuel ou en petits groupes",
  "En présence",
  "En ligne",
  "Stage en milieu de travail",
  "Discussions en groupe (tables rondes)",
)

#let section_contexte_apprentissage(md_section) = {
  [
    #heading(level: 2, outlined: true, bookmarked: true)[
      Contexte d’apprentissage et méthodes pédagogiques
    ] <contexte-dapprentissage-et-méthodes-pédagogiques>
  ]
  _rendre_liste_cases_corps(_items_contexte_canoniques, md_section)
}
