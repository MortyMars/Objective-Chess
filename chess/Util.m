// Util.m
// chess
// Created by MCN on 01/12/2019 (Util.h was alone)
// Copyright © 2019 MCN - All rights reserved
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026

#import "Util.h"
#import "Minimax.h"


/* Initialisation des variables globales déclarées en .h */
Side sideCourant = sideWhite; // Valeur initialisée à sideWhite puisque ce sont tjs les Blancs qui commencent

Side sideJoueur = sideInvalid;
Side sideIA = sideInvalid;

NSString *stringCoupsPartie = @"";
NSString *stringDebugging   = @"";

BOOL petitRoque = NO;
BOOL grandRoque = NO;

BOOL stopMatOuPat = NO;

BOOL enPassant = NO;

int checkCount = 0;
int evalWhitePOV = 0;

int   numCoup = 2; // Numéro du coup pour la liste des coups joés
long  numDebugLine = 1;

int NUMBER_MOVES_AHEAD = 4; /* Valeur arbitraire cohérente avec l'activation par défaut -tout aussi
arbitraire-, du 'menu item' n°3 dans 'Partie->Difficulté'. Mais ça n'est qu'une conformité de façade
car c'est dans AppDelegate que l'on initialise réellement NUMBER_MOVES_AHEAD par appel de
[MCNconnecteur SetDifficulty1, 2, 3, 4, ou 5] qui positionne au passage le menu ad-hoc */

MCNconnecteur *monControleur = nil;

// Pré initialisation de maMinimax
Minimax *maMinimax = nil;


/* Tableaux de char utilisés pour la @property 'description' de 'Pos' ... */
int Absc1[8] = {'a','b','c','d','e','f','g','h'};  /* ici qd les BLANCS  sont en bas (colonnes de a à h) */
int Absc2[8] = {'h','g','f','e','d','c','b','a'};  /* et là qd les NOIRS sont en bas (colonnes de h à a) */

int depthCounter = 0;
