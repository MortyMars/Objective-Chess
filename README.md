Objective-Chess - Implémentation d'un Jeu d'Échec en Objective-C (Négamax Alpha Beta)
-------------------------------------------------------------------------------------

Ce fork est la reprise d'une implémentation attrayante du jeu d'échecs, présentant l'intérêt d'être une des rares écrites pour macOS en Objective-C, langage qui reste indéniablement élégant bien qu'aujourd'hui désuet.

Fonctionnalités apportées
-------------------------
Le développement de la présente version du jeu a consisté en l'ajout de fonctionnalités diverses.

Structurelles :
- Il est possible de jouer avec les Blancs ou avec les Noirs
- Un déroulé des coups joués, respectant la convention de nommage 'Notation algébrique réversible', s'affiche en continu
- Les situations de mise en échec du Roi, de Mat et de Pat, sont détectées et signalées par fenêtres de dialogue
- Le moteur de l'IA a été modifié pour le conformer aux pseudo-codes Négamax Alpha Bêta les plus utilisés, et le rendre plus performant
- La promotion du pion parvenant sur sa dernière rangée est gérée
- La possibilité de prise en passant accordée au pion est implémentée
- La fonction d'évaluation prend désormais en compte les positions d'échec et de mat potentiel ainsi que les pions menaçant d'une promotion
- Un diagramme de situation d'un échiquier, peut être chargé et visualisé dans l'interface via sa description au format FEN
- Possibilité à tout moment d'une partie, de changer de coté de jeu 
- Le niveau de jeu de l'IA peut être modifié tout au long de la partie
- La règle imposant de proposer la nullité d'une partie après 50 coups sans prise de pièce ou déplacement de pion est implémentée
- Il est possible de demander à l'IA de résoudre des diagrammes de situations de partie
- Le Joueur peut demander à l'IA de lui suggérer un (bon) coup

Cosmétiques :
- Le dessin des pièces a été modifié pour un résultat plus esthétique
- Les couleurs de l'échiquier ont été modifiées aux mêmes fins
- Un repérage des cases est mis en place, facilitant la lecture et la visualisation des coups
- La situation sur l'échiquier est évaluée au fil de la partie pour mettre en évidence un avantage se dégageant pour l'un ou l'autre des camps
- L'application est dotée d'un jeu d'icones
- Les menus sont personnalisés et enrichis
- Une 'barre d'état' reprenant l'évaluation du board, le trait, l'état du roque, celui de la cible e.p. et des compteurs, fait son apparition

Notes de mise à jour (02/2026)
------------------------------
- v0.9.0-beta : Version d'initialisation de la reprise du fork, fonctionnelle mais affectée par certains bugs
- v1.0.0-beta : Première version véritablement fonctionnelle, à la réserve que le programme joue juste réglementairement et assez mal
- v1.0.1-beta : Code nettoyé, méthodes renommées, certaines redécoupées, pour une meilleure lisibilité
- v1.0.2-beta : La promotion d'un pion parvenant sur sa dernière rangée est implémentée, la notation des coups est mise à jour en conséquence
- v1.0.3-beta : La prise en passant est à son tour gérée, avec mise à jour de la notation des coups
- v1.0.4-beta : Mise en place de tests unitaires, fix d'un bug lors de la détermination du meilleur coup IA, amélioration de la fonction d'évaluation
- v1.0.5-beta : L'évaluation tient compte d'un pion parvenant en avant-dernière rangée ; Negamax a été retouché
- v1.0.8-beta : Possibilité de charger un diagramme au format FEN - Possibilité de modifier à tout moment le niveau de jeu de l'IA - Ajout de menus et création d'une 'barre d'état'
- v1.0.9-beta : Possibilité de demander à l'IA de résoudre un diagramme de situation de partie
- v1.1.0-beta : Refactoring du moteur de jeu (Minimax, ChessBoard, RuleBook) pour de meilleures performances - Ajout de critères positionnels à la fonction d'évaluation
- v1.1.0 : Involutivité makeMove/unmakeMove acquise - Hachage Zobrist en place - Tables de transposition implémentées = Ces modifications concourent à une amélioration très significatives des performances du moteur
- v1.1.1 : Le Joueur peut demander à l'IA de lui suggérer un (bon) coup

Ce qui reste à faire (ma TODO list)
-----------------------------------
- Reprendre certains bugs mineurs ou pertes de fonctionnalités annexes, apparus lors du refactoring profond du moteur
- Améliorer la qualité de jeu de l'IA concernant les coups les plus immédiats et certains sacrifices inutiles
- Implémenter la possibilité d'enregistrer le déroulement d'une partie, board après board
