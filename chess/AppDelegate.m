//  AppDelegate.m
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

#import "AppDelegate.h"

@implementation AppDelegate

   @synthesize monMCNconnecteur; // MCN
   //@synthesize maMinimax;

   // ==================================================================================================
   // MÉTHODE SYSTÈME
   // MacOS peut sauvegarder et restaurer automatiquement l’état d’une application quand elle est relancée
   // (état fenêtres, contenu, etc.) et il est demandé au dev d'indiquer ses intentions vis-à-vis de cette
   // fonctionnalité. On indique ici notre accord, afin de faire taire le Warning récurent dans Xcode.
   - (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
       return YES;
   }

   // ==================================================================================================
   // UNIQUE RÉELLE MÉTHODE (d'instance) de la classe ayant pour objectif d'initialiser l'application
   - (void)applicationDidFinishLaunching:(NSNotification *)aNotification
   {
      /* L'appel ici, dans AppDelegate, de méthodes de la classe MCNconnecteur permet d'avoir l'assurance
      du chargement préalable de tous les objets de l'interface (instances de classes en particulier...)
      Un appel trop tôt dans le code, avec des objets encore 'nil' rendrait inefficace la mise à jour
      souhaitée de l'affichage (c'est en tous cas ce que je crois avoir compris...)  */
      
      // MCN - MàJ des repères de cases selon l'affichage standard
      sideJoueur = sideWhite;  sideIA = sideBlack; //choix arbitraire à ce stade, qui sera confirmé + tard
      [monMCNconnecteur MajReperesCases];
      
      /* MCN - MàJ du listing des coups joués
      'InitialiseTxtCoups' est appelée afin d'afficher le premier coup lorsque l'IA a les Blancs, sachant
      qu'il faut d'abord définir la police utilisée dans le contrôle txtCoups (exigence de TextView)...  */
      [monMCNconnecteur.txtCoups setFont:[NSFont fontWithName:@"Helvetica" size:14]];
      //[monMCNconnecteur InitialiseTxtCoups:stringCoupsPartie];
      
      // MCN - Initialisation des indicateurs
      monMCNconnecteur.indicIAdoitJouer.transparent = YES;
      monMCNconnecteur.indicJdoitJouer.transparent = NO;
      
      /* MCN - Initialisation du niveau de prospection de l'IA par appel de la méthode 'SetDifficulty' ad-hoc
      On note qu'ici c'est AppDelegate (self) qui envoi le message à SetDifficulty3 qui est une IBAction
      ici on choisit le niveau 2... qui correspond à fixer NUMBER_MOVE_AHEAD à 3
      (le mini = Difficulty1 -> NUMBER_MOVE_AHEAD = 0, et le maxi = Difficulty5 -> NUMBER_MOVE_AHEAD = 4) */
      [monMCNconnecteur SetDifficulty3:self];
      
      /* MCN - INITIALISATION DE LA VARIABLE GLOBALE 'monMCNcontroleur' DÉCLARÉE DANS 'UTIL.H'.
      LA VARIABLE EST IDENTIFIÉE ICI COMME ÉTANT L'OBJET 'monMCNconnecteur' INSTANCIÉ DANS APPDELEGATE.
      ELLE EN PREND AVANTAGEUSEMENT LA PLACE PUISQUE L'INSTANCE COURANTE 'monMCNconnecteur' PERDRA LE FOCUS
      SUR L'UI DÈS QUE L'ON SORTIRA DE 'APPLICATIONDIDFINISHLAUNCHING' ET N'AURA PLUS D'UTILITÉ.
      'monMCNcontroleur' DEVIENT DÈS LORS LE SEUL MOYEN EFFICACE D'INTERAGIR ULTÉRIEUREMENT ET DIRECTEMENT
      AVEC L'INTERFACE  DURANT TOUTE LA DURÉE DE VIE DE L'APPLICATION.
      (J'imagine qu'il doit exister un moyen plus élégant de parvenir aux mêmes fins, mais à ce stade de mes
      essais c'est le seul trouvé qui fonctionne efficacement, et c'est tout ce qui m'importe finalement.) */
      monMCNControleur = monMCNconnecteur;
      
      // Revoir finalité de cette commande car je ne me rappelle plus...
      monMCNControleur.maChessView.delegate = monMCNControleur;
      
      /* Initialisation de la variable */
      //maMinimax = maMinimax;
      maMinimax = [[Minimax alloc] init];
      
      
      // NSLog pour le fun...
      NSLog(@"Welcome sur Objective-Chess\n");
      //NSLog(@"La taille de stockage pour un 'int' est de %li bits", sizeof(int));
      //NSLog(@"La valeur maxi pour un 'int' est ±%d \n",INT_MAX);
      
      // MCN - NSLog de contrôle
      NSLog(@"Interface initialisée et chargée\n");
      
   } // Fin de Méthode 'applicationDidFinishLaunching'

@end

