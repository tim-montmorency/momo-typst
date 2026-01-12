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

### Recommandé: installer via Nix

Le dépôt inclut un environnement Nix épinglé (Typst + Python) pour que tout le monde compile avec les mêmes versions.

1) Installez Nix

- macOS / Linux (recommandé): utilisez l’installateur Determinate Systems (simple et fiable)
  - https://determinate.systems/nix/

2) Entrez dans l’environnement du dépôt (inclut `typst`)

- `nix develop`

Ensuite, `typst` est disponible dans votre shell.

### Alternative (si vous ne voulez pas Nix)

Installer Typst manuellement, puis assurez-vous d’avoir aussi `python3` pour le script de cache.

Pour assurer une typographie identique sur toutes les machines, le dépôt inclut les polices dans `fonts/`.
Compilez avec:

- `typst compile --font-path fonts <fichier>.typ`
- `typst watch --font-path fonts <fichier>.typ`



## Utilisation

### Entrypoints (scripts du dépôt)

Ces scripts sont utilisés localement et en CI (rien de spécifique à GitHub dans la logique):

- Préparer le dépôt (télécharger/mettre à jour le cache): `./scripts/prepare_repo.sh`
- Compiler des PDFs de référence: `./scripts/build_repo.sh`
- Pipeline complet (prepare + build): `./scripts/ci.sh`
- Générer un site GitHub Pages (HTML + PDFs): `./scripts/build_pages.sh`

### Nix (environnement reproductible)

Si vous utilisez Nix, vous pouvez exécuter la CI locale dans un environnement épinglé:

- `nix develop -c ./scripts/ci.sh`

### Compiler l’exemple (cours-582-999)

Depuis la racine du dépôt:

- Compilation PDF: `typst compile --font-path fonts cours-582-999-mo.typ`
- Mode watch: `typst watch --font-path fonts cours-582-999-mo.typ`

Le logo par défaut est `cm_logo.png` à la racine. Remplacez le fichier si nécessaire.

### Prévisualiser un cours (VS Code)

Ouvrez un fichier `cours-*.typ` (ex: `cours-582-501-mo.typ`).

La prévisualisation (Tinymist) est configurée pour utiliser les polices du dépôt via `.vscode/settings.json` (font paths + désactivation des polices système pour un rendu reproductible).

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
  - `typst compile --font-path fonts --input md=cours-582-611-mo.md cours-md.typ cours-582-611-mo.pdf`

Note: si vous utilisez cet exemple, créez votre propre `cours-md.typ` à la racine du dépôt.

#### Option: plan de cours hébergé dans un README GitHub

Typst (dans ce repo) ne télécharge pas directement du contenu HTTP(S) pendant la compilation.
Le workflow recommandé est donc:

```sh
python3 scripts/fetch_github_plan.py \
  "https://raw.githubusercontent.com/<org>/<repo>/refs/heads/<branch>/README.md" \
  cache/mon-cours

typst compile --font-path fonts cours-md.typ --input md=cache/mon-cours/plan.md
```

Pour automatiser le caching de plusieurs cours, ajoutez les URLs dans `cache/sources.json` puis exécutez:

```sh
python3 scripts/fetch_github_plan.py --sources-file cache/sources.json
```

Notes:

- Le script génère `cache/<cours>/plan.md` (un wrapper Markdown avec frontmatter YAML, ex: `numero_cours`).
- Il génère aussi `cache/<cours>/cours_data.snippet.typ` pour copier/coller les champs de page 2 dans `data/cours.typ`.

Un exemple prêt à compiler est fourni dans `cours-582-601-mo-github.typ` (utilise `--input md=...`).

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
