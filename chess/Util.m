// Util.m
// chess
// Created by MCN on 01/12/2019 (Util.h was alone)
// Copyright © 2019 MCN - All rights reserved
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026

#import "Util.h"
#import "Minimax.h"
#import <assert.h>


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

int   numCoup = 2; // Numéro du coup pour la liste des coups joués
long  numDebugLine = 1;

int NUMBER_MOVES_AHEAD = 4; /* Valeur arbitraire cohérente avec l'activation par défaut -tout aussi
arbitraire-, du 'menu item' n°3 dans 'Partie->Difficulté'. Mais ça n'est qu'une conformité de façade
car c'est dans AppDelegate que l'on initialise réellement NUMBER_MOVES_AHEAD par appel de
[Connecteur SetDifficulty1, 2, 3, 4, ou 5] qui positionne au passage le menu ad-hoc */


// Pré initialisation de monConnecteur
Connecteur *monConnecteur = nil;

// Pré initialisation de maMinimax
Minimax *maMinimax = nil;


/* Tableaux de char utilisés pour la @property 'description' de 'Pos' ... */
int Absc1[8] = {'a','b','c','d','e','f','g','h'};  /* ici qd les BLANCS  sont en bas (colonnes de a à h) */
int Absc2[8] = {'h','g','f','e','d','c','b','a'};  /* et là qd les NOIRS sont en bas (colonnes de h à a) */

int depthCounter = 0;

// Méthode de test d'involutivité
/* void TestInvolution(ChessBoard *board)
{
    uint64_t hash0 = board->zobristKey;
    int side0      = board->sideToMove;
    int castle0    = board->castlingRights;
    int ep0        = board->enPassantFile;

    Piece *backup[8][8];
    memcpy(backup, board->pieceCase, sizeof(backup));

    //NSMutableArray<Move *> *moves = [NSMutableArray array];
    //[board GenerateLegalMoves:moves];
   NSSet * moves;
   
   moves = [maMinimax PossibleMovesForSide:sideWhite board:board];

    for (Move *m in moves) {

        MoveState st = [board makeMove:m];
        [board unmakeMove:m state:st];

        // --- ASSERTS ---
        if (board->zobristKey != hash0 ||
            board->sideToMove != side0 ||
            board->castlingRights != castle0 ||
            board->enPassantFile != ep0 ||
            memcmp(board->pieceCase, backup, sizeof(backup)) != 0)
        {
            NSLog(@"❌ Involution cassée !");
            NSLog(@"Move fautif : %@", m);
            NSLog(@"Involution make/unmake échouée");
        }
    }
} */

void TestInvolution(void)
{
    // ================== SAUVEGARDE ==================

    Piece *savedPieceCase[8][8];
    for (int x = 0; x < 8; x++)
        for (int y = 0; y < 8; y++)
            savedPieceCase[x][y] = monConnecteur.maChessView->liveBoard->pieceCase[x][y];

    uint64_t savedZobrist      = monConnecteur.maChessView->liveBoard->zobristKey;
    Side     savedSideToMove   = monConnecteur.maChessView->liveBoard->sideToMove;
    int      savedCastleRights = monConnecteur.maChessView->liveBoard->castlingRights;
    int      savedEPFile       = monConnecteur.maChessView->liveBoard->enPassantFile;

    // ================== TEST ==================

   NSSet * moves;
   
   moves = [maMinimax PossibleMovesForSide:sideWhite board:monConnecteur.maChessView->liveBoard];

    for (Move *m in moves)
    {
        MoveState st = [monConnecteur.maChessView->liveBoard makeMove:m];
        [monConnecteur.maChessView->liveBoard unmakeMove:m state:st];

        // -------- Comparaison board --------
        for (int x = 0; x < 8; x++) {
            for (int y = 0; y < 8; y++) {
                if (monConnecteur.maChessView->liveBoard->pieceCase[x][y] != savedPieceCase[x][y]) {
                    NSLog(@"❌ Involution échouée sur move %@", m);
                    NSLog(@"Board corrompu après unmakeMove");
                }
            }
        }

        // -------- Comparaison état global --------
       assert(monConnecteur.maChessView->liveBoard->zobristKey == savedZobrist);
       assert(monConnecteur.maChessView->liveBoard->sideToMove == savedSideToMove);
       assert(monConnecteur.maChessView->liveBoard->castlingRights == savedCastleRights);
       assert(monConnecteur.maChessView->liveBoard->enPassantFile == savedEPFile);
    }

    NSLog(@"✅ TestInvolution OK (%lu moves)", (unsigned long)moves.count);
}


