// Move.h
// chess
// Created by Andrew Wang on 15/07/2013,
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026

#import "Piece.h"

@class Piece,Pos;  /* @class permet d'indiquer au compilateur que les classes "Piece" et "Pos" existent et
                    sont déclarées ailleurs, ce qui permet d'éviter des #import bouclant sur eux-mêmes, en
                    particulier en cas de classe en appelant une autre, comme ici Move qui utilise Pos
                    NB : le rappel que Piece existe ne parait par contre pas pertinent ici... */

/* Déclaration de la Classe Move qui adopte le protocole NSCopying permettant
 de faire des copies d'objets Move, ...ce dont nous avons besoin            */
@interface Move : NSObject <NSCopying>

   // Propriétés de la classe (iVars publiques)
   @property (nonatomic, strong) Pos         *start;
   @property (nonatomic, strong) Pos         *dest;

   @property (nonatomic)         Square      fromSquare;
   @property (nonatomic)         Square      toSquare;

   @property (nonatomic, strong) Piece       *movingPiece;
   @property (nonatomic, strong) Piece       *capturedPiece;
   
   @property (nonatomic)         PieceType   oldType;       // type avant promotion
   @property (nonatomic)         PieceType   promotionType; // ✨ NOUVEAU : type cible (Dame par défaut)

   @property (nonatomic)         BOOL        isCapture;     // Ce move est-il une capture
   @property (nonatomic)         BOOL        givesCheck;    // Ce move provoque t-il une mise en échec
   @property (nonatomic)         BOOL        isCastling;    // Ce move est-il un roque
   @property (nonatomic)         BOOL        isPromotion;   // Ce move est-il une promotion de pion
   @property (nonatomic)         BOOL        wasPromotion;  // Ce move a t-il généré une promotion de pion
   @property (nonatomic)         BOOL        isEnPassant;   // Ce move est-il une prise e.p.

   @property (nonatomic)         int         orderingScore;

   
   // Méthode permettant d'en initialiser les valeurs
   -(id)initWithStart:(Pos *)start
                  Dest:(Pos *)dest;

   // ✨ méthode (de classe) de confort (sucre syntaxique)
   +(Move *)newMoveFromX:(int)x
                       Y:(int)y
                    ToNx:(int)nx
                      Ny:(int)ny;

   
   // Méthodes 'system'
   -(id) copyWithZone:(NSZone *)zone;
   -(NSString *) description;

   
   // Méthodes de transformations de 'Moves'
   +(Move *)opMove:(Move *) move;
   +(Move *)mirrorMove:(Move *) move;


@end
