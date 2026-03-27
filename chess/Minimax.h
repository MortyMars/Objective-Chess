// Minimax.h
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026

#import "Connecteur.h"
#import "MoveToStr.h"
#import "Piece.h"
#import "Move.h"
#import "Zobrist.h"
#import "TranspositionTable.h"
#import "Util.h"


#define INF 1000000     // Définit le score infini pour limiter sans contraindre
#define QS_MAX_DEPTH 4  // Profondeur choisie pour la Quiescence


// Constantes LMR (Late Moves Reductions - profondeur d'analyse)
/* Les valeurs proposées sont volontairement conservatives pour une première intégration.
Si le jeu est stable, on peut ensuite abaisser LMR_MOVE_THRESHOLD à 2 et monter
LMR_REDUCTION_2 à 3 pour gratter encore de la profondeur.                              */
#define LMR_MIN_DEPTH      3   // profondeur minimale pour déclencher LMR
#define LMR_MOVE_THRESHOLD 3   // index minimal du coup pour déclencher LMR
#define LMR_REDUCTION_1    1   // réduction standard
#define LMR_REDUCTION_2    2   // réduction agressive (coups très tardifs)
#define LMR_LATE_MOVE      6   // seuil pour réduction agressive

// Historique des positions pour détection de répétition
#define MAX_GAME_LENGTH 512


@class Move, ChessBoard; // compte tenu de l'appel de ces 2 classes dans la classe Minimax

@interface Minimax : NSObject

   // DÉCLARATION DES VARIABLES D'INSTANCE
   {
      @public  // Déclaration des iVars comme publiques pour accès aux catégories
      int nbLoop;
      int nbElag;
      //int nodeCount; // dble emploi avec nodes ?
      uint64_t nodes;

      // Variables de profilling
      int evalCount ;
      int moveGenCount ;
      int copyBoardCount ;
      NSTimeInterval evalTotalTime;
      NSTimeInterval moveGenTotalTime ;

      // Variables de cache
      NSMutableDictionary *evalCache;
      int cacheHits;
      int cacheMisses;

      // Tableau pour Heuristic History
      int historyTable[2][8][8][8][8];  // [side][fromX][fromY][toX][toY]
      
      // Variables stockant le meilleur coup entre itérations d'Iterative Deepening
      Move *_idBestMove;
      int   _idBestScore;
      
      /* Killer Moves
      Noter qu'une max depth Negamax 'limitée' à 64 nous laisse de la marge   */
      Move *_killerMoves[64][2][2]; // [max depth Negamax] [side 0=W 1=B] [slot]
      
      // Historique de positions
      uint64_t positionHistory[MAX_GAME_LENGTH];
      int      historyCount;
      
   }

   @property int depthCounter;
   @property (nonatomic, strong) TranspositionTable *transpositionTable;
   @property (nonatomic, strong) Move *lastIAMove;  // Dernier coup joué

   // Property temporaire pour Debug
   @property (nonatomic) int lastPhase; // phase PeSTO du dernier EvalBoardForSide

   // Introduction d'un Opening Book
   @property NSDictionary<NSString *, NSArray<NSString *> *> *openingBook;

   // DÉCLARATION DE MÉTHODES AFIN QU'ELLES SOIENT VISIBLES POUR LES TESTS
   -(int)NegamaxForSide:(Side)side
                  board:(ChessBoard *)board
                  depth:(int)depth  // depth est la profondeur restante (NUMBER_MOVES_AHEAD est sa valeur max)
                  alpha:(int)alpha
                   beta:(int)beta
             inNullMove:(BOOL)inNullMove
                    ply:(int)ply;   // ply est la distance depuis la racine. Le passage de ply en paramètre a pour
                                    // but de faciliter son incrémentation à chaque appel récursif de NegamaxForSide


   -(int)QuiescenceForSide:(Side)side
                     board:(ChessBoard *)board
                     alpha:(int)alpha
                      beta:(int)beta
                   qsDepth:(int)qsDepth;
   

   -(BOOL)IsKingInCheck:(Side)side board:(ChessBoard *)board;


   // Méthode déterminant le meilleur coup pour 'side''
   -(Move *)   BestMoveForSide:(Side)side             // côté blanc ou côté noir
                         Board:(ChessBoard *)board;   // et selon la configuration de l'échiquier courant

   // Méthode évaluant l'échiquier à un moment donné de la partie
   -(int)      EvalBoardForSide:(Side)side
                          board:(ChessBoard *)board;

   // Méthode déterminant tous les coups possibles pour un 'side'
   -(NSSet *)  PossibleMovesForSide:(Side)side
                              board:(ChessBoard *)board;


   // Méthode testant si 'side' met son adversaire en échec
   -(NSString *) TestEchecFavSide:(Side)side
                            Board:(ChessBoard *)board;

   // Méthode testant si le roi 'side' est en échec
   -(BOOL)     TestEchecRoiSide:(Side)side
                        inBoard:(ChessBoard*)board;


   // Détecte si une position a déjà été vue (répétition = nulle)
   -(BOOL)isRepetition:(uint64_t)zobristKey;

   // Helper IsKingInCheck
   -(BOOL)doesPieceAtX:(int)px Y:(int)py
         attackSquareX:(int)tx Y:(int)ty
                 board:(ChessBoard *)board;

   -(int)ValueOfPiece:(PieceType)p;

   // Helper 'doesPieceAtX'
   -(BOOL)isPathClearFromX:(int)fx Y:(int)fy
                       toX:(int)tx Y:(int)ty
                     board:(ChessBoard *)board;

   // Méthodes ajoutant la 'Mobilité' dans EvalBoardForSide
   -(int)EvaluateMobility:(ChessBoard *)board;
   -(int)CountPseudoLegalMovesForSide:(Side)side board:(ChessBoard *)board;

   

@end


// Déclaration fonction de recalcul Zobrist (utilisée en mode DEBUG_ZOBRIST
uint64_t recomputeZobrist(ChessBoard *board);


/* SCORES DE MAT ET TABLES DE TRANSPOSITION
Déclaration des fonctions Helpers ajoutées pour le calcul des scores de mat
PROBLÈME FONDAMENTAL :
Un score de mat encode à combien de coups le mat est détecté, via la convention :
score_mat = MATE_SCORE - ply_depuis_la_racine
Exemple : mat détecté en 3 coups depuis la racine → score = 100000 - 3 = 99997.
Ce score est relatif à la racine. Quand on le stocke en TT puis qu'on le récupère depuis
un nœud différent (à un autre ply), il faut le recentrer sur le nœud courant, sinon le moteur
croit voir un mat en 3 depuis un nœud qui est lui-même à ply=5 — ce qui correspond en réalité
à un mat en 8 depuis la racine.*/
static inline int scoreToTT(int score, int ply);
static inline int scoreFromTT(int score, int ply);
