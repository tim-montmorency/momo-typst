// lib.typ — template partagé (plan de cours).
//
// Usage (dans un .typ à la racine du dépôt):
//   #import "lib.typ": plan_de_cours
//   #show: plan_de_cours.with(...)
//   Votre contenu...
// Sources de vérité
#import "data/cours.typ": cours
#import "data/botin.typ": personnes
#import "data/bureaux.typ": bureaux

// Markdown
#import "@preview/cmarker:0.1.8"

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
      let t = lines.at(end).trim()
      // Fin de section au prochain heading (#, ##, ###...)
      if t.starts-with("#") { break }
      end += 1
    }
    let before = lines.slice(0, start).join("\n")
    let section = lines.slice(start + 1, end).join("\n")
    let after = lines.slice(end).join("\n")
    (before, section, after)
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

#let _extraire_section_md_par_titres_niveau(md, niveau, titres) = {
  // titres: tuple/list de titres sans le préfixe "### ".
  for t in titres {
    let (avant, section, apres) = _extraire_section_md_niveau(md, niveau, t)
    if section != none { return (avant, section, apres, t) }
  }
  (md, none, "", none)
}

#let _extraire_section_md_par_titres(md, titres) = {
  // titres: tuple/list de titres sans le préfixe "## ".
  for t in titres {
    let (avant, section, apres) = _extraire_section_md(md, t)
    if section != none { return (avant, section, apres, t) }
  }
  (md, none, "", none)
}

#let _rendre_markdown(md) = {
  let (_, corps) = cmarker.render-with-metadata(
    md,
    // Pas de métadonnées sur les fragments.
    metadata-block: none,
    scope: (image: (source, alt: none, format: auto) => image(source, alt: alt, format: format)),
  )
  corps
}

#let _case_contexte(coche: false) = box(
  width: 1.2em,
  height: 1.2em,
  stroke: 1pt,
  inset: 0pt,
)[#align(center, if coche { [X] } else { [] })]

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

#let _items_materiel_canoniques = (
  "Disque dur portatif.",
  "Carte SD (pour les détails voir le guide_etudiants).",
  "Clé USB.",
  "Cahier ou papiers divers, pour griffonner, conceptualiser, réaliser des croquis et noter vos inspirations.",
  "Pour le travail à la maison avec Maya, il vous faut une carte graphique NVIDIA.",
  "Prévoir un budget d’environ 50$ pour des rendus complexes.",
  "Compte GitHub.",
)

#let section_materiel_requis(md_section) = {
  [
    #heading(level: 2, outlined: true, bookmarked: true)[
      Matériel, comptes et volumes requis
    ] <matériel-requis>
  ]
  _rendre_liste_cases_corps(_items_materiel_canoniques, md_section)
}

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

#let cours_par_numero(numero_cours) = {
  cours.at(numero_cours, default: none)
}

#let _exiger_cours(numero_cours) = {
  let meta = cours_par_numero(numero_cours)
  if meta == none {
    panic("Numero de cours inconnu: " + numero_cours + ". Ajoutez-le à data/cours.typ.")
  }
  meta
}

#let personne_par_id(id_prof) = {
  personnes.at(id_prof, default: none)
}

#let _exiger_personne(id_prof) = {
  let meta = personne_par_id(id_prof)
  if meta == none {
    panic("Personne inconnue: " + id_prof + ". Ajoutez-la à data/botin.typ.")
  }
  meta
}

#let bureau_par_id(id_bureau) = {
  bureaux.at(id_bureau, default: none)
}

