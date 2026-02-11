//  Zobrist.h
//  Chess
//  Created by MCN on 2026-02-08.
//  Copyright © 2026 MCN - All rights reserved


// =====================================================================================================
// Initialisation des tables glogales
uint64_t zobristPiece[2][6][64];
uint64_t zobristSide;
uint64_t zobristCastle[16];
uint64_t zobristEnPassant[8];




// =====================================================================================================
// Implémentation des fonctions Zobrist

// Générateur de nombre aléatoire
static uint64_t rand64(void)
{
    return ((uint64_t)arc4random() << 32) | arc4random();
}

// Initialisateur de la clé Zobrist
void InitZobrist(void)
{
    for (int s = 0; s < 2; s++)
        for (int p = 0; p < 6; p++)
            for (int sq = 0; sq < 64; sq++)
                zobristPiece[s][p][sq] = rand64();

    zobristSide = rand64();

    for (int i = 0; i < 16; i++)
        zobristCastle[i] = rand64();

    for (int i = 0; i < 8; i++)
        zobristEnPassant[i] = rand64();
}
