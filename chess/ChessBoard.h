//  ChessBoard.h
//  chess
//
//  Created by Andrew Wang on 15/07/2013
//  Completed by MCN on 2020
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "MCNmoveToStr.h"
#import "Pos.h"


@class Piece,Move, Pos;

/* Déclaration de la Classe ChessBoard qui dérive de NSObject et qui adopte le protocole <NSCopying>,
ce qui permettra notamment de faire des copies d'objets ChessBoard, ...ce dont nous avons besoin  */
@interface ChessBoard : NSObject <NSCopying>
   {
      /* Variable d'instance -tableau à 2 dimensions- désignant la pièce en case [x] [y]
       Déclarée publique pour pouvoir y accéder via l'opérateur '->' dans d'autres classes */
      @public Piece *pieceCase[8][8];
      
      /* Autres variables d'instances MCN, créées pour stocker les valeurs liées à la 'Status Bar' */
      @public NSString *strRoque;
      @public NSString *strCibleEP;
      @public int       nbDemis;
      @public int       nbEntiers;
   }

   // 'lastmove' est le dernier move réalisé, déclaré ici, mais défini dans 'PerformMove'
   @property (nonatomic, strong) Move *lastMove;

   // Méthodes d'instance
   -(id)         init;
   -(void)       SetupPieces;
   -(Piece *)    piece_colX:(int)x rangY:(int)y;
   -(Piece *)    pieceAtPos:(Pos *)pos;
   -(Piece *)    MovePieceDeStart:(Pos *)start ADest:(Pos *)dest;
   -(void)       PerformMove:(Move *)move;
   -(id)         copyWithZone:(NSZone *)zone;
   -(NSString *) description;

   // Ajout des Méthodes IB MCN liées à l'utilisation des menus
   -(IBAction)   NewPartieJoueurBlancs:(id)sender;
   -(IBAction)   NewPartieJoueurNoirs:(id)sender;
   -(IBAction)   RetournerBoard:(id)sender;

   // Ajout des Méthodes d'instance MCN
   -(void)       DefCouleurJoueur;  // désuette depuis refonte de l'UI et démarrage sur un échiquier vide
   -(void)       PremCoupAIBlancs;
   -(NSString *) SelectPromoPion:(Piece*)piece auRang:(int)rang;
   -(void)       CalculerStrRoque;
   -(void)       DeterminerCibleEP:(Move *)move;
   -(void)       CompterDemiCoups:(Move *)move;
   -(void)       ProposerNulle50Coups;
   -(void)       AlertePartieNulle;

@end
