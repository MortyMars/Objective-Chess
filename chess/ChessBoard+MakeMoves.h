// ChessBoard+MakeMoves.m
// chess
// Created by MortyMars on 16/02/2026


#import "ChessBoard.h" 

@interface ChessBoard (MakeMoves)   // Extension de la Classe ChessBoard

   -(MoveState) makeMove:(Move *)m ;

   -(void)      unmakeMove:(Move *)m state:(MoveState)state;

   -(uint8_t)   updateCastlingRights:(uint8_t)rights
                             forMove:(Move *)m
                       capturedPiece:(Piece *)captured;


@end
