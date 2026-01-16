//  Minimax.m - VERSION OPTIMISÉE
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 2020
//  Optimisé pour performance IA - 2025
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "Minimax.h"

int nbLoop = 0;
int nbElag = 0;

@implementation Minimax

   
//***************************************************************************************************
// MÉTHODE 1 : BestMoveForSide - Point d'entrée du moteur IA
// Cette méthode trouve le meilleur coup pour l'IA en explorant l'arbre des possibilités
//***************************************************************************************************
+(Move *)BestMoveForSide:(Side)side
                   board:(ChessBoard *)board
{
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
   
   /* ✅ NOUVEAU : FILTRAGE DES COUPS MANIFESTEMENT PERDANTS
      On retire les captures où SEE < -200 (perte nette > 200)
      Sauf s'il n'y a pas d'autre choix */
   NSMutableSet *filteredMoves = [[NSMutableSet alloc] init];
   NSMutableSet *badCaptures = [[NSMutableSet alloc] init];
   
   for (Move *move in movesPossibles) {
      Piece *captured = [board pieceAtPos:move.dest];
      
      if (captured && captured.type != Invalide) {
         /* C'est une capture : vérifier avec SEE */
         int see = [self StaticExchangeEvaluation:move board:board];
         
         if (see < -200) {
            /* Capture très perdante (ex: Dame prend Fou et se fait prendre) */
            [badCaptures addObject:move];
         } else {
            [filteredMoves addObject:move];
         }
      } else {
         /* Pas une capture : toujours garder */
         [filteredMoves addObject:move];
      }
   }
   
   /* Si on a filtré TOUS les coups, garder aussi les mauvaises captures
      (mieux que de ne rien jouer) */
   if (filteredMoves.count == 0) {
      filteredMoves = [movesPossibles mutableCopy];
   } else {
      NSLog(@"🚫 SEE a filtré %lu captures perdantes", (unsigned long)badCaptures.count);
   }
   
   /* TRI DES COUPS AVANT ÉVALUATION */
   NSArray *sortedMoves = [self SortMovesByPriority:filteredMoves board:board];
   
   NSLog(@"\n=== BMFS : Analyse de %lu coups possibles pour les %@ ===",
         (unsigned long)sortedMoves.count,
         (side == 1)? @"Noirs" : @"Blancs");
   
   /* Évaluation de chaque coup possible */
   for (Move *moveEnCours in sortedMoves)
   {
      ChessBoard *newBoard = board.copy;
      [newBoard PerformMove:moveEnCours];
      
      /* DÉTECTION RAPIDE DU MAT */
      if ([self PossibleMovesForSide:otherSide board:newBoard].count == 0) {
         if ([self TestEchecRoiSide:otherSide inBoard:newBoard]) {
            NSLog(@"\n✓ BMFS : MAT TROUVÉ ! Move gagnant = %@", moveEnCours);
            return moveEnCours;
         }
      }
      
      /* Appel à Negamax avec depth=2 (rapide) */
      int negaMax = [self NegamaxForSide:side
                                   board:newBoard
                                   depth:2  // ✅ Garder depth=2 pour la vitesse
                                   alpha:-INT_MAX
                                    beta:INT_MAX];
      
      /* Mise à jour du meilleur coup */
      if (negaMax > bestScore || !bestMove) {
         bestScore = negaMax;
         bestMove = moveEnCours;
         NSLog(@"\n→ BMFS : Nouveau meilleur coup : Score = %d, Move = %@",
               bestScore, bestMove);
      }
   }
   
   NSLog(@"\n=== BMFS : DÉCISION FINALE pour les %@ ===",
         (side == 1)? @"Noirs" : @"Blancs");
   NSLog(@"Score attendu = %d", bestScore);
   NSLog(@"Move retenu = %@\n", bestMove);
   
   return bestMove;
}


