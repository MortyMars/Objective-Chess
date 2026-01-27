// Minimax.m
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved.
// Optimized for AI perfs by MCN in 2025


#import "Minimax.h"
#import "Util.h"



// Variables globales GPT - Direction des pièces
static const int bishopDirs[4][2] = {{-1,-1},{-1,1},{1,-1},{1,1}};
static const int rookDirs[4][2] = {{-1,0},{1,0},{0,-1},{0,1}};
static const int queenDirs[8][2] = {{-1,-1},{-1,1},{1,-1},{1,1},{-1,0},{1,0},{0,-1},{0,1}};
static const int knightOffsets[8][2] = {{-2,-1},{-2,1},{-1,-2},{-1,2},{1,-2},{1,2},{2,-1},{2,1}};

@implementation Minimax

- (instancetype)init
{
   self = [super init];
   if (self) {
      evalCache = [[NSMutableDictionary alloc] initWithCapacity:200000];
      cacheHits = 0;
      cacheMisses = 0;
   }
   return self;
}


// ================================================================================================
// MÉTHODE 1 : BestMoveForSide - Point d'entrée du moteur IA
// Cette méthode trouve le meilleur coup pour l'IA en explorant l'arbre des possibilités
// ================================================================================================
-(Move *)BestMoveForSide:(Side)side
                   board:(ChessBoard *)board
{
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
   
   // LOG DE CTRL
   NSLog(@"BestMoveForSide: side=%@ board=%@",
         side == sideWhite ? @"WHITE" : @"BLACK",
         board);
   
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
   
   // Réinit valeurs cache
   evalCache = [[NSMutableDictionary alloc] initWithCapacity:100000];
   cacheHits = 0;
   cacheMisses = 0;
   
   /* Détermination du jeu de tous les moves possibles pour 'side' */
   NSSet *movesPossibles = [self PossibleMovesForSide:side board:board];
   
   /* PRÉREQUIS : Tester si side est mat ou pat */
   if (movesPossibles.count == 0) {
      [self NotifiePatMatDesSide:side onBoard:board];
      return nil;
   }
   
   /* Initialisation des variables de recherche */
   int bestScore  = -INT_MAX;
   Move *bestMove = nil;
   Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
   
   /* ========== FILTRAGE SÉCURITÉ ========== */
   NSMutableSet *safeMovesOnly = [[NSMutableSet alloc] init];
   int dangerousMovesFiltered = 0;
   
   for (Move *move in movesPossibles) {
      Piece *movingPiece = [board pieceAtPos:move.start];
      Piece *capturedPiece = [board pieceAtPos:move.dest];
      
      if (!movingPiece) continue;
      
      BOOL isDangerous = NO;
      
      /* Valeur de la pièce qui bouge */
      int movingValue = 0;
      switch (movingPiece.type) {
         case Dame: movingValue = 900; break;
         case Tour: movingValue = 500; break;
         case Fou:
         case Cava: movingValue = 300; break;
         case Pion: movingValue = 100; break;
         case Roi: movingValue = 0; break;
         default: break;
      }
      
      /* Valeur capturée */
      int capturedValue = 0;
      if (capturedPiece && capturedPiece.type != Invalide) {
         switch (capturedPiece.type) {
            case Dame: capturedValue = 900; break;
            case Tour: capturedValue = 500; break;
            case Fou:
            case Cava: capturedValue = 300; break;
            case Pion: capturedValue = 100; break;
            default: break;
         }
      }
      
      /* Vérifier seulement pour les pièces chères */
      if (movingValue >= 300) {
         ChessBoard *testBoard = board.copy;
         [testBoard PerformMove:move];
         
         Side enemySide = (movingPiece.side == sideWhite) ? sideBlack : sideWhite;
         
         /* Utiliser le helper */
         int cheapestAttacker = [self CheapestAttackerValue:move.dest
                                                      bySide:enemySide
                                                     inBoard:testBoard];
         
         if (cheapestAttacker > 0) {  // Case attaquée
            int netGain = capturedValue - movingValue;
            
            if (netGain < -200) {
               isDangerous = YES;
               dangerousMovesFiltered++;
            }
         }
      }
      
      if (!isDangerous) [safeMovesOnly addObject:move];
   }
   
   if (safeMovesOnly.count == 0) {
      safeMovesOnly = [NSMutableSet setWithArray:[movesPossibles allObjects]];
   } else if (dangerousMovesFiltered > 0) {
      NSLog(@"🛡️ Filtre : %d coups dangereux bloqués, %lu gardés",
            dangerousMovesFiltered, (unsigned long)safeMovesOnly.count);
   }
   /* ======= FIN DE FILTRAGE SÉCURITÉ ======= */
   
   /* TRI DES COUPS */
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
      ChessBoard *newBoard = board.copy;
      [newBoard PerformMove:moveEnCours];
      /* DÉTECTION RAPIDE DU MAT */
      if ([self PossibleMovesForSide:otherSide board:newBoard].count == 0) {
         if ([self TestEchecRoiSide:otherSide inBoard:newBoard]) {
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
            NSLog(@"✓ MAT trouvé : %@ (%.1fs, %d nœuds)\n",
                  moveEnCours, elapsed, nodeCount);
            return moveEnCours;
         }
      }
      /* Appel à Negamax */
      int negaMax = [self NegamaxForSide:side
                                   board:newBoard
                                   depth:NUMBER_MOVES_AHEAD
                                   alpha:-INT_MAX
                                    beta:INT_MAX];
      /* Mise à jour du meilleur coup */
      if (negaMax > bestScore || !bestMove) {
         bestScore = negaMax;
         bestMove = moveEnCours;
      }
   }
   
   /* ========== CALCUL DU TEMPS ÉCOULÉ ========== */
   NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:startTime];
   
   NSLog(@"✅ Coup choisi : %@ (score=%d, %.1fs, %d nœuds, %.0f n/s)\n",
         bestMove, bestScore, elapsed, nodeCount, nodeCount/elapsed);
   // Log de PROFILLING
   NSLog(@"\n📊 PROFILING :");
   NSLog(@"   EvalBoard : %d appels, %.2fs total, %.1fms/appel",
         evalCount, evalTotalTime, evalCount > 0 ? (evalTotalTime * 1000.0) / evalCount : 0);
   NSLog(@"   MoveGen   : %d appels, %.2fs total, %.1fms/appel",
         moveGenCount, moveGenTotalTime, moveGenCount > 0 ? (moveGenTotalTime * 1000.0) / moveGenCount : 0);
   NSLog(@"   CopyBoard : %d copies", copyBoardCount);

   double percentEval = evalTotalTime / elapsed * 100.0;
   double percentMoveGen = moveGenTotalTime / elapsed * 100.0;
   NSLog(@"   Répartition : EvalBoard=%.0f%%, MoveGen=%.0f%%\n", percentEval, percentMoveGen);
   
   // Profilling du nombre de coups élagué
   NSLog(@"📊 Élagages : %d cutoffs sur %d nœuds (%.1f%%)", nbElag, nodeCount, (100.0 * nbElag / nodeCount));
   
   return bestMove;
}


