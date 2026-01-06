//  MCNmoveToStr.m
//  Chess
//
//  Created by MCN on 22/02/2022.
//  Copyright © 2022 MCN. All rights reserved.

#import "MCNmoveToStr.h"


   /* Classe créée afin d'abriter les Méthodes implémentées
      1) pour EXTRAIRE d'un 'Move' le déplacement exécuté
   et 2) pour le TRANSFORMER en une NSString aussi compréhensible que proche de la 'Notation algébrique réversible'
   Elles sont utilisées pour l'affichage de la liste des coups joués successivement par l'IA et par le Joueur

   Les deux méthodes sont appelées l'une après l'autre :
        - dans ChessBoard.m lors du premier coup de l'IA lorsqu'elle a les blancs
        - dans ChessView.m à chaque coup Joueur, qu'il ait les blancs ou les noirs
        - dans ChessView.m encore, à chaque coup de l'IA quand elle a les noirs
          et à partir du deuxième coup quand elle a les blancs  */

@implementation MCNmoveToStr


   //***************************************************************************************************
   // Méthode de classe
   // MCN - Extraction Transformation
   +(NSMutableString *) ConvertEnStringMove:(Move *) move
                                   PromPion:(NSString *) promPion
                                   StrEchec:(NSString *) strEchec
                                      Board:(ChessBoard *) board;
   {
      /* TRANSFORMATION de la chaine contenue dans 'move' en notation plus standard
       'move' porte l'info mais n'est pas une NSString
       'moveProv' valeur intermédiaire pour faciliter la lisibilité du code
       'moveMCN' est la chaine résultant de la transformation successive des caractères et de leur concaténation */
      
      // moveProv récupère le coup au format 'Cd3xFe5'
      NSString *moveProv = [self Modif00EnA1:move surBoard:board];
      
      // Initialisation de moveMCN à la valeur de la description du coup proprement dit
      NSMutableString* moveMCN = [NSMutableString stringWithFormat:@"%@",moveProv];
      
      // Ajout de l'indication de prise et 'en passant' si c'est le cas
      // sachant que dans ce cas, le dernier move ajouté à la chaine est forcément de la forme 'd5-e6'
      if (enPassant) {
         // Passage par une NSString provisoire
         NSString *moveMCNprov;
         // remplacement du dernier '-' par un 'x' signalant une prise de pièce, l'ajout devient 'd5xe6'
         moveMCNprov = [moveMCN stringByReplacingCharactersInRange:NSMakeRange((moveMCN.length-3), 1) withString:@"x"];
         // assignation de la string obtenue à 'moveMCN'
         moveMCN = [moveMCNprov mutableCopy];
         // ajout de l'indication e.p., pour donner finalement 'd5xe6 e.p.'
         [moveMCN appendString:@" e.p."];
      }

      // Ajout de la promotion éventuelle d'un pion joué
      [moveMCN appendString:promPion];
      
      // Ajout de l'indication Échec / Échec et Mat, par exploitation du paramètre 'strEchec'
      NSString *advEstEnEchec = strEchec;
      if ([advEstEnEchec isEqual:@"Mat"]) {
         [moveMCN appendString:@"#"];
      }
      else if ([advEstEnEchec isEqual:@"Echec"]) {
         if       (checkCount == 1)    [moveMCN appendString: @"+"];
         else if  (checkCount  > 1)    [moveMCN appendString:@"++"];
      }
      
      // Ajout de caractères 'espace' pour aligner verticalement les coups des Noirs
      if([moveMCN length] < 8) {
         while ([moveMCN length] != 8) [moveMCN appendString:@" "];
      }
      
      // FIN TRANSFORMATION
      return moveMCN;
   } // Fin de ConvertEnStringMove


   //***************************************************************************************************
   // Méthode de classe
   // Mise en forme de la suite des coups, pour avoir deux déplacements par ligne (Blancs puis Noirs)
   +(void) MettreEnFormeChaine:(NSString *) moveToStr
                  Protagoniste:(NSString *) strJ_IA;
   {
      /* AJOUT du coup JOUEUR à la liste de ceux déjà joués
      après ajout d'un retour chariot pour un nouveau coup Blancs
      ou après ajout d'espaces pour un nouveau coup Noirs
      
      Cas du 1er demi-coup de la partie (des Blancs donc) quand il est joué par le Joueur
      sachant que le premier demi-coup quand il est joué par l'IA est géré par PremCoupAIBlancs */
      if ((sideCourant == sideWhite) && [stringCoupsPartie isEqual:@""]) {
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"1.\t"];
      }
      // Cas des autres demi-coups joués par les Blancs
      else if (sideCourant == sideWhite)  {
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:
                              [NSString stringWithFormat:@"\n%d.\t",numCoup]];
         numCoup = numCoup + 1; // incrémentation du numéro de coup, initialisé à 2 au départ
      }
      // Cas des demi-coups joués par les Noirs
      else if (sideCourant == sideBlack) {
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\t\t"];
      }
      
      // Ajout du coup proprement dit, après la mise en forme
      stringCoupsPartie = [stringCoupsPartie stringByAppendingString:
                           [NSString stringWithFormat:@"%@ : %@", strJ_IA, moveToStr]];
      
      // Mise à jour du contrôle 'txtView' affichant la liste des coups
      [monMCNControleur MaJtxtCoups];
      
   } // Fin de 'MettreEnFormeChaine'


   // **************************************************************************************************
   // Méthode de classe
   // Transforme la représentation des coups (1 , 1) vers (2 , 2) en a1-b2
   // La méthode est appelée par ConvertEnStringMove et par certains contrôle de NSLog
   +(NSString *)Modif00EnA1:(Move *)move surBoard:(ChessBoard*)board
   {
      NSString* movVerStr = @"";
      NSMutableString* strDuMove=[NSMutableString stringWithFormat:@"%@",movVerStr];
      
      // Test initial si roque ou pas, car si roque pas de notation compliquée : o-o ou o-o-o
      if (petitRoque || grandRoque) {
         [strDuMove appendString:(petitRoque) ? @"o-o     " : @"o-o-o   "];
      }
      else {
            // Il n'y a pas roque --> on s'oblige à la description complète du coup
            
            movVerStr = [NSMutableString stringWithFormat:@"%@",move];
            
            int typPrenante = [board pieceAtPos:move.start].type;
            int typPrise    = [board pieceAtPos:move.dest] .type;
            NSString *strType[6] = {@"",@"C",@"F",@"T",@"D",@"R"};
            
            movVerStr = [NSString stringWithFormat:@"%@",move]; //movVerStr reçoit le move au format NSString
            
            /* Ajout du type de la pièce
            NB : le type d'une pièce est issu d'une 'enum' ; c'est donc un indice dans une liste
            [typPrenante-1] permet d'accéder au bon indice dans le tableau  */
            if (typPrenante) [strDuMove appendString:strType[typPrenante-1]];
            
            // 1er cas - Le JOUEUR a les BLANCS
            if (sideJoueur == sideWhite) {
                  // Ajout de la case de départ
                  [strDuMove appendString:[movVerStr substringWithRange:NSMakeRange(0, 2)]];
                  
                  // Ajout de l'indication de prise ou pas, et si oui, de la piece prise
                  if (typPrise)
                       [strDuMove appendString:[@"x" stringByAppendingString:strType[typPrise-1]]];
                  else [strDuMove appendString: @"-"];
                  
                  // Ajout de la case destination
                  [strDuMove appendString:[movVerStr substringWithRange:NSMakeRange(3, 2)]];
            } // Fin de JOUEUR a les BLANCS
            
            // 2ème cas - Le JOUEUR a les NOIRS
            else {
                  // Ajout de la case départ
                  [strDuMove appendString:[movVerStr substringWithRange:NSMakeRange(0, 2)]];
                  
                  // Ajout de l'indication de prise ou pas, et si oui, de la piece prise
                  if (typPrise)
                       [strDuMove appendString:[@"x" stringByAppendingString:strType[typPrise-1]]];
                  else [strDuMove appendString: @"-"];
                  
                  // Ajout de la case destination
                  [strDuMove appendString:[movVerStr substringWithRange:NSMakeRange(3, 2)]];
            }   // Fin de JOUEUR a les NOIRS
      } // Fin de Else
      
      return strDuMove;
   } // Fin de Méthode 'MoveEnStr'


@end
