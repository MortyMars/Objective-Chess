//  RuleBook.m
//  chess
//  Created by Andrew Wang on 15/07/2013,
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026

//  CLASSE DÉFINISSANT LES RÈGLES DE DÉPLACEMENT DES PIÈCES SUR L'ÉCHIQUIER

#import "RuleBook.h"
#import "ChessBoard.h"



@implementation RuleBook

   // ==================================================================================================
   // Méthode de Classe - DÉFINITION DU JEU DES DÉPLACEMENTS ADMIS POUR CHAQUE TYPE DE PIÈCE
   // Le principe de la méthode est de créer un objet NSSet et de le "remplir", si nécessaire en plusieurs
   // étapes, avec les déplacements autorisés pour la pièce concernée
   // Contrairement à son quasi clone 'PosLegalesForPieceSAR' cette méthode intègre la suppression des
   // positions générant la mise en échec de son Roi
   +(NSSet<Pos *> *)PosLegalesForPiece:(Piece *)piece
                                 atPos:(Pos *)pos
                               inBoard:(ChessBoard *)board
   {
      NSMutableSet<Pos *> *result = [NSMutableSet set];
      
      NSMutableArray<Move *> *moves = [NSMutableArray arrayWithCapacity:32];
      
      // Génération moderne
      [maMinimax GenMovesForSide:piece.side board:board into:moves];
      
      for (Move *m in moves) {
         
         // Ce coup concerne-t-il la pièce demandée ?
         if (m.start.x != pos.x || m.start.y != pos.y)
            continue;
         
         // Vérification légale via make/unmake
         MoveState st = [board makeMove:m];
         
         BOOL illegal = [maMinimax IsKingInCheck:piece.side board:board];
         [board unmakeMove:m state:st];
         
         if (illegal)
            continue;
         
         // Coup légal → on ajoute la destination
         [result addObject:m.dest];
      }
      
      return result;
   }


   // ==================================================================================================
   // MISE À JOUR NEW ENGINE (MÀJNE)
   // Méthode de Classe Quasi-Clone de 'PosLegalesForPiece' en version SAR, càd sans appel récursif
   // Elle est appelée PAR 'TestEchecRoiSideSAR' pour y déterminer le jeu des position acceptées nécessaire
   // au test de mise en échec
   // Plutôt que de faire appel à cette version renommée on aurait pu copier le code dans TestEchecRoiSide,
   // mais le code est un peu plus aéré et la façon, peu glorieuse, est plus transparente
   // Cette présente version, utilisée pour obtenir le jeu PosAcceptee brut, n'intègre pas la supp des pos
   // créant une mise en échec de son propre roi (elle intègre 'aSupprimer1' mais pas 'aSupprimer2')
   +(NSSet<Pos *> *)PosLegalesForPieceSAR:(Piece *)piece
                                    atPos:(Pos *)pos
                                  inBoard:(ChessBoard *)board
   {
      NSMutableSet<Pos *> *result = [NSMutableSet set];
      
      NSMutableArray<Move *> *moves = [NSMutableArray arrayWithCapacity:32];
      
      // Génération moderne
      [maMinimax GenMovesForSide:piece.side board:board into:moves];
      
      for (Move *m in moves) {
         
         // Ce coup concerne-t-il la pièce demandée ?
         if (m.start.x != pos.x || m.start.y != pos.y)
            continue;
         
         // Vérification légale via make/unmake
         MoveState st = [board makeMove:m];
         
         BOOL illegal = [maMinimax IsKingInCheck:piece.side board:board];
         [board unmakeMove:m state:st];
         
         if (illegal)
            continue;
         
         // Coup légal → on ajoute la destination
         [result addObject:m.dest];
      }
      
      return result;
   }


   // ==================================================================================================
   // Création d'un jeu de cases acceptées dans une direction donnée, dénommé "ligneDeCases"
   // Cette méthode n'est utile que pour les pièces à grands déplacements et n'est appelée (cf. plus haut)
   // que dans le présent fichier RuleBook.m
   // Elle allège le code de détermination des déplacements acceptés pour la Dame, la Tour, et le Fou
   +(NSSet *)SearchInDirection:(Pos *)start
                            dx:(int)dx
                            dy:(int)dy
                         board:(ChessBoard *)board
   {
      NSMutableSet *ligneDeCases = [[NSMutableSet alloc] initWithCapacity:8];
      
      int x = start.x, y = start.y;
      
      do {
         x += dx;
         y += dy;
         
         // le numéro de la ligne et de la colonne doit être compris entre 0 et 7
         if (x < 0 || y < 0 || x > 7 || y > 7) break;
         
         Pos *pos = [Pos posWithX:x y:y];        // définition de la nouvelle position
         [ligneDeCases addObject:pos];           // on ajoute la position nouvelle au jeu des possibilités
      } while (![board piece_colX:x rangY:y]);   // ...tant qu'il n'y a pas de pièce en [x,y]
      
      // On retourne la ligne de cases autorisées, ligne qui sera ajoutée au jeu des pos possibles
      return ligneDeCases;
   } // FIN de 'SearchInDirection'


   // ==================================================================================================
   // MCN - Méthode de Classe Quasi-Clone de [Minimax TestEchecRoiSide] en version SAR (sans appel récursif)
   // Elle est appelée dans 'PosLegalesForPiece' et appelle une version renommée 'PosLegalesForPieceSAR'
   // pour éviter l'appel récursif qui plante le programme
   +(BOOL)TestEchecRoiSideSAR:(Side)side inBoard:(ChessBoard *)board
   {
      BOOL roiSideEnEchec = NO;
      //NSMutableSet *movesSideAdv = [[NSMutableSet alloc] init];
      Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      
      // On parcourt chaque case du 'board' courant, à la recherche des pièces adverses (càd 'otherSide)
      // et pour chacune d'elle on vérifie chacune de ses destinations possibles>>
      for (int x = 0; x < 8; x++)
      {
         for (int y = 0; y < 8; y++)
         {
            Pos *pos = [Pos posWithX:x y:y];
            Piece *pieceAdv = [board piece_colX:x rangY:y];
            if (pieceAdv)
            {
               if (pieceAdv.side == otherSide)
               {
                  NSSet *PosAcceptees = [RuleBook PosLegalesForPieceSAR:pieceAdv atPos:pos inBoard:board];
                  for (Pos *possibleDest in PosAcceptees)
                  {
                     Move *moveSideAdv = [[Move alloc] initWithStart:pos Dest:possibleDest];
                     //[movesSideAdv addObject:moveSideAdv];
                     
                     // DÉTECTION MISE EN ÉCHEC  >>et sur chacune de ces cases destinations on regarde
                     // si on trouve notre Roi, auquel cas nous sommes en situation d'Échec :-(
                     Piece *piece = [board piece_colX:moveSideAdv.dest.x rangY:moveSideAdv.dest.y];
                     if (piece.type == Roi)
                     {
                        if (piece.side == side)
                        {
                           roiSideEnEchec = YES;
                           //NSLog(@"\nLes %@ SONT Échec",(side==1)?@"Noirs":@"Blancs");
                           return roiSideEnEchec;
                        } // fin if
                     } // fin if
                  }  // fin for
               }  // fin if
            } // fin if
         } // fin for y
      } // fin for x
      return roiSideEnEchec;
   } // Fin de Méthode 'TestEchecRoiSideSAR'


@end
