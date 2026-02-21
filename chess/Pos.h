// Pos.h
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Updated by MCN in 2020


@interface Pos : NSObject <NSCopying> /* Le protocole NSCopying permettra de faire des copies d'objets Pos,
                                      ...ce dont nous avons besoin  */
    
   @property (nonatomic, readonly) int x;
   @property (nonatomic, readonly) int y;

   +(Pos *)      posWithX:(int)x
                        y:(int)y;

   // Déclarations ajoutées pour rendre visibles certaines méthodes utilisées dans ChessTest
   -(id)         initWithX:(int)x
                         y:(int)y;

   // Rappel autres méthodes
   -(BOOL)       isEqual:(id)object;
   -(NSUInteger) hash;
   -(id)         copyWithZone:(NSZone *)zone;
   -(NSString *) description;


@end
