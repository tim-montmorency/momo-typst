// lib/paths.typ — helpers pour résoudre des chemins depuis la racine du projet
//
// Contexte: plusieurs modules vivent dans lib/* (ex: lib/md, lib/pages).
// Les appels `read(...)` / `image(...)` résolvent les chemins relativement au fichier
// qui exécute l'appel. Comme ces modules ne sont pas à la racine, on normalise
// les chemins "simples" (ex: "assets/cm_logo.png") vers "../../assets/cm_logo.png".

#let _est_chemin_deja_relatif_ou_absolu(s) = {
  s.starts-with("/") or s.starts-with("./") or s.starts-with("../")
}

#let _est_url(s) = {
  s.starts-with("http://") or s.starts-with("https://")
}

#let _resoudre_chemin_depuis_racine(chemin, prefix: "../../") = {
  let s = str(chemin)
  if _est_url(s) or _est_chemin_deja_relatif_ou_absolu(s) {
    s
  } else {
    prefix + s
  }
}

#let _joindre_base_et_relatif(base, rel) = {
  let b = str(base)
  let r = str(rel)
  let r2 = if r.starts-with("./") { r.slice(2) } else { r }
  if b.ends-with("/") {
    b + r2
  } else {
    b + "/" + r2
  }
}

#let _resoudre_source_asset(source, prefix: "../../", base_url: none) = {
  let s = str(source)
  if _est_url(s) {
    s
  } else if base_url != none {
    let b = str(base_url)
    if _est_url(b) {
      // Pour un Markdown distant, les liens relatifs (y compris ./ et ../)
      // doivent être résolus relativement au dossier du README distant.
      _joindre_base_et_relatif(b, s)
    } else {
      // Pour un Markdown local (ex: README téléchargé dans cache/*), les liens
      // relatifs doivent être résolus relativement au dossier du fichier.
      _resoudre_chemin_depuis_racine(_joindre_base_et_relatif(b, s), prefix: prefix)
    }
  } else {
    _resoudre_chemin_depuis_racine(s, prefix: prefix)
  }
}