// ================================================================================================
// Méthode d'instance NegamaxForSide
// ================================================================================================
-(int)NegamaxForSide:(Side)side
               board:(ChessBoard *)board
               depth:(int)depth
               alpha:(int)alpha
                beta:(int)beta
{
   NSLog(@"Negamax: side=%@ depth=%d",
         side == sideWhite ? @"WHITE" : @"BLACK",
         depth);

   if (depth == 0) {
      
      // DEBUG TEMPORAIRE
      int eval = [self EvalBoardForSide:side board:board];
      NSLog(@"Eval leaf = %d", eval);
      
      return eval;
   }
   NSMutableArray<Move *> *moves = [NSMutableArray arrayWithCapacity:64];
   [self generatePseudoMovesForSide:side board:board into:moves];

   Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
   for (Move *m in moves) {
      
      // LIGNE 1 POUR DEBUG
      //ChessBoard *before = [board copy];
      
      MoveState state = [board makeMove:m];

      //if (![self kingInCheck:side board:board]) {
      // Appel récursif à Negamax
      int score = -[self NegamaxForSide:otherSide
                                  board:board
                                  depth:depth-1
                                  alpha:-beta
                                   beta:-alpha];

      if (score > alpha) alpha = score;
      //}

      [board unmakeMove:m state:state];
      
      // LIGNE 2 POUR DEBUG
      //NSAssert([board isEqual:before], @"💥 Plateau corrompu après unmakeMove");


      if (alpha >= beta)
         break;
   }

   return alpha;
}



