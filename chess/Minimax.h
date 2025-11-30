//
//  Minimax.h
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "util.h"

@class Move, ChessBoard;
@interface Minimax : NSObject

+(Move *)bestMoveForSide:(Side)side board:(ChessBoard *)board;

@end
