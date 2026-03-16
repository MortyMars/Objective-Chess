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

#define INF 1000000     // Définit le score infini pour limiter sans contraindre
#define QS_MAX_DEPTH 4  // Profondeur choisie pour la Quiescence



@class Move, ChessBoard; // compte tenu de l'appel de ces 2 classes dans la classe Minimax

@interface Minimax : NSObject

   // DÉCLARATION DES VARIABLES D'INSTANCE
   {
      @public  // Déclaration des iVars comme publiques pour accès aux catégories
      int nbLoop;
      int nbElag;
      int nodeCount; // dble emploi avec nodes ?
      uint64_t nodes;     // dble emploi avec nodeCount ?

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
      
      // Compteur de profondeur de pile make/unmake
      //int depthCounter;
      
      /* Supprimé des iVar, et désormais passé en paramètre
      // Drapeau utilisé par le Null Move Pruning
      //@public BOOL isInNullMove;  // initialisé dans BMFS
      Fin de suppression */
      
      // Variables stockant le meilleur coup entre itérations d'Iterative Deepening
      Move *_idBestMove;
      int   _idBestScore;
      
      // Killer Moves
      Move *_killerMoves[64][2][2]; // [max depth Negamax] [side 0=W 1=B] [slot]
      /* Noter qu'une max depth Negamax 'limitée' à 64 nous laisse de la marge */

   }

   @property int depthCounter;

   @property (nonatomic, strong) TranspositionTable *transpositionTable;

   @property (nonatomic, strong) Move *lastIAMove;  // Dernier coup joué

   // Introduction d'un Opening Book
   @property NSDictionary<NSString *, NSArray<NSString *> *> *openingBook;

   // Historique des positions pour détection de répétition
   #define MAX_GAME_LENGTH 512

   // DÉCLARATION DE MÉTHODES AFIN QU'ELLES SOIENT VISIBLES POUR LES TESTS
   -(int)NegamaxForSide:(Side)side
                  board:(ChessBoard *)board
                  depth:(int)depth
                  alpha:(int)alpha
                   beta:(int)beta
             inNullMove:(BOOL)inNullMove;


   -(int)QuiescenceForSide:(Side)side
                     board:(ChessBoard *)board
                     alpha:(int)alpha
                      beta:(int)beta
                   qsDepth:(int)qsDepth;


   // MÉTHODES AJOUTÉES POUR LE REFACTORING DU MOTEUR
   

   -(BOOL)IsKingInCheck:(Side)side board:(ChessBoard *)board;

   
   // DÉCLARATION DES MÉTHODES D'INSTANCE

   // Méthode déterminant le meilleur coup pour 'side''
   -(Move *)   BestMoveForSide:(Side)side             // côté blanc ou côté noir
                         Board:(ChessBoard *)board;   // et selon la configuration de l'échiquier courant

   // Méthode évaluant l'échiquier à un moment donné de la partie
   -(int)      EvalBoardForSide:(Side)side
                          board:(ChessBoard *)board;

   // Méthode déterminant tous les coups possibles pour un 'side'
   -(NSSet *)  PossibleMovesForSide:(Side)side
                              board:(ChessBoard *)board;


   // MÉTHODES DE CLASSE MCN
   // Méthode testant si 'side' met son adversaire en échec
   -(NSString *) TestEchecFavSide:(Side)side
                            Board:(ChessBoard *)board;

   // Méthode testant si le roi 'side' est en échec
   -(BOOL)     TestEchecRoiSide:(Side)side
                        inBoard:(ChessBoard*)board;

   // Méthode SSE qui calcule si une capture est bonne
   /* +(int)StaticExchangeEvaluation:(Move *)capture
                   board:(ChessBoard *)board; */

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

   // Méthode de construction de l'Opening Book
   -(void)buildOpeningBook;


   
@end


// Déclaration fonction de recalcul Zobrist 
//#ifdef DEBUG_ZOBRIST
   uint64_t recomputeZobrist(ChessBoard *board);
//#endif
