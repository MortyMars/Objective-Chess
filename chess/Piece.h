//
//  Piece.h
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "util.h"

@interface Piece : NSObject <NSCopying>

@property (nonatomic) PieceType type;
@property (nonatomic) Side side;
@property (nonatomic) int numMoves;

-(id)initWithType:(PieceType)type side:(Side)side;

@end
