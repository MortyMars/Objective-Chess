// ChessConfig.h
// chess
// Created by MCN on 16/02/2026 for optimized New Engine
// Copyright (c) 2026 MCN. All rights reserved


#ifndef ChessConfig_h
#define ChessConfig_h

   // ==== FLAGS DE DEBUG ====
   /*========= LIGNE À COMMENTER /DÉCOMMENTER EN FONCTION DES BESOINS DE DEBUG ==========*/
   /*                                                                                    */
   //#define DEBUG_ZOBRIST 1   // DEBUG_ZOBRIST mis en place dans Negamax et Quiescence     /
   /*                                                                                    */
   /*============== FIN D'ACTIVATION /DÉSACTIVATION DE DEBUG_ZOBRIST ====================*/

   // #define DEBUG_MOVE_GEN 1
   // #define DEBUG_EVALUATION 1
   // #define DEBUG_TT 1  // Pour plus tard !

   // ==== CONSTANTES DU MOTEUR ====
   #define DELTA_MARGIN 100   // Sécurité = 1 pion

   // ==== LOGGING ====
   #define LOG_EP(fmt, ...) NSLog(@"🟡 EP  " fmt, ##__VA_ARGS__)
   #define LOG_CASTLE(fmt, ...) NSLog(@"🏰 " fmt, ##__VA_ARGS__)
   #define LOG_PROMO(fmt, ...) NSLog(@"👑 " fmt, ##__VA_ARGS__)
   #define LOG_UNMAKE(fmt, ...) NSLog(@"↩️ UNMAKE " fmt, ##__VA_ARGS__)



#endif


// ========================================================================
// TABLES DE TRANSPOSITION
// ========================================================================

//#define TT_SIZE (1 << 20)       // 1M entrées
//#define TT_ENABLED 1            // Activer/désactiver TT
