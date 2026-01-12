// lib/pages/presentation.typ — page 2: Présentation du cours

#import "../utils.typ": _texte_paragraphes, _liste_lignes, _colonnes_fr

#let page_presentation_du_cours(meta_cours) = {
  set par(justify: true, leading: 1.25em)

  let description = if meta_cours != none { meta_cours.at("description_du_cours", default: none) } else { none }
  let objectif = if meta_cours != none { meta_cours.at("objectif_integrateur", default: none) } else { none }
  let competences = if meta_cours != none { meta_cours.at("competences_ministerielles", default: none) } else { none }
  let objectifs = if meta_cours != none { meta_cours.at("objectifs_apprentissage", default: none) } else { none }
  let cours_lies = if meta_cours != none { meta_cours.at("cours_lies", default: none) } else { none }

  let prealables_abs = if cours_lies != none { cours_lies.at("prealables_absolus", default: none) } else { none }
  let prealables_rel = if cours_lies != none { cours_lies.at("prealables_relatifs", default: none) } else { none }
  let corequis = if cours_lies != none { cours_lies.at("corequis", default: none) } else { none }

  // Headings (indexés dans l'outline)
  [
    #heading(level: 2, outlined: true, bookmarked: true)[Présentation du cours]
    <présentation-du-cours>
  ]

  [
    #heading(level: 3, outlined: true, bookmarked: true)[Description du cours]
    <description-du-cours>
  ]
  let desc = _texte_paragraphes(description)
  if desc != none { desc } else { "" }
  v(0.9em)

  [
    #heading(level: 3, outlined: true, bookmarked: true)[Objectif intégrateur]
    <objectif-intégrateur>
  ]
  let obj = _texte_paragraphes(objectif)
  if obj != none { obj } else { "" }
  v(0.9em)

  [
    #heading(level: 3, outlined: true, bookmarked: true)[Compétence(s) ministérielle(s)]
    <compétences-ministérielles>
  ]
  let comp = _liste_lignes(competences)
  if comp != none { comp } else { "" }
  v(0.9em)

  [
    #heading(level: 3, outlined: true, bookmarked: true)[Objectifs d’apprentissage]
    <objectifs-dapprentissage>
  ]
  if objectifs != none {
    let xs = if type(objectifs) == "array" { objectifs } else { objectifs }
    enum(
      numbering: "1.",
      indent: 1.2em,
      body-indent: 1.2em,
      spacing: 0.35em,
      ..xs.map(x => [#str(x)]),
    )
  } else {
    ""
  }
  v(0.9em)

  [
    #heading(level: 3, outlined: true, bookmarked: true)[Cours liés (préalables absolus, relatifs, corequis)]
    <cours-liés>
  ]
  v(0.45em)

  // Tableau sans barres (ni verticales ni horizontales), avec 1–3 colonnes
  // selon la présence de préalables absolus/relatifs/corequis dans data/cours.typ.
  let _colonne(titre, items) = block({
    align(center, block({
      set text(weight: "bold")
      titre
    }))
    v(0.45em)
    let l = _liste_lignes(items)
    if l != none { l } else { "" }
  })

  let colonnes = (
    if _liste_lignes(prealables_abs) != none {
      _colonne([
        Les cours suivants sont préalables absolus au présent cours
      ], prealables_abs)
    } else { none },
    if _liste_lignes(prealables_rel) != none {
      _colonne([
        Les cours suivants sont préalables relatifs au présent cours
      ], prealables_rel)
    } else { none },
    if _liste_lignes(corequis) != none {
      _colonne([
        Les cours suivants sont corequis au présent cours
      ], corequis)
    } else { none },
  ).filter(x => x != none)

  if colonnes.len() > 0 {
    let n = colonnes.len()
    grid(
      columns: _colonnes_fr(n),
      gutter: if n == 1 { 0cm } else if n == 2 { 2.2cm } else { 1.4cm },
      align: (left, left),
      ..colonnes,
    )
  }
}
