//  ChessView.h
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

#import "Move.h"
#import "RuleBook.h"


@class ChessBoard, Pos;

@protocol ChessViewDelegate <NSObject>
   -(void)AlertMsgEchecSide:(Side)side;
@end

@interface ChessView : NSView
    
   {
      // Déclaration des variables d'instance utiles
      @public ChessBoard *liveBoard; // déclarée publique
      BOOL isThereTileSelected;
      Pos *selTile;
      NSSet *PosAcceptees;
      //@public BOOL uiFlipped; // ajout séparation UI / Moteur
   }

   @property (weak) id <ChessViewDelegate> delegate;

   @property BOOL uiFlipped;

   // Déclaration de méthodes devant être appelées à l'ext de la classe (dans ChessTests pour le coup...)
   -(id)   initWithFrame:(NSRect)frame;

   // dito pour méthodes MCN
   -(void) MakeIAMoveForSide:(Side)side Board:(ChessBoard *)board;
   
   -(void) MajStatusBarViaMove:(Move *)move
                     PrecBoard:(ChessBoard *)precBoard
                      StrCheck:(NSString *)strCheck;

   // rappel des autres méthodes
   -(void) drawBoard;
   -(void) mouseDown:(NSEvent *)theEvent;
   -(void) MakeComputerMove;
   -(void) drawRect:(NSRect)dirtyRect;

   // rappel des méthodes MCN
   -(void) MakeJoueurMoveVersDest:(Pos *) dest;

   +(NSString *)VisualIndicator:(int)evalWhitePOV;

   // Méthode de retournement du board pour l'UI
   -(int)engineXFromUIX:(int)x;
   -(int)engineYFromUIY:(int)y ;


@end



static inline int engineX(int uiX, BOOL flipped);

static inline int engineY(int uiY, BOOL flipped);

