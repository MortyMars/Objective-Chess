//  Minimax.h
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 2020
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "MCNconnecteur.h"
#import "MCNmoveToStr.h"
#import "Piece.h"



@class Move, ChessBoard; // compte tenu de l'appel de ces 2 classes dans la classe Minimax


@interface Minimax : NSObject

   {
   // variable d'instance
   
   }

    
   // Méthode de classe déterminant le meilleur coup pour les blancs / les noirs
   +(Move *)     BestMoveForSide:(Side)side             // côté blanc ou côté noir
                           board:(ChessBoard *)board;   // et selon la configuration de l'échiquier courant

   // Méthode de classe évaluant l'échiquier à un moment donné de la partie
   +(int)        EvalBoardForSide:(Side)side
                            board:(ChessBoard *)board;

   +(NSSet *)    PossibleMovesForSide:(Side)side
                                board:(ChessBoard *)board;

   +(void)       NotifiePatMatDesSide:(Side)side
                              onBoard:(ChessBoard*)board;
   

   // Méthodes de Classe MCN
   +(NSString *) TestEchecFavSide:(Side)side
                            Board:(ChessBoard *)board;

   +(BOOL)       TestEchecRoiSide:(Side)side
                          inBoard:(ChessBoard*)board;

   // Déclaration de méthodes, ajoutées pour qu'elles soient accessibles pour les tests
   +(int)        NegamaxForSide:(Side)side
                          board:(ChessBoard *)board
                          depth:(int)depth
                          alpha:(int)alpha
                           beta:(int)beta;


@end
