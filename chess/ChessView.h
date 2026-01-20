//  ChessView.h
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

#import "Move.h"
#import "RuleBook.h"


@class ChessBoard, Pos;

@protocol ChessViewDelegate <NSObject>
   -(void)AlerteEchecRoiSide:(Side)side;
@end

@interface ChessView : NSView
    
   {
      // Déclaration des variables d'instance utiles
      @public ChessBoard *liveBoard; // déclarée public MCN (ligne originale : 'ChessBoard *board;')
      BOOL isThereTileSelected;
      Pos *selTile;
      NSSet *PosAcceptees;
   }

   @property (weak) id <ChessViewDelegate> delegate;

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


@end
