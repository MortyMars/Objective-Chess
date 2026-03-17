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
#import "PeSTO.h"


// Définition ci-dessous de la valeur de base du mat reportée dans Util.h pour accès à Minimax + les TT
// #define MATE_SCORE    100000

#define SCORE_INF     200000   // définit à 200000 le plus bas des scores
                               // SCORE_INF > MATE_SCORE, et SCORE_INF < INT_MAX/2

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
         [self buildOpeningBook];  // Ouverture de l'Opening Book
      }
      return self;
   }


   // ================================================================================================
   // MÉTHODE BestMoveForSide - Point d'entrée du moteur IA
   // Cette méthode trouve le meilleur coup pour l'IA en explorant l'arbre des possibilités
   -(Move *)BestMoveForSide:(Side)side Board:(ChessBoard *)board
   {
      // --- Initialisation des iVars et variables -----------------
      nbLoop = 0; nbElag = 0; nodeCount = 0;
      evalCount = 0; moveGenCount = 0; copyBoardCount = 0;
      evalTotalTime = 0; moveGenTotalTime = 0;
      memset(historyTable, 0, sizeof(historyTable));
      //isInNullMove = NO;
      historyCount = 0;
      memset(positionHistory, 0, sizeof(positionHistory));
      nodes = 0;
      _idBestMove  = nil;
      _idBestScore = -SCORE_INF - 1;
      [self.transpositionTable newGeneration];
      
      NSDate *startTime = [NSDate date];
      
      // 📖 Consulter le livre d'ouvertures en premier
      if (board->nbEntiers <= 16) {  // Limiter aux 16 premiers coups entiers (Joueur+IA)
        Move *bookMove = [self lookupOpeningBook:board side:side];
        if (bookMove) {
            _idBestMove  = bookMove;
            _idBestScore = 0;
            return bookMove;
        }
      }
      
      // --- Vérification légalité des coups -----------------------
      NSSet *movesPossibles = [self PossibleMovesForSide:side board:board];
      if (movesPossibles.count == 0) {
         [monConnecteur AlertMsgPatMatSide:side onBoard:board];
         return nil;
      }
      
      // -----------------------------------------------------------
      // 🔁 ITERATIVE DEEPENING : de depth 1 → NUMBER_MOVES_AHEAD
      for (int depth = 1; depth <= NUMBER_MOVES_AHEAD; depth++) {
         
         // Réinitialiser alpha/beta à chaque itération
         int alpha = -SCORE_INF;
         int beta  =  SCORE_INF;
         
         Move *iterBestMove  = nil;
         int   iterBestScore = -SCORE_INF - 1;
         
         memset(_killerMoves, 0, sizeof(_killerMoves));  // ← Killer Moves
         
         // Tri des coups — le hash move de la TT sera promu automatiquement
         NSMutableArray *moves = [NSMutableArray arrayWithArray:
                                  [movesPossibles allObjects]];
         [self ScoreMovesList:moves board:board side:side depth:depth];
         
         // ✨ Promouvoir le meilleur coup de l'itération précédente
         if (_idBestMove) {
            for (Move *m in moves) {
               if (m.fromSquare == _idBestMove.fromSquare &&
                   m.toSquare   == _idBestMove.toSquare) {
                  m.orderingScore += 2000000; // Priorité maximale
                  break;
               }
            }
         }
         
         [moves sortUsingComparator:^NSComparisonResult(Move *a, Move *b) {
            return (b.orderingScore - a.orderingScore);
         }];
         
         // --- Boucle racine ---
         for (Move *move in moves) {
            
            // Skip répétition immédiate
            if (self.lastIAMove &&
                move.fromSquare == self.lastIAMove.toSquare &&
                move.toSquare   == self.lastIAMove.fromSquare) {
               continue;
            }
            
            positionHistory[historyCount++] = board->zobristKey;
            MoveState st = [board makeMove:move];
            
            int score = -[self NegamaxForSide:(side == sideWhite ? sideBlack : sideWhite)
                                        board:board
                                        depth:depth - 1
                                        alpha:-beta
                                         beta:-alpha
                                   inNullMove:NO];
            
            [board unmakeMove:move state:st];
            historyCount--;
            
            if (score > iterBestScore) {
               iterBestScore = score;
               iterBestMove  = move;
            }
            if (score > alpha) alpha = score;
            if (alpha >= beta) break; // Beta cutoff racine
         }
         
         // --- Valider l'itération ---
         if (iterBestMove) {
            _idBestMove  = iterBestMove;
            _idBestScore = iterBestScore;
            // Log de Debug
            if (board->nbEntiers >= 28 && board->nbEntiers <= 42) {
                NSLog(@"🔍 Coup %d : phase=%d isEndGame=%d score=%d",
                      board->nbEntiers, self.lastPhase,
                      (self.lastPhase < 80), _idBestScore);
            }
            // Fin Log Debug
         }
         
         // NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
         // NSLog(@"🔁 depth=%d → coup=%@ score=%d (%.2fs, %llu nœuds)",
         //       depth, _idBestMove, _idBestScore, elapsed, nodes);
         
      } // fin iterative deepening
      
      // ✅ FALLBACK : si aucune itération n'a produit de coup
      // (cas rare : mat en 1, double échec, retour TT prématuré)
      if (!_idBestMove) {
         NSMutableArray<Move *> *fallbackMoves = [NSMutableArray array];
         [self GenMovesForSide:side board:board into:fallbackMoves];
         
         for (Move *m in fallbackMoves) {
            MoveState st = [board makeMove:m];
            BOOL legal = ![self IsKingInCheck:side board:board];
            [board unmakeMove:m state:st];
            
            if (legal) {
               _idBestMove  = m;
               _idBestScore = 0;  // Score inconnu, valeur neutre
               NSLog(@"⚠️ Fallback activé : coup %@ choisi par défaut", m);
               break;
            }
         }
      }
      
      // --- Stats finales ---
      NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
      NSLog(@"---------------------------------------------------------");
      if (sideIA==sideBlack) {
         NSLog(@"✅ Best Move : %@ (score=%d, %.1fs, %llu nœuds, %.0f n/s)",
               _idBestMove, _idBestScore, elapsed, nodes,
               (elapsed > 0) ? nodes/elapsed : 0);
      } else {
         NSLog(@"✅ Best Move : %@ (score=%d, %.1fs, %llu nœuds, %.0f n/s)",
               [Move opMove:_idBestMove], _idBestScore, elapsed, nodes,
               (elapsed > 0) ? nodes/elapsed : 0);
      }
      
      [self.transpositionTable printStats];
      
      self.lastIAMove = _idBestMove;
      
      // Log ciblé finale — à commenter après diagnostic
      if (board->nbEntiers >= 28 && board->nbEntiers <= 42) {
          NSLog(@"🔍 Coup %d : phase=%d isEndGame=%d score=%d",
                board->nbEntiers,
                self.lastPhase,
                (self.lastPhase < 80),
                _idBestScore);
      }
      
      return _idBestMove;
      
   } // !BMFS


   // ================================================================================================
   // MÉTHODE NegamaxForSide avec Tables de Transposition
   // Moteur récursif du jeu, explorant l'arbre des possibilités de coups réalisables
   -(int)NegamaxForSide:(Side)side
                  board:(ChessBoard *)board
                  depth:(int)depth
                  alpha:(int)alpha
                   beta:(int)beta
             inNullMove:(BOOL)inNullMove
   {
      nodes++;
      
      #ifdef DEBUG_ZOBRIST
         uint64_t keyEntry = board->zobristKey;
      #endif
      
      // ✅ Détection de répétition AVANT probe TT
      if ([self isRepetition:board->zobristKey]) {
         // Score de répétition contextualisé :
         // - En position gagnante : malus pour décourager la répétition
         // - En position perdante : bonus pour encourager la répétition (sauvetage)
         // On utilise evalWhitePOV du dernier calcul statique comme proxy
         int contempt = (side == sideWhite) ? self.lastPhase / 4
                                          : -(self.lastPhase / 4);
         // contempt ∈ [-64, +64] selon la phase
         // En ouverture (phase=256) : contempt = ±64 → forte dissuasion
         // En finale   (phase=0)   : contempt = 0  → répétition neutre
         return -contempt;
      }
      
      
      // ----------------------------------------------------------------------
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
      
      
      // Sauvegarder alpha APRÈS ajustements TT, et AVANT exploration
      int alphaOrig = alpha;
      
      
      // ----------------------------------------------------------------------
      // Quiescence Search à profondeur 0
      if (depth <= 0) {
         return [self QuiescenceForSide:side
                                  board:board
                                  alpha:alpha
                                   beta:beta
                                qsDepth:0];
      }
      
      // ----------------------------------------------------------------------
      // ✅ NULL MOVE PRUNING

      BOOL inCheck = [self IsKingInCheck:side board:board];

      // Conditions pour NMP :
      // 1. Profondeur suffisante (≥ 3)
      // 2. Pas en échec (null move serait illégal)
      // 3. Pas déjà dans un null move (éviter récursion infinie)
      // 4. Pas dans une position de mat proche (optionnel)

      if (depth >= 3 && !inCheck && !inNullMove) {
         
        /* Suppression reprise Claude */
        // Activer le flag
        //isInNullMove = YES;
        
        // L'adversaire joue (sans coup réel)
        Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
        
        // Réduction de profondeur (R = 2)
        int R = 2;
        
        // Recherche avec fenêtre nulle
        int nullScore = -[self NegamaxForSide:otherSide
                                        board:board
                                        depth:depth - 1 - R
                                        alpha:-beta
                                         beta:-beta + 1
                                   inNullMove:YES];
        
        /* Suppression reprise Claude */
        // Désactiver le flag
        //isInNullMove = NO;
         
        // ✅ LOG pour debug
        //NSLog(@"🔍 NMP depth=%d, nullScore=%d, beta=%d, cutoff=%d",
        //        depth, nullScore, beta, (nullScore >= beta));
        
        // Si même avec le handicap, on est au-dessus de beta
        if (nullScore >= beta) {
            // Coupure beta ! Pas besoin de chercher plus
            // Note : on ne stocke PAS dans la TT (résultat approximatif)
            return beta;  // Fail-soft
        }
      }
      
      // ----------------------------------------------------------------------
      // Génération et tri des coups
      NSMutableArray<Move *> *moves = [NSMutableArray arrayWithCapacity:64];
      [self GenMovesForSide:side board:board into:moves];
      
      // Move Ordering avec bonus TT
      // NSLog(@"🔵 AVANT ScoreMovesList, enPassantFile=%d", board->enPassantFile);
      [self ScoreMovesList:moves board:board side:side depth:depth];
      
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
      
      // ----------------------------------------------------------------------
      // Traiter le cas Mat/Pat
      if (moves.count == 0) {
         
         #ifdef DEBUG_ZOBRIST
               NSAssert(board->zobristKey == keyEntry,
                        @"Zobrist corrompu : sortie Negamax sans coups");
         #endif
         
         int score;
         if ([self IsKingInCheck:side board:board]) {
            // Mat : très mauvais pour le camp qui joue
            score = -MATE_SCORE + (NUMBER_MOVES_AHEAD - depth);
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
      
      // ----------------------------------------------------------------------
      // Recherche principale
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      Move *bestMove = nil;  // ✨ Tracker le meilleur coup pour TT
      
      int moveIndex = 0;   // ← compteur LMR
      
      for (Move *m in moves) {
         
         #ifdef DEBUG_ZOBRIST
               uint64_t keyBefore = board->zobristKey;
               NSLog(@"➡️ AVANT makeMove %@ : hash=%llx", m, keyBefore);
         #endif
         
         // ✅ Ajouter la position à l'historique AVANT makeMove
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
            
            // ── LMR : conditions d'éligibilité ──────────────────
            /* Dans Negamax, les coups sont triés du meilleur au moins bon. Les premiers coups
            (TT move, captures gagnantes, killers) méritent une recherche pleine profondeur.
            Les coups tardifs dans la liste —les moins prometteurs— ont peu de chances d'être le
            meilleur coup. LMR parie sur ça : on les recherche à profondeur réduite. Si le score
            réduit dépasse alpha, on re-recherche à pleine profondeur pour confirmer. ------- */
            BOOL lmrEligible = (depth >= LMR_MIN_DEPTH)           // profondeur suffisante
                            && (moveIndex >= LMR_MOVE_THRESHOLD)  // coup tardif
                            && !m.isCapture                       // pas une capture
                            && !m.isPromotion                     // pas une promotion
                            && !inCheck;                          // pas en échec
                        
            // ── Calcul de R ─────────────────────────────────────
            int R = 0;
            if (lmrEligible) {
                  R = (moveIndex >= LMR_LATE_MOVE) ? LMR_REDUCTION_2 : LMR_REDUCTION_1;
            }
            
            int score;
            
            // RECHERCHE RÉDUITE EN MODE LMR
            if (R > 0) {
               // ── Recherche réduite LMR ────────────────────────
               score = -[self NegamaxForSide:otherSide
                                       board:board
                                       depth:depth-1 - R // profondeur réduire de R (1 ou 2)
                                       alpha:-beta
                                        beta:-alpha
                                  inNullMove:NO];
            
            
               // ── Re-recherche pleine profondeur si prometteur ─
               if (score > alpha) {
                  score = -[self NegamaxForSide:otherSide
                                          board:board
                                          depth:depth-1
                                          alpha:-beta
                                           beta:-alpha
                                     inNullMove:NO];
               }
               // NSLog de contrôle du déclenchement du LMR
               // NSLog(@"🔻 LMR depth=%d moveIndex=%d R=%d", depth, moveIndex, R);
            }
            // RECHERCHE PLEINE PROFONDEUR (NEGAMAX STANDARD)
            else {
               // ── Recherche pleine profondeur coups prioritaires
               score = -[self NegamaxForSide:otherSide
                                       board:board
                                       depth:depth-1
                                       alpha:-beta
                                        beta:-alpha
                                  inNullMove:NO];
            } // Brackett MCN !?
            
            // ✅ LOG pour les coups suspects
            if (depth == NUMBER_MOVES_AHEAD) {  // Seulement au niveau racine
                NSLog(@"🎯 Coup %@ → score=%d", m, score);
            }
            
            if (score > alpha) {
               alpha = score;
               bestMove = m;  // ✨ Nouveau meilleur coup
            }
         }
         
         [board unmakeMove:m state:st];
         
         // ✅ Retirer la position de l'historique APRÈS unmakeMove
         historyCount--;
         
         // Incrémenter après chaque coup tenté (légal ou non)
         moveIndex++;
         
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
            // Killer Move : coup silencieux qui cause un cutoff
            if (!m.isCapture && !m.isPromotion) {
               int sideIdx = (side == sideWhite)? 0 : 1;
              // Éviter les doublons
              BOOL alreadyKiller = (_killerMoves[depth][0] &&
                  m.fromSquare == _killerMoves[depth][sideIdx][0].fromSquare &&
                  m.toSquare   == _killerMoves[depth][sideIdx][0].toSquare);
              
              if (!alreadyKiller) {
                  _killerMoves[depth][sideIdx][1] = _killerMoves[depth][sideIdx][0];
                  _killerMoves[depth][sideIdx][0] = m;
              }
            }
            break;
         }
         
      } // Sortie de boucle for de Recherche Principale
      
      #ifdef DEBUG_ZOBRIST
         NSAssert(board->zobristKey == keyEntry,
                  @"Zobrist corrompu : sortie Negamax normale");
      #endif
      
      // ----------------------------------------------------------------------
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
   // MÉTHODE QuiescenceForSide
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
            return standPat;  // fail-soft : retourner le score réel
         }
         if (standPat > alpha) alpha = standPat;
      }
      
      // 2️⃣ Limite QS (mais jamais en échec)
      if (qsDepth >= QS_MAX_DEPTH && !inCheck) {
         #ifdef DEBUG_ZOBRIST
                  NSAssert(board->zobristKey == keyEntry,
                           @"Zobrist corrompu : QS stand-pat cutoff");
         #endif
         return alpha;
      }
      
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
            NSAssert(standPat != -INF, @"standPat non initialisé dans delta pruning");
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
         
         // Après ces filtres, on peut y aller
         MoveState st = [board makeMove:m];
         
         BOOL legal = ![self IsKingInCheck:side board:board];
         if (legal) {
            int score = -[self QuiescenceForSide:otherSide
                                           board:board
                                           alpha:-beta
                                            beta:-alpha
                                         qsDepth:qsDepth + 1];
            
            [board unmakeMove:m state:st];  // ← toujours ici, légal ou non
            
            if (score >= beta)  return score;  // fail-soft
            
            if (score > alpha)  alpha = score;
            
         } else {
            [board unmakeMove:m state:st]; // si en échec on annule le coup
         }
      }
      
      #ifdef DEBUG_ZOBRIST
      NSAssert(board->zobristKey == keyEntry,
               @"Zobrist corrompu : QS return final");
      #endif
      
      return alpha;
      
   } // !QuiescenceForSide

   
   // ================================================================================================
   // MÉTHODE ScoreMove - ÉVALUATION D'UN COUP (Ne pas confondre avec 'ScoreMovesList'
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
            case Cava: victimValue = 300; break;
            case Fou:  victimValue = 310; break;
            case Tour: victimValue = 500; break;
            case Dame: victimValue = 900; break;
            case Roi:  victimValue = 100000; break;
            default: break;
         }
         
         switch (movingPiece.type) {
            case Pion: attackerValue = 100; break;
            case Cava: attackerValue = 300; break;
            case Fou:  attackerValue = 310; break;
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
   // MÉTHODE ScoreMovesList - ÉVALUATION D'UNE LISTE DE COUPS (Ne pas confondre avec ScoreMove)
   - (void)ScoreMovesList:(NSArray<Move *> *)moves
                    board:(ChessBoard *)board
                     side:(Side)side
                    depth:(int)depth
   {
      int sideIdx = (side == sideWhite)? 0 : 1;
      
      for (Move *m in moves) {
         
         int score = 0;
         
         if (m.isCapture) {
            int see = [self SEEForMove:m board:board];
            
            if (see >= 0) score = 10000 + see;   // captures gagnantes
            else score = 5000 + see;             // captures perdantes
            
         }
         else {
            // Killer 1
            if (_killerMoves[depth][sideIdx][0] &&
                m.fromSquare == _killerMoves[depth][sideIdx][0].fromSquare &&
                m.toSquare   == _killerMoves[depth][sideIdx][0].toSquare) {
              score += 9000;
            }
            // Killer 2
            else if (_killerMoves[depth][sideIdx][1] &&
                     m.fromSquare == _killerMoves[depth][sideIdx][1].fromSquare &&
                     m.toSquare   == _killerMoves[depth][sideIdx][1].toSquare) {
              score += 8000;
            }
            // 🎯 Coups calmes intéressants
            if (m.movingPiece.type == Cava || m.movingPiece.type == Fou)
               score += 100;  // développement
            
            if (m.givesCheck) score += 200;
            
            if (m.isCastling) score += 300;
            
            if (m.isPromotion) score += 900;
         }
         
         m.orderingScore = score;
      }
   } // !ScoreMovesList




   // ================================================================================================
   // MÉTHODE FilterCaptures - FILTRAGE DES CAPTURES POUR QUIESCENCE SEARCH
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
   // MÉTHODE EvalBoardForSide - VERSION AMÉLIORÉE AVEC ÉVALUATION POSITIONNELLE
   // Cette méthode évalue la qualité d'une position d'échecs pour un camp donné
   // PHILOSOPHIE D'ÉVALUATION :
   // - Matériel : Valeur brute des pièces (base)
   // - Position : Où sont placées les pièces (crucial)
   // - Sécurité : Le roi est-il en sécurité ?
   // - Structure : Les pions sont-ils bien organisés ?
   // - Mobilité : Combien de coups possibles ?
   // - Développement : Les pièces sont-elles actives ?
   -(int)EvalBoardForSide:(Side)side
                    board:(ChessBoard *)board
   {
      evalWhitePOV = 0;  /* Évaluation du point de vue des Blancs (convention Negamax) */
      
      /* Variables pour statistiques intermédiaires */
      //int materialWhite = 0, materialBlack = 0;
      //int developmentWhite = 0, developmentBlack = 0;
      //int totalMaterial = 0;  /* Pour détecter la fin de partie */
      
      // ── PARTIE 1 : MATÉRIEL + PST PESTO + INTERPOLATION DE PHASE ─────────────
      evalWhitePOV = 0;
      // Accumulateurs mg/eg séparés pour chaque camp
      int mgWhite = 0, egWhite = 0;
      int mgBlack = 0, egBlack = 0;
      // Compteurs pour le calcul de phase
      int knights = 0, bishops = 0, rooks = 0, queens = 0;
      // Variables de développement (conservées pour Partie 3)
      int developmentWhite = 0, developmentBlack = 0;
      // ── Passe unique sur le board ─────────────────────────────────────────────
      for (int x = 0; x < 8; x++) {
          for (int y = 0; y < 8; y++) {
              Piece *piece = board->pieceCase[x][y];
              if (!piece || piece.type == Invalide) continue;
              int sq   = y * 8 + x;   // convention : y=0 fond Blancs
              int side = (piece.side == sideWhite) ? 0 : 1;
              int type = (int)piece.type;
              int mg = PeSTO_PieceValueMG[type] + PeSTO_LookupMG(type, sq, side);
              int eg = PeSTO_PieceValueEG[type] + PeSTO_LookupEG(type, sq, side);
              // Comptage pour la phase (toutes pièces des deux camps)
              switch (piece.type) {
                  case Cava: knights++; break;
                  case Fou:  bishops++; break;
                  case Tour: rooks++;   break;
                  case Dame: queens++;  break;
                  default: break;
              }
              // Bonus développement (conservé pour Partie 3)
              if (piece.type == Cava || piece.type == Fou) {
                  if (piece.side == sideWhite && y > 0) developmentWhite += 5;
                  if (piece.side == sideBlack && y < 7) developmentBlack += 5;
              }
              // Malus Tour bougée prématurément (conservé)
              if (piece.type == Tour && piece.numMoves > 0) {
                  BOOL kingHasCastled = NO;
                  if (piece.side == sideWhite) {
                      Piece *wk = board->pieceCase[2][0];
                      if (!wk || wk.type != Roi || wk.side != sideWhite)
                          wk = board->pieceCase[6][0];
                      kingHasCastled = (wk && wk.type == Roi &&
                                        wk.side == sideWhite && wk.numMoves > 0);
                  } else {
                      Piece *bk = board->pieceCase[2][7];
                      if (!bk || bk.type != Roi || bk.side != sideBlack)
                          bk = board->pieceCase[6][7];
                      kingHasCastled = (bk && bk.type == Roi &&
                                        bk.side == sideBlack && bk.numMoves > 0);
                  }
                  if (!kingHasCastled) {
                      if (piece.side == sideWhite) { mgWhite -= 25; egWhite -= 10; }
                      else                         { mgBlack -= 25; egBlack -= 10; }
                  }
              }
              // Malus Dame sortie trop tôt
              if (piece.type == Dame && board->nbEntiers < 10) {
                  if (piece.side == sideWhite && y > 1) mgWhite -= 10;
                  if (piece.side == sideBlack && y < 6) mgBlack -= 10;
              }
              // Accumulation
              if (piece.side == sideWhite) { mgWhite += mg; egWhite += eg; }
              else                         { mgBlack += mg; egBlack += eg; }
          }
      }
      // ── Interpolation de phase ────────────────────────────────────────────────
      int phase = PeSTO_GamePhase(knights, bishops, rooks, queens);
      self.lastPhase = phase;  // ← exposer pour le log provisoire
      // Score interpolé du point de vue des Blancs
      int scoreWhite = PeSTO_Interpolate(mgWhite, egWhite, phase);
      int scoreBlack = PeSTO_Interpolate(mgBlack, egBlack, phase);
      evalWhitePOV   = scoreWhite - scoreBlack;
      // Exposer la phase pour les Parties suivantes
      // (remplace le booléen isEndGame utilisé dans Parties 5 et 7)
      BOOL isEndGame = (phase < 80);  // ~30% du matériel restant
      
      // NSLog de contrôle (ATTENTION VERBEUX)
      /* NSLog(@"📊 Phase=%d isEndGame=%d (knights=%d bishops=%d rooks=%d queens=%d)",
            phase, isEndGame, knights, bishops, rooks, queens); */
      
      /* -------------------------------------------
      PARTIE 2 : ÉVAL. DE LA STRUCTURE DE PIONS
      Détection des pions doublés (malus) et pions passés (bonus) */
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
            int penalty = (whitePawnsInColumn - 1) * -20; // de 10 à 20 : recalibrage PeSTO
            evalWhitePOV += penalty;  // Malus pour Blancs = négatif
         }
         if (blackPawnsInColumn > 1) {
            int penalty = (blackPawnsInColumn - 1) * -20;
            evalWhitePOV -= penalty;  // Malus pour Noirs  = positif pour Blancs
         }
         
         /* BONUS PION PASSÉ : +15 si aucun pion adverse ne peut l'arrêter
         Vérification simplifiée : pas de pion adverse dans cette colonne ni colonnes adjacentes */
         if (whitePawnsInColumn == 1 && whiteMostAdvanced >= 3) {
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
               // Bonus de base modulé par avancement et phase
               int baseBonus = 20 + (whiteMostAdvanced * 10);
               // En finale, le pion passé est beaucoup plus dangereux
               int egBonus = 40 + (whiteMostAdvanced * 20);
               int bonus = PeSTO_Interpolate(baseBonus, egBonus, phase);
               evalWhitePOV += bonus;  // Bonus pour Blancs
            }
         }
         
         if (blackPawnsInColumn == 1 && blackMostAdvanced <= 4) {
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
               int baseBonus = 20 + ((7 - blackMostAdvanced) * 10);
               // En finale, le pion passé est beaucoup plus dangereux
               int egBonus   = 40 + ((7 - blackMostAdvanced) * 20);
               int bonus = PeSTO_Interpolate(baseBonus, egBonus, phase);
               evalWhitePOV -= bonus; // Bonus pour Noirs = négatif pour Blancs
            }
         }
         
         /* MALUS PIONS ISOLÉS : pas de pion ami sur colonnes adjacentes */
         if (whitePawnsInColumn == 1) {
            BOOL hasLeftSupport  = (x > 0 && [self pawnsInColumn:x-1 side:sideWhite board:board] > 0);
            BOOL hasRightSupport = (x < 7 && [self pawnsInColumn:x+1 side:sideWhite board:board] > 0);
            if (!hasLeftSupport && !hasRightSupport)
               evalWhitePOV -= PeSTO_Interpolate(15, 25, phase); // plus pénalisant en EG
         }
         if (blackPawnsInColumn == 1) {
            BOOL hasLeftSupport  = (x > 0 && [self pawnsInColumn:x-1 side:sideBlack board:board] > 0);
            BOOL hasRightSupport = (x < 7 && [self pawnsInColumn:x+1 side:sideBlack board:board] > 0);
            if (!hasLeftSupport && !hasRightSupport)
               evalWhitePOV += PeSTO_Interpolate(15, 25, phase);
         }
         
      } // !for Partie 2
      
      /* -------------------------------------------
      PARTIE 3 : BONUS DÉVELOPPEMENT
      Les pièces (cavaliers/fous) sorties de leur position de départ reçoivent un bonus
      Ceci a déjà  été calculé dans la boucle principale ci-dessus                   */
      int developmentDiff = developmentWhite - developmentBlack;
      evalWhitePOV += developmentDiff;  // Toujours du point de vue des Blancs
      
      /* -------------------------------------------
      PARTIE 4 : BONUS MOBILITÉ
      Comptage des coups pseudo-légaux disponibles pour chaque camp
      Plus on a d'options, mieux c'est !                         */
      int mobilityBonus = [self EvaluateMobility:board];
      evalWhitePOV += mobilityBonus;
      
      /* -------------------------------------------
      PARTIE 5 : SÉCURITÉ DU ROI
      Détecter si le Roi est dangereusement exposé */
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Piece *piece = [board piece_colX:x rangY:y];
            if (piece && piece.type == Roi) {
               
               // ✅ NOUVEAU : Pénalité si Roi au centre en milieu de partie
               // on réutilise 'isEndGame' de la partie 1
               // on commente donc la ligne ci-dessous
               //BOOL isEndGame = (materialWhite + materialBlack < 2600);
               
               
               if (!isEndGame) {
                  // En milieu de partie, le Roi DOIT être sur les bords
                  BOOL isOnEdge   = (x == 0 || x == 7 || y == 0 || y == 7);
                  BOOL isInCorner = ((x <= 1 || x >= 6) && (y == 0 || y == 7));
                  
                  if (!isOnEdge) {
                     // Roi au centre = TRÈS DANGEREUX
                     int dangerPenalty = -120;  // ~1.5 pion PeSTO
                     
                     if (piece.side == sideWhite) {
                        evalWhitePOV += dangerPenalty;
                     } else {
                        evalWhitePOV -= dangerPenalty;
                     }
                  } else if (!isInCorner) {
                     // Roi sur le bord mais pas dans le coin
                     int edgePenalty = -40;
                     
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
                           pawnShield += 40; // ~0.5 pion PeSTO par pion protecteur
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
                           pawnShield += 40; // ~0.5 pion PeSTO par pion protecteur
                        }
                     }
                  }
                  
                  evalWhitePOV -= pawnShield;
               }
               
               /* ROI ACTIF EN FINALE */
               if (isEndGame) {
                   // Localiser les deux Rois
                   int wkx = -1, wky = -1, bkx = -1, bky = -1;
                   for (int ix = 0; ix < 8 && (wkx < 0 || bkx < 0); ix++)
                       for (int iy = 0; iy < 8 && (wkx < 0 || bkx < 0); iy++) {
                           Piece *p = board->pieceCase[ix][iy];
                           if (p && p.type == Roi) {
                               if (p.side == sideWhite) { wkx = ix; wky = iy; }
                               else                     { bkx = ix; bky = iy; }
                           }
                       } // Fin de for for
                  
                   if (wkx >= 0 && bkx >= 0) {
                       // Distance de Manhattan entre les deux Rois
                       int kingDist = abs(wkx - bkx) + abs(wky - bky);
                       // Centralisation : distance au centre (3.5, 3.5)
                       int wCenterDist = abs(wkx - 3) + abs(wky - 3);
                       int bCenterDist = abs(bkx - 3) + abs(bky - 3);
                       // Bonus si avantage matériel : forcer le rapprochement des Rois
                       if (evalWhitePOV > 100) {
                           // Blancs gagnants : Roi Blanc vers Roi Noir, Roi Noir au bord
                           evalWhitePOV -= kingDist * 4;    // récompense la proximité
                           evalWhitePOV += bCenterDist * 6; // punit Roi Noir au bord
                           evalWhitePOV -= wCenterDist * 2; // encourage Roi Blanc au centre
                       } else if (evalWhitePOV < -100) {
                           // Noirs gagnants : symétrique
                           evalWhitePOV += kingDist * 4;
                           evalWhitePOV -= wCenterDist * 6;
                           evalWhitePOV += bCenterDist * 2;
                       }
                   }
               } /* Fin de Roi actif en finale */
               
            }
         }
      }
      
      /* -------------------------------------------
      PARTIE 6 : PIONS EN AVANT-DERNIÈRE RANGÉE   */
      for (int x = 0; x < 8; x++) {
          Piece *pionB = board->pieceCase[x][6];
          if (pionB && pionB.type == Pion && pionB.side == sideWhite) {
              evalWhitePOV += 400; // PeSTO couvre déjà ~178 via table Pion EG rang 7
              //NSLog(@"🔵 Pion blanc promo x=%d, evalWhitePOV=%d", x, evalWhitePOV);
          }
          Piece *pionN = board->pieceCase[x][1];
          if (pionN && pionN.type == Pion && pionN.side == sideBlack) {
              evalWhitePOV -= 400;
              //NSLog(@"🔵 Pion noir promo x=%d, evalWhitePOV=%d", x, evalWhitePOV);
          }
      }
      
      /* -------------------------------------------
      PARTIE 7 : BONUS ROQUE (MiddleGame only)    */
      if (!isEndGame) {
         
         // --- BLANCS ---
         Piece *whiteKing = nil;
         int wkx = 0, wky = 0;
         for (int x = 0; x < 8 && !whiteKing; x++)
            for (int y = 0; y < 8 && !whiteKing; y++) {
               Piece *p = board->pieceCase[x][y];
               if (p && p.type == Roi && p.side == sideWhite) {
                  whiteKing = p; wkx = x; wky = y;
               }
            }
         
         if (whiteKing) {
            BOOL wCastledKS  = (wkx == 6 && wky == 0);  // g1
            BOOL wCastledQS  = (wkx == 2 && wky == 0);  // c1
            BOOL wCanCastleK = (board->castlingRights & 1);
            BOOL wCanCastleQ = (board->castlingRights & 2);
            BOOL wKingOnE1   = (wkx == 4 && wky == 0);  // pas encore bougé
            
            if (wCastledKS || wCastledQS) {
               evalWhitePOV += 40; // PeSTO couvre déjà une partie via Roi MG
            } else if (wKingOnE1 && (wCanCastleK || wCanCastleQ)) {
               
               // ✅ NOUVEAU : vérifier que le chemin est libre
               BOOL kingsideFree  = !board->pieceCase[5][0] &&
               !board->pieceCase[6][0]; // f1 et g1 libres
               BOOL queensideFree = !board->pieceCase[1][0] &&
               !board->pieceCase[2][0] &&
               !board->pieceCase[3][0]; // b1, c1, d1 libres
               
               //BOOL canActuallyCastle = (wCanCastleK && kingsideFree) ||
               //(wCanCastleQ && queensideFree);
               
               /* Vérifier que les Tours n'ont pas bougé */
               Piece *wRookK = board->pieceCase[7][0];  // h1
               Piece *wRookQ = board->pieceCase[0][0];  // a1
               BOOL wRookKIntact = (wRookK && wRookK.type == Tour &&
                                    wRookK.side == sideWhite && wRookK.numMoves == 0);
               BOOL wRookQIntact = (wRookQ && wRookQ.type == Tour &&
                                    wRookQ.side == sideWhite && wRookQ.numMoves == 0);
               BOOL canActuallyCastle = (wCanCastleK && kingsideFree && wRookKIntact) ||
                                        (wCanCastleQ && queensideFree && wRookQIntact);
               /* Fin de vérif déplacement des tours */
               
               if (canActuallyCastle) {
                  evalWhitePOV += 30;   // Roque réellement possible
               } else {
                  evalWhitePOV -= 40;   // Droit formel mais chemin bloqué ❌
               }
            } else {
               evalWhitePOV -= 80;       // Droit perdu
            }
            
            // NSLog(@"wks=%d, wky=%d, wCastledKS=%d, wCanCastleK=%d, \nevalWhitePOV=%d, castlingRights=%d",
            //         wkx,    wky,    wCastledKS,    wCanCastleK,      evalWhitePOV,    board->castlingRights);
         }
         
         // --- NOIRS ---
         Piece *blackKing = nil;
         int bkx = 0, bky = 0;
         for (int x = 0; x < 8 && !blackKing; x++)
            for (int y = 0; y < 8 && !blackKing; y++) {
               Piece *p = board->pieceCase[x][y];
               if (p && p.type == Roi && p.side == sideBlack) {
                  blackKing = p; bkx = x; bky = y;
               }
            }
         
         if (blackKing) {
            BOOL bCastledKS  = (bkx == 6 && bky == 7);  // g8
            BOOL bCastledQS  = (bkx == 2 && bky == 7);  // c8
            BOOL bCanCastleK = (board->castlingRights & 4);
            BOOL bCanCastleQ = (board->castlingRights & 8);
            BOOL bKingOnE8   = (bkx == 4 && bky == 7);  // pas encore bougé
            
            if (bCastledKS || bCastledQS) {
               evalWhitePOV -= 40;
            } else if (bKingOnE8 && (bCanCastleK || bCanCastleQ)) {
               
               // ✅ NOUVEAU : vérifier que le chemin est libre
               BOOL kingsideFree  = !board->pieceCase[5][7] &&
               !board->pieceCase[6][7]; // f8 et g8 libres
               BOOL queensideFree = !board->pieceCase[1][7] &&
               !board->pieceCase[2][7] &&
               !board->pieceCase[3][7]; // b8, c8, d8 libres
               
               //BOOL canActuallyCastle = (bCanCastleK && kingsideFree) ||
               //(bCanCastleQ && queensideFree);
               
               /* Vérifier que les Tours n'ont pas bougé */
               Piece *bRookK = board->pieceCase[7][7];  // h8
               Piece *bRookQ = board->pieceCase[0][7];  // a8
               BOOL bRookKIntact = (bRookK && bRookK.type == Tour &&
                                    bRookK.side == sideBlack && bRookK.numMoves == 0);
               BOOL bRookQIntact = (bRookQ && bRookQ.type == Tour &&
                                    bRookQ.side == sideBlack && bRookQ.numMoves == 0);
               BOOL canActuallyCastle = (bCanCastleK && kingsideFree && bRookKIntact) ||
                                        (bCanCastleQ && queensideFree && bRookQIntact);
               /* Fin de vérif déplacement des tours */
               
               if (canActuallyCastle) {
                  evalWhitePOV += 30;   // Roque réellement possible
               } else {
                  evalWhitePOV += 40;   // Malus pour Noirs = positif POV Blancs
               }
            } else {
               evalWhitePOV += 80;       // Droit perdu = malus Noirs = positif POV Blancs
            }
         }
      }
      // -------------------------------------------
      
      
      /* La mise à jour de l'interface est déplacée dans 'MakeIAMoveForSide' et sa variante 'Silent'
      pour limiter le nombre de mise à jour de l'interface pendant que l'IA décide de son coup    */
      
      // Assertion pour debug
      NSAssert(abs(evalWhitePOV) < SCORE_INF,
          @"⚠️ Score suspect : %d", evalWhitePOV);
      
      /* CONVERSION FINALE POUR NEGAMAX :
       - Si 'side' = Blancs : retourner evalWhitePOV tel quel (positif = bon pour Blancs)
       - Si 'side' = Noirs  : retourner -evalWhitePOV (négatif devient positif)
      Ainsi Negamax reçoit toujours une évaluation positive = bon pour le camp qui joue */
      return (side == sideWhite) ? evalWhitePOV : -evalWhitePOV;
      /* Pour l'évaluation du board par contre, sachant que la convention -qui veut qu'une éval
      positive indique un avantage aux Blancs et une éval négative l'inverse- se suffit à elle
      même et n'a pas à être inversée pour sa version affichée en barre d'état.              */
      
   } // !EvalBoardForSide


   // ================================================================================================
   // MÉTHODE PossibleMovesForSide - GÉNÉRATION DES COUPS LÉGAUX
   -(NSSet *)PossibleMovesForSide:(Side)side board:(ChessBoard *)board
   {
       NSMutableArray *allMoves = [NSMutableArray array];
       [self GenMovesForSide:side board:board into:allMoves];
       
       //NSLog(@"🔍 PossibleMovesForSide pour %@:", (side == sideWhite) ? @"Blancs" : @"Noirs");
       //NSLog(@"   Coups générés (avant filtre): %lu", (unsigned long)allMoves.count);
       
       NSMutableSet *legalMoves = [NSMutableSet set];
       
       for (Move *m in allMoves) {
           // ✅ LOG pour chaque coup testé
           //NSLog(@"   Test coup: %@", m);
           
           // ✅ Copier le board
           ChessBoard *testBoard = board.copy;
           
          /*
          // ✅ Vérifier que la copie contient bien les pièces
           Piece *movingPiece = testBoard->pieceCase[m.fromSquare % 8][m.fromSquare / 8];
           if (!movingPiece) {
               NSLog(@"     ❌ Pas de pièce en (%d,%d) dans testBoard !",
                     m.fromSquare % 8, m.fromSquare / 8);
               continue;
           }
           */
           
           MoveState st = [testBoard makeMove:m];
           
           if (![self IsKingInCheck:side board:testBoard]) {
               //NSLog(@"     ✅ Coup LÉGAL");
               [legalMoves addObject:m];
           }
           //else NSLog(@"     ❌ Coup illégal (roi en échec)");
           
           // Pas besoin d'unmake (testBoard sera libéré)
       }
       
       //NSLog(@"   → Coups légaux trouvés: %lu", (unsigned long)legalMoves.count);
       
       return legalMoves;
   }


   // ================================================================================================
   // MÉTHODE TestEchecFavSide - DÉTECTION ÉCHEC EN FAVEUR DE SIDE
   -(NSString *)TestEchecFavSide:(Side)side Board:(ChessBoard *)board
   {
       Side enemySide = (side == sideWhite) ? sideBlack : sideWhite;
       checkCount = 0;
       
      // Si le roi ennemi n'est pas en échec on sort en retournant une chaine vide
       if (![self IsKingInCheck:enemySide board:board]) {
           return @"";
       }
       
       // Sinon trouver le roi...
       Pos *kingPos = nil;
       for (int x = 0; x < 8; x++) {
           for (int y = 0; y < 8; y++) {
               Piece *p = board->pieceCase[x][y];
               if (p && p.type == Roi && p.side == enemySide) {
                   kingPos = [Pos posWithX:x y:y];
                   break;
               }
           }
           if (kingPos) break;
       }
       
       // ... et compter les attaquants distincts
       if (kingPos) {
           for (int x = 0; x < 8; x++) {
               for (int y = 0; y < 8; y++) {
                   Piece *piece = board->pieceCase[x][y];
                   if (piece && piece.side == side) {
                       // Appel du helper 'doesPieceAtX'
                       if ([self doesPieceAtX:x Y:y
                                attackSquareX:kingPos.x
                                            Y:kingPos.y
                                        board:board]) {
                           checkCount++;
                           
                           if (checkCount >= 2) break;  // Pas besoin de chercher plus
                       }
                   }
               }
               if (checkCount >= 2) break;
           }
       }
       
       NSLog(@"🔍 Échec détecté, checkCount=%d", checkCount);
       return @"Echec";
   } // !TestEchecFavSide

   
   // ================================================================================================
   // MÉTHODE TestEchecRoiSide - VERSION RAPIDE DE LA DÉTECTION D'ÉCHEC
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
   // Méthode SEE Static Exchange Evaluation
   - (int)SEEForMove:(Move *)move board:(ChessBoard *)board
   {
       // Gain immédiat de la capture
       int gain = [self ValueOfPiece:move.capturedPiece.type];
       int attackerValue = [self ValueOfPiece:move.movingPiece.type];
       
       // Si on perd la pièce qui capture sans recapture possible → SEE = gain - attacker
       // On cherche uniquement la recapture la moins chère (1 niveau)
       ChessBoard *testBoard = board.copy;
       MoveState st = [testBoard makeMove:move];
       
       Side otherSide = (move.movingPiece.side == sideWhite) ? sideBlack : sideWhite;
       
       NSMutableArray<Move *> *recaptures = [NSMutableArray arrayWithCapacity:8];
       [self GenCapturForSide:otherSide board:testBoard into:recaptures];
       
       // Recapture la moins chère sur la case cible
       int minRecaptureValue = INT_MAX;
       for (Move *rm in recaptures) {
           if (rm.dest.x == move.dest.x && rm.dest.y == move.dest.y) {
               int v = [self ValueOfPiece:rm.movingPiece.type];
               if (v < minRecaptureValue) minRecaptureValue = v;
           }
       }
       
       [testBoard unmakeMove:move state:st];
       
       if (minRecaptureValue == INT_MAX) {
           // Pas de recapture → gain pur
           return gain;
       }
       
       // Recapture possible : gain - perte si recapture rentable pour l'adversaire
       return gain - MAX(0, attackerValue - minRecaptureValue);
      
   } // !SEEForMove



   // ================================================================================================
   // Méthode retournant la valeur d'une pièce
   -(int)ValueOfPiece:(PieceType)p
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
      
      // 2️⃣ Menace de Cavaliers
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
      
      // 3️⃣ Menace de Pions
      int pawnDir = (enemy == sideWhite) ? 1 : -1;
      for (int dx = -1; dx <= 1; dx += 2) {
         int px = kingX + dx;
         int py = kingY - pawnDir;
         if (px < 0 || px > 7 || py < 0 || py > 7) continue;
         
         Piece *p = board->pieceCase[px][py];
         if (p && p.side == enemy && p.type == Pion)
            return YES;
      }
      
      // 4️⃣ Menaces de Fous /Dames (diagonales)
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
      
      // 5️⃣ Menaces de Tours /Dames (lignes droites)
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
      
      // 6️⃣ Menace du Roi adverse (cases adjacentes)
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


   
   // ================================================================================================
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


   // ================================================================================================
   // Helper appelée par IsKingInCheck
   -(BOOL)doesPieceAtX:(int)px Y:(int)py
        attackSquareX:(int)tx Y:(int)ty
                board:(ChessBoard *)board
   {
       Piece *piece = board->pieceCase[px][py];
       if (!piece) return NO;
       
       int dx = tx - px;
       int dy = ty - py;
       int adx = abs(dx);
       int ady = abs(dy);
       
       switch (piece.type) {
           case Pion: {
               int dir = (piece.side == sideWhite) ? 1 : -1;
               // Pion attaque en diagonale
               return (dy == dir && adx == 1);
           }
           
           case Cava:
               return (adx == 2 && ady == 1) || (adx == 1 && ady == 2);
           
           case Fou:
               if (adx != ady) return NO;  // Pas diagonal
               // Vérifier qu'il n'y a pas d'obstacle
               return [self isPathClearFromX:px Y:py toX:tx Y:ty board:board];
           
           case Tour:
               if (dx != 0 && dy != 0) return NO;  // Pas droit
               return [self isPathClearFromX:px Y:py toX:tx Y:ty board:board];
           
           case Dame:
               // Diagonal OU droit
               if (adx == ady || dx == 0 || dy == 0) {
                   return [self isPathClearFromX:px Y:py toX:tx Y:ty board:board];
               }
               return NO;
           
           case Roi:
               return (adx <= 1 && ady <= 1);
           
           default:
               return NO;
       }
   }

   
   // ================================================================================================
   // Helper pour vérifier le chemin, appelée par 'doesPieceAtX', elle-même appelée par 'IsKingInCheck'
   -(BOOL)isPathClearFromX:(int)fx Y:(int)fy toX:(int)tx Y:(int)ty board:(ChessBoard *)board
   {
       int dx = (tx > fx) ? 1 : (tx < fx) ? -1 : 0;
       int dy = (ty > fy) ? 1 : (ty < fy) ? -1 : 0;
       
       int x = fx + dx;
       int y = fy + dy;
       
       while (x != tx || y != ty) {
           if (board->pieceCase[x][y]) return NO;  // Obstacle
           x += dx;
           y += dy;
       }
       
       return YES;
   }


   // ================================================================================================
   // MÉTHODE D'ÉVALUATION D'UN BONUS DE MOBILITÉ, PRIS EN COMPTE DANS 'EVALBOARDFORSIDE'
   -(int)EvaluateMobility:(ChessBoard *)board
   {
      int whiteMobility = [self CountPseudoLegalMovesForSide:sideWhite board:board];
      int blackMobility = [self CountPseudoLegalMovesForSide:sideBlack board:board];

      /* Coefficient : ajuster sa valeur après tests en situation :
       - 2 peut être considéré commen subtil (priorité au matériel et aux positions),
       - 5 comme modéré (valeur conseillée pour débuter),
       - 10 comme agressif (favorise les positions ouvertes) */
      int mobilityBonus = (whiteMobility - blackMobility) * 2;

      // ✅ LOG temporaire pour observer
      //NSLog(@"📊 Mobilité: W=%d, B=%d, bonus=%+d", whiteMobility, blackMobility, mobilityBonus);

      return mobilityBonus;
   }

   // ================================================================================================
   // MÉTHODE UTILISÉE DANS L'ÉVALUATION DE LA MOBILITÉ
   // COMPTAGE RAPIDE DES COUPS PSEUDO-LÉGAUX (sans vérifier l'échec au roi)
   -(int)CountPseudoLegalMovesForSide:(Side)side board:(ChessBoard *)board
   {
      NSMutableArray *moves = [NSMutableArray array];
      [self GenMovesForSide:side board:board into:moves];
      return (int)moves.count;
   }



   // ================================================================================================
   // OPENING BOOK ÉTENDU — buildOpeningBook
   // Couverture : 1.e4, 1.d4, 1.c4, 1.Cf3 + réponses Noirs + développement jusqu'au coup 8
   // Format : FEN partiel (pièces + trait) → tableau de coups candidats
   - (void)buildOpeningBook {
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
   }


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
   - (NSString *)fenSymbolForPiece:(Piece *)p
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


   // ================================================================================================
   // Helper pour Pions passés en Partie 2
   -(int)pawnsInColumn:(int)col side:(Side)side board:(ChessBoard *)board {
       int count = 0;
       for (int y = 0; y < 8; y++) {
           Piece *p = board->pieceCase[col][y];
           if (p && p.type == Pion && p.side == side) count++;
       }
       return count;
   }


   
@end


#ifdef DEBUG_ZOBRIST
   // FONCTION recalculant la clé Zobrist
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
