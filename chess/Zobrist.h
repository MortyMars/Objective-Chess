// Zobrist.h
// Chess
// Created by MortyMars on 2026-02-08.


#import <stdint.h>
#import <stdlib.h>


// TABLES GLOBALES ZOBRIST
extern uint64_t zobristPiece[2][7][64]; // 2 couleurs, 7 types de pièces, et 64 cases
extern uint64_t zobristSide;
extern uint64_t zobristCastle[16];
extern uint64_t zobristEnPassant[8];


// MÉTHODES GLOBALES
extern void InitZobrist(void);
