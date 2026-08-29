// Connecteur.m
// Chess
// Created by MCN on 01/11/2020
// Copyright © 2020 MCN - All rights reserved

// CLASSE CONTROLEUR INTERAGISSANT AVEC L'UI ET SES DIFFERENTS OBJETS

#import "Connecteur.h"
#import "ChessConfig.h"


@implementation Connecteur

   /* Pour que les propriétés soient accessibles par d'autres objets que ceux de la classe
   Connecteur, il faut normalement créer des accesseurs (fonctions/méthodes d'accès)
   car les propriétés sont privées par défaut.
   Le mot clé 'synthesize', précédant la propriété, demande au compilateur de construire
   ces accesseurs pour nous, ce qui évite de le faire manuellement... */

   /* (1) le nom 'txtListeCoupsPartie' est choisi en référence à l'identifiant correspondant de
   l'interface xib, mais ce rapprochement n'est pas exigé pour la compilation du programme */

   @synthesize txtListeCoupsPartie; // (1)

   @synthesize lblEvalBoard;
   @synthesize lblTrait;
   @synthesize lblRoque;
   @synthesize lblCibleEP;
   @synthesize lbl50Coups;
   @synthesize lblNumCoup;
   @synthesize lblEchec;
   @synthesize lblInfo;
   @synthesize lblCoupProposed;

   @synthesize lettresSideBlancs;
   @synthesize lettresSideBlancsBas;
   @synthesize lettresSideNoirs;
   @synthesize lettresSideNoirsBas;
   @synthesize chiffresSideBlancs;
   @synthesize chiffresSideNoirs;
   @synthesize chiffresSideNoirsGauche;
   @synthesize chiffresSideBlancsGauche;

   @synthesize indicIAdoitJouer;
   @synthesize indicJdoitJouer;

   @synthesize menuRapide;
   @synthesize menuFacile;
   @synthesize menuSTD;
   @synthesize menuReflechi;
   @synthesize menuChampion;

   
   
   // =============================================================================================
   // Implémentation Méthode MàJ 'txtListeCoupsPartie'
   // appelée par MoveToStr
   -(void)MaJtxtListeCoupsPartie {
      // Affectation de la valeur de la var global 'stringCoupsPartie'
      txtListeCoupsPartie.string = stringCoupsPartie;
      
      // Forcer le scroll du contrôle vers le bas pour voir tjs les derniers coups
      [monConnecteur.txtListeCoupsPartie
            scrollRangeToVisible:NSMakeRange(monConnecteur.txtListeCoupsPartie.string.length, 0)];
      
   } // !MaJtxtListeCoupsPartie

   

   // =============================================================================================
   // Implémentation Méthode d'édition de la liste des coups
   // Appelée par AppDelegate pour la mise à jour du 1er coup qd l'IA a les Blancs
   - (void)InitialiseListeCoupsPartie:(NSString *)texteSortie
   {
      // Sortie concaténée
      txtListeCoupsPartie.string = [txtListeCoupsPartie.string stringByAppendingString:texteSortie];
   
   } // !InitialiseListeCoupsPartie

   

   // =============================================================================================
   // Méthode d'instance assurant le repérage des rang. et col. selon l'orientation de l'échiquier
   -(void)MajReperesCases
   {
      if (sideJoueur == sideWhite)
      {
         chiffresSideBlancs      .hidden = NO;
         chiffresSideNoirs       .hidden = YES;
         chiffresSideBlancsGauche.hidden = NO;
         chiffresSideNoirsGauche .hidden = YES;
         lettresSideBlancs       .hidden = NO;
         lettresSideNoirs        .hidden = YES;
         lettresSideBlancsBas    .hidden = NO;
         lettresSideNoirsBas     .hidden = YES;
      }
      else
      {
         chiffresSideBlancs      .hidden = YES;
         chiffresSideNoirs       .hidden = NO;
         chiffresSideBlancsGauche.hidden = YES;
         chiffresSideNoirsGauche .hidden = NO;
         lettresSideBlancs       .hidden = YES;
         lettresSideNoirs        .hidden = NO;
         lettresSideBlancsBas    .hidden = YES;
         lettresSideNoirsBas     .hidden = NO;
      }
      
   } // !MajReperesCases


   // Gestion des items du menu 'Partie->Difficulté'
   -(IBAction)SetDifficulty1:(id)sender {
      [menuRapide    setState:YES]; // Rapide
      [menuFacile    setState:NO];
      [menuSTD       setState:NO];
      [menuReflechi  setState:NO];
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 6;
      monConnecteur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   -(IBAction)SetDifficulty2:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:YES]; // Facile
      [menuSTD       setState:NO];
      [menuReflechi  setState:NO];
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 7;
      monConnecteur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   -(IBAction)SetDifficulty3:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:NO];
      [menuSTD       setState:YES]; // Standard
      [menuReflechi  setState:NO];
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 8;
      monConnecteur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   -(IBAction)SetDifficulty4:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:NO];
      [menuSTD       setState:NO];
      [menuReflechi  setState:YES]; // Réfléchi
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 9;
      monConnecteur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   -(IBAction)SetDifficulty5:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:NO];
      [menuSTD       setState:NO];
      [menuReflechi  setState:NO];
      [menuChampion  setState:YES]; // Champions
      NUMBER_MOVES_AHEAD = 10;
      monConnecteur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }
   // !SetDifficultyX

   

   // ==================================================================================================
   // Méthode d'affichage DÉLÉGUÉE
   // d'une boite de dialogue signalant qu'un camp est en position d'ÉCHEC
   -(void)AlertMsgEchecSide:(Side)side {
      
      NSString *msgTitre;
      NSString *msgInfo;
      int bouton;
      
      if (side == sideBlack) {
         msgTitre = @"Le Roi NOIR est en position d'Échec !";
         msgInfo  = @"OK pour poursuivre la partie...";
      }
      else {
         msgTitre = @"Le Roi BLANC est en position d'Échec !";
         msgInfo  = @"OK pour poursuivre la partie...";
      }
      
      NSAlert *alertEchec = [[NSAlert alloc] init];
      [alertEchec addButtonWithTitle:@"OK"];
      [alertEchec setMessageText:msgTitre];
      [alertEchec setInformativeText:msgInfo];
      [alertEchec setAlertStyle:NSAlertStyleInformational];
      
      // Attente clic OK
      NSModalResponse boutonChoisi = [alertEchec runModal];
      if (boutonChoisi == NSAlertFirstButtonReturn) bouton = 1; /* ce qui ne sert à rien d'autre
      qu'interrompre le programme en attente d'un clic sur 'OK', bouton = 1 n'est qu'un artifice */
      
   }



   // ================================================================================================
   // Méthode d'affichage DÉLÉGUÉE
   // d'une boite de dialogue signalant qu'un camp est en position de MAT ou de PAT
   -(void)AlertMsgPatMatSide:(Side)side
                       onBoard:(ChessBoard*)board
   {
      if ([maMinimax IsKingInCheck:(side) board:(board)]) {
         /* Roi en échec --> MAT DÉTECTÉ
         car on a appelé la méthode APRÈS avoir vérifié que le Roi side n'a pas d'échappatoire */
         NSString *msgTitre;
         NSString *msgInfo;
         
         while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == ' ') {
            stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
         }
         while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == '+') {
            stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
         }
         
         monConnecteur.lblEchec.cell.stringValue = @"Échec et Mat !";
         
         if (side == sideBlack) {
            msgTitre = @"Les NOIRS sont Mat !";
            msgInfo  = @"Partie terminée, Les BLANCS gagnent !";
            stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t1-0"];
            [monConnecteur MaJtxtListeCoupsPartie];
         }
         else if (side == sideWhite) {
            msgTitre = @"Les BLANCS sont Mat !";
            msgInfo  = @"Partie terminée, Les NOIRS gagnent !";
            stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t0-1"];
            [monConnecteur MaJtxtListeCoupsPartie];
         }
         
         NSAlert *alertMat = [[NSAlert alloc] init];
         [alertMat addButtonWithTitle:@"OK"];
         [alertMat setMessageText:msgTitre];
         [alertMat setInformativeText:msgInfo];
         [alertMat setAlertStyle:NSAlertStyleInformational];
         
         NSModalResponse boutonChoisi = [alertMat runModal];
         if (boutonChoisi == NSAlertFirstButtonReturn) {
            stopMatOuPat = YES;
         }
         
         // Message en Log
         NSString *strRoiMat = (side == sideBlack)? @"\"Noirs\"":@"\"Blancs\"";
         NSLog(@"\nLe Roi %@ est Mat\n", strRoiMat);
      }
      else {
         /* Roi pas en échec --> PAT DÉTECTÉ */
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\n\t1/2-1/2"];
         [monConnecteur MaJtxtListeCoupsPartie];
         
         NSString *msgTitre;
         NSString *msgInfo;
         
         if (side == sideBlack) {
            msgTitre = @"Les NOIRS sont Pat !";
            msgInfo  = @"Le Roi Noir est Pat, la partie est déclarée nulle !";
         }
         else if (side == sideWhite) {
            msgTitre = @"Les BLANCS sont Pat !";
            msgInfo  = @"Le Roi Blanc est Pat, la partie est déclarée nulle !";
         }
         
         monConnecteur.lblEchec.cell.stringValue = @"Pat !";
         
         NSAlert *alertPat = [[NSAlert alloc] init];
         [alertPat addButtonWithTitle:@"OK"];
         [alertPat setMessageText:msgTitre];
         [alertPat setInformativeText:msgInfo];
         [alertPat setAlertStyle:NSAlertStyleInformational];
         
         NSModalResponse boutonChoisi = [alertPat runModal];
         if (boutonChoisi == NSAlertFirstButtonReturn) {
            stopMatOuPat = YES;
         }
         
         // Message en Log
         NSString *strRoiPat = (side == sideBlack)? @"\"Noirs\"":@"\"Blancs\"";
         NSLog(@"\nLe Roi %@ est Pat\n", strRoiPat);
      }
   }


@end
