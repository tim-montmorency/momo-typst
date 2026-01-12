#import "lib.typ": plan_de_cours, charger_plan_de_cours_md_input

// Exemple: compile un plan de cours depuis un README GitHub téléchargé.
// 1) python3 scripts/fetch_github_plan.py <raw-url> cache/582-601
// 2) typst compile cours-582-601-mo-github.typ --input md=cache/582-601/plan.md
#let (params, corps) = charger_plan_de_cours_md_input(default: "cache/582-601/plan.md")

#show: plan_de_cours.with(..params)

#corps
