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


#define SCORE_INF 10000000 // Définit à 10 000 000 le plus bas des scores (affecté d'un signe -)




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
      if (board->nbEntiers <= 10) {  // Limiter aux 10 premiers coups entiers (Joueur+IA)
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
         }
         
         NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
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
        return 0;  // Position répétée = nulle (draw)
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
      
      // ----------------------------------------------------------------------
      // Recherche principale
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      Move *bestMove = nil;  // ✨ Tracker le meilleur coup pour TT
      
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
            
            int score = -[self NegamaxForSide:otherSide
                                        board:board
                                        depth:depth-1
                                        alpha:-beta
                                         beta:-alpha
                                   inNullMove:NO];
            
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
      }
      
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
      int materialWhite = 0, materialBlack = 0;
      int developmentWhite = 0, developmentBlack = 0;
      int totalMaterial = 0;  /* Pour détecter la fin de partie */
      
      /* -------------------------------------------
      PARTIE 1 : ÉVAL. MATÉRIELLE + POSITIONNELLE
      Tables de valeurs positionnelles pour chaque type de pièce
      Ces tables donnent un bonus/malus selon la position de la pièce sur l'échiquier
      Convention : les tableaux sont vus du point de vue des Blancs (rangée 0 = fond Blancs)
      Mais ATTENTION la représentation des tables est inversée par rapport à un board !! */
      
      /* PIONS : Encourage l'avancée et le contrôle du centre - Table ASYMÉTRIQUE
      qui devra donc faire l'objet d'un miroir Vertical pour les Noirs ------- */
      static const int pawnTable[8][8] = {
         {  0,  0,  0,  0,  0,  0,  0,  0 }, // y=0 départ (jamais évalué)
         {  0,  0,  0,  0,  0,  0,  0,  0 }, // y=1 pas encore bougé
         {  1,  1,  1,  2,  2,  1,  1,  1 }, // y=2 développement minimal
         {  1,  1,  2,  4,  4,  2,  1,  1 }, // y=3 centre ✅
         {  2,  2,  3,  5,  5,  3,  2,  2 }, // y=4 centre avancé ✅✅
         {  3,  3,  4,  5,  5,  4,  3,  3 }, // y=5 très avancé
         {  5,  5,  5,  6,  6,  5,  5,  5 }, // y=6 avant-promotion ✅✅✅
         {  0,  0,  0,  0,  0,  0,  0,  0 }  // y=7 promotion (géré Partie 6)
      };
      
      /* CAVALIERS : Encourage position centrale et pénalise les bords
      Table SYMÉTRIQUE sans correction nécessaire ----------------- */
      static const int knightTable[8][8] = {
         {-15,-10, -6, -6, -6, -6,-10,-15 }, // y=0 ← très punitif : éviter le recul
         {-10, -6, -2,  0,  0, -2, -6,-10 }, // y=1 ← punitif
         { -4,  0,  3,  4,  4,  3,  0, -4 },
         { -4,  2,  4,  6,  6,  4,  2, -4 },
         { -4,  2,  4,  6,  6,  4,  2, -4 },
         { -4,  0,  3,  4,  4,  3,  0, -4 },
         {-10, -6, -2,  0,  0, -2, -6,-10 },
         {-15,-10, -6, -6, -6, -6,-10,-15 }
      };
      
      /* FOUS : Encourage diagonales longues et centre
      Table SYMÉTRIQUE sans correction nécessaire   */
      static const int bishopTable[8][8] = {
         { -4, -2, -2, -2, -2, -2, -2, -4 }, // y=0 fond Blancs
         { -2,  0,  0,  1,  1,  0,  0, -2 },
         { -2,  0,  2,  2,  2,  2,  0, -2 },
         { -2,  1,  2,  3,  3,  2,  1, -2 }, // y=3 centre
         { -2,  1,  2,  3,  3,  2,  1, -2 }, // y=4 centre
         { -2,  0,  2,  2,  2,  2,  0, -2 },
         { -2,  0,  0,  1,  1,  0,  0, -2 },
         { -4, -2, -2, -2, -2, -2, -2, -4 }  // y=7 fond Noirs
      };
      
      /* TOURS : Encourage 7ème rangée et colonnes ouvertes - Table ASYMÉTRIQUE
      qui devra donc faire l'objet d'un mirroir V pour les Noirs ----------- */
      static const int rookTable[8][8] = {
         { -3, -3, -3,  1,  0,  1, -3, -3 }, // y=0 : pénalise coins/b1/g1, encourage d1/f1
         {  0,  0,  1,  2,  2,  1,  0,  0 }, // y=1 légère préférence d/e
         {  0,  0,  1,  2,  2,  1,  0,  0 }, // y=2
         {  0,  0,  1,  2,  2,  1,  0,  0 }, // y=3
         {  0,  0,  1,  2,  2,  1,  0,  0 }, // y=4
         {  0,  0,  1,  2,  2,  1,  0,  0 }, // y=5
         {  3,  3,  4,  5,  5,  4,  3,  3 }, // y=6 7e rangée ✅✅
         {  0,  0,  0,  0,  0,  0,  0,  0 }  // y=7
      };
      
      /* DAME : Préférence pour le centre, éviter l'exposition précoce
      Table SYMÉTRIQUE sans correction nécessaire ----------------- */
      static const int queenTable[8][8] = {
         { -5, -3, -2, -1, -1, -2, -3, -5 }, // y=0 fond : éviter sortie précoce
         { -3,  0,  0,  0,  0,  0,  0, -3 }, // y=1
         { -2,  0,  2,  2,  2,  2,  0, -2 }, // y=2
         { -1,  0,  2,  3,  3,  2,  0, -1 }, // y=3 centre ✅
         { -1,  0,  2,  3,  3,  2,  0, -1 }, // y=4 centre ✅
         { -2,  0,  2,  2,  2,  2,  0, -2 }, // y=5
         { -3,  0,  0,  0,  0,  0,  0, -3 }, // y=6
         { -5, -3, -2, -1, -1, -2, -3, -5 }  // y=7 fond
      };
      
      /* ROI milieu de partie : Encourage le roque et la sécurisation du Roi sur les côtés.
      Table ASYMÉTRIQUE qui devra donc faire l'objet d'un miroir Vertical pour les Noirs.
      On note que la table Rois -par ses bonus importants pour le roque- primera sur la table
      Tours, dont les bonus en première ligne sont calculés opportunément post-roque.      */
      static const int kingMiddleGameTable[8][8] = {
         {  2, 10,  8,  0,  0, -2, 10,  2 }, // y=0 : g1/b1 après roque ✅✅, e1/d1 dangereux
         {  4,  6,  2,  0,  0,  2,  4,  2 }, // y=1 couverture pions ✅
         { -4, -6, -6, -8, -8, -6, -6, -4 }, // y=2
         { -6, -8, -8,-10,-10, -8, -8, -6 }, // y=3
         { -8,-10,-10,-12,-12,-10,-10, -8 }, // y=4
         {-10,-12,-12,-14,-14,-12,-12,-10 }, // y=5 très dangereux
         {-10,-12,-12,-14,-14,-12,-12,-10 }, // y=6
         {-12,-14,-14,-14,-14,-14,-14,-12 }  // y=7 fond Noirs = très dangereux pour Blancs
      };
      
      /* ROI fin de partie : Le roi devient actif au centre
      Table SYMÉTRIQUE sans correction nécessaire        */
      static const int kingEndGameTable[8][8] = {
         { -6, -4, -2, -2, -2, -2, -4, -6 }, // y=0
         { -4,  0,  2,  2,  2,  2,  0, -4 }, // y=1
         { -2,  2,  4,  6,  6,  4,  2, -2 }, // y=2
         { -2,  2,  6,  8,  8,  6,  2, -2 }, // y=3 centre ✅
         { -2,  2,  6,  8,  8,  6,  2, -2 }, // y=4 centre ✅
         { -2,  2,  4,  6,  6,  4,  2, -2 }, // y=5
         { -4,  0,  2,  2,  2,  2,  0, -4 }, // y=6
         { -6, -4, -2, -2, -2, -2, -4, -6 }  // y=7
      };
      
      /* Comptage du matériel total pour déterminer si on est en fin de partie
      ✅ Pré-calculer totalMaterial AVANT la boucle principale              */

      // Passe 1 : calcul du matériel total (sans le Roi)
      totalMaterial = 0;
      for (int x = 0; x < 8; x++) {
          for (int y = 0; y < 8; y++) {
              Piece *p = [board piece_colX:x rangY:y];
              if (!p || p.type == Roi || p.type == Invalide) continue;
              switch (p.type) {
                  case Pion:  totalMaterial += 100; break;
                  case Cava:  totalMaterial += 300; break;
                  case Fou:   totalMaterial += 310; break;
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
                  /* Table Pions asymétrique -> miroir V seul pour les Noirs */
                  if (piece.side == sideWhite) positionBonus = pawnTable[y][x];
                  else                         positionBonus = pawnTable[7-y][x];
                  break;
                  
               case Cava:
                  materialValue = 300;
                  positionBonus = knightTable[y][x]; // Table symétrique RAS Blancs/Noirs
                  
                  /* BONUS DÉVELOPPEMENT : Cavalier sorti de sa case de départ */
                  if (piece.side == sideWhite && y > 0) developmentWhite += 5;
                  if (piece.side == sideBlack && y < 7) developmentBlack += 5;
                  break;
                  
               case Fou:
                  materialValue = 310;
                  positionBonus = bishopTable[y][x]; // Table symétrique RAS Blancs/Noirs
                  
                  /* BONUS DÉVELOPPEMENT : Fou sorti de sa case de départ */
                  if (piece.side == sideWhite && y > 0) developmentWhite += 5;
                  if (piece.side == sideBlack && y < 7) developmentBlack += 5;
                  break;
                  
               case Tour:
                  materialValue = 500;
                  /* Table Tours asymétrique -> miroir V+H pour les Noirs */
                  if (piece.side == sideWhite) positionBonus = rookTable[y][x];
                  else                         positionBonus = rookTable[7-y][x];
                  
                  /* MALUS TOUR BOUGÉE AVANT ROQUE
                  Si la tour a bougé et que le roi n'a pas encore roquer
                  → pénalité proportionnelle à la phase de jeu            */
                  if (!isEndGame && piece.numMoves > 0) {
                     BOOL kingHasCastled = NO;
                     if (piece.side == sideWhite) {
                        /* Roi Blanc a roquer si wkx == 2 ou 6, wky == 0 */
                        Piece *wk = board->pieceCase[2][0];
                        if (!wk || wk.type != Roi || wk.side != sideWhite)
                           wk = board->pieceCase[6][0];
                        
                        kingHasCastled = (wk && wk.type == Roi &&
                                          wk.side == sideWhite && wk.numMoves > 0);
                     }
                     else {
                        Piece *bk = board->pieceCase[2][7];
                        
                        if (!bk || bk.type != Roi || bk.side != sideBlack)
                           bk = board->pieceCase[6][7];
                        
                        kingHasCastled = (bk && bk.type == Roi &&
                                          bk.side == sideBlack && bk.numMoves > 0);
                        
                     }
                     
                     if (!kingHasCastled) {
                        /* Malus croissant : -25 dès le 1er mouvement       */
                        int rookPenalty = -25;
                        if (piece.side == sideWhite) evalWhitePOV += rookPenalty;
                        else                         evalWhitePOV -= rookPenalty;
                     }
                  }
                  break;
                  
               case Dame:
                  materialValue = 900;
                  positionBonus = queenTable[y][x]; // Table symétrique RAS Blancs/Noirs
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
                     positionBonus = kingEndGameTable[y][x]; // Table symétrique RAS Blancs/Noirs
                  } else {
                     /* Table Rois 'MiddleGame' asymétrique -> miroir V+H pour les Noirs */
                     if (piece.side == sideWhite) positionBonus = kingMiddleGameTable[y][x];
                     else                         positionBonus = kingMiddleGameTable[7-y][x];
                  }
                  break;
            } // Fin de switch
            
            /* DÉSACTIVER Accumulation du matériel total (pour détecter fin de partie) */
            //if (piece.type != Roi) totalMaterial += materialValue;
            
            /* Ajout de la valeur + bonus positionnel selon la couleur */
            int pieceValue = materialValue + positionBonus;
            
            if (piece.side == sideWhite) {
               materialWhite += pieceValue;
               evalWhitePOV  += pieceValue;   // Blancs = positif
            } else {
               materialBlack += pieceValue;
               evalWhitePOV  -= pieceValue;   // Noirs = négatif
            }
         } // !for 'y'
      } // !for 'x' et fin de parcours de l'échiquier
      
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
                           pawnShield += 20;  // Bonus par pion protecteur
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
      
      /* -------------------------------------------
      PARTIE 6 : PIONS EN AVANT-DERNIÈRE RANGÉE   */
      for (int x = 0; x < 8; x++) {
          Piece *pionB = board->pieceCase[x][6];
          if (pionB && pionB.type == Pion && pionB.side == sideWhite) {
              evalWhitePOV += 900;
              //NSLog(@"🔵 Pion blanc promo x=%d, evalWhitePOV=%d", x, evalWhitePOV);
          }
          Piece *pionN = board->pieceCase[x][1];
          if (pionN && pionN.type == Pion && pionN.side == sideBlack) {
              evalWhitePOV -= 900;
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
               evalWhitePOV += 60;
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
                  evalWhitePOV += 20;   // Roque réellement possible
               } else {
                  evalWhitePOV -= 30;   // Droit formel mais chemin bloqué ❌
               }
            } else {
               evalWhitePOV -= 50;       // Droit perdu
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
               evalWhitePOV -= 60;
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
                  evalWhitePOV += 20;   // Roque réellement possible
               } else {
                  evalWhitePOV += 30;   // Malus pour Noirs = positif POV Blancs
               }
            } else {
               evalWhitePOV += 50;       // Droit perdu = malus Noirs = positif POV Blancs
            }
         }
      }
      // -------------------------------------------
      
      
      /* La mise à jour de l'interface est déplacée dans 'MakeIAMoveForSide' et sa variante 'Silent'
      pour limiter le nombre de mise à jour de l'interface pendant que l'IA décide de son coup    */
      
      // Assertion pour debug
      NSAssert(abs(evalWhitePOV) < 50000,
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
   // Méthode de construction de l'Opening Book
   - (void)buildOpeningBook {
       self.openingBook = @{
           // ── POSITION INITIALE ────────────────────────────────
           @"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w" :
               @[@"e2e4", @"d2d4", @"c2c4", @"g1f3"],
           // ── APRÈS 1.e4 ───────────────────────────────────────
           @"rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b" :
               @[@"e7e5", @"c7c5", @"e7e6", @"c7c6", @"d7d5"],
           // 1.e4 e5
           @"rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w" :
               @[@"g1f3", @"f2f4", @"b1c3"],
           @"rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b" :
               @[@"b8c6", @"g8f6", @"d7d6"],
           // 1.e4 e5 2.Cf3 Cc6 → Giuoco / Ruy Lopez
           @"r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w" :
               @[@"f1c4", @"f1b5", @"d2d4"],
           // Giuoco Piano : 3.Fc4 Fc5
           @"r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b" :
               @[@"f8c5", @"g8f6", @"f7f5"],
           @"r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w" :
               @[@"e1g1", @"d2d3", @"b2b4"],
           // Ruy Lopez : 3.Fb5 a6
           @"r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b" :
               @[@"a7a6", @"g8f6", @"f7f5"],
           @"r1bqkbnr/1ppp1ppp/p1n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w" :
               @[@"f1a4", @"f1c4", @"e1g1"],
           // Défense Sicilienne : 1...c5
           @"rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w" :
               @[@"g1f3", @"b1c3", @"c2c3"],
           @"rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b" :
               @[@"b8c6", @"d7d6", @"e7e6"],
           // Défense Française : 1...e6
           @"rnbqkbnr/pppp1ppp/4p3/8/4P3/8/PPPP1PPP/RNBQKBNR w" :
               @[@"d2d4", @"d2d3", @"g1f3"],
           @"rnbqkbnr/pppp1ppp/4p3/8/3PP3/8/PPP2PPP/RNBQKBNR b" :
               @[@"d7d5", @"c7c5", @"g8f6"],
           // ── APRÈS 1.d4 ───────────────────────────────────────
           @"rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b" :
               @[@"d7d5", @"g8f6", @"e7e6", @"c7c5"],
           // 1.d4 d5 → Gambit Dame
           @"rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w" :
               @[@"c2c4", @"g1f3", @"e2e3"],
           @"rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b" :
               @[@"e7e6", @"c7c6", @"d5c4"],
           // 1.d4 Cf6 → Nimzo / Est-Indienne
           @"rnbqkb1r/pppppppp/5n2/8/3P4/8/PPP1PPPP/RNBQKBNR w" :
               @[@"c2c4", @"g1f3", @"b1c3"],
           @"rnbqkb1r/pppppppp/5n2/8/2PP4/8/PP2PPPP/RNBQKBNR b" :
               @[@"e7e6", @"g7g6", @"c7c5"],
           // ── APRÈS 1.c4 (Anglaise) ────────────────────────────
           @"rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b" :
               @[@"e7e5", @"g8f6", @"c7c5"],
           // ── APRÈS 1.Cf3 ──────────────────────────────────────
           @"rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b" :
               @[@"d7d5", @"g8f6", @"c7c5", @"e7e6"],
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
