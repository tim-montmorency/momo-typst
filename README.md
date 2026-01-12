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
- Nettoyer les entrypoints générés (prévisualisation): `./scripts/clean_generated.sh`
- Compiler des PDFs de référence: `./scripts/build_repo.sh`
- Pipeline complet (prepare + build): `./scripts/ci.sh`
- Générer un site GitHub Pages (HTML + PDFs): `./scripts/build_pages.sh`

Note: `./scripts/prepare_repo.sh` génère aussi des fichiers `.typ` (non versionnés) afin de pouvoir prévisualiser chaque cours directement dans VS Code (Tinymist) sans passer par `--input`.

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

#### Option recommandée (preview): entrypoints `.typ` générés

Après `./scripts/prepare_repo.sh`, un fichier par cours est généré à la racine, ex:

- `cours-2026-hiver-582-601-mo.generated.typ`

Vous pouvez ouvrir ce fichier dans VS Code et utiliser la prévisualisation Tinymist.

Ces fichiers sont générés automatiquement à partir de `cache/sources.json` et sont ignorés par Git.

Pour repartir de zéro (côté “root”), vous pouvez faire:

```sh
./scripts/clean_generated.sh
./scripts/prepare_repo.sh
```

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

##### Comment les profs ajoutent leur plan (recommandé)

Chaque prof héberge son plan de cours en **Markdown** dans son propre dépôt (généralement un `README.md`).
Ensuite, il suffit d’ajouter une entrée dans `cache/sources.json`.

Champs à remplir (et seulement ceux-là):

- `id`: identifiant du cours, ex: `582-601-mo`
- `annee`: année de référence (ex: `2026`)
- `readme_url`: URL raw du README, ex: `https://raw.githubusercontent.com/<org>/<repo>/refs/heads/<branch>/README.md`

##### Format de `id` (corrélation)

L’`id` est l’identifiant unique d’un cours dans ce dépôt. Il sert à dériver:

- le semestre (`automne` / `hiver`),
- l’emplacement du cache (où `plan.md` est écrit),
- le nom et le chemin du PDF généré pour Pages.

Formats acceptés:

- `582-601` (suffixe implicite)
- `582-601-mo` (suffixe explicite)

Exemple pour `id = 582-601-mo`, `annee = 2026`:

- Cache: `cache/2026/hiver/582-601-mo/plan.md`
- PDF Pages: `docs/2026/hiver/582-601-mo.pdf`

Le reste est **généré automatiquement**:

- `out_dir` (dossier de cache) est dérivé de `annee` + semestre + `id`
- `numero_cours` (frontmatter) est dérivé de `id` (par défaut suffixe `MO` si absent)

##### Semestre (automne / hiver)

Le semestre est dérivé automatiquement à partir de l’`id` du cours:

- On prend le **4e chiffre** de l’identifiant numérique du cours.
- S’il est **impair** → `automne`
- S’il est **pair** → `hiver`

Exemple: `582-601` → chiffres `582601` → 4e chiffre = `6` (pair) → `hiver`.

##### Structure du cache

Le cache est rangé ainsi:

- `cache/<annee>/<automne|hiver>/<id>/plan.md`

Notes:

- Le script génère `cache/<annee>/<automne|hiver>/<id>/plan.md` (un wrapper Markdown avec frontmatter YAML, ex: `numero_cours`).
- Il génère aussi `cache/<annee>/<automne|hiver>/<id>/cours_data.snippet.typ` pour copier/coller les champs de page 2 dans `data/cours.typ`.

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

Le botin supporte aussi un champ optionnel `departement` (département de la professeure ou du professeur).
S’il n’est pas fourni, la valeur par défaut est `Techniques d’intégration multimédia`.

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
