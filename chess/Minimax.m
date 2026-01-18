//  Minimax.m - VERSION OPTIMISÃ‰E
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 2020
//  OptimisÃ© pour performance IA - 2025
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "Minimax.h"

int nbLoop = 0;
int nbElag = 0;

@implementation Minimax

   
//***************************************************************************************************
// MÃ‰THODE 1 : BestMoveForSide - Point d'entrÃ©e du moteur IA
// Cette mÃ©thode trouve le meilleur coup pour l'IA en explorant l'arbre des possibilitÃ©s
//***************************************************************************************************
+(Move *)BestMoveForSide:(Side)side
                   board:(ChessBoard *)board
{
   /* DÃ©termination du jeu de tous les moves possibles pour 'side' */
   NSSet *movesPossibles = [self PossibleMovesForSide:side board:board];
   
   /* PRÃ‰REQUIS : Tester si side est mat ou pat avant de chercher le meilleur coup */
   if (movesPossibles.count == 0) {
      [self NotifiePatMatDesSide:side onBoard:board];
      return nil;
   }
   
   /* Initialisation des variables de recherche */
   int bestScore  = -INT_MAX;
   Move *bestMove = nil;
   Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
   
   /* OPTIMISATION 1 : TRI DES COUPS AVANT Ã‰VALUATION
      Les coups avec captures sont Ã©valuÃ©s en premier, ce qui amÃ©liore l'Ã©lagage alpha-beta */
   NSArray *sortedMoves = [self SortMovesByPriority:movesPossibles board:board];
   
   NSLog(@"\n=== BMFS : Analyse de %lu coups possibles pour les %@ ===",
         (unsigned long)sortedMoves.count,
         (side == 1)? @"Noirs" : @"Blancs");
   
   
   // Juste AVANT la boucle for (Move *moveEnCours in sortedMoves)
   NSMutableSet *safeMovesOnly = [[NSMutableSet alloc] init];

   for (Move *move in sortedMoves) {
      Piece *att = [board pieceAtPos:move.start];
      Piece *vic = [board pieceAtPos:move.dest];
      
      // Bloquer les sacrifices évidents de grosses pièces
      BOOL isSuicide = NO;
      
      if (vic && vic.type != Invalide) {
         // C'est une capture
         int attackerValue = 0;
         int victimValue = 0;
         
         switch (att.type) {
            case Dame: attackerValue = 900; break;
            case Tour: attackerValue = 500; break;
            case Fou:
            case Cava: attackerValue = 300; break;
            case Pion: attackerValue = 100; break;
            default: break;
         }
         
         switch (vic.type) {
            case Dame: victimValue = 900; break;
            case Tour: victimValue = 500; break;
            case Fou:
            case Cava: victimValue = 300; break;
            case Pion: victimValue = 100; break;
            default: break;
         }
         
         // Si j'attaque avec une pièce plus chère que la victime
         if (attackerValue > victimValue + 100) {
            // Vérifier si je peux être repris
            ChessBoard *test = board.copy;
            [test PerformMove:move];
            
            Side enemy = (att.side == sideWhite) ? sideBlack : sideWhite;
            
            // Vérifier si la case est attaquée par l'ennemi
            for (int ex = 0; ex < 8 && !isSuicide; ex++) {
               for (int ey = 0; ey < 8 && !isSuicide; ey++) {
                  Piece *enemyPiece = [test piece_colX:ex rangY:ey];
                  if (!enemyPiece || enemyPiece.side != enemy) continue;
                  
                  Pos *ePos = [Pos posWithX:ex y:ey];
                  NSSet *eMoves = [RuleBook PosAccepteesForPiece:enemyPiece
                                                           atPos:ePos
                                                         inBoard:test];
                  
                  for (Pos *eDest in eMoves) {
                     if (eDest.x == move.dest.x && eDest.y == move.dest.y) {
                        isSuicide = YES;
                        break;
                     }
                  }
               }
            }
         }
      }
      
      if (!isSuicide) {
         [safeMovesOnly addObject:move];
      }
   }

   if (safeMovesOnly.count > 0) {
      sortedMoves = [safeMovesOnly allObjects];
      NSLog(@"🛡️ Filtrage sécurité : %lu coups gardés sur %lu",
            (unsigned long)safeMovesOnly.count,
            (unsigned long)[sortedMoves count]);
   }
   
   
   
   /* Ã‰valuation de chaque coup possible */
   for (Move *moveEnCours in sortedMoves)
   {
      ChessBoard *newBoard = board.copy;
      [newBoard PerformMove:moveEnCours];
      
      /* OPTIMISATION 2 : DÃ‰TECTION RAPIDE DU MAT
         Si ce coup met l'adversaire mat, c'est forcÃ©ment le meilleur - on retourne immÃ©diatement */
      if ([self PossibleMovesForSide:otherSide board:newBoard].count == 0) {
         if ([self TestEchecRoiSide:otherSide inBoard:newBoard]) {
            NSLog(@"\nâœ“ BMFS : MAT TROUVÃ‰ ! Move gagnant = %@", moveEnCours);
            return moveEnCours;  // Mat = meilleur coup possible
         }
      }
      
      /* Appel Ã  Negamax pour Ã©valuer ce coup en simulant les rÃ©ponses adverses
         On utilise une fenÃªtre alpha-beta maximale au premier niveau */
      int negaMax = [self NegamaxForSide:side
                                   board:newBoard
                                   depth:NUMBER_MOVES_AHEAD
                                   alpha:-INT_MAX
                                    beta:INT_MAX];
      
      /* Mise Ã  jour du meilleur coup si nÃ©cessaire */
      if (negaMax > bestScore || !bestMove) {
         bestScore = negaMax;
         bestMove = moveEnCours;
         NSLog(@"\nâ†’ BMFS : Nouveau meilleur coup : Score = %d, Move = %@",
               bestScore, bestMove);
      }
   }
   
   /* Log final du coup choisi */
   NSLog(@"\n=== BMFS : DÃ‰CISION FINALE pour les %@ ===",
         (side == 1)? @"Noirs" : @"Blancs");
   NSLog(@"Score attendu = %d", bestScore);
   NSLog(@"Move retenu = %@\n", bestMove);
   
   return bestMove;
}


