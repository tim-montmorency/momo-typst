// lib/plan.typ — orchestrateur du gabarit public `plan_de_cours`

#import "utils.typ": _joindre, _lignes
#import "data.typ": _exiger_cours, _exiger_personne, _exiger_bureau
#import "pages/couverture.typ": page_couverture_plan_de_cours
#import "pages/presentation.typ": page_presentation_du_cours
#import "typography.typ": FONT_CORPS, FONT_TITRES, INTERLETTRE_DEFAUT, TAILLE_CORPS, INTERLIGNE_CORPS, POIDS_TITRES

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

  // Optionnel: désactiver la page 2 auto (utile si le Markdown contient déjà
  // une section "Présentation du cours").
  inclure_presentation_du_cours: true,

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
  // Typographie (normes graphiques):
  // - Corps: Geist Regular, interlignage 120%, inter-lettrage 0
  // - Titres/sous-titres: Inter Tight SemiBold, inter-lettrage 0
  set text(font: FONT_CORPS, tracking: INTERLETTRE_DEFAUT, TAILLE_CORPS)
  set par(justify: true, leading: INTERLIGNE_CORPS)
  set heading(numbering: none)

  // Heading spécial pour le « bloc titre » (numérotation désactivée).
  // On le garde comme `heading` pour qu'il soit cliquable dans l'outline PDF.
  show heading.where(level: 1, numbering: none): it => block({
    align(center, block({
      set par(leading: 1em)
      set text(font: FONT_TITRES, tracking: INTERLETTRE_DEFAUT, 22pt, weight: POIDS_TITRES)
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

  // Grille stylistique: après décalage, les sections principales sont level 2
  // et les sous-sections level 3.
  // NOTE: doit être défini avant la page 2 pour qu'elle ait le même style.
  show heading.where(level: 2): it => block({
    set par(leading: 1em)
    set text(font: FONT_TITRES, tracking: INTERLETTRE_DEFAUT, 16pt, weight: POIDS_TITRES)
    it.body
    v(0.8em)
  })

  show heading.where(level: 3): it => block({
    set par(leading: 1.1em)
    set text(font: FONT_TITRES, tracking: INTERLETTRE_DEFAUT, 13pt, weight: POIDS_TITRES)
    it.body
    v(0.5em)
  })

  // Page 2: Présentation du cours (données dans data/cours.typ)
  if inclure_presentation_du_cours {
    page_presentation_du_cours(meta_cours)
    pagebreak()
  }

  // Body
  body
}

// Alias (compatibilité):
#let syllabus = plan_de_cours
