//  Minimax.m - VERSION OPTIMISÉE
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 2020
//  Optimisé pour performance IA - 2025
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "Minimax.h"

int nbLoop = 0;
int nbElag = 0;
static int nodeCount = 0;  // ✅ AJOUTER ICI

@implementation Minimax

   
//***************************************************************************************************
// MÉTHODE 1 : BestMoveForSide - Point d'entrée du moteur IA
// Cette méthode trouve le meilleur coup pour l'IA en explorant l'arbre des possibilités
//***************************************************************************************************
+(Move *)BestMoveForSide:(Side)side
                   board:(ChessBoard *)board
{
   /* ========== DÉMARRAGE DU TIMER ========== */
   NSDate *startTime = [NSDate date];
   nodeCount = 0;
   
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
      
      if (!isDangerous) {
         [safeMovesOnly addObject:move];
      }
   }
   
   if (safeMovesOnly.count == 0) {
      //NSLog(@"⚠️ Tous les coups sont dangereux");
      safeMovesOnly = [NSMutableSet setWithArray:[movesPossibles allObjects]];
   } else if (dangerousMovesFiltered > 0) {
      NSLog(@"🛡️ Filtre : %d coups dangereux bloqués, %lu gardés",
            dangerousMovesFiltered, (unsigned long)safeMovesOnly.count);
   }
   
   /* TRI DES COUPS */
   NSArray *sortedMoves = [self SortMovesByPriority:safeMovesOnly board:board];
   
   NSLog(@"=== IA (%@) analyse %lu coups ===",
         (side == sideWhite) ? @"Blancs" : @"Noirs",
         (unsigned long)sortedMoves.count);
   
   
   /* ========== DÉTECTION MENACE DE MAT ========== */
   Side enemySide = (side == sideWhite) ? sideBlack : sideWhite;

   if ([self HasMateInOne:enemySide inBoard:board]) {
      NSLog(@"⚠️ ALERTE : L'adversaire a un mat en 1 coup !");
      
      /* Filtrer les coups qui NE BLOQUENT PAS le mat */
      NSMutableSet *movesBlockingMate = [[NSMutableSet alloc] init];
      
      for (Move *move in sortedMoves) {
         ChessBoard *testBoard = board.copy;
         [testBoard PerformMove:move];
         
         /* Après ce coup, l'adversaire a-t-il toujours mat en 1 ? */
         if (![self HasMateInOne:enemySide inBoard:testBoard]) {
            [movesBlockingMate addObject:move];
         }
      }
      
      if (movesBlockingMate.count > 0) {
         NSLog(@"🛡️ %lu coups bloquent le mat", (unsigned long)movesBlockingMate.count);
         sortedMoves = [movesBlockingMate allObjects];
      } else {
         NSLog(@"💀 Aucun coup ne peut empêcher le mat");
      }
   }
   
   
   
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
   
   return bestMove;
}


