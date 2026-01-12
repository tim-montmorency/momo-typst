#import "lib.typ": plan_de_cours, charger_plan_de_cours_md_input

#let (params, corps) = charger_plan_de_cours_md_input()

#show: plan_de_cours.with(..params)

#corps
