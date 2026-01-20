//  Move.m
//  chess
//  Created by Andrew Wang on 15/07/2013,
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//  Updated by MCN in 2020

#import "Move.h"


@implementation Move

   //***************************************************************************************************
   // Méthode d'instance retournant un Move sur la base d'une position de départ et d'une position de
   // destination
   -(id)initWithStart:(Pos *)start
                 dest:(Pos *)dest
   {
      if (self = [super init]) {
         _start = start;
         _dest = dest;
      }
      return self;
   }

   // **************************************************************************************************
   // Méthode exigée par le Protocol NSCopying dont hérite la classe Move
   // Elle n'est pas formellement appelée dans le code, mais s'active dès l'envoi d'un msg copy sur un objet
   -(id)copyWithZone:(NSZone *)zone
   {
      Move *newMove = [[Move allocWithZone:zone] initWithStart:self.start dest:self.dest];
      return newMove;
   }


   //***************************************************************************************************
   // 'description' est une @property de NSObbject, dont l'appel est implicite
   // Elle est surdéfinie ici pour nos besoins d'affichage dans la console
   // et c'est à partir de cette base, que l'on traduira les moves en 'a1-b2'
   -(NSString *)description
   {
      // la 'description' de Move est définie en tant que NSString au format 'Pos>Pos', par exemple : 'e2>e4'
      return [NSString stringWithFormat:@"%@>%@",self.start,self.dest];
   }


@end
