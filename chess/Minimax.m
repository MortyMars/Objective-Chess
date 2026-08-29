// Minimax.m
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved.
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026


#import "Minimax.h"
#import "Minimax+GenMoves.h"
#import "ChessBoard+MakeMoves.h"
#import "ChessConfig.h"
#import "PeSTO.h"
#import "Minimax+OpeningBook.h"


// Définition ci-dessous de la valeur de base du mat reportée dans Util.h pour accès à Minimax + les TT
// #define MATE_SCORE    100000

#define SCORE_INF 200000         // définit à 200000 le plus bas des scores
                                 // SCORE_INF > MATE_SCORE, et SCORE_INF < INT_MAX/2

/* Définition et qualibrage de la fenêtre d'aspiration
- 50 est la valeur standard
- à porter à 75 si le log révèle trop de fail-low/high
- à réduire à 30 s'il n'en révèle  pas assez
- 150 /200 revient à annuler l'effet d'aspiration   */
#define ASPIRATION_WINDOW 50
#define ASPIRATION_MIN_DEPTH 4   // N'activer qu'à partir de depth 4


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
         gameHistoryCount = 0;
         memset(gameHistory, 0, sizeof(gameHistory));
      }
      return self;
   }


   // ================================================================================================
   // MÉTHODE BestMoveForSide - Point d'entrée du moteur IA
   // Cette méthode trouve le meilleur coup pour l'IA en explorant l'arbre des possibilités
   -(Move *)BestMoveForSide:(Side)side Board:(ChessBoard *)board
   {
      // --- Initialisation des iVars et variables -----------------
      nbLoop = 0;
      nbElag = 0;
      //nodeCount = 0; // iVar caduque
      nodes = 0;
      evalCount = 0;
      moveGenCount = 0;
      copyBoardCount = 0;
      evalTotalTime = 0;
      moveGenTotalTime = 0;
      memset(historyTable, 0, sizeof(historyTable));
      //isInNullMove = NO;
      
      /* REPRISE DU PROJET - Ne plus remettre positionHistory à zéro "à blanc"
      Le présent bloc est remplacé par le nouveau bloc immédiatement ci-après
      historyCount = 0;
      memset(positionHistory, 0, sizeof(positionHistory)); ---------------- */
      /* Initialiser positionHistory avec les positions réelles SAUF la dernière
      (qui sera ajoutée par searchRootMoves avant chaque coup testé) */
      int copyCount = MAX(0, gameHistoryCount - 1);
      historyCount = copyCount;
      memcpy(positionHistory, gameHistory, copyCount * sizeof(uint64_t));
      
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
         
         // ── Aspiration Windows ───────────────────────────────────
         int alpha, beta;
         /* L'aspiration Windows s'étant révélée difficile à calibrer
         et ainsi inefficace au point de gréver les perfs du moteur,
         elle est provisoiremnt désactivée,
         if (depth >= ASPIRATION_MIN_DEPTH &&
            abs(_idBestScore) < MATE_SCORE - NUMBER_MOVES_AHEAD) {
               alpha = _idBestScore - ASPIRATION_WINDOW;
               beta  = _idBestScore + ASPIRATION_WINDOW;
         } else {
               alpha = -SCORE_INF;
               beta  =  SCORE_INF;
         }
         alpha et beta retrouvent leurs valeurs par défaut ------- */
         alpha = -SCORE_INF;
         beta  =  SCORE_INF;
         
         Move *iterBestMove  = nil;
         int   iterBestScore = -SCORE_INF - 1;
         
         memset(_killerMoves, 0, sizeof(_killerMoves));
         
         // Tri des coups
         NSMutableArray *moves = [NSMutableArray arrayWithArray:
                                  [movesPossibles allObjects]];
         [self ScoreMovesList:moves board:board side:side depth:depth];
         
         // Promouvoir le meilleur coup de l'itération précédente
         if (_idBestMove) {
            for (Move *m in moves) {
               if (m.fromSquare == _idBestMove.fromSquare &&
                   m.toSquare   == _idBestMove.toSquare) {
                  m.orderingScore += 2000000;
                  break;
               }
            }
         }
         
         [moves sortUsingComparator:^NSComparisonResult(Move *a, Move *b) {
            return (b.orderingScore - a.orderingScore);
         }];
         
         // --- Recherche initiale avec fenêtre étroite ---
         iterBestScore = [self searchRootMoves:moves
                                         board:board
                                          side:side
                                         depth:depth
                                         alpha:alpha
                                          beta:beta
                                   outBestMove:&iterBestMove];
         
         /* BLOC D'ASPIRATION WINDOW À CONSERVER COMMENTÉ
         // --- Fail-low : score STRICTEMENT en dessous de la fenêtre ---
         if (iterBestScore < alpha &&
             depth >= ASPIRATION_MIN_DEPTH &&
             abs(iterBestScore) < MATE_SCORE - NUMBER_MOVES_AHEAD) {
            
            NSLog(@"↙️ Fail-low depth=%d score=%d alpha=%d", depth, iterBestScore, alpha);
            iterBestScore = [self searchRootMoves:moves
                                            board:board
                                             side:side
                                            depth:depth
                                            alpha:-SCORE_INF
                                             beta:beta
                                      outBestMove:&iterBestMove];
         }
         // --- Fail-high : score STRICTEMENT au dessus de la fenêtre ---
         else if (iterBestScore > beta &&
                  depth >= ASPIRATION_MIN_DEPTH &&
                  abs(iterBestScore) < MATE_SCORE - NUMBER_MOVES_AHEAD) {
            
            NSLog(@"↗️ Fail-high depth=%d score=%d beta=%d", depth, iterBestScore, beta);
            iterBestScore = [self searchRootMoves:moves
                                            board:board
                                             side:side
                                            depth:depth
                                            alpha:alpha
                                             beta:SCORE_INF
                                      outBestMove:&iterBestMove];
         } FIN DE BLOC CONSERVÉ COMMENTÉ  */
         
         // --- Valider l'itération ---
         if (iterBestMove) {
            _idBestMove  = iterBestMove;
            _idBestScore = iterBestScore;
         }
         
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
      
      /* // Enregistrer la position APRÈS le coup IA dans l'historique réel
      if (gameHistoryCount < MAX_GAME_LENGTH) {
          gameHistory[gameHistoryCount++] = board->zobristKey;
      } */
      
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
                    ply:(int)ply 
   {
      nodes++;
      
      #ifdef DEBUG_ZOBRIST
         uint64_t keyEntry = board->zobristKey;
      #endif
      
      // ✅ Détection de répétition AVANT probe TT
      if ([self isRepetition:board->zobristKey]) {
         
         /* REPRISE PROJET : Bloc commenté
         // Score de répétition contextualisé :
         // - En position gagnante : malus pour décourager la répétition
         // - En position perdante : bonus pour encourager la répétition (sauvetage)
         
         // Contempt proportionnel à la phase ET au déséquilibre matériel
         int baseContempt = self.lastPhase / 4;  // 0-64 selon phase
         // En finale (phase faible), augmenter le contempt pour forcer la recherche
         int phaseBonus = (self.lastPhase < 80) ? 30 : 0;
         
         
         int contempt = (side == sideWhite) ?  (baseContempt + phaseBonus)
                                            : -(baseContempt + phaseBonus);
         // contempt ∈ [-64, +64] selon la phase
         // En ouverture (phase=256) : contempt = ±64 → forte dissuasion
         // En finale   (phase=0)   : contempt = 0  → répétition neutre
         return -contempt; */
         
         // REPRISE PROJET
         // ✅ Utiliser simplement une valeur fixe
         return 0; // Répétition = position nulle, score neutre
         
      }
      
      // ----------------------------------------------------------------------
      // 🔍 PROBE TT : Consulter la table de transposition
      Move *ttMove = nil;
      TTEntry *ttEntry = [self.transpositionTable probe:board->zobristKey
                                               bestMove:&ttMove];
      
      BOOL inCheck = [self IsKingInCheck:side board:board];
      
      if (ttEntry) {
          if (ttEntry->depth >= depth) {
              int ttScore = scoreFromTT(ttEntry->score, ply);
              
              switch (ttEntry->nodeType) {
                  case TT_EXACT:
                      return ttScore;
                  case TT_LOWER_BOUND:
                      if (ttScore >= beta) return ttScore;
                      if (ttScore > alpha) alpha = ttScore;
                      break;
                  case TT_UPPER_BOUND:
                      if (ttScore <= alpha) return ttScore;
                      if (ttScore < beta) beta = ttScore;
                      break;
              }
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
      
      // Déclaration /Définition de 'inCheck' avancé en 'ProbeTT'
      // BOOL inCheck = [self IsKingInCheck:side board:board];

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
                                   inNullMove:YES
                                          ply:ply +1];
        
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
            // return beta;         // Fail-soft erroné
            return nullScore;       // Vrai Fail-soft
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
                                  score:scoreToTT(score, ply)
                                  depth:depth
                               nodeType:TT_EXACT
                               bestMove:nil];
         return score;
      }
      
      // ----------------------------------------------------------------------
      // Recherche principale
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      Move *bestMove = nil;  // ✨ Tracker le meilleur coup pour TT
      
      // Déclaration du compteur LMR
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
                                  inNullMove:NO
                                         ply:ply+1];
            
            
               // ── Re-recherche pleine profondeur si prometteur ─
               // ✅ Correction : PVS-style re-search
               if (score > alpha && score < beta) {
                  score = -[self NegamaxForSide:otherSide
                                          board:board
                                          depth:depth-1
                                          alpha:-beta
                                           beta:-alpha
                                     inNullMove:NO
                                            ply:ply+1];
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
                                  inNullMove:NO
                                         ply:ply+1];
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
               // ✅ AJOUT : History Heuristic
               historyTable[sideIdx][m.fromSquare % 8][m.fromSquare / 8]
                           [m.toSquare % 8][m.toSquare / 8] += depth * depth;
               // depth² : les cutoffs à grande profondeur valent plus
               
            }
            break;
         }
         
      } // Sortie de boucle for de Recherche Principale
      
      #ifdef DEBUG_ZOBRIST
         NSAssert(board->zobristKey == keyEntry,
                  @"Zobrist corrompu : sortie Negamax normale");
      #endif
      
      /* Bloc suspecté de bug, commenté
      // ── FILTRE PIÈCE SUSPENDUE POST-COUP ─────────────────────────
      // Si le meilleur coup laisse une pièce majeure en prise,
      // pénaliser le score pour décourager ce coup à la racine.
      if (bestMove && depth >= 2 && !inCheck) {
          static const int majorVal[7] = { 0, 0, 337, 365, 477, 1025, 0 };
          //  Ne surveiller que N, B, R, Q (pas pions ni roi)
          MoveState st = [board makeMove:bestMove];
          for (int x = 0; x < 8; x++) {
              for (int y = 0; y < 8; y++) {
                  Piece *p = board->pieceCase[x][y];
                  if (!p || majorVal[p.type] == 0) continue;
                  if (p.side != side) continue;  // nos pièces seulement
                  int sq = y * 8 + x;
                  Side enemy = (side == sideWhite) ? sideBlack : sideWhite;
                  BOOL attacked = [self IsSquareAttackedAtX:x Y:y
                                                     bySide:enemy Board:board];
                  BOOL defended = [self IsSquareDefended:sq bySide:side board:board];
                  if (attacked && !defended) {
                      alpha -= majorVal[p.type] / 2;
                  }
              }
          }
          [board unmakeMove:bestMove state:st];
         
      } Fin de bloc commenté */

      
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
                               score:scoreToTT(alpha, ply)
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
            
            [board unmakeMove:m state:st];      // ← toujours ici, légal ou non
            
            if (score >= beta)  return score;   // fail-soft
            
            if (score > alpha)  alpha = score;
            
         } else {
            [board unmakeMove:m state:st];      // si en échec on annule le coup
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
   // MÉTHODE EvalBoardForSide évaluant la qualité d'une situation de board pour un camp donné
   // CRITÈRES D'ÉVALUATION :
   // - Matériel : Valeur brute des pièces (base)
   // - Position : Bonus positionnel (via tables PeSTO)
   // - Sécurité : Le roi est-il en sécurité ?
   // - Structure : Les pions sont-ils bien organisés ?
   // - Mobilité : Combien de coups possibles ?
   // - Développement : Les pièces sont-elles actives ?
   -(int)EvalBoardForSide:(Side)side
                    board:(ChessBoard *)board
   {
      evalWhitePOV = 0;  /* Évaluation du point de vue des Blancs (convention Negamax) */
      
      /* --------------------------------------------------
      PARTIE 1 : MATÉRIEL + PeSTO + INTERPOL DE PHASE    */
      evalWhitePOV = 0;
      // Accumulateurs mg/eg séparés pour chaque camp
      int mgWhite = 0, egWhite = 0;
      int mgBlack = 0, egBlack = 0;
      // Compteurs pour le calcul de phase
      int knights = 0, bishops = 0, rooks = 0, queens = 0;
      // Variables de développement (conservées pour Partie 3)
      int developmentWhite = 0, developmentBlack = 0;
      // ── Passe unique sur le board
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
      // ── Interpolation de phase
      int phase = PeSTO_GamePhase(knights, bishops, rooks, queens);
      self.lastPhase = phase;  // ← exposer pour le log provisoire
      // Score interpolé du point de vue des Blancs
      int scoreWhite = PeSTO_Interpolate(mgWhite, egWhite, phase);
      int scoreBlack = PeSTO_Interpolate(mgBlack, egBlack, phase);
      evalWhitePOV   = scoreWhite - scoreBlack;
      // Exposer la phase pour les Parties suivantes
      // (remplace le booléen isEndGame utilisé dans Parties 5 et 7)
      BOOL isEndGame = (phase < 128);  // 128 correspond à 50% du matériel restant
      
      // NSLog de contrôle (ATTENTION VERBEUX)
      /* NSLog(@"📊 Phase=%d isEndGame=%d (knights=%d bishops=%d rooks=%d queens=%d)",
            phase, isEndGame, knights, bishops, rooks, queens); */
      
      /* --------------------------------------------------
      PARTIE 2 : ÉVAL. DE LA STRUCTURE DE PIONS
      Détection pions doublés (malus) et passés (bonus)  */
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
      
      /* --------------------------------------------------
      PARTIE 3 : BONUS DÉVELOPPEMENT
      Les pièces (cavaliers/fous) sorties de leur position
      de départ reçoivent un bonus. Ceci a déjà été calculé
      dans la boucle principale ci-dessus                */
      int developmentDiff = developmentWhite - developmentBlack;
      evalWhitePOV += developmentDiff;  // Toujours du point de vue des Blancs
      
      /* --------------------------------------------------
      PARTIE 4 : BONUS MOBILITÉ
      Comptage des coups pseudo-légaux disponibles pour
      chaque camp, plus on a d'options mieux c'est !     */
      int mobilityBonus = [self EvaluateMobility:board];
      evalWhitePOV += mobilityBonus;
      
      /* --------------------------------------------------
       PARTIE 5 : SÉCURITÉ DU ROI
       Détecter si le Roi est dangereusement exposé       */
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
                  
                  /* Déjà géré par kingEndGameTable PeSTO, mais ajouter un bonus explicite
                  pour fuir vers le centre si on est en position perdante               */
                  if (evalWhitePOV > 100 && piece.side == sideBlack) {
                     // Roi Noir perdant : bonus si proche du centre
                     int centerBonus = (4 - abs(x - 3)) + (4 - abs(y - 3));
                     evalWhitePOV += centerBonus * 3; // positif = bon pour Blancs = mauvais pour Noirs
                     // Ce malus pousse le Roi Noir vers le centre plutôt que dans les coins
                  }
                  if (evalWhitePOV < -100 && piece.side == sideWhite) {
                     // Roi Blanc perdant : symétrique
                     int centerBonus = (4 - abs(x - 3)) + (4 - abs(y - 3));
                     evalWhitePOV -= centerBonus * 3;
                  }
                  
               } /* Fin de Roi actif en finale */
               
            }
         }
      }
      
      /* --------------------------------------------------
      PARTIE 6 : PIONS EN AVANT-DERNIÈRE RANGÉE          */
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
      
      /* --------------------------------------------------
      PARTIE 7 : BONUS ROQUE (MiddleGame only)           */
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
      
      /* --------------------------------------------------
      PARTIE 8 : PIÈCES SUSPENDUES
      Évaluation symétrique des deux camps : chaque pièce
      non défendue (ou défendue par une pièce plus chère)
      génère un malus pour son camp, exprimé en POV Blancs.
      Indépendant de 'side' → score stable à tout ply.
      Actif en milieu de partie ET en finale.            */

      static const int hangVal[7] = { 0, 82, 337, 365, 477, 1025, 0 };
      //  Rappel  ---->                  P    N    B    R    Q    K

      for (int evalSide = 0; evalSide <= 1; evalSide++) {

        Side pieceSide   = (evalSide == 0) ? sideWhite : sideBlack;
        Side attackSide  = (evalSide == 0) ? sideBlack : sideWhite;
        int  sign        = (evalSide == 0) ? -1 : +1;
        // sign=-1 : pièce Blanche suspendue = malus POV Blancs
        // sign=+1 : pièce Noire  suspendue = bonus POV Blancs

        for (int x = 0; x < 8; x++) {
            for (int y = 0; y < 8; y++) {

                Piece *p = board->pieceCase[x][y];
                if (!p || p.type == Invalide ||
                    p.type == Pion || p.type == Roi) continue;
                if (p.side != pieceSide) continue;

                int val    = hangVal[p.type];

                // Valeur minimale de l'attaquant adverse
                int minAtk = [self minAttackerValue:x y:y
                                             bySide:attackSide board:board];
                if (minAtk == 0) continue;  // pièce non attaquée

                // La pièce est-elle défendue par un ami ?
                BOOL defended = [self IsSquareAttackedAtX:x Y:y
                                                   bySide:pieceSide Board:board];
                int penalty = 0;

                if (!defended) {
                    if (minAtk < val) {
                        // Attaquant moins cher → vrai gain pour l'adversaire
                        penalty = -((val - minAtk) / 2);
                    } else if (minAtk == val) {
                        // Échange égal → léger désavantage
                        penalty = -(val / 8);
                    }
                    // minAtk > val : l'attaque est défavorable → pas de malus
                } else {
                    if (minAtk < val) {
                        // Défendue mais attaquant moins cher → échange potentiellement favorable à l'adversaire
                        penalty = -((val - minAtk) / 4);
                    }
                }

                // Appliquer le malus en POV Blancs
                if (penalty != 0) evalWhitePOV += sign * penalty;
            }
        }
      }
      // ---------------------------------------------
      
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
      
      NSMutableSet *legalMoves = [NSMutableSet set];
      
      for (Move *m in allMoves) {
         // ✅ LOG pour chaque coup testé
         //NSLog(@"   Test coup: %@", m);
         
         // ✅ Copier le board
         ChessBoard *testBoard = board.copy;
         
         /* RÉALISATION EFFECTIVE DU MOVE  ----  Il ne s'agit pas ici d'un "move de test" défait plus tard
         par un 'unmakeMove'. On utilise donc un Cast forcé vers un 'void', car un 'MoveState' retourné ne
         serait pas utilisé par un unmakeMove à suivre, ce qui créerait une alerte du compilateur.      */
         //MoveState st = [testBoard makeMove:m];
         (void)[testBoard makeMove:m];
         
         if (![self IsKingInCheck:side board:testBoard]) {
            //NSLog(@"     ✅ Coup LÉGAL");
            [legalMoves addObject:m];
         }
      }
      //NSLog(@"   → Coups légaux trouvés: %lu", (unsigned long)legalMoves.count);
      return legalMoves;
      
   } // !PossibleMovesForSide


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
   // isRepetition détecte si une position a déjà été vue (répétition = nulle)
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
   // Helper pour Pions passés en Partie 2
   -(int)pawnsInColumn:(int)col side:(Side)side board:(ChessBoard *)board {
       int count = 0;
       for (int y = 0; y < 8; y++) {
           Piece *p = board->pieceCase[col][y];
           if (p && p.type == Pion && p.side == side) count++;
       }
       return count;
   }


   // ================================================================================================
   // Méthode isSeenBefore - Retourne YES si la position a déjà été vue au moins une fois
   // (utilisé pour invalider le score TT, plus strict que isRepetition)
   -(BOOL)isSeenBefore:(uint64_t)zobristKey {
       for (int i = 0; i < historyCount; i++) {
           if (positionHistory[i] == zobristKey) return YES;
       }
       return NO;
   }


   // ================================================================================================
   // Retourne la valeur PeSTO de la pièce adverse la moins chère
   // pouvant capturer la case (x,y). Retourne 0 si aucun attaquant.
   -(int)minAttackerValue:(int)x y:(int)y bySide:(Side)side board:(ChessBoard *)board
   {
       static const int val[7] = { 0, 82, 337, 365, 477, 1025, 20000 };
       int minVal = 0;

       // ── Pions ────────────────────────────────────────────────────
       int pawnDir = (side == sideWhite) ? -1 : 1;
       for (int dx = -1; dx <= 1; dx += 2) {
           int px = x + dx;
           int py = y + pawnDir;
           if (px < 0 || px > 7 || py < 0 || py > 7) continue;
           Piece *p = board->pieceCase[px][py];
           if (p && p.side == side && p.type == Pion) {
               if (minVal == 0 || val[Pion] < minVal) minVal = val[Pion];
           }
       }

       // ── Cavaliers ────────────────────────────────────────────────
       static const int kn[8][2] = {{1,2},{2,1},{-1,2},{-2,1},
                                     {1,-2},{2,-1},{-1,-2},{-2,-1}};
       for (int i = 0; i < 8; i++) {
           int nx = x + kn[i][0], ny = y + kn[i][1];
           if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;
           Piece *p = board->pieceCase[nx][ny];
           if (p && p.side == side && p.type == Cava) {
               if (minVal == 0 || val[Cava] < minVal) minVal = val[Cava];
           }
       }

       // ── Fous + Dame (diagonales) ─────────────────────────────────
       static const int bDirs[4][2] = {{1,1},{1,-1},{-1,1},{-1,-1}};
       for (int d = 0; d < 4; d++) {
           int nx = x + bDirs[d][0], ny = y + bDirs[d][1];
           while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
               Piece *p = board->pieceCase[nx][ny];
               if (p) {
                   if (p.side == side &&
                       (p.type == Fou || p.type == Dame)) {
                       int v = val[p.type];
                       if (minVal == 0 || v < minVal) minVal = v;
                   }
                   break;
               }
               nx += bDirs[d][0]; ny += bDirs[d][1];
           }
       }

       // ── Tours + Dame (lignes) ────────────────────────────────────
       static const int rDirs[4][2] = {{1,0},{-1,0},{0,1},{0,-1}};
       for (int d = 0; d < 4; d++) {
           int nx = x + rDirs[d][0], ny = y + rDirs[d][1];
           while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
               Piece *p = board->pieceCase[nx][ny];
               if (p) {
                   if (p.side == side &&
                       (p.type == Tour || p.type == Dame)) {
                       int v = val[p.type];
                       if (minVal == 0 || v < minVal) minVal = v;
                   }
                   break;
               }
               nx += rDirs[d][0]; ny += rDirs[d][1];
           }
       }

       // ── Roi ──────────────────────────────────────────────────────
       for (int dx = -1; dx <= 1; dx++) {
           for (int dy = -1; dy <= 1; dy++) {
               if (dx == 0 && dy == 0) continue;
               int nx = x + dx, ny = y + dy;
               if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;
               Piece *p = board->pieceCase[nx][ny];
               if (p && p.side == side && p.type == Roi) {
                   if (minVal == 0 || val[Roi] < minVal) minVal = val[Roi];
               }
           }
       }

       return minVal;
   } // !minAttackerValue


   // ================================================================================================
   // Méthode privée searchRootMoves
   // Boucle racine factorisée pour l'Aspiration Windows, utilisée dans BMFS
   -(int)searchRootMoves:(NSMutableArray *)moves
                   board:(ChessBoard *)board
                    side:(Side)side
                   depth:(int)depth
                   alpha:(int)alpha
                    beta:(int)beta
             outBestMove:(Move **)outBestMove
   {
      int iterBestScore = -SCORE_INF - 1;
      *outBestMove = nil;
      
      for (Move *move in moves) {
         
         /* REPRISE DU CODE - Suppression du skip de répétition immédiate
         // Skip répétition immédiate
         if (self.lastIAMove &&
             move.fromSquare == self.lastIAMove.toSquare &&
             move.toSquare   == self.lastIAMove.fromSquare) {
            continue;
         } ----------------------------------------------------------- */
         
         positionHistory[historyCount++] = board->zobristKey;
         MoveState st = [board makeMove:move];
         
         // ✅ AJOUTER : vérifier si le coup adverse produit un Pat
         Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
         NSMutableArray *opponentMoves = [NSMutableArray array];
         [self GenMovesForSide:otherSide board:board into:opponentMoves];
         BOOL isOpponentStalemate = (opponentMoves.count == 0 &&
                                     ![self IsKingInCheck:otherSide board:board]);
         if (isOpponentStalemate) {
             [board unmakeMove:move state:st];
             historyCount--;
             continue;  // Ignorer ce coup — il produit un Pat
         }
         
         int score = -[self NegamaxForSide:(side == sideWhite ? sideBlack : sideWhite)
                                     board:board
                                     depth:depth - 1
                                     alpha:-beta
                                      beta:-alpha
                                inNullMove:NO
                                       ply:0];
         
         [board unmakeMove:move state:st];
         historyCount--;
         
         if (score > iterBestScore) {
            iterBestScore = score;
            *outBestMove  = move;
         }
         if (score > alpha) alpha = score;
         if (alpha >= beta) break;
      }
      
      if (iterBestScore < 0)
         NSLog(@"💣 Attention 'iterBestScore' porte une valeur négative : %d",iterBestScore);
      
      return iterBestScore;
      
   } // !searchRootMoves


   // ================================================================================================
   // Méthode enregistrant le coup Joueur dans l'historique de partie, sachant que
   // le coup Joueur est réalisé dans l'UI (clics à la souris) et non dans BMFS
   -(void)recordMoveInGameHistory:(uint64_t)zobristKey {
       if (gameHistoryCount < MAX_GAME_LENGTH) {
           gameHistory[gameHistoryCount++] = zobristKey;
       }
   }


   // RAZ de l'historique de game
   -(void)resetGameHistory {
       gameHistoryCount = 0;
       memset(gameHistory, 0, sizeof(gameHistory));
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


// ── Helpers à ajouter (par exemple en tête de Minimax.m) ──────────

static inline int scoreToTT(int score, int ply) {
    if (score >  MATE_SCORE - 200) return score + ply;  // mat pour nous
    if (score < -MATE_SCORE + 200) return score - ply;  // mat pour eux
    return score;
}

static inline int scoreFromTT(int score, int ply) {
    if (score >  MATE_SCORE - 200) return score - ply;
    if (score < -MATE_SCORE + 200) return score + ply;
    return score;
}
