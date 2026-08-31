// Minimax+OpeningBook.m
// chess
// Created by MortyMars on 18/03/2026


#import "Minimax+OpeningBook.h"
#import "Minimax+GenMoves.h"
#import "ChessBoard+MakeMoves.h"



@implementation Minimax (OpeningBook) // Extension de la Classe Minimax

   // ================================================================================================
   // OPENING BOOK ÉTENDU — buildOpeningBook
   // Couverture : 1.e4, 1.d4, 1.c4, 1.Cf3 + réponses Noirs + développement jusqu'au coup 8
   // Format : FEN partiel (pièces + trait) → tableau de coups candidats
   -(void)buildOpeningBook {
      self.openingBook = (NSDictionary<NSString *, NSArray<NSString *> *> *)@{
         
         // ============================================================
         // POSITION INITIALE
         @"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w" :
            @[@"e2e4", @"d2d4", @"c2c4", @"g1f3"],
         
         // ============================================================
         // APRÈS 1.e4
         @"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b" :
            @[@"e7e5", @"c7c5", @"e7e6", @"c7c6", @"d7d5", @"g8f6"],
         
         // ── 1.e4 e5 — Ouvertures ouvertes ───────────────────────────
         @"rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w" :
            @[@"g1f3", @"f2f4", @"b1c3", @"f1c4"],
         
         // 1.e4 e5 2.Cf3
         @"rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b" :
            @[@"b8c6", @"g8f6", @"d7d6", @"f7f5"],
         
         // 1.e4 e5 2.Cf3 Cc6
         @"r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w" :
            @[@"f1b5", @"f1c4", @"d2d4", @"b1c3"],
         
         // ── Ruy Lopez : 1.e4 e5 2.Cf3 Cc6 3.Fb5 ────────────────────
         @"r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b" :
            @[@"a7a6", @"g8f6", @"f7f5", @"d7d6"],
         
         // Ruy Lopez 3...a6 4.Fa4
         @"r1bqkbnr/1ppp1ppp/p1n5/4p3/B3P3/5N2/PPPP1PPP/RNBQK2R w" :
            @[@"f1a4", @"f1c4", @"e1g1"],
         
         // Ruy Lopez 3...a6 4.Fa4 Cf6 5.0-0
         @"r1bqkb1r/1ppp1ppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQ1RK1 b" :
            @[@"f8e7", @"b7b5", @"d7d6"],
         
         // Ruy Lopez 5...Fe7 6.Te1
         @"r1bqk2r/1pppbppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQR1K1 b" :
            @[@"b7b5", @"d7d6", @"e8g8"],
         
         // Ruy Lopez 6...b5 7.Fb3
         @"r1bqk2r/2ppbppp/p1n2n2/1p2p3/4P3/1B3N2/PPPP1PPP/RNBQR1K1 b" :
            @[@"d7d6", @"e8g8", @"c6a5"],
         
         // ── Giuoco Piano : 1.e4 e5 2.Cf3 Cc6 3.Fc4 ─────────────────
         @"r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b" :
            @[@"f8c5", @"g8f6", @"f7f5", @"d7d6"],
         
         // Giuoco Piano 3...Fc5 4.c3
         @"r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/2P2N2/PP1P1PPP/RNBQK2R b" :
            @[@"g8f6", @"d7d6", @"a7a6"],
         
         // Giuoco Piano 3...Fc5 4.c3 Cf6 5.d4
         @"r1bqk2r/pppp1ppp/2n2n2/2b1p3/2BPP3/2P2N2/PP3PPP/RNBQK2R b" :
            @[@"e5d4", @"f8b4", @"d7d6"],
         
         // Giuoco Piano 3...Fc5 4.0-0
         @"r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b" :
            @[@"g8f6", @"d7d6", @"f7f5"],
         
         // ── Italien avancé : 1.e4 e5 2.Cf3 Cc6 3.Fc4 Cf6 4.d3 ──────
         @"r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R b" :
            @[@"f8c5", @"f8e7", @"d7d6"],
         
         // ── Défense des Deux Cavaliers : 3...Cf6 ────────────────────
         @"r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w" :
            @[@"d2d3", @"e1g1", @"c2c3", @"d2d4"],
         
         // ── Partie Ecossaise : 1.e4 e5 2.Cf3 Cc6 3.d4 ──────────────
         @"r1bqkbnr/pppp1ppp/2n5/4p3/3PP3/5N2/PPP2PPP/RNBQKB1R b" :
            @[@"e5d4", @"f7f5", @"d7d6"],
         
         // Ecossaise 3...exd4 4.Cxd4
         @"r1bqkbnr/pppp1ppp/2n5/8/3pP3/5N2/PPP2PPP/RNBQKB1R w" :
            @[@"f3d4"],
         
         @"r1bqkbnr/pppp1ppp/2n5/8/3NP3/8/PPP2PPP/RNBQKB1R b" :
            @[@"f8c5", @"g8f6", @"d8h4"],
         
         // Ecossaise 4...Fc5 5.Fe3
         @"r1bqk1nr/pppp1ppp/2n5/2b5/3NP3/4B3/PPP2PPP/RN1QKB1R b" :
            @[@"d8f6", @"g8e7", @"d7d6"],
         
         // ── Défense Sicilienne : 1.e4 c5 ────────────────────────────
         @"rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w" :
            @[@"g1f3", @"b1c3", @"c2c3", @"f2f4"],
         
         // Sicilienne 2.Cf3
         @"rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b" :
            @[@"b8c6", @"d7d6", @"e7e6", @"a7a6", @"g8f6"],
         
         // Sicilienne 2.Cf3 d6 3.d4
         @"rnbqkbnr/pp2pppp/3p4/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R b" :
            @[@"c5d4", @"g8f6"],
         
         // Sicilienne 2.Cf3 d6 3.d4 cxd4 4.Cxd4
         @"rnbqkbnr/pp2pppp/3p4/8/3NP3/8/PPP2PPP/RNBQKB1R b" :
            @[@"g8f6", @"b8c6", @"a7a6"],
         
         // Sicilienne Najdorf : ...a6
         @"rnbqkb1r/1p2pppp/p2p1n2/8/3NP3/2N5/PPP2PPP/R1BQKB1R w" :
            @[@"f1e2", @"c1g5", @"c1e3", @"f2f3"],
         
         // Sicilienne Dragon : ...g6
         @"rnbqkb1r/pp2pp1p/3p1np1/8/3NP3/2N5/PPP2PPP/R1BQKB1R w" :
            @[@"c1e3", @"f1e2", @"f2f3"],
         
         // Sicilienne 2.Cf3 Cc6 3.d4
         @"r1bqkbnr/pp1ppppp/2n5/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R b" :
            @[@"c5d4", @"e7e6", @"d7d6"],
         
         // Sicilienne 2.Cf3 Cc6 3.d4 cxd4 4.Cxd4
         @"r1bqkbnr/pp1ppppp/2n5/8/3NP3/8/PPP2PPP/RNBQKB1R b" :
            @[@"g8f6", @"e7e6", @"d7d6", @"e7e5"],
         
         // Sicilienne Scheveningen : ...e6
         @"r1bqkb1r/pp3ppp/2nppn2/8/3NP3/2N5/PPP2PPP/R1BQKB1R w" :
            @[@"f1e2", @"c1e3", @"c1g5"],
         
         // Sicilienne 2.c3
         @"rnbqkbnr/pp1ppppp/8/2p5/4P3/2P5/PP1P1PPP/RNBQKBNR b" :
            @[@"g8f6", @"d7d5", @"e7e6", @"b8c6"],
         
         
         // ── Défense Française : 1.e4 e6 ─────────────────────────────
         @"rnbqkbnr/pppp1ppp/4p3/8/4P3/8/PPPP1PPP/RNBQKBNR w" :
            @[@"d2d4", @"d2d3", @"g1f3", @"b1c3"],
         
         // Française 2.d4 d5
         @"rnbqkbnr/pppp1ppp/4p3/8/3PP3/8/PPP2PPP/RNBQKBNR b" :
            @[@"d7d5", @"c7c5", @"g8f6"],
         
         // Française 2.d4 d5 3.Cc3
         @"rnbqkbnr/ppp2ppp/4p3/3p4/3PP3/2N5/PPP2PPP/R1BQKBNR b" :
            @[@"g8f6", @"f8b4", @"d5e4", @"c7c5"],
         
         // Française variante Winawer : 3.Cc3 Fb4
         @"rnbqk1nr/ppp2ppp/4p3/3p4/1b1PP3/2N5/PPP2PPP/R1BQKBNR w" :
            @[@"e4e5", @"a2a3", @"d1g4"],
         
         // Française variante classique : 3.Cc3 Cf6 4.Fg5
         @"rnbqkb1r/ppp2ppp/4pn2/3p2B1/3PP3/2N5/PPP2PPP/R2QKBNR b" :
            @[@"f8e7", @"d5e4", @"h7h6"],
         
         // Française 3.e5 (avancée)
         @"rnbqkbnr/ppp2ppp/4p3/3pP3/3P4/8/PPP2PPP/RNBQKBNR b" :
            @[@"c7c5", @"b8c6", @"g8e7"],
         
         // Française avancée 3...c5 4.c3
         @"rnbqkbnr/pp3ppp/4p3/2ppP3/3P4/2P5/PP3PPP/RNBQKBNR b" :
            @[@"b8c6", @"d8b6", @"g8e7"],
         
         
         // ── Défense Caro-Kann : 1.e4 c6 ─────────────────────────────
         @"rnbqkbnr/pp1ppppp/2p5/8/4P3/8/PPPP1PPP/RNBQKBNR w" :
            @[@"d2d4", @"b1c3", @"g1f3"],
         
         // Caro-Kann 2.d4 d5
         @"rnbqkbnr/pp2pppp/2p5/3p4/3PP3/8/PPP2PPP/RNBQKBNR w" :
            @[@"b1c3", @"e4e5", @"e4d5", @"g1f3"],
         
         // Caro-Kann 2.d4 d5 3.Cc3 dxe4 4.Cxe4
         @"rnbqkbnr/pp2pppp/2p5/8/3PN3/8/PPP2PPP/R1BQKBNR b" :
            @[@"c8f5", @"g8f6", @"b8d7"],
         
         // Caro-Kann classique 3...Cf6 4.Cf3
         @"rnbqkb1r/pp2pppp/2p2n2/8/3PN3/5N2/PPP2PPP/R1BQKB1R b" :
            @[@"e7e6", @"c8f5", @"b8d7"],
         
         
         // ── Défense Pirc/Moderne : 1.e4 d6 ─────────────────────────
         @"rnbqkbnr/ppp1pppp/3p4/8/4P3/8/PPPP1PPP/RNBQKBNR w" :
            @[@"d2d4", @"g1f3", @"b1c3"],
         
         // Pirc 2.d4 Cf6 3.Cc3
         @"rnbqkb1r/ppp1pppp/3p1n2/8/3PP3/2N5/PPP2PPP/R1BQKBNR b" :
            @[@"g7g6", @"c7c6", @"e7e5"],
         
         // Pirc 3...g6 4.f4 (système autrichien)
         @"rnbqkb1r/ppp1pp1p/3p1np1/8/3PPP2/2N5/PPP3PP/R1BQKBNR b" :
            @[@"f8g7", @"c7c6", @"e7e5"],
         
         
         // ── Défense Scandinave : 1.e4 d5 ────────────────────────────
         @"rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w" :
            @[@"e4d5", @"e4e5"],
         
         // Scandinave 2.exd5 Dxd5 3.Cc3
         @"rnbqkbnr/ppp1pppp/8/3Q4/8/2N5/PPPP1PPP/R1BQKBNR b" :
            @[@"d5a5", @"d5d6", @"d5d8"],
         
         // Scandinave 2.exd5 Cf6
         @"rnbqkb1r/ppp1pppp/5n2/3P4/8/8/PPPP1PPP/RNBQKBNR w" :
            @[@"d2d4", @"b1c3", @"g1f3"],
         
         
         // ============================================================
         // APRÈS 1.d4
         @"rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b" :
            @[@"d7d5", @"g8f6", @"e7e6", @"c7c5", @"f7f5"],
         
         
         // ── 1.d4 d5 — Gambit Dame et dérivés ────────────────────────
         @"rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w" :
            @[@"c2c4", @"g1f3", @"e2e3", @"c2c3"],
         
         // Gambit Dame : 1.d4 d5 2.c4
         @"rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b" :
            @[@"e7e6", @"c7c6", @"d5c4", @"g8f6", @"e7e5"],
         
         // GD accepté : 2...dxc4 3.Cf3
         @"rnbqkbnr/ppp1pppp/8/8/2pP4/5N2/PP2PPPP/RNBQKB1R b" :
            @[@"g8f6", @"e7e6", @"a7a6"],
         
         // GD refusé : 2...e6 3.Cc3
         @"rnbqkbnr/ppp2ppp/4p3/3p4/2PP4/2N5/PP2PPPP/R1BQKBNR b" :
            @[@"g8f6", @"c7c6", @"f8e7", @"b8d7"],
         
         // GD refusé 3...Cf6 4.Fg5
         @"rnbqkb1r/ppp2ppp/4pn2/3p2B1/2PP4/2N5/PP2PPPP/R2QKBNR b" :
            @[@"f8e7", @"b8d7", @"h7h6"],
         
         // GD refusé 3...Cf6 4.Fg5 Fe7 5.e3
         @"rnbqk2r/ppp1bppp/4pn2/3p2B1/2PP4/2N1P3/PP3PPP/R2QKBNR b" :
            @[@"e8g8", @"h7h6", @"b8d7"],
         
         // GD refusé 5...0-0 6.Cf3
         @"rnbq1rk1/ppp1bppp/4pn2/3p2B1/2PP4/2N1PN2/PP3PPP/R2QKB1R b" :
            @[@"b8d7", @"h7h6", @"c7c6"],
         
         // Défense slave : 2...c6
         @"rnbqkbnr/pp2pppp/2p5/3p4/2PP4/8/PP2PPPP/RNBQKBNR w" :
            @[@"g1f3", @"b1c3", @"e2e3"],
         
         // Slave 3.Cf3 Cf6 4.Cc3
         @"rnbqkb1r/pp2pppp/2p2n2/3p4/2PP4/2N2N2/PP2PPPP/R1BQKB1R b" :
            @[@"e7e6", @"d5c4", @"a7a6", @"c8f5"],
         
         
         // ── 1.d4 Cf6 — Systèmes indiens ─────────────────────────────
         @"rnbqkb1r/pppppppp/5n2/8/3P4/8/PPP1PPPP/RNBQKBNR w" :
            @[@"c2c4", @"g1f3", @"b1c3", @"c1g5"],
         
         // 1.d4 Cf6 2.c4
         @"rnbqkb1r/pppppppp/5n2/8/2PP4/8/PP2PPPP/RNBQKBNR b" :
            @[@"e7e6", @"g7g6", @"c7c5", @"d7d5", @"e7e5"],
         
         // ── Nimzo-Indienne : 2...e6 3.Cc3 Fb4 ──────────────────────
         @"rnbqkb1r/pppp1ppp/4pn2/8/2PP4/2N5/PP2PPPP/R1BQKBNR b" :
            @[@"f8b4", @"f8e7", @"d7d5", @"c7c5"],
         
         @"rnbqk2r/pppp1ppp/4pn2/8/1bPP4/2N5/PP2PPPP/R1BQKBNR w" :
            @[@"d1c2", @"e2e3", @"f2f3", @"a2a3"],
         
         // Nimzo 4.Dc2 0-0 5.e4
         @"rnbq1rk1/pppp1ppp/4pn2/8/1bPPP3/2N5/PPQ2PPP/R1B1KBNR b" :
            @[@"d7d5", @"c7c5", @"b8c6"],
         
         // Nimzo 4.e3 0-0 5.Fd3
         @"rnbq1rk1/pppp1ppp/4pn2/8/1bPP4/2N1P3/PP1B1PPP/R2QKBNR b" :
            @[@"d7d5", @"c7c5", @"b8c6"],
         
         // ── Défense Est-Indienne : 2...g6 3.Cc3 Fg7 ────────────────
         @"rnbqkb1r/pppppp1p/5np1/8/2PP4/2N5/PP2PPPP/R1BQKBNR b" :
            @[@"f8g7", @"d7d6", @"c7c5"],
         
         @"rnbqk2r/ppppppbp/5np1/8/2PP4/2N5/PP2PPPP/R1BQKBNR w" :
            @[@"e2e4", @"g1f3", @"c1f4"],
         
         // Est-Indienne 4.e4 d6 5.Cf3
         @"rnbqk2r/ppp1ppbp/3p1np1/8/2PPP3/2N2N2/PP3PPP/R1BQKB1R b" :
            @[@"e8g8", @"e7e5", @"c7c5"],
         
         // Est-Indienne 5...0-0 6.Fe2
         @"rnbq1rk1/ppp1ppbp/3p1np1/8/2PPP3/2N2N2/PP2BPPP/R1BQK2R b" :
            @[@"e7e5", @"c7c5", @"b8a6"],
         
         // Est-Indienne 6...e5 7.0-0
         @"rnbq1rk1/ppp2pbp/3p1np1/4p3/2PPP3/2N2N2/PP2BPPP/R1BQ1RK1 b" :
            @[@"b8c6", @"b8a6", @"f8e8"],
         
         // ── Défense Grünfeld : 2...g6 3.c4 d5 ──────────────────────
         @"rnbqkb1r/ppp1pp1p/5np1/3p4/2PP4/2N5/PP2PPPP/R1BQKBNR w" :
            @[@"c4d5", @"g1f3", @"e2e4"],
         
         // Grünfeld 4.cxd5 Cxd5 5.e4
         @"rnbqkb1r/ppp1pp1p/6p1/3n4/3PP3/2N5/PP3PPP/R1BQKBNR b" :
            @[@"d5c3", @"d5f6", @"d5b6"],
         
         // Grünfeld 5...Cxc3 6.bxc3 Fg7
         @"rnbqk2r/ppp1pp1p/6p1/8/3PP3/2P5/P4PPP/R1BQKBNR b" :
            @[@"f8g7", @"c7c5", @"d8d6"],
         
         
         // ── 1.d4 f5 — Défense Hollandaise ───────────────────────────
         @"rnbqkbnr/ppppp1pp/8/5p2/3P4/8/PPP1PPPP/RNBQKBNR w" :
            @[@"g2g3", @"c2c4", @"g1f3"],
         
         // Hollandaise 2.g3 Cf6 3.Fg2
         @"rnbqkb1r/ppppp1pp/5n2/5p2/3P4/6P1/PPP1PP1P/RNBQKBNR w" :
            @[@"f1g2", @"g1f3"],
         
         
         // ── 1.d4 c5 — Défense Benoni ────────────────────────────────
         @"rnbqkbnr/pp1ppppp/8/2p5/3P4/8/PPP1PPPP/RNBQKBNR w" :
            @[@"d4d5", @"g1f3", @"c2c3"],
         
         // Benoni moderne : 1.d4 Cf6 2.c4 c5 3.d5
         @"rnbqkb1r/pp1ppppp/5n2/2pP4/2P5/8/PP2PPPP/RNBQKBNR b" :
            @[@"e7e6", @"d7d6", @"g7g6"],
         
         // Benoni 3...e6 4.Cc3 exd5 5.cxd5 d6
         @"rnbqkb1r/pp3ppp/3p1n2/2pP4/8/2N5/PP2PPPP/R1BQKBNR w" :
            @[@"e2e4", @"g1f3", @"g2g3"],
         
         
         // ============================================================
         // APRÈS 1.c4 — Partie Anglaise
         @"rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b" :
            @[@"e7e5", @"g8f6", @"c7c5", @"e7e6", @"g7g6"],
         
         // Anglaise 1...e5 2.Cc3
         @"rnbqkbnr/pppp1ppp/8/4p3/2P5/2N5/PP1PPPPP/R1BQKBNR b" :
            @[@"g8f6", @"b8c6", @"f7f5", @"f8b4"],
         
         // Anglaise 1...e5 2.Cc3 Cf6 3.g3
         @"rnbqkb1r/pppp1ppp/5n2/4p3/2P5/2N3P1/PP1PPP1P/R1BQKBNR b" :
            @[@"d7d5", @"b8c6", @"f8b4"],
         
         // Anglaise 1...Cf6 2.Cc3 e6 3.Cf3
         @"rnbqkb1r/pppp1ppp/4pn2/8/2P5/2N2N2/PP1PPPPP/R1BQKB1R b" :
            @[@"d7d5", @"f8b4", @"c7c5"],
         
         // Anglaise symétrique : 1...c5 2.Cf3
         @"rnbqkbnr/pp1ppppp/8/2p5/2P5/5N2/PP1PPPPP/RNBQKB1R b" :
            @[@"b8c6", @"g8f6", @"e7e6"],
         
         
         // ============================================================
         // APRÈS 1.Cf3 — Réti et dérivés
         @"rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b" :
            @[@"d7d5", @"g8f6", @"c7c5", @"e7e6", @"f7f5"],
         
         // Réti 1...d5 2.g3
         @"rnbqkbnr/ppp1pppp/8/3p4/8/5NP1/PPPPPP1P/RNBQKB1R b" :
            @[@"g8f6", @"c7c5", @"e7e6", @"c8f5"],
         
         // Réti 1...d5 2.g3 Cf6 3.Fg2 c6
         @"rnbqkb1r/pp2pppp/2p2n2/3p4/8/5NP1/PPPPPPBP/RNBQK2R w" :
            @[@"e1g1", @"d2d3", @"c2c4"],
         
         // Réti 1...Cf6 2.c4
         @"rnbqkb1r/pppppppp/5n2/8/2P5/5N2/PP1PPPPP/RNBQKB1R b" :
            @[@"e7e6", @"g7g6", @"c7c5", @"d7d5"],
         
         
         // ============================================================
         // DÉVELOPPEMENT GÉNÉRAL (positions communes coups 5-8)
         
         // Roque Blancs après développement
         @"r1bq1rk1/pppp1ppp/2n2n2/2b1p3/2B1P3/2P2N2/PP1P1PPP/RNBQ1RK1 w" :
            @[@"d2d3", @"d2d4", @"b1a3"],
         
         // Position centrale ouverte type
         @"r1bq1rk1/ppp2ppp/2np1n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQ1RK1 w" :
            @[@"c1e3", @"d3d4", @"h2h3"],
         
         // Après roque des deux camps, milieu de partie
         @"r1bq1rk1/ppp1bppp/2np1n2/4p3/2BPP3/2N2N2/PPP2PPP/R1BQR1K1 w" :
            @[@"c4b3", @"d4d5", @"c3d5"],
         
         // Système Londres classique : 1.d4 d5 2.Cf3 Cf6 3.Ff4
         @"rnbqkb1r/ppp1pppp/5n2/3p4/3P1B2/5N2/PPP1PPPP/RN1QKB1R b" :
            @[@"e7e6", @"c7c5", @"c8f5", @"b8c6"],
         
         // Londres 3...e6 4.e3
         @"rnbqkb1r/ppp2ppp/4pn2/3p4/3P1B2/4PN2/PPP2PPP/RN1QKB1R b" :
            @[@"f8e7", @"f8d6", @"c7c5", @"b8d7"],
         
         // Londres 4...Fd6 5.Fg3
         @"rnbqk2r/ppp2ppp/3bpn2/3p4/3P4/4PNBP/PPP2PP1/RN1QKB1R b" :
            @[@"e8g8", @"b8d7", @"c7c5"],
         
      };
      
   } // !buildOpeningBook


   // ================================================================================================
   // Méthode lookupOpeningBook
   -(Move *)lookupOpeningBook:(ChessBoard *)board
                         side:(Side)side
   {
      if (!self.openingBook) return nil;
      
      // Générer le FEN partiel (pièces + trait seulement)
      NSString *fen = [self partialFEN:board side:side];
      
      NSArray<NSString *> *candidates = self.openingBook[fen];
      
      if (!candidates || candidates.count == 0) return nil;
      
      // Mélanger les candidats pour varier le jeu
      NSMutableArray *shuffled = [NSMutableArray arrayWithArray:candidates];
      
      for (NSInteger i = shuffled.count - 1; i > 0; i--) {
         NSInteger j = arc4random_uniform((uint32_t)(i + 1));
         [shuffled exchangeObjectAtIndex:i withObjectAtIndex:j];
         
      }
      
      NSMutableArray<Move *> *legalMoves = [NSMutableArray array];
      [self GenMovesForSide:side board:board into:legalMoves];
      
      for (NSString *bookMove in shuffled) {
         
         // Convertir "e2e4" → Move
         int fx = [bookMove characterAtIndex:0] - 'a';
         int fy = [bookMove characterAtIndex:1] - '1';
         int tx = [bookMove characterAtIndex:2] - 'a';
         int ty = [bookMove characterAtIndex:3] - '1';
         
         for (Move *m in legalMoves) {
            if (m.start.x == fx && m.start.y == fy &&
                m.dest.x  == tx && m.dest.y  == ty) {
               // Vérifier légalité
               MoveState st = [board makeMove:m];
               BOOL legal = ![self IsKingInCheck:side board:board];
               [board unmakeMove:m state:st];
               if (legal) {
                  NSLog(@"---------------------------------------------------------");
                  NSLog(@"📖 Opening book : %@", bookMove);
                  return m;
               }
            }
         }
         
      } // fin boucle candidats
      return nil;
   }


   // ================================================================================================
   // Méthode partialFEN
   -(NSString *)partialFEN:(ChessBoard *)board side:(Side)side
   {
      NSMutableString *fen = [NSMutableString string];
      
      // Pièces (y=7 → y=0, rangée 8 → rangée 1)
      for (int y = 7; y >= 0; y--) {
         int empty = 0;
         for (int x = 0; x < 8; x++) {
            Piece *p = board->pieceCase[x][y];
            if (!p) {
               empty++;
            } else {
               if (empty > 0) {
                  [fen appendFormat:@"%d", empty];
                  empty = 0;
               }
               NSString *symbol = [self fenSymbolForPiece:p];
               [fen appendString:symbol];
            }
         }
         if (empty > 0) [fen appendFormat:@"%d", empty];
         if (y > 0) [fen appendString:@"/"];
      }
      
      // Trait
      [fen appendString:(side == sideWhite) ? @" w" : @" b"];
      
      return fen;
   }


   // ================================================================================================
   // Méthode fenSymbolForPiece
   -(NSString *)fenSymbolForPiece:(Piece *)p
   {
      NSString *symbols[] = {@"P", @"N", @"B", @"R", @"Q", @"K"};
      PieceType types[]   = {Pion, Cava, Fou, Tour, Dame, Roi};
      
      for (int i = 0; i < 6; i++) {
         if (p.type == types[i]) {
            return (p.side == sideWhite) ? symbols[i] :
            [symbols[i] lowercaseString];
         }
      }
      return @"?";
   }


@end
