//  AppDelegate.h
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020

#import "MCNconnecteur.h"

//Rappel au compilateur que MCNconnecteur est une classe, définie ailleurs
@class MCNconnecteur;

// Déclaration de la classe AppDelegate, ...qui adopte le Protocol <NSApplicationDelegate>
@interface AppDelegate : NSObject <NSApplicationDelegate>

   @property (assign) IBOutlet NSWindow *window;
   
   // MCN - Déclaration du MCNconnecteur instancié par AppDelegate
   @property (strong) IBOutlet MCNconnecteur *monMCNconnecteur;

   // Déclaration de l'unique méthode d'instance
   - (void)applicationDidFinishLaunching:(NSNotification *)aNotification;


@end
