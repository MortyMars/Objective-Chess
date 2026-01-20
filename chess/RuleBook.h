//  RuleBook.h
//  chess
//  Created by Andrew Wang on 15/07/2013,
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020



#import "Util.h"


@class Piece,Pos;
@class ChessBoard;

@interface RuleBook : NSObject

   
   // Méthodes de Classe
   +(NSSet *) PosAccepteesForPiece:(Piece *)piece
                             atPos:(Pos *)pos
                           inBoard:(ChessBoard *)board;

   +(NSSet *) RechercheEnDirection:(Pos *)start
                                dx:(int)dx
                                dy:(int)dy
                             board:(ChessBoard *)board;



   // Méthodes de Classe MCN
   +(NSSet *) PosAccepteesForPieceSAR:(Piece *)piece
                                atPos:(Pos *)pos
                              inBoard:(ChessBoard *)board;

   +(BOOL)    TestEchecRoiSideSAR:(Side)side
                          inBoard:(ChessBoard *)board;

  

@end
