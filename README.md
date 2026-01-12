# momo-Typst

Gabarits Typst partagés pour une équipe d’enseignant·e·s.
L’objectif: garder une mise en page uniforme (marges, titres, en-tête, pagination) tout en laissant chaque personne remplir le contenu.

## Structure

- `lib.typ` : façade stable (API publique) à importer dans tous les documents
- `lib/` : implémentation atomisée (pages, markdown, utilitaires)
- `data/cours.typ` : métadonnées de cours (heures, pondération, titre…) — source de vérité via `numero_cours`
- `data/botin.typ` : botin des personnes (nom, courriel, bureau…) — source de vérité via `id_prof` / `ids_profs`
- `data/bureaux.typ` : répertoire des bureaux (pour éviter la redondance quand un bureau est partagé)
- `syllabus.typ` : exemple de plan de cours (syllabus) qui compile directement

## Prérequis

Installer Typst



## Utilisation

### Compiler l’exemple de syllabus

Depuis la racine du dépôt:

- Compilation PDF: `typst compile syllabus.typ`
- Mode watch: `typst watch syllabus.typ`

Le logo par défaut est `cm_logo.png` à la racine. Remplacez le fichier si nécessaire.

### Prévisualiser un cours (VS Code)

Ouvrez un fichier `cours-*.typ` (ex: `cours-582-501-mo.typ`).

- `numero_cours` alimente automatiquement la page couverture à partir de `data/cours.typ`
- `id_prof` alimente `prof / courriel / bureau` à partir de `data/botin.typ` (et les bureaux partagés via `data/bureaux.typ`)

### Écrire le contenu en Markdown

Le modèle recommandé est:

- un fichier `.typ` très mince (point d’entrée) qui ne fait que charger le Markdown;
- un fichier `.md` du même nom qui contient:
  - un frontmatter YAML (les champs du gabarit), puis
  - le contenu du plan de cours en Markdown.

Exemple: [cours-582-611-mo.typ](cours-582-611-mo.typ) charge [cours-582-611-mo.md](cours-582-611-mo.md).

Le rendu Markdown utilise le package `cmarker` (CommonMark) et le frontmatter YAML est lu automatiquement au début du fichier.

#### Option: un seul wrapper `.typ` pour tous les cours

Typst n’expose pas directement le nom/chemin du fichier `.typ` courant, donc on ne peut pas déduire automatiquement `mon-fichier.md` à partir de `mon-fichier.typ`.

À la place, vous pouvez utiliser la fonction `charger_plan_de_cours_md_input(...)` (dans `lib.typ`) pour lire le chemin du Markdown via `--input md=...`.

Exemple de wrapper minimal:

```typst
#import "lib.typ": plan_de_cours, charger_plan_de_cours_md_input

#let (params, corps) = charger_plan_de_cours_md_input()
#show: plan_de_cours.with(..params)
#corps
```

- Exemple:
  - `typst compile --input md=cours-582-611-mo.md cours-md.typ cours-582-611-mo.pdf`

Note: si vous utilisez cet exemple, créez votre propre `cours-md.typ` à la racine du dépôt.

### Évaluations sommatives (tableau)

Le gabarit transforme automatiquement la sous-section Markdown `### Évaluations sommatives` (dans la section `## Évaluation des apprentissages`) en tableau (comme sur la capture d’écran), à partir d’une structure en listes.

Format attendu:

```markdown
### Évaluations sommatives

#### Nom de l’évaluation

- Description
  - Texte libre (1+ lignes)
- Type
  - Individuel
  - Équipe
- Critères
  - Critère 1
  - Critère 2
- Échéance
  - Séance 3
- Pondération
  - 20 %
```

Notes:

- Les blocs `#### ...` deviennent des lignes du tableau.
- `Type` coche automatiquement `Individuel` / `Équipe` selon les valeurs présentes.
- Le tableau répète son en-tête si il se poursuit sur une page suivante et une évaluation n’est pas coupée entre deux pages.

### Plateformes pédagogiques

API recommandée:

```typst
#show: plan_de_cours.with(
  numero_cours: "582 611 MO",
  session: [Hiver 2026],
  ids_profs: ("prenom-nom", "autre-personne"),
  plateformes: ("Teams", "GitHub", "Moodle"),
)
```

- Si une plateforme n’est pas dans la liste connue du gabarit (Teams/Timdoc/GitHub), elle est automatiquement ajoutée comme nouvelle case à cocher.
- Pour une seule plateforme, utilisez un tuple à 1 élément: `plateformes: ("Teams",)`.
- Compatibilité: vous pouvez encore utiliser `plateforme_teams`, `plateforme_timdoc`, `plateforme_github`, `plateforme_autre` si `plateformes` n’est pas fourni.

### Créer un nouveau document enseignant

1. Créez un fichier `.typ` (ex: `mon-doc.typ`)
2. Importez le template:

```typst
#import "lib.typ": plan_de_cours

#show: plan_de_cours.with(
  titre: [Titre du document],
  numero_cours: "582 501 MO",
  session: [Hiver 2026],
  id_prof: "prenom-nom",
)

= Première section
Votre contenu…
```

### Configurer le botin (courriel, bureau)

Modifiez `data/botin.typ` et ajoutez une entrée par personne.
Ensuite, utilisez `id_prof` dans vos documents.

Pour plusieurs profs dans un même plan de cours, utilisez `ids_profs`:

```typst
#show: plan_de_cours.with(
  numero_cours: "582 501 MO",
  session: [Hiver 2026],
  ids_profs: ("prenom-nom", "autre-personne"),
)
```

## Conventions

- Modifiez le style global dans `lib.typ` (pas dans chaque document).
- Gardez les documents individuels centrés sur le contenu: titres, listes, tableaux.
