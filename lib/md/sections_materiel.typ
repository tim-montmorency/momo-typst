// lib/md/sections_materiel.typ — section Matériel requis

#import "sections_contexte.typ": _rendre_liste_cases_corps

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
