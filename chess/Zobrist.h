//  Zobrist.h
//  Chess
//  Created by MCN on 2026-02-08.
//  Copyright © 2026 MCN - All rights reserved

#import <stdint.h>
#import <stdlib.h>

/*========= LIGNE À COMMENTER /DÉCOMMENTER EN FONCTION DES BESOINS DE DEBUG ==========*/
/*                                                                                    */
#define DEBUG_ZOBRIST   // DEBUG_ZOBRIST mis en place dans Negamax et Quiescence       /
/*                                                                                    */
/*============== FIN D'ACTIVATION /DÉSACTIVATION DE DEBUG_ZOBRIST ====================*/


// =====================================================================================================
// TABLES GLOBALES ZOBRIST
extern uint64_t zobristPiece[2][7][64]; // 2 couleurs, 7 types de pièces, et 64 cases
extern uint64_t zobristSide;
extern uint64_t zobristCastle[16];
extern uint64_t zobristEnPassant[8];

// =====================================================================================================
// MÉTHODES GLOBALES
extern void InitZobrist(void);
