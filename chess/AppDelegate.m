// AppDelegate.m
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Updated by MCN in 2020

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
      
      /* INITIALISATION DE LA VARIABLE GLOBALE 'monConnecteur' DÉCLARÉE DANS 'UTIL.H'.
      L'instance créée par Interface Builder 'connecteurFromIB' est assignée à la variable globale
      'monConnecteur' qui devient ainsi accessible depuis n'importe quelle classe qui importe Util.h,
      tout en restant retenue en mémoire durant toute la durée de vie de l'application. */
      monConnecteur = connecteurFromIB;
      
      
      // MÀJ des repères de cases selon l'affichage standard
      sideJoueur = sideWhite;  sideIA = sideBlack; //choix arbitraire à ce stade, qui sera confirmé + tard
      [monConnecteur MajReperesCases];
      
      /* MÀJ du listing des coups joués
      'InitialiseListeCoupsPartie' est appelée afin d'afficher le premier coup lorsque l'IA a les Blancs, sachant
      qu'il faut d'abord définir la police utilisée dans le contrôle txtListeCoupsPartie (exigence de TextView)...  */
      [monConnecteur.txtListeCoupsPartie setFont:[NSFont fontWithName:@"Helvetica" size:14]];
      //[monConnecteur InitialiseListeCoupsPartie:stringCoupsPartie];
      
      // Initialisation des indicateurs
      monConnecteur.indicIAdoitJouer.transparent = YES;
      monConnecteur.indicJdoitJouer.transparent = NO;
      
      /* Initialisation du niveau de prospection IA par appel à la méthode ad-hoc
      On note que c'est AppDelegate (self) qui envoit le message à SetDifficultyX
      Ici on choisit le niveau 3, qui correspond à fixer NUMBER_MOVE_AHEAD à 8 */
      [monConnecteur SetDifficulty3:self];
      
      
      // Revoir finalité de cette commande car je ne me rappelle plus...
      monConnecteur.maChessView.delegate = monConnecteur;
      
      /* Initialisation de la variable */
      //maMinimax = maMinimax;
      maMinimax = [[Minimax alloc] init];
      
      // MCN - NSLog de contrôle
      NSLog(@"Interface initialisée et chargée");
      NSLog(@"Welcome sur Objective-Chess 😉\n");
      
      // Initialisation de la clé de hachage Zobrist
      InitZobrist();
      
      // DEBUG *********** Test d'involution ************ DEBUG
      //TestInvolution(monConnecteur.maChessView->liveBoard);

      
   } // !applicationDidFinishLaunching


@end