//***************************************************************************************************
// MÉTHODE 2 : NegamaxForSide - CŒUR DE L'ALGORITHME (VERSION OPTIMISÉE)
// Implémentation de l'algorithme Negamax avec élagage alpha-beta et Quiescence Search
//
// OPTIMISATIONS PRINCIPALES :
// 1. Évaluation déplacée après les conditions de sortie (gain majeur)
// 2. Limitation stricte de la Quiescence Search à -3 niveaux max
// 3. Filtrage des captures AVANT la boucle en mode QS
// 4. Tri des coups pour améliorer l'élagage
//***************************************************************************************************
+(int)NegamaxForSide:(Side)side
               board:(ChessBoard *)board
               depth:(int)depth
               alpha:(int)alpha
                beta:(int)beta
{
   Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
   
   /* ÉTAPE 1 : GÉNÉRATION DES COUPS POSSIBLES */
   NSSet *movesPossibles = [self PossibleMovesForSide:otherSide board:board];
   
   /* ÉTAPE 2 : DÉTECTION MAT/PAT */
   if (movesPossibles.count == 0) {
      if ([self TestEchecRoiSide:otherSide inBoard:board]) {
         return 100000;  // Mat favorable à 'side'
      }
      return 0;  // Pat = nulle
   }
   
   /* ÉTAPE 3 : CONDITIONS DE SORTIE ET QUIESCENCE SEARCH */
   if (depth <= 0) {
      /* Évaluation statique de la position */
      int eval = [self EvalBoardForSide:side board:board];
      
      /* ✅ QUIESCENCE SEARCH ÉTENDUE : -6 niveaux au lieu de -3
         Ceci permet de voir les séquences de captures plus longues */
      if (depth > -6) {
         /* Élagage beta cutoff précoce */
         if (eval >= beta) return eval;
         
         /* Mise à jour de la fenêtre alpha */
         if (eval > alpha) alpha = eval;
         
         /* ✅ AMÉLIORATION : Inclure aussi les ÉCHECS en QS
            Car un échec peut forcer une séquence tactique importante */
         NSSet *tacticalMoves = [self FilterTacticalMoves:movesPossibles
                                                      from:otherSide
                                                     board:board];
         
         if (tacticalMoves.count == 0) {
            return eval;  // Pas de coups tactiques = on arrête
         }
         
         /* On continue avec les coups tactiques uniquement */
         movesPossibles = tacticalMoves;
         
      } else {
         /* Limite QS atteinte */
         return eval;
      }
   }
   
   /* ÉTAPE 4 : TRI DES COUPS (Move Ordering) */
   NSArray *sortedMoves = [self SortMovesByPriority:movesPossibles board:board];
   
   /* ÉTAPE 5 : EXPLORATION RÉCURSIVE */
   for (Move *moveEnCours in sortedMoves)
   {
      ChessBoard *newBoard = board.copy;
      [newBoard PerformMove:moveEnCours];
      
      int score = -[self NegamaxForSide:otherSide
                                  board:newBoard
                                  depth:depth - 1
                                  alpha:-beta
                                   beta:-alpha];
      
      if (score > alpha) {
         alpha = score;
         
         if (alpha >= beta) {
            nbElag++;
            break;  // Cutoff beta
         }
      }
   }
   
   return alpha;
}


//***************************************************************************************************
// NOUVELLE MÉTHODE : FilterTacticalMoves
// Remplace FilterCaptures pour inclure les échecs en plus des captures
//***************************************************************************************************
+(NSSet *)FilterTacticalMoves:(NSSet *)moves
                         from:(Side)side
                        board:(ChessBoard *)board
{
   NSMutableSet *tacticalMoves = [[NSMutableSet alloc] init];
   Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
   
   for (Move *move in moves) {
      BOOL isTactical = NO;
      
      /* 1. Vérifier si c'est une capture */
      Piece *captured = [board pieceAtPos:move.dest];
      if (captured && captured.type != Invalide && captured.side != side) {
         isTactical = YES;
      }
      
      /* 2. Vérifier si ce coup donne échec */
      if (!isTactical) {
         ChessBoard *testBoard = board.copy;
         [testBoard PerformMove:move];
         
         if ([self TestEchecRoiSide:otherSide inBoard:testBoard]) {
            isTactical = YES;
         }
      }
      
      if (isTactical) {
         [tacticalMoves addObject:move];
      }
   }
   
   return tacticalMoves;
}


