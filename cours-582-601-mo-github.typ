// Exemple: plan de cours hébergé dans un README GitHub (via cache local).
// 1) Ajoutez une entrée dans cache/sources.json
// 2) Exécutez ./scripts/prepare_repo.sh
// 3) Compilez ce fichier (ou ouvrez un cours-*.generated.typ pour preview)

#import "lib.typ": plan_de_cours, charger_plan_de_cours_md_input

// Exemple: compile un plan de cours depuis un README GitHub téléchargé.
// 1) python3 scripts/fetch_github_plan.py <raw-url> cache/582-601
// 2) typst compile cours-582-601-mo-github.typ --input md=cache/582-601/plan.md
#let (params, corps) = charger_plan_de_cours_md_input(default: "cache/2026/hiver/582-601-mo/plan.md")

#show: plan_de_cours.with(..params)

#corps
