#import "lib.typ": plan_de_cours, charger_plan_de_cours_md

#let (params, corps) = charger_plan_de_cours_md("cours-582-999-mo.md")

#show: plan_de_cours.with(..params)

#corps
