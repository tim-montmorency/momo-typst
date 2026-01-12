// data/cours.typ — source de vérité des cours.
//
// Clé: numéro/code unique (ex: "582 501 MO").
// Valeur: dictionnaire des champs utilisés par le gabarit.
//
// Champs optionnels utilisés pour la page 2 "PRÉSENTATION DU COURS":
// - description_du_cours: string (peut contenir des paragraphes via lignes vides)
// - objectif_integrateur: string
// - competences_ministerielles: liste/tuple de strings (ex: "015F ...")
// - objectifs_apprentissage: liste/tuple de strings
// - cours_lies: dictionnaire avec:
//     - prealables_absolus: liste/tuple de strings
//     - prealables_relatifs: liste/tuple de strings
//     - corequis: liste/tuple de strings
//   (on pourra ajouter plus tard relatifs/corequis au besoin)
//
// NOTE: En Typst, `@` est spécial; dans du texte markup, écrivez `\@`.

#let cours = (
  // Exemple (à remplacer)
  "TIM-000": (
    numero: "TIM-000",
    titre: "Nom complet du cours",
    heures: "Sélectionnez le nombre d’heures",
    ponderation: "Sélectionnez la pondération",
  ),

  // --- Extrait de grille (exemples) ---
  // Session 5
  "582 501 MO": (
    numero: "582 501 MO",
    titre: "Conception d’une expérience multimédia",
    ponderation: "3-3-2",
    // Heures d’enseignement par semaine (cours + labo) dérivées de la pondération.
    heures: "6 h/semaine (3 + 3)",
    unites: [2 2/3],
    prealables: [PA : 570 V11 MO, 582 401 MO, 582 412 MO, 582 414 MO, 582 431 MO],
    corequis: [CR : 582 521 MO, 582 531 MO],
    session: 5,
  ),
  "582 511 MO": (
    numero: "582 511 MO",
    titre: "Web 5",
    ponderation: "3-5-3",
    heures: "8 h/semaine (3 + 5)",
    unites: [3 2/3],
    prealables: [PA : 582 411 MO],
    session: 5,
  ),
  "582 521 MO": (
    numero: "582 521 MO",
    titre: "Installation multimédia",
    ponderation: "2-2-2",
    heures: "4 h/semaine (2 + 2)",
    unites: [2],
    prealables: [PA : 582 412 MO],
    session: 5,
  ),
  "582 531 MO": (
    numero: "582 531 MO",
    titre: "Objets interactifs",
    ponderation: "2-2-2",
    heures: "4 h/semaine (2 + 2)",
    unites: [2],
    prealables: [PA : 582 431 MO],
    session: 5,
  ),
  "582 541 MO": (
    numero: "582 541 MO",
    titre: "Préparation au milieu de travail",
    ponderation: "2-2-1",
    heures: "4 h/semaine (2 + 2)",
    unites: [1 2/3],
    prealables: [PA : tous les cours de la formation spécifique des sessions 1 à 4],
    corequis: [CR : 582 501 MO, 582 511 MO],
    session: 5,
  ),

  // Session 6
  "582 601 MO": (
    numero: "582 601 MO",
    titre: "Expérience multimédia",
    ponderation: "1-10-12",
    heures: "11 h/semaine (1 + 10)",
    unites: [7 2/3],
    prealables: [PA : 582 501 MO, 582 521 MO],
    session: 6,

    // --- Page 2: PRÉSENTATION DU COURS ---
    description_du_cours: "Ce cours vise la réalisation d’un projet multimédia en équipe tel  qu’une installation interactive ou une expérience de réalité mixte.\nL’élève collabore à l’élaboration d’un projet multimédia interactif,  et ce, de la conception jusqu’à la présentation du produit.\nIl a  l’occasion de mettre en pratique toutes les compétences acquises  au cours de sa formation technique.",
    objectif_integrateur: "Réaliser une expérience multimédia interactive.",
    competences_ministerielles: (
      "015U Réaliser un produit multimédia sur support (éléments 1 à 11).",
    ),
    objectifs_apprentissage: (
      "Planifier la réalisation de l’expérience multimédia.",
      "Programmer l’expérience multimédia.",
      "Contrôler la qualité de l’expérience multimédia.",
      "Présenter l’expérience multimédia.",
    ),
    cours_lies: (
      prealables_absolus: (
        "582 501 MO Conception d’une expérience multimédia",
        "582 521 MO Installation multimédia",
      ),
      prealables_relatifs: (),
      corequis: (),
    ),
  ),
  "582 611 MO": (
    numero: "582 611 MO",
    titre: "Stage en entreprise",
    ponderation: "1-15-6",
    heures: "16 h/semaine (1 + 15)",
    unites: [7 1/3],
    prealables: [PA : tous les cours de la formation spécifique de la session 5],
    corequis: [CR : 582 601 MO],
    session: 6,
  ),

  "582 999 MO": (
    numero: "582 999 MO",
    titre: "Création multimédia",
    ponderation: "3-3-2",
    // Heures d’enseignement par semaine (cours + labo) dérivées de la pondération.
    heures: "60h",
    unites: [2 2/3],
    prealables: [PA : 570 V11 MO, 582 401 MO, 582 412 MO, 582 414 MO, 582 431 MO],
    corequis: [CR : 582 521 MO, 582 531 MO],
    session: 5,
    description_du_cours: "Ce cours intensif de création multimédia permet aux étudiants de mettre en pratique les compétences acquises au cours de leur formation en réalisant un projet complet de A à Z. Encadrés par des professionnels du domaine, les étudiants travaillent en équipe pour concevoir, développer et présenter une œuvre multimédia innovante, intégrant des éléments visuels, sonores et interactifs. Ce cours vise à renforcer la créativité, la collaboration et les compétences techniques des étudiants, tout en les préparant aux défis du milieu professionnel.",
    objectif_integrateur: "Réaliser un projet multimédia complet en équipe, de la conception à la présentation, en intégrant des éléments visuels, sonores et interactifs.",
    competences_ministerielles: (
      "099X Appliquer les principes de conception multimédia pour créer des œuvres innovantes.",
      "010X Collaborer efficacement au sein d'une équipe multidisciplinaire.",
      "023X Utiliser des outils et technologies avancés pour le développement multimédia.",
      "0292 Gérer un projet de création multimédia du début à la fin, en respectant les délais et les exigences techniques.",
    ),
    objectifs_apprentissage: (
      "Intégrer des médias visuels et sonores dans une expérience ludique.",
      "Programmer des actions interactives qu’un utilisateur doit accomplir pour progresser.",
    ),
    cours_lies: (
      prealables_absolus: (
        "420 V11 MO Programmation interactive",
      ),
      // Exemple: aucun préalable relatif
      prealables_relatifs: (),
      corequis: (
        "582 521 MO Installation multimédia",
        "582 531 MO Objets interactifs",
      ),
    ),
  ),
)
