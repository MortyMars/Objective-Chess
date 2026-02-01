//  RuleBook.m
//  chess
//  Created by Andrew Wang on 15/07/2013,
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

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
   +(NSSet *)PosLegalesForPiece:(Piece *)piece atPos:(Pos *)pos inBoard:(ChessBoard *)board
   {
      NSMutableSet *PosAcceptees = [[NSMutableSet alloc] init];
      
      // direction du déplacement d'une TOUR ou de la DAME --------------------------------------------------
      if (piece.type == Tour || piece.type == Dame) {
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:1 dy:0 board:board]];    // à droite
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:-1 dy:0 board:board]];   // à gauche
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:0 dy:1 board:board]];    // devant
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:0 dy:-1 board:board]];   // derrière
      }
      
      // direction du déplacement d'un FOU ou de la DAME ----------------------------------------------------
      if (piece.type == Fou || piece.type == Dame) {
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:1 dy:1 board:board]];    // au NE
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:-1 dy:1 board:board]];   // au NO
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:1 dy:-1 board:board]];   // au SE
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:-1 dy:-1 board:board]];  // au SO
      }
      
      // déplacement du ROI ---------------------------------------------------------------------------------
      if (piece.type == Roi) {
         // déplacement normal
         for (int x = pos.x - 1; x <= pos.x + 1; x++) {
            for (int y = pos.y - 1; y <= pos.y + 1;y++) {
               if (x >= 0 && y >= 0 && x < 8 && y < 8) {
                  if (x != pos.x || y != pos.y) {
                     [PosAcceptees addObject:[Pos posWithX:x y:y]];
                  }
               }
            }
         }
         
         // ROQUE
         // Le schéma de déplact des pièces dépend de l'orientation de l'échiquier, et donc de sideJoueur
         // Cas 1 - Les Blancs sont au bas de l'écran (car le joueur joue les Blancs)
         if (sideJoueur == sideWhite) {
            if (piece.numMoves == 0) {
               Piece *rightRook = [board piece_colX:7 rangY:pos.y];
               Piece *leftRook = [board piece_colX:0 rangY:pos.y];
               
               // si petit roque : le Roi en 4, Blanc ou Noir, va en 6
               if (rightRook && rightRook.numMoves == 0) {
                  if (![board piece_colX:6 rangY:pos.y] && ![board piece_colX:5 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:6 y:pos.y]];
               }
               
               // si grand roque : le Roi en 4, Blanc ou Noir, va en 2
               if (leftRook && leftRook.numMoves == 0) {
                  if (![board piece_colX:3 rangY:pos.y] && ![board piece_colX:2 rangY:pos.y] && ![board piece_colX:1 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:2 y:pos.y]];
               }
            }
         }
         // Cas 2 - Ce sont les Noirs qui sont au bas de l'écran (le joueur joue les Noirs)
         if (sideJoueur == sideBlack) {
            if (piece.numMoves == 0) {
               Piece *rightRook = [board piece_colX:7 rangY:pos.y];
               Piece *leftRook = [board piece_colX:0 rangY:pos.y];
               
               // si petit roque : le Roi en 3, blanc ou noir, va en 1
               if (rightRook && rightRook.numMoves == 0) {
                  if (![board piece_colX:2 rangY:pos.y] && ![board piece_colX:1 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:1 y:pos.y]];
               }
               
               // si grand roque : le Roi en 3, blanc ou noir, va en 5
               if (leftRook && leftRook.numMoves == 0) {
                  if (![board piece_colX:4 rangY:pos.y] && ![board piece_colX:5 rangY:pos.y] && ![board piece_colX:6 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:5 y:pos.y]];
               }
            }
         }
         // Fin de ROQUE
      } // Fin de déplacement du ROI
      
      // déplacement du CAVALIER ----------------------------------------------------------------------------
      if (piece.type == Cava) {
         // chaque test permet de vérifier que le cavalier n'est pas trop près
         // du bord de l'échiquier (la bande) pour permettre le déplacement
         if (pos.x >= 1 && pos.y >= 2)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 1 y:pos.y - 2]];  // Le cavalier a 8 coups
         if (pos.x >= 2 && pos.y >= 1)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 2 y:pos.y - 1]];  // possibles à chaque fois
         if (pos.x >= 2 && pos.y <= 6)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 2 y:pos.y + 1]];  // La liste exhaustive
         if (pos.x >= 1 && pos.y <= 5)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 1 y:pos.y + 2]];  // en est détaillée ici
         if (pos.x <= 6 && pos.y >= 2)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 1 y:pos.y - 2]];  // dans ces huits déplacements
         if (pos.x <= 5 && pos.y >= 1)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 2 y:pos.y - 1]];  // permis tant que
         if (pos.x <= 5 && pos.y <= 6)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 2 y:pos.y + 1]];  // la pièce reste sur
         if (pos.x <= 6 && pos.y <= 5)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 1 y:pos.y + 2]];  // l'échiquier
      }
      
      // déplacement du PION --------------------------------------------------------------------------------
      if (piece.type == Pion) {
         
         int dir;
         if (sideJoueur == sideWhite) {
            dir = (piece.side == sideWhite) ? 1 : -1;   // Les pions JOUEUR se déplacent vers le "haut"
            // les pions IA vers le "bas"
         }
         else {
            dir = (piece.side == sideWhite) ? -1 : 1;
         }
         
         Pos *dest = [Pos posWithX:pos.x y:pos.y + dir];
         if (![board pieceAtPos:dest]) {
            [PosAcceptees addObject:dest];
            
            // déplacement possible de deux cases au premier coup
            dest = [Pos posWithX:pos.x y:pos.y + 2 * dir];
            if (piece.numMoves == 0 && ![board pieceAtPos:dest])
               [PosAcceptees addObject:dest];
         }
         
         // déplacement en prenant une pièce
         Pos *posLeft = [Pos posWithX:pos.x - 1 y:pos.y + dir];
         Pos *posRight = [Pos posWithX:pos.x + 1 y:pos.y + dir];
         Piece *capturedPieceLeft = [board pieceAtPos:posLeft];
         Piece *capturedPieceRight = [board pieceAtPos:posRight];
         
         if (capturedPieceLeft) {
            if (capturedPieceLeft.side != piece.side) {
               [PosAcceptees addObject:posLeft];
            }
         }
         if (capturedPieceRight) {
            if (capturedPieceRight.side != piece.side) {
               [PosAcceptees addObject:posRight];
            }
         }
         
         /* MCN - GESTION DES POSITIONS SUPPLÉMENTAIRES ADMISES DANS LES CONDITIONS DE LA PRISE "EN PASSANT"
         On gère ici l'ajout du déplacement particulier autorisé pour un pion lors d'une prise en passant,
         mais pas la prise elle-même, qui devra être gérée ailleurs (dans PerformMove ça conviendrait bien,
         comme c'est déjà le cas du roque, certes d'une façon différente...)
         NOTER que le code qui traitera la prise en passant -avec la prise de la pièce elle-même et la
         notation 'e.p.' ajoutée au coup- devra préalablement identifier le move utilisant cette prise.
         Pour cette identification formelle il pourra être utile, sans s'engouffrer dans des tests
         compliqués, d'exploiter la particularité du move, à savoir que c'est le seul cas de déplacement
         du pion 'en biais' sans qu'il y ait une pièce sur la case destination...
         Cas1 : orientation du board avec les blancs en bas */
         if (sideJoueur == sideWhite) {
            // si le pion (on sait que s'en est un) est Blanc et est sur la 5ème rangée, ou Noir sur la 4ème
            if (((piece.side == sideWhite)&&(pos.y == 4)) || ((piece.side == sideBlack)&&(pos.y == 3))) {
               // si la dernière pièce jouée est un pion...
               // de la couleur adverse...
               // qui a avancé de 2 cases...
               // et qui se trouve à coté du pion...
              if (([board pieceAtPos:board.lastMove.dest].type == Pion) &&
                  ([board pieceAtPos:board.lastMove.dest].side != piece.side) &&
                  (abs(board.lastMove.dest.y - board.lastMove.start.y) > 1)   &&
                  (abs(board.lastMove.dest.x - pos.x) == 1 )) {
               
                     // ...alors on valide case de G ou de D, en AV pour le Joueur et en AR pour l'IA
                     Pos *posG = [Pos posWithX:board.lastMove.dest.x y:((board.lastMove.start.y + board.lastMove.dest.y)/2)];
                     [PosAcceptees addObject:posG];
               }
            }
         }
         // Cas2 : orientation du board avec les Noirs en bas
         else if (sideJoueur == sideBlack) {
            // si le pion (on sait que s'en est un) est Noir et est sur la 5ème rangée, ou Blanc sur la 4ème
            if (((piece.side == sideBlack)&&(pos.y == 4)) || ((piece.side == sideWhite)&&(pos.y == 3))) {
               // si la dernière pièce jouée est un pion...
               // de la couleur adverse...
               // qui a avancé de 2 cases...
               // et qui se trouve à coté du pion
              if (([board pieceAtPos:board.lastMove.dest].type == Pion) &&
                  ([board pieceAtPos:board.lastMove.dest].side != piece.side) &&
                  (abs(board.lastMove.dest.y - board.lastMove.start.y) > 1)   &&
                  (abs(board.lastMove.dest.x - pos.x) == 1 )) {
               
                     // ...alors on valide case de G ou de D, en AV pour le Joueur et en AR pour l'IA
                     Pos *posG = [Pos posWithX:board.lastMove.dest.x y:((board.lastMove.start.y + board.lastMove.dest.y)/2)];
                     [PosAcceptees addObject:posG];
               }
            }
         }
         // MCN - Fin de gestion de la prise en passant
         
      }  // Fin de paramétrage du déplacement du Pion --------------------------------------------------
      
      /* Il faut maintenant enlever de ce jeu des déplacements acceptés, toutes les cases occupées par
      des pièces de la même couleur que la pièce objet du calcul. En effet, on peut s'accaparer un
      emplacement occupé par une pièce ennemie, en la prenant, mais ça n'est pas possible avec une pièce
      de sa propre couleur */
      NSMutableSet *aSupprimer1 = [[NSMutableSet alloc] init];
      for (Pos *posTest1 in PosAcceptees)
      {
         if ([board pieceAtPos:posTest1].side == piece.side)
         {
            [aSupprimer1 addObject:posTest1];
         }
      }
      [PosAcceptees minusSet:aSupprimer1];
      
      //°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
      /* Suppression des positions générant la mise en échec de son propre roi */
      NSMutableSet *aSupprimer2 = [[NSMutableSet alloc] init];
      for (Pos *posTest2 in PosAcceptees)
      {
         Move *movTest2 = [[Move alloc]initWithStart:pos Dest:posTest2];
         ChessBoard * boardForTest = board.copy;
         [boardForTest PerformMove:movTest2];
         if ([self TestEchecRoiSideSAR:piece.side inBoard:boardForTest] == YES)
         {
            [aSupprimer2 addObject:posTest2];
         }
      }
      [PosAcceptees minusSet:aSupprimer2];
      //°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
      
      // Finalement, après traitement complet, on retourne le jeu de toutes les positions possibles
      return PosAcceptees;
   }  // FIN de 'PosLegalesForPiece'



   // ==================================================================================================
   // MCN - Méthode de Classe Quasi-Clone de 'PosLegalesForPiece' en version SAR, càd sans appel récursif
   // Elle est appelée PAR 'TestEchecRoiSideSAR' pour y déterminer le jeu des position acceptées nécessaire
   // au test de mise en échec
   // Plutôt que de faire appel à cette version renommée on aurait pu copier le code dans TestEchecRoiSide,
   // mais le code est un peu plus aéré et la façon, peu glorieuse, est plus transparente
   // Cette présente version, utilisée pour obtenir le jeu PosAcceptee brut, n'intègre pas la supp des pos
   // créant une mise en échec de son propre roi (elle intègre 'aSupprimer1' mais pas 'aSupprimer2')
   +(NSSet *)PosLegalesForPieceSAR:(Piece *)piece atPos:(Pos *)pos inBoard:(ChessBoard *)board
   {
      NSMutableSet *PosAcceptees = [[NSMutableSet alloc] init];
      
      // direction du déplacement d'une TOUR ou de la DAME --------------------------------------------------
      if (piece.type == Tour || piece.type == Dame) {
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:1 dy:0 board:board]];    // à droite
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:-1 dy:0 board:board]];   // à gauche
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:0 dy:1 board:board]];    // devant
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:0 dy:-1 board:board]];   // derrière
      }
      
      // direction du déplacement d'un FOU ou de la DAME ----------------------------------------------------
      if (piece.type == Fou || piece.type == Dame) {
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:1 dy:1 board:board]];    // au NE
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:-1 dy:1 board:board]];   // au NO
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:1 dy:-1 board:board]];   // au SE
         [PosAcceptees unionSet:[self SearchInDirection:pos dx:-1 dy:-1 board:board]];  // au SO
      }
      
      // déplacement du ROI ---------------------------------------------------------------------------------
      if (piece.type == Roi) {
         // déplacement normal
         for (int x = pos.x - 1; x <= pos.x + 1; x++) {
            for (int y = pos.y - 1; y <= pos.y + 1;y++) {
               if (x >= 0 && y >= 0 && x < 8 && y < 8) {
                  if (x != pos.x || y != pos.y) {
                     [PosAcceptees addObject:[Pos posWithX:x y:y]];
                  }
               }
            }
         }
         
         // ROQUE
         // Le schéma de déplacement des pièces dépend de l'orientation de l'échiquier, et donc de sideJoueur
         // Cas 1 - Les Blancs sont au bas de l'écran (car le joueur joue les Blancs)
         if (sideJoueur == sideWhite) {
            if (piece.numMoves == 0) {
               Piece *rightRook = [board piece_colX:7 rangY:pos.y];
               Piece *leftRook = [board piece_colX:0 rangY:pos.y];
               
               // petit roque
               if (rightRook && rightRook.numMoves == 0) {
                  if (![board piece_colX:6 rangY:pos.y] && ![board piece_colX:5 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:6 y:pos.y]];
               }
               
               // grand roque
               if (leftRook && leftRook.numMoves == 0) {
                  if (![board piece_colX:3 rangY:pos.y] && ![board piece_colX:2 rangY:pos.y] && ![board piece_colX:1 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:2 y:pos.y]];
               }
            }
         }
         // Cas 2 - Ce sont les Noirs qui sont au bas de l'écran (le joueur joue les Noirs)
         if (sideJoueur == sideBlack) {
            if (piece.numMoves == 0) {
               Piece *rightRook = [board piece_colX:7 rangY:pos.y];
               Piece *leftRook = [board piece_colX:0 rangY:pos.y];
               
               // petit roque
               if (rightRook && rightRook.numMoves == 0) {
                  if (![board piece_colX:2 rangY:pos.y] && ![board piece_colX:1 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:1 y:pos.y]];
               }
               
               // grand roque
               if (leftRook && leftRook.numMoves == 0) {
                  if (![board piece_colX:4 rangY:pos.y] && ![board piece_colX:5 rangY:pos.y] && ![board piece_colX:6 rangY:pos.y])
                     [PosAcceptees addObject:[Pos posWithX:5 y:pos.y]];
               }
            }
         }
         // Fin de ROQUE
      } // Fin de déplacement du ROI
      
      // déplacement du CAVALIER -----------------------------------------------------------------------
      if (piece.type == Cava) {
         // chaque test permet de vérifier que le cavalier n'est pas trop près
         // du bord de l'échiquier (la bande) pour permettre le déplacement
         if (pos.x >= 1 && pos.y >= 2)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 1 y:pos.y - 2]];  // Le cavalier a 8 coups
         if (pos.x >= 2 && pos.y >= 1)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 2 y:pos.y - 1]];  // possibles à chaque fois
         if (pos.x >= 2 && pos.y <= 6)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 2 y:pos.y + 1]];  // La liste exhaustive
         if (pos.x >= 1 && pos.y <= 5)
            [PosAcceptees addObject:[Pos posWithX:pos.x - 1 y:pos.y + 2]];  // en est détaillée ici
         if (pos.x <= 6 && pos.y >= 2)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 1 y:pos.y - 2]];  // dans ces huits déplacements
         if (pos.x <= 5 && pos.y >= 1)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 2 y:pos.y - 1]];  // permis tant que
         if (pos.x <= 5 && pos.y <= 6)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 2 y:pos.y + 1]];  // la pièce reste sur
         if (pos.x <= 6 && pos.y <= 5)
            [PosAcceptees addObject:[Pos posWithX:pos.x + 1 y:pos.y + 2]];  // l'échiquier
      }
      
      // déplacement du PION ---------------------------------------------------------------------------
      if (piece.type == Pion) {
         
         int dir;
         if (sideJoueur == sideWhite) {
            dir = (piece.side == sideWhite) ? 1 : -1;   // Les pions JOUEUR se déplacent vers le "haut"
                                                        // les pions IA vers le "bas"
         }
         else {
            dir = (piece.side == sideWhite) ? -1 : 1;
         }
         
         Pos *dest = [Pos posWithX:pos.x y:pos.y + dir];
         if (![board pieceAtPos:dest]) {
            [PosAcceptees addObject:dest];
            
            // déplacement possible de deux cases au premier coup
            dest = [Pos posWithX:pos.x y:pos.y + 2 * dir];
            if (piece.numMoves == 0 && ![board pieceAtPos:dest])
               [PosAcceptees addObject:dest];
         }
         
         // déplacement en prenant une pièce
         Pos *posLeft = [Pos posWithX:pos.x - 1 y:pos.y + dir];
         Pos *posRight = [Pos posWithX:pos.x + 1 y:pos.y + dir];
         Piece *capturedPieceLeft = [board pieceAtPos:posLeft];
         Piece *capturedPieceRight = [board pieceAtPos:posRight];
         
         if (capturedPieceLeft) {
            if (capturedPieceLeft.side != piece.side) {
               [PosAcceptees addObject:posLeft];
            }
         }
         if (capturedPieceRight) {
            if (capturedPieceRight.side != piece.side) {
               [PosAcceptees addObject:posRight];
            }
         }
         
         // TODO: Gérer la prise "en passant"
         // Il faut détecter que le pion adverse à coté duquel on se trouve immédiatement
         // vient d'avancer de deux cases (c'est donc forcément son premier déplacement)
      }  // Fin de paramétrage du déplacement des pièces -----------------------------------------------
      
      /* Il faut maintenant enlever de ce jeu des déplacements acceptés, toutes les cases occupées par des
      pièces de la même couleur que la pièce objet du calcul. En effet, on peut s'accaparer un emplacement
      occupé par une pièce ennemie, en la prenant, mais ça n'est pas possible avec une pièce de sa propre
      couleur */
      NSMutableSet *aSupprimer1 = [[NSMutableSet alloc] init];
      for (Pos *posTest1 in PosAcceptees)
      {
         if ([board pieceAtPos:posTest1].side == piece.side)
         {
            [aSupprimer1 addObject:posTest1];
         }
      }
      [PosAcceptees minusSet:aSupprimer1];
      
      // Finalement, après traitement complet, on retourne le jeu de toutes les positions possibles
      return PosAcceptees;
   }  // FIN de 'PosLegalesForPieceSAR'



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
