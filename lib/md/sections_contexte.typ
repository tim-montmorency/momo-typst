// lib/md/sections_contexte.typ — section Contexte d’apprentissage

#import "../utils.typ": _normaliser_choix

#let _case_contexte(coche: false) = box(
  width: 1.2em,
  height: 1.2em,
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
  let choix = _choix_depuis_md(md_section)
  let selection = (:)
  for it in choix {
    let coche = it.at(0)
    let lib = it.at(1)
    selection.insert(_normaliser_choix(lib), coche)
  }

  // Inconnus: ceux dans le markdown qui ne matchent aucun canonique.
  let canon_norm = items_canoniques.map(x => _normaliser_choix(x)).dedup()
  let inconnus = choix
    .filter(it => it.at(0))
    .map(it => it.at(1))
    .filter(lib => not (_normaliser_choix(lib) in canon_norm))
    .dedup()

  let rows = (items_canoniques + inconnus).map(label => {
    let key = _normaliser_choix(label)
    let coche = selection.at(key, default: false)
    grid(
      columns: (auto, 1fr),
      gutter: 1.4em,
      align: (left, left),
      _case_contexte(coche: coche),
      [#label],
    )
  })

  stack(spacing: 0.7em, ..rows)
}

#let _items_contexte_canoniques = (
  "Exposés magistraux",
  "En laboratoire informatique",
  "Apprentissage et utilisation de logiciels sous forme de démonstrations, d'exercices, de travaux pratiques",
  "Projets multimédias",
  "Exposés interactifs",
  "Écoute de pistes sonores",
  "Activités coopératives",
  "Tutorat individuel ou de petits groupes",
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