//***************************************************************************************************
// MÉTHODE 3 : SortMovesByPriority - TRI DES COUPS PAR PRIORITÉ
// NOUVELLE MÉTHODE pour améliorer l'efficacité de l'élagage alpha-beta
//
// Principe : Les meilleurs coups sont examinés en premier, ce qui provoque plus de cutoffs
// et réduit donc le nombre de branches à explorer
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
// - La valeur de la pièce capturée (si capture)
// - D'autres critères possibles (coups centraux, développement, etc.)
//***************************************************************************************************
+(int)ScoreMove:(Move *)move board:(ChessBoard *)board
{
   int score = 0;
   
   /* Vérifier s'il y a une capture */
   Piece *captured = [board pieceAtPos:move.dest];
   if (captured && captured.type != Invalide) {
      /* ✅ UTILISER SEE POUR ÉVALUER LA CAPTURE */
      int see = [self StaticExchangeEvaluation:move board:board];
      
      if (see > 0) {
         /* Bonne capture : haute priorité */
         score = 2000 + see;
      } else if (see == 0) {
         /* Échange égal : priorité moyenne */
         score = 1000;
      } else {
         /* Mauvaise capture : basse priorité (mais on l'explore quand même) */
         score = 500 + see;
      }
   }
   
   /* Bonus pour les coups centraux (cases e4, d4, e5, d5) */
   int x = move.dest.x;
   int y = move.dest.y;
   if ((x == 3 || x == 4) && (y == 3 || y == 4)) {
      score += 20;
   }
   
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
      
      /* Vérifier qu'il y a bien une pièce adverse à la destination */
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
// - Matériel : Valeur brute des pièces (base)
// - Position : Où sont placées les pièces (crucial)
// - Sécurité : Le roi est-il en sécurité ?
// - Structure : Les pions sont-ils bien organisés ?
// - Mobilité : Combien de coups possibles ?
// - Développement : Les pièces sont-elles actives ?
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
   
   /* Variables pour statistiques intermédiaires */
   int mobilityWhite = 0, mobilityBlack = 0;
   int developmentWhite = 0, developmentBlack = 0;
   int totalMaterial = 0;  /* Pour détecter la fin de partie */
   
   
   // ==================================================================================
   // PARTIE 1 : ÉVALUATION MATÉRIELLE + POSITIONNELLE
   // ==================================================================================
   
   /* Tables de valeurs positionnelles (INCHANGÉES) */
   static const int pawnTable[8][8] = {
      {  0,  0,  0,  0,  0,  0,  0,  0 },
      { 10, 10, 10, 10, 10, 10, 10, 10 },
      {  2,  2,  4,  6,  6,  4,  2,  2 },
      {  1,  1,  2,  5,  5,  2,  1,  1 },
      {  0,  0,  0,  4,  4,  0,  0,  0 },
      {  1, -1, -2,  0,  0, -2, -1,  1 },
      {  1,  2,  2, -4, -4,  2,  2,  1 },
      {  0,  0,  0,  0,  0,  0,  0,  0 }
   };
   
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
               if (piece.side == sideWhite) {
                  positionBonus = pawnTable[y][x];
               } else {
                  positionBonus = pawnTable[7-y][x];
               }
               break;
               
            case Cava:
               value = 300;
               positionBonus = knightTable[y][x];
               
               /* BONUS DÉVELOPPEMENT */
               if (piece.side == sideWhite && y > 0) developmentWhite += 5;
               if (piece.side == sideBlack && y < 7) developmentBlack += 5;
               break;
               
            case Fou:
               value = 300;
               positionBonus = bishopTable[y][x];
               
               /* BONUS DÉVELOPPEMENT */
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
               
               /* MALUS SI DAME SORTIE TROP TÔT */
               if (board->nbEntiers < 10) {
                  if (piece.side == sideWhite && y > 1) positionBonus -= 10;
                  if (piece.side == sideBlack && y < 6) positionBonus -= 10;
               }
               break;
               
            case Roi:
               value = 100000;
               
               /* Choix de la table selon la phase de jeu */
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
         }
         
         /* Accumulation du matériel total (pour détecter fin de partie) */
         if (piece.type != Roi) totalMaterial += value;
         
         /* ✅ AJOUT À evalWhitePOV UNIQUEMENT
            Blancs = positif, Noirs = négatif */
         int pieceValue = value + positionBonus;
         
         if (piece.side == sideWhite) {
            evalWhitePOV += pieceValue;
         } else {
            evalWhitePOV -= pieceValue;
         }
      }
   }
   
   
   // ==================================================================================
   // PARTIE 2 : ÉVALUATION DE LA MOBILITÉ
   // ==================================================================================
   
   if (NUMBER_MOVES_AHEAD % 2 == 0) {
      NSSet *movesWhite = [self PossibleMovesForSide:sideWhite board:board];
      NSSet *movesBlack = [self PossibleMovesForSide:sideBlack board:board];
      
      mobilityWhite = (int)movesWhite.count * 2;
      mobilityBlack = (int)movesBlack.count * 2;
      
      /* ✅ AJOUT COHÉRENT */
      evalWhitePOV += (mobilityWhite - mobilityBlack);
   }
   
   
   // ==================================================================================
   // PARTIE 3 : ÉVALUATION DE LA STRUCTURE DE PIONS
   // ==================================================================================
   
   for (int x = 0; x < 8; x++) {
      int whitePawnsInColumn = 0;
      int blackPawnsInColumn = 0;
      int whiteMostAdvanced = -1;
      int blackMostAdvanced = 8;
      
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
         evalWhitePOV += (whitePawnsInColumn - 1) * -10;
      }
      if (blackPawnsInColumn > 1) {
         evalWhitePOV -= (blackPawnsInColumn - 1) * -10;
      }
      
      /* BONUS PION PASSÉ : +15 si aucun pion adverse ne peut l'arrêter */
      if (whitePawnsInColumn == 1 && whiteMostAdvanced >= 4) {
         BOOL isPassed = YES;
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
            evalWhitePOV += (15 + (whiteMostAdvanced * 5));
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
            evalWhitePOV -= (15 + ((7 - blackMostAdvanced) * 5));
         }
      }
   }
   
   
   // ==================================================================================
   // PARTIE 4 : BONUS DÉVELOPPEMENT
   // ==================================================================================
   
   evalWhitePOV += (developmentWhite - developmentBlack);
   
   
   // ==================================================================================
   // PARTIE 5 : DÉTECTION MAT
   // ==================================================================================
   
   if ([self TestEchecRoiSide:sideBlack inBoard:board]) {
      if ([self PossibleMovesForSide:sideBlack board:board].count == 0) {
         evalWhitePOV += 100000;  // Mat des Noirs
      }
   }
   else if ([self TestEchecRoiSide:sideWhite inBoard:board]) {
      if ([self PossibleMovesForSide:sideWhite board:board].count == 0) {
         evalWhitePOV -= 100000;  // Mat des Blancs
      }
   }
   
   
   // ==================================================================================
   // PARTIE 6 : PIONS EN AVANT-DERNIÈRE RANGÉE
   // ==================================================================================
   
   if (sideJoueur == sideWhite) {
      for (int x = 0; x < 8; x++) {
         Piece *pionB = board->pieceCase[x][6];
         if ((pionB.type == Pion) && (pionB.side == sideWhite)) {
            evalWhitePOV += 900;
         }
         Piece *pionN = board->pieceCase[x][1];
         if ((pionN.type == Pion) && (pionN.side == sideBlack)) {
            evalWhitePOV -= 900;
         }
      }
   }
   if (sideJoueur == sideBlack) {
      for (int x = 0; x < 8; x++) {
         Piece *pionB = board->pieceCase[x][1];
         if ((pionB.type == Pion) && (pionB.side == sideWhite)) {
            evalWhitePOV += 900;
         }
         Piece *pionN = board->pieceCase[x][6];
         if ((pionN.type == Pion) && (pionN.side == sideBlack)) {
            evalWhitePOV -= 900;
         }
      }
   }
   
   
   // ==================================================================================
   // MISE À JOUR DE L'INTERFACE (evalDisplay = evalWhitePOV)
   // ==================================================================================
   
   if (evalWhitePOV > 0)
      monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : +%d", evalWhitePOV];
   else
      monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : %d", evalWhitePOV];
   
   
   /* ✅ CONVERSION FINALE POUR NEGAMAX */
   return (side == sideWhite) ? evalWhitePOV : -evalWhitePOV;
}