// ================================================================================================
// MÉTHODE 3 : SortMovesByPriority
// TRI DES COUPS PAR PRIORITÉ pour améliorer l'efficacité de l'élagage alpha-beta
// Principe : Les meilleurs coups sont examinés en premier, ce qui provoque plus de cutoffs
// et réduit donc le nombre de branches à explorer
// ================================================================================================
-(NSArray *)SortMovesByPriority:(NSSet *)moves
                          board:(ChessBoard *)board
                           side:(Side)side
                          depth:(int)depth
{
   /* Conversion du NSSet en NSArray pour pouvoir le trier */
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
// MÉTHODE 4 : ScoreMove - ÉVALUATION RAPIDE D'UN COUP
// Attribution d'un score heuristique rapide basé sur :
// - La valeur de la pièce capturée (si capture)
// - D'autres critères possibles (coups centraux, développement, etc.)
// ================================================================================================
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
}


// ================================================================================================
// MÉTHODE 5 : FilterCaptures - FILTRAGE DES CAPTURES POUR QUIESCENCE SEARCH
// NOUVELLE MÉTHODE pour optimiser le QS
// Ne conserve que les coups qui sont des captures, car ce sont les coups "tactiques"
// qui peuvent changer drastiquement l'évaluation d'une position
// ================================================================================================
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
// ================================================================================================
-(int)EvalBoardForSide:(Side)side
                 board:(ChessBoard *)board
{
   // Générer une clé unique pour cette position
   NSString *key = [self BoardHashKey:board forSide:side];
   NSNumber *cached = evalCache[key];
   if (cached) {
      cacheHits++;
      return [cached intValue];
   }
   cacheMisses++;
   
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
               if (totalMaterial < 3000) {
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
   
   /* Compter les dames pour vérifier les promotions */
   int queensWhite = 0, queensBlack = 0;
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Piece *p = [board piece_colX:x rangY:y];
         if (p && p.type == Dame) {
            if (p.side == sideWhite) queensWhite++;
            else queensBlack++;
         }
      }
   }

   if (queensWhite > 1 || queensBlack > 1)
      NSLog(@"🔍 PROMOTION DÉTECTÉE : Blancs=%d Dames, Noirs=%d Dames", queensWhite, queensBlack);
   
   
   /* PARTIE 2 désactivée car la mobilité est déjà gérée par le nbre de coups explorés
   // ===========================================
   // PARTIE 2 : ÉVALUATION DE LA MOBILITÉ
   // La mobilité = nombre de coups possibles pour chaque camp
   // Un camp avec plus de coups possibles a généralement un meilleur contrôle du jeu
   // OPTIMISATION : On ne calcule ceci que tous les 2 niveaux pour économiser du temps
   
   if (NUMBER_MOVES_AHEAD % 2 == 0) {  // Calcul partiel pour économiser du temps
      NSSet *movesWhite = [self PossibleMovesForSide:sideWhite board:board];
      NSSet *movesBlack = [self PossibleMovesForSide:sideBlack board:board];
      
      mobilityWhite = (int)movesWhite.count * 2;  // Bonus réduit : 2 points par coup possible
      mobilityBlack = (int)movesBlack.count * 2;
      
      int mobilityDiff = mobilityWhite - mobilityBlack;
      evalWhitePOV += mobilityDiff;  // Toujours du point de vue des Blancs
   }
   FIN de PARTIE 2 désactivée*/
   
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
             BOOL isEndGame = (totalMaterial < 2000);  // Peu de matériel
             
             if (!isEndGame) {
                // En milieu de partie, le Roi DOIT être sur les bords
                BOOL isOnEdge   = (x == 0 || x == 7 || y == 0 || y == 7);
                BOOL isInCorner = ((x <= 1 || x >= 6) && (y == 0 || y == 7));
                
                if (!isOnEdge) {
                   // Roi au centre = TRÈS DANGEREUX
                   int dangerPenalty = -200;  // Grosse pénalité
                   
                   if (piece.side == sideWhite) {
                      evalWhitePOV += dangerPenalty;
                   } else {
                      evalWhitePOV -= dangerPenalty;
                   }
                } else if (!isInCorner) {
                   // Roi sur le bord mais pas dans le coin
                   int edgePenalty = -50;
                   
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
   
   /* PARTIE 6 désactivée car redondante avec la vérification faite dans NegamaxForSide
   // ===========================================
   // PARTIE 6 : DÉTECTION MAT
   // Note : Cette section pourrait être optimisée en ne l'appelant que rarement
   // car elle est coûteuse en calcul
   if ([self TestEchecRoiSide:sideBlack inBoard:board]) {
      if ([self PossibleMovesForSide:sideBlack board:board].count == 0) {
         evalWhitePOV += +100000;  // Mat des Noirs = énorme avantage Blancs
      }
   }
   else if ([self TestEchecRoiSide:sideWhite inBoard:board]) {
      if ([self PossibleMovesForSide:sideWhite board:board].count == 0) {
         evalWhitePOV += -100000;  // Mat des Blancs = énorme avantage Noirs
      }
   }
   FIN de PARTIE 6 désactivée*/
   
   // ===========================================
   // PARTIE 7 : PIONS EN AVANT-DERNIÈRE RANGÉE
   /* Bonus important pour pions sur le point d'être promus */
   if (sideJoueur == sideWhite) {
      for (int x = 0; x < 8; x++) {
         Piece *pionB = board->pieceCase[x][6];
         if ((pionB.type == Pion) && (pionB.side == sideWhite)) {
            evalWhitePOV += +900;  // Pion Blanc proche promo
         }
         Piece *pionN = board->pieceCase[x][1];
         if ((pionN.type == Pion) && (pionN.side == sideBlack)) {
            evalWhitePOV += -900;  // Pion Noir proche promo
         }
      }
   }
   if (sideJoueur == sideBlack) {
      for (int x = 0; x < 8; x++) {
         Piece *pionB = board->pieceCase[x][1];
         if ((pionB.type == Pion) && (pionB.side == sideWhite)) {
            evalWhitePOV += +900;  // Pion Blanc proche promo
         }
         Piece *pionN = board->pieceCase[x][6];
         if ((pionN.type == Pion) && (pionN.side == sideBlack)) {
            evalWhitePOV += -900;  // Pion Noir proche promo
         }
      }
   }
   
   // ===========================================
   
   /* La mise à jour de l'interface est déplacée dans 'MakeIAMoveForSide' et sa variante 'Silent......'
    pour limiter le nombre de mise à jour de l'interface pendant que l'IA décide de son coup */
   
   // Stocker dans le cache
   evalCache[key] = @(evalWhitePOV);
   // Limiter la taille du cache
   if (evalCache.count > 200000) [evalCache removeAllObjects];
   
   /* CONVERSION FINALE POUR NEGAMAX :
      - Si 'side' = Blancs : retourner evalWhitePOV tel quel (positif = bon pour Blancs)
      - Si 'side' = Noirs  : retourner -evalWhitePOV (négatif devient positif)
      Ainsi Negamax reçoit toujours une évaluation positive = bon pour le camp qui joue */
   return (side == sideWhite) ? evalWhitePOV : -evalWhitePOV;
   //return evalWhitePOV;
   /* Pour l'évaluation du board par contre, sachant que la convention -qui veut qu'une éval
    positive indique un avantage aux Blancs et une éval négative l'inverse- se suffit à elle
    même et n'a pas à être inversée pour sa version affichée en barre d'état. */
   
}


// ================================================================================================
// MÉTHODE 7 : PossibleMovesForSide - GÉNÉRATION DES COUPS LÉGAUX
// ================================================================================================
-(NSSet *)PossibleMovesForSide:(Side)side
                         board:(ChessBoard *)board
{
   NSMutableSet *moves = [[NSMutableSet alloc] init];
   
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Pos *pos = [Pos posWithX:x y:y];
         Piece *piece = [board piece_colX:x rangY:y];
         
         if (piece && piece.side == side) {
            NSSet *PosAcceptees = [RuleBook PosAccepteesForPiece:piece atPos:pos inBoard:board];
            
            for (Pos *possibleDest in PosAcceptees) {
               Move *move = [[Move alloc] initWithStart:pos dest:possibleDest];
               
               /* Vérification que le coup ne met pas son propre roi en échec */
               ChessBoard *newBoard = board.copy;
               [newBoard PerformMove:move];
               [moves addObject:move];
            }
         }
      }
   }
   
   return moves;
}


