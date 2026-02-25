// Connecteur.h
// Chess
// Created by MCN on 01/11/2020.
// Copyright © 2020 MCN - All rights reserved

#import "Minimax.h"
#import "ChessView.h"


@class ChessView;
@protocol ChessViewDelegate;

@interface Connecteur : NSObjectController <ChessViewDelegate>

   // Variables d'instance :
   {
   
   
   }

   
   // Création de la liaison entre le code et le Champ de Texte Scrollable
   @property (unsafe_unretained) IBOutlet NSTextView *txtCoups; // (1)
   // (1) le nom 'txtCoups' est choisi en référence à l'identifiant correspondant de
   // l'interface xib, mais ce rapprochement n'est pas exigé pour la compilation du programme
   // NB : la police de caractère utilisée dans txtCoups est fixée par 'AppDelegate'
   
   
   // Création de labels affichant diverses info sur la partie en cours
   /* Rappel sur la façon de procéder :
   1) on crée ci-dessous un IBOutlet
   2) via l'éditeur->Assistant, on 'tire' un lien entre la zone de texte
      de l'interface qui nous intéresse et l'objet 'monConnecteur'
   3) à partir de là 'monConnecteur' pilote le contenu du lbl créé    */
   @property (weak) IBOutlet NSTextField *lblEvalBoard;
   @property (weak) IBOutlet NSTextField *lblTrait;
   @property (weak) IBOutlet NSTextField *lblRoque;
   @property (weak) IBOutlet NSTextField *lblCibleEP;
   @property (weak) IBOutlet NSTextField *lbl50Coups;
   @property (weak) IBOutlet NSTextField *lblNumCoup;
   @property (weak) IBOutlet NSTextField *lblEchec;
   @property (weak) IBOutlet NSTextField *lblInfo;
   @property (weak) IBOutlet NSTextField *lblCoupProposed;

   
   // Création du lien entre la Vue (ChessView) et le Contrôleur (MCNConnecteur)
   @property (weak) IBOutlet ChessView *maChessView;


   // Déclaration d'une Méthode pour l'INITIALISATION de la zone de texte 'txtCoups'
   // Elle n'est appelée que dans 'AppDelegate' pour le 1er coup des Blancs joués par l'IA
   -(void)InitialiseTxtCoups:(NSString *)textSortie;

   
   // Déclaration d'une Méthode pour la MISE A JOUR de la zone de texte 'txtCoups'
   // Elle n'est appelée dans 'MoveToStr' pour chaque MàJ nécessaire de la liste des coups
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
   -(IBAction)SetDifficulty1:(id)sender;
   -(IBAction)SetDifficulty2:(id)sender;
   -(IBAction)SetDifficulty3:(id)sender;
   -(IBAction)SetDifficulty4:(id)sender;
   -(IBAction)SetDifficulty5:(id)sender;

   
   // Création des Outlet MCN pour gestion du menu 'Partie->Difficulté'
   @property (strong) IBOutlet NSMenuItem *menuRapide;
   @property (strong) IBOutlet NSMenuItem *menuFacile;
   @property (strong) IBOutlet NSMenuItem *menuSTD;
   @property (strong) IBOutlet NSMenuItem *menuReflechi;
   @property (strong) IBOutlet NSMenuItem *menuChampion;
   @property (strong) IBOutlet NSMenuItem *menuPoursuivre;

   
   /* Déclaration des Méthodes gérant les NSAlert déléguées */
   -(void)AlertMsgEchecSide:(Side)side;
   -(void)AlertMsgPatMatSide:(Side)side onBoard:(ChessBoard*)board;


@end

