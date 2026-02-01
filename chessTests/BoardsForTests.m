//
//  BoardsForTests.m
//  ChessTests
//
//  Created by MCN on 21/04/2022.
//  Copyright © 2022 MCN. All rights reserved.
//

#import "BoardsForTests.h"
//#import "ChessTests.h"


@implementation BoardsForTests

   // ==================================================================================================
   // Méthode non-test de configuration du board du Coup Du Berger
   +(ChessBoard *)ConfigBoardCoupDuBerger {
      
      
      //[ChessTests initBoardStd];
      
      sideJoueur = sideWhite;
      ChessBoard *testBoard = [[ChessBoard alloc]init];
      sideJoueur = sideWhite;
      sideIA = sideBlack;
      [testBoard SetupPieces];
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      monMCNControleur.maChessView->liveBoard = testBoard;
      
      //[self initBoardStd];
      
      
      
      // Puis mise en place du scénario à étudier par une série de moves
      Move *move1 = [[Move alloc]initWithStart:[Pos posWithX:4 y:1] Dest:[Pos posWithX:4 y:3]];
      [testBoard PerformMove:move1]; // e2-e4 Blancs
      Move *move2 = [[Move alloc]initWithStart:[Pos posWithX:4 y:6] Dest:[Pos posWithX:4 y:4]];
      [testBoard PerformMove:move2]; // e5-e7 Noirs
      Move *move3 = [[Move alloc]initWithStart:[Pos posWithX:3 y:0] Dest:[Pos posWithX:7 y:4]];
      [testBoard PerformMove:move3]; // Dd1-h5 Blancs
      Move *move4 = [[Move alloc]initWithStart:[Pos posWithX:1 y:7] Dest:[Pos posWithX:2 y:5]];
      [testBoard PerformMove:move4]; // Cb8-c6 Noirs
      Move *move5 = [[Move alloc]initWithStart:[Pos posWithX:5 y:0] Dest:[Pos posWithX:2 y:3]];
      [testBoard PerformMove:move5]; // Ff1-c4 Blancs
      Move *move6 = [[Move alloc]initWithStart:[Pos posWithX:6 y:7] Dest:[Pos posWithX:5 y:5]];
      [testBoard PerformMove:move6]; // Cg8-f6 Noirs
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard soumis à l'IA pour jouer le prochain coup Blancs : \n%@\n",testBoard);
      
      return testBoard;
   }



   // ==================================================================================================
   // Méthode non-test de configuration du board cas1 Mat en 10 coups
   +(ChessBoard *)ConfigBoardMatEn3Cas1 {
      /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 16 pièces,
       on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
       plein de moves
       CAS D'EXERCICE NUMÉRO 1 : Walter Browne - Victor Brond, Mar del Plata 1971 */
      
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
      
      // Effacement du board déjà construit
      for (int x=0; x < 8; x ++) {
         testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
         testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
         testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
         testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
         testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
         testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
         testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
         testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // Construction du nouveau board
      testBoard->pieceCase[1][2] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[2][3] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[5][3] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[7][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[1][2].numMoves = 1;
      testBoard->pieceCase[2][3].numMoves = 1;
      testBoard->pieceCase[5][3].numMoves = 1;
      
      testBoard->pieceCase[0][4] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[1][5] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[5][6] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[7][4] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[0][4].numMoves = 1;
      testBoard->pieceCase[1][5].numMoves = 1;
      testBoard->pieceCase[7][4].numMoves = 1;
      
      
      testBoard->pieceCase[7][6] = [[Piece alloc] initWithType:Fou      side:sideBlack];
      
      testBoard->pieceCase[5][5] = [[Piece alloc] initWithType:Tour     side:sideWhite];
      testBoard->pieceCase[6][0] = [[Piece alloc] initWithType:Tour     side:sideWhite];
      testBoard->pieceCase[4][7] = [[Piece alloc] initWithType:Tour     side:sideBlack];
      
      testBoard->pieceCase[0][0] = [[Piece alloc] initWithType:Dame     side:sideWhite];
      testBoard->pieceCase[2][1] = [[Piece alloc] initWithType:Dame     side:sideBlack];
      
      testBoard->pieceCase[7][5] = [[Piece alloc] initWithType:Roi      side:sideWhite];
      testBoard->pieceCase[5][7] = [[Piece alloc] initWithType:Roi      side:sideBlack];
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard cas n°1 soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      // Calcul de l'EvalBoard
      //[Minimax EvalBoardForSide:sideWhite board:testBoard];
      
      return testBoard;
   } // Fin board cas1


   // ==================================================================================================
   // Méthode non-test de configuration du board cas2 Mat en 10 coups
   +(ChessBoard *)ConfigBoardMatEn3Cas2 {
      /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 22 pièces,
       on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
       plein de moves
       CAS D'EXERCICE NUMÉRO 2 : Stian Johansen - Monika Machlik, Oslo 2013 */
      
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
      
      // Effacement du board déjà construit
      for (int x=0; x < 8; x ++) {
         testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
         testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
         testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
         testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
         testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
         testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
         testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
         testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // Construction new board
      testBoard->pieceCase[1][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[5][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[7][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[0][3] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[4][4] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[0][3].numMoves = 1;
      testBoard->pieceCase[4][4].numMoves = 1;
      
      testBoard->pieceCase[0][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[5][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[6][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[7][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[3][3] = [[Piece alloc] initWithType:Pion side:sideBlack];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup au pion avancé :
      testBoard->pieceCase[3][3].numMoves = 1;
      
      testBoard->pieceCase[3][4] = [[Piece alloc] initWithType:Cava side:sideBlack];
      
      testBoard->pieceCase[1][4] = [[Piece alloc] initWithType:Fou  side:sideWhite];
      testBoard->pieceCase[5][5] = [[Piece alloc] initWithType:Fou  side:sideWhite];
      testBoard->pieceCase[1][3] = [[Piece alloc] initWithType:Fou  side:sideBlack];
      
      testBoard->pieceCase[0][0] = [[Piece alloc] initWithType:Tour side:sideWhite];
      testBoard->pieceCase[6][2] = [[Piece alloc] initWithType:Tour side:sideWhite];
      testBoard->pieceCase[2][4] = [[Piece alloc] initWithType:Tour side:sideBlack];
      testBoard->pieceCase[6][7] = [[Piece alloc] initWithType:Tour side:sideBlack];
      
      testBoard->pieceCase[5][4] = [[Piece alloc] initWithType:Dame side:sideWhite];
      testBoard->pieceCase[0][4] = [[Piece alloc] initWithType:Dame side:sideBlack];
      
      testBoard->pieceCase[5][0] = [[Piece alloc] initWithType:Roi  side:sideWhite];
      testBoard->pieceCase[7][7] = [[Piece alloc] initWithType:Roi  side:sideBlack];
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard cas n°2 soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      // Calcul de l'EvalBoard
      //[Minimax EvalBoardForSide:sideWhite board:testBoard];
      
      return testBoard;
   } // Fin board cas2


   // ==================================================================================================
   // Méthode non-test de configuration du board cas3 Mat en 10 coups
   +(ChessBoard *)ConfigBoardMatEn3Cas3 {
      /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 20 pièces,
       on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
       plein de moves
       CAS D'EXERCICE NUMÉRO 3 : Tomasz Kamieniecki - Evgeniya Dolukhanova, Varsovie 2010 */
      
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
      
      // Effacement du board déjà construit
      for (int x=0; x < 8; x ++) {
         testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
         testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
         testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
         testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
         testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
         testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
         testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
         testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // Construction nouveau board
      testBoard->pieceCase[0][4] = [[Piece alloc] initWithType:Pion side:sideWhite];
      testBoard->pieceCase[1][1] = [[Piece alloc] initWithType:Pion side:sideWhite];
      testBoard->pieceCase[6][1] = [[Piece alloc] initWithType:Pion side:sideWhite];
      testBoard->pieceCase[7][1] = [[Piece alloc] initWithType:Pion side:sideWhite];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup au pion avancé :
      testBoard->pieceCase[0][4].numMoves = 1;
      
      testBoard->pieceCase[0][5] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[1][4] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[2][3] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[3][4] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[6][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[7][5] = [[Piece alloc] initWithType:Pion side:sideBlack];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[0][5].numMoves = 1;
      testBoard->pieceCase[1][4].numMoves = 1;
      testBoard->pieceCase[2][3].numMoves = 1;
      testBoard->pieceCase[3][4].numMoves = 1;
      testBoard->pieceCase[7][5].numMoves = 1;
      
      testBoard->pieceCase[6][4] = [[Piece alloc] initWithType:Cava side:sideWhite];
      testBoard->pieceCase[6][5] = [[Piece alloc] initWithType:Cava side:sideBlack];
      
      testBoard->pieceCase[5][1] = [[Piece alloc] initWithType:Tour side:sideWhite];
      testBoard->pieceCase[7][2] = [[Piece alloc] initWithType:Tour side:sideWhite];
      testBoard->pieceCase[4][6] = [[Piece alloc] initWithType:Tour side:sideBlack];
      testBoard->pieceCase[6][7] = [[Piece alloc] initWithType:Tour side:sideBlack];
      
      testBoard->pieceCase[7][3] = [[Piece alloc] initWithType:Dame side:sideWhite];
      testBoard->pieceCase[4][4] = [[Piece alloc] initWithType:Dame side:sideBlack];
      
      testBoard->pieceCase[6][0] = [[Piece alloc] initWithType:Roi  side:sideWhite];
      testBoard->pieceCase[7][7] = [[Piece alloc] initWithType:Roi  side:sideBlack];
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard cas n°3 soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      // Calcul de l'EvalBoard
      //[Minimax EvalBoardForSide:sideWhite board:testBoard];
      
      return testBoard;
   } // Fin board cas3

   // ==================================================================================================
   // Méthode non-test de configuration du board cas4 Mat en 10 coups
   +(ChessBoard *)ConfigBoardMatEn3Cas4 {
      /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 15 pièces,
       on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
       plein de moves
       CAS D'EXERCICE NUMÉRO 4 */
      
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
      
      // Effacement du board déjà construit
      for (int x=0; x < 8; x ++) {
         testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
         testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
         testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
         testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
         testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
         testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
         testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
         testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // Construction new board
      testBoard->pieceCase[0][2] = [[Piece alloc] initWithType:Pion side:sideWhite];
      testBoard->pieceCase[1][1] = [[Piece alloc] initWithType:Pion side:sideWhite];
      testBoard->pieceCase[6][3] = [[Piece alloc] initWithType:Pion side:sideWhite];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[0][2].numMoves = 1;
      testBoard->pieceCase[6][3].numMoves = 1;
      
      testBoard->pieceCase[0][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[1][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[2][5] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[6][5] = [[Piece alloc] initWithType:Pion side:sideBlack];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[2][5].numMoves = 1;
      testBoard->pieceCase[6][5].numMoves = 1;
      
      testBoard->pieceCase[6][4] = [[Piece alloc] initWithType:Cava side:sideWhite];
      testBoard->pieceCase[0][5] = [[Piece alloc] initWithType:Cava side:sideBlack];
      
      testBoard->pieceCase[4][1] = [[Piece alloc] initWithType:Fou  side:sideWhite];
      
      testBoard->pieceCase[0][7] = [[Piece alloc] initWithType:Tour side:sideBlack];
      
      testBoard->pieceCase[3][5] = [[Piece alloc] initWithType:Dame side:sideWhite];
      testBoard->pieceCase[3][6] = [[Piece alloc] initWithType:Dame side:sideBlack];
      
      testBoard->pieceCase[1][0] = [[Piece alloc] initWithType:Roi  side:sideWhite];
      testBoard->pieceCase[3][7] = [[Piece alloc] initWithType:Roi  side:sideBlack];
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard cas n°4 soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      // Calcul de l'EvalBoard
      //[Minimax EvalBoardForSide:sideWhite board:testBoard];
      
      return testBoard;
   } // Fin board cas4


   // ==================================================================================================
   // Méthode non-test de configuration du board cas Mat en 3 coups Niveau dit Très Fort
   +(ChessBoard *)ConfigBoardMatEn3Fort {
      /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 15 pièces,
       on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
       plein de moves
       CAS D'EXERCICE NUMÉRO 5 */
      
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
      
      // Effacement du board déjà construit
      for (int x=0; x < 8; x ++) {
         testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
         testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
         testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
         testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
         testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
         testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
         testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
         testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // New board
      testBoard->pieceCase[3][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[1][2] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[4][2] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[1][3] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[7][5] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[1][2].numMoves = 1;
      testBoard->pieceCase[4][2].numMoves = 1;
      testBoard->pieceCase[1][3].numMoves = 1;
      testBoard->pieceCase[7][5].numMoves = 1;
      
      testBoard->pieceCase[4][3] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[4][4] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[2][5] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[2][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      testBoard->pieceCase[3][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[4][3].numMoves = 1;
      testBoard->pieceCase[4][4].numMoves = 1;
      testBoard->pieceCase[2][5].numMoves = 1;
      
      testBoard->pieceCase[0][4] = [[Piece alloc] initWithType:Cava side:sideWhite];
      
      testBoard->pieceCase[0][7] = [[Piece alloc] initWithType:Fou  side:sideWhite];
      testBoard->pieceCase[5][2] = [[Piece alloc] initWithType:Fou  side:sideBlack];
      
      testBoard->pieceCase[7][3] = [[Piece alloc] initWithType:Tour side:sideWhite];
      
      testBoard->pieceCase[4][6] = [[Piece alloc] initWithType:Roi  side:sideWhite];
      testBoard->pieceCase[3][4] = [[Piece alloc] initWithType:Roi  side:sideBlack];
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard cas n°5 Mat en 3 - Niveau 'Très Fort' soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      return testBoard;
   } // Fin board cas5


   // ==================================================================================================
   // Méthode non-test de configuration du board cas6 Mat en 10 coups
   +(ChessBoard *)ConfigBoardMatEn7Demi {
      /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 22 pièces,
       on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
       plein de moves
       CAS D'EXERCICE NUMÉRO 6 : Mat en 7 demi-coups */
      
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
      
      // Effacement du board déjà construit
      for (int x=0; x < 8; x ++) {
         testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
         testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
         testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
         testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
         testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
         testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
         testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
         testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // new board
      testBoard->pieceCase[0][2] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[1][3] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[4][2] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[5][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[6][2] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[7][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[0][2].numMoves = 1;
      testBoard->pieceCase[1][3].numMoves = 1;
      testBoard->pieceCase[4][2].numMoves = 1;
      testBoard->pieceCase[6][2].numMoves = 1;
      
      testBoard->pieceCase[0][5] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[1][4] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[2][3] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[2][6] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[7][5] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup au pion avancé :
      testBoard->pieceCase[0][5].numMoves = 1;
      testBoard->pieceCase[1][4].numMoves = 1;
      testBoard->pieceCase[2][3].numMoves = 1;
      testBoard->pieceCase[7][5].numMoves = 1;
      
      testBoard->pieceCase[4][6] = [[Piece alloc] initWithType:Cava side:sideBlack];
      
      testBoard->pieceCase[5][5] = [[Piece alloc] initWithType:Fou  side:sideWhite];
      testBoard->pieceCase[1][5] = [[Piece alloc] initWithType:Fou  side:sideBlack];
      
      testBoard->pieceCase[3][6] = [[Piece alloc] initWithType:Tour side:sideWhite];
      testBoard->pieceCase[4][7] = [[Piece alloc] initWithType:Tour side:sideBlack];
      testBoard->pieceCase[5][7] = [[Piece alloc] initWithType:Tour side:sideBlack];
      
      testBoard->pieceCase[7][4] = [[Piece alloc] initWithType:Dame side:sideWhite];
      
      testBoard->pieceCase[6][0] = [[Piece alloc] initWithType:Roi  side:sideWhite];
      testBoard->pieceCase[6][7] = [[Piece alloc] initWithType:Roi  side:sideBlack];
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard cas n°6 'Mat en 7 demi' soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      return testBoard;
   } // Fin board cas6


   // ==================================================================================================
   // Méthode non-test de configuration du board cas7 Mat en 10 coups
   +(ChessBoard *)ConfigBoardMatEn3Zugzwang {
      /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 22 pièces,
       on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
       plein de moves
       CAS D'EXERCICE NUMÉRO 7 : Mat en 3 coups par Zugzwang */
      
      // Récupération du 'focus' sur le ChessBoard de la ChessView active
      ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
      
      // Effacement du board déjà construit
      for (int x=0; x < 8; x ++) {
         testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
         testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
         testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
         testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
         testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
         testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
         testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
         testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // new board
      testBoard->pieceCase[0][3] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      testBoard->pieceCase[7][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup au pion avancé :
      testBoard->pieceCase[0][3].numMoves = 1;
      
      testBoard->pieceCase[0][4] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[0][6] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[1][5] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      testBoard->pieceCase[7][5] = [[Piece alloc] initWithType:Pion     side:sideBlack];
      // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
      testBoard->pieceCase[0][4].numMoves = 1;
      testBoard->pieceCase[1][5].numMoves = 1;
      testBoard->pieceCase[7][5].numMoves = 1;
      
      testBoard->pieceCase[2][5] = [[Piece alloc] initWithType:Roi  side:sideWhite];
      testBoard->pieceCase[0][5] = [[Piece alloc] initWithType:Roi  side:sideBlack];
      
      // Sortie de contrôle de la matrice
      NSLog(@"\n\nBoard cas n°6 'Mat en 3 par Zugzwang' soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      return testBoard;
   } // Fin board cas7


// ==================================================================================================
// Méthode non-test de configuration du board cas8 Mat en 10 coups
+(ChessBoard *)ConfigBoardMatEn3Hard {
   /* Contrairement au test du coup du berger, le cas de ce board de départ ne comporte que 22 pièces,
    on le crée de toute pièce (ha ha) plutôt qu'en partant d'un board standard auquel on aurait appliqué
    plein de moves
    CAS D'EXERCICE NUMÉRO 8 : Mat en 3 Difficile */
   
   // Récupération du 'focus' sur le ChessBoard de la ChessView active
   ChessBoard *testBoard = monMCNControleur.maChessView->liveBoard;
   
   // Effacement du board déjà construit
   for (int x=0; x < 8; x ++) {
      testBoard->pieceCase[x][0] = nil;   // effacement rangée 0
      testBoard->pieceCase[x][1] = nil;   // effacement rangée 1
      testBoard->pieceCase[x][2] = nil;   // effacement rangée 2
      testBoard->pieceCase[x][3] = nil;   // effacement rangée 3
      testBoard->pieceCase[x][4] = nil;   // effacement rangée 4
      testBoard->pieceCase[x][5] = nil;   // effacement rangée 5
      testBoard->pieceCase[x][6] = nil;   // effacement rangée 6
      testBoard->pieceCase[x][7] = nil;   // effacement rangée 7
   }
   
   // new board
   testBoard->pieceCase[1][1] = [[Piece alloc] initWithType:Pion     side:sideWhite];
   testBoard->pieceCase[7][2] = [[Piece alloc] initWithType:Pion     side:sideWhite];
   testBoard->pieceCase[2][3] = [[Piece alloc] initWithType:Pion     side:sideWhite];
   // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup aux pions avancés :
   testBoard->pieceCase[7][2].numMoves = 1;
   testBoard->pieceCase[2][3].numMoves = 1;
   
   testBoard->pieceCase[4][1] = [[Piece alloc] initWithType:Pion     side:sideBlack];
   testBoard->pieceCase[1][3] = [[Piece alloc] initWithType:Pion     side:sideBlack];
   testBoard->pieceCase[7][3] = [[Piece alloc] initWithType:Pion     side:sideBlack];
   testBoard->pieceCase[2][4] = [[Piece alloc] initWithType:Pion     side:sideBlack];
   testBoard->pieceCase[1][5] = [[Piece alloc] initWithType:Pion     side:sideBlack];
   testBoard->pieceCase[3][6] = [[Piece alloc] initWithType:Pion     side:sideBlack];
   // Il faut interdire la possibilité d'avancer de 2 cases d'1 coup au pion avancé :
   testBoard->pieceCase[4][1].numMoves = 1;
   testBoard->pieceCase[1][3].numMoves = 1;
   testBoard->pieceCase[7][3].numMoves = 1;
   testBoard->pieceCase[2][4].numMoves = 1;
   testBoard->pieceCase[1][5].numMoves = 1;
   
   testBoard->pieceCase[6][4] = [[Piece alloc] initWithType:Fou  side:sideWhite];
   testBoard->pieceCase[5][2] = [[Piece alloc] initWithType:Fou  side:sideBlack];
   
   testBoard->pieceCase[1][2] = [[Piece alloc] initWithType:Tour side:sideWhite];
   testBoard->pieceCase[6][5] = [[Piece alloc] initWithType:Tour side:sideBlack];
   testBoard->pieceCase[6][7] = [[Piece alloc] initWithType:Tour side:sideBlack];
   
   testBoard->pieceCase[1][6] = [[Piece alloc] initWithType:Dame side:sideBlack];
   
   testBoard->pieceCase[0][1] = [[Piece alloc] initWithType:Roi  side:sideWhite];
   testBoard->pieceCase[0][3] = [[Piece alloc] initWithType:Roi  side:sideBlack];
   
   // Sortie de contrôle de la matrice
   NSLog(@"\n\nBoard cas n°6 'Mat en 7 demi' soumis à l'IA pour le prochain coup Blancs : \n%@\n",testBoard);
   
   // Réglages d'orientation et de trait
   sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
   
   return testBoard;
} // Fin board cas6





@end
