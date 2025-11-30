//
//  ChessView.h
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "util.h"

@class ChessBoard,Pos;
@interface ChessView : NSView
{
    ChessBoard *board;
    
    BOOL hasSelTile;
    Pos *selTile;
    NSSet *coverage;
}
@end