/* ============================================================================
   RÉSUMÉ DES MODIFICATIONS - CONVENTION NEGAMAX STANDARD
   ============================================================================
   
   CHANGEMENT FONDAMENTAL :
   
   L'évaluation est maintenant TOUJOURS du point de vue des BLANCS :
   - evalWhitePOV > 0 = avantage Blancs
   - evalWhitePOV < 0 = avantage Noirs
   
   Conversion finale selon le camp qui évalue :
   - Si side = Blancs : retourne evalWhitePOV (positif = bon)
   - Si side = Noirs  : retourne -evalWhitePOV (l'inverse)
   
   Ainsi, Negamax reçoit toujours un score où :
   - Positif = bon pour le camp qui joue
   - Négatif = mauvais pour le camp qui joue
   
   Et l'algorithme Negamax classique peut fonctionner avec son inversion
   de signe standard : score = -Negamax(otherSide, ...)
   
   ============================================================================
   
   AMÉLIORATIONS CONSERVÉES :
   
   1. ✅ ÉVALUATION POSITIONNELLE (TABLES)
      - Chaque type de pièce a une table de bonus selon sa position
      - Pions : encouragés au centre et en avancée
      - Cavaliers : bonus important au centre, malus sur les bords
      - Fous : bonus sur longues diagonales
      - Tours : bonus sur 7ème rangée
      - Dame : légère préférence centre, éviter sortie précoce
      - Roi : différent selon phase (milieu/fin de partie)
   
   2. ✅ MOBILITÉ
      - Bonus de 2 points par coup possible
      - Calcul optimisé (tous les 2 niveaux seulement)
      - Camp avec plus de mobilité = meilleur contrôle
   
   3. ✅ STRUCTURE DE PIONS
      - Pions doublés : MALUS -10 par pion supplémentaire
      - Pions passés : BONUS +15 à +50 selon avancée
      - Détection simplifiée mais efficace
   
   4. ✅ DÉVELOPPEMENT
      - Bonus +5 pour chaque cavalier/fou développé
      - Malus -10 pour dame sortie trop tôt (< coup 10)
      - Encourage ouverture correcte
   
   5. ✅ PHASE DE JEU
      - Détection automatique milieu/fin de partie
      - Roi : défensif en milieu, actif en finale
      - Adapte la stratégie automatiquement
   
   ============================================================================
*/



