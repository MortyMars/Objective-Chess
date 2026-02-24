// Minimax.m
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved.
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026


#import "Minimax.h"
#import "Minimax+GenMoves.h"
#import "ChessBoard+MakeMoves.h"
#import "ChessConfig.h"
#import "Util.h"


#define SCORE_INF 10000000




static int nodes = 0;
static int nbCallsIsKingCheck = 0;


@interface Minimax () {
    // ... tes iVars existantes ...
    
    // ✨ NOUVEAU : Historique de positions
    uint64_t positionHistory[MAX_GAME_LENGTH];
    int      historyCount;
}
@end


@implementation Minimax

   // Méthode d'initialisation d'une instance
   - (instancetype)init
   {
      self = [super init];
      if (self) {
         evalCache = [[NSMutableDictionary alloc] initWithCapacity:200000];
         cacheHits = 0;
         cacheMisses = 0;
         self.transpositionTable = [[TranspositionTable alloc] initWithSizeMB:128];
      }
      return self;
   }


   // ================================================================================================
   // MÉTHODE 1 : BestMoveForSide - Point d'entrée du moteur IA
   // Cette méthode trouve le meilleur coup pour l'IA en explorant l'arbre des possibilités
   -(Move *)BestMoveForSide:(Side)side
                      Board:(ChessBoard *)board
   {
      maMinimax.depthCounter = 0;   // 🔴 OBLIGATOIRE
      
      // Init des iVars
      nbLoop = 0;
      nbElag = 0;
      nodeCount = 0;
      evalCount = 0;
      moveGenCount = 0;
      copyBoardCount = 0;
      evalTotalTime = 0;
      moveGenTotalTime = 0;
      memset(historyTable, 0, sizeof(historyTable));
      
      
      // Réinitialisation Heuristic History
      memset(historyTable, 0, sizeof(historyTable));
      
      /* ========== DÉMARRAGE DU TIMER ========== */
      NSDate *startTime = [NSDate date];
      nodeCount = 0;
      nbElag = 0;  // ✅ FIX : Réinitialiser nbElag pour avoir des stats correctes
      
      /* ✅ RÉINITIALISER LES COMPTEURS DU PROFILLING */
      evalCount = 0;
      moveGenCount = 0;
      copyBoardCount = 0;
      evalTotalTime = 0;
      moveGenTotalTime = 0;
      
      /* // Réinit valeurs cache
      evalCache = [[NSMutableDictionary alloc] initWithCapacity:100000];
      cacheHits = 0;
      cacheMisses = 0; */
      
      // ✅ NOUVEAU : Réinitialiser l'historique de positions
      historyCount = 0;
      memset(positionHistory, 0, sizeof(positionHistory));
      
      /* Stats efficacité TT */
      // ✅ APRÈS — reset propre AVANT la recherche
      nodes = 0;  // Reset au lieu de sauvegarder
      [self.transpositionTable newGeneration];
      /* Fin Stats*/
      
      /* Détermination du jeu de tous les moves possibles pour 'side' */
      NSSet *movesPossibles = [self PossibleMovesForSide:side board:board];
      
      /* PRÉREQUIS : Tester si side est mat ou pat */
      if (movesPossibles.count == 0) {
         [monConnecteur AlertMsgPatMatSide:side onBoard:board];
         return nil;
      }
      
      /* Initialisation des variables de recherche */
      int bestScore  = -SCORE_INF;
      Move *bestMove = nil;
      Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      
      // ========== FILTRAGE SÉCURITÉ ========== //
      NSMutableSet *safeMovesOnly = [[NSMutableSet alloc] init];             // ⚠️ Version Filtrage de sécu
      //NSMutableSet *safeMovesOnly = [NSMutableSet setWithSet:movesPossibles];  // ⚠️ Copie directe sans filtrage
       
      int dangerousMovesFiltered = 0;
      
      for (Move *move in movesPossibles) {
         Piece *movingPiece = [board pieceAtPos:move.start];
         Piece *capturedPiece = [board pieceAtPos:move.dest];
         
         if (!movingPiece) continue;
         
         BOOL isDangerous = NO;
         
         // Valeur de la pièce qui bouge
         int movingValue = [self ValueOfPiece:movingPiece.type];
         
         // Valeur capturée
         int capturedValue = 0;
         if (capturedPiece && capturedPiece.type != Invalide) {
            capturedValue = [self ValueOfPiece:capturedPiece.type];
         }
         
         // Vérifier seulement pour les pièces chères
         if (movingValue >= 300) {
            
               #ifdef DEBUG_ZOBRIST
                  uint64_t hashAvantCopy = board->zobristKey;
                  NSLog(@"🔵 AVANT board.copy: hash=%llx", hashAvantCopy);
               #endif
                           
               ChessBoard *testBoard = board.copy;
                           
               #ifdef DEBUG_ZOBRIST
                  uint64_t hashApresCopy = board->zobristKey;
                  NSLog(@"🔵 APRÈS board.copy: hash original=%llx, hash copie=%llx",
                        hashApresCopy, testBoard->zobristKey);
                  if (hashApresCopy != hashAvantCopy) {
                     NSLog(@"💥💥💥 board.copy A CORROMPU LE BOARD ORIGINAL !");
                  }
               #endif
                           
               MoveState st = [testBoard makeMove:move];
                           
               #ifdef DEBUG_ZOBRIST
                  uint64_t hashApresPerform = board->zobristKey;
                  NSLog(@"🔵 APRÈS PerformMove: hash original=%llx", hashApresPerform);
                  if (hashApresPerform != hashAvantCopy) {
                     NSLog(@"💥💥💥 PerformMove A CORROMPU LE BOARD ORIGINAL !");
                  }
               #endif
            
            Side enemySide = (movingPiece.side == sideWhite) ? sideBlack : sideWhite;
            
            // Utiliser le helper
            int cheapestAttacker = [self CheapestAttackValue:move.dest
                                                      bySide:enemySide
                                                     inBoard:testBoard];
            
            if (cheapestAttacker > 0) {  // Case attaquée
               int netGain = capturedValue - movingValue;
            }
         }
         
         if (!isDangerous) [safeMovesOnly addObject:move];
      }
      
      if (safeMovesOnly.count == 0) {
         safeMovesOnly = [NSMutableSet setWithArray:[movesPossibles allObjects]];
      } else if (dangerousMovesFiltered > 0) {
         NSLog(@"🛡️ BMFS - Filtrage : %d coups dangereux bloqués, %lu gardés",
               dangerousMovesFiltered, (unsigned long)safeMovesOnly.count);
      }
      
      // ======= FIN DE FILTRAGE SÉCURITÉ ======= //
      
      
      // TRI DES COUPS
      NSArray *sortedMoves = [self SortMovesByPriority:safeMovesOnly
                                                 board:board
                                                  side:side // c'est side qui joue
                                                 depth:NUMBER_MOVES_AHEAD];
      
      NSLog(@"=== IA (%@) analyse %lu coups ===",
            (side == sideWhite) ? @"Blancs" : @"Noirs",
            (unsigned long)sortedMoves.count);
      
      
      /* ========== ÉVALUATION DE CHAQUE COUP ========== */
      for (Move *moveEnCours in sortedMoves)
      {
         // ✅ NOUVEAU : Ajouter la position avant makeMove
         positionHistory[historyCount++] = board->zobristKey;
         
         // ✅ CORRECT — makeMove/unmakeMove sur le board original
         MoveState st = [board makeMove:moveEnCours];
         
         // Negamax retourne le score du point de vue d'otherSide
         // On le négative UNE SEULE FOIS pour obtenir le score pour side
         int score = -[self NegamaxForSide:otherSide
                                     board:board
                                     depth:NUMBER_MOVES_AHEAD - 1
                                     alpha:-SCORE_INF
                                      beta:SCORE_INF];

         [board unmakeMove:moveEnCours state:st];
         
         // ✅ NOUVEAU : Retirer la position après unmakeMove
         historyCount--;
         
         // score est maintenant positif = bon pour side ✅
         if (score > bestScore || !bestMove) {
             bestScore = score;
             bestMove = moveEnCours;
         }
      }
      
      /* ========== CALCUL DU TEMPS ÉCOULÉ ========== */
      NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
      
      NSLog(@"✅ Coup choisi : %@ (score=%d, %.1fs, %d nœuds, %.0f n/s)\n",
            bestMove, bestScore, elapsed, nodeCount, nodeCount/elapsed);
      
      // Stats efficacité Après la recherche
      NSLog(@"🎯 Nœuds explorés: %llu", nodes);
      [self.transpositionTable printStats];
      // Fin de stats
      
      return bestMove;
      
   } // !BestMoveForSide


   // ================================================================================================
   // MÉTHODE 2 : NegamaxForSide avec Tables de Transposition
   // Moteur récursif du jeu, explorant l'arbre des possibilités de coups réalisables
   -(int)NegamaxForSide:(Side)side
                  board:(ChessBoard *)board
                  depth:(int)depth
                  alpha:(int)alpha
                   beta:(int)beta
   {
      nodes++;
      
      int alphaOrig = alpha;  // ✨ Sauvegarder alpha original pour TT
      
      #ifdef DEBUG_ZOBRIST
         uint64_t keyEntry = board->zobristKey;
      #endif
      
      // ✅ NOUVEAU : Détection de répétition AVANT probe TT
       if ([self isRepetition:board->zobristKey]) {
           return 0;  // Position répétée = nulle (draw)
       }
      
      
      // ========================================================================
      // 🔍 PROBE TT : Consulter la table de transposition
      Move *ttMove = nil;
      TTEntry *ttEntry = [self.transpositionTable probe:board->zobristKey
                                               bestMove:&ttMove];

      if (ttEntry) {
          // ttMove est déjà rempli automatiquement !
          
          // Utiliser le score de la TT si la profondeur est suffisante
          if (ttEntry->depth >= depth) {
            int ttScore = ttEntry->score;
            
            switch (ttEntry->nodeType) {
               case TT_EXACT:
                  // Score exact : retourner directement
                  return ttScore;
                  
               case TT_LOWER_BOUND:
                  // Fail-high (beta cutoff) : score >= ttScore
                  if (ttScore >= beta) return ttScore;
                  if (ttScore > alpha) alpha = ttScore;
                  break;
                  
               case TT_UPPER_BOUND:
                  // Fail-low (alpha cutoff) : score <= ttScore
                  if (ttScore <= alpha) return ttScore;
                  if (ttScore < beta) beta = ttScore;
                  break;
            }
            
            // Fenêtre alpha-beta fermée ?
            if (alpha >= beta) return ttScore;
         }
      }
      
      // ========================================================================
      // Quiescence Search à profondeur 0
      if (depth <= 0) {
         return [self QuiescenceForSide:side
                                  board:board
                                  alpha:alpha
                                   beta:beta
                                qsDepth:0];
      }
      
      // ========================================================================
      // Génération et tri des coups
      NSMutableArray<Move *> *moves = [NSMutableArray arrayWithCapacity:64];
      [self GenMovesForSide:side board:board into:moves];
      
      // Move Ordering avec bonus TT
      NSLog(@"🔵 AVANT ScoreMovesList, enPassantFile=%d", board->enPassantFile);
      [self ScoreMovesList:moves board:board side:side];
      
      // ✨ Bonus énorme pour le coup TT (essayer en premier)
      if (ttMove) {
         for (Move *m in moves) {
            if (m.fromSquare == ttMove.fromSquare &&
                m.toSquare == ttMove.toSquare) {
               m.orderingScore += 1000000;  // Priorité absolue
               break;
            }
         }
      }
      
      [moves sortUsingComparator:^NSComparisonResult(Move *a, Move *b) {
         return (b.orderingScore - a.orderingScore);  // ⚠️ Ordre décroissant !
      }];
      
      // ========================================================================
      // Traiter le cas Mat/Pat
      if (moves.count == 0) {
         
      #ifdef DEBUG_ZOBRIST
            NSAssert(board->zobristKey == keyEntry,
                     @"Zobrist corrompu : sortie Negamax sans coups");
      #endif
         
         int score;
         if ([self IsKingInCheck:side board:board]) {
            // Mat : très mauvais pour le camp qui joue
            score = -100000 + (NUMBER_MOVES_AHEAD - depth);
         } else {
            // Pat : nul
            score = 0;
         }
         
         // ✨ Stocker dans TT (score exact, pas de meilleur coup)
         [self.transpositionTable store:board->zobristKey
                                  score:score
                                  depth:depth
                               nodeType:TT_EXACT
                               bestMove:nil];
         return score;
      }
      
      // ========================================================================
      // Recherche principale
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      Move *bestMove = nil;  // ✨ Tracker le meilleur coup pour TT
      
      for (Move *m in moves) {
         
         #ifdef DEBUG_ZOBRIST
               uint64_t keyBefore = board->zobristKey;
               NSLog(@"➡️ AVANT makeMove %@ : hash=%llx", m, keyBefore);
         #endif
         
         // ✅ NOUVEAU : Ajouter la position à l'historique AVANT makeMove
         positionHistory[historyCount++] = board->zobristKey;
         
         MoveState st = [board makeMove:m];
         
         #ifdef DEBUG_ZOBRIST
               uint64_t keyAfter = board->zobristKey;
               uint64_t z2 = recomputeZobrist(board);
               NSLog(@"   APRES makeMove %@ : hash=%llx (recalc=%llx) diff=%llx",
                     m, keyAfter, z2, keyAfter ^ z2);
               
               if (z2 != board->zobristKey) {
                  NSLog(@"❌ Mismatch détecté !");
                  NSAssert(NO, @"Zobrist corrompu");
               }
         #endif
         
         // Filtre de légalité
         if (![self IsKingInCheck:side board:board]) {
            
            int score = -[self NegamaxForSide:otherSide
                                        board:board
                                        depth:depth-1
                                        alpha:-beta
                                         beta:-alpha];
            
            if (score > alpha) {
               alpha = score;
               bestMove = m;  // ✨ Nouveau meilleur coup
            }
         }
         
         [board unmakeMove:m state:st];
         
         // ✅ NOUVEAU : Retirer la position de l'historique APRÈS unmakeMove
         historyCount--;
         
         #ifdef DEBUG_ZOBRIST
               uint64_t keyAfterUnmake = board->zobristKey;
               uint64_t z3 = recomputeZobrist(board);
               NSLog(@"⬅️ APRES unmakeMove %@ : hash=%llx (recalc=%llx) diff=%llx",
                     m, keyAfterUnmake, z3, keyAfterUnmake ^ z3);
               
               if (keyAfterUnmake != keyBefore) {
                  NSLog(@"💥 UNMAKE n'a pas restauré le hash !");
                  NSAssert(NO, @"unmakeMove ne restaure pas le hash");
               }
         #endif
            
         // Beta cutoff
         if (alpha >= beta) {
            break;
         }
      }
      
      #ifdef DEBUG_ZOBRIST
         NSAssert(board->zobristKey == keyEntry,
                  @"Zobrist corrompu : sortie Negamax normale");
      #endif
      
      // ========================================================================
      // 💾 STORE TT : Stocker le résultat dans la table
      TTNodeType nodeType;
      if (alpha <= alphaOrig) {
         // Fail-low : tous les coups <= alpha original
         nodeType = TT_UPPER_BOUND;
      }
      else if (alpha >= beta) {
         // Fail-high : cutoff (au moins un coup >= beta)
         nodeType = TT_LOWER_BOUND;
      }
      else {
         // PV node : score exact dans [alpha, beta]
         nodeType = TT_EXACT;
      }
      
      [self.transpositionTable store:board->zobristKey
                               score:alpha
                               depth:depth
                            nodeType:nodeType
                            bestMove:bestMove];
      
      return alpha;
      
   } // !NegamaxForSide

   // ================================================================================================
   // Méthode de Quiescence
   // La quiescence est utilisée pour étendre la recherche sur les nœuds instables dans les arbres Minimax.
   // Elle permet de reporter l'évaluation jusqu'à ce que la position soit suffisamment stable pour être
   // évaluée statiquement, c'est-à-dire sans tenir compte de l'historique de la position ou des futurs moves.
   - (int)QuiescenceForSide:(Side)side
                      board:(ChessBoard *)board
                      alpha:(int)alpha
                       beta:(int)beta
                    qsDepth:(int)qsDepth
   {
      nodes++;
      
               #ifdef DEBUG_ZOBRIST
               uint64_t keyEntry = board->zobristKey;
               #endif

      
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      
      BOOL inCheck = [self IsKingInCheck:side board:board];
      
      int standPat = -INF;
      
      // 1️⃣ Stand-pat uniquement hors échec
      if (!inCheck) {
         standPat = [self EvalBoardForSide:side board:board];
         
         if (standPat >= beta) {
            
               #ifdef DEBUG_ZOBRIST
               NSAssert(board->zobristKey == keyEntry,
                        @"Zobrist corrompu : QS stand-pat cutoff");
               #endif
            
            return beta;}
         
         if (standPat > alpha) alpha = standPat;
      }
      
      // 2️⃣ Limite QS (mais jamais en échec)
      if (qsDepth >= QS_MAX_DEPTH && !inCheck) {
         
               #ifdef DEBUG_ZOBRIST
               NSAssert(board->zobristKey == keyEntry,
                        @"Zobrist corrompu : QS stand-pat cutoff");
               #endif
         
         return alpha;}
      
      // 3️⃣ Génération des coups
      NSMutableArray<Move *> *moves = [NSMutableArray arrayWithCapacity:32];
      
      if (inCheck) {
         [self GenMovesForSide:side board:board into:moves];
      } else {
         [self GenCapturForSide:side board:board into:moves];
      }
      
      // 4️⃣ Boucle QS
      for (Move *m in moves) {
         
         // 🔹 DELTA PRUNING
         if (!inCheck) {
            int gain = [self ValueOfPiece:m.capturedPiece.type];
            if (standPat + gain + DELTA_MARGIN < alpha)
               continue;
         }
         
         // 🔹 SEE FILTER
         if (!inCheck) {
            int see = [self SEEForMove:m board:board];
            if (see < 0)
               continue;
         }
         
         // 🔴 INTERDICTION DES SUICIDES DE DAME
         if (!inCheck && m.movingPiece.type == Dame && ![self IsSquareDefended:m.toSquare
                                                                        bySide:side
                                                                         board:board]) {
            continue;
         }
         
         // On peut y aller
         
               #ifdef DEBUG_ZOBRIST
               // GÉNÉRATION CLÉ ZOBRIST AVANT MAKEMOVE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
               uint64_t keyBefore = board->zobristKey;
               #endif
         
         MoveState st = [board makeMove:m];
         
               #ifdef DEBUG_ZOBRIST
               uint64_t z2 = recomputeZobrist(board);
               if (z2 != board->zobristKey) {
                   NSLog(@"❌ Quiescence: Zobrist mismatch après makeMove %@", m);
                   NSLog(@"   Hash actuel=%llx, recalculé=%llx", board->zobristKey, z2);
                   NSLog(@"   Move: castling=%d EP=%d capture=%d promo=%d",
                         m.isCastling, m.isEnPassant, m.isCapture, m.isPromotion);
                   NSLog(@"   fromSq=%d toSq=%d", m.fromSquare, m.toSquare);
                  NSAssert(board->zobristKey == z2,  // ✅ Assertion correcte
                           @"Zobrist corrompu après makeMove");
               }
               #endif
         
               /* Assertion incorrecte
               #ifdef DEBUG_ZOBRIST
                  NSAssert(board->zobristKey == keyEntry,
                           @"Zobrist corrompu : QS stand-pat cutoff");
               #endif
               */
         
         if (![self IsKingInCheck:side board:board]) {
            
            int score = -[self QuiescenceForSide:otherSide
                                           board:board
                                           alpha:-beta
                                            beta:-alpha
                                         qsDepth:qsDepth + 1];
            
            [board unmakeMove:m state:st];
            
               #ifdef DEBUG_ZOBRIST
               // COMPARAISON CLÉ ZOBRIST APRÈS UNMAKEMOVE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
               NSAssert(board->zobristKey == keyBefore, @"❌ Quiescence Zobrist make/unmake incohérent");
               #endif
               
               #ifdef DEBUG_ZOBRIST
               NSAssert(board->zobristKey == keyEntry,
                        @"Zobrist corrompu : QS stand-pat cutoff");
               #endif
            
            if (score >= beta) {
               
                  #ifdef DEBUG_ZOBRIST
                  NSAssert(board->zobristKey == keyEntry,
                           @"Zobrist corrompu : QS stand-pat cutoff");
                  #endif
               
               return beta;
            }
            
            if (score > alpha) alpha = score;
            
         } // !if !IsKingInCheck
         
         else [board unmakeMove:m state:st]; // si IsKingInCheck on annule le coup
         
      } // !for move
      
               #ifdef DEBUG_ZOBRIST
               NSAssert(board->zobristKey == keyEntry,
                        @"Zobrist corrompu : QS return final");
               #endif
      
      return alpha;
      
   } // !QuiescenceForSide


   // ================================================================================================
   // MÉTHODE 3 : SortMovesByPriority
   // TRI DES COUPS PAR PRIORITÉ pour améliorer l'efficacité de l'élagage alpha-beta
   // Principe : Les meilleurs coups sont examinés en premier, ce qui provoque plus de cutoffs
   // et réduit donc le nombre de branches à explorer
   -(NSArray *)SortMovesByPriority:(NSSet *)moves
                             board:(ChessBoard *)board
                              side:(Side)side
                             depth:(int)depth
   {
      // Conversion du NSSet en NSArray pour pouvoir le trier
      NSArray *movesArray = [moves allObjects];
      
      return [movesArray sortedArrayUsingComparator:^NSComparisonResult(Move *m1, Move *m2) {
         int score1 = [self ScoreMove:m1 board:board side:side depth:depth];
         int score2 = [self ScoreMove:m2 board:board side:side depth:depth];
         
         if (score2 > score1) return NSOrderedAscending;
         if (score2 < score1) return NSOrderedDescending;
         return NSOrderedSame;
      }];
   }


   // ================================================================================================
   // MÉTHODE 4 : ScoreMove - ÉVALUATION D'UN COUP (Ne pas confondre avec 'ScoreMovesList'
   // Attribution d'un score heuristique rapide basé sur :
   // - La valeur de la pièce capturée (si capture)
   // - D'autres critères possibles (coups centraux, développement, etc.)
   -(int)ScoreMove:(Move *)move
             board:(ChessBoard *)board
              side:(Side)side
             depth:(int)depth
   {
      int score = 0;
      
      Piece *captured = [board pieceAtPos:move.dest];
      
      // 1. CAPTURES (priorité absolue)
      if (captured && captured.type != Invalide) {
         Piece *movingPiece = [board pieceAtPos:move.start];
         
         int victimValue = 0;
         int attackerValue = 0;
         
         switch (captured.type) {
            case Pion: victimValue = 100; break;
            case Cava:
            case Fou:  victimValue = 300; break;
            case Tour: victimValue = 500; break;
            case Dame: victimValue = 900; break;
            case Roi:  victimValue = 100000; break;
            default: break;
         }
         
         switch (movingPiece.type) {
            case Pion: attackerValue = 100; break;
            case Cava:
            case Fou:  attackerValue = 300; break;
            case Tour: attackerValue = 500; break;
            case Dame: attackerValue = 900; break;
            case Roi:  attackerValue = 100000; break;
            default: break;
         }
         
         // MVV-LVA
         score = 10000 + (victimValue * 10) - attackerValue;
      }
      
      // 2. HISTORY HEURISTIC (non-captures)
      else {
         int sideIdx = (side == sideWhite) ? 0 : 1;
         
         // ✅ ACCÈS ULTRA-RAPIDE (pas de isEqual!)
         int historyScore = historyTable[sideIdx]
         [move.start.x]
         [move.start.y]
         [move.dest.x]
         [move.dest.y];
         
         if (historyScore > 0) {
            // ✅ FIX : Augmenter le score pour que l'history ait un vrai impact
            // Avant: 8000-8999 (toujours < captures 10000+)
            // Après: 5000-9999 (meilleur que coups centraux, < captures)
            score = 5000 + MIN(historyScore, 4999);
         }
         else {
            // Coups centraux (fallback)
            int distFromCenter = abs(3 - move.dest.x) + abs(3 - move.dest.y);
            score = (8 - distFromCenter) * 2;
         }
      }
      return score;
   } // !ScoreMove


   // ================================================================================================
   // MÉTHODE 4bis : ScoreMovesList - ÉVALUATION D'UNE LISTE DE COUPS (Ne pas confondre avec ScoreMove)
   - (void)ScoreMovesList:(NSArray<Move *> *)moves
                    board:(ChessBoard *)board
                     side:(Side)side
   {
      for (Move *m in moves) {
         
         int score = 0;
         
         if (m.isCapture) {
            
            int see = [self SEEForMove:m board:board];
            
            if (see >= 0)
               score = 10000 + see;   // captures gagnantes
            else
               score = 5000 + see;    // captures perdantes
            
         } else {
            
            // 🎯 Coups calmes intéressants
            if (m.movingPiece.type == Cava || m.movingPiece.type == Fou)
               score += 100;  // développement
            
            if (m.givesCheck)
               score += 200;
            
            if (m.isCastling)
               score += 300;
            
            if (m.isPromotion)
               score += 900;
            
         }
         
         m.orderingScore = score;
      }
   } // !ScoreMovesList




   // ================================================================================================
   // MÉTHODE 5 : FilterCaptures - FILTRAGE DES CAPTURES POUR QUIESCENCE SEARCH
   // NOUVELLE MÉTHODE pour optimiser le QS
   // Ne conserve que les coups qui sont des captures, car ce sont les coups "tactiques"
   // qui peuvent changer drastiquement l'évaluation d'une position
   -(NSSet *)FilterCaptures:(NSSet *)moves from:(Side)side board:(ChessBoard *)board
   {
      NSMutableSet *captures = [[NSMutableSet alloc] init];
      
      for (Move *move in moves) {
         Piece *captured = [board pieceAtPos:move.dest];
         
         /* Vérifier qu'il y a bien une pièce adverse à  la destination */
         if (captured && captured.type != Invalide && captured.side != side) {
            [captures addObject:move];
         }
      }
      
      return captures;
   }


   // ================================================================================================
   // MÉTHODE : EvalBoardForSide - VERSION AMÉLIORÉE AVEC ÉVALUATION POSITIONNELLE
   // Cette méthode évalue la qualité d'une position d'échecs pour un camp donné
   // PHILOSOPHIE D'ÉVALUATION :
   // - Matériel : Valeur brute des pièces (base)
   // - Position : Où sont placées les pièces (crucial)
   // - Sécurité : Le roi est-il en sécurité ?
   // - Structure : Les pions sont-ils bien organisés ?
   // - Mobilité : Combien de coups possibles ?
   // - Développement : Les pièces sont-elles actives ?
   // CONVENTION NEGAMAX STANDARD :
   // - L'évaluation est TOUJOURS du Point Of View des BLANCS (White POV)
   // - Valeur positive = avantage Blancs, négative = avantage Noirs
   // - Negamax inversera le signe selon le camp qui joue
   -(int)EvalBoardForSide:(Side)side
                    board:(ChessBoard *)board
   {
      /* A DÉSACTIVER CAR DOUBLE EMPLOI AVEC TT
      // Générer une clé unique pour cette position
      NSString *key = [self BoardHashKey:board forSide:side];
      NSNumber *cached = evalCache[key];
      if (cached) {
         cacheHits++;
         return [cached intValue];
      }
      cacheMisses++;
      FIN DE DÉSACTIVATION */
      
      evalWhitePOV = 0;  /* Évaluation du point de vue des Blancs (convention Negamax) */
      
      /* Variables pour statistiques intermédiaires */
      int materialWhite = 0, materialBlack = 0;
      // int mobilityWhite = 0, mobilityBlack = 0;
      int developmentWhite = 0, developmentBlack = 0;
      int totalMaterial = 0;  /* Pour détecter la fin de partie */
      
      // ===========================================
      // PARTIE 1 : ÉVAL. MATÉRIELLE + POSITIONNELLE
      /* Tables de valeurs positionnelles pour chaque type de pièce
       Ces tables donnent un bonus/malus selon la position de la pièce sur l'échiquier
       Convention : les tableaux sont vus du point de vue des Blancs (rangée 0 = fond Blancs) */
      
      /* TABLE PIONS : Encourage l'avancée et le contrôle du centre */
      static const int pawnTable[8][8] = {
         {  0,  0,  0,  0,  0,  0,  0,  0 }, // (x0,y0) à (x0,y7) Rangée de promotion
         {  1,  1,  2,  2,  2,  2,  1,  1 }, // Avant-dernière rangée (au sens échiquéen)
         {  1,  1,  2,  3,  3,  2,  1,  1 },
         {  1,  1,  2,  4,  4,  2,  1,  1 },
         {  0,  0,  1,  3,  3,  1,  0,  0 }, // Rangée 'centrale'
         {  0,  0,  0,  0,  0,  0,  0,  0 },
         {  1,  1, -1, -3, -3, -1,  1,  1 },
         {  0,  0,  0,  0,  0,  0,  0,  0 }  // (x7,y0) à (x7,y7) Rangée de départ
      };
      
      /* TABLE CAVALIERS : Encourage position centrale et pénalise les bords */
      static const int knightTable[8][8] = {
         { -8, -6, -4, -4, -4, -4, -6, -8 },
         { -6, -2,  0,  1,  1,  0, -2, -6 },
         { -4,  0,  2,  3,  3,  2,  0, -4 },
         { -4,  1,  3,  4,  4,  3,  1, -4 },
         { -4,  1,  3,  4,  4,  3,  1, -4 },
         { -4,  0,  2,  3,  3,  2,  0, -4 },
         { -6, -2,  0,  1,  1,  0, -2, -6 },
         { -8, -6, -4, -4, -4, -4, -6, -8 }
      };
      
      /* TABLE FOUS : Encourage diagonales longues et centre */
      static const int bishopTable[8][8] = {
         { -4, -2, -2, -2, -2, -2, -2, -4 },
         { -2,  0,  0,  1,  1,  0,  0, -2 },
         { -2,  0,  2,  2,  2,  2,  0, -2 },
         { -2,  1,  2,  3,  3,  2,  1, -2 },
         { -2,  1,  2,  3,  3,  2,  1, -2 },
         { -2,  0,  2,  2,  2,  2,  0, -2 },
         { -2,  0,  0,  1,  1,  0,  0, -2 },
         { -4, -2, -2, -2, -2, -2, -2, -4 }
      };
      
      /* TABLE TOURS : Encourage 7ème rangée et colonnes ouvertes (approximatif) */
      static const int rookTable[8][8] = {
         {  0,  0,  0,  0,  0,  0,  0,  0 },
         {  2,  2,  2,  2,  2,  2,  2,  2 }, // '7e rangée' au sens échiquéen
         {  0,  0,  0,  0,  0,  0,  0,  0 },
         {  0,  0,  0,  0,  0,  0,  0,  0 },
         {  0,  0,  0,  0,  0,  0,  0,  0 },
         {  0,  0,  0,  0,  0,  0,  0,  0 },
         {  0,  0,  0,  0,  0,  0,  0,  0 },
         {  0,  0,  0,  0,  0,  0,  0,  0 }
      };
      
      /* TABLE DAME : Légère préférence pour le centre, éviter l'exposition précoce */
      static const int queenTable[8][8] = {
         { -4, -2, -2, -1, -1, -2, -2, -4 },
         { -2,  0,  0,  0,  0,  0,  0, -2 },
         { -2,  0,  1,  1,  1,  1,  0, -2 },
         { -1,  0,  1,  2,  2,  1,  0, -1 },
         { -1,  0,  1,  2,  2,  1,  0, -1 },
         { -2,  0,  1,  1,  1,  1,  0, -2 },
         { -2,  0,  0,  0,  0,  0,  0, -2 },
         { -4, -2, -2, -1, -1, -2, -2, -4 }
      };
      
      /* TABLE ROI (milieu de partie) : Encourage roque et sécurité sur les côtés */
      static const int kingMiddleGameTable[8][8] = {
         { -8,-10,-10,-12,-12,-10,-10, -8 },
         { -8,-10,-10,-12,-12,-10,-10, -8 },
         { -6, -8, -8,-10,-10, -8, -8, -6 },
         { -6, -8, -8,-10,-10, -8, -8, -6 },
         { -4, -6, -6, -8, -8, -6, -6, -4 },
         { -2, -4, -4, -4, -4, -4, -4, -2 },
         {  4,  4,  2,  0,  0,  2,  4,  4 },
         {  6,  8,  4,  2,  2,  4,  8,  6 }
      };
      
      /* TABLE ROI (fin de partie) : Le roi devient actif au centre */
      static const int kingEndGameTable[8][8] = {
         { -8, -6, -4, -2, -2, -4, -6, -8 },
         { -6, -4, -2,  0,  0, -2, -4, -6 },
         { -4, -2,  2,  4,  4,  2, -2, -4 },
         { -4, -2,  4,  6,  6,  4, -2, -4 },
         { -4, -2,  4,  6,  6,  4, -2, -4 },
         { -4, -2,  2,  4,  4,  2, -2, -4 },
         { -6, -4, -2,  0,  0, -2, -4, -6 },
         { -8, -6, -4, -2, -2, -4, -6, -8 }
      };
      
      /* ========== PARCOURS DE L'ÉCHIQUIER ========== */
      /* Comptage du matériel total pour déterminer si on est en fin de partie */
      // ✅ FIX : pré-calculer totalMaterial AVANT la boucle principale

      // Passe 1 : calcul du matériel total (sans le Roi)
      totalMaterial = 0;
      for (int x = 0; x < 8; x++) {
          for (int y = 0; y < 8; y++) {
              Piece *p = [board piece_colX:x rangY:y];
              if (!p || p.type == Roi || p.type == Invalide) continue;
              switch (p.type) {
                  case Pion:  totalMaterial += 100; break;
                  case Cava:  totalMaterial += 300; break;
                  case Fou:   totalMaterial += 300; break;
                  case Tour:  totalMaterial += 500; break;
                  case Dame:  totalMaterial += 900; break;
                  default: break;
              }
          }
      }
      BOOL isEndGame = (totalMaterial < 2600);
      
      // Passe 2 : évaluation complète
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Piece *piece = [board piece_colX:x rangY:y];
            if (!piece) continue;
            int materialValue = 0;  // Valeur matérielle
            int positionBonus = 0;  // Bonus positionnel
            
            /* Détermination de la valeur de base et du bonus positionnel */
            switch (piece.type) {
               case Invalide:
                  break;
                  
               case Pion:
                  materialValue = 100;
                  /* Pour les Noirs, on inverse la table (miroir vertical) */
                  if (piece.side == sideWhite) positionBonus = pawnTable[y][x];
                  else positionBonus = pawnTable[7-y][x];
                  break;
                  
               case Cava:
                  materialValue = 300;
                  positionBonus = knightTable[y][x];
                  
                  /* BONUS DÉVELOPPEMENT : Cavalier sorti de sa case de départ */
                  if (piece.side == sideWhite && y > 0) developmentWhite += 5;
                  if (piece.side == sideBlack && y < 7) developmentBlack += 5;
                  break;
                  
               case Fou:
                  materialValue = 300;
                  positionBonus = bishopTable[y][x];
                  /* BONUS DÉVELOPPEMENT : Fou sorti de sa case de départ */
                  if (piece.side == sideWhite && y > 0) developmentWhite += 5;
                  if (piece.side == sideBlack && y < 7) developmentBlack += 5;
                  break;
                  
               case Tour:
                  materialValue = 500;
                  if (piece.side == sideWhite) positionBonus = rookTable[y][x];
                  else positionBonus = rookTable[7-y][x];
                  break;
                  
               case Dame:
                  materialValue = 900;
                  positionBonus = queenTable[y][x];
                  /* MALUS SI DAME SORTIE TROP TÔT (avant coups 10-15) */
                  if (board->nbEntiers < 10) {
                     if (piece.side == sideWhite && y > 1) positionBonus -= 10;
                     if (piece.side == sideBlack && y < 6) positionBonus -= 10;
                  }
                  break;
                  
               case Roi:
                  materialValue = 100000;
                  /* Choix de la table selon la phase de jeu */
                  /* Fin de partie si matériel total < 3000 (approximatif) */
                  if (isEndGame) {
                     if (piece.side == sideWhite) positionBonus = kingEndGameTable[y][x];
                     else positionBonus = kingEndGameTable[7-y][x];
                  } else {
                     if (piece.side == sideWhite) positionBonus = kingMiddleGameTable[y][x];
                     else positionBonus = kingMiddleGameTable[7-y][x];
                  }
                  break;
            } // Fin de switch
            
            /* Accumulation du matériel total (pour détecter fin de partie) */
            if (piece.type != Roi) totalMaterial += materialValue;
            
            /* Ajout de la valeur + bonus positionnel selon la couleur */
            int pieceValue = materialValue + positionBonus;
            
            if (piece.side == sideWhite) {
               materialWhite += pieceValue;
               evalWhitePOV  += pieceValue;   // Blancs = positif
            } else {
               materialBlack += pieceValue;
               evalWhitePOV  -= pieceValue;   // Noirs = négatif
            }
         } // fin de for 'y'
      } // fin de for 'x' et fin de parcours de l'échiquier
      
      // PARTIE 2 désactivée
      
      // ===========================================
      // PARTIE 3 : ÉVAL. DE LA STRUCTURE DE PIONS
      /* Détection des pions doublés (malus) et pions passés (bonus) */
      for (int x = 0; x < 8; x++) {
         int whitePawnsInColumn = 0;
         int blackPawnsInColumn = 0;
         int whiteMostAdvanced = -1;  // Y le plus élevé pour pion blanc
         int blackMostAdvanced = 8;   // Y le plus bas pour pion noir
         
         /* Comptage des pions par colonne */
         for (int y = 0; y < 8; y++) {
            Piece *piece = [board piece_colX:x rangY:y];
            if (piece && piece.type == Pion) {
               if (piece.side == sideWhite) {
                  whitePawnsInColumn++;
                  if (y > whiteMostAdvanced) whiteMostAdvanced = y;
               } else {
                  blackPawnsInColumn++;
                  if (y < blackMostAdvanced) blackMostAdvanced = y;
               }
            }
         }
         
         /* MALUS PIONS DOUBLÉS : -10 par pion doublé */
         if (whitePawnsInColumn > 1) {
            int penalty = (whitePawnsInColumn - 1) * -10;
            evalWhitePOV += penalty;  // Malus pour Blancs = négatif
         }
         if (blackPawnsInColumn > 1) {
            int penalty = (blackPawnsInColumn - 1) * -10;
            evalWhitePOV -= penalty;  // Malus pour Noirs  = positif pour Blancs
         }
         
         /* BONUS PION PASSÉ : +15 si aucun pion adverse ne peut l'arrêter
          Vérification simplifiée : pas de pion adverse dans cette colonne ni colonnes adjacentes */
         if (whitePawnsInColumn == 1 && whiteMostAdvanced >= 4) {
            BOOL isPassed = YES;
            // Vérifier colonnes adjacentes
            for (int adjX = MAX(0, x-1); adjX <= MIN(7, x+1); adjX++) {
               for (int y = whiteMostAdvanced; y < 8; y++) {
                  Piece *p = [board piece_colX:adjX rangY:y];
                  if (p && p.type == Pion && p.side == sideBlack) {
                     isPassed = NO;
                     break;
                  }
               }
            }
            if (isPassed) {
               int bonus = 15 + (whiteMostAdvanced * 5);  // Bonus croissant mais réduit
               evalWhitePOV += bonus;  // Bonus pour Blancs
            }
         }
         
         if (blackPawnsInColumn == 1 && blackMostAdvanced <= 3) {
            BOOL isPassed = YES;
            for (int adjX = MAX(0, x-1); adjX <= MIN(7, x+1); adjX++) {
               for (int y = 0; y <= blackMostAdvanced; y++) {
                  Piece *p = [board piece_colX:adjX rangY:y];
                  if (p && p.type == Pion && p.side == sideWhite) {
                     isPassed = NO;
                     break;
                  }
               }
            }
            if (isPassed) {
               int bonus = 15 + ((7 - blackMostAdvanced) * 5);
               evalWhitePOV -= bonus;  // Bonus pour Noirs = négatif pour Blancs
            }
         }
      }
      
      // ===========================================
      // PARTIE 4 : BONUS DÉVELOPPEMENT
      /* Les pièces (cavaliers/fous) sorties de leur position de départ reçoivent un bonus
       Ceci a déjà  été calculé dans la boucle principale ci-dessus */
      int developmentDiff = developmentWhite - developmentBlack;
      evalWhitePOV += developmentDiff;  // Toujours du point de vue des Blancs
      
      // ===========================================
      // PARTIE 5 : SÉCURITÉ DU ROI
      // Détecter si le Roi est dangereusement exposé
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Piece *piece = [board piece_colX:x rangY:y];
            if (piece && piece.type == Roi) {
               
               // ✅ NOUVEAU : Pénalité si Roi au centre en milieu de partie
               //BOOL isEndGame = (totalMaterial < 2000);  // Peu de matériel
               BOOL isEndGame = (materialWhite + materialBlack < 2600);
               
               
               if (!isEndGame) {
                  // En milieu de partie, le Roi DOIT être sur les bords
                  BOOL isOnEdge   = (x == 0 || x == 7 || y == 0 || y == 7);
                  BOOL isInCorner = ((x <= 1 || x >= 6) && (y == 0 || y == 7));
                  
                  if (!isOnEdge) {
                     // Roi au centre = TRÈS DANGEREUX
                     int dangerPenalty = -60;  // Grosse pénalité
                     
                     if (piece.side == sideWhite) {
                        evalWhitePOV += dangerPenalty;
                     } else {
                        evalWhitePOV -= dangerPenalty;
                     }
                  } else if (!isInCorner) {
                     // Roi sur le bord mais pas dans le coin
                     int edgePenalty = -20;
                     
                     if (piece.side == sideWhite) {
                        evalWhitePOV += edgePenalty;
                     } else {
                        evalWhitePOV -= edgePenalty;
                     }
                  }
               }
               
               // ✅ BONUS : Compter les pions protecteurs devant le Roi
               if (piece.side == sideWhite && y == 0) {  // Roi Blanc sur rangée 0
                  int pawnShield = 0;
                  
                  // Vérifier les 3 colonnes devant le Roi
                  for (int dx = -1; dx <= 1; dx++) {
                     int checkX = x + dx;
                     if (checkX >= 0 && checkX < 8) {
                        Piece *pawn = [board piece_colX:checkX rangY:1];
                        if (pawn && pawn.type == Pion && pawn.side == sideWhite) {
                           pawnShield += 10;  // Bonus par pion protecteur
                        }
                     }
                  }
                  
                  evalWhitePOV += pawnShield;
               }
               
               if (piece.side == sideBlack && y == 7) {  // Roi Noir sur rangée 7
                  int pawnShield = 0;
                  
                  for (int dx = -1; dx <= 1; dx++) {
                     int checkX = x + dx;
                     if (checkX >= 0 && checkX < 8) {
                        Piece *pawn = [board piece_colX:checkX rangY:6];
                        if (pawn && pawn.type == Pion && pawn.side == sideBlack) {
                           pawnShield += 20;
                        }
                     }
                  }
                  
                  evalWhitePOV -= pawnShield;
               }
            }
         }
      }
      
      // PARTIE 6 désactivée
      
      // ===========================================
      // PARTIE 7 : PIONS EN AVANT-DERNIÈRE RANGÉE
      // ✅ APRÈS — symétrique et indépendant
      /* Bonus important pour pions sur le point d'être promus */
      // Ce bonus s'applique toujours, peu importe qui joue
      for (int x = 0; x < 8; x++) {
          // Pion blanc en y=6 (avant-dernière rangée côté blanc)
          Piece *pionB = board->pieceCase[x][6];
          if (pionB && pionB.type == Pion && pionB.side == sideWhite) {
              evalWhitePOV += 900;
          }
          // Pion noir en y=1 (avant-dernière rangée côté noir)
          Piece *pionN = board->pieceCase[x][1];
          if (pionN && pionN.type == Pion && pionN.side == sideBlack) {
              evalWhitePOV -= 900;
          }
      }
      
      // ===========================================
      
      /* La mise à jour de l'interface est déplacée dans 'MakeIAMoveForSide' et sa variante 'Silent......'
       pour limiter le nombre de mise à jour de l'interface pendant que l'IA décide de son coup */
      
      // Stocker dans le cache
      // evalCache[key] = @(evalWhitePOV);
      // Limiter la taille du cache
      // if (evalCache.count > 200000) [evalCache removeAllObjects];
      
      /* CONVERSION FINALE POUR NEGAMAX :
       - Si 'side' = Blancs : retourner evalWhitePOV tel quel (positif = bon pour Blancs)
       - Si 'side' = Noirs  : retourner -evalWhitePOV (négatif devient positif)
       Ainsi Negamax reçoit toujours une évaluation positive = bon pour le camp qui joue */
      return (side == sideWhite) ? evalWhitePOV : -evalWhitePOV;
      //return evalWhitePOV;
      /* Pour l'évaluation du board par contre, sachant que la convention -qui veut qu'une éval
       positive indique un avantage aux Blancs et une éval négative l'inverse- se suffit à elle
       même et n'a pas à être inversée pour sa version affichée en barre d'état. */
      
   } // !EvalBoardForSide


   /* ANCIEN CODE
   // ================================================================================================
   // MÉTHODE 7 : PossibleMovesForSide - GÉNÉRATION DES COUPS LÉGAUX
   -(NSSet *)PossibleMovesForSide:(Side)side
                            board:(ChessBoard *)board
   {
      NSMutableSet *moves = [[NSMutableSet alloc] init];
      
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Pos *pos = [Pos posWithX:x y:y];
            Piece *piece = [board piece_colX:x rangY:y];
            
            if (piece && piece.side == side) {
               NSSet *PosAcceptees = [RuleBook PosLegalesForPiece:piece atPos:pos inBoard:board];
               
               for (Pos *possibleDest in PosAcceptees) {
                  Move *move = [[Move alloc] initWithStart:pos Dest:possibleDest];
                  
                  // Vérification que le coup ne met pas son propre roi en échec
                  ChessBoard *newBoard = board.copy;
                  MoveState st = [newBoard makeMove:move];
                  [moves addObject:move];
               }
            }
         }
      }
      
      return moves;
   } */

   // ================================================================================================
   // MÉTHODE 7 : PossibleMovesForSide - GÉNÉRATION DES COUPS LÉGAUX
   -(NSSet *)PossibleMovesForSide:(Side)side board:(ChessBoard *)board
   {
       NSMutableArray *allMoves = [NSMutableArray array];
       [self GenMovesForSide:side board:board into:allMoves];
       
       NSMutableSet *legalMoves = [NSMutableSet set];
       
       for (Move *m in allMoves) {
           // ✅ Copier le board pour tester l'échec
           ChessBoard *testBoard = board.copy;
           
           MoveState st = [testBoard makeMove:m];
           
           if (![self IsKingInCheck:side board:testBoard]) {
               [legalMoves addObject:m];  // ← Move intact !
           }
           
           // Pas besoin d'unmakeMove sur testBoard (il sera libéré)
       }
       
       return legalMoves;
   }


   // ================================================================================================
   // MÉTHODE 8 : TestEchecFavSide - DÉTECTION ÉCHEC EN FAVEUR DE SIDE
   -(NSString *)TestEchecFavSide:(Side)side Board:(ChessBoard *)board
   {
       Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
       checkCount = 0;  // Reset
       
       if ([self IsKingInCheck:otherSide board:board]) {
           
           // Trouver le roi
           Pos *kingPos = nil;
           for (int x = 0; x < 8; x++) {
               for (int y = 0; y < 8; y++) {
                   Piece *p = board->pieceCase[x][y];
                   if (p && p.type == Roi && p.side == otherSide) {
                       kingPos = [Pos posWithX:x y:y];
                       break;
                   }
               }
               if (kingPos) break;
           }
           
           // Compter les attaquants
           if (kingPos) {
               for (int x = 0; x < 8; x++) {
                   for (int y = 0; y < 8; y++) {
                       Piece *piece = board->pieceCase[x][y];
                       if (piece && piece.side == side) {
                           // Utiliser IsSquareAttackedAtX au lieu de générer les coups
                           if ([self IsSquareAttackedAtX:kingPos.x
                                                        Y:kingPos.y
                                                   bySide:side
                                                    Board:board]) {
                               checkCount++;
                               // On a déjà trouvé qu'il est attaqué,
                               // pas besoin de compter davantage
                               break;
                           }
                       }
                   }
                   if (checkCount > 1) break; // Permettre la détection de l'échec multiple
               }
           }
           
           // ✅ NE PAS ALERTER ICI — laisser l'appelant le faire
           NSLog(@"🔍 Échec détecté, checkCount=%d", checkCount);
           return @"Echec";
       }
       
       return @"";
   }


   // ================================================================================================
   // MÉTHODE 9 : TestEchecRoiSide - VERSION RAPIDE DE LA DÉTECTION D'ÉCHEC
   -(BOOL)TestEchecRoiSide:(Side)side inBoard:(ChessBoard *)board
   {
      Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Pos *pos = [Pos posWithX:x y:y];
            Piece *pieceAdv = [board piece_colX:x rangY:y];
            
            if (pieceAdv && pieceAdv.side == otherSide) {
               NSSet *PosAcceptees = [RuleBook PosLegalesForPiece:pieceAdv atPos:pos inBoard:board];
               
               for (Pos *possibleDest in PosAcceptees) {
                  Move *moveSideAdv = [[Move alloc] initWithStart:pos Dest:possibleDest];
                  Piece *piece = [board piece_colX:moveSideAdv.dest.x rangY:moveSideAdv.dest.y];
                  
                  if (piece.type == Roi && piece.side == side) return YES;
               }
            }
         }
      }
      
      return NO;
   }



   // ================================================================================================
   // MÉTHODE HELPER :
   // Recherche et retourne le move d'attaque le moins couteux en matériel
   -(int)CheapestAttackValue:(Pos *)targetSquare
                      bySide:(Side)attackingSide
                     inBoard:(ChessBoard *)board
   {
      int cheapestValue = SCORE_INF;
      BOOL isAttacked = NO;
      
      int targetX = targetSquare.x;
      int targetY = targetSquare.y;
      
      // ✅ OPTIMISATION : Vérifier seulement les cases qui PEUVENT attaquer la cible
      
      // 1. PIONS (diagonales)
      int pawnDir = (attackingSide == sideWhite) ? 1 : -1;
      
      for (int dx = -1; dx <= 1; dx += 2) {  // -1 et +1
         int checkX = targetX + dx;
         int checkY = targetY - pawnDir;  // Direction inverse (le pion vient d'où ?)
         
         if (checkX >= 0 && checkX < 8 && checkY >= 0 && checkY < 8) {
            Piece *p = [board piece_colX:checkX rangY:checkY];
            if (p && p.type == Pion && p.side == attackingSide) {
               isAttacked = YES;
               if (100 < cheapestValue) cheapestValue = 100;
            }
         }
      }
      
      // Optimisation : si pion trouvé, inutile de chercher plus cher
      if (cheapestValue == 100) return 100;
      
      // 2. CAVALIERS (8 positions en L)
      static const int knightMoves[8][2] = {
         {-2, -1}, {-2, 1}, {-1, -2}, {-1, 2},
         {1, -2},  {1, 2},  {2, -1},  {2, 1}
      };
      
      for (int i = 0; i < 8; i++) {
         int checkX = targetX + knightMoves[i][0];
         int checkY = targetY + knightMoves[i][1];
         
         if (checkX >= 0 && checkX < 8 && checkY >= 0 && checkY < 8) {
            Piece *p = [board piece_colX:checkX rangY:checkY];
            if (p && p.type == Cava && p.side == attackingSide) {
               isAttacked = YES;
               if (300 < cheapestValue) cheapestValue = 300;
            }
         }
      }
      
      // 3. FOUS, TOURS, DAME (directions rayonnantes)
      static const int directions[8][2] = {
         {-1, -1}, {-1, 0}, {-1, 1}, {0, -1},
         {0, 1},   {1, -1}, {1, 0},  {1, 1}
      };
      
      for (int d = 0; d < 8; d++) {
         int dx = directions[d][0];
         int dy = directions[d][1];
         
         BOOL isDiagonal = (dx != 0 && dy != 0);
         BOOL isStraight = (dx == 0 || dy == 0);
         
         // Parcourir la direction jusqu'au bord ou une pièce
         for (int dist = 1; dist < 8; dist++) {
            int checkX = targetX + dx * dist;
            int checkY = targetY + dy * dist;
            
            if (checkX < 0 || checkX >= 8 || checkY < 0 || checkY >= 8) break;
            
            Piece *p = [board piece_colX:checkX rangY:checkY];
            
            if (p) {
               if (p.side == attackingSide) {
                  // Vérifier si cette pièce peut attaquer dans cette direction
                  if (p.type == Dame) {
                     isAttacked = YES;
                     if (900 < cheapestValue) cheapestValue = 900;
                  } else if (p.type == Tour && isStraight) {
                     isAttacked = YES;
                     if (500 < cheapestValue) cheapestValue = 500;
                  } else if (p.type == Fou && isDiagonal) {
                     isAttacked = YES;
                     if (300 < cheapestValue) cheapestValue = 300;
                  } else if (p.type == Roi && dist == 1) {
                     isAttacked = YES;
                     if (100000 < cheapestValue) cheapestValue = 100000;
                  }
               }
               break;  // Pièce bloque cette direction
            }
         }
      }
      
      return isAttacked ? cheapestValue : 0;
   }


   // ================================================================================================
   // Nouvelle méthode pour générer une clé de hachage
   -(NSString *)BoardHashKey:(ChessBoard *)board forSide:(Side)side
   {
      NSMutableString *hash = [NSMutableString stringWithCapacity:128];
      
      for (int y = 0; y < 8; y++) {
         for (int x = 0; x < 8; x++) {
            Piece *p = [board piece_colX:x rangY:y];
            if (p && p.type != Invalide) [hash appendFormat:@"%d%d%d", p.type, p.side, y*8+x];
         }
      }
      [hash appendFormat:@"_%d", side];
      return hash;
   }


   // ================================================================================================
   // Méthode SEE Static Exchange Evaluation
   - (int)SEEForMove:(Move *)move board:(ChessBoard *)board
   {
      // Valeur gagnée
      int gain = [self ValueOfPiece:move.capturedPiece.type];
      
      // Coût : pièce qui capture
      int attackerValue = [self ValueOfPiece:move.movingPiece.type];
      
      // ✅ CRITIQUE : Copier le board pour ne pas affecter l'original
      ChessBoard *testBoard = board.copy;
      
      
      /* Le traitement concernera uniquement une copie du board -- */
      MoveState st = [testBoard makeMove:move];
      
      Side side = move.movingPiece.side;
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      
      NSMutableArray<Move *> *recaptures = [NSMutableArray arrayWithCapacity:8];
      [self GenCapturForSide:otherSide board:testBoard into:recaptures];
      
      int worstRecapture = 0;
      
      for (Move *rm in recaptures) {
         if (rm.toSquare == move.toSquare) {
            int v = [self ValueOfPiece:rm.movingPiece.type];
            worstRecapture = MAX(worstRecapture, v);
         }
      }
      
      [testBoard unmakeMove:move state:st];
      /* Fin de traitement sur la copie du board ----------------- */
      
      
      // 👉 BILAN MATÉRIEL RÉEL
      return gain - attackerValue - worstRecapture;
      
   } // !SEEForMove


   // ================================================================================================
   // Méthode retournant la valeur d'une pièce
   - (int)ValueOfPiece:(PieceType)p
   {
      switch (p) {
         case Pion       : return 100;     // valeur de base
         case Cava       : return 300;     // 3 Pions
         case Fou        : return 310;     // 3 Pions mais avec une préf. // Cava
         case Tour       : return 500;     // 5 Pions et moins que Fou + Cava
         case Dame       : return 900;     // 9 Pions et moins que 2 Tours
         case Roi        : return 20000;
         case Invalide   : return 0;
         default         : return 0;
      }
   }


   // ================================================================================================
   // Méthode permettant de détecter si le Roi 'side' est en échec
   -(BOOL)IsKingInCheck:(Side)side board:(ChessBoard *)board
   {
      int kingX = -1, kingY = -1;
      
      // 1️⃣ Trouver le roi
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Piece *p = board->pieceCase[x][y];
            if (p && p.type == Roi && p.side == side) {
               kingX = x;
               kingY = y;
               break;   // On sort du 'for'
            }
         }
      }
      
      NSAssert(kingX != -1, @"IsKingInCheck: roi introuvable"); // Assertion problématique...
      
      Side enemy = (side == sideWhite) ? sideBlack : sideWhite;
      
      // 2️⃣ Cavaliers
      static const int knightMoves[8][2] = {
         {1,2},{2,1},{-1,2},{-2,1},
         {1,-2},{2,-1},{-1,-2},{-2,-1}
      };
      
      for (int i = 0; i < 8; i++) {
         int nx = kingX + knightMoves[i][0];
         int ny = kingY + knightMoves[i][1];
         if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;   // On passe à l'itération suivante du 'for'
         
         Piece *p = board->pieceCase[nx][ny];
         if (p && p.side == enemy && p.type == Cava)
            return YES;
      }
      
      // 3️⃣ Pions
      int pawnDir = (enemy == sideWhite) ? 1 : -1;
      for (int dx = -1; dx <= 1; dx += 2) {
         int px = kingX + dx;
         int py = kingY - pawnDir;
         if (px < 0 || px > 7 || py < 0 || py > 7) continue;
         
         Piece *p = board->pieceCase[px][py];
         if (p && p.side == enemy && p.type == Pion)
            return YES;
      }
      
      // 4️⃣ Fous / Dames (diagonales)
      for (int d = 0; d < 4; d++) {
         int dx = bishopDirs[d][0];
         int dy = bishopDirs[d][1];
         int x = kingX + dx;
         int y = kingY + dy;
         
         while (x >= 0 && x < 8 && y >= 0 && y < 8) {
            Piece *p = board->pieceCase[x][y];
            if (p) {
               if (p.side == enemy &&
                   (p.type == Fou || p.type == Dame))
                  return YES;
               break;
            }
            x += dx;
            y += dy;
         }
      }
      
      // 5️⃣ Tours / Dames (lignes droites)
      for (int d = 0; d < 4; d++) {
         int dx = rookDirs[d][0];
         int dy = rookDirs[d][1];
         int x = kingX + dx;
         int y = kingY + dy;
         
         while (x >= 0 && x < 8 && y >= 0 && y < 8) {
            Piece *p = board->pieceCase[x][y];
            if (p) {
               if (p.side == enemy &&
                   (p.type == Tour || p.type == Dame))
                  return YES;
               break;
            }
            x += dx;
            y += dy;
         }
      }
      
      // 6️⃣ Roi adverse (cases adjacentes)
      for (int dx = -1; dx <= 1; dx++) {
         for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            int x = kingX + dx;
            int y = kingY + dy;
            if (x < 0 || x > 7 || y < 0 || y > 7) continue;
            
            Piece *p = board->pieceCase[x][y];
            if (p && p.side == enemy && p.type == Roi)
               return YES;
         }
      }
      
      return NO;
   } // !IsKingInCheck


   // Détecte si une position a déjà été vue (répétition = nulle)
   -(BOOL)isRepetition:(uint64_t)zobristKey
   {
       // Compter les occurrences de cette clé dans l'historique
       int count = 0;
       for (int i = 0; i < historyCount; i++) {
           if (positionHistory[i] == zobristKey) {
               count++;
               if (count >= 2) {
                   // 3ème occurrence (2 dans l'historique + la position actuelle)
                   return YES;
               }
           }
       }
       return NO;
   }


   


@end


#ifdef DEBUG_ZOBRIST
   // Fonction recalculant la clé Zobrist
   uint64_t recomputeZobrist(ChessBoard *board)
   {
       uint64_t key = 0;

       // 🔹 Pièces sur l’échiquier
       for (int x = 0; x < 8; x++) {
           for (int y = 0; y < 8; y++) {
               Piece *p = board->pieceCase[x][y];
               if (!p) continue;

               int sq = y * 8 + x;
               key ^= zobristPiece[p.side][p.type][sq];
           }
       }

       // 🔹 Side to move
       if (board->sideToMove == sideBlack) {
           key ^= zobristSide;
       }

       // 🔹 Droits de roque
       key ^= zobristCastle[board->castlingRights];

       // 🔹 En-passant
       if (board->enPassantFile != -1) {
           key ^= zobristEnPassant[board->enPassantFile];
       }

       return key;
   }
#endif