// ================================================================================================
// MÉTHODE 8 : TestEchecFavSide - DÉTECTION ÉCHEC AVEC NOTIFICATION
// ================================================================================================
-(NSString *)TestEchecFavSide:(Side)side Board:(ChessBoard *)board
{
   NSString *strEchec = @"";
   NSString *strOtherSide = @"";
   checkCount = 0;
   Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
   
   // Parcours de l'échiquier
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Pos *pos = [Pos posWithX:x y:y];
         Piece *piece = [board piece_colX:x rangY:y];
         // Si 'piece' existe et qu'elle est de la couleur 'side'
         if (piece && piece.side == side) {
            // Création du jeu des destinations possibles pour la pièce
            NSSet *PosAcceptees = [RuleBook PosAccepteesForPiece:piece atPos:pos inBoard:board];
            // Parcours de toutes les destinations possibles
            for (Pos *possibleDest in PosAcceptees) {
               // Création du move correspondant (on ne l'exécute pas)
               Move *moveSide = [[Move alloc] initWithStart:pos dest:possibleDest];
               // Création d'une pièce adverse potentiellement présente à l'arrivée du move
               Piece *pieceAdv = [board piece_colX:moveSide.dest.x rangY:moveSide.dest.y];
               // Si cette pièce est le Roi adverse, alors ça signifie que celui-ci est en 'échec'
               if (pieceAdv.type == Roi && pieceAdv.side == otherSide) {
                  strEchec = @"Echec";
                  checkCount++;
               }
            }
         }
      }
   }
   
   // Message en Log
   strOtherSide = (side == sideWhite)? @"Noir":@"Blanc";
   if ([strEchec isEqual:@"Echec"]) {
      [monMCNControleur.maChessView.delegate AlerteEchecRoiSide:otherSide];
      NSLog(@"\nLe Roi %@ est en situation : %@", strOtherSide, strEchec);
   }
   
   return strEchec;
}


