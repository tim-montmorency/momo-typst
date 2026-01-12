// lib/data.typ — accès aux sources de vérité (data/*.typ)

#import "../data/cours.typ": cours
#import "../data/botin.typ": personnes
#import "../data/bureaux.typ": bureaux

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
