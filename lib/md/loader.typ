// lib/md/loader.typ — charge un plan de cours depuis Markdown (frontmatter + sections spécialisées)

#import "@preview/cmarker:0.1.8"

#import "core.typ": _retirer_frontmatter_yaml, _extraire_section_md_par_titres, _extraire_section_md_par_titres_niveau, _rendre_markdown
#import "sections_contexte.typ": section_contexte_apprentissage
#import "sections_materiel.typ": section_materiel_requis
#import "evaluations.typ": section_evaluations_sommatives

#import "../paths.typ": _resoudre_chemin_depuis_racine, _resoudre_source_asset

#let charger_plan_de_cours_md(
  chemin_md,
  // Optionnel: forcer/compléter des valeurs au-dessus du frontmatter.
  surcharges: (:),
) = {
  let md_brut = read(_resoudre_chemin_depuis_racine(chemin_md))
  let (meta_brut, _) = cmarker.render-with-metadata(
    md_brut,
    metadata-block: "frontmatter-yaml",
    // Important: résoudre les images relativement au projet (pas au package cmarker).
    scope: (image: (source, alt: none, format: auto) => image(_resoudre_source_asset(source), alt: alt, format: format)),
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
