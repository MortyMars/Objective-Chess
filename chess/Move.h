//
//  Move.h
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Piece,Pos;
@interface Move : NSObject <NSCopying>

@property (nonatomic, strong) Pos *start;
@property (nonatomic, strong) Pos *dest;

-(id)initWithStart:(Pos *)start dest:(Pos *)dest;

@end