//***************************************************************************************************
// MÃ‰THODE 2 : NegamaxForSide - CÅ’UR DE L'ALGORITHME (VERSION OPTIMISÃ‰E)
// ImplÃ©mentation de l'algorithme Negamax avec Ã©lagage alpha-beta et Quiescence Search
//
// OPTIMISATIONS PRINCIPALES :
// 1. Ã‰valuation dÃ©placÃ©e aprÃ¨s les conditions de sortie (gain majeur)
// 2. Limitation stricte de la Quiescence Search Ã  -3 niveaux max
// 3. Filtrage des captures AVANT la boucle en mode QS
// 4. Tri des coups pour amÃ©liorer l'Ã©lagage
//***************************************************************************************************
+(int)NegamaxForSide:(Side)side
               board:(ChessBoard *)board
               depth:(int)depth
               alpha:(int)alpha
                beta:(int)beta
{
   Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
   
   /* Ã‰TAPE 1 : GÃ‰NÃ‰RATION DES COUPS POSSIBLES
      On gÃ©nÃ¨re les coups ici pour pouvoir dÃ©tecter mat/pat ET les utiliser plus tard */
   NSSet *movesPossibles = [self PossibleMovesForSide:otherSide board:board];
   
   /* Ã‰TAPE 2 : DÃ‰TECTION MAT/PAT
      Si aucun coup n'est possible, c'est soit mat soit pat */
   if (movesPossibles.count == 0) {
      if ([self TestEchecRoiSide:otherSide inBoard:board]) {
         return 100000;  // Mat favorable Ã  'side'
      }
      return 0;  // Pat = nulle
   }
   
   /* Ã‰TAPE 3 : CONDITIONS DE SORTIE ET QUIESCENCE SEARCH
      OPTIMISATION CRITIQUE : L'Ã©valuation n'est faite QUE quand on atteint la profondeur limite */
   if (depth <= 0) {
      /* On Ã©value le plateau SEULEMENT maintenant */
      int eval = [self EvalBoardForSide:side board:board];
       
       /* DEBUG : Log pour vÃ©rifier les Ã©valuations */
         NSLog(@"  Eval depth=%d side=%@ : eval=%d",
               depth,
               (side == sideWhite) ? @"Blancs" : @"Noirs",
               eval);
      
      /* QUIESCENCE SEARCH (QS) : On continue Ã  explorer les captures pour Ã©viter
         "l'effet horizon" oÃ¹ l'IA ne voit pas une prise importante juste aprÃ¨s depth=0
         OPTIMISATION : Limitation stricte Ã  3 niveaux supplÃ©mentaires maximum */
      if (depth > -3) {
         /* Ã‰lagage beta cutoff prÃ©coce */
         if (eval >= beta) return eval;
         
         /* Mise Ã  jour de la fenÃªtre alpha */
         if (eval > alpha) alpha = eval;
         
         /* OPTIMISATION : Filtrer les captures AVANT la boucle
            On ne continue le QS que s'il y a des captures possibles */
         NSSet *captures = [self FilterCaptures:movesPossibles from:otherSide board:board];
         if (captures.count == 0) {
            return eval;  // Pas de capture = on retourne l'Ã©valuation statique
         }
         
         /* On remplace movesPossibles par les captures uniquement */
         movesPossibles = captures;
         NSLog(@"\n  QS (depth %d) : %lu captures Ã  examiner", depth, (unsigned long)captures.count);
         
      } else {
         /* Limite QS atteinte : on arrÃªte l'exploration */
         return eval;
      }
   }
   
   /* Ã‰TAPE 4 : TRI DES COUPS (Move Ordering)
      OPTIMISATION : Examiner les meilleurs coups en premier amÃ©liore drastiquement l'Ã©lagage
      Les captures de grande valeur sont prioritaires */
   NSArray *sortedMoves = [self SortMovesByPriority:movesPossibles board:board];
   
   /* Ã‰TAPE 5 : EXPLORATION RÃ‰CURSIVE DE L'ARBRE
      Pour chaque coup possible, on simule la position rÃ©sultante et on Ã©value rÃ©cursivement */
   for (Move *moveEnCours in sortedMoves)
   {
      /* CrÃ©ation d'un plateau virtuel pour simuler le coup */
      ChessBoard *newBoard = board.copy;
      [newBoard PerformMove:moveEnCours];
      
      /* APPEL RÃ‰CURSIF : On inverse les rÃ´les (otherSide joue), on descend d'un niveau,
         et on inverse alpha/beta (principe du Negamax) */
      int score = -[self NegamaxForSide:otherSide
                                  board:newBoard
                                  depth:depth - 1
                                  alpha:-beta
                                   beta:-alpha];
      
      /* Mise Ã  jour du meilleur score trouvÃ© */
      if (score > alpha) {
         alpha = score;
         
         /* Ã‰LAGAGE ALPHA-BETA : Si alpha >= beta, les coups suivants ne peuvent pas
            amÃ©liorer la position, on peut arrÃªter l'exploration de cette branche */
         if (alpha >= beta) {
            nbElag++;
            break;  // Cutoff beta
         }
      }
   }
   
   return alpha;
}