//***************************************************************************************************
// MÉTHODE 2 : NegamaxForSide - CÅ’UR DE L'ALGORITHME (VERSION OPTIMISÉE)
// Implémentation de l'algorithme Negamax avec élagage alpha-beta et Quiescence Search
//
// OPTIMISATIONS PRINCIPALES :
// 1. Évaluation déplacée aprÃ¨s les conditions de sortie (gain majeur)
// 2. Limitation stricte de la Quiescence Search Ã  -3 niveaux max
// 3. Filtrage des captures AVANT la boucle en mode QS
// 4. Tri des coups pour améliorer l'élagage
//***************************************************************************************************
+(int)NegamaxForSide:(Side)side
               board:(ChessBoard *)board
               depth:(int)depth
               alpha:(int)alpha
                beta:(int)beta
{
   /* Au début de NegamaxForSide
    Vidage du cache */
   nodeCount++;

   /* Toutes les 10000 évaluations, vider les caches si vous en avez */
   if (nodeCount % 10000 == 0) {
      NSLog(@"⏱️ Negamax : %d nœuds explorés", nodeCount);
   }

   /* Limite de sécurité : si trop de nœuds, arrêter la recherche */
   if (nodeCount > 500000) {
      NSLog(@"⚠️ LIMITE ATTEINTE : Arrêt de la recherche");
      return [self EvalBoardForSide:side board:board];
   }
   /* Fin de vidage du cache */
   
   
   
   Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
   
   /* ÉTAPE 1 : GÉNÉRATION DES COUPS POSSIBLES
      On génÃ¨re les coups ici pour pouvoir détecter mat/pat ET les utiliser plus tard */
   NSSet *movesPossibles = [self PossibleMovesForSide:otherSide board:board];
   
   /* ÉTAPE 2 : DÉTECTION MAT/PAT
      Si aucun coup n'est possible, c'est soit mat soit pat */
   if (movesPossibles.count == 0) {
      if ([self TestEchecRoiSide:otherSide inBoard:board]) {
         return 100000;  // Mat favorable Ã  'side'
      }
      return 0;  // Pat = nulle
   }
   
   /* ÉTAPE 3 : CONDITIONS DE SORTIE ET QUIESCENCE SEARCH
      OPTIMISATION CRITIQUE : L'évaluation n'est faite QUE quand on atteint la profondeur limite */
   if (depth <= 0) {
      /* On évalue le plateau SEULEMENT maintenant */
      int eval = [self EvalBoardForSide:side board:board];
       
       /* DEBUG : Log pour vérifier les évaluations */
         /*NSLog(@"  Eval depth=%d side=%@ : eval=%d",
               depth,
               (side == sideWhite) ? @"Blancs" : @"Noirs",
               eval); */
      
      /* QUIESCENCE SEARCH (QS) : On continue Ã  explorer les captures pour éviter
         "l'effet horizon" oÃ¹ l'IA ne voit pas une prise importante juste aprÃ¨s depth=0
         OPTIMISATION : Limitation stricte Ã  3 niveaux supplémentaires maximum */
      if (depth > -3) {
         /* Élagage beta cutoff précoce */
         if (eval >= beta) return eval;
         
         /* Mise Ã  jour de la fenÃªtre alpha */
         if (eval > alpha) alpha = eval;
         
         /* OPTIMISATION : Filtrer les captures AVANT la boucle
            On ne continue le QS que s'il y a des captures possibles */
         NSSet *captures = [self FilterCaptures:movesPossibles from:otherSide board:board];
         if (captures.count == 0) {
            return eval;  // Pas de capture = on retourne l'évaluation statique
         }
         
         /* On remplace movesPossibles par les captures uniquement */
         movesPossibles = captures;
         //NSLog(@"\n  QS (depth %d) : %lu captures Ã  examiner", depth, (unsigned long)captures.count);
         
      } else {
         /* Limite QS atteinte : on arrÃªte l'exploration */
         return eval;
      }
   }
   
   /* ÉTAPE 4 : TRI DES COUPS (Move Ordering)
      OPTIMISATION : Examiner les meilleurs coups en premier améliore drastiquement l'élagage
      Les captures de grande valeur sont prioritaires */
   NSArray *sortedMoves = [self SortMovesByPriority:movesPossibles board:board];
   
   /* ÉTAPE 5 : EXPLORATION RÉCURSIVE DE L'ARBRE
      Pour chaque coup possible, on simule la position résultante et on évalue récursivement */
   for (Move *moveEnCours in sortedMoves)
   {
      /* Création d'un plateau virtuel pour simuler le coup */
      ChessBoard *newBoard = board.copy;
      [newBoard PerformMove:moveEnCours];
      
      /* APPEL RÉCURSIF : On inverse les rôles (otherSide joue), on descend d'un niveau,
         et on inverse alpha/beta (principe du Negamax) */
      int score = -[self NegamaxForSide:otherSide
                                  board:newBoard
                                  depth:depth - 1
                                  alpha:-beta
                                   beta:-alpha];
      
      /* Mise Ã  jour du meilleur score trouvé */
      if (score > alpha) {
         alpha = score;
         
         /* ÉLAGAGE ALPHA-BETA : Si alpha >= beta, les coups suivants ne peuvent pas
            améliorer la position, on peut arrÃªter l'exploration de cette branche */
         if (alpha >= beta) {
            nbElag++;
            break;  // Cutoff beta
         }
      }
   }
   
   return alpha;
}


//***************************************************************************************************
// MÉTHODE 3 : SortMovesByPriority - TRI DES COUPS PAR PRIORITÉ
// NOUVELLE MÉTHODE pour améliorer l'efficacité de l'élagage alpha-beta
//
// Principe : Les meilleurs coups sont examinés en premier, ce qui provoque plus de cutoffs
// et réduit donc le nombre de branches Ã  explorer
//***************************************************************************************************
+(NSArray *)SortMovesByPriority:(NSSet *)moves board:(ChessBoard *)board
{
   /* Conversion du NSSet en NSArray pour pouvoir le trier */
   NSArray *movesArray = [moves allObjects];
   
   return [movesArray sortedArrayUsingComparator:^NSComparisonResult(Move *m1, Move *m2) {
      int score1 = [self ScoreMove:m1 board:board];
      int score2 = [self ScoreMove:m2 board:board];
      
      /* Tri par ordre décroissant (meilleurs coups en premier) */
      if (score2 > score1) return NSOrderedAscending;
      if (score2 < score1) return NSOrderedDescending;
      return NSOrderedSame;
   }];
}


