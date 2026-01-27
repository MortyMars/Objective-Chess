//  ChessTests.m
//  ChessTests
//  Created by MCN on 24/03/2022.
//  Copyright © 2022 MCN - All rights reserved.

#import "ChessTests.h"
#import "BoardsForTests.h"



@implementation ChessTests

   ChessBoard *testBoard;


   - (void)setUp {
      // Placer le code de configuration ici.
      // Cette méthode est appelée avant l'invocation de chaque méthode de test dans la classe.
      /* sideJoueur = sideWhite;
      testBoard = [[ChessBoard alloc]init];
      [testBoard SetupPieces]; */
   }

   // Méthode (qui n'est pas un test) mise en place pour remplacer 'setUp' et permettre de choisir test par test
   // lesquels qui est exécutée par défaut avant tout test
   // La présente méthode présente l'avantage de laisser le choix de l'exécuter ou non
   - (void)tearDown {
      // Placer le code de démontage ici.
      // Cette méthode est appelée après l'invocation de chaque méthode de test dans la classe.
   }

   
   - (void)testNegamaxFS {
      // This is an example of a functional test case.
      // Use XCTAssert and related functions to verify your tests produce the correct results.
      //[BoardsForTests initBoardStd];
      
      sideJoueur = sideWhite;
      ChessBoard *testBoard = [[ChessBoard alloc]init];
      sideJoueur = sideWhite;
      sideIA = sideBlack;
      [testBoard SetupPieces];
      
      
      NSLog(@"\n\nBoard de départ standard créé : \n%@\n",testBoard);
      int negaMax =[Minimax NegamaxForSide:sideBlack board:testBoard depth:3 alpha:-INT_MAX beta:INT_MAX];
      XCTAssertTrue(negaMax < 103900);
      NSLog(@"\n\n Valeur de retour de NegamaxFS = %d \n\n",negaMax);
   }

   // **************************************************************************************************
   // Test de détermination du coup ultime pour le Mat du berger
   - (void)testCoupDuBerger {
      
      // Mise en place du board pour un Mat en 1 coup
      ChessBoard *testBoard = [BoardsForTests ConfigBoardCoupDuBerger];
      
      // À partir de là on attend Dh5xf7# ou Fc4xf7# (Dh5xf7+ ou Fc4xf7+ en mode dégradé)...
      
      // Récupération du 'focus' sur le ChessView instancié par l'application
      ChessView *testView = monMCNControleur.maChessView;
      
      testView.needsDisplay = YES;
      
      // Boite de dialogue, permettant une interruption rendant possible l'affichage du board Avant résolution
      NSAlert *stop1 = [[NSAlert alloc] init];
      [stop1 setMessageText:@"Cas du coup du Berger"];
      [stop1 setInformativeText:@"Voici le 'board' proposé à l'IA, Trait aux Blancs"];
      [stop1 addButtonWithTitle:@"OK, c'est parti !"];
      [stop1 setAlertStyle:NSAlertStyleInformational];
      [stop1 runModal];

      /* Lancement de la boucle des coups successifs, limitée à 5 coups, Blancs au trait
      Sauf bug ou erreur grossière du moteur, un seul coup suffit sur ce cas basique ...*/
      int compteur = 0;
      while (([Minimax PossibleMovesForSide:sideWhite board:testBoard].count!=0) &&
             ([Minimax PossibleMovesForSide:sideBlack board:testBoard].count!=0) &&
             (compteur < 5)) {
         
         [testView MakeIAMoveForSide:sideWhite Board:testBoard];
         if ([Minimax PossibleMovesForSide:sideBlack board:testBoard].count!=0) {
            [testView MakeIAMoveForSide:sideBlack Board:testBoard];}
         
         compteur += 1;
      }
      
      testView.needsDisplay = YES;
      
      // Contrôle chaine des coups
      NSLog(@"Coups successifs = \n%@",stringCoupsPartie);
      // Contrôle de la matrice finale
      NSLog(@"\n\nBoard final : \n%@\n",testBoard);
      
      // Seconde Boite de dialogue, permettant une interruption rendant possible l'affichage du board Avant
      NSAlert *stop2 = [[NSAlert alloc] init];
      [stop2 setMessageText:@"Cas du coup du Berger"];
      [stop2 setInformativeText:@"Et voilà le 'board' final proposé par l'IA"];
      [stop2 addButtonWithTitle:@"OK !"];
      [stop2 setAlertStyle:NSAlertStyleInformational];
      [stop2 runModal];
      
      
   } // Fin de testCoupDuBerger


   // **************************************************************************************************
   // Test permettant de vérifier le solutionnement de cas de mat résolubles idéalement en 3 coups
   // On se contentera ici d'un mat dans les 10 coups que l'on s'accorde pour y parvenir
   -(void) test1MatEn20CoupsMax {
      
      // Boite de dialogue pour choix du cas à proposer à l'IA
      NSString *msgTitre = @"Choix du cas d'exercice";
      NSString *msgInfo  = @"Choisissez un des 4 tests de Mat en 3 coups";
      NSString *rappelCas = @"";

      NSAlert *choixExoMat = [[NSAlert alloc] init];
      [choixExoMat addButtonWithTitle:@"Cas1 : W. Browne        -       V. Brond       1971"];
      [choixExoMat addButtonWithTitle:@"Cas2 : S. Johansen     -     M. Machlik     2013"];
      [choixExoMat addButtonWithTitle:@"Cas3 : T. Kamieniecki - E. Dolukhanova 2010"];
      [choixExoMat addButtonWithTitle:@"Cas4 : V. Akopian       -       C. Gabriel     1996"];
      [choixExoMat setMessageText:msgTitre];
      [choixExoMat setInformativeText:msgInfo];
      [choixExoMat setAlertStyle:NSAlertStyleInformational];

      /* Récupération du choix du cas de figure fait par le joueur et CONSTRUCTION DU BOARD
      Noter l'astuce employée pour disposer d'un véritable quadruple choix -sachant que NSAlert ne
      sait pas lire un retour au-delà du 'ThirdButton'- en utilisant un pseudo choix par défaut...  */
      NSModalResponse boutonChoisi = [choixExoMat runModal];
      switch (boutonChoisi) {
         case NSAlertFirstButtonReturn : {
            testBoard = [BoardsForTests ConfigBoardMatEn3Cas1];
            NSLog(@"\nÉtude du CAS1 : W. Browne vs V. Brond - Mar del Plata 1971\n");
            rappelCas = @"Cas n°1"; break;}
         case NSAlertSecondButtonReturn: {
            testBoard = [BoardsForTests ConfigBoardMatEn3Cas2];
            NSLog(@"\nÉtude du CAS2 : S. Johansen vs M. Machlik - Oslo 2013\n");
            rappelCas = @"Cas n°2"; break;}
         case NSAlertThirdButtonReturn : {
            testBoard = [BoardsForTests ConfigBoardMatEn3Cas3];
            NSLog(@"\nÉtude du CAS3 : T. Kamieniecki vs E. Dolukhanova - Varsovie 2010\n");
            rappelCas = @"Cas n°3"; break;}
         default                       : {
            testBoard = [BoardsForTests ConfigBoardMatEn3Cas4];
            NSLog(@"\nÉtude du CAS4 : V. Akopian vs C. Gabriel - Baden-Baden 1996\n");
            rappelCas = @"Cas n°4"; break;}
      }
      
      // Calcul de l'eval board
      //[Minimax EvalBoardForSide:sideWhite board:testBoard];
      
      // Récupération du 'focus' sur le ChessView instancié par l'application
      ChessView *testView = monMCNControleur.maChessView;
      
      testView.needsDisplay = YES;
      
      // Seconde Boite de dialogue, permettant une interruption rendant possible l'affichage du board Avant
      NSAlert *stop1 = [[NSAlert alloc] init];
      [stop1 setMessageText:[NSString stringWithFormat:@"Cas de Mat en 3 coups (%@)", rappelCas]];
      [stop1 setInformativeText:@"Voici le 'board' proposé à l'IA, Trait aux Blancs"];
      [stop1 addButtonWithTitle:@"OK, c'est parti !"];
      [stop1 setAlertStyle:NSAlertStyleInformational];
      [stop1 runModal];
      
      // Lancement de la boucle des coups successifs, limitée à 20 coups, Blance au trait
      int compteur = 0;
      /* Tant que Blancs non Pat ou Mat ET Noirs non Pat ou Mat ET compteur inférieur à 10
      (mais dès que l'un des trois, on sort de la boucle)   */
      while (([Minimax PossibleMovesForSide:sideWhite board:testBoard].count!=0) &&
             ([Minimax PossibleMovesForSide:sideBlack board:testBoard].count!=0) &&
             (compteur < 20)) {
         
         // On lance le coup Blancs puisqu'ils ne sont pas Pat ou Mat (test fait ci-dessus)
         [testView MakeIAMoveForSide:sideWhite Board:testBoard];
         testView.needsDisplay = YES;
         [testView displayIfNeeded];
         
         // On ne lance le coup Noirs que s'ils ne sont pas Pat ou Mat après le coup Blancs
         if ([Minimax PossibleMovesForSide:sideBlack board:testBoard].count!=0) {
            
            [testView MakeIAMoveForSide:sideBlack Board:testBoard];
            
            /*NSDictionary *dicoBlack = @{testBoard:@"ObjBoard", [NSNumber numberWithInt:sideBlack]:@"SideEnInt"};
            NSLog(@"SideBlack en  int   --> %@",[NSNumber numberWithInt:sideBlack]);
            NSLog(@"NSDictionary dicoB  --> %@",dicoBlack);
            [NSTimer scheduledTimerWithTimeInterval:0.02
                                             target:testView
                                           selector:@selector(MakeIAMoveForSide:Board:)
                                           userInfo:dicoBlack
                                            repeats:NO];*/
            
            testView.needsDisplay = YES;
            [testView displayIfNeeded];
         }
         
         compteur += 1;
      }
      
      testView.needsDisplay = YES;
      
      // Contrôle chaine des coups
      NSLog(@"Coups successifs = \n%@",stringCoupsPartie);
      // Contrôle de la matrice finale
      NSLog(@"\n\nBoard final : \n%@\n",testBoard);
      
      // Seconde Boite de dialogue, permettant une interruption rendant possible l'affichage du board Avant
      NSAlert *stop2 = [[NSAlert alloc] init];
      [stop2 setMessageText:[NSString stringWithFormat:@"Cas de Mat en 3 coups (%@)", rappelCas]];
      [stop2 setInformativeText:@" Et voilà le 'board' final proposé par l'IA"];
      [stop2 addButtonWithTitle:@"OK !"];
      [stop2 setAlertStyle:NSAlertStyleInformational];
      [stop2 runModal];
      
   } // Fin de test MatEnXcoups


   // **************************************************************************************************
   // Test permettant de vérifier le solutionnement de cas de mat résolubles idéalement en 3 coups
   // On se contentera ici d'un mat dans les 10 coups que l'on s'accorde pour y parvenir
   -(void) test2MatEn20CoupsMax {
      
      ChessBoard *testBoard = [[ChessBoard alloc]init];
      
      NSString *msgTitre = @"Choix du cas d'exercice";
      NSString *msgInfo  = @"Choisissez un des 4 tests de Mat 'en 3 coups'";
      NSString *rappelCas = @"";
      
      NSAlert *choixExoMat = [[NSAlert alloc] init];
      [choixExoMat addButtonWithTitle:@"Cas5 : Mat en 3 coups - Niveau 'Très Fort'"];
      [choixExoMat addButtonWithTitle:@"Cas6 : Mat en 7 demi-coups"];
      [choixExoMat addButtonWithTitle:@"Cas7 : Mat en 3 par Zugzwang"];
      [choixExoMat addButtonWithTitle:@"Cas8 : Mat en 3 Difficile"];
      [choixExoMat setMessageText:msgTitre];
      [choixExoMat setInformativeText:msgInfo];
      [choixExoMat setAlertStyle:NSAlertStyleInformational];
      
      /* Récupération du choix du cas de figure fait par le joueur
       Noter l'astuce employée pour disposer d'un véritable quadruple choix -sachant que NSAlert ne
       sait pas lire un retour au-delà du 'ThirdButton'- en utilisant un pseudo choix par défaut...  */
      NSModalResponse boutonChoisi = [choixExoMat runModal];
      switch (boutonChoisi) {
         case NSAlertFirstButtonReturn : {testBoard = [BoardsForTests ConfigBoardMatEn3Fort];
            NSLog(@"\nÉtude du CAS 5 : Mat en 3 coups - 'Très Fort'\n");
            rappelCas = @"Cas n°5"; break;}
         case NSAlertSecondButtonReturn: {testBoard = [BoardsForTests ConfigBoardMatEn7Demi];
            NSLog(@"\nÉtude du CAS 6 : Mat en 7 demi-coups\n");
            rappelCas = @"Cas n°6"; break;}
         case NSAlertThirdButtonReturn : {testBoard = [BoardsForTests ConfigBoardMatEn3Zugzwang];
            NSLog(@"\nÉtude du CAS 7 : Mat en 3 par Zugzwang\n");
            rappelCas = @"Cas n°7"; break;}
         default                       : {testBoard = [BoardsForTests ConfigBoardMatEn3Hard];
            NSLog(@"\nÉtude du CAS 8 : Mat en 3 Difficile\n");
            rappelCas = @"Cas n°8"; break;}
      }
      
      // Récupération du 'focus' sur le ChessView instancié par l'application
      ChessView *testView = monMCNControleur.maChessView;
      
      testView.needsDisplay = YES;
      
      // Seconde Boite de dialogue, permettant une interruption rendant possible l'affichage du board Avant
      NSAlert *stop = [[NSAlert alloc] init];
      [stop setMessageText:[NSString stringWithFormat:@"Cas de Mat en 3 coups (%@)", rappelCas]];
      [stop setInformativeText:@"Voici le 'board' proposé à l'IA, Trait aux Blancs"];
      [stop addButtonWithTitle:@"OK, c'est parti !"];
      [stop setAlertStyle:NSAlertStyleInformational];
      [stop runModal];
      
      
      // Lancement de la boucle des coups successifs, limitée à 50 coups, Blancs au trait
      int compteur = 0;
      while (([Minimax PossibleMovesForSide:sideWhite board:testBoard].count!=0) &&
             ([Minimax PossibleMovesForSide:sideBlack board:testBoard].count!=0) &&
             (compteur < 50)) {
         
         [testView MakeIAMoveForSide:sideWhite Board:testBoard];
         if ([Minimax PossibleMovesForSide:sideBlack board:testBoard].count!=0) {
            [testView MakeIAMoveForSide:sideBlack Board:testBoard];}
         testView.needsDisplay = YES;
         
         compteur += 1;
      }
      
      // Contrôle chaine des coups
      NSLog(@"Coups successifs = \n%@",stringCoupsPartie);
      // Contrôle de la matrice finale
      NSLog(@"\n\nBoard final : \n%@\n",testBoard);
      
      // Seconde Boite de dialogue, permettant une interruption rendant possible l'affichage du board Avant
      NSAlert *stop2 = [[NSAlert alloc] init];
      [stop2 setMessageText:[NSString stringWithFormat:@"Cas de Mat en 3 coups (%@)", rappelCas]];
      [stop2 setInformativeText:@"Et voilà le 'board' final proposé par l'IA"];
      [stop2 addButtonWithTitle:@"OK !"];
      [stop2 setAlertStyle:NSAlertStyleInformational];
      [stop2 runModal];
      
   } // Fin de test MatEnXcoups



   // **************************************************************************************************
   // Test de performance
   -(void)testPerformanceBestMoveFS
   {
      // This is an example of a performance test case.
      [self measureBlock:^{
         // Put the code you want to measure the time of here.
         [maMinimax BestMoveForSide:sideWhite board:[BoardsForTests ConfigBoardMatEn3Cas2]];
      }];
      
      /* Résultat du test réalisé le 28 mars :
       Test Suite 'Selected tests' passed at 2022-03-28 20:03:13.731.
       Executed 1 test, with 0 failures (0 unexpected) in 448.871 (448.873) seconds */
      
      /* Résultat du test réalisé le 01 avril :
       Test Suite 'Selected tests' failed at 2022-04-01 01:40:47.927.
       Executed 1 test, with 1 failure (0 unexpected) in 1265.730 (1265.732) seconds */
      
      /* Résultat du test réalisé le 12 avril avec NUMBER_MOVE_AHEAD = 2 :
       Test Suite 'Selected tests' passed at 2022-04-12 21:59:04.161.
       Executed 1 test, with 0 failures (0 unexpected) in 879.683 (879.685) seconds */
      
      /* Résultat du test réalisé le 13 avril avec NUMBER_MOVE_AHEAD = 2 :
       Test Suite 'Selected tests' passed at 2022-04-14 00:03:30.315.
       Executed 1 test, with 0 failures (0 unexpected) in 550.508 (550.511) seconds */
      
      /* Résultat du test réalisé le 23 janvier 2026 avec NUMBER_MOVE_AHEAD = 2 :
       Test Suite 'Selected tests' passed at 2026-01-23 00:49:19.865.
       Executed 1 test, with 0 failures (0 unexpected) in 221.659 (221.660) seconds  👍*/
      
   }


   // **************************************************************************************************
   // Test de performance
   -(void)testPerformancePossibleMoveFS {
      // This is an example of a performance test case.
      [self measureBlock:^{
         // Put the code you want to measure the time of here.
         [Minimax PossibleMovesForSide:sideWhite board:[BoardsForTests ConfigBoardMatEn3Cas2]];
      }];
      
      /* Résultat du test réalisé le 20/04/22 :
       Test Suite 'Selected tests' passed at 2022-04-20 19:08:25.092.
       Executed 1 test, with 0 failures (0 unexpected) in 0.368 (0.370) seconds       */
      
      /* Résultat du test réalisé le :
       */
      
      /* Résultat du test réalisé le :
        */
      
      /* Résultat du test réalisé le  :
        */
      
   }


   // **************************************************************************************************
   // Test de performance
   -(void)testPerformancePerformMove {
      // This is an example of a performance test case.
      [self measureBlock:^{
         // Put the code you want to measure the time of here.
         Pos *Depart =  [[Pos alloc] initWithX:5 y:4];
         Pos *Arrivee = [[Pos alloc] initWithX:1 y:0];
         Move *moveTest = [[Move alloc] initWithStart:Depart dest:Arrivee];
         ChessBoard *perfBoard = [BoardsForTests ConfigBoardMatEn3Cas2];
         [perfBoard PerformMove:moveTest];
      }];
      
      /* Résultat du test réalisé le :
       Test Suite 'Selected tests' passed at 2022-04-20 19:09:42.512.
       Executed 1 test, with 0 failures (0 unexpected) in 0.312 (0.314) seconds   */
      
      /* Résultat du test réalisé le :
       Test Suite 'Selected tests' passed at 2026-01-23 00:57:21.436.
       Executed 1 test, with 0 failures (0 unexpected) in 0.332 (0.333) seconds 🙂  */
      
      /* Résultat du test réalisé le :
       */
      
      /* Résultat du test réalisé le  :
       */
   }


   // **************************************************************************************************
   // Test de performance
   -(void)testPerformanceEvalBoardFS {
      // This is an example of a performance test case.
      [self measureBlock:^{
         // Put the code you want to measure the time of here.
         [Minimax EvalBoardForSide:sideWhite board:[BoardsForTests ConfigBoardMatEn3Cas2]];
      }];
      
      /* Résultat du test réalisé le :
       Test Suite 'Selected tests' passed at 2022-04-20 19:10:18.698.
       Executed 1 test, with 0 failures (0 unexpected) in 0.369 (0.372) seconds       */
      
      /* Résultat du test réalisé le :
       */
      
      /* Résultat du test réalisé le :
       */
      
      /* Résultat du test réalisé le  :
       */
   }


   // **************************************************************************************************
   // Test de performance
   -(void)testPerformanceNegamaxFS {
      // This is an example of a performance test case.
      [self measureBlock:^{
         // Put the code you want to measure the time of here.
         [Minimax NegamaxForSide:sideWhite
                           board:[BoardsForTests ConfigBoardMatEn3Cas2]
                           depth:4
                           alpha:-INT_MAX
                            beta:+INT_MAX];
      }];
      
      /* Résultat du test réalisé le 20/04/22 avec NUMBER_MOVE_AHEAD = 4 :
       Test Suite 'Selected tests' passed at 2022-04-20 20:02:38.471.
       Executed 1 test, with 0 failures (0 unexpected) in 1473.922 (1473.924) seconds   */
      
      /* Résultat du test réalisé le 20/04/22 avec NUMBER_MOVE_AHEAD = 3 :
       Test Suite 'Selected tests' passed at 2022-04-21 00:31:38.393.
       Executed 1 test, with 0 failures (0 unexpected) in 187.086 (187.088) seconds    */
      
      /* Résultat du test réalisé le 20/04/22 sur VARIANTE avec NUMBER_MOVE_AHEAD = 3 :
       Test Suite 'Selected tests' passed at 2022-04-21 00:50:23.048.
       Executed 1 test, with 0 failures (0 unexpected) in 119.406 (119.408) seconds    */
      
      /* Résultat du test réalisé le 28/04/22 sur VARIANTE avec NUMBER_MOVE_AHEAD = 4 :
       Test Suite 'Selected tests' passed at 2022-04-28 23:37:37.105.
       Executed 1 test, with 0 failures (0 unexpected) in 667.456 (667.458) seconds       */
      
      /* Résultat du test réalisé le 23/01/26 sur REFONTE DE NEGAMAX et EVALBOARD avec
       NUMBER_MOVE_AHEAD = 4 :
       Test Suite 'Selected tests' passed at 2026-01-23 01:37:58.371.
       Executed 1 test, with 0 failures (0 unexpected) in 631.698 (631.699) seconds  👍*/
      
   }


   // ******************************
   // Test de la fonction d'évaluation
   -(void)testFonctEvaluation {

      ChessBoard *boardCas1 = [BoardsForTests ConfigBoardMatEn3Cas1];
      //NSLog(@"Evaluation du Board cas1 : %d\n",evalDisplay);
      /* XCTAssertTrue([Minimax EvalBoardForSide:sideWhite board:boardCas1] == +200);
      XCTAssertTrue(evalDisplay == +200);
      XCTAssertTrue([Minimax EvalBoardForSide:sideBlack board:boardCas1] == -200);
      XCTAssertTrue(evalDisplay == +200); */
      
      ChessBoard *boardCas2 = [BoardsForTests ConfigBoardMatEn3Cas2];
      //NSLog(@"Evaluation du Board cas2 : %d\n",evalDisplay);
      /* XCTAssertTrue([Minimax EvalBoardForSide:sideWhite board:boardCas2] == 0);
      XCTAssertTrue(evalDisplay == 0);
      XCTAssertTrue([Minimax EvalBoardForSide:sideBlack board:boardCas2] == 0);
      XCTAssertTrue(evalDisplay == 0); */

      ChessBoard *boardCas3 = [BoardsForTests ConfigBoardMatEn3Cas3];
      //NSLog(@"Evaluation du Board cas3 : %d\n",evalDisplay);
      /* XCTAssertTrue([Minimax EvalBoardForSide:sideWhite board:boardCas3] == -200);
      XCTAssertTrue(evalDisplay == -200);
      XCTAssertTrue([Minimax EvalBoardForSide:sideBlack board:boardCas3] == +200);
      XCTAssertTrue(evalDisplay == -200); */
      
      ChessBoard *boardCas4 = [BoardsForTests ConfigBoardMatEn3Cas4];
      //NSLog(@"Evaluation du Board cas4 : %d\n",evalDisplay);
      /* XCTAssertTrue([Minimax EvalBoardForSide:sideWhite board:boardCas4] == -300);
      XCTAssertTrue(evalDisplay == -300);
      XCTAssertTrue([Minimax EvalBoardForSide:sideBlack board:boardCas4] == +300);
      XCTAssertTrue(evalDisplay == -300); */
      
   }

@end
