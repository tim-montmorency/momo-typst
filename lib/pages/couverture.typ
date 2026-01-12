// lib/pages/couverture.typ — page couverture (formulaire)

#import "../utils.typ": _case_a_cocher, _colonnes_fr

#import "../paths.typ": _resoudre_source_asset
#import "../typography.typ": FONT_CORPS, FONT_TITRES, INTERLETTRE_DEFAUT, TAILLE_CORPS, INTERLIGNE_CORPS, POIDS_TITRES

#let page_couverture_plan_de_cours(
  // Chemin d'image optionnel pour le logo (ex: "assets/cm_logo.png").
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

  // Libellés (singulier/pluriel) — calculés par l'orchestrateur.
  libelle_courriel: [Courriel :],
  libelle_bureau: [Bureau :],

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
  set text(font: FONT_CORPS, tracking: INTERLETTRE_DEFAUT, TAILLE_CORPS)
  set par(leading: INTERLIGNE_CORPS)

  // Header row: logo (left) + title (right)
  let logo_effectif = if logo == none {
    none
  } else {
    _resoudre_source_asset(logo)
  }
  grid(
    columns: (1fr, 1fr),
    align: (left, right),
    gutter: 0pt,
    if logo_effectif != none { image(logo_effectif, height: 1.6cm) } else { [] },
    block({
      set par(leading: 1em)
      set text(font: FONT_TITRES, tracking: INTERLETTRE_DEFAUT, 18pt, weight: POIDS_TITRES)
      titre_droite
    }),
  )

  v(1.2cm)
  align(center, block({
    set par(leading: 1em)
    set text(font: FONT_TITRES, tracking: INTERLETTRE_DEFAUT, 22pt, weight: POIDS_TITRES)
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
  // Important: on rend `value` directement (pas dans `block(...)`) pour éviter
  // un espacement supplémentaire quand `value` contient des retours de ligne.
  // NOTE: la ligne verticale est gérée par `table(stroke: ...)` pour rester
  // continue, même si un libellé s'étend sur plusieurs lignes.
  let _cell_valeur(value) = pad(
    left: 0.9em,
    top: 0.3em,
    bottom: 0.3em,
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
    // Colonne de gauche auto: évite que les libellés (ex: Département...) cassent.
    // Colonne de droite: prend le reste.
    columns: (auto, 1fr),
    align: (right, left),
    inset: 0pt,
    // Une seule ligne verticale entre les colonnes, sans bordures externes.
    stroke: (x: 1pt, y: none, top: none, bottom: none, left: none, right: none),

    _cell_label([Nombre d’heures d’enseignement :]), _cell_valeur(texte_heures),
    _cell_label([Pondération :]), _cell_valeur(texte_ponderation),
    _cell_label([Programme :]), _cell_valeur(texte_programme),
    _cell_label([Département du programme :]), _cell_valeur(texte_departement_programme),
    _cell_label([Session :]), _cell_valeur(texte_session),
    _cell_label([Professeure ou professeur :]), _cell_valeur(texte_prof),
    _cell_label([Département de la professeure ou du professeur :]), _cell_valeur(texte_departement_prof),
    _cell_label(libelle_courriel), _cell_valeur(texte_courriel),
    _cell_label(libelle_bureau), _cell_valeur(texte_bureau),
    _cell_label([Plateforme pédagogique utilisée :]), _cell_valeur(_plateformes),
    _cell_label([Coordination :]), _cell_valeur(coordination_nom),
    _cell_label([Contact de la coordination :]),
    _cell_valeur(stack(spacing: 0.25em, coordination_courriel, [Bureau : #coordination_bureau])),
  )]
}
