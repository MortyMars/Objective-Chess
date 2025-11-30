//  MCNconnecteur.m
//  Chess
//
//  Created by MCN on 01/11/2020.
//  Copyright © 2020 MCN - All rights reserved.

// CLASSE CONTROLEUR INTERAGISSANT SUR L'UI ET SES DIFFERENTS OBJETS

#import "MCNconnecteur.h"


@implementation MCNconnecteur

   /* Pour que les propriétés soient accessibles par d'autres objets que ceux de la classe
   MCNconnecteur, il faut normalement créer des accesseurs (fonctions/méthodes d'accès)
   car les propriétés sont privées par défaut.
   Le mot clé 'synthesize', précédant la propriété, demande au compilateur de construire
   ces accesseurs pour nous, ce qui évite de le faire manuellement... */

   /* (1) le nom 'txtCoups' est choisi en référence à l'identifiant correspondant de
   l'interface xib, mais ce rapprochement n'est pas exigé pour la compilation du programme */

   @synthesize txtCoups; // (1)

   @synthesize lblEvalBoard;
   @synthesize lblTrait;
   @synthesize lblRoque;
   @synthesize lblCibleEP;
   @synthesize lbl50Coups;
   @synthesize lblNumCoup;
   @synthesize lblEchec;
   @synthesize lblInfo;

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

   
   
   // *********************************************************************************************
   // Implémentation Méthode MàJ 'txtCoups'
   // appelée par MCNmoveToStr
   -(void)MaJtxtCoups;
   {
      // Affectation de la valeur de la var global 'stringCoupsPartie'
      txtCoups.string = stringCoupsPartie;
   
   } // Fin de Méthode

   
   // *********************************************************************************************
   // Implémentation Méthode d'édition de la liste des coups
   // Appelée par AppDelegate pour la mise à jour du 1er coup qd l'IA a les Blancs
   - (void)InitialiseTxtCoups:(NSString *)texteSortie
   {
      // Sortie concaténée
      //txtCoups.cell.title = [txtCoups.cell.title stringByAppendingString:texteSortie]; // (1)
      txtCoups.string = [txtCoups.string stringByAppendingString:texteSortie];
   
   } // Fin de Méthode

   
   // *********************************************************************************************
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
   } // Fin de Méthode MajReperesCases


   // Gestion des items du menu 'Partie->Difficulté'
   - (IBAction)SetDifficulty1:(id)sender {
      [menuRapide    setState:YES];
      [menuFacile    setState:NO];
      [menuSTD       setState:NO];
      [menuReflechi  setState:NO];
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 0;
      //NSLog(@"\n Valeur de NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD);
      monMCNControleur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   - (IBAction)SetDifficulty2:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:YES];
      [menuSTD       setState:NO];
      [menuReflechi  setState:NO];
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 1;
      //NSLog(@"\n Valeur de NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD);
      monMCNControleur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   - (IBAction)SetDifficulty3:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:NO];
      [menuSTD       setState:YES];
      [menuReflechi  setState:NO];
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 2;
      //NSLog(@"\n Valeur de NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD);
      monMCNControleur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   - (IBAction)SetDifficulty4:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:NO];
      [menuSTD       setState:NO];
      [menuReflechi  setState:YES];
      [menuChampion  setState:NO];
      NUMBER_MOVES_AHEAD = 3;
      //NSLog(@"\n Valeur de NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD);
      monMCNControleur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }

   - (IBAction)SetDifficulty5:(id)sender {
      [menuRapide    setState:NO];
      [menuFacile    setState:NO];
      [menuSTD       setState:NO];
      [menuReflechi  setState:NO];
      [menuChampion  setState:YES];
      NUMBER_MOVES_AHEAD = 4;
      //NSLog(@"\n Valeur de NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD);
      monMCNControleur.lblInfo.cell.stringValue =
                              [NSString stringWithFormat:@"Info : NUMBER_MOVES_AHEAD = %d", NUMBER_MOVES_AHEAD];
   }
   // Fin de gestion des items du menu 'Partie->Difficulté'

   //***************************************************************************************************
   // Méthode d'affichage déléguée
   // d'une boite de dialogue signalant qu'un camp est en position d'échec
   -(void)AlerteEchecRoiSide:(Side)side {
      
      NSString *msgTitre;
      NSString *msgInfo;
      int bouton;
      
      if (sideCourant == sideWhite) {
         msgTitre = @"Le Roi NOIR est en position d'Échec !";
         msgInfo  = @"OK pour poursuivre la partie...";
      }
      else {
         msgTitre = @"Le Roi BLANC est en position d'Échec !";
         msgInfo  = @"OK pour poursuivre la partie...";
      }
      
      NSAlert *alertEchec = [[NSAlert alloc] init];
      [alertEchec addButtonWithTitle:@"OK (Méthode déléguée)"];
      [alertEchec setMessageText:msgTitre];
      [alertEchec setInformativeText:msgInfo];
      [alertEchec setAlertStyle:NSAlertStyleInformational];
      
      // Attente clic OK
      NSModalResponse boutonChoisi = [alertEchec runModal];
      if (boutonChoisi == NSAlertFirstButtonReturn) bouton = 1; /* ce qui ne sert à rien d'autre
      qu'interrompre le programme en attente d'un clic sur 'OK', bouton = 1 n'est qu'un artifice */
      
   }



@end