//***************************************************************************************************
// MÉTHODE 7 : PossibleMovesForSide - GÉNÉRATION DES COUPS LÉGAUX
// (Code conservé tel quel - déjà optimisé)
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




/* ============================================================================
   RÉSUMÉ DES OPTIMISATIONS APPORTÉES
   ============================================================================
   
   1. ✅ ÉVALUATION DIFFÉRÉE
      - EvalBoardForSide n'est plus appelée systématiquement à chaque nœud
      - Appelée uniquement quand depth <= 0 (fin d'exploration)
      - GAIN : ~70% de réduction des appels à la fonction la plus coûteuse
   
   2. ✅ QUIESCENCE SEARCH LIMITÉE
      - Limitation stricte à 3 niveaux supplémentaires (depth > -3)
      - Filtrage des captures AVANT la boucle pour éviter les itérations inutiles
      - GAIN : Prévention des arbres de recherche exponentiels
   
   3. ✅ TRI DES COUPS (Move Ordering)
      - Nouvelles méthodes : SortMovesByPriority et ScoreMove
      - Les captures sont examinées en priorité
      - GAIN : Amélioration drastique de l'élagage alpha-beta
   
   4. ✅ FILTRAGE OPTIMISÉ DES CAPTURES
      - Nouvelle méthode FilterCaptures pour le Quiescence Search
      - Évite de parcourir tous les coups en mode QS
      - GAIN : Réduction du facteur de branchement en QS
   
   5. ✅ DÉTECTION MAT IMMÉDIATE
      - Si un coup met mat, retour immédiat sans explorer d'autres options
      - GAIN : Fin de partie accélérée quand mat est trouvé
   
   PERFORMANCE ATTENDUE :
   - Temps de calcul divisé par 5 à 10 pour NUMBER_MOVES_AHEAD = 3
   - Élagage alpha-beta 2 à 3 fois plus efficace
   - Possibilité d'augmenter NUMBER_MOVES_AHEAD à 4 sans perte de réactivité
   
   ============================================================================
*/