// ================================================================================================
// MÉTHODE 9 : TestEchecRoiSide - VERSION RAPIDE DE LA DÉTECTION D'ÉCHEC
// ================================================================================================
-(BOOL)TestEchecRoiSide:(Side)side inBoard:(ChessBoard *)board
{
   Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
   
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Pos *pos = [Pos posWithX:x y:y];
         Piece *pieceAdv = [board piece_colX:x rangY:y];
         
         if (pieceAdv && pieceAdv.side == otherSide) {
            NSSet *PosAcceptees = [RuleBook PosAccepteesForPiece:pieceAdv atPos:pos inBoard:board];
            
            for (Pos *possibleDest in PosAcceptees) {
               Move *moveSideAdv = [[Move alloc] initWithStart:pos dest:possibleDest];
               Piece *piece = [board piece_colX:moveSideAdv.dest.x rangY:moveSideAdv.dest.y];
               
               if (piece.type == Roi && piece.side == side) return YES;
            }
         }
      }
   }
   
   return NO;
}


// ================================================================================================
// MÉTHODE 10 : NotifiePatMatDesSide - GESTION FIN DE PARTIE
// ================================================================================================
-(void)NotifiePatMatDesSide:(Side)side
                    onBoard:(ChessBoard*)board
{
   if ([self TestEchecRoiSide:side inBoard:board]) {
      /* MAT DÉTECTÉ */
      NSString *msgTitre;
      NSString *msgInfo;
      
      while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == ' ') {
         stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
      }
      while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == '+') {
         stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
      }
      
      monMCNControleur.lblEchec.cell.stringValue = @"Échec et Mat !";
      
      if (side == sideBlack) {
         msgTitre = @"Les NOIRS sont Mat !";
         msgInfo  = @"Partie terminée, Les BLANCS gagnent !";
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t1-0"];
         [monMCNControleur MaJtxtCoups];
      }
      else if (side == sideWhite) {
         msgTitre = @"Les BLANCS sont Mat !";
         msgInfo  = @"Partie terminée, Les NOIRS gagnent !";
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t0-1"];
         [monMCNControleur MaJtxtCoups];
      }
      
      NSAlert *alertMat = [[NSAlert alloc] init];
      [alertMat addButtonWithTitle:@"OK"];
      [alertMat setMessageText:msgTitre];
      [alertMat setInformativeText:msgInfo];
      [alertMat setAlertStyle:NSAlertStyleInformational];
      
      NSModalResponse boutonChoisi = [alertMat runModal];
      if (boutonChoisi == NSAlertFirstButtonReturn) {
         stopMatOuPat = YES;
      }
      
      // Message en Log
      NSString *strRoiMat = (side == sideBlack)? @"\"Noirs\"":@"\"Blancs\"";
      NSLog(@"\nLe Roi %@ est Mat\n", strRoiMat);
   }
   else {
      /* PAT DÉTECTÉ */
      stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\n\t1/2-1/2"];
      [monMCNControleur MaJtxtCoups];
      
      NSString *msgTitre;
      NSString *msgInfo;
      
      if (side == sideBlack) {
         msgTitre = @"Les NOIRS sont Pat !";
         msgInfo  = @"Le Roi Noir est Pat, la partie est déclarée nulle !";
      }
      else if (side == sideWhite) {
         msgTitre = @"Les BLANCS sont Pat !";
         msgInfo  = @"Le Roi Blanc est Pat, la partie est déclarée nulle !";
      }
      
      monMCNControleur.lblEchec.cell.stringValue = @"Pat !";
      
      NSAlert *alertPat = [[NSAlert alloc] init];
      [alertPat addButtonWithTitle:@"OK"];
      [alertPat setMessageText:msgTitre];
      [alertPat setInformativeText:msgInfo];
      [alertPat setAlertStyle:NSAlertStyleInformational];
      
      NSModalResponse boutonChoisi = [alertPat runModal];
      if (boutonChoisi == NSAlertFirstButtonReturn) {
         stopMatOuPat = YES;
      }
      
      // Message en Log
      NSString *strRoiPat = (side == sideBlack)? @"\"Noirs\"":@"\"Blancs\"";
      NSLog(@"\nLe Roi %@ est Pat\n", strRoiPat);
   }
}