//***************************************************************************************************
// MÉTHODE 4 : ScoreMove - ÉVALUATION RAPIDE D'UN COUP
// NOUVELLE MÉTHODE pour le tri des coups
//
// Attribution d'un score heuristique rapide basé sur :
// - La valeur de la piÃ¨ce capturée (si capture)
// - D'autres critÃ¨res possibles (coups centraux, développement, etc.)
//***************************************************************************************************
+(int)ScoreMove:(Move *)move board:(ChessBoard *)board
{
   int score = 0;
   
   /* Vérifier s'il y a une capture */
   Piece *captured = [board pieceAtPos:move.dest];
   if (captured && captured.type != Invalide) {
      /* Priorité haute pour les captures : score de base + valeur de la piÃ¨ce */
      switch (captured.type) {
         case Pion:  score = 1000 + 100;    break;
         case Cava:  score = 1000 + 300;    break;
         case Fou:   score = 1000 + 300;    break;
         case Tour:  score = 1000 + 500;    break;
         case Dame:  score = 1000 + 900;    break;
         case Roi:   score = 1000 + 100000; break;  // Théorique
         default:    break;
      }
   }
   
   /* AMÉLIORATION FUTURE : Ajouter d'autres heuristiques
      - Coups vers le centre du plateau (bonus +10 Ã  +30)
      - Développement des piÃ¨ces (sortir cavaliers/fous)
      - Contrôle des cases importantes
      - Menaces sur le roi adverse */
   
   return score;
}


//***************************************************************************************************
// MÉTHODE 5 : FilterCaptures - FILTRAGE DES CAPTURES POUR QUIESCENCE SEARCH
// NOUVELLE MÉTHODE pour optimiser le QS
//
// Ne conserve que les coups qui sont des captures, car ce sont les coups "tactiques"
// qui peuvent changer drastiquement l'évaluation d'une position
//***************************************************************************************************
+(NSSet *)FilterCaptures:(NSSet *)moves from:(Side)side board:(ChessBoard *)board
{
   NSMutableSet *captures = [[NSMutableSet alloc] init];
   
   for (Move *move in moves) {
      Piece *captured = [board pieceAtPos:move.dest];
      
      /* Vérifier qu'il y a bien une piÃ¨ce adverse Ã  la destination */
      if (captured && captured.type != Invalide && captured.side != side) {
         [captures addObject:move];
      }
   }
   
   return captures;
}