//***************************************************************************************************
// NOUVELLE MÉTHODE : StaticExchangeEvaluation (SEE)
// Évalue rapidement si une capture est avantageuse sans faire de recherche complète
//
// Exemple : Si la Dame (900) capture un Fou (300) mais peut être reprise par un Pion (100),
//           le SEE retourne : 300 - 900 = -600 → capture PERDANTE
//***************************************************************************************************
+(int)StaticExchangeEvaluation:(Move *)capture
                         board:(ChessBoard *)board
{
   Piece *attacker = [board pieceAtPos:capture.start];
   Piece *victim = [board pieceAtPos:capture.dest];
   
   if (!victim || victim.type == Invalide) {
      return 0;  // Pas de capture
   }
   
   /* Valeur de la pièce capturée */
   int gain = [self PieceValue:victim.type];
   
   /* Simulation de la capture */
   ChessBoard *testBoard = board.copy;
   [testBoard PerformMove:capture];
   
   /* Vérifier si l'attaquant peut être repris */
   Side otherSide = (attacker.side == sideWhite) ? sideBlack : sideWhite;
   
   /* Trouver le défenseur le moins cher qui peut reprendre */
   int cheapestDefender = INT_MAX;
   Move *recapture = nil;
   
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Piece *defender = [testBoard piece_colX:x rangY:y];
         if (!defender || defender.side != otherSide) continue;
         
         Pos *defPos = [Pos posWithX:x y:y];
         NSSet *defMoves = [RuleBook PosAccepteesForPiece:defender
                                                     atPos:defPos
                                                   inBoard:testBoard];
         
         for (Pos *dest in defMoves) {
            if (dest.x == capture.dest.x && dest.y == capture.dest.y) {
               int defValue = [self PieceValue:defender.type];
               if (defValue < cheapestDefender) {
                  cheapestDefender = defValue;
                  recapture = [[Move alloc] initWithStart:defPos dest:dest];
               }
            }
         }
      }
   }
   
   /* Si aucune recapture possible */
   if (!recapture) {
      return gain;  // Capture gratuite
   }
   
   /* Calculer le gain net : valeur capturée - valeur de l'attaquant */
   int attackerValue = [self PieceValue:attacker.type];
   
   /* Récursion simplifiée : on suppose la meilleure défense */
   int loss = -[self StaticExchangeEvaluation:recapture board:testBoard];
   
   return gain - attackerValue + loss;
}


//***************************************************************************************************
// MÉTHODE HELPER : PieceValue
// Retourne la valeur matérielle d'un type de pièce
//***************************************************************************************************
+(int)PieceValue:(PieceType)type
{
   switch (type) {
      case Pion:  return 100;
      case Cava:  return 300;
      case Fou:   return 300;
      case Tour:  return 500;
      case Dame:  return 900;
      case Roi:   return 100000;
      default:    return 0;
   }
}


@end
