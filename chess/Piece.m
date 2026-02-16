//  Piece.m
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

#import "Piece.h"
#import "ChessConfig.h"


@implementation Piece

   // ==================================================================================================
   // Méthode d'instance définissant une Pièce sur la base d'un type et d'une couleur
   -(id)initWithType:(PieceType)type
                side:(Side)side
   {
      if (self = [super init]) {
         _type = type;
         _side = side;
      }
      return self;
   }

   // ==================================================================================================
   // Méthode exigée par le Protocol NSCopying dont hérite la classe Piece
   // Elle n'est pas formellement appelée dans le code, mais s'active dès l'envoi d'un msg copy sur un objet
   -(id)copyWithZone:(NSZone *)zone
   {
      Piece *newPiece = [[Piece allocWithZone:zone] initWithType:self.type
                                                            side:self.side];
      newPiece.numMoves = self.numMoves;
      return newPiece;
   }


   // Méthode permettant un affichage des pièces en 'texte' clair plutôt qu'adresses de pointeurs
   - (NSString *)description
   {
      NSString *sideStr = (self.side == sideWhite) ? @"White" : @"Black";
      
      NSString *typeStr = @"?";
      switch (self.type) {
         case Roi:      typeStr = @"King";   break;
         case Dame:     typeStr = @"Queen";  break;
         case Tour:     typeStr = @"Rook";   break;
         case Fou:      typeStr = @"Bishop"; break;
         case Cava:     typeStr = @"Knight"; break;
         case Pion:     typeStr = @"Pawn";   break;
         case Invalide: typeStr = @"Invalid";break;
      }
      
      return [NSString stringWithFormat:@"<%@ %@>", sideStr, typeStr];
   }



@end
