//  Zobrist.h
//  Chess
//  Created by MCN on 2026-02-08.
//  Copyright © 2026 MCN - All rights reserved

// =====================================================================================================
// TABLES GLOBALES ZOBRIST
extern uint64_t zobristPiece[2][6][64];
extern uint64_t zobristSide;
extern uint64_t zobristCastle[16];
extern uint64_t zobristEnPassant[8];

// =====================================================================================================
// MÉTHODES GLOBALES
extern void InitZobrist(void);