#let charger_plan_de_cours_md(
  chemin_md,
  // Optionnel: forcer/compléter des valeurs au-dessus du frontmatter.
  surcharges: (:),
) = {
  let md_brut = read(chemin_md)
  let (meta_brut, _) = cmarker.render-with-metadata(
    md_brut,
    metadata-block: "frontmatter-yaml",
    // Important: résoudre les images relativement au projet (pas au package cmarker).
    scope: (image: (source, alt: none, format: auto) => image(source, alt: alt, format: format)),
  )

  let meta = if meta_brut == none { (:) } else { meta_brut }

  // Extrait seulement les clés qu’on supporte comme paramètres de `plan_de_cours`.
  // Important: on n'ajoute pas les clés absentes afin de ne pas écraser les valeurs
  // par défaut (ex: `logo`).
  let params = (
    (:) +
    (if meta.at("logo", default: none) != none { (logo: meta.at("logo")) } else { (:) }) +
    (if meta.at("numero_cours", default: none) != none { (numero_cours: meta.at("numero_cours")) } else { (:) }) +
    (if meta.at("titre", default: none) != none { (titre: meta.at("titre")) } else { (:) }) +
    (if meta.at("sous_titre", default: none) != none { (sous_titre: meta.at("sous_titre")) } else { (:) }) +
    (if meta.at("etablissement", default: none) != none { (etablissement: meta.at("etablissement")) } else { (:) }) +
    (if meta.at("programme", default: none) != none { (programme: meta.at("programme")) } else { (:) }) +
    (if meta.at("departement_prof", default: none) != none { (departement_prof: meta.at("departement_prof")) } else { (:) }) +
    (if meta.at("cours", default: none) != none { (cours: meta.at("cours")) } else { (:) }) +
    (if meta.at("session", default: none) != none { (session: meta.at("session")) } else { (:) }) +
    (if meta.at("id_prof", default: none) != none { (id_prof: meta.at("id_prof")) } else { (:) }) +
    (if meta.at("ids_profs", default: none) != none { (ids_profs: meta.at("ids_profs")) } else { (:) }) +
    (if meta.at("prof", default: none) != none { (prof: meta.at("prof")) } else { (:) }) +
    (if meta.at("courriel", default: none) != none { (courriel: meta.at("courriel")) } else { (:) }) +
    (if meta.at("bureau", default: none) != none { (bureau: meta.at("bureau")) } else { (:) }) +
    (if meta.at("plateformes", default: none) != none { (plateformes: meta.at("plateformes")) } else { (:) }) +
    (if meta.at("plateforme_teams", default: none) != none { (plateforme_teams: meta.at("plateforme_teams")) } else { (:) }) +
    (if meta.at("plateforme_timdoc", default: none) != none { (plateforme_timdoc: meta.at("plateforme_timdoc")) } else { (:) }) +
    (if meta.at("plateforme_github", default: none) != none { (plateforme_github: meta.at("plateforme_github")) } else { (:) }) +
    (if meta.at("plateforme_autre", default: none) != none { (plateforme_autre: meta.at("plateforme_autre")) } else { (:) }) +
    (if meta.at("derniere_mise_a_jour", default: none) != none { (derniere_mise_a_jour: meta.at("derniere_mise_a_jour")) } else { (:) })
  )

  // Normalisation minimale: accepte aussi `plateformes: "Teams, GitHub"`.
  if params.at("plateformes", default: none) != none {
    let v = params.at("plateformes")
    if type(v) == "string" {
      let parts = v.split(",").map(p => p.trim()).filter(p => p != "")
      params = params + (plateformes: parts)
    }
  }

  // Applique les surcharges en dernier.
  params = params + surcharges

  // Rend le Markdown, en remplaçant certaines sections par des rendus dédiés.
  let md_sans_meta = _retirer_frontmatter_yaml(md_brut)

  let (a1, sec_contexte, reste1, _) = _extraire_section_md_par_titres(
    md_sans_meta,
    ("Contexte d’apprentissage et méthodes pédagogiques",),
  )
  let (a2, sec_materiel, reste2, _) = _extraire_section_md_par_titres(
    reste1,
    ("Matériel requis", "Matériel, comptes et volumes requis"),
  )

  let corps = []
  if a1 != none and str(a1).trim() != "" { corps = corps + _rendre_markdown(a1) }
  if sec_contexte != none {
    if corps != [] { corps = corps + v(1.0em) }
    corps = corps + section_contexte_apprentissage(sec_contexte)
    corps = corps + v(1.0em)
  }
  if a2 != none and str(a2).trim() != "" { corps = corps + _rendre_markdown(a2) }
  if sec_materiel != none {
    if corps != [] { corps = corps + v(1.0em) }
    corps = corps + section_materiel_requis(sec_materiel)
    corps = corps + v(1.0em)
  }

  // Sous-section (###) dans "Évaluation des apprentissages": rendue en tableau.
  let (a3, sec_sommatives, reste3, _) = _extraire_section_md_par_titres_niveau(
    reste2,
    3,
    ("Évaluations sommatives",),
  )
  if a3 != none and str(a3).trim() != "" { corps = corps + _rendre_markdown(a3) }
  if sec_sommatives != none {
    if corps != [] { corps = corps + v(1.0em) }
    corps = corps + section_evaluations_sommatives(sec_sommatives)
    corps = corps + v(1.0em)
  }
  if reste3 != none and str(reste3).trim() != "" { corps = corps + _rendre_markdown(reste3) }

  (params, corps)
}

