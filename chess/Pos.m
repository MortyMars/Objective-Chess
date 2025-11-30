//
//  Pos.m
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#import "Pos.h"

@implementation Pos

-(id)initWithX:(int)x y:(int)y
{
    if (self = [super init]) {
        _x = x;
        _y = y;
    }
    return self;
}

+(Pos *)posWithX:(int)x y:(int)y
{
    return [[self alloc] initWithX:x y:y];
}

-(BOOL)isEqual:(id)object
{
    if ([object class] != [self class]) return NO;
    if (self.x == ((Pos *)object).x && self.y == ((Pos *)object).y) return YES;
    return NO;
}

-(NSUInteger)hash
{
    return self.y * 8 + self.x;
}

-(id)copyWithZone:(NSZone *)zone
{
    Pos *pos = [[Pos allocWithZone:zone] initWithX:self.x y:self.y];
    return pos;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"(%d, %d)",self.x,self.y];
}
@end
