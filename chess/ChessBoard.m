//
//  ChessBoard.m
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import "ChessBoard.h"
#import "util.h"
#import "Piece.h"
#import "Pos.h"
#import "Move.h"

@implementation ChessBoard

-(id)init
{
    if (self=[super init]) {
    }
    return self;
}

-(void)setupPieces
{
    // init chess pieces
    board[0][0] = [[Piece alloc] initWithType:PieceTypeRook side:SideWhite];
    board[1][0] = [[Piece alloc] initWithType:PieceTypeKnight side:SideWhite];
    board[2][0] = [[Piece alloc] initWithType:PieceTypeBishop side:SideWhite];
    board[3][0] = [[Piece alloc] initWithType:PieceTypeQueen side:SideWhite];
    board[4][0] = [[Piece alloc] initWithType:PieceTypeKing side:SideWhite];
    board[5][0] = [[Piece alloc] initWithType:PieceTypeBishop side:SideWhite];
    board[6][0] = [[Piece alloc] initWithType:PieceTypeKnight side:SideWhite];
    board[7][0] = [[Piece alloc] initWithType:PieceTypeRook side:SideWhite];
    
    for (int x = 0; x < 8; x++) {
        board[x][1] = [[Piece alloc] initWithType:PieceTypePawn side:SideWhite];
        board[x][6] = [[Piece alloc] initWithType:PieceTypePawn side:SideBlack];
        board[x][7] = [[Piece alloc] initWithType:board[x][0].type side:SideBlack];
    }
}

-(Piece *)pieceAtX:(int)x y:(int)y
{
    if (x < 0 || y < 0 || x > 7 || y > 7) return nil;
    return board[x][y];
}

-(Piece *)pieceAtPos:(Pos *)pos
{
    int x = pos.x, y = pos.y;
    if (x < 0 || y < 0 || x > 7 || y > 7) return nil;
    return board[x][y];
}

-(void)performMove:(Move *)move
{
    Piece *piece = [self movePieceFrom:move.start to:move.dest];
    
    // if castle, move the rook too
    if (piece.type == PieceTypeKing && abs(move.dest.x - move.start.x) > 1) {
        int rookX = (move.dest.x == 2) ? 0 : 7;
        int rookDestX = (rookX == 0) ? 3 : 5;
        [self movePieceFrom:[Pos posWithX:rookX y:move.dest.y] to:[Pos posWithX:rookDestX y:move.dest.y]];
    }
    
    self.lastMove = move;   // save this move
}

-(Piece *)movePieceFrom:(Pos *)start to:(Pos *)dest
{
    // move in board
    board[(int)dest.x][(int)dest.y] = board[(int)start.x][(int)start.y];
    
    Piece *piece = board[(int)dest.x][(int)dest.y];
    piece.numMoves++; // increment number of moves
    
    board[(int)start.x][(int)start.y] = nil;
    
    return piece;
}

-(id)copyWithZone:(NSZone *)zone
{
    ChessBoard *newBoard = [[ChessBoard allocWithZone:zone] init];
    for (int x = 0; x < 8; x++) {
        for (int y = 0; y < 8; y++) {
            if (board[x][y]) newBoard->board[x][y] = board[x][y].copy;
        }
    }
    newBoard.lastMove = self.lastMove.copy;
    return newBoard;
}

-(NSString *)description
{
    NSString *desc = @"";
    for (int y = 7; y >= 0; y--) {
        for (int x = 0; x < 8; x++) {
            desc = [desc stringByAppendingFormat:@"%d ",board[x][y].type];
        }
        desc = [desc stringByAppendingString:@"\n"];
    }
    return desc;
}

@end