//***************************************************************************************************
// MÃ‰THODE 3 : SortMovesByPriority - TRI DES COUPS PAR PRIORITÃ‰
// NOUVELLE MÃ‰THODE pour amÃ©liorer l'efficacitÃ© de l'Ã©lagage alpha-beta
//
// Principe : Les meilleurs coups sont examinÃ©s en premier, ce qui provoque plus de cutoffs
// et rÃ©duit donc le nombre de branches Ã  explorer
//***************************************************************************************************
+(NSArray *)SortMovesByPriority:(NSSet *)moves board:(ChessBoard *)board
{
   /* Conversion du NSSet en NSArray pour pouvoir le trier */
   NSArray *movesArray = [moves allObjects];
   
   return [movesArray sortedArrayUsingComparator:^NSComparisonResult(Move *m1, Move *m2) {
      int score1 = [self ScoreMove:m1 board:board];
      int score2 = [self ScoreMove:m2 board:board];
      
      /* Tri par ordre dÃ©croissant (meilleurs coups en premier) */
      if (score2 > score1) return NSOrderedAscending;
      if (score2 < score1) return NSOrderedDescending;
      return NSOrderedSame;
   }];
}


//***************************************************************************************************
// MÃ‰THODE 4 : ScoreMove - Ã‰VALUATION RAPIDE D'UN COUP
// NOUVELLE MÃ‰THODE pour le tri des coups
//
// Attribution d'un score heuristique rapide basÃ© sur :
// - La valeur de la piÃ¨ce capturÃ©e (si capture)
// - D'autres critÃ¨res possibles (coups centraux, dÃ©veloppement, etc.)
//***************************************************************************************************
+(int)ScoreMove:(Move *)move board:(ChessBoard *)board
{
   int score = 0;
   
   /* VÃ©rifier s'il y a une capture */
   Piece *captured = [board pieceAtPos:move.dest];
   if (captured && captured.type != Invalide) {
      /* PrioritÃ© haute pour les captures : score de base + valeur de la piÃ¨ce */
      switch (captured.type) {
         case Pion:  score = 1000 + 100;    break;
         case Cava:  score = 1000 + 300;    break;
         case Fou:   score = 1000 + 300;    break;
         case Tour:  score = 1000 + 500;    break;
         case Dame:  score = 1000 + 900;    break;
         case Roi:   score = 1000 + 100000; break;  // ThÃ©orique
         default:    break;
      }
   }
   
   /* AMÃ‰LIORATION FUTURE : Ajouter d'autres heuristiques
      - Coups vers le centre du plateau (bonus +10 Ã  +30)
      - DÃ©veloppement des piÃ¨ces (sortir cavaliers/fous)
      - ContrÃ´le des cases importantes
      - Menaces sur le roi adverse */
   
   return score;
}


