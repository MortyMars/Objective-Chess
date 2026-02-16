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

#define INF 1000000     // Définit le score infini pour limiter sans contraindre
#define QS_MAX_DEPTH 4  // Profondeur choisie pour la Quiescence



@class Move, ChessBoard; // compte tenu de l'appel de ces 2 classes dans la classe Minimax

@interface Minimax : NSObject

   // DÉCLARATION DES VARIABLES D'INSTANCE
   {
      @public  // Déclaration des iVars comme publiques pour accès aux catégories
      int nbLoop;
      int nbElag;
      int nodeCount;

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

   }

   @property int depthCounter;

   // DÉCLARATION DE MÉTHODES AFIN QU'ELLES SOIENT VISIBLES POUR LES TESTS
   -(int)NegamaxForSide:(Side)side
                  board:(ChessBoard *)board
                  depth:(int)depth
                  alpha:(int)alpha
                   beta:(int)beta;


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

   

   
@end


// Déclaration fonction de recalcul Zobrist 
//#ifdef DEBUG_ZOBRIST
   uint64_t recomputeZobrist(ChessBoard *board);
//#endif
