//
//  ChessView.m
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import "ChessView.h"
#import "ChessBoard.h"
#import "Piece.h"
#import "RuleBook.h"
#import "util.h"
#import "Pos.h"
#import "Move.h"
#import "Minimax.h"

@implementation ChessView

-(id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        board = [[ChessBoard alloc] init];
        [board setupPieces];
    }
    
    return self;
}

-(void)drawBoard
{
    float tileWidth = self.bounds.size.width / 8;
    float tileHeight = self.bounds.size.height / 8;
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    NSImage *piecesImage = [NSImage imageNamed:@"pieces.png"];
    for (int x = 0; x < 8; x++) {
        for (int y = 0; y < 8; y++) {
            CGRect destRect = CGRectMake(x * tileWidth, y * tileHeight, tileWidth, tileHeight);
            
            // color each tile as a checkerboard
            if (hasSelTile && selTile.x == x && selTile.y == y) {   // selected tile
                CGContextSetRGBFillColor(context, 0, 255, 0, 255);
            } else if ([coverage containsObject:[Pos posWithX:x y:y]]) {   // part of coverage
                CGContextSetRGBFillColor(context, 255, 0, 0, 255);
            } else {    // normal tile
                if ((x + y) % 2 == 1) {
                    CGContextSetRGBFillColor(context, 255, 255, 255, 255);
                } else {
                    CGContextSetRGBFillColor(context, 0, 0, 100, 255);
                }
            }
            CGContextFillRect(context, destRect);
            
            Piece *piece = [board pieceAtPos:[Pos posWithX:x y:y]];
            Side side = piece.side;
            
            if (piece) {    // if piece exists at this point
                int index = 0;
                switch (piece.type) {
                    case PieceTypeInvalid: break;
                    case PieceTypeQueen: index = 0; break;
                    case PieceTypeKing: index = 1; break;
                    case PieceTypeRook: index = 2; break;
                    case PieceTypePawn: index = 3; break;
                    case PieceTypeBishop: index = 4; break;
                    case PieceTypeKnight: index = 5; break;
                    default: break;
                }
                CGRect sourceRect = CGRectMake(index * 60, (side == SideBlack) ? 0 : 60, 60, 60);
                [piecesImage drawInRect:destRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1];
            }
        }
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    float tileWidth = self.bounds.size.width / 8;
    float tileHeight = self.bounds.size.height / 8;
    
    CGPoint pos = [theEvent locationInWindow];
    int x = pos.x / tileWidth, y = pos.y / tileHeight;
    Pos *tilePos = [Pos posWithX:x y:y];
    Piece *selPiece = [board pieceAtPos:tilePos];
    if (!hasSelTile) {      // selecting a piece
        if ([board pieceAtPos:tilePos]) {
            selTile = tilePos;
            hasSelTile = YES;
            coverage = [RuleBook coverageForPiece:selPiece atPos:tilePos inBoard:board];
        }
    } else {                // moving a selected piece
        // move has to be valid
        if (tilePos.x != selTile.x || tilePos.y != selTile.y) {
            if ([coverage containsObject:tilePos]) {
                // move the piece
                Move *move = [[Move alloc] initWithStart:selTile dest:tilePos];
                [board performMove:move];
                
                [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(makeComputerMove) userInfo:nil repeats:NO];
            }
        }
        hasSelTile = NO;
        coverage = nil;
    }

    self.needsDisplay = YES;
}

-(void)makeComputerMove
{
    // make AI move
    Move *aiMove = [Minimax bestMoveForSide:SideBlack board:board];
    [board performMove:aiMove];
    
    self.needsDisplay = YES;
}

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    [self drawBoard];
}

@end
