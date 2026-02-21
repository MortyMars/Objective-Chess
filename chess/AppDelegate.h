// AppDelegate.h
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Updated by MCN in 2020

#import "Connecteur.h"
#import "Minimax.h"
#import "Util.h"        // Pour accéder à monConnecteur

//Rappel au compilateur que Connecteur est une classe, définie ailleurs
@class Connecteur;

// Déclaration de la classe AppDelegate, ...qui adopte le Protocol <NSApplicationDelegate>
@interface AppDelegate : NSObject <NSApplicationDelegate>

   @property (assign) IBOutlet NSWindow *window;
   
   // IBOutlet pour Interface Builder (nom distinct pour éviter toute confusion)
   // L'instance sera ensuite assignée à la variable globale 'monConnecteur'
   @property (strong) IBOutlet Connecteur *connecteurFromIB;

   //@property Minimax *maMinimax;

   // Déclaration de l'unique méthode d'instance
   - (void)applicationDidFinishLaunching:(NSNotification *)aNotification;


@end