// Variante pratique: lit le chemin du Markdown depuis `--input md=...`.
// Utile pour avoir un seul wrapper `.typ` réutilisable.
#let charger_plan_de_cours_md_input(
  // Valeur par défaut si `md` n’est pas fourni.
  default: none,
  surcharges: (:),
) = {
  let chemin_md = sys.inputs.at("md", default: default)
  if chemin_md == none {
    panic(
      "Aucun fichier Markdown fourni. " +
      "Utilisez `--input md=mon-fichier.md` ou appelez charger_plan_de_cours_md(\"mon-fichier.md\").",
    )
  }
  charger_plan_de_cours_md(chemin_md, surcharges: surcharges)
}

#let _exiger_bureau(id_bureau) = {
  let meta = bureau_par_id(id_bureau)
  if meta == none {
    panic("Bureau inconnu: " + id_bureau + ". Ajoutez-le à data/bureaux.typ.")
  }
  meta
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
  else if type(x) == "content" { x }
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
    let xs = if type(items) == "array" { items } else { items }
    let ys = xs.map(x => if x == none { none } else { str(x) }).filter(x => x != none and x != "")
    if ys.len() == 0 { none } else { stack(spacing: 0.25em, ..ys) }
  }
}

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

#let page_couverture_plan_de_cours(
  // Chemin d'image optionnel pour le logo (ex: "cm_logo.png").
  logo: none,
  titre_droite: [PLAN DE COURS],
  instruction: [Sélectionnez \# du cours et appuyez sur TAB],

  texte_heures: [Sélectionnez le nombre d’heures],
  texte_ponderation: [Sélectionnez la pondération],
  texte_programme: [Techniques d’intégration multimédia],
  texte_departement_programme: [Techniques d’intégration multimédia],
  texte_session: [Sélectionnez la session],
  texte_prof: [Sélectionnez votre nom],
  texte_departement_prof: [Sélectionnez votre département],
  texte_courriel: [Sélectionnez votre courriel],
  texte_bureau: [Sélectionnez votre bureau],

  // Nouvelle API (préférée): liste de plateformes cochées (ex: ("Teams", "GitHub", "Moodle")).
  // Si none, on retombe sur les booléens (compatibilité).
  plateformes: none,

  // Ancienne API (compatibilité)
  plateforme_teams: false,
  plateforme_timdoc: false,
  plateforme_github: false,
  plateforme_autre: false,

  coordination_nom: [Lora Boisvert],
  coordination_courriel: [lora.boisvert\@cmontmorency.qc.ca],
  coordination_bureau: [C-1651],
) = {
  set page(
    width: 11in,
    height: 8.5in,
    margin: (x: 2.2cm, y: 2.2cm),
    footer: context { align(right)[#counter(page).display("1")] },
  )
  set text(11pt)
  set par(leading: 1.2em)

  // Header row: logo (left) + title (right)
  grid(
    columns: (1fr, 1fr),
    align: (left, right),
    gutter: 0pt,
    if logo != none { image(logo, height: 1.6cm) } else { [] },
    block({
      set text(18pt, weight: "bold")
      titre_droite
    }),
  )

  v(1.2cm)
  align(center, block({
    set text(22pt, weight: "bold")
    instruction
  }))
  v(0.5cm)
  line(length: 100%, stroke: 1pt)
  v(0.7cm)

  // Table: ligne verticale continue + espacement stable.
  // On ajoute du padding à droite sur les libellés pour éviter que le `:` touche
  // la ligne verticale.
  let _cell_label(label) = pad(
    right: 0.65em,
    top: 0.3em,
    bottom: 0.3em,
    block({
      set text(weight: "bold")
      label
    }),
  )
  // La barre centrale est le bord gauche de la colonne de droite.
  // Important: on rend `value` directement (pas dans `block(...)`) pour éviter
  // un espacement supplémentaire quand `value` contient des retours de ligne.
  let _cell_valeur(value) = box(
    stroke: (left: 1pt),
    inset: (left: 0.9em, top: 0.3em, bottom: 0.3em),
  )[ #value ]

  let _plateformes = block({
      let connues = ("Teams", "Timdoc", "GitHub")

      let _normaliser_plateforme(p) = {
        if p == none { none }
        else {
          let s = str(p)
          if s in ("Teams", "teams", "TEAMS") { "Teams" }
          else if s in ("Timdoc", "timdoc", "TIMDOC") { "Timdoc" }
          else if s in ("GitHub", "Github", "github", "GITHUB", "Git Hub", "git hub", "Git-Hub", "git-hub") { "GitHub" }
          else { s }
        }
      }

      let coches = if plateformes != none {
        plateformes
      } else {
        // Compatibilité: reconstruit une liste de noms cochés à partir des booléens.
        (
          if plateforme_teams { "Teams" } else { none },
          if plateforme_timdoc { "Timdoc" } else { none },
          if plateforme_github { "GitHub" } else { none },
          if plateforme_autre { "Autre" } else { none },
        ).filter(x => x != none)
      }

      let coches_norm = if coches == none {
        ()
      } else {
        coches.map(p => _normaliser_plateforme(p)).filter(x => x != none).dedup()
      }

      // Plateformes affichées: celles qu’on connaît + celles cochées mais inconnues.
      let inconnues = coches_norm.filter(p => not (p in connues))
      let affichees = (connues + inconnues).dedup()

      let items_effectifs = affichees.map(p => _case_a_cocher([#p], coche: p in coches_norm))

      let nb = items_effectifs.len()
      // 1 ligne si la liste est courte; sinon, force un rendu sur 2 lignes.
      let nb_cols = calc.max(1, calc.min(4, if nb <= 4 { nb } else { calc.ceil(nb / 2) }))

      grid(
        columns: _colonnes_fr(nb_cols),
        gutter: 1.1em,
        ..items_effectifs,
      )
    })

  // Table 40/60, pleine largeur, avec séparateur vertical unique.
  block(width: 100%)[#table(
    columns: (0.4fr, 0.6fr),
    align: (right, left),
    inset: 0pt,
    stroke: none,

    _cell_label([Nombre d’heures d’enseignement :]), _cell_valeur(texte_heures),
    _cell_label([Pondération :]), _cell_valeur(texte_ponderation),
    _cell_label([Programme :]), _cell_valeur(texte_programme),
    _cell_label([Département du programme :]), _cell_valeur(texte_departement_programme),
    _cell_label([Session :]), _cell_valeur(texte_session),
    _cell_label([Professeure ou professeur :]), _cell_valeur(texte_prof),
    _cell_label([Département de la professeure ou du professeur :]), _cell_valeur(texte_departement_prof),
    _cell_label([Courriel :]), _cell_valeur(texte_courriel),
    _cell_label([Bureau :]), _cell_valeur(texte_bureau),
    _cell_label([Plateforme pédagogique utilisée :]), _cell_valeur(_plateformes),
    _cell_label([Coordination :]), _cell_valeur(coordination_nom),
    _cell_label([Contact de la coordination :]),
    _cell_valeur(stack(spacing: 0.25em, coordination_courriel, [Bureau : #coordination_bureau])),
  )]
}

#let plan_de_cours(
  // Page couverture
  logo: "cm_logo.png",

  // Single source of truth key
  numero_cours: none,

  // Title block on the second page
  titre: [Plan de cours],
  sous_titre: none,
  etablissement: [Collège Montmorency],
  programme: [Techniques d’intégration multimédia],
  departement_prof: none,
  cours: none,
  session: none,
  // Références au botin (data/botin.typ)
  // - Pour un seul prof: utilisez id_prof
  // - Pour plusieurs profs: utilisez ids_profs: ("id1", "id2")
  id_prof: none,
  ids_profs: none,
  prof: none,
  courriel: none,
  // NOTE: `bureau` est la valeur (ex: [C-1651]) — pas une ligne avec "Bureau :".
  bureau: none,
  derniere_mise_a_jour: none,

  // Plateformes (couverture)
  plateformes: none,
  // Ancienne API (compatibilité)
  plateforme_teams: false,
  plateforme_timdoc: false,
  plateforme_github: false,
  plateforme_autre: false,

  // Content
  body,
) = {
  let meta_cours = if numero_cours != none { _exiger_cours(numero_cours) } else { none }

  let liste_ids_profs = if ids_profs != none {
    ids_profs
  } else if id_prof != none {
    (id_prof,)
  } else {
    none
  }

  let profs = if liste_ids_profs == none {
    ()
  } else {
    liste_ids_profs.map(id => _exiger_personne(id))
  }

  let noms_profs = profs.map(p => p.at("nom", default: none)).filter(x => x != none)

  let prof_effectif = if prof != none {
    prof
  } else if noms_profs.len() == 0 {
    none
  } else {
    // Un prof par ligne.
    _lignes(noms_profs)
  }

  let departement_prof_effectif = if departement_prof != none { departement_prof } else { programme }

  let courriel_effectif = if courriel != none {
    courriel
  } else {
    let courriels = profs.map(p => p.at("courriel", default: none)).filter(x => x != none)
    if courriels.len() == 0 { none } else { _lignes(courriels) }
  }

  let bureaux_codes = if bureau != none {
    (bureau,)
  } else {
    let ids_bureaux = profs.map(p => p.at("bureau_id", default: none)).filter(x => x != none).dedup()
    let codes = ids_bureaux.map(idb => _exiger_bureau(idb).code)

    // Compatibilité: si une entrée de botin a encore `bureau` directement.
    let codes_directs = profs.map(p => p.at("bureau", default: none)).filter(x => x != none)

    let tous = (codes + codes_directs).dedup()
    if tous.len() == 0 { none } else { tous }
  }

  // Couverture: valeur seulement (sans libellé)
  let bureau_couverture = if bureaux_codes == none {
    none
  } else if bureaux_codes.len() == 1 {
    bureaux_codes.at(0)
  } else {
    _joindre(bureaux_codes)
  }

  // Bloc titre: avec libellé
  let bureau_titre = if bureaux_codes == none {
    none
  } else if bureaux_codes.len() == 1 {
    [Bureau : #bureaux_codes.at(0)]
  } else {
    [Bureaux : #(_joindre(bureaux_codes))]
  }
  let ligne_cours = if cours != none {
    cours
  } else if meta_cours != none {
    // Affichage par défaut: "NUMÉRO · Titre"
    [#meta_cours.numero · #meta_cours.titre]
  } else {
    none
  }

  let titre_couverture = if meta_cours != none {
    [#meta_cours.numero #meta_cours.titre]
  } else {
    [Sélectionnez \# du cours et appuyez sur TAB]
  }

  // Métadonnées PDF (macOS Aperçu lit Title/Author)
  let titre_pdf = if meta_cours != none {
    meta_cours.numero + " " + meta_cours.titre
  } else {
    "Plan de cours"
  }
  let auteur_pdf = if noms_profs.len() == 0 { none } else { noms_profs.join(", ") }
  set document(title: titre_pdf)
  if auteur_pdf != none {
    set document(author: auteur_pdf)
  }

  // First page (form-like cover)
  page_couverture_plan_de_cours(
    logo: logo,
    instruction: titre_couverture,
    texte_programme: programme,
    texte_departement_programme: programme,
    texte_heures: if meta_cours != none { meta_cours.heures } else { [Sélectionnez le nombre d’heures] },
    texte_ponderation: if meta_cours != none { meta_cours.ponderation } else { [Sélectionnez la pondération] },
    texte_session: if meta_cours != none and ("session" in meta_cours) { [Session #meta_cours.session] } else { [Sélectionnez la session] },
    texte_prof: if prof_effectif != none { prof_effectif } else { [Sélectionnez votre nom] },
    texte_departement_prof: departement_prof_effectif,
    texte_courriel: if courriel_effectif != none { courriel_effectif } else { [Sélectionnez votre courriel] },
    texte_bureau: if bureau_couverture != none { bureau_couverture } else { [Sélectionnez votre bureau] },

    plateformes: plateformes,
    plateforme_teams: plateforme_teams,
    plateforme_timdoc: plateforme_timdoc,
    plateforme_github: plateforme_github,
    plateforme_autre: plateforme_autre,
  )

  // Main document starts on a fresh page
  pagebreak()

  // Global styling
  set page(
    width: 11in,
    height: 8.5in,
    margin: (x: 2.2cm, y: 2.2cm),
    numbering: "1",
    footer: context { align(right)[#counter(page).display("1")] },
  )
  set text(11pt)
  set par(justify: true, leading: 1.25em)
  set heading(numbering: none)

  // Heading spécial pour le « bloc titre » (numérotation désactivée).
  // On le garde comme `heading` pour qu'il soit cliquable dans l'outline PDF.
  show heading.where(level: 1, numbering: none): it => block({
    align(center, block({
      set text(22pt, weight: "bold")
      it
    }))
    v(0.8em)
  })

  // H1 racine du cours (outline) — caché pour ne pas apparaître avant la page 2.
  // Permet d'avoir une seule hiérarchie: H1 (cours) > H2 (sections principales) > H3.
  let titre_cours_outline = if meta_cours != none {
    [#meta_cours.numero #meta_cours.titre]
  } else {
    titre
  }
  hide([
    #heading(level: 1, numbering: none, outlined: true, bookmarked: true)[#titre_cours_outline]
    <cours>
  ])

  // Page 2: Présentation du cours (données dans data/cours.typ)
  page_presentation_du_cours(meta_cours)
  pagebreak()

  // Grille stylistique: après décalage, les sections principales sont level 2
  // et les sous-sections level 3.
  show heading.where(level: 2): it => block({
    set text(16pt, weight: "semibold")
    upper(it.body)
    v(0.4em)
    line(length: 100%)
    v(0.8em)
  })

  show heading.where(level: 3): it => block({
    set text(13pt, weight: "semibold")
    upper(it.body)
    v(0.3em)
  })

  // Body
  body
}

// Alias (compatibilité):
#let syllabus = plan_de_cours
