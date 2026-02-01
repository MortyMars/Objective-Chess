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
   +(NSSet *) PosLegalesForPiece:(Piece *)piece
                           atPos:(Pos *)pos
                         inBoard:(ChessBoard *)board;

   +(NSSet *) SearchInDirection:(Pos *)start
                                dx:(int)dx
                                dy:(int)dy
                             board:(ChessBoard *)board;

   // Méthodes de Classe MCN
   +(NSSet *) PosLegalesForPieceSAR:(Piece *)piece       // Méthode SAR (Sans appel récursif)
                              atPos:(Pos *)pos
                            inBoard:(ChessBoard *)board;

   +(BOOL)    TestEchecRoiSideSAR:(Side)side             // Méthode SAR (Sans appel récursif)
                          inBoard:(ChessBoard *)board;

@end
