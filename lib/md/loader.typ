// lib/md/loader.typ — charge un plan de cours depuis Markdown (frontmatter + sections spécialisées)

#import "@preview/cmarker:0.1.8"

#import "core.typ": _retirer_frontmatter_yaml, _extraire_section_md_par_titres, _extraire_section_md_par_titres_niveau, _rendre_markdown
#import "sections_contexte.typ": section_contexte_apprentissage
#import "sections_materiel.typ": section_materiel_requis

#import "../data.typ": ids_personnes_par_noms
#import "../paths.typ": _est_url, _resoudre_chemin_depuis_racine, _resoudre_source_asset

#let _extraire_ligne_valeur_bullet(md, libelle) = {
  // Cherche une ligne Markdown du type: "- Libellé : valeur".
  // Retourne la valeur (string) ou none.
  let cible = lower(str(libelle)).replace("\u00A0", " ")
  for line in md.split("\n") {
    let t = line.trim().replace("\u00A0", " ")
    if t.starts-with("-") {
      let s = t.slice(1).trim()
      let parts = s.split(":")
      if parts.len() >= 2 {
        let k = lower(parts.at(0).trim())
        if k == cible {
          return parts.slice(1).join(":").trim()
        }
      }
    }
  }
  none
}

#let _split_noms_profs(s) = {
  // Accepte: "A et B", "A, B", "A et B et C".
  let x = str(s).replace("\u00A0", " ").trim()
  x = x.replace(" et ", ",")
  x = x.replace(" & ", ",")
  x = x.replace(";", ",")
  x.split(",").map(p => p.trim()).filter(p => p != "")
}

#let _retirer_entete_readme_si_redondant(md) = {
  // Retire le « bloc d'entête » typique d'un README GitHub:
  // image + H1 + liste de métadonnées (Numéro de cours, Pondération, Professeurs...).
  // On ne le fait que si on détecte des champs redondants.
  let lines = md.split("\n")
  let limit = if lines.len() < 80 { lines.len() } else { 80 }
  let debut = lines.slice(0, limit).join("\n")

  let redondant = (
    debut.contains("Numéro de cours") or
    debut.contains("Pondération") or
    debut.contains("Nombre d’heures") or
    debut.contains("Nombre d'heures") or
    debut.contains("Professeur") or
    debut.contains("Professeurs")
  )

  if not redondant { md }
  else {
    // Coupe jusqu'au premier heading niveau 2.
    let idx = range(0, lines.len())
      .filter(i => lines.at(i).trim().starts-with("## "))
      .at(0, default: none)

    if idx == none { md } else { lines.slice(idx).join("\n") }
  }
}

#let _normaliser_titres_heading(md) = {
  // Certains README exportés contiennent des headings cassés sur 2 lignes:
  // "##" puis "Titre". On recolle pour faciliter l'extraction.
  let lines = md.split("\n")
  let out = ""
  let first = true
  let i = 0
  while i < lines.len() {
    let a = lines.at(i).trim()
    if (a == "#" or a == "##" or a == "###" or a == "####") and i + 1 < lines.len() {
      let b = lines.at(i + 1).trim()
      if b != "" {
        let line = a + " " + b
        out = if first { first = false; line } else { out + "\n" + line }
        i += 2
        continue
      }
    }
    let line = lines.at(i)
    out = if first { first = false; line } else { out + "\n" + line }
    i += 1
  }
  out
}

#let _base_url_depuis_fichier(url) = {
  // Enlève le dernier segment (README.md) pour obtenir le dossier.
  let parts = str(url).split("/")
  if parts.len() <= 1 { str(url) } else { parts.slice(0, parts.len() - 1).join("/") }
}

#let _base_dir_depuis_fichier(chemin) = {
  // Ex: "cache/582/README.md" -> "cache/582".
  let s = str(chemin)
  if s.contains("/") {
    let parts = s.split("/")
    parts.slice(0, parts.len() - 1).join("/")
  } else {
    none
  }
}

