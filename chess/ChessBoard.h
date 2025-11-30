//
//  ChessBoard.h
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "util.h"

@class Piece,Pos,Move;
@interface ChessBoard : NSObject <NSCopying>
{
    Piece *board[8][8];
}

@property (nonatomic, strong) Move *lastMove;


-(void)setupPieces;

-(Piece *)pieceAtX:(int)x y:(int)y;
-(Piece *)pieceAtPos:(Pos *)pos;
-(Piece *)movePieceFrom:(Pos *)start to:(Pos *)dest;
-(void)performMove:(Move *)move;

@end
