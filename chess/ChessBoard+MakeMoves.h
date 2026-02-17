//  ChessBoard+MakeMoves.m
//  chess
//  Created by MCN on 16/02/2026 for optimized New Engine
//  Copyright (c) 2026 MCN. All rights reserved

#import "ChessBoard.h" 

@interface ChessBoard (MakeMoves)   // Extension de la Classe ChessBoard

   -(MoveState)makeMove:(Move *)m ;

   -(void)unmakeMove:(Move *)m state:(MoveState)state;

   - (uint8_t)updateCastlingRights:(uint8_t)rights
                           forMove:(Move *)m
                     capturedPiece:(Piece *)captured
                             fromX:(int)fx fromY:(int)fy
                               toX:(int)tx toY:(int)ty;

@end
