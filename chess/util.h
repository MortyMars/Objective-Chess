//  Util.h
//  chess
//  Created by Andrew Wang on 15/07/2013,
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

/* MCN - Macro permettant de supprimer les indications Date, Heure, Appli, ... des messages NSLog */
#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


/* "PieceType" définit -via une énum- un nouveau type de données pour les pièces du jeu.
(pour le coup il s'agit du type de pièce : pion, tour, cavalier, fou, dame, roi)

La succession des pièces dans l'énumération n'est pas anodine.
En effet, chacune recevra l'indice de sa position lorsqu'il s'agira de lui attribuer une représentation en
ligne de commande, et notamment lorsqu'on voudra afficher l'échiquier sous forme de matrice simplifiée.
Sachant que le premier type dans l'énum porte l'indice 0, que le deuxième porte l'indice 1 et ainsi de suite,
on déduit de l'ordre fixé dans l'énum, qu'une pièce invalide ou l'absence de pièce sera représentée par '0'
un pion '1', un cavalier '2', un fou '3', une tour '4', une dame '5', et un roi '6' d'où la matrice de départ
de partie (les blancs sont en bas) :

           4 2 3 5 6 3 2 4
           1 1 1 1 1 1 1 1
           0 0 0 0 0 0 0 0
           0 0 0 0 0 0 0 0
           0 0 0 0 0 0 0 0
           0 0 0 0 0 0 0 0
           1 1 1 1 1 1 1 1
           4 2 3 5 6 3 2 4                   */

typedef enum {Invalide, Pion, Cava, Fou,
              Tour, Dame, Roi} PieceType;


/* "Side" définit -via une énum- un nouveau type pour les couleurs en présence.
Chaque 'Side' ici défini prend la valeur de son indice dans l'enum
Ainsi on peut écrire que sideInvalid = 0, sideBlack = 1, et sideWhite = 2, mais il est beaucoup
plus efficace dans le code d'utiliser leur mnémonique plutôt que leur valeur intrinsèque */
typedef enum {sideInvalid, sideBlack, sideWhite} Side;


/* Modif. MCN - Ajout de variables globales (pardon aux puristes défenseurs du code)
Chacune de ces variables ont des implantations dans le code de plusieurs Classes
Il n'a donc pas été possible de les déclarer comme variables d'instance, ce qui
aurait été plus élégant. Certaines autres variables à portée plus limitée ont par contre
pu être définies comme telles dans la classe qu'elles concerne exclusivement.
NB : extern supporte les variables mais aussi les fonctions (et méthodes ?) sous la forme
par exemple de : 'extern void MaFonction(NSString *param1, int param2)' */

extern Side sideCourant;
extern Side sideJoueur;
extern Side sideIA;

extern NSString* stringCoupsPartie;
extern NSString* stringDebugging;

extern BOOL petitRoque;    // petit roque exécuté
extern BOOL grandRoque;    // grand roque exécuté
extern BOOL stopMatOuPat;  // Mat ou Pat détecté
extern BOOL enPassant;     // prise en passant exécutée

extern int checkCount;     /* Nbre de mises en échec simultanées subies par un Roi
                           Nécessaire du point de vue de la notation + ou ++ mais également potentiellement
                           utile du point de vue performance puisqu'un Roi en position de double échec doit
                           impérativement bouger (impossible de couvrir deux lignes d'échec en un seul coup),
                           ce qui limite la recherche du prochain coup ; mais ça reste à implémenter... */

extern int evalDisplay;      /* Valeur d'évaluation d'un Board, signée conformément à la convention */

extern int  numCoup;             // Num apparaissant dans la liste des coups joués
extern long numDebugLine;        // Num de ligne du fichier de déboggage (implémentation supprimée du code)

extern int NUMBER_MOVES_AHEAD;

/* Création d'une variable globale particulière, de type MCNconnecteur, qui permettra de contrôler l'UI par
le code après lui avoir affecté la valeur de l'objet controleur instancié par AppDelegate (cf. cette classe) */
@class MCNconnecteur;
extern MCNconnecteur *monMCNControleur;

// Déclaration de 2 tableaux intervenant dans la 'description' des Pos et des Move
extern int Absc1[8];
extern int Absc2[8];

// Fin de Modif. MCN

extern void DoEvents(void);



