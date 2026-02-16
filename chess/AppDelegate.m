//  AppDelegate.m
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

#import "AppDelegate.h"
#import "ChessConfig.h"
#import "Zobrist.h"

@implementation AppDelegate

   @synthesize connecteurFromIB; // MCN - IBOutlet pour Interface Builder
   //@synthesize maMinimax;

   // ==================================================================================================
   // MÉTHODE SYSTÈME
   // MacOS peut sauvegarder et restaurer automatiquement l'état d'une application quand elle est relancée
   // (état fenêtres, contenu, etc.) et il est demandé au dev d'indiquer ses intentions vis-à-vis de cette
   // fonctionnalité. On indique ici notre accord, afin de faire taire le Warning récurent dans Xcode.
   - (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
       return YES;
   }

   // ==================================================================================================
   // UNIQUE RÉELLE MÉTHODE (d'instance) de la classe ayant pour objectif d'initialiser l'application
   - (void)applicationDidFinishLaunching:(NSNotification *)aNotification
   {
      /* L'appel ici, dans AppDelegate, de méthodes de la classe Connecteur permet d'avoir l'assurance
      du chargement préalable de tous les objets de l'interface (instances de classes en particulier...)
      Un appel trop tôt dans le code, avec des objets encore 'nil' rendrait inefficace la mise à jour
      souhaitée de l'affichage (c'est en tous cas ce que je crois avoir compris...)  */
      
      /* MCN - INITIALISATION DE LA VARIABLE GLOBALE 'monConnecteur' DÉCLARÉE DANS 'UTIL.H'.
      L'instance créée par Interface Builder 'connecteurFromIB' est assignée à la variable globale
      'monConnecteur' qui devient ainsi accessible depuis n'importe quelle classe qui importe Util.h,
      tout en restant retenue en mémoire durant toute la durée de vie de l'application. */
      monConnecteur = connecteurFromIB;
      
      
      // MCN - MÀJ des repères de cases selon l'affichage standard
      sideJoueur = sideWhite;  sideIA = sideBlack; //choix arbitraire à ce stade, qui sera confirmé + tard
      [monConnecteur MajReperesCases];
      
      /* MCN - MÀJ du listing des coups joués
      'InitialiseTxtCoups' est appelée afin d'afficher le premier coup lorsque l'IA a les Blancs, sachant
      qu'il faut d'abord définir la police utilisée dans le contrôle txtCoups (exigence de TextView)...  */
      [monConnecteur.txtCoups setFont:[NSFont fontWithName:@"Helvetica" size:14]];
      //[monConnecteur InitialiseTxtCoups:stringCoupsPartie];
      
      // MCN - Initialisation des indicateurs
      monConnecteur.indicIAdoitJouer.transparent = YES;
      monConnecteur.indicJdoitJouer.transparent = NO;
      
      /* MCN - Initialisation du niveau de prospection de l'IA par appel de la méthode 'SetDifficulty' ad-hoc
      On note qu'ici c'est AppDelegate (self) qui envoi le message à SetDifficulty3 qui est une IBAction
      ici on choisit le niveau 2... qui correspond à fixer NUMBER_MOVE_AHEAD à 3
      (le mini = Difficulty1 -> NUMBER_MOVE_AHEAD = 0, et le maxi = Difficulty5 -> NUMBER_MOVE_AHEAD = 4) */
      [monConnecteur SetDifficulty2:self];
      
      
      
      // Revoir finalité de cette commande car je ne me rappelle plus...
      monConnecteur.maChessView.delegate = monConnecteur;
      
      /* Initialisation de la variable */
      //maMinimax = maMinimax;
      maMinimax = [[Minimax alloc] init];
      
      
      // NSLog pour le fun...
      NSLog(@"Welcome sur Objective-Chess\n");
      //NSLog(@"La taille de stockage pour un 'int' est de %li bits", sizeof(int));
      //NSLog(@"La valeur maxi pour un 'int' est ±%d \n",INT_MAX);
      
      // MCN - NSLog de contrôle
      NSLog(@"Interface initialisée et chargée\n");
      
      // Initialisation de la clé de hachage Zobrist
      InitZobrist();
      
      // DEBUG *********** Test d'involution ************ DEBUG
      //TestInvolution(monConnecteur.maChessView->liveBoard);

      
   } // !applicationDidFinishLaunching




@end




