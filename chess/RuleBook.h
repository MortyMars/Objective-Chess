//
//  RuleBook.h
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "util.h"

@class Piece,ChessBoard,Pos;
@interface RuleBook : NSObject

+(NSSet *)coverageForPiece:(Piece *)piece atPos:(Pos *)pos inBoard:(ChessBoard *)board;
@end
