//  Pos.m
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

#import "Pos.h"
#import "Util.h"


@implementation Pos

   // ==================================================================================================
   // Méthode d'instance ATTRIBUANT des coordonnées sur l'échiquier à un objet Pos
   -(id)initWithX:(int)x // méthode à 2 paramètres x et y
                y:(int)y // correspondant à la position de la pièce sur l'échiquier
   {
      if (self = [super init]) {
         _x = x;
         _y = y;
      }
      return self;
   }

   
   // ==================================================================================================
   // Méthode de classe RETOURNANT la position correspondant à des coordonnées sur l'échiquier
   +(Pos *)posWithX:(int)x // même construction que la méthode
                  y:(int)y // d'instance initWithX:y:
   {
      return [[self alloc] initWithX:x y:y];
   }

   
   // ==================================================================================================
   // Méthode d'instance définissant ce qu'est l'égalité entre deux positions (self et une autre pos)
   -(BOOL)isEqual:(id)object
   {
      if ([object class] != [self class]) return NO;
      if (self.x == ((Pos *)object).x && self.y == ((Pos *)object).y) return YES;
      return NO;
   }


   // ==================================================================================================
   // Méthode d'instance définissant un identifiant numérique unique pour chaque Pos de l'échiquier
   -(NSUInteger)hash
   {
      return self.y * 8 + self.x;
   }

   
   // ==================================================================================================
   // Méthode exigée par le protocole NSCopying dont hérite la classe Pos
   // Elle n'est pas appelée dans le code, mais est exécutée dès l'envoi d'un message copy sur un objet
   -(id)copyWithZone:(NSZone *)zone
   {
      Pos *pos = [[Pos allocWithZone:zone] initWithX:self.x y:self.y];
      return pos;
   }

   
   // ==================================================================================================
   // 'description' est une @property de NSObject, dont l'appel est implicite
   // Elle est surdéfinie ici pour nos besoins de notation des coups joués
   -(NSString *)description
   {
      /* La 'description' d'un objet Pos est définie ci-dessous en tant que NSString au format 'a1'
      Il est nécessaire de tenir cpte de l'orientation de l'échiquier, d'où le recours à 2 tableaux de
      valeurs différents : Absc1 (lettres croissantes de a à h) et Absc2 (lettres décroissantes de h à a)
      NB : Absc1 et Absc2 sont des variables globales définies dans 'Util.m'   */
      NSString *descriptRetournee;
      if      (sideJoueur == sideWhite)
                     descriptRetournee = [NSString stringWithFormat:@"%c%d", Absc1[self.x], self.y+1];
      else if (sideJoueur == sideBlack)
                     descriptRetournee = [NSString stringWithFormat:@"%c%d", Absc2[self.x], 8-self.y];
      
      return descriptRetournee;
   }

@end
