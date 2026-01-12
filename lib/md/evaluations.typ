// lib/md/evaluations.typ — parser + rendu tableau "Évaluations sommatives"

#import "../utils.typ": _normaliser_choix
#import "core.typ": _rendre_markdown

#let _extraire_blocs_evaluations_sommatives(md_section) = {
  // Parse une section Markdown de niveau 3 contenant des blocs "#### <titre>".
  // Chaque bloc contient une liste de champs (Description, Type, Critères, Échéance, Pondération).
  let lines = md_section.split("\n")
  let i = 0
  let blocs = ()

  let _cle_canonique(k) = {
    let x = lower(_normaliser_choix(str(k)))
    // tolère ':' et espaces
    if x.starts-with("description") { "description" }
    else if x.starts-with("type") { "type" }
    else if x.starts-with("criter") { "criteres" }
    else if x.starts-with("critèr") { "criteres" }
    else if x.starts-with("échéance") or x.starts-with("echeance") { "echeance" }
    else if x.starts-with("pondération") or x.starts-with("ponderation") { "ponderation" }
    else { none }
  }

  let _indentation(line) = {
    // Compte les espaces/tabs en début de ligne.
    let j = 0
    while j < line.len() {
      let ch = line.at(j)
      if ch == " " or ch == "\t" { j += 1 } else { break }
    }
    j
  }

  let _est_heading4(line) = line.trim().starts-with("#### ")

  while i < lines.len() {
    let t = lines.at(i).trim()
    if _est_heading4(t) {
      let titre = t.slice(5).trim()
      i += 1
      // IMPORTANT: utiliser des clés string (pas des identifiants) pour que
      // `insert(cle, ...)` et `at(cle)` soient cohérents.
      let champs = (
        "description": (),
        "type": (),
        "criteres": (),
        "echeance": (),
        "ponderation": (),
      )
      let cle = none
      while i < lines.len() and not _est_heading4(lines.at(i)) {
        let ln = lines.at(i)
        let s = ln.trim()
        let ind = _indentation(ln)
        if s == "" { i += 1; continue }

        // Clé: item de premier niveau (indentation = 0)
        if ind == 0 and (ln.starts-with("- ") or ln.starts-with("* ") or ln.starts-with("+ ")) {
          let key_raw = s.slice(2).trim()
          if key_raw.ends-with(":") {
            key_raw = key_raw.slice(0, key_raw.len() - 1).trim()
          }
          cle = _cle_canonique(key_raw)
          i += 1
          continue
        }

        // Valeur: item indenté (sous-liste)
        if ind > 0 and (s.starts-with("- ") or s.starts-with("* ") or s.starts-with("+ ")) {
          let tail = s.slice(2).trim()
          if cle != none and tail != "" {
            let prev = champs.at(cle, default: ())
            champs.insert(cle, prev + (tail,))
          }
          i += 1
          continue
        }

        i += 1
      }

      // Normalise champs simples: on garde seulement la première ligne pour echeance/ponderation/type.
      let desc = champs.at("description", default: ())
      let criteres = champs.at("criteres", default: ())
      let type = {
        let xs = champs.at("type", default: ())
        if xs.len() == 0 { none } else { xs.at(0) }
      }
      let echeance = {
        let xs = champs.at("echeance", default: ())
        if xs.len() == 0 { none } else { xs.at(0) }
      }
      let ponderation = {
        let xs = champs.at("ponderation", default: ())
        if xs.len() == 0 { none } else { xs.at(0) }
      }

      blocs = blocs + ((
        titre: titre,
        description: desc,
        type: type,
        criteres: criteres,
        echeance: echeance,
        ponderation: ponderation,
      ),)
    } else {
      i += 1
    }
  }
  blocs
}

