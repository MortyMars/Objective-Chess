// Zobrist.m
// Chess
// Created by MortyMars on 2026-02-08.


#import "Zobrist.h"
#import "ChessConfig.h"


// INITIALISATION DES TABLES GLOBALES
uint64_t zobristPiece[2][7][64];
uint64_t zobristSide;
uint64_t zobristCastle[16];
uint64_t zobristEnPassant[8];


// IMPLÉMENTATION DES FONCTIONS ZOBRIST

// Générateur de nombre aléatoire
static uint64_t rand64(void) {
    return ((uint64_t)arc4random() << 32) | arc4random();
}

// Initialisateur de la clé Zobrist
void InitZobrist(void) {
   
    for (int s = 0; s < 2; s++)                    // 2 sides
        for (int p = 0; p < 7; p++)                // 7 types de Pièces (cis 'Invalide')
            for (int sq = 0; sq < 64; sq++)        // 64 cases
                zobristPiece[s][p][sq] = rand64();

    zobristSide = rand64();

    for (int i = 0; i < 16; i++)
        zobristCastle[i] = rand64();

    for (int i = 0; i < 8; i++)
        zobristEnPassant[i] = rand64();
}