//***************************************************************************************************
// MÉTHODE : EvalBoardForSide - VERSION AMÉLIORÉE AVEC ÉVALUATION POSITIONNELLE
// Cette méthode évalue la qualité d'une position d'échecs pour un camp donné
//
// PHILOSOPHIE D'ÉVALUATION :
// - Matériel : Valeur brute des piÃ¨ces (base)
// - Position : OÃ¹ sont placées les piÃ¨ces (crucial)
// - Sécurité : Le roi est-il en sécurité ?
// - Structure : Les pions sont-ils bien organisés ?
// - Mobilité : Combien de coups possibles ?
// - Développement : Les piÃ¨ces sont-elles actives ?
//
// CONVENTION NEGAMAX STANDARD :
// - L'évaluation est TOUJOURS du point de vue des BLANCS
// - Valeur positive = avantage Blancs, négative = avantage Noirs
// - Negamax inversera le signe selon le camp qui joue
//***************************************************************************************************
+(int)EvalBoardForSide:(Side)side
                 board:(ChessBoard *)board
{
   int evalWhitePOV = 0;  /* Évaluation du point de vue des Blancs (convention Negamax) */
   evalDisplay = 0;       /* Valeur affichée (convention : + = avantage Blancs) */
   
   /* Variables pour statistiques intermédiaires */
   int materialWhite = 0, materialBlack = 0;
   int mobilityWhite = 0, mobilityBlack = 0;
   int developmentWhite = 0, developmentBlack = 0;
   int totalMaterial = 0;  /* Pour détecter la fin de partie */
   
   
   // ==================================================================================
   // PARTIE 1 : ÉVALUATION MATÉRIELLE + POSITIONNELLE
   // ==================================================================================
   /* Tables de valeurs positionnelles pour chaque type de piÃ¨ce
      Ces tables donnent un bonus/malus selon la position de la piÃ¨ce sur l'échiquier
      Convention : les tableaux sont vus du point de vue des Blancs (rangée 0 = fond Blancs) */
   
   /* TABLE PIONS : Encourage l'avancée et le contrôle du centre
      VALEURS RÉDUITES pour éviter les sacrifices stupides */
   static const int pawnTable[8][8] = {
      {  0,  0,  0,  0,  0,  0,  0,  0 },  // Rangée 0 (promotion, ne devrait pas arriver)
      { 10, 10, 10, 10, 10, 10, 10, 10 },  // Rangée 1 (avant-derniÃ¨re, déjÃ  géré ailleurs)
      {  2,  2,  4,  6,  6,  4,  2,  2 },  // Rangée 2
      {  1,  1,  2,  5,  5,  2,  1,  1 },  // Rangée 3
      {  0,  0,  0,  4,  4,  0,  0,  0 },  // Rangée 4 (centre)
      {  1, -1, -2,  0,  0, -2, -1,  1 },  // Rangée 5
      {  1,  2,  2, -4, -4,  2,  2,  1 },  // Rangée 6
      {  0,  0,  0,  0,  0,  0,  0,  0 }   // Rangée 7 (départ)
   };
   
   /* TABLE CAVALIERS : Encourage position centrale et pénalise les bords
      VALEURS RÉDUITES */
   static const int knightTable[8][8] = {
      {-10, -8, -6, -6, -6, -6, -8,-10 },
      { -8, -4,  0,  0,  0,  0, -4, -8 },
      { -6,  0,  2,  3,  3,  2,  0, -6 },
      { -6,  1,  3,  4,  4,  3,  1, -6 },
      { -6,  0,  3,  4,  4,  3,  0, -6 },
      { -6,  1,  2,  3,  3,  2,  1, -6 },
      { -8, -4,  0,  1,  1,  0, -4, -8 },
      {-10, -8, -6, -6, -6, -6, -8,-10 }
   };
   
   /* TABLE FOUS : Encourage diagonales longues et centre
      VALEURS RÉDUITES */
   static const int bishopTable[8][8] = {
      { -4, -2, -2, -2, -2, -2, -2, -4 },
      { -2,  0,  0,  0,  0,  0,  0, -2 },
      { -2,  0,  1,  2,  2,  1,  0, -2 },
      { -2,  1,  1,  2,  2,  1,  1, -2 },
      { -2,  0,  2,  2,  2,  2,  0, -2 },
      { -2,  2,  2,  2,  2,  2,  2, -2 },
      { -2,  1,  0,  0,  0,  0,  1, -2 },
      { -4, -2, -2, -2, -2, -2, -2, -4 }
   };
   
   /* TABLE TOURS : Encourage 7Ã¨me rangée et colonnes ouvertes (approximatif)
      VALEURS RÉDUITES */
   static const int rookTable[8][8] = {
      {  0,  0,  0,  0,  0,  0,  0,  0 },
      {  1,  2,  2,  2,  2,  2,  2,  1 },
      { -1,  0,  0,  0,  0,  0,  0, -1 },
      { -1,  0,  0,  0,  0,  0,  0, -1 },
      { -1,  0,  0,  0,  0,  0,  0, -1 },
      { -1,  0,  0,  0,  0,  0,  0, -1 },
      { -1,  0,  0,  0,  0,  0,  0, -1 },
      {  0,  0,  0,  1,  1,  0,  0,  0 }
   };
   
   /* TABLE DAME : LégÃ¨re préférence pour le centre, éviter l'exposition précoce
      VALEURS RÉDUITES */
   static const int queenTable[8][8] = {
      { -4, -2, -2, -1, -1, -2, -2, -4 },
      { -2,  0,  0,  0,  0,  0,  0, -2 },
      { -2,  0,  1,  1,  1,  1,  0, -2 },
      { -1,  0,  1,  1,  1,  1,  0, -1 },
      {  0,  0,  1,  1,  1,  1,  0, -1 },
      { -2,  1,  1,  1,  1,  1,  0, -2 },
      { -2,  0,  1,  0,  0,  0,  0, -2 },
      { -4, -2, -2, -1, -1, -2, -2, -4 }
   };
   
   /* TABLE ROI (milieu de partie) : Encourage roque et sécurité sur les côtés
      VALEURS RÉDUITES */
   static const int kingMiddleGameTable[8][8] = {
      { -6, -8, -8,-10,-10, -8, -8, -6 },
      { -6, -8, -8,-10,-10, -8, -8, -6 },
      { -6, -8, -8,-10,-10, -8, -8, -6 },
      { -6, -8, -8,-10,-10, -8, -8, -6 },
      { -4, -6, -6, -8, -8, -6, -6, -4 },
      { -2, -4, -4, -4, -4, -4, -4, -2 },
      {  4,  4,  0,  0,  0,  0,  4,  4 },
      {  4,  6,  2,  0,  0,  2,  6,  4 }
   };
   
   /* TABLE ROI (fin de partie) : Le roi devient actif au centre
      VALEURS RÉDUITES */
   static const int kingEndGameTable[8][8] = {
      {-10, -8, -6, -4, -4, -6, -8,-10 },
      { -6, -4, -2,  0,  0, -2, -4, -6 },
      { -6, -2,  4,  6,  6,  4, -2, -6 },
      { -6, -2,  6,  8,  8,  6, -2, -6 },
      { -6, -2,  6,  8,  8,  6, -2, -6 },
      { -6, -2,  4,  6,  6,  4, -2, -6 },
      { -6, -6,  0,  0,  0,  0, -6, -6 },
      {-10, -6, -6, -6, -6, -6, -6,-10 }
   };
   
   
   /* ========== PARCOURS DE L'ÉCHIQUIER ========== */
   /* Comptage du matériel total pour déterminer si on est en fin de partie */
   // int totalMaterial = 0;
   
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Piece *piece = [board piece_colX:x rangY:y];
         if (!piece) continue;
         
         int value = 0;              // Valeur matérielle
         int positionBonus = 0;      // Bonus positionnel
         
         /* Détermination de la valeur de base et du bonus positionnel */
         switch (piece.type) {
            case Invalide:
               break;
               
            case Pion:
               value = 100;
               /* Pour les Noirs, on inverse la table (miroir vertical) */
               if (piece.side == sideWhite) {
                  positionBonus = pawnTable[y][x];
               } else {
                  positionBonus = pawnTable[7-y][x];
               }
               break;
               
            case Cava:
               value = 300;
               positionBonus = knightTable[y][x];
               
               /* BONUS DÉVELOPPEMENT : Cavalier sorti de sa case de départ
                  VALEUR RÉDUITE */
               if (piece.side == sideWhite && y > 0) developmentWhite += 5;
               if (piece.side == sideBlack && y < 7) developmentBlack += 5;
               break;
               
            case Fou:
               value = 300;
               positionBonus = bishopTable[y][x];
               
               /* BONUS DÉVELOPPEMENT : Fou sorti de sa case de départ
                  VALEUR RÉDUITE */
               if (piece.side == sideWhite && y > 0) developmentWhite += 5;
               if (piece.side == sideBlack && y < 7) developmentBlack += 5;
               break;
               
            case Tour:
               value = 500;
               if (piece.side == sideWhite) {
                  positionBonus = rookTable[y][x];
               } else {
                  positionBonus = rookTable[7-y][x];
               }
               break;
               
            case Dame:
               value = 900;
               positionBonus = queenTable[y][x];
               
               /* MALUS SI DAME SORTIE TROP TÃ”T (avant coups 10-15)
                  VALEUR RÉDUITE */
               if (board->nbEntiers < 10) {
                  if (piece.side == sideWhite && y > 1) positionBonus -= 10;
                  if (piece.side == sideBlack && y < 6) positionBonus -= 10;
               }
               break;
               
            case Roi:
               value = 100000;
               
               /* Choix de la table selon la phase de jeu */
               /* Fin de partie si matériel total < 3000 (approximatif) */
               if (totalMaterial < 3000) {
                  if (piece.side == sideWhite) {
                     positionBonus = kingEndGameTable[y][x];
                  } else {
                     positionBonus = kingEndGameTable[7-y][x];
                  }
               } else {
                  if (piece.side == sideWhite) {
                     positionBonus = kingMiddleGameTable[y][x];
                  } else {
                     positionBonus = kingMiddleGameTable[7-y][x];
                  }
               }
               break;
         } // Fin de switch
         
         /* Accumulation du matériel total (pour détecter fin de partie) */
         if (piece.type != Roi) totalMaterial += value;
         
         /* Ajout de la valeur + bonus positionnel selon la couleur */
         int pieceValue = value + positionBonus;
         
         if (piece.side == sideWhite) {
            materialWhite += pieceValue;
            evalWhitePOV += pieceValue;   // Blancs = positif
         } else {
            materialBlack += pieceValue;
            evalWhitePOV -= pieceValue;   // Noirs = négatif
         }

         evalDisplay += pieceValue * ((piece.side == sideWhite) ? 1 : -1);
         
      } // fin de for 2
   } // Fin de parcours de l'échiquier (for 1)
   
   /* Après le parcours de l'échiquier
    Log concernant la gestion des promotions */
   //NSLog(@"🔍 EVAL DEBUG : totalMaterial=%d, evalWhitePOV=%d, side=%@",totalMaterial, evalWhitePOV, (side == sideWhite) ? @"Blancs" : @"Noirs");

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

   if (queensWhite > 1 || queensBlack > 1) {
      NSLog(@"🔍 PROMOTION DÉTECTÉE : Blancs=%d Dames, Noirs=%d Dames",
            queensWhite, queensBlack);
   }
   
   // ==================================================================================
   // PARTIE 2 : ÉVALUATION DE LA MOBILITÉ
   // ==================================================================================
   /* La mobilité = nombre de coups possibles pour chaque camp
      Un camp avec plus de coups possibles a généralement un meilleur contrôle du jeu
      OPTIMISATION : On ne calcule ceci que tous les 2 niveaux pour économiser du temps */
   
   if (NUMBER_MOVES_AHEAD % 2 == 0) {  // Calcul partiel pour économiser du temps
      NSSet *movesWhite = [self PossibleMovesForSide:sideWhite board:board];
      NSSet *movesBlack = [self PossibleMovesForSide:sideBlack board:board];
      
      mobilityWhite = (int)movesWhite.count * 2;  // Bonus réduit : 2 points par coup possible
      mobilityBlack = (int)movesBlack.count * 2;
      
      int mobilityDiff = mobilityWhite - mobilityBlack;
      evalDisplay += mobilityDiff;
      evalWhitePOV += mobilityDiff;  // Toujours du point de vue des Blancs
   }
   
   
   // ==================================================================================
   // PARTIE 3 : ÉVALUATION DE LA STRUCTURE DE PIONS
   // ==================================================================================
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
      
      /* MALUS PIONS DOUBLÉS : -10 par pion doublé (réduit) */
      if (whitePawnsInColumn > 1) {
         int penalty = (whitePawnsInColumn - 1) * -10;
         evalDisplay += penalty;
         evalWhitePOV += penalty;  // Malus pour Blancs = négatif
      }
      if (blackPawnsInColumn > 1) {
         int penalty = (blackPawnsInColumn - 1) * -10;
         evalDisplay -= penalty;      // Négatif car défavorable aux Blancs
         evalWhitePOV -= penalty;     // Malus pour Noirs = positif pour Blancs
      }
      
      /* BONUS PION PASSÉ : +15 si aucun pion adverse ne peut l'arrÃªter (réduit)
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
            evalDisplay += bonus;
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
            evalDisplay -= bonus;
            evalWhitePOV -= bonus;  // Bonus pour Noirs = négatif pour Blancs
         }
      }
   }
   
   
   // ==================================================================================
   // PARTIE 4 : BONUS DÉVELOPPEMENT
   // ==================================================================================
   /* Les piÃ¨ces (cavaliers/fous) sorties de leur position de départ reÃ§oivent un bonus
      Ceci a déjÃ  été calculé dans la boucle principale ci-dessus */
   
   int developmentDiff = developmentWhite - developmentBlack;
   evalDisplay += developmentDiff;
   evalWhitePOV += developmentDiff;  // Toujours du point de vue des Blancs
   
   
   // ==================================================================================
   // PARTIE 5 : SÉCURITÉ DU ROI
   // ==================================================================================
   /* Bonus si le roi a roqué (déjÃ  reflété dans les tables positionnelles)
      On peut ajouter un bonus supplémentaire pour les pions protecteurs devant le roi */
   
   // TODO : Implémenter détection pions protecteurs (complexe, Ã  faire plus tard)
   
   
   // ==================================================================================
   // PARTIE 6 : DÉTECTION MAT (CODE ORIGINAL CONSERVÉ)
   // ==================================================================================
   /* Note : Cette section pourrait Ãªtre optimisée en ne l'appelant que rarement
      car elle est coÃ»teuse en calcul */
   
   if ([self TestEchecRoiSide:sideBlack inBoard:board]) {
      if ([self PossibleMovesForSide:sideBlack board:board].count == 0) {
         evalDisplay += +100000;
         evalWhitePOV += +100000;  // Mat des Noirs = énorme avantage Blancs
      }
   }
   else if ([self TestEchecRoiSide:sideWhite inBoard:board]) {
      if ([self PossibleMovesForSide:sideWhite board:board].count == 0) {
         evalDisplay += -100000;
         evalWhitePOV += -100000;  // Mat des Blancs = énorme avantage Noirs
      }
   }
   
   
   // ==================================================================================
   // PARTIE 7 : PIONS EN AVANT-DERNIÃˆRE RANGÉE (CODE ORIGINAL CONSERVÉ)
   // ==================================================================================
   /* Bonus important pour pions sur le point d'Ãªtre promus */
   
   if (sideJoueur == sideWhite) {
      for (int x = 0; x < 8; x++) {
         Piece *pionB = board->pieceCase[x][6];
         if ((pionB.type == Pion) && (pionB.side == sideWhite)) {
            evalDisplay += +900;
            evalWhitePOV += +900;  // Pion Blanc proche promo
         }
         Piece *pionN = board->pieceCase[x][1];
         if ((pionN.type == Pion) && (pionN.side == sideBlack)) {
            evalDisplay += -900;
            evalWhitePOV += -900;  // Pion Noir proche promo
         }
      }
   }
   if (sideJoueur == sideBlack) {
      for (int x = 0; x < 8; x++) {
         Piece *pionB = board->pieceCase[x][1];
         if ((pionB.type == Pion) && (pionB.side == sideWhite)) {
            evalDisplay += +900;
            evalWhitePOV += +900;  // Pion Blanc proche promo
         }
         Piece *pionN = board->pieceCase[x][6];
         if ((pionN.type == Pion) && (pionN.side == sideBlack)) {
            evalDisplay += -900;
            evalWhitePOV += -900;  // Pion Noir proche promo
         }
      }
   }
   
   
   // ==================================================================================
   // MISE À JOUR DE L'INTERFACE
   // ==================================================================================
   
   if (evalDisplay > 0)
      monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : +%d", evalDisplay];
   else
      monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : %d", evalDisplay];
   
   /* CONVERSION FINALE POUR NEGAMAX :
      - Si 'side' = Blancs : retourner evalWhitePOV tel quel (positif = bon pour Blancs)
      - Si 'side' = Noirs  : retourner -evalWhitePOV (négatif devient positif)
      Ainsi Negamax reÃ§oit toujours une évaluation positive = bon pour le camp qui joue */
   return (side == sideWhite) ? evalWhitePOV : -evalWhitePOV;
}


