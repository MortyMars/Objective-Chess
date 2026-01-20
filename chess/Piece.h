//  Piece.h
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020


#import "Util.h"


@interface Piece : NSObject <NSCopying> /* Le protocole NSCopying permettra de faire des copies d'objets
                                        Piece, ...ce dont nous avons besoin */
    
   @property (nonatomic) PieceType type;
   @property (nonatomic) Side side;
   @property (nonatomic) int numMoves;

   -(id) initWithType:(PieceType)type
                 side:(Side)side;

   -(id) copyWithZone:(NSZone *)zone;


@end
