// lib.typ — façade stable du gabarit (API publique)
//
// Usage (dans un .typ à la racine du dépôt):
//   #import "lib.typ": plan_de_cours, charger_plan_de_cours_md
//   #show: plan_de_cours.with(...)
//   Votre contenu...

// API publique du gabarit
#import "lib/plan.typ": plan_de_cours, syllabus

// API publique Markdown-first
#import "lib/md/loader.typ": charger_plan_de_cours_md, charger_plan_de_cours_md_input
