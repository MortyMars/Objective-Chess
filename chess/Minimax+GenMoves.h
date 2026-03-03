// Minimax+GenMoves.h
// chess
// Created by MCN on 16/02/2026 for optimized New Engine
// Copyright (c) 2026 MCN. All rights reserved


#import "Minimax.h"

@interface Minimax (GenMoves)    // Extension de la Classe Minimax

   // MÉTHODES DE MOVES
   -(void)GenMovesForSide:(Side)side
                    board:(ChessBoard *)board
                     into:(NSMutableArray<Move *> *)moves;

   -(void)GenPawnMovesFromX:(int)x y:(int)y
                      piece:(Piece *)p
                      board:(ChessBoard *)board
                       into:(NSMutableArray<Move *> *)moves;

   -(void)GenKnightMovesFromX:(int)x y:(int)y
                        piece:(Piece *)p
                        board:(ChessBoard *)board
                         into:(NSMutableArray *)moves;

   -(void)GenSlideMovesFromX:(int)x y:(int)y
                       piece:(Piece *)p
                       board:(ChessBoard *)board
                        dirs:(const int (*)[2])dirs
                    dirCount:(int)dirCount
                        into:(NSMutableArray *)moves;

   -(void)GenKingMovesFromX:(int)x y:(int)y
                      piece:(Piece *)p
                      board:(ChessBoard *)board
                       into:(NSMutableArray *)moves;

   
// MÉTHODES DE CAPTURES
   -(void)GenCapturForSide:(Side)side
                     board:(ChessBoard *)board
                      into:(NSMutableArray<Move *> *)moves;

   -(void)GenPawnCapturFromX:(int)x y:(int)y
                       piece:(Piece *)p
                       board:(ChessBoard *)board
                        into:(NSMutableArray<Move *> *)moves;

   -(void)GenKnightCapturFromX:(int)x y:(int)y
                         piece:(Piece *)p
                         board:(ChessBoard *)board
                          into:(NSMutableArray<Move *> *)moves;

   -(void)GenSlideCapturFromX:(int)x y:(int)y
                        piece:(Piece *)p
                        board:(ChessBoard *)board
                         dirs:(const int (*)[2])dirs
                     dirCount:(int)dirCount
                         into:(NSMutableArray<Move *> *)moves;

   -(void)GenKingCapturFromX:(int)x y:(int)y
                       piece:(Piece *)p
                       board:(ChessBoard *)board
                        into:(NSMutableArray<Move *> *)moves;


   // MÉTHODES HELPER
   -(BOOL)IsSquareDefended:(Square)sq bySide:(Side)side board:(ChessBoard *)board;

   -(BOOL)IsSquareAttackedAtX:(int)x
                            Y:(int)y
                       bySide:(Side)attackingSide
                        Board:(ChessBoard *)board;


@end
