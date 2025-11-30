//
//  Minimax.m
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import "Minimax.h"
#import "ChessBoard.h"
#import "Piece.h"
#import "Move.h"
#import "Pos.h"
#import "RuleBook.h"

#define NUM_MOVES_AHEAD 3

@implementation Minimax

+(Move *)bestMoveForSide:(Side)side board:(ChessBoard *)board
{
    int bestScore = -INFINITY;
    Move *bestMove = nil;
    for (Move *newMove in [self possibleMovesForSide:side board:board]) {
        ChessBoard *newBoard = board.copy;
        [newBoard performMove:newMove];
        int score = [self minimaxForSide:side board:newBoard depth:NUM_MOVES_AHEAD alpha:-INFINITY beta:INFINITY];
        if (score > bestScore || !bestMove) {
            NSLog(@"A good move is %@ with score %d",newMove,score);
            bestScore = score;
            bestMove = newMove;
        }
    }
    return bestMove;
}

+(int)minimaxForSide:(Side)side board:(ChessBoard *)board depth:(int)depth alpha:(int)alpha beta:(int)beta
{
    if (depth <= 0) {
        return [self scoreForSide:side board:board];
    } else {
        int best = INFINITY;
        Side otherSide = (side == SideWhite) ? SideBlack : SideWhite;
        for (Move *newMove in [self possibleMovesForSide:otherSide board:board]) {
            ChessBoard *newBoard = board.copy;
            [newBoard performMove:newMove];
            int score = -[self minimaxForSide:otherSide board:newBoard depth:depth - 1 alpha:-beta beta:-alpha];
            best = MIN(best,score);
            //if (score > alpha) alpha = score;
            //if (alpha >= beta) return alpha;
        }
        return best;
    }
}

+(int)scoreForSide:(Side)side board:(ChessBoard *)board
{
    int score = 0;
    
    for (int x = 0; x < 8; x++) {
        for (int y = 0; y < 8; y++) {
            Piece *piece = [board pieceAtX:x y:y];
            if (piece) {
                int value = 0;
                switch (piece.type) {
                    case PieceTypeInvalid: break;
                    case PieceTypeBishop: case PieceTypeKnight: value = 300; break;
                    case PieceTypeRook: value = 500; break;
                    case PieceTypeQueen: value = 900; break;
                    case PieceTypePawn: value = 100; break;
                    case PieceTypeKing: value = 100000; break;
                }
                score += value * ((piece.side == side) ? 1 : -1);
            }
        }
    }
    //if (score) NSLog(@"Score is %d for board\n%@ and side %@",score,board,(side == SideBlack) ? @"black" : @"white");
    
    return score;
}

+(NSSet *)possibleMovesForSide:(Side)side board:(ChessBoard *)board
{
    NSMutableSet *moves = [[NSMutableSet alloc] init];
    for (int x = 0; x < 8; x++) {
        for (int y = 0; y < 8; y++) {
            Pos *pos = [Pos posWithX:x y:y];
            Piece *piece = [board pieceAtX:x y:y];
            if (piece) {
                if (piece.side == side) {
                    NSSet *coverage = [RuleBook coverageForPiece:piece atPos:pos inBoard:board];
                    for (Pos *possibleDest in coverage) {
                        Move *move = [[Move alloc] initWithStart:pos dest:possibleDest];
                        [moves addObject:move];
                    }
                }
            }
        }
    }
    return moves;
}
@end
