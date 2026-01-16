//  MCNconnecteur.h
//  Chess
//
//  Created by MCN on 01/11/2020.
//  Copyright © 2020 MCN - All rights reserved.

#import "Minimax.h"
#import "ChessView.h"


@class ChessView;
@protocol ChessViewDelegate;

@interface MCNconnecteur : NSObjectController <ChessViewDelegate>

   // Variables d'instance :
   {
   
   
   }


   // (1) le nom 'txtCoups' est choisi en référence à l'identifiant correspondant de
   // l'interface xib, mais ce rapprochement n'est pas exigé pour la compilation du programme

   // Création de la liaison entre le code et le Champ de Texte Scrollable
   @property (unsafe_unretained) IBOutlet NSTextView *txtCoups; // (1)
   // NB : la police de caractère utilisée dans txtCoups est fixée par 'AppDelegate'
   
   // Création de labels affichant diverses info sur la partie en cours
   @property (weak) IBOutlet NSTextField *lblEvalBoard;
   @property (weak) IBOutlet NSTextField *lblTrait;
   @property (weak) IBOutlet NSTextField *lblRoque;
   @property (weak) IBOutlet NSTextField *lblCibleEP;
   @property (weak) IBOutlet NSTextField *lbl50Coups;
   @property (weak) IBOutlet NSTextField *lblNumCoup;
   @property (weak) IBOutlet NSTextField *lblEchec;
   @property (weak) IBOutlet NSTextField *lblInfo;
   
   // Création du lien entre la Vue (ChessView) et le Contrôleur (MCNConnecteur)
   @property (weak) IBOutlet ChessView *maChessView;


   // Déclaration d'une Méthode pour l'INITIALISATION de la zone de texte 'txtCoups'
   // Elle n'est appelée que dans 'AppDelegate' pour le 1er coup des Blancs joués par l'IA
   -(void)InitialiseTxtCoups:(NSString *)textSortie;

   // Déclaration d'une Méthode pour la MISE A JOUR de la zone de texte 'txtCoups'
   // Elle n'est appelée dans 'MCNmoveToStr' pour chaque MàJ nécessaire de la liste des coups
   -(void)MaJtxtCoups;

   // Création des zones de texte assurant le repérage des cases
   @property (weak) IBOutlet NSTextField *lettresSideBlancs;
   @property (weak) IBOutlet NSTextField *lettresSideNoirs;
   @property (weak) IBOutlet NSTextField *chiffresSideBlancs;
   @property (weak) IBOutlet NSTextField *chiffresSideNoirs;
   @property (weak) IBOutlet NSTextField *lettresSideBlancsBas;
   @property (weak) IBOutlet NSTextField *lettresSideNoirsBas;
   @property (weak) IBOutlet NSTextField *chiffresSideBlancsGauche;
   @property (weak) IBOutlet NSTextField *chiffresSideNoirsGauche;

   // Définition de la méthode assurant la MàJ de ce repérage
   -(void) MajReperesCases;

   // Création de boutons fictifs ayant fonction d'indiquer qui doit jouer
   @property (weak) IBOutlet NSButton *indicIAdoitJouer;
   @property (weak) IBOutlet NSButton *indicJdoitJouer;

   // Méthode IB MCN du menu 'Partie->Difficulté'
   - (IBAction)SetDifficulty1:(id)sender;
   - (IBAction)SetDifficulty2:(id)sender;
   - (IBAction)SetDifficulty3:(id)sender;
   - (IBAction)SetDifficulty4:(id)sender;
   - (IBAction)SetDifficulty5:(id)sender;

   // Création des Outlet MCN pour gestion du menu 'Partie->Difficulté'
   @property (weak) IBOutlet NSMenuItem *menuRapide;
   @property (weak) IBOutlet NSMenuItem *menuFacile;
   @property (weak) IBOutlet NSMenuItem *menuSTD;
   @property (weak) IBOutlet NSMenuItem *menuReflechi;
   @property (weak) IBOutlet NSMenuItem *menuChampion;

   @property (weak) IBOutlet NSMenuItem *menuPoursuivre;

   /* Déclaration des Méthodes gérant les NSAlert déléguées */
   -(void) AlerteEchecRoiSide:(Side) side;


@end