#let charger_plan_de_cours_md(
  chemin_md,
  // Optionnel: forcer/compléter des valeurs au-dessus du frontmatter.
  surcharges: (:),
) = {
  let md_est_url = _est_url(str(chemin_md))
  if md_est_url {
    panic(
      "Chargement depuis URL non supporté directement par Typst (réseau désactivé). " +
      "Téléchargez d'abord le README et ses images, puis compilez le fichier local. " +
      "Voir scripts/fetch_github_plan.py."
    )
  }

  let md_base_dir = _base_dir_depuis_fichier(chemin_md)
  let md_brut = read(_resoudre_chemin_depuis_racine(chemin_md))
  let (meta_brut, _) = cmarker.render-with-metadata(
    md_brut,
    metadata-block: "frontmatter-yaml",
    // Important: résoudre les images relativement au projet (pas au package cmarker).
    scope: (
      image: (source, alt: none, format: auto) => image(
        _resoudre_source_asset(source, base_url: md_base_dir),
        alt: alt,
        format: format,
      ),

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
    if type(v) == str {
      let parts = v.split(",").map(p => p.trim()).filter(p => p != "")
      params = params + (plateformes: parts)
    }
  }

  // Applique les surcharges en dernier.
  params = params + surcharges

  // Auto-détection profs depuis le contenu Markdown (liste en tête de README)
  // si aucun champ prof/id_prof/ids_profs n'est fourni par le frontmatter.
  if params.at("ids_profs", default: none) == none and params.at("id_prof", default: none) == none and params.at("prof", default: none) == none {
    let val = _extraire_ligne_valeur_bullet(md_brut, "Professeurs")
    if val == none {
      val = _extraire_ligne_valeur_bullet(md_brut, "Professeur")
    }
    if val != none {
      let noms = _split_noms_profs(val)
      let ids = ids_personnes_par_noms(noms)
      if ids != none {
        if ids.len() == 1 {
          params = params + (id_prof: ids.at(0))
        } else {
          params = params + (ids_profs: ids)
        }
      } else {
        // Fallback: utiliser la chaîne telle quelle si pas de match botin.
        params = params + (prof: val)
      }
    }
  }

  // Rend le Markdown, en remplaçant certaines sections par des rendus dédiés.
  let md_sans_meta = _normaliser_titres_heading(_retirer_frontmatter_yaml(md_brut))

  // Présentation du cours: si on a `numero_cours`, la page 2 est la source de vérité
  // (data/cours.typ). On retire donc cette section du Markdown pour éviter la redondance.
  // Si on n'a pas `numero_cours`, on laisse la section en place et on désactive la page 2 auto.
  let a_numero_cours = params.at("numero_cours", default: none) != none
  let (avant_pres, sec_pres, apres_pres, _) = _extraire_section_md_par_titres(
    md_sans_meta,
    (
      "Présentation du cours",
      "PRÉSENTATION DU COURS",
    ),
  )
  if sec_pres != none {
    if a_numero_cours {
      md_sans_meta = avant_pres + "\n" + apres_pres
    } else {
      params = params + (inclure_presentation_du_cours: false)
    }
  }

  // Si le numéro de cours est connu, on enlève aussi l'entête README redondant
  // (image/H1 + liste de métadonnées) pour éviter un "page 3" qui répète la page 2.
  if a_numero_cours {
    md_sans_meta = _retirer_entete_readme_si_redondant(md_sans_meta)
  }

  let (a1, sec_contexte, reste1, _) = _extraire_section_md_par_titres(
    md_sans_meta,
    (
      "Contexte d’apprentissage et méthodes pédagogiques",
      "Contexte d'apprentissage et méthodes pédagogiques",
      "Contexte d’enseignement et méthodes pédagogiques",
      "Contexte d'enseignement et méthodes pédagogiques",
    ),
  )
  let (a2, sec_materiel, reste2, _) = _extraire_section_md_par_titres(
    reste1,
    (
      "Matériel requis",
      "Matériel et volumes requis",
      "Matériel, comptes et volumes requis",
      "Matériel et comptes requis",
    ),
  )

  // Auto-plateforme: si le matériel requis mentionne un compte GitHub,
  // on coche GitHub sur la couverture (plateforme pédagogique utilisée),
  // sauf si les plateformes ont été définies explicitement via le frontmatter.
  let github_mentionne_dans_materiel = if sec_materiel == none {
    false
  } else {
    let s = lower(str(sec_materiel)).replace("\u00A0", " ")
    // Tolère variantes: "Compte GitHub", "compte github", etc.
    s.contains("github") and (s.contains("compte") or s.contains("compte "))
  }

  let plateformes_configurees = (
    params.at("plateformes", default: none) != none or
    params.at("plateforme_teams", default: none) != none or
    params.at("plateforme_timdoc", default: none) != none or
    params.at("plateforme_github", default: none) != none or
    params.at("plateforme_autre", default: none) != none
  )

  if github_mentionne_dans_materiel and not plateformes_configurees {
    params = params + (plateforme_github: true)
  }

  let corps = []
  if a1 != none and str(a1).trim() != "" { corps = corps + _rendre_markdown(a1, base_url: md_base_dir) }
  if sec_contexte != none {
    if corps != [] { corps = corps + v(0.6em) }
    corps = corps + section_contexte_apprentissage(sec_contexte)
    corps = corps + v(0.6em)
  }
  if a2 != none and str(a2).trim() != "" { corps = corps + _rendre_markdown(a2, base_url: md_base_dir) }
  if sec_materiel != none {
    if corps != [] { corps = corps + v(0.6em) }
    corps = corps + section_materiel_requis(sec_materiel)
    corps = corps + v(0.6em)
  }

  // Plus de traitement spécial pour "Évaluations sommatives": on laisse passer
  // le contenu tel quel et on le rend via le moteur Markdown.
  if reste2 != none and str(reste2).trim() != "" { corps = corps + _rendre_markdown(reste2, base_url: md_base_dir) }

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
