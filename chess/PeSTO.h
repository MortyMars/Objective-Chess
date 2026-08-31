// PeSTO.h — Tables positionnelles PeSTO + interpolation de phase
// Source : https://www.chessprogramming.org/PeSTO%27s_Evaluation_Function
// Reworking by MortyMars early 2026


// Convention : index 0 = a1 (bas gauche Blancs), index 63 = h8
// Orientation : rangée 1 Blancs en bas → rangée 8 Noirs en haut

#pragma once
#import <Foundation/Foundation.h>

// ── Valeurs de base des pièces (mg / eg) ─────────────────────────────────
extern const int PeSTO_PieceValueMG[7]; // indexé par PieceType
extern const int PeSTO_PieceValueEG[7];

// ── Tables positionnelles [pièce][case 0..63] ────────────────────────────
// Toutes exprimées du point de vue des Blancs.
// Pour les Noirs : miroir vertical = case (7 - rang)*8 + col
extern const int PeSTO_MG[7][64];  // middlegame
extern const int PeSTO_EG[7][64];  // endgame

// ── Calcul de phase ───────────────────────────────────────────────────────
// Retourne un entier dans [0, 256] :
//   256 = ouverture pure (tout le matériel présent)
//     0 = fin de partie pure (plus de matériel mineur/majeur)
int PeSTO_GamePhase(int knights, int bishops, int rooks, int queens);

// ── Interpolation ─────────────────────────────────────────────────────────
// Interpolation linéaire entre mg et eg selon la phase.
// phase=256 → score mg pur ; phase=0 → score eg pur
static inline int PeSTO_Interpolate(int mg, int eg, int phase) {
    return (mg * phase + eg * (256 - phase)) / 256;
}

// ── Lookup PST pour une pièce ─────────────────────────────────────────────
// sq    : case 0..63 (y*8 + x, rangée 0 = Blancs)
// side  : 0=Blancs, 1=Noirs (miroir automatique pour Noirs)
// type  : PieceType (Pion=1..Roi=6)
static inline int PeSTO_LookupMG(int type, int sq, int side) {
    int idx = (side == 0) ? sq : ((7 - sq/8)*8 + sq%8);
    return PeSTO_MG[type][idx];
}
static inline int PeSTO_LookupEG(int type, int sq, int side) {
    int idx = (side == 0) ? sq : ((7 - sq/8)*8 + sq%8);
    return PeSTO_EG[type][idx];
}
