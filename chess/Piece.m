//
//  Piece.m
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import "Piece.h"

@implementation Piece

-(id)initWithType:(PieceType)type side:(Side)side
{
    if (self = [super init]) {
        _type = type;
        _side = side;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    Piece *newPiece = [[Piece allocWithZone:zone] initWithType:self.type side:self.side];
    newPiece.numMoves = self.numMoves;
    return newPiece;
}

@end