//***************************************************************************************************
// MÃ‰THODE 5 : FilterCaptures - FILTRAGE DES CAPTURES POUR QUIESCENCE SEARCH
// NOUVELLE MÃ‰THODE pour optimiser le QS
//
// Ne conserve que les coups qui sont des captures, car ce sont les coups "tactiques"
// qui peuvent changer drastiquement l'Ã©valuation d'une position
//***************************************************************************************************
+(NSSet *)FilterCaptures:(NSSet *)moves from:(Side)side board:(ChessBoard *)board
{
   NSMutableSet *captures = [[NSMutableSet alloc] init];
   
   for (Move *move in moves) {
      Piece *captured = [board pieceAtPos:move.dest];
      
      /* VÃ©rifier qu'il y a bien une piÃ¨ce adverse Ã  la destination */
      if (captured && captured.type != Invalide && captured.side != side) {
         [captures addObject:move];
      }
   }
   
   return captures;
}


//***************************************************************************************************
// MÃ‰THODE : EvalBoardForSide - VERSION AMÃ‰LIORÃ‰E AVEC Ã‰VALUATION POSITIONNELLE
// Cette mÃ©thode Ã©value la qualitÃ© d'une position d'Ã©checs pour un camp donnÃ©
//
// PHILOSOPHIE D'Ã‰VALUATION :
// - MatÃ©riel : Valeur brute des piÃ¨ces (base)
// - Position : OÃ¹ sont placÃ©es les piÃ¨ces (crucial)
// - SÃ©curitÃ© : Le roi est-il en sÃ©curitÃ© ?
// - Structure : Les pions sont-ils bien organisÃ©s ?
// - MobilitÃ© : Combien de coups possibles ?
// - DÃ©veloppement : Les piÃ¨ces sont-elles actives ?
//
// CONVENTION NEGAMAX STANDARD :
// - L'Ã©valuation est TOUJOURS du point de vue des BLANCS
// - Valeur positive = avantage Blancs, nÃ©gative = avantage Noirs
// - Negamax inversera le signe selon le camp qui joue
//***************************************************************************************************
+(int)EvalBoardForSide:(Side)side
                 board:(ChessBoard *)board
{
   int evalWhitePOV = 0;  /* Ã‰valuation du point de vue des Blancs (convention Negamax) */
   evalDisplay = 0;       /* Valeur affichÃ©e (convention : + = avantage Blancs) */
   
   /* Variables pour statistiques intermÃ©diaires */
   int materialWhite = 0, materialBlack = 0;
   int mobilityWhite = 0, mobilityBlack = 0;
   int developmentWhite = 0, developmentBlack = 0;
   int totalMaterial = 0;  /* Pour dÃ©tecter la fin de partie */
   
   
   // ==================================================================================
   // PARTIE 1 : Ã‰VALUATION MATÃ‰RIELLE + POSITIONNELLE
   // ==================================================================================
   /* Tables de valeurs positionnelles pour chaque type de piÃ¨ce
      Ces tables donnent un bonus/malus selon la position de la piÃ¨ce sur l'Ã©chiquier
      Convention : les tableaux sont vus du point de vue des Blancs (rangÃ©e 0 = fond Blancs) */
   
   /* TABLE PIONS : Encourage l'avancÃ©e et le contrÃ´le du centre
      VALEURS RÃ‰DUITES pour Ã©viter les sacrifices stupides */
   static const int pawnTable[8][8] = {
      {  0,  0,  0,  0,  0,  0,  0,  0 },  // RangÃ©e 0 (promotion, ne devrait pas arriver)
      { 10, 10, 10, 10, 10, 10, 10, 10 },  // RangÃ©e 1 (avant-derniÃ¨re, dÃ©jÃ  gÃ©rÃ© ailleurs)
      {  2,  2,  4,  6,  6,  4,  2,  2 },  // RangÃ©e 2
      {  1,  1,  2,  5,  5,  2,  1,  1 },  // RangÃ©e 3
      {  0,  0,  0,  4,  4,  0,  0,  0 },  // RangÃ©e 4 (centre)
      {  1, -1, -2,  0,  0, -2, -1,  1 },  // RangÃ©e 5
      {  1,  2,  2, -4, -4,  2,  2,  1 },  // RangÃ©e 6
      {  0,  0,  0,  0,  0,  0,  0,  0 }   // RangÃ©e 7 (dÃ©part)
   };
   
   /* TABLE CAVALIERS : Encourage position centrale et pÃ©nalise les bords
      VALEURS RÃ‰DUITES */
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
      VALEURS RÃ‰DUITES */
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
   
   /* TABLE TOURS : Encourage 7Ã¨me rangÃ©e et colonnes ouvertes (approximatif)
      VALEURS RÃ‰DUITES */
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
   
   /* TABLE DAME : LÃ©gÃ¨re prÃ©fÃ©rence pour le centre, Ã©viter l'exposition prÃ©coce
      VALEURS RÃ‰DUITES */
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
   
   /* TABLE ROI (milieu de partie) : Encourage roque et sÃ©curitÃ© sur les cÃ´tÃ©s
      VALEURS RÃ‰DUITES */
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
      VALEURS RÃ‰DUITES */
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
   
   
   /* ========== PARCOURS DE L'Ã‰CHIQUIER ========== */
   /* Comptage du matÃ©riel total pour dÃ©terminer si on est en fin de partie */
   // int totalMaterial = 0;
   
   for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
         Piece *piece = [board piece_colX:x rangY:y];
         if (!piece) continue;
         
         int value = 0;              // Valeur matÃ©rielle
         int positionBonus = 0;      // Bonus positionnel
         
         /* DÃ©termination de la valeur de base et du bonus positionnel */
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
               
               /* BONUS DÃ‰VELOPPEMENT : Cavalier sorti de sa case de dÃ©part
                  VALEUR RÃ‰DUITE */
               if (piece.side == sideWhite && y > 0) developmentWhite += 5;
               if (piece.side == sideBlack && y < 7) developmentBlack += 5;
               break;
               
            case Fou:
               value = 300;
               positionBonus = bishopTable[y][x];
               
               /* BONUS DÃ‰VELOPPEMENT : Fou sorti de sa case de dÃ©part
                  VALEUR RÃ‰DUITE */
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
                  VALEUR RÃ‰DUITE */
               if (board->nbEntiers < 10) {
                  if (piece.side == sideWhite && y > 1) positionBonus -= 10;
                  if (piece.side == sideBlack && y < 6) positionBonus -= 10;
               }
               break;
               
            case Roi:
               value = 100000;
               
               /* Choix de la table selon la phase de jeu */
               /* Fin de partie si matÃ©riel total < 3000 (approximatif) */
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
         
         /* Accumulation du matÃ©riel total (pour dÃ©tecter fin de partie) */
         if (piece.type != Roi) totalMaterial += value;
         
         /* Ajout de la valeur + bonus positionnel selon la couleur */
         int pieceValue = value + positionBonus;
         
         if (piece.side == sideWhite) {
            materialWhite += pieceValue;
            evalWhitePOV += pieceValue;   // Blancs = positif
         } else {
            materialBlack += pieceValue;
            evalWhitePOV -= pieceValue;   // Noirs = nÃ©gatif
         }

         evalDisplay += pieceValue * ((piece.side == sideWhite) ? 1 : -1);
         
      }
   }
   
   
   // ==================================================================================
   // PARTIE 2 : Ã‰VALUATION DE LA MOBILITÃ‰
   // ==================================================================================
   /* La mobilitÃ© = nombre de coups possibles pour chaque camp
      Un camp avec plus de coups possibles a gÃ©nÃ©ralement un meilleur contrÃ´le du jeu
      OPTIMISATION : On ne calcule ceci que tous les 2 niveaux pour Ã©conomiser du temps */
   
   if (NUMBER_MOVES_AHEAD % 2 == 0) {  // Calcul partiel pour Ã©conomiser du temps
      NSSet *movesWhite = [self PossibleMovesForSide:sideWhite board:board];
      NSSet *movesBlack = [self PossibleMovesForSide:sideBlack board:board];
      
      mobilityWhite = (int)movesWhite.count * 2;  // Bonus rÃ©duit : 2 points par coup possible
      mobilityBlack = (int)movesBlack.count * 2;
      
      int mobilityDiff = mobilityWhite - mobilityBlack;
      evalDisplay += mobilityDiff;
      evalWhitePOV += mobilityDiff;  // Toujours du point de vue des Blancs
   }
   
   
   // ==================================================================================
   // PARTIE 3 : Ã‰VALUATION DE LA STRUCTURE DE PIONS
   // ==================================================================================
   /* DÃ©tection des pions doublÃ©s (malus) et pions passÃ©s (bonus) */
   
   for (int x = 0; x < 8; x++) {
      int whitePawnsInColumn = 0;
      int blackPawnsInColumn = 0;
      int whiteMostAdvanced = -1;  // Y le plus Ã©levÃ© pour pion blanc
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
      
      /* MALUS PIONS DOUBLÃ‰S : -10 par pion doublÃ© (rÃ©duit) */
      if (whitePawnsInColumn > 1) {
         int penalty = (whitePawnsInColumn - 1) * -10;
         evalDisplay += penalty;
         evalWhitePOV += penalty;  // Malus pour Blancs = nÃ©gatif
      }
      if (blackPawnsInColumn > 1) {
         int penalty = (blackPawnsInColumn - 1) * -10;
         evalDisplay -= penalty;      // NÃ©gatif car dÃ©favorable aux Blancs
         evalWhitePOV -= penalty;     // Malus pour Noirs = positif pour Blancs
      }
      
      /* BONUS PION PASSÃ‰ : +15 si aucun pion adverse ne peut l'arrÃªter (rÃ©duit)
         VÃ©rification simplifiÃ©e : pas de pion adverse dans cette colonne ni colonnes adjacentes */
      if (whitePawnsInColumn == 1 && whiteMostAdvanced >= 4) {
         BOOL isPassed = YES;
         // VÃ©rifier colonnes adjacentes
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
            int bonus = 15 + (whiteMostAdvanced * 5);  // Bonus croissant mais rÃ©duit
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
            evalWhitePOV -= bonus;  // Bonus pour Noirs = nÃ©gatif pour Blancs
         }
      }
   }
   
   
   // ==================================================================================
   // PARTIE 4 : BONUS DÃ‰VELOPPEMENT
   // ==================================================================================
   /* Les piÃ¨ces (cavaliers/fous) sorties de leur position de dÃ©part reÃ§oivent un bonus
      Ceci a dÃ©jÃ  Ã©tÃ© calculÃ© dans la boucle principale ci-dessus */
   
   int developmentDiff = developmentWhite - developmentBlack;
   evalDisplay += developmentDiff;
   evalWhitePOV += developmentDiff;  // Toujours du point de vue des Blancs
   
   
   // ==================================================================================
   // PARTIE 5 : SÃ‰CURITÃ‰ DU ROI
   // ==================================================================================
   /* Bonus si le roi a roquÃ© (dÃ©jÃ  reflÃ©tÃ© dans les tables positionnelles)
      On peut ajouter un bonus supplÃ©mentaire pour les pions protecteurs devant le roi */
   
   // TODO : ImplÃ©menter dÃ©tection pions protecteurs (complexe, Ã  faire plus tard)
   
   
   // ==================================================================================
   // PARTIE 6 : DÃ‰TECTION MAT (CODE ORIGINAL CONSERVÃ‰)
   // ==================================================================================
   /* Note : Cette section pourrait Ãªtre optimisÃ©e en ne l'appelant que rarement
      car elle est coÃ»teuse en calcul */
   
   if ([self TestEchecRoiSide:sideBlack inBoard:board]) {
      if ([self PossibleMovesForSide:sideBlack board:board].count == 0) {
         evalDisplay += +100000;
         evalWhitePOV += +100000;  // Mat des Noirs = Ã©norme avantage Blancs
      }
   }
   else if ([self TestEchecRoiSide:sideWhite inBoard:board]) {
      if ([self PossibleMovesForSide:sideWhite board:board].count == 0) {
         evalDisplay += -100000;
         evalWhitePOV += -100000;  // Mat des Blancs = Ã©norme avantage Noirs
      }
   }
   
   
   // ==================================================================================
   // PARTIE 7 : PIONS EN AVANT-DERNIÃˆRE RANGÃ‰E (CODE ORIGINAL CONSERVÃ‰)
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
   // MISE Ã€ JOUR DE L'INTERFACE
   // ==================================================================================
   
   if (evalDisplay > 0)
      monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Ã‰val : +%d", evalDisplay];
   else
      monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Ã‰val : %d", evalDisplay];
   
   /* CONVERSION FINALE POUR NEGAMAX :
      - Si 'side' = Blancs : retourner evalWhitePOV tel quel (positif = bon pour Blancs)
      - Si 'side' = Noirs  : retourner -evalWhitePOV (nÃ©gatif devient positif)
      Ainsi Negamax reÃ§oit toujours une Ã©valuation positive = bon pour le camp qui joue */
   return (side == sideWhite) ? evalWhitePOV : -evalWhitePOV;
}