// ================================================================================================
// MÉTHODE HELPER :
// Recherche et retourne le move d'attaque le moins couteux en matériel
// ================================================================================================
-(int)CheapestAttackerValue:(Pos *)targetSquare
                     bySide:(Side)attackingSide
                    inBoard:(ChessBoard *)board
{
   int cheapestValue = INT_MAX;
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
// ================================================================================================
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
// Méthode SSE
// ================================================================================================
-(int)StaticExchangeEvaluation:(Move *)capture
                          board:(ChessBoard *)board
{
   Piece *attacker = [board pieceAtPos:capture.start];
   Piece *victim = [board pieceAtPos:capture.dest];
   
   if (!victim || victim.type == Invalide) {
      return 0;  // Pas une capture
   }
   
   int attackerValue = [self PieceValue:attacker];
   int victimValue = [self PieceValue:victim];
   
   // Simuler la capture
   ChessBoard *afterCapture = board.copy;
   [afterCapture PerformMove:capture];
   
   // Est-ce que l'adversaire peut reprendre ?
   Side enemySide = (attacker.side == sideWhite) ? sideBlack : sideWhite;
   int cheapestAttacker = [self CheapestAttackerValue:capture.dest
                                               bySide:enemySide
                                              inBoard:afterCapture];
   
   if (cheapestAttacker == 0) {
      // Personne ne peut reprendre, gain net
      return victimValue;
   }
   
   // Quelqu'un peut reprendre
   int netGain = victimValue - attackerValue;
   
   // Si on perd au change, mauvaise capture
   if (netGain < 0) {
      return netGain * 10;  // Pénalité forte
   }
   
   return victimValue;  // Capture neutre ou bonne
}


// ================================================================================================
// Helper pour obtenir la valeur d'une pièce
// ================================================================================================
-(int)PieceValue:(Piece *)piece
{
   switch (piece.type) {
      case Pion: return 100;
      case Cava:
      case Fou:  return 300;
      case Tour: return 500;
      case Dame: return 900;
      case Roi:  return 100000;
      default:   return 0;
   }
}


// GPT
-(void)generatePseudoMovesForSide:(Side)side
                            board:(ChessBoard *)board
                             into:(NSMutableArray<Move *> *)moves
{
   // ⚠️ IMPORTANT
   [moves removeAllObjects];

   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Piece *p = board->pieceCase[x][y];
         if (!p || p.side != side) continue;
         // NSLog de debug
         if (p && p.side != side) {
            NSLog(@"💥 Coup généré pour MAUVAISE couleur : %@ (%d,%d)",
                  p.side == sideWhite ? @"White" : @"Black", x, y);
         }
         

         switch (p.type) {
            case Pion:
               [self genPawnMovesFromX:x y:y piece:p board:board into:moves];
               break;
            case Cava:
               [self genKnightMovesFromX:x y:y piece:p board:board into:moves];
               break;
            case Fou:
               [self genSlidingMovesFromX:x y:y piece:p board:board
                                     dirs:bishopDirs dirCount:4 into:moves];
               break;
            case Tour:
               [self genSlidingMovesFromX:x y:y piece:p board:board
                                     dirs:rookDirs dirCount:4 into:moves];
               break;
            case Dame:
               [self genSlidingMovesFromX:x y:y piece:p board:board
                                     dirs:queenDirs dirCount:8 into:moves];
               break;
            case Roi:
               [self genKingMovesFromX:x y:y piece:p board:board into:moves];
               break;
            default:
               break;
         }
      }
   }
}




