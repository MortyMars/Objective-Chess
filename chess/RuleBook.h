// RuleBook.h
// chess
// Initial code by Andrew Wang on 15/07/2013,
// Refactoring by MortyMars in 2026


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

   // Méthodes de Classe SAR (Sans appel récursif)
   +(NSSet *) PosLegalesForPieceSAR:(Piece *)piece       // Version SAR de 'PosLegales...'
                              atPos:(Pos *)pos
                            inBoard:(ChessBoard *)board;

   +(BOOL)    TestEchecRoiSideSAR:(Side)side             // Version SAR de 'TestEchecRoi...'
                          inBoard:(ChessBoard *)board;

@end