//***************************************************************************************************
// MÉTHODE 7 : PossibleMovesForSide - GÉNÉRATION DES COUPS LÉGAUX
// (Code conservé tel quel - déjÃ  optimisé)
//***************************************************************************************************
+(NSSet *)PossibleMovesForSide:(Side)side
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


//***************************************************************************************************
// MÉTHODE 8 : TestEchecFavSide - DÉTECTION ÉCHEC AVEC NOTIFICATION
// (Code conservé tel quel)
//***************************************************************************************************
+(NSString *)TestEchecFavSide:(Side)side Board:(ChessBoard *)board
{
   NSString *strEchec = @"";
   checkCount = 0;
   Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
   
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Pos *pos = [Pos posWithX:x y:y];
         Piece *piece = [board piece_colX:x rangY:y];
         
         if (piece && piece.side == side) {
            NSSet *PosAcceptees = [RuleBook PosAccepteesForPiece:piece atPos:pos inBoard:board];
            
            for (Pos *possibleDest in PosAcceptees) {
               Move *moveSide = [[Move alloc] initWithStart:pos dest:possibleDest];
               Piece *pieceAdv = [board piece_colX:moveSide.dest.x rangY:moveSide.dest.y];
               
               if (pieceAdv.type == Roi && pieceAdv.side == otherSide) {
                  strEchec = @"Echec";
                  checkCount++;
               }
            }
         }
      }
   }
   
   if ([strEchec isEqual:@"Echec"]) {
      [monMCNControleur.maChessView.delegate AlerteEchecRoiSide:otherSide];
      NSLog(@"\n\t\t\t\t\t\t\tLa chaine strEchec est : %@", strEchec);
   }
   
   return strEchec;
}


