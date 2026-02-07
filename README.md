Objective-Chess - Implémentation du Jeu d'Échec en Objective-C - IA Négamax Alpha Bêta
--------------------------------------------------------------------------------------

Commentaires et avis personnels
-------------------------------
Ce fork est la reprise d'une implémentation attrayante du jeu d'échecs (repo original qema/chess), présentant l'intérêt d'être une des rares à être écrite pour macOS en Objective-C, qui reste un langage indéniablement élégant bien qu'aujourd'hui désuet.

Fonctionnalités apportées
-------------------------
Par rapport au repo original, le développement de la présente version a consisté -chronologiquement- en l'apport de certaines améliorations ou fonctionnalités.

Structurelles :
- Il est possible de choisir de jouer avec les Blancs ou avec les Noirs
- Un déroulé historique des coups joués, respectant la convention de nommage 'Notation algébrique réversible', s'affiche en continu
- Les situations de mise en échec du Roi, de Mat et de Pat, sont détectées et sont signalées par fenêtres de dialogue
- Le moteur de l'IA a été retravaillé à différentes reprises pour le conformer aux pseudo-codes Négamax Alpha Bêta les plus utilisés, et pour le rendre plus performant
- La promotion du pion parvenant sur sa dernière rangée est pleinement gérée
- La possibilité de prise en passant accordée au pion est également implémentée
- Le moteur de l'IA est nettoyé d'un bug récurrent et fugitif présent depuis les toutes premières versions
- La fonction d'évaluation, outre l'avantage matériel, prend désormais en compte les positions d'échec et de mat potentiel ainsi que les pions menaçant d'une promotion
- Tout diagramme d'une situation d'un échiquier, peut être chargé et visualisé dans l'interface via sa description au format FEN
- Possibilité à tout moment d'une partie, de changer de coté de jeu 
- Le niveau de jeu de l'IA peut être modifié tout au long de la partie
- La règle imposant de proposer la nullité d'une partie après 50 coups sans prise de pièce ou déplacement de pion est implémentée
- Il est possible de demander à l'IA de résoudre des diagrammes de situations de partie

Cosmétiques :
- Le dessin des pièces a été retouché, puis remplacé, pour un résultat plus esthétique à mon goût, ...mais ça n'engage que moi ;-)
- Les couleurs de l'échiquier lui-même ont été modifiées aux mêmes fins et avec les mêmes réserves ;-))
- Un repérage des cases est mis en place, facilitant la lecture et la visualisation des coups,
- La situation sur l'échiquier est évaluée au fil de la partie pour mettre en évidence un avantage se dégageant pour l'une ou l'autre des couleurs,
- L'application est dotée d'un jeu d'icones.
- Les menus de l'application sont personnalisés et enrichis
- Une 'barre d'état' -reprenant l'évaluation du board, le trait, l'état du roque, celui de la cible e.p. et des compteurs- fait son apparition

Notes de mise à jour (02/2026)
------------------------------
- v0.9.0-beta : version de présentation du projet, quasi fonctionnelle mais encore affectée par certains dysfonctionnements récurrents
- v1.0.0-beta : première version véritablement fonctionnelle, à la réserve que le programme joue tout juste réglementairement mais assez mal ;-)
- v1.0.1-beta : code nettoyé, méthodes renommées, certaines redécoupées, pour une meilleure lisibilité ; mais il reste du boulot...
- v1.0.2-beta : la promotion d'un pion parvenant sur sa dernière rangée est implémentée, la notation des coups est mise à jour en conséquence
- v1.0.3-beta : la prise en passant est à son tour gérée, y compris la mise à jour en conséquence de la notation des coups
- v1.0.4-beta : mise en place de tests unitaires pour le projet, levée d'un bug récurrent pendant la détermination du meilleur coup IA, amélioration de la fonction d'évaluation ; l'IA joue de ce fait globalement mieux
- v1.0.5-beta : la fonction d'évaluation tient désormais compte du danger présenté par un pion parvenant en avant-dernière rangée ; Negamax a été retouché ; le dessin des pièces est une nouvelle fois modifié
- v1.0.8-beta : possibilité de charger un diagramme au format FEN ; possibilité de modifier à tout moment le niveau de jeu de l'IA ; interface revue pour intégrer ces nouvelles fonctionnalités : ajout de menus et création d'une 'barre d'état'
- v1.0.9-beta : possibilité de demander à l'IA de résoudre un diagramme de situation de partie
- v1.1.0-beta : refactoring du moteur de jeu (Minimax, ChessBoard, RuleBook) pour de meilleures performances ; amélioration sensible de la fonction d'évaluation qui ajoute désormais aux calculs matériels des critères positionnels

Ce qui reste à faire (ma TODO list)
-----------------------------------
Nécessairement :
- Améliorer encore les temps de réponse de l'IA, dans la lignée des progrés sensibles déjà faits
- Améliorer la qualité de jeu de l'IA concernant les bons coups les plus immédiats et certains sacrifices inutiles
- Implémenter la possibilité d'enregistrer le déroulement d'une partie, board après board

Potentiellement :
- Offrir au Joueur la possibilité de se voir proposer un prochain bon coup
