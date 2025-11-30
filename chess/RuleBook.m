//
//  RuleBook.m
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import "RuleBook.h"
#import "Piece.h"
#import "ChessBoard.h"
#import "util.h"
#import "Pos.h"

@implementation RuleBook

+(NSSet *)coverageForPiece:(Piece *)piece atPos:(Pos *)pos inBoard:(ChessBoard *)board
{
    NSMutableSet *coverage = [[NSMutableSet alloc] init];
    
    if (piece.type == PieceTypeRook || piece.type == PieceTypeQueen) {
        [coverage unionSet:[self flashlightBeam:pos dx:1 dy:0 board:board]];
        [coverage unionSet:[self flashlightBeam:pos dx:-1 dy:0 board:board]];
        [coverage unionSet:[self flashlightBeam:pos dx:0 dy:1 board:board]];
        [coverage unionSet:[self flashlightBeam:pos dx:0 dy:-1 board:board]];
    }
    if (piece.type == PieceTypeBishop || piece.type == PieceTypeQueen) {
        [coverage unionSet:[self flashlightBeam:pos dx:1 dy:1 board:board]];
        [coverage unionSet:[self flashlightBeam:pos dx:-1 dy:1 board:board]];
        [coverage unionSet:[self flashlightBeam:pos dx:1 dy:-1 board:board]];
        [coverage unionSet:[self flashlightBeam:pos dx:-1 dy:-1 board:board]];
    }
    if (piece.type == PieceTypeKing) {
        // normal moves
        for (int x = pos.x - 1; x <= pos.x + 1; x++) {
            for (int y = pos.y - 1; y <= pos.y + 1;y++) {
                if (x >= 0 && y >= 0 && x < 8 && y < 8) {
                    if (x != pos.x || y != pos.y) {
                        [coverage addObject:[Pos posWithX:x y:y]];
                    }
                }
            }
        }
        
        // castle
        if (piece.numMoves == 0) {
            Piece *rightRook = [board pieceAtX:7 y:pos.y];
            Piece *leftRook = [board pieceAtX:0 y:pos.y];
            
            // kingside
            if (rightRook && rightRook.numMoves == 0) {
                if (![board pieceAtX:6 y:pos.y] && ![board pieceAtX:5 y:pos.y])
                    [coverage addObject:[Pos posWithX:6 y:pos.y]];
            }
            
            // queenside
            if (leftRook && leftRook.numMoves == 0) {
                if (![board pieceAtX:3 y:pos.y] && ![board pieceAtX:2 y:pos.y] && ![board pieceAtX:1 y:pos.y])
                    [coverage addObject:[Pos posWithX:2 y:pos.y]];
            }
        }
    }
    if (piece.type == PieceTypeKnight) {
        if (pos.x >= 1 && pos.y >= 2)
            [coverage addObject:[Pos posWithX:pos.x - 1 y:pos.y - 2]];
        if (pos.x >= 2 && pos.y >= 1)
            [coverage addObject:[Pos posWithX:pos.x - 2 y:pos.y - 1]];
        if (pos.x >= 2 && pos.y <= 6)
            [coverage addObject:[Pos posWithX:pos.x - 2 y:pos.y + 1]];
        if (pos.x >= 1 && pos.y <= 5)
            [coverage addObject:[Pos posWithX:pos.x - 1 y:pos.y + 2]];
        if (pos.x <= 6 && pos.y >= 2)
            [coverage addObject:[Pos posWithX:pos.x + 1 y:pos.y - 2]];
        if (pos.x <= 5 && pos.y >= 1)
            [coverage addObject:[Pos posWithX:pos.x + 2 y:pos.y - 1]];
        if (pos.x <= 5 && pos.y <= 6)
            [coverage addObject:[Pos posWithX:pos.x + 2 y:pos.y + 1]];
        if (pos.x <= 6 && pos.y <= 5)
            [coverage addObject:[Pos posWithX:pos.x + 1 y:pos.y + 2]];
    }
    if (piece.type == PieceTypePawn) {
        int dir = piece.side == SideWhite ? 1 : -1;
        // normal move
        Pos *dest = [Pos posWithX:pos.x y:pos.y + dir];
        if (![board pieceAtPos:dest]) {
            [coverage addObject:dest];
            
            // double move on first turn
            dest = [Pos posWithX:pos.x y:pos.y + 2 * dir];
            if (piece.numMoves == 0 && ![board pieceAtPos:dest])
                [coverage addObject:dest];
        }
        
        // capture
        Pos *posLeft = [Pos posWithX:pos.x - 1 y:pos.y + dir];
        Pos *posRight = [Pos posWithX:pos.x + 1 y:pos.y + dir];
        Piece *capturedPieceLeft = [board pieceAtPos:posLeft];
        Piece *capturedPieceRight = [board pieceAtPos:posRight];
        if (capturedPieceLeft) {
            if (capturedPieceLeft.side != piece.side) {
                [coverage addObject:posLeft];
            }
        }
        if (capturedPieceRight) {
            if (capturedPieceRight.side != piece.side) {
                [coverage addObject:posRight];
            }
        }
        
        // TODO: en passant
    }
    
    // remove all pieces that are the same side as the player!
    NSMutableSet *toBeRemoved = [[NSMutableSet alloc] init];
    for (Pos *pos in coverage) {
        if ([board pieceAtPos:pos].side == piece.side) {
            [toBeRemoved addObject:pos];
        }
    }
    [coverage minusSet:toBeRemoved];
    
    return coverage;
}

+(NSSet *)flashlightBeam:(Pos *)start dx:(int)dx dy:(int)dy board:(ChessBoard *)board
{
    NSMutableSet *beam = [[NSMutableSet alloc] initWithCapacity:8];
    
    int x = start.x, y = start.y;
    
    do {
        x += dx;
        y += dy;
        
        if (x < 0 || y < 0 || x > 7 || y > 7) break;
        
        Pos *pos = [Pos posWithX:x y:y];
        [beam addObject:pos];
    } while (![board pieceAtX:x y:y]);
    
    return beam;
}

@end