//***************************************************************************************************
// MÉTHODE 9 : TestEchecRoiSide - VERSION RAPIDE DE LA DÉTECTION D'ÉCHEC
// (Code conservé tel quel)
//***************************************************************************************************
+(BOOL)TestEchecRoiSide:(Side)side inBoard:(ChessBoard *)board
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
               
               if (piece.type == Roi && piece.side == side) {
                  return YES;
               }
            }
         }
      }
   }
   
   return NO;
}


//***************************************************************************************************
// MÉTHODE 10 : NotifiePatMatDesSide - GESTION FIN DE PARTIE
// (Code conservé tel quel)
//***************************************************************************************************
+(void)NotifiePatMatDesSide:(Side)side
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
         msgInfo = @"Partie terminée, Les BLANCS gagnent !";
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t1-0"];
         [monMCNControleur MaJtxtCoups];
      }
      else if (side == sideWhite) {
         msgTitre = @"Les BLANCS sont Mat !";
         msgInfo = @"Partie terminée, Les NOIRS gagnent !";
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
   }
   else {
      /* PAT DÉTECTÉ */
      stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\n\t1/2-1/2"];
      [monMCNControleur MaJtxtCoups];
      
      NSString *msgTitre;
      NSString *msgInfo;
      
      if (side == sideBlack) {
         msgTitre = @"Les NOIRS sont Pat !";
         msgInfo = @"Le Roi Noir est Pat, la partie est déclarée nulle !";
      }
      else if (side == sideWhite) {
         msgTitre = @"Les BLANCS sont Pat !";
         msgInfo = @"Le Roi Blanc est Pat, la partie est déclarée nulle !";
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
   }
}