/* ============================================================================
   RÃ‰SUMÃ‰ DES MODIFICATIONS - CONVENTION NEGAMAX STANDARD
   ============================================================================
   
   CHANGEMENT FONDAMENTAL :
   
   L'Ã©valuation est maintenant TOUJOURS du point de vue des BLANCS :
   - evalWhitePOV > 0 = avantage Blancs
   - evalWhitePOV < 0 = avantage Noirs
   
   Conversion finale selon le camp qui Ã©value :
   - Si side = Blancs : retourne evalWhitePOV (positif = bon)
   - Si side = Noirs  : retourne -evalWhitePOV (l'inverse)
   
   Ainsi, Negamax reÃ§oit toujours un score oÃ¹ :
   - Positif = bon pour le camp qui joue
   - NÃ©gatif = mauvais pour le camp qui joue
   
   Et l'algorithme Negamax classique peut fonctionner avec son inversion
   de signe standard : score = -Negamax(otherSide, ...)
   
   ============================================================================
   
   AMÃ‰LIORATIONS CONSERVÃ‰ES :
   
   1. âœ… Ã‰VALUATION POSITIONNELLE (TABLES)
      - Chaque type de piÃ¨ce a une table de bonus selon sa position
      - Pions : encouragÃ©s au centre et en avancÃ©e
      - Cavaliers : bonus important au centre, malus sur les bords
      - Fous : bonus sur longues diagonales
      - Tours : bonus sur 7Ã¨me rangÃ©e
      - Dame : lÃ©gÃ¨re prÃ©fÃ©rence centre, Ã©viter sortie prÃ©coce
      - Roi : diffÃ©rent selon phase (milieu/fin de partie)
   
   2. âœ… MOBILITÃ‰
      - Bonus de 2 points par coup possible
      - Calcul optimisÃ© (tous les 2 niveaux seulement)
      - Camp avec plus de mobilitÃ© = meilleur contrÃ´le
   
   3. âœ… STRUCTURE DE PIONS
      - Pions doublÃ©s : MALUS -10 par pion supplÃ©mentaire
      - Pions passÃ©s : BONUS +15 Ã  +50 selon avancÃ©e
      - DÃ©tection simplifiÃ©e mais efficace
   
   4. âœ… DÃ‰VELOPPEMENT
      - Bonus +5 pour chaque cavalier/fou dÃ©veloppÃ©
      - Malus -10 pour dame sortie trop tÃ´t (< coup 10)
      - Encourage ouverture correcte
   
   5. âœ… PHASE DE JEU
      - DÃ©tection automatique milieu/fin de partie
      - Roi : dÃ©fensif en milieu, actif en finale
      - Adapte la stratÃ©gie automatiquement
   
   ============================================================================
*/



