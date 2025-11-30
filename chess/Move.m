//
//  Move.m
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import "Move.h"
#import "Piece.h"
#import "Pos.h"

@implementation Move

-(id)initWithStart:(Pos *)start dest:(Pos *)dest
{
    if (self = [super init]) {
        _start = start;
        _dest = dest;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    Move *newMove = [[Move allocWithZone:zone] initWithStart:self.start dest:self.dest];
    return newMove;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"[move: %@ to %@]",self.start,self.dest];
}

@end
