// data/botin.typ — répertoire (botin) des personnes.
//
// Objectif: centraliser les infos de contact (courriel, bureau, etc.)
// pour éviter de les répéter dans chaque plan de cours.
//
// NOTE: En Typst, `@` est spécial; dans du texte markup, écrivez `\@`.

#let personnes = (
  // Exemples (cas tests) — noms avec accents et caractères spéciaux.
  // NOTE: les IDs doivent être stables et simples (ASCII), les noms peuvent contenir des accents.
  "guillaume-arseneault": (
    nom: "Guillaume Arseneault",
    courriel: "guillaume.arseneault@college.example",
    bureau_id: "c-1651",
  ),
  "thomas-o-fredericks": (
    nom: "Thomas O. Fredericks",
    courriel: "thomas.ofredericks@college.example",
    bureau_id: "c-1651",
  ),
  // Deux profs partagent le même bureau (ne doit s’afficher qu’une seule fois).
  "marie-soleil-bouchard": (
    nom: "Marie-Soleil Bouchard",
    courriel: "marie-soleil.bouchard@college.example",
    bureau_id: "c-1651",
  ),
  "etienne-duchesne": (
    nom: "Étienne Duchesne",
    courriel: "etienne.duchesne@college.example",
    bureau_id: "c-1651",
  ),

  // Deux profs avec bureaux différents (les deux bureaux doivent être visibles).
  "chloe-d-aoust": (
    nom: "Chloë d’Aoust",
    courriel: "chloe.daoust@college.example",
    bureau_id: "c-1652",
  ),
  "francois-xavier-ouellet": (
    nom: "François‑Xavier Ouellet",
    courriel: "fx.ouellet@college.example",
    bureau_id: "c-1653",
  ),

  // Un autre cas test avec diacritiques variés.
  "soren-nunez": (
    nom: "Søren Núñez",
    courriel: "soren.nunez@college.example",
    bureau_id: "c-1652",
  ),
)