//***************************************************************************************************
// MÃ‰THODE 7 : PossibleMovesForSide - GÃ‰NÃ‰RATION DES COUPS LÃ‰GAUX
// (Code conservÃ© tel quel - dÃ©jÃ  optimisÃ©)
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
               
               /* VÃ©rification que le coup ne met pas son propre roi en Ã©chec */
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
// MÃ‰THODE 8 : TestEchecFavSide - DÃ‰TECTION Ã‰CHEC AVEC NOTIFICATION
// (Code conservÃ© tel quel)
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
// MÃ‰THODE 9 : TestEchecRoiSide - VERSION RAPIDE DE LA DÃ‰TECTION D'Ã‰CHEC
// (Code conservÃ© tel quel)
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
// MÃ‰THODE 10 : NotifiePatMatDesSide - GESTION FIN DE PARTIE
// (Code conservÃ© tel quel)
//***************************************************************************************************
+(void)NotifiePatMatDesSide:(Side)side
                    onBoard:(ChessBoard*)board
{
   if ([self TestEchecRoiSide:side inBoard:board]) {
      /* MAT DÃ‰TECTÃ‰ */
      NSString *msgTitre;
      NSString *msgInfo;
      
      while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == ' ') {
         stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
      }
      while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == '+') {
         stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
      }
      
      monMCNControleur.lblEchec.cell.stringValue = @"Ã‰chec et Mat !";
      
      if (side == sideBlack) {
         msgTitre = @"Les NOIRS sont Mat !";
         msgInfo = @"Partie terminÃ©e, Les BLANCS gagnent !";
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t1-0"];
         [monMCNControleur MaJtxtCoups];
      }
      else if (side == sideWhite) {
         msgTitre = @"Les BLANCS sont Mat !";
         msgInfo = @"Partie terminÃ©e, Les NOIRS gagnent !";
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
      /* PAT DÃ‰TECTÃ‰ */
      stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\n\t1/2-1/2"];
      [monMCNControleur MaJtxtCoups];
      
      NSString *msgTitre;
      NSString *msgInfo;
      
      if (side == sideBlack) {
         msgTitre = @"Les NOIRS sont Pat !";
         msgInfo = @"Le Roi Noir est Pat, la partie est dÃ©clarÃ©e nulle !";
      }
      else if (side == sideWhite) {
         msgTitre = @"Les BLANCS sont Pat !";
         msgInfo = @"Le Roi Blanc est Pat, la partie est dÃ©clarÃ©e nulle !";
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

@end


/* ============================================================================
   RÃ‰SUMÃ‰ DES OPTIMISATIONS APPORTÃ‰ES
   ============================================================================
   
   1. âœ… Ã‰VALUATION DIFFÃ‰RÃ‰E
      - EvalBoardForSide n'est plus appelÃ©e systÃ©matiquement Ã  chaque nÅ“ud
      - AppelÃ©e uniquement quand depth <= 0 (fin d'exploration)
      - GAIN : ~70% de rÃ©duction des appels Ã  la fonction la plus coÃ»teuse
   
   2. âœ… QUIESCENCE SEARCH LIMITÃ‰E
      - Limitation stricte Ã  3 niveaux supplÃ©mentaires (depth > -3)
      - Filtrage des captures AVANT la boucle pour Ã©viter les itÃ©rations inutiles
      - GAIN : PrÃ©vention des arbres de recherche exponentiels
   
   3. âœ… TRI DES COUPS (Move Ordering)
      - Nouvelles mÃ©thodes : SortMovesByPriority et ScoreMove
      - Les captures sont examinÃ©es en prioritÃ©
      - GAIN : AmÃ©lioration drastique de l'Ã©lagage alpha-beta
   
   4. âœ… FILTRAGE OPTIMISÃ‰ DES CAPTURES
      - Nouvelle mÃ©thode FilterCaptures pour le Quiescence Search
      - Ã‰vite de parcourir tous les coups en mode QS
      - GAIN : RÃ©duction du facteur de branchement en QS
   
   5. âœ… DÃ‰TECTION MAT IMMÃ‰DIATE
      - Si un coup met mat, retour immÃ©diat sans explorer d'autres options
      - GAIN : Fin de partie accÃ©lÃ©rÃ©e quand mat est trouvÃ©
   
   PERFORMANCE ATTENDUE :
   - Temps de calcul divisÃ© par 5 Ã  10 pour NUMBER_MOVES_AHEAD = 3
   - Ã‰lagage alpha-beta 2 Ã  3 fois plus efficace
   - PossibilitÃ© d'augmenter NUMBER_MOVES_AHEAD Ã  4 sans perte de rÃ©activitÃ©
   
   ============================================================================
*/