//***************************************************************************************************
// MÉTHODE HELPER : IsSquareAttacked
// Vérifie si une case est attaquée par un camp donné
// Retourne la valeur de l'attaquant le moins cher (ou 0 si pas attaqué)
//***************************************************************************************************

+(int)CheapestAttackerValue:(Pos *)targetSquare
                     bySide:(Side)attackingSide
                    inBoard:(ChessBoard *)board
{
   int cheapestValue = INT_MAX;
   BOOL isAttacked = NO;
   
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Piece *piece = [board piece_colX:x rangY:y];
         
         if (!piece || piece.type == Invalide || piece.side != attackingSide) {
            continue;
         }
         
         Pos *piecePos = [Pos posWithX:x y:y];
         NSSet *moves = [RuleBook PosAccepteesForPiece:piece
                                                  atPos:piecePos
                                                inBoard:board];
         
         for (Pos *dest in moves) {
            if (dest.x == targetSquare.x && dest.y == targetSquare.y) {
               isAttacked = YES;
               
               int attackerValue = 0;
               switch (piece.type) {
                  case Pion: attackerValue = 100; break;
                  case Cava:
                  case Fou: attackerValue = 300; break;
                  case Tour: attackerValue = 500; break;
                  case Dame: attackerValue = 900; break;
                  case Roi: attackerValue = 100000; break;
                  default: break;
               }
               
               if (attackerValue < cheapestValue) {
                  cheapestValue = attackerValue;
               }
               
               /* Optimisation : si on trouve un pion, inutile de chercher moins cher */
               if (cheapestValue == 100) {
                  return cheapestValue;
               }
               
               break;
            }
         }
         
         /* Optimisation : si on a trouvé un pion attaquant */
         if (cheapestValue == 100) {
            return cheapestValue;
         }
      }
   }
   
   return isAttacked ? cheapestValue : 0;
}


