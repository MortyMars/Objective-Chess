//  Minimax.h
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 2020
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "MCNconnecteur.h"
#import "MCNmoveToStr.h"
#import "Piece.h"



@class Move, ChessBoard; // compte tenu de l'appel de ces 2 classes dans la classe Minimax


@interface Minimax : NSObject

    // DÉCLARATION DES VARIABLES D'INSTANCE
    // (logiquement vide car Minimax n'a pas vocation à avoir d'instances)
    {
   
    }

    // DÉCLARATION DES MÉTHODES DE CLASSE
    // Méthode de classe déterminant le meilleur coup pour 'side''
    +(Move *)     BestMoveForSide:(Side)side             // côté blanc ou côté noir
                            board:(ChessBoard *)board;   // et selon la configuration de l'échiquier courant

    // Méthode de classe évaluant l'échiquier à un moment donné de la partie
    +(int)        EvalBoardForSide:(Side)side
                             board:(ChessBoard *)board;

    // Méthode déterminant tous les coups possibles pour un 'side'
    +(NSSet *)    PossibleMovesForSide:(Side)side
                                 board:(ChessBoard *)board;

    // Méthode notifiant s'il y a Pat ou Mat des 'side'
    +(void)       NotifiePatMatDesSide:(Side)side
                               onBoard:(ChessBoard*)board;
   

    // MÉTHODES DE CLASSE MCN
    // Méthode testant si 'side' met son adversaire en échec
    +(NSString *) TestEchecFavSide:(Side)side
                             Board:(ChessBoard *)board;

    // Méthode testant si le roi 'side' est en échec
    +(BOOL)       TestEchecRoiSide:(Side)side
                           inBoard:(ChessBoard*)board;

    // DÉCLARATION DE MÉTHODES AFIN QU'ELLES SOIENT VISIBLES POUR LES TESTS
    +(int)        NegamaxForSide:(Side)side
                           board:(ChessBoard *)board
                           depth:(int)depth
                           alpha:(int)alpha
                            beta:(int)beta;


@end