-(void)genKnightMovesFromX:(int)x y:(int)y
                     piece:(Piece *)p
                     board:(ChessBoard *)board
                      into:(NSMutableArray *)moves
{
   for (int i = 0; i < 8; i++) {
      int nx = x + knightOffsets[i][0];
      int ny = y + knightOffsets[i][1];

      if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;

      Piece *target = board->pieceCase[nx][ny];
      if (!target || target.side != p.side) {
         Pos *start = [Pos posWithX:x y:y];
         Pos *dest  = [Pos posWithX:nx y:ny];
         [moves addObject:[[Move alloc] initWithStart:start dest:dest]];
      }
   }
}





-(void)genSlidingMovesFromX:(int)x y:(int)y
                      piece:(Piece *)p
                      board:(ChessBoard *)board
                       dirs:(const int (*)[2])dirs
                   dirCount:(int)dirCount
                       into:(NSMutableArray *)moves
{
   for (int d = 0; d < dirCount; d++) {
      int dx = dirs[d][0];
      int dy = dirs[d][1];

      int nx = x + dx;
      int ny = y + dy;

      while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
         Piece *target = board->pieceCase[nx][ny];

         Pos *start = [Pos posWithX:x y:y];
         Pos *dest  = [Pos posWithX:nx y:ny];

         if (!target) {
            [moves addObject:[[Move alloc] initWithStart:start dest:dest]];
         }
         else {
            if (target.side != p.side) {
               [moves addObject:[[Move alloc] initWithStart:start dest:dest]];
            }
            break; // pièce bloquante
         }

         nx += dx;
         ny += dy;
      }
   }
}


-(void)genPawnMovesFromX:(int)x y:(int)y
                   piece:(Piece *)p
                   board:(ChessBoard *)board
                    into:(NSMutableArray *)moves
{
   int dir = (p.side == sideWhite) ? 1 : -1;
   int startRank = (p.side == sideWhite) ? 1 : 6;

   int ny = y + dir;

   // Avance simple
   if (ny >= 0 && ny < 8 && board->pieceCase[x][ny] == nil) {
      Pos *start = [Pos posWithX:x y:y];
      Pos *dest  = [Pos posWithX:x y:ny];
      [moves addObject:[[Move alloc] initWithStart:start dest:dest]];

      // Double pas
      if (y == startRank) {
         int ny2 = y + 2 * dir;
         if (board->pieceCase[x][ny2] == nil) {
            Pos *dest2 = [Pos posWithX:x y:ny2];
            [moves addObject:[[Move alloc] initWithStart:start dest:dest2]];
         }
      }
   }

   // Captures diagonales
   for (int dx = -1; dx <= 1; dx += 2) {
      int nx = x + dx;
      if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;

      Piece *target = board->pieceCase[nx][ny];
      if (target && target.side != p.side) {
         Pos *start = [Pos posWithX:x y:y];
         Pos *dest  = [Pos posWithX:nx y:ny];
         [moves addObject:[[Move alloc] initWithStart:start dest:dest]];
      }
   }
}



-(void)genKingMovesFromX:(int)x y:(int)y
                   piece:(Piece *)p
                   board:(ChessBoard *)board
                    into:(NSMutableArray *)moves
{
   for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
         if (dx == 0 && dy == 0) continue;

         int nx = x + dx;
         int ny = y + dy;

         if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;

         Piece *target = board->pieceCase[nx][ny];
         if (!target || target.side != p.side) {
            Pos *start = [Pos posWithX:x y:y];
            Pos *dest  = [Pos posWithX:nx y:ny];
            [moves addObject:[[Move alloc] initWithStart:start dest:dest]];
         }
      }
   }
}




@end