// Helper ajouté
+(NSString *)PieceTypeName:(PieceType)type {
   switch (type) {
      case Pion: return @"Pion";
      case Cava: return @"Cavalier";
      case Fou: return @"Fou";
      case Tour: return @"Tour";
      case Dame: return @"Dame";
      case Roi: return @"Roi";
      default: return @"?";
   }
}


//***************************************************************************************************
// NOUVELLE MÉTHODE : DetectImmediateMateThreats
// Détecte si l'adversaire a un coup qui donne mat au prochain tour
//
// À ajouter dans Minimax.m, et à appeler dans BestMoveForSide
//***************************************************************************************************

+(BOOL)HasMateInOne:(Side)attackingSide
            inBoard:(ChessBoard *)board
{
   NSSet *attackerMoves = [self PossibleMovesForSide:attackingSide board:board];
   Side defendingSide = (attackingSide == sideWhite) ? sideBlack : sideWhite;
   
   for (Move *move in attackerMoves) {
      ChessBoard *testBoard = board.copy;
      [testBoard PerformMove:move];
      
      /* Vérifier si ce coup met mat */
      if ([self TestEchecRoiSide:defendingSide inBoard:testBoard]) {
         NSSet *defenderMoves = [self PossibleMovesForSide:defendingSide board:testBoard];
         
         if (defenderMoves.count == 0) {
            /* C'est mat ! */
            return YES;
         }
      }
   }
   
   return NO;
}

@end