#let section_evaluations_sommatives(md_section) = {
  [
    #heading(level: 3, outlined: true, bookmarked: true)[Évaluations sommatives]
    <évaluations-sommatives>
  ]

  let evals = _extraire_blocs_evaluations_sommatives(md_section)
  if evals.len() == 0 {
    // Fallback: si la structure n'est pas reconnue, on rend le markdown tel quel.
    _rendre_markdown("### Évaluations sommatives\n\n" + md_section)
  } else {
    let _type_cases(t) = {
      let _case_type(label, coche: false) = {
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
      let x = if t == none { "" } else { str(t) }
      let xl = lower(x)
      let est_ind = xl.contains("individ")
      let est_eq = xl.contains("équip") or xl.contains("equip")
      grid(
        columns: (auto, auto),
        gutter: 1.2em,
        _case_type([Individuel], coche: est_ind),
        _case_type([Équipe], coche: est_eq),
      )
    }

    let _texte_paragraphes_local(t) = {
      if t == none { none }
      else {
        let s = str(t)
        let parts = s.split("\n\n").map(p => p.trim()).filter(p => p != "")
        if parts.len() == 0 {
          none
        } else if parts.len() == 1 {
          parts.at(0)
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

    let _cell_left(e) = {
      let desc_block = if e.description != none and e.description.len() > 0 {
        let desc = e.description.map(x => str(x)).filter(x => x.trim() != "")
        if desc.len() == 0 { none } else { _texte_paragraphes_local(desc.join("\n")) }
      } else {
        none
      }

      block(breakable: false)[
        #set par(leading: 1.15em)
        #set text(weight: "bold")
        #e.titre
        #set text(weight: "regular")
        #v(0.45em)
        #(desc_block)
        #(if desc_block != none { v(0.65em) } else { none })
        #_type_cases(e.type)
      ]
    }

    let _cell_mid(e) = {
      let cs = if e.criteres != none { e.criteres.map(x => str(x)).filter(x => x.trim() != "") } else { () }
      block(breakable: false)[
        #set par(leading: 1.15em)
        #(
          if cs.len() == 0 {
            ""
          } else {
            stack(
              spacing: 0.25em,
              ..cs.map(x => block(width: 100%)[#x]),
            )
          }
        )
      ]
    }

    let _cell_deadline(e) = block(breakable: false)[
      #set par(leading: 1.15em)
      #(if e.echeance == none { "" } else { str(e.echeance) })
    ]

    let _cell_pct(e) = block(breakable: false)[
      #set text(weight: "bold")
      #(if e.ponderation == none { "" } else { str(e.ponderation) })
    ]

    let header = table.header(
      pad(x: 0.25em, y: 0.2em)[
        #text(weight: "bold")[DESCRIPTION ET FORME DE L’ÉVALUATION]
      ],
      pad(x: 0.25em, y: 0.2em)[
        #align(center)[
          #text(weight: "bold")[SAVOIRS ESSENTIELS / PRINCIPAUX CRITÈRES D’ÉVALUATION]
        ]
      ],
      pad(x: 0.25em, y: 0.2em)[
        #align(center)[#text(weight: "bold")[ÉCHÉANCE]]
      ],
      pad(x: 0.25em, y: 0.2em)[
        #align(center)[#text(weight: "bold")[%]]
      ],
    )

    let body = ()
    for i in range(0, evals.len()) {
      let e = evals.at(i)
      body = body + (
        _cell_left(e),
        _cell_mid(e),
        _cell_deadline(e),
        _cell_pct(e),
      )
      if i < evals.len() - 1 {
        body = body + (table.hline(stroke: 1.6pt),)
      }
    }

    table(
      // Proportions proches du gabarit (colonne % plus visible).
      columns: (0.40fr, 0.42fr, 0.11fr, 0.07fr),
      inset: (x: 0.35em, y: 0.3em),
      stroke: 1.0pt,
      align: (left, left, left, right),
      // Bandeau d'en-tête gris pâle.
      fill: (x, y) => if y == 0 { luma(92%) } else { none },
      header,
      table.hline(stroke: 1.6pt),
      ..body,
    )
  }
}
