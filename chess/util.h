// Util.h
// chess
// Created by Andrew Wang on 15/07/2013,
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026


// =====================================================================================================
// DEFINE ET MACROS

/* MCN - Macro permettant de supprimer les indications Date, Heure, Appli, ... des messages NSLog */
#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

// Macros de transposition de la propriété 'square' d'un 'move'
// cf. la déclaration du typedef Square ci-après
#define SQ(x, y)   ((y) * 8 + (x))
#define SQ_X(sq)   ((sq) & 7)
#define SQ_Y(sq)   ((sq) >> 3)

/* Macro de debugging des Move sous forme de 'square' selon l'usage
NSLog(@"Move %@ -> %@", SQ_STR(m.fromSquare), SQ_STR(m.toSquare));  */
#define SQ_STR(sq) \
    ([NSString stringWithFormat:@"%c%d", 'a'+SQ_X(sq), SQ_Y(sq)+1])

// Valeur de base du Mat
#define MATE_SCORE    100000   // définition de la valeur de base du mat



// ===============================================================================================================
// TYPEDEF

/* 'Square' représente les cases de l'échiquier sous la forme d'un int entre 0 et 63
La transposition en coordonnées x (colonnes) et y (rangées) s'opère grâce aux macros ci-dessus
L'ordre de numérotation arbitraire est le suivant (les blancs sont en bas) :
       56 57 58 59 60 61 62 63       (rangée y=7 --> 7*8=56 + colonne x=0 à 7)
       48 49 50 51 52 53 54 55       (rangée y=6 --> 6*8=48 + colonne x=0 à 7)
       40 41 42 43 44 45 46 47       (rangée y=5 --> 5*8=40 + colonne x=0 à 7)
       32 33 34 35 36 37 38 39       (rangée y=4 --> 4*8=32 + colonne x=0 à 7)
       24 25 26 27 28 29 30 31       (rangée y=3 --> 3*8=24 + colonne x=0 à 7)
       16 17 18 19 20 21 22 23       (rangée y=2 --> 2*8=16 + colonne x=0 à 7)
        8  9 10 11 12 13 14 15       (rangée y=1 --> 1*8=8  + colonne x=0 à 7)
        0  1  2  3  4  5  6  7       (rangée y=0 --> 0*8=0  + colonne x=0 à 7)              */

typedef int Square;


/* 'PieceType' définit -via une énum- un nouveau type de données pour les pièces du jeu.
(pour le coup il s'agit du type de pièce : pion, tour, cavalier, fou, dame, roi)
La succession des pièces dans l'énumération n'est pas anodine.
En effet, chacune recevra l'indice de sa position lorsqu'il s'agira de lui attribuer une représentation en
ligne de commande, et notamment lorsqu'on voudra afficher l'échiquier sous forme de matrice simplifiée.
Sachant que le premier type dans l'énum porte l'indice 0, que le deuxième porte l'indice 1 et ainsi de suite,
on déduit de l'ordre fixé dans l'énum, qu'une pièce invalide ou l'absence de pièce sera représentée par '0'
un pion '1', un cavalier '2', un fou '3', une tour '4', une dame '5', et un roi '6' d'où la matrice de départ
de partie (les blancs sont en bas) :
      4  2  3  5  6  3  2  4
      1  1  1  1  1  1  1  1
      0  0  0  0  0  0  0  0
      0  0  0  0  0  0  0  0
      0  0  0  0  0  0  0  0
      0  0  0  0  0  0  0  0
      1  1  1  1  1  1  1  1
      4  2  3  5  6  3  2  4         */

typedef enum {Invalide, Pion, Cava, Fou,
              Tour, Dame, Roi} PieceType;


/* 'Side' définit -via une énum- un nouveau type pour les couleurs en présence.
Chaque 'Side' ici défini prend la valeur de son indice dans l'enum
Ainsi on peut écrire que sideInvalid = 0, sideBlack = 1, et sideWhite = 2, mais il est beaucoup
plus efficace dans le code d'utiliser leur mnémonique plutôt que leur valeur intrinsèque */

typedef enum {sideInvalid, sideBlack, sideWhite} Side;



// ===============================================================================================================
// VARIABLES GLOBALES

/* Ajout de variables globales (pardon aux puristes défenseurs du code académique)
Chacune de ces variables ont des implantations dans le code de plusieurs Classes.
Il ne m'a donc pas été possible de les déclarer comme variables d'instance, ce qui aurait été plus élégant.
Certaines autres variables à portée plus limitée ont par contre pu être définies comme telles dans la classe
qu'elles concernent exclusivement.
NB : 'extern' (mot clé pour definir une variable globale en Objectice-C) supporte les variables mais aussi
les fonctions/méthodes sous la forme par exemple de : 'extern void MaFonction(NSString *param1, int param2)' */

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
                           ce qui limite la recherche du prochain coup ; mais ça reste à implémenter...   */

extern int evalWhitePOV;   /* Valeur d'évaluation d'un Board, signée conformément à la convention */

extern int  numCoup;       // Num apparaissant dans la liste des coups joués
extern long numDebugLine;  // Num de ligne du fichier de débogage (implémentation supprimée du code)

extern int NUMBER_MOVES_AHEAD;

// Déclaration de 2 tableaux intervenant dans la 'description' des Pos et des Move
extern int Absc1[8];
extern int Absc2[8];


/* VARIABLE GLOBALE ESSENTIELLE, de type 'Connecteur' créée pour contrôler l'UI depuis n'importe quelle classe.
Une instance de cette même classe ('connecteurFromIB') est à l'origine créée par Interface Builder lors de
l'initialisation de l'interface, pour la piloter, mais avec l'inconvénient de ne pas être globalement accessible.
On assignera la valeur de cette instance à notre variable globale pour en faire un 'connecteur' UI durable. */
@class Connecteur;
extern Connecteur *monConnecteur;

/* Pour faciliter l'accès aux méthodes d'instances de la classe Minimax, création d'une variable
globale permettant de garder le contrôle sur l'instance (unique dans une partie)              */
@class Minimax;
extern Minimax *maMinimax;

// Pour test d'involubilité
extern BOOL engineIsBusy;

// Pour moteur verbeux
extern BOOL kVerboseMoveDebug;

extern const int bishopDirs[4][2];
extern const int rookDirs[4][2];
extern const int queenDirs[8][2];
extern const int knightOffsets[8][2];

extern BOOL partieLancee;

extern BOOL modeAuto;



// ===============================================================================================================
// MÉTHODES GLOBALES

// Méthode globale 'DoEvents'
extern void DoEvents(void);


extern void TestInvolution(void);


