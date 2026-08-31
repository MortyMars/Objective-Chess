// Minimax+OpeningBook.h
// chess
// Created by MortyMars on 18/03/2026


#import "Minimax.h"

@interface Minimax (OpeningBook)    // Extension de la Classe Minimax


   // Méthode de construction de l'Opening Book
   -(void)buildOpeningBook;

   // Méthode lookupOpeningBook
   -(Move *)lookupOpeningBook:(ChessBoard *)board
                         side:(Side)side;

   // Méthode partialFEN
   -(NSString *)partialFEN:(ChessBoard *)board
                      side:(Side)side;

   // Méthode fenSymbolForPiece
   -(NSString *)fenSymbolForPiece:(Piece *)p;


@end
