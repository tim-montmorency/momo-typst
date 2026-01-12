// lib/paths.typ — helpers pour résoudre des chemins depuis la racine du projet
//
// Contexte: plusieurs modules vivent dans lib/* (ex: lib/md, lib/pages).
// Les appels `read(...)` / `image(...)` résolvent les chemins relativement au fichier
// qui exécute l'appel. Comme ces modules ne sont pas à la racine, on normalise
// les chemins "simples" (ex: "cm_logo.png") vers "../../cm_logo.png".

#let _est_chemin_deja_relatif_ou_absolu(s) = {
  s.starts-with("/") or s.starts-with("./") or s.starts-with("../")
}

#let _est_url(s) = {
  s.starts-with("http://") or s.starts-with("https://")
}

#let _resoudre_chemin_depuis_racine(chemin, prefix: "../../") = {
  let s = str(chemin)
  if _est_chemin_deja_relatif_ou_absolu(s) {
    s
  } else {
    prefix + s
  }
}

#let _resoudre_source_asset(source, prefix: "../../") = {
  let s = str(source)
  if _est_url(s) {
    s
  } else {
    _resoudre_chemin_depuis_racine(s, prefix: prefix)
  }
}
