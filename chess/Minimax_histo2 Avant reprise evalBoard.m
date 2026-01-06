//  Minimax.m
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 2020
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "Minimax.h"
#import "ChessBoard.h"
#import "Move.h"
#import "Pos.h"
#import "RuleBook.h"

/* NUMBER_MOVES_AHEAD est la constante qui définit sur combien de coups à venir l'algorithme fait ses simulations
De base cette constante est fixée à 3, pour un moteur performant a minima : à garder donc pour les releases ...
Par contre cette valeur peut être avantageusement abaissée à 2 lors de phases de test de fonctionnalités pour un
moteur à réponse quasi instantanée
Pour pouvoir agir sur la valeur de NUMBER_MOVE_AHEAD par le code, la constante a été transformée en variable
globale et a été transférée dans le fichier Util.h */
//#define NUMBER_MOVES_AHEAD 2

int nbLoop = 0;
int nbElag = 0;

@implementation Minimax

   
   //***************************************************************************************************
   // Méthode de classe
   // La méthode est générique mais elle n'est réellement appelée que par l'IA pour trouver son meilleur
   // coup, le joueur -lui- se débrouille tout seul, pour l'instant ...
   +(Move *)BestMoveForSide:(Side)side
                      board:(ChessBoard *)board
   {
      NSSet *movesPossibles = [self PossibleMovesForSide:side board:board];
      // PRÉREQUIS : TESTER SI SIDE EST MAT OU PAT À CE STADE, CAR SI LE CAS PAS LA PEINE D'ALLER PLUS LOIN...
      if (movesPossibles.count == 0) [self NotifiePatMatDesSide:side onBoard:board];
      // Sinon on poursuit en cherchant le meilleur move possible pour 'side'...
      else
      {
         int bestScore = -INT_MAX;
         Move *bestMove = nil;
         Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
         /* Pour chacun des coups possibles pour la couleur considérée...
         Si par exemple NUMBER_MOVES_AHEAD est fixé à 3, l'algo fera une simul sur les 3 prochains tours : d'abord
         pour l'IA (ici dans BestMFSide), puis pour le Joueur et l'IA à nouveau (dans l'appel récursif de NegaMax) */
         for (Move *moveEnCours in movesPossibles)
            {
               ChessBoard *newBoard = board.copy; // On travaille sur une copie du board courant
               [newBoard PerformMove:moveEnCours];
               
               /* TEST AJOUTÉ CAR SI LE MOVE MET L'ADV. MAT ALORS C'EST LE BEST MOVE QU'IL NOUS FAUT !
               (À ce stade on ne se contente pas d'un Pat, que l'on ne recherche jamais pour l'adversaire,
               il faut donc vérifier les 2 conditions : d'impossibilité de 'move' et de mise en échec)
               TODO : Le if initial a été scindé en 2 pour réduire le nbre de tests et donc de méthodes
               appelées, MAIS VOIR LAQUELLE DES 2 (PossibleMoveFS ou TestEchecRoiSide) EST LA MOINS LOURDE
               AFIN DE LA METTRE EN TETE DE TEST */
               if ([self PossibleMovesForSide:otherSide board:newBoard].count == 0) {
                  if ([self TestEchecRoiSide:otherSide   inBoard:newBoard]) {
                        bestMove = moveEnCours;
                        /* int eval = [self EvalBoardForSide:side board:newBoard];
                        NSLog(@"\n\n\tLe 'bestMove' IA (%@) est %@# \tpour une 'eval' courante du board de %d \n\n",
                              (side == sideWhite)? @"Blancs" : @"Noirs",
                              [MCNmoveToStr Modif00EnA1:bestMove surBoard:board], eval); */
                        return bestMove;
                  }
               } // FIN DE TEST AJOUTÉ
               
               /* Appel initial à 'NegaMaxFS' avec les paramètres par défaut : pour 'side', dans une copie du board
               (car les moves sont virtuels), à la profondeur de recherche max, et avec la fenêtre alpha bêta max */
               int negaMax = +[self NegamaxForSide:side // TEST JUIN22 ("side" à l'origine)
                                             board:newBoard
                                             depth:NUMBER_MOVES_AHEAD
                                             alpha:-INT_MAX
                                              beta:INT_MAX];
               if (negaMax > bestScore || !bestMove) {
                  bestScore = negaMax;
                  bestMove = moveEnCours;
                  NSLog(@"Meilleur choix trouvé pour les %@ : Score attendu = %d et Move retenu = %@",
                        (side == 1)? @"Noirs" : @"Blancs", bestScore, bestMove);
               } // Fin de if
            } // Fin de for
         
         /* NSLog de contrôle, potentiellement désactivable */
         NSLog(@"Choix définitif retenu pour les %@ : Score attendu = %d et Move retenu = %@",
               (side == 1)? @"Noirs" : @"Blancs", bestScore, bestMove);
         return bestMove;
      } // Fin de else
      
      //return 0;
      return Nil; // Valeur de retour à laquelle on n'accède jamais, mais plus raccord avec un type Move attendu
   }
   
   
   //*************************************************************************************************************
   // Méthode de classe - Implémentation de l'algorithme 'Negamax' ('Minimax' compact) avec élagage alpha-bêta
   // L'appel initial à 'NegaMax' se fait dans 'BestMoveForSide' avec les param. par défaut. Les appels suivants se font
   // par récursivité dans le coeur de 'NegaMax' avec des param. adaptés à l'alternance IA/Joueur des coups examinés.
   +(int)NegamaxForSide:(Side)side
                  board:(ChessBoard *)board
                  depth:(int)depth
                  alpha:(int)alpha
                   beta:(int)beta   {
      
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      
      /* Test assurant la sortie de la boucle de l'appel récursif (cf. plus bas)
      Si on a atteint la profondeur définie ou si le camp adv est Mat ou Pat, alors on sort */
      if (depth <= 0 || [self PossibleMovesForSide:otherSide board:board].count == 0)
      {
         int eval = [self EvalBoardForSide:side board:board] ;
         NSLog(@" \n Depth= %d (NB_MOVE_AHEAD= %d) - Coup %@= ?? - Old éval= ?? New éval= %d",
                              depth, NUMBER_MOVES_AHEAD, (otherSide == 1)? @"Noirs":@"Blancs",eval);
         return eval;
         //return (side == sideBlack)? eval:-eval; // TEST !?
      }
      
      // sinon on descend dans l'arbre des coups successifs par appel récursif
      else
      {
         // nbLoop ++; NSLog(@"\n Coups examinés    = %d",nbLoop);
         int best = -INT_MAX;
         // Pour chaque coup possible de chacun des 3 tours à venir ==>
         for (Move *moveEnCours in [self PossibleMovesForSide:otherSide board:board])
         {
            ChessBoard *newBoard = board.copy;
            [newBoard PerformMove:moveEnCours]; // ==> on simule son exécution, pour évaluer chaque board résultant
            
            // APPEL RÉCURSIF PERMETTANT DE POURSUIVRE LA SIMUL POUR LES TOURS DE PROFONDEUR (depth) 2 PUIS 1
            int score = -[self NegamaxForSide:otherSide  // couleur permutée à chaque appel
                                        board:newBoard
                                        depth:depth - 1  // 'depth' passe de 3 (*) à 2, à 1, puis à 0
                                        alpha:-beta      // alpha et bêta sont croisés à chaque nouvel appel car ce
                                         beta:-alpha];   // qui est Max pour l'IA matche avec ce qui est Min pour le Joueur
            
            // LA SUITE N'EST EXÉCUTÉE QUE QUAND SCORE EST ÉVALUÉ (càd qd 'depth'=0) CE QUI NOUS FAIT SORTIR DE NEGAMAX
            if (score > best) {
               NSLog(@" \n Depth= %d (NB_MOVE_AHEAD= %d) - Coup %@= %@ - Old éval= %d - New éval= %d ",
                                    depth, NUMBER_MOVES_AHEAD, (otherSide == 1)? @"Noirs":@"Blancs",moveEnCours,best,score);
               
               best = score;           // dans Négamax on cherche toujours la valeur Max (pas comme en minimax)
               if (best > alpha) {
                  alpha = best;        // on réduit la fenêtre de [-INT_MAX ; +INT_MAX] à [best ; +INT_MAX]
                  if (alpha >= beta) { // les bornes de la fenêtre se croisent --> ÉLAGAGE !!
                     // nbElag ++; NSLog(@"\n Branches élaguées = %d", nbElag);
                     return best;
                  }
               } // Fin de if best
            } // Fin de if score
         } // Fin de for chaque move possible
         /*NSLog(@"\n En 'depth' %d le meilleur score retenu par les %@ est : %d",
               depth, (otherSide == 1)? @"Noirs":@"Blancs", best); */
         return best; // Ligne ORIGINALE conforme au BEST PSEUDO CODE NEGAMAX
         NSLog(@"Meilleure évaluation retournée par Negamax = %d",best);
      } /* Fin de else (profondeur non atteinte) */
   } /* Fin de méthode 'NegamaxFS' */
   
   
   //*************************************************************************************************************
   // Méthode de classe MCN
   // ex méthode 'scoreForSide' renommée pour une meilleure compréhension du but de la méthode
   // et pour éviter la confusion entre la variable 'score' de 'negamax'
   +(int)EvalBoardForSide:(Side)side
                    board:(ChessBoard *)board
   {
      int evalBoardRetournee = 0;
      evalBoardAffichee = 0;
      
      /* ÉVALUATION MATÉRIELLE - On balaye chaque case de l'échiquier considéré, pour obtenir une valeur globale
      totalisant la valeur de chacune des pièces encore présentes. À noter que la valeur relative des pièces
      (au Roi près) est celle communément attribuée par la sphère échiquéenne */
      for (int x = 0; x < 8; x++)      // balayage des abcisses
      {
         for (int y = 0; y < 8; y++)   // balayage des ordonnées
         {
            Piece *piece = [board piece_colX:x rangY:y];
            if (piece)
            {
               int value = 0;
               switch (piece.type)
               {
                  case Invalide:                  break;   // si pas de pièce, pas de valeur ajoutée
                  case Pion:    value = 100;      break;   // s'il y a un Pion : +100
                  case Cava:    value = 300;      break;   // +300 pour un Cavalier
                  case Fou:     value = 300;      break;   // +300 pour un Fou
                  case Tour:    value = 500;      break;   // +500 pour une Tour
                  case Dame:    value = 900;      break;   // +900 pour la Dame
                  case Roi:     value = 100000;   break;   // +100 000 pour le Roi !!!!
                  /* Bien que le Roi ne puisse être capturé -ce qu'ignorent complètement la présente méthode
                  d'évaluation, le moteur de l'IA, ainsi que la méthode gérant le déplacement des pièces- il est
                  important de lui accorder une forte valeur afin d'inciter l'IA à choisir, par appat du gain,
                  un coup qui permettrait de le capturer si c'était effectivement possible... */
               }
               
               /* VALEUR RETOURNÉE POUR L'ALGO : Si la pièce est de la couleur visée par l'appel de la méthode,
               alors sa valeur s'ajoute au total, sinon elle est déduite */
               evalBoardRetournee += value * ((piece.side == sideIA)? 1 : -1);      // INCRÉMENT VALEUR RETOURNÉE
               
               /* VALEUR AFFICHÉE : Si la pièce est Blanche sa valeur s'ajoute au total, sinon elle est déduite
               (par conv. une éval pos indique un avantage aux Blancs et une éval nég un avantage aux Noirs) */
               evalBoardAffichee  += value * ((piece.side == sideWhite)? 1 : -1);   // INCRÉMENT VALEUR AFFICHÉE
               
               /* Le mode de calcul d'evalBoardRetournee (et non d'evalBoardAffichee) inverse le signe du résultat
               selon la couleur, ce qui est cohérent avec la nécessité d'inverser cette valeur imposée par Négamax
               quand c'est aux Noirs de jouer... - TODO - VÉRIFIER QUE LE SIGNE PORTÉ PAR L'ÉVALUATION INFLUENCE
               CORRECTEMENT L'IA DANS LE CHOIX DE SON MEILLEUR COUP, QUELLE QUE SOIT LA COULEUR QU'ELLE JOUE */
            } /* Fin de if piece*/
         } /* Fin de for y */
      } /* fin de for x */
      
      /* PRISE EN COMPTE DE LA MISE EN ÉCHEC ET MAT
      NB : La prise en compte de la mise en échec, implémentée un temps dans l'éval, a été abandonnée car
      elle perturbait le choix du coup quand il s'opposait à une prise potentielle de pièce, pour un bénéfice
      (la mise en échec) qui n'est finalement que temporaire sans garantir un avantage stratégique futur */
      //Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      
      if ([self TestEchecRoiSide:sideJoueur inBoard:board]) {
         if ([self PossibleMovesForSide:sideJoueur board:board].count == 0) { // Joueur est Mat
            evalBoardRetournee += +100000; /* car favorise IA */
            evalBoardAffichee  += +100000 * ((side == sideWhite)? 1 : -1);
         }
      }
      else if ([self TestEchecRoiSide:sideIA inBoard:board]) {
         if ([self PossibleMovesForSide:sideIA board:board].count == 0) {      // IA est Mat
            evalBoardRetournee += -100000; /* car favorise Joueur */
            evalBoardAffichee  += -100000 * ((side == sideWhite)? 1 : -1);
         }
      }
      /* FIN DE PRISE EN COMPTE DE LA MISE EN ÉCHEC ET MAT  */
      
      /* PRISE EN CPTE DES PIONS EN AVANT-DERNIÈRE RANGÉE : +900 ACCORDÉS COMME S'ILS ÉTAIENT DÉJÀ PROMUS DAMES
      Échiquier orienté avec les Blancs en bas */
      if (sideJoueur == sideWhite) {
         for (int x = 0; x < 8; x ++) {
            Piece *pionB = board->pieceCase[x][6];  // Pion Blanc en rangée 6
            if ((pionB.type == Pion) && (pionB.side == sideWhite)){
               evalBoardRetournee += 900 *((pionB.side == sideIA)? 1 : -1);
               evalBoardAffichee  += 900 *((side == sideWhite) ? 1 : -1);
            }
            Piece *pionN = board->pieceCase[x][1];  // Pion Noir en rangée 1
            if ((pionN.type == Pion) && (pionN.side == sideBlack)){
               evalBoardRetournee += 900 *((pionN.side == sideIA)? 1 : -1);
               evalBoardAffichee  += 900 *((side == sideWhite) ? 1 : -1);
            }
         }
      }
      /* Échiquier orienté avec les Noirs en bas */
      if (sideJoueur == sideBlack) {
         for (int x = 0; x < 8; x ++) {
            Piece *pionB = board->pieceCase[x][1];  // Pion Blanc en rangée 1
            if ((pionB.type == Pion) && (pionB.side == sideWhite)){
               evalBoardRetournee += 900 *((pionB.side == sideIA)? 1 : -1);
               evalBoardAffichee  += 900 *((side == sideWhite) ? 1 : -1);
            }
            Piece *pionN = board->pieceCase[x][6];  // Pion Noir en rangée 6
            if ((pionN.type == Pion) && (pionN.side == sideBlack)){
               evalBoardRetournee += 900 *((pionN.side == sideIA)? 1 : -1);
               evalBoardAffichee  += 900 *((side == sideWhite) ? 1 : -1);
            }
         }
      }
      /* FIN DE PRISE EN COMPTE DES PIONS ARRIVÉS SUR LEUR AVANT DERNIÈRE RANGÉE */
      
      /* TEST JUIN22 - TODO VÉRIFIER COMPORTEMENT DU JEU
      INVERSION EVALBOARD QD C'EST L'ADV DE L'IA QUI JOUE VS QD C'EST AUX NOIRS DE JOUER (SELON C#ESS ENGINE)  */
      //if (side == sideBlack) evalBoardRetournee = -evalBoardRetournee;
      //if (side == sideBlack) evalBoardRetournee = -evalBoardRetournee;
      /* FIN TEST JUIN22 */

      /* Mise à jour du 'lblEvalBoard' de l'interface, avec un '+' ajouté aux valeurs positives */
      if (evalBoardAffichee > 0)
            monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : +%d", evalBoardAffichee];
      else  monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : %d",  evalBoardAffichee];
      
      
      /* New test shuntant les calculs sur evalBoardRetournee pour la rapprocher de evalBoardAffichee */
      if (side == sideBlack) evalBoardRetournee = - evalBoardAffichee;
      return evalBoardRetournee;
      
      
      //return evalBoardAffichee;
      
   } /* Fin de Méthode 'EvalBoardForSide' */

   

   //*************************************************************************************************************
   // Méthode de classe 'PossibleMoveForSide'
   // Détermine tous les 'moves' possibles d'un 'side', à partir de l'ensemble des positions possibles de toutes
   // les pièces de cette couleur présentes sur le 'board'
   // MCN - AJOUT D'UNE VÉRIFICATION SYSTÉMATIQUE SI POSITION D'ÉCHEC GÉNÉRÉE AVANT VALIDATION ET AJOUT D'UN MOVE
   +(NSSet *)PossibleMovesForSide:(Side)side
                            board:(ChessBoard *)board
   {
      NSMutableSet *moves = [[NSMutableSet alloc] init];
      //Pos *posRoiSide;
      for (int x = 0; x < 8; x++)
      {
         for (int y = 0; y < 8; y++)
         {
            Pos *pos = [Pos posWithX:x y:y];
            Piece *piece = [board piece_colX:x rangY:y];
            if (piece)
            {
               if (piece.side == side)
               {
                  NSSet *PosAcceptees = [RuleBook PosAccepteesForPiece:piece atPos:pos inBoard:board];
                  for (Pos *possibleDest in PosAcceptees)
                  {
                     Move *move = [[Move alloc] initWithStart:pos dest:possibleDest];
                     // Il faut réaliser le move (dans une copie du board) pour pouvoir contrôler l'absence de pos d'échec
                     ChessBoard *newBoard = board.copy;
                     [newBoard PerformMove:move];
                     [moves addObject:move]; // Retour de la ligne d'origine
                  } // fin de for
               } // fin de if piece.side
            } // fin de if piece
         } // fin de for y
      } // fin de for x
      return moves;
   } // Fin de 'PossibleMoveForSide' AVEC CONTROLE SYSTÉMATIQUE DE POSITION D'ÉCHEC



   //*************************************************************************************************************
   // MCN - Méthode de Classe (inspirée de 'PossibleMoveForSide') - Détection des positions d'Échec en FAVEUR du
   // coté 'Side' (autrement dit Roi 'otherSide' en échec). La méthode vise à déterminer tous les 'moves' possibles
   // coté 'side' d'un 'board' et à examiner si à chaque destination de chacun de ces 'moves' on trouve le Roi adverse,
   // auquel cas cela signifie qu'il est en échec. De par sa lourdeur comparée à sa version lite 'TestEchecRoiSide',
   // cette méthode est à réserver aux besoins d'affichage de la chaine de description complète de l'échec. C'est elle
   // qui recherche les positions d'échec multiples et qui gère les messages d'alerte correspondant. NOTER que le Mat
   // est confirmé par un test supplémentaire vérifiant qu'un protagoniste ne dispose plus d'aucun coup autorisé.
   +(NSString *)TestEchecFavSide:(Side)side Board:(ChessBoard *)board
   {
      NSString *strEchec = @"";
      checkCount = 0;
      Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      /* On s'arrête sur chaque case du 'board' courant, on regarde si on y trouve une pièce, et si cette pièce
      est de couleur 'side'...     Si oui, pour chacune de ses destinations possibles... */
      for (int x = 0; x < 8; x++)
      {
         for (int y = 0; y < 8; y++)
         {
            Pos *pos = [Pos posWithX:x y:y];
            Piece *piece = [board piece_colX:x rangY:y];
            if (piece)
            {
               if (piece.side == side)
               {
                  NSSet *PosAcceptees = [RuleBook PosAccepteesForPiece:piece atPos:pos inBoard:board];
                  for (Pos *possibleDest in PosAcceptees)
                  {
                     Move *moveSide = [[Move alloc] initWithStart:pos dest:possibleDest];
                     
                     /* DÉTECTION MISE EN ÉCHEC  ...on regarde si sur chacune de ces cases destination il y a une
                     pièce de la couleur opposée dont le type est Roi... Si oui, il y a Echec */
                     Piece *pieceAdv = [board piece_colX:moveSide.dest.x rangY:moveSide.dest.y];
                     if (pieceAdv.type == Roi)
                     {
                        if (pieceAdv.side == otherSide)
                        {
                           strEchec = @"Echec";
                           checkCount = checkCount + 1;  // incrémentation de checkCount
                           //NSLog(@"\ncheckCount = %d",checkCount);
                        } // fin if
                     } // fin if
                  }  // fin for
               }  // fin if
            }  // fin if
         } // fin for
      } // Sortie du for
      
      /* Il est nécessaire de parcourir la boucle de détection d'ÉCHEC ci-avant jusqu'au bout sans en
         sortir à la première détection, ceci afin de pouvoir comptabiliser les échecs multiples.  */
      
      /* On continue par l'affichage d'une NSAlert uniquement s'il est avéré que le Roi est en échec  */
      if ([strEchec isEqual:@"Echec"])
      {
         // Boite de dialogue
         NSString *msgTitre;
         NSString *msgInfo;
         
         if (sideCourant == sideWhite) {
            msgTitre = @"Le Roi NOIR est en position d'Échec !";
            msgInfo  = @"OK pour poursuivre la partie...";
         }
         else {
            msgTitre = @"Le Roi BLANC est en position d'Échec !";
            msgInfo  = @"OK pour poursuivre la partie...";
         }
         
         NSAlert *alertEchec = [[NSAlert alloc] init];
         [alertEchec addButtonWithTitle:@"OK"];
         [alertEchec setMessageText:msgTitre];
         [alertEchec setInformativeText:msgInfo];
         [alertEchec setAlertStyle:NSAlertStyleInformational];
         
         // Récupération du choix fait par le joueur
         NSModalResponse boutonChoisi = [alertEchec runModal];
         if (boutonChoisi == NSAlertFirstButtonReturn) return strEchec;
         
      } // fin if (strEchec...)
      
      return strEchec;
      
   }  // fin méthode TestEchecFavSide



   // *************************************************************************************************************
   // MCN - Méthode de Classe - Version "lite" de 'TestEchecFavSide' (renvoyant quant à elle une chaine décrivant
   // la situation vis-à-vis de l'échec) visant pour sa part à répondre RAPIDEMENT à la question de savoir si le Roi
   // est en échec, en se moquant d'être capable de dire si l'échec est simple ou double et si le mat est confirmé...
   // NOTER que la question posée, et donc la réponse apportée, par les deux méthodes en question sont inverses
   // Cette méthode est adaptée (c'est sa raison d'être) pour valider ou non un MovePossible....
   // Elle n'est appelée que dans 'PossibleMoveForSide' et dans 'NotifiePatMatDesSide'
   +(BOOL)TestEchecRoiSide:(Side)side inBoard:(ChessBoard *)board
   {
      BOOL sideEstEnEchec = NO;
      Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      
      /* On parcourt chaque case du 'board' courant, à la recherche des pièces adverses (càd 'otherSide')
      et pour chacune d'elle on vérifie chacune de ses destinations possibles>>    */
      for (int x = 0; x < 8; x++)
      {
         for (int y = 0; y < 8; y++)
         {
            Pos *pos = [Pos posWithX:x y:y];
            Piece *pieceAdv = [board piece_colX:x rangY:y];
            if (pieceAdv)
            {
               if (pieceAdv.side == otherSide)
               {
                  NSSet *PosAcceptees = [RuleBook PosAccepteesForPiece:pieceAdv atPos:pos inBoard:board];
                  for (Pos *possibleDest in PosAcceptees)
                  {
                     Move *moveSideAdv = [[Move alloc] initWithStart:pos dest:possibleDest];
                        
                     // DÉTECTION MISE EN ÉCHEC  >> et sur chacune de ces cases destinations on regarde si on
                     // trouve notre Roi, auquel cas nous sommes en situation d'Échec :-(
                     Piece *piece = [board piece_colX:moveSideAdv.dest.x rangY:moveSideAdv.dest.y];
                     if (piece.type == Roi)
                     {
                        if (piece.side == side)
                        {
                           sideEstEnEchec = YES;
                           //NSLog(@"\nLes %@ SONT Échec",(side==1)?@"Noirs":@"Blancs");
                           return sideEstEnEchec;
                        } // fin if
                     } // fin if
                  }  // fin for
               }  // fin if
            } // fin for
         } // fin for
      } // Sortie du for
      return sideEstEnEchec;
   } // Fin de Méthode 'TestEchecRoiSide'

   

   //***************************************************************************************************
   // MCN - Méthode de gestion du Pat et du Mat - CETTE MÉTHODE NE DOIT ÊTRE APPELÉE QU'APRÈS QU'UN TEST
   // SUR 'PossibleMovesForSide' AIT RÉVÉLÉ QUE LE JEU DE MOVES EST VIDE, CAR C'EST BIEN CE TEST QUI
   // CARACTÉRISE UNE SITUATION DE MAT OU DE PAT, LA PRÉSENTE MÉTHODE NE FAIT QUE LA TRAITER...
   +(void)NotifiePatMatDesSide:(Side)side
                       onBoard:(ChessBoard*)board
   {
      /* MAT - Par définition, si on est ici c'est que 'side' n'a plus de move possible...
      ...et si en plus 'side' est Échec sur le board actuel, c'est que 'side' est Mat */
      if ([self TestEchecRoiSide:side inBoard:board])
      {
         /* Traitement des chaines : liste des coups et messages */
         NSString *msgTitre;
         NSString *msgInfo;
         /* Suppression des caractères vides en fin de chaine 'stringCoupsPartie' tant qu'il y en a */
         while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == ' ')  {
            /* range : à partir du char à l'indice 0 et sur une longueur de len-1 pour supp le dernier char */
            stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
         }
         /* Suppression des caractères '+' en fin de chaine tant qu'il y en a */
         while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == '+')  {
            stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
         }
         
         /* Mise à jour 'Status Bar' */
         monMCNControleur.lblEchec.cell.stringValue = @"Échec et Mat !";
         
         /* Boite de dialogue */
         if (side == sideBlack)
         {  msgTitre = @"Les  NOIRS  sont Mat !";
            msgInfo = @"Partie terminée, Les BLANCS gagnent !";
            /* Mise à jour de la liste des coups et du contrôle 'txtView'
            on ajoute un '#' pour signifier mat, puis 1-0 pour "les Blancs gagnent" */
            stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t1-0"];
            [monMCNControleur MaJtxtCoups];
         }
         else if (side == sideWhite)
         {  msgTitre = @"Les  BLANCS  sont Mat !";
            msgInfo = @"Partie terminée, Les NOIRS gagnent !";
            /* Mise à jour de la liste des coups et du contrôle 'txtView'
            on ajoute un '#' pour signifier mat, puis 0-1 pour "les Noirs gagnent" */
            stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t0-1"];
            [monMCNControleur MaJtxtCoups];
         }
         
         /* Affichage de la boite de dialogue */
         NSAlert *alertMat = [[NSAlert alloc] init];
         [alertMat addButtonWithTitle:@"OK"];
         [alertMat setMessageText:msgTitre];
         [alertMat setInformativeText:msgInfo];
         [alertMat setAlertStyle:NSAlertStyleInformational];
         
         /* Attente 'OK' par le joueur */
         NSModalResponse boutonChoisi = [alertMat runModal];
         if (boutonChoisi == NSAlertFirstButtonReturn) {
            stopMatOuPat = YES;
         }
         
      } // fin if de niv 1 et de MAT
      
      /* PAT - Mais si au contraire il n'y a pas situation d'échec, c'est que 'side' est simplement Pat */
      else
      {
         /* Si pas de move possible mais pas de situation d'Échec alors 'Pat'
         Mise à jour de la liste des coups et du contrôle 'textView' */
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\n\t1/2-1/2"];
         [monMCNControleur MaJtxtCoups];
         
         NSString *msgTitre;
         NSString *msgInfo;
         if (side == sideBlack)
         {  msgTitre = @"Les  NOIRS  sont Pat !";
            msgInfo = @"Le Roi Noir est Pat, la partie est déclarée nulle !";
         }
         else if (side == sideWhite)
         {  msgTitre = @"Les  BLANCS  sont Pat !";
            msgInfo = @"Le Roi Blanc est Pat, la partie est déclarée nulle !";
         }
         
         /* Mise à jour 'Status Bar' */
         monMCNControleur.lblEchec.cell.stringValue = @"Pat !";
         
         /* Affichage boite de dialogue */
         NSAlert *alertPat = [[NSAlert alloc] init];
         [alertPat addButtonWithTitle:@"OK"];
         [alertPat setMessageText:msgTitre];
         [alertPat setInformativeText:msgInfo];
         [alertPat setAlertStyle:NSAlertStyleInformational];
         
         /* Attente 'OK' par le joueur */
         NSModalResponse boutonChoisi = [alertPat runModal];
         if (boutonChoisi == NSAlertFirstButtonReturn) {
            stopMatOuPat = YES;
         }
      } /* fin else de niv 1 et de PAT */
   } /* Fin de Méthode 'NotifiePatMatDesSide' */

   
@end
