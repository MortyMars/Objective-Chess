//  MCNmoveToStr.h
//  Chess
//
//  Created by MCN on 22/02/2022.
//  Copyright © 2022 MCN. All rights reserved.

#include "ChessBoard.h"
#include "Minimax.h"


/* La Classe 'MCNmoveToStr' n'a de Classe que le nom car elle n'a pas vocation à générer des instances,
mais plutôt à définir des méthodes (de classe uniquement donc) qui s'apparentent plus dans leur role et
leur utilisation, à des fonctions c. Mais dans un projet Objective-C, le rendu global est + élégant ;-)
NB : c'est également le cas des très respectables classes 'Minimax' et 'RuleBook' */

@interface MCNmoveToStr : NSObject

   // No variable d'instance :
   {
      
   
   }

    // DÉCLARATION DES MÉTHODES, TOUTES DE CLASSE
    // Méthode générant une chaine décrivant un Move
    +(NSMutableString *) ConvertEnStringMove:(Move *) move
                                    PromPion:(NSString *) promPion
                                    StrEchec:(NSString *) strEchec
                                       Board:(ChessBoard *) board;

   
    // Méthode mettant en forme ordonnée la chaine ci-dessus
    +(void)              MettreEnFormeChaine:(NSString *) moveToStr
                                Protagoniste:(NSString *) strJ_IA;
                     
   
    // Méthode modifiant le repérage des cases en 'a1 à g8'
    +(NSString *)        Modif00EnA1:(Move *)move
                            surBoard:(ChessBoard*)board;



@end
