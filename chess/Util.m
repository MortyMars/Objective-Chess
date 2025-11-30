//  Util.m
//  chess
//
//  Created by MCN on 01/12/2019 (Util.h existait déjà)
//  Copyright © 2019 MCN - All rights reserved.

#import "Util.h"


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
int evalDisplay = 0;

int   numCoup = 2;
long  numDebugLine = 1;

int NUMBER_MOVES_AHEAD = 2; /* Valeur arbitraire cohérente avec l'activation par défaut -tout aussi
arbitraire-, du 'menu item' n°3 dans 'Partie->Difficulté'. Mais ça n'est qu'une conformité de façade
car c'est dans AppDelegate que l'on initialise réellement NUMBER_MOVES_AHEAD par appel de
[MCNconnecteur SetDifficulty1, 2, 3, 4, ou 5] qui positionne au passage le menu ad-hoc */

MCNconnecteur *monMCNControleur = nil;

/* Tableaux de char utilisés pour la @property 'description' de 'Pos' ... */
int Absc1[8] = {'a','b','c','d','e','f','g','h'};  /* ici qd les BLANCS  sont en bas (colonnes de a à h) */
int Absc2[8] = {'h','g','f','e','d','c','b','a'};  /* et là qd les NOIRS sont en bas (colonnes de h à a) */
