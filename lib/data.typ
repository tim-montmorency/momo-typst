// lib/data.typ — accès aux sources de vérité (data/*.typ)

#import "../data/cours.typ": cours
#import "../data/botin.typ": personnes
#import "../data/bureaux.typ": bureaux

#let _normaliser_nom_personne(s) = {
  // Normalisation simple pour matcher des noms provenant du Markdown.
  // - minuscules
  // - supprime ponctuation courante (.,’,' )
  // - remplace tirets par espaces
  // - compacte les espaces
  let x = lower(str(s))
  x = x.replace("\u00A0", " ")
  x = x.replace(".", "")
  x = x.replace("’", "")
  x = x.replace("'", "")
  x = x.replace("‑", " ")
  x = x.replace("-", " ")
  x = x.replace("  ", " ")
  x = x.replace("  ", " ")
  x.trim()
}

#let id_personne_par_nom(nom) = {
  let cible = _normaliser_nom_personne(nom)
  for id in personnes.keys() {
    let p = personnes.at(id)
    let n = p.at("nom", default: none)
    if n != none and _normaliser_nom_personne(n) == cible {
      return id
    }
  }
  none
}

#let ids_personnes_par_noms(noms) = {
  // Retourne seulement les IDs trouvés, dans le même ordre.
  let ids = ()
  for nom in noms {
    let id = id_personne_par_nom(nom)
    if id != none {
      ids = ids + (id,)
    }
  }
  if ids == () { none } else { ids }
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

#let _exiger_bureau(id_bureau) = {
  let meta = bureau_par_id(id_bureau)
  if meta == none {
    panic("Bureau inconnu: " + id_bureau + ". Ajoutez-le à data/bureaux.typ.")
  }
  meta
}
