//  MCNdiagramme.h
//  Chess
//  Created by MCN on 03/04/2022
//  Copyright © 2022 MCN. All rights reserved


#import "Minimax.h"

//typedef enum {Slash=('/'),_1,_2,_3,_4,_5,_6,_7,_8,p,r,n,b,q,k,P,R,N,B,Q,K} carValid;


@interface MCNdiagramme : NSView

   {  /* Création d'une variable d'instance de type NSOperation
      permettant un déroulement séquentiel des coups successifs */
      NSOperationQueue *maFileSerie;
      
      // Variable d'instance qualifiant de code FEN saisi
      bool codeFenOK;
   }

   -(IBAction)   SaisieCodeFEN:(id)sender;
   -(IBAction)   DiagrammeIAvsIA:(id)sender;


   -(NSString *) RecupCodeFEN;
   -(void)       TradFenEnView:(NSString *) stringFEN;
   -(void)       EffaceBoardBlancsEnBas:(ChessBoard *) board;
   -(void)       OkDeuxCasesPionsBoard:(ChessBoard *)board;
   -(void)       LireSecondPartStrFEN:(NSString *)secondStr;

   /* Définition de versions silencieuses (ou adaptées) de Méthodes d'autres classes permettant
   de rendre visibles les coups successifs d'une résolution de diagramme par l'IA contre l'IA */
   -(void)       SilentMakeIAMoveForSide:(Side)side
                                   Board:(ChessBoard *)board;
   
   +(NSString *) SilentTestEchecFavSide: (Side)side
                                  Board:(ChessBoard *)board;
   
   -(void)       SilentMajStatusBarViaMove:(Move *)move
                                 PrecBoard:(ChessBoard *)precBoard
                                  StrCheck:(NSString *)strCheck;
   
   +(void)       SilentNotifiePatMatDesSide:(Side)side
                                    onBoard:(ChessBoard*)board;

@end
