//  Minimax.m
//  chess
//
//  Created by Andrew Wang on 15/07/2013, Completed by MCN on 2020
//  Copyright (c) 2013 Andrew Wang. All rights reserved.

#import "Minimax.h"


//#define NUMBER_MOVES_AHEAD 3
/* NUMBER_MOVES_AHEAD est la constante qui définit sur combien de coups à venir l'algorithme fait ses
simulations. De base cette constante est fixée à 3, pour un moteur performant a minima : à garder donc
pour les releases ... Par contre cette valeur peut être avantageusement abaissée à 2 lors de phases de
test de fonctionnalités pour un moteur à réponse quasi instantanée
Depuis la première refonte de l'interface intégrant le réglage de la valeur de NUMBER_MOVE_AHEAD par le
code, la constante a été transformée en variable globale et a été transférée dans le fichier Util.h  */

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
      /* Détermination du jeu de tous les moves possibles pour 'side' */
      NSSet *movesPossibles = [self PossibleMovesForSide:side board:board];
      /* PRÉREQUIS : TESTER SI SIDE EST MAT OU PAT À CE STADE, CAR SI OUI PAS LA PEINE D'ALLER PLUS LOIN */
      if (movesPossibles.count == 0) [self NotifiePatMatDesSide:side onBoard:board];
      /* Sinon on poursuit en cherchant le meilleur move possible pour 'side'... */
      else
      {
         int bestScore  = -INT_MAX;
         Move *bestMove = nil;
         Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
         /* Pour chacun des coups possibles pour la couleur considérée...
         Si par ex NUMBER_MOVES_AHEAD est fixé à 3, l'algo fera une simul sur les 3 prochains tours : pour
         l'IA (ici dans BMFS), puis pour le Joueur et l'IA à nouveau (dans l'appel récursif de NegaMax) */
         for (Move *moveEnCours in movesPossibles)
            {
               ChessBoard *newBoard = board.copy;  /* On travaille sur une copie du board courant */
               [newBoard PerformMove:moveEnCours];
               
               /* TEST AJOUTÉ CAR SI LE MOVE MET L'ADV. MAT ALORS C'EST LE BEST MOVE QU'IL NOUS FAUT !
               (À ce stade on ne se contente pas d'un Pat, que l'on ne recherche jamais pour l'adversaire,
               il faut donc vérifier les 2 conditions : d'impossibilité de 'move' et de mise en échec)
               TODO : Le if initial a été scindé en 2 pour réduire le nbre de tests et donc de méthodes
               appelées, MAIS VOIR LAQUELLE DES 2 (PossibleMoveFS ou TestEchecRoiSide) EST LA MOINS LOURDE
               AFIN DE LA METTRE EN TETE DE TEST */
               if ([self PossibleMovesForSide:otherSide  board:newBoard].count == 0) {
                  if ([self TestEchecRoiSide:otherSide inBoard:newBoard]) {
                        bestMove = moveEnCours;
                        return bestMove;
                  }
               } // FIN DE TEST AJOUTÉ
               
               /* Appel initial à 'NegaMaxFS' avec les param par défaut : pour 'side', dans une copie du board
               (car les moves sont virtuels), à la profondeur max, et avec la fenêtre alpha bêta max */
               int negaMax = +[self NegamaxForSide:side
                                             board:newBoard
                                             depth:NUMBER_MOVES_AHEAD
                                             alpha:-INT_MAX
                                              beta:INT_MAX];
               if (negaMax > bestScore || !bestMove) {
                  bestScore = negaMax;
                  bestMove = moveEnCours;
                  NSLog(@"\n BMFS : Un choix intermédiaire est trouvé pour les %@ : Score = %d et Move = %@",
                        (side == 1)? @"Noirs" : @"Blancs", bestScore, bestMove);
               } // Fin de if
            } // Fin de for
         
         /* NSLog de contrôle, potentiellement désactivable */
         NSLog(@"\n BMFS : Choix définitif validé pour les %@ : Score attendu = %d et Move retenu = %@",
               (side == 1)? @"Noirs" : @"Blancs", bestScore, bestMove);
         return bestMove;
      } // Fin de else
      
      //return 0;
      return Nil; // Ligne jamais atteinte, mais valeur de retour + raccord avec un type Move attendu
   }
   
   
   //***************************************************************************************************
   // Méthode de classe - Implémentation de l'algo 'Negamax' ('Minimax' compact) avec élagage alpha-bêta
   // L'appel initial à 'NegaMax' se fait dans 'BestMoveForSide'. Les appels suivants se font par récursi-
   // vité dans le coeur de 'NegaMax' avec des param adaptés à l'alternance IA/Joueur des coups examinés.
   // Une touche de 'Quiescence Search' (QS) est ajouté au code pour une meilleure efficacité de l'algo...
   +(int)NegamaxForSide:(Side)side
                  board:(ChessBoard *)board
                  depth:(int)depth
                  alpha:(int)alpha
                   beta:(int)beta   {
      
      Side otherSide = (side == sideWhite) ? sideBlack : sideWhite;
      
      /* Test assurant la sortie de la boucle de l'appel récursif (cf. plus bas)
      Si le camp adversaire est Mat ou Pat, alors on sort */
      
      /* ************************************************************** */
      /* ********* MODIF du 02/06/2025 - OPTIMISATION DU CODE ********* */
      int eval = [self EvalBoardForSide:side board:board];
   
      if ([self PossibleMovesForSide:otherSide board:board].count == 0) {
         // Distinguer mat et pat
         if ([self TestEchecRoiSide:otherSide inBoard:board]) {
            return 100000; // Mat favorable
         }
         else {
            return 0;      // Pat = nulle
         }
      }
      /* ********* FIN DE MODIF        - OPTIMISATION DU CODE ********* */
      /* ************************************************************** */
      
      /* 'depth <= 0' n'est plus un cas de sortie inconditionnelle, mais le début d'une QS */
      if (depth <= 0)
      {
         if (eval >= beta) return eval;  /* Si 'eval' est sup au max attendu alors on retourne 'eval' */
         if (eval > alpha) alpha = eval; /* QS : Sinon si 'eval' est sup à alpha, on referme la fenêtre
         basse et on continue ; depth <=0 n'est donc plus un motif de sortie de la boucle récursive */
         NSLog(@"\nQuiescence Search (QS) en depth : %d",depth);
      }
      if (depth <= -31) return eval; /* Test de sécurité, suite à QS, a priori totalement inutile */
      
      // Si pas de sortie de boucle à ce stade, on descend dans l'arbre des coups successifs par appel
      // récursif. Pour chaque coup possible de chacun des 3 tours à venir ==>
      for (Move *moveEnCours in [self PossibleMovesForSide:otherSide board:board])
      {
         /* En mode QS (càd en depth<=0) on écarte tous les moves qui ne sont pas des captures */
         /* Bloc de détection de capture */
         BOOL capture = NO;
         int typePiece  = [board pieceAtPos:moveEnCours.dest].type;
         Side sidePiece = [board pieceAtPos:moveEnCours.dest].side;
         if (typePiece != Invalide) {
            if (sidePiece == otherSide) {
               capture = YES;
               NSLog(@"\nPièce virtuellement prise: type= %d side (Noir 1, Blanc 2) %d",typePiece,sidePiece);
            }
         } /* Fin de bloc capture */
         /* QS : si depth = 0 et pas de prise on passe au move suivant sans aller plus loin dans la boucle */
         if(depth <= 0 && !capture) {
            NSLog(@"\n Move : %@ abandonné car sans capture Next Move !!", moveEnCours);
            continue;   // continue = on saute au PossibleMove suivant
         }
         ChessBoard *newBoard = board.copy;
         [newBoard PerformMove:moveEnCours]; // ==> on simule chaque move pour évaluer chaque board résultant
         
         // APPEL RÉCURSIF PERMETTANT DE POURSUIVRE LA SIMUL POUR LES TOURS DE PROFONDEUR (depth) 2 PUIS 1
         int score = -[self NegamaxForSide:otherSide  /* couleur permutée à chaque appel */
                                     board:newBoard   /* on se place dans une copie du board */
                                     depth:depth - 1  /* 'depth' passe de 3 (*) à 2, à 1, puis à 0 */
                                     alpha:-beta      /* alpha et bêta sont échangés à chaque nouvel appel */
                                      beta:-alpha];   /* car Max pour l'IA matche avec Min pour le Joueur */
         
         // LA SUITE N'EST EXÉCUTÉE QUE QUAND SCORE EST ÉVALUÉ (càd qd depth=0) ET QU'ON SORT DE NEGAMAX
         if (score >= alpha) {
            
            alpha = score; /* dans Négamax on cherche toujours la valeur Max (pas comme en minimax) */
            
            /* si les bornes de la fenêtre se croisent --> ÉLAGAGE BETA !! (on sort de la boucle for) */
            if (alpha >= beta) {
               nbElag ++; //NSLog(@"\n\t\t\t NegaFS : Branches élaguées = %d", nbElag);
               break; // break = sortie de la boucle 'for'
            }
            
         } // Fin de if score
      } // Fin de for chaque move possible
      
      //NSLog(@"\n\t\t NegaFS : Meilleure évaluation retournée par Negamax = %d",alpha);
      return alpha;
         
      
   } /* Fin de méthode 'NegamaxFS' */
   
   
   //***************************************************************************************************
   // Méthode de classe MCN
   // ex méthode 'scoreForSide' renommée pour une meilleure compréhension du but de la méthode
   // et pour éviter la confusion entre la variable 'score' de 'negamax'
   // MODIF du 22/09/22 - REVOIR, CONFIRMER ET COMMENTER
   // Méthode revue en lien avec la modification de la prise en compte de l'Évaluation par
   // l'algorithme Negamax (cf. 'MODIF du 17/09/22')
   +(int)EvalBoardForSide:(Side)side
                    board:(ChessBoard *)board
   {
      int evalForAlgo = 0;  /* Valeur retournée pour l'algorithme Negamax */
          evalDisplay = 0;  /* Valeur affichée respectant la convention (cf. Util.h) */
      
      /* ÉVALUATION MATÉRIELLE - On balaye chaque case de l'échiquier considéré, pour obtenir une valeur
      globale totalisant la valeur de chacune des pièces encore présentes. À noter que la valeur relative
      des pièces (au Roi près) est celle communément attribuée par la sphère échiquéenne */
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
                  d'évaluation, le moteur de l'IA, ainsi que la méthode gérant le déplacement des pièces- il
                  est important de lui accorder une forte valeur afin d'inciter l'IA à choisir, par appat du
                  gain, un coup qui permettrait de le capturer si c'était effectivement possible... */
               }
               
               /* Si la pièce est Blanche sa valeur s'ajoute au total, sinon elle est déduite
               (par conv. une éval + indique un avantage aux Blancs et une éval - un avantage aux Noirs) */
               evalDisplay += value * ((piece.side == sideWhite)? 1 : -1);   // INCRÉMENT VALEUR AFFICHÉE
               evalForAlgo += value * ((piece.side == side)? 1 : -1);
               
            } /* Fin de if piece*/
         } /* Fin de for y */
      } /* fin de for x */
      
      /* PRISE EN COMPTE DE LA MISE EN ÉCHEC ET MAT
      NB : La prise en compte de la mise en échec, implémentée un temps dans l'éval, a été abandonnée car
      elle perturbait le choix du coup quand il s'opposait à une prise potentielle de pièce, pour un bénéfice
      (la mise en échec) qui n'est finalement que temporaire sans garantir un avantage stratégique futur */
      //Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      
      /* Si les Noirs sont Mat */
      if ([self TestEchecRoiSide:sideBlack inBoard:board]) {
         if ([self PossibleMovesForSide:sideBlack board:board].count == 0) {
            evalDisplay += +100000; /* Valeur positive car situation favorisant les Blancs */
            evalForAlgo += +100000 * ((side == sideWhite)? 1 : -1);
         }
      }
      /* Si les Blancs sont Mat */
      else if ([self TestEchecRoiSide:sideWhite inBoard:board]) {
         if ([self PossibleMovesForSide:sideWhite board:board].count == 0) {
            evalDisplay += -100000; /* Valeur négative car situation favorisant les Noirs */
            evalForAlgo += +100000 * ((side == sideBlack)? 1 : -1);
         }
      }
      /* FIN DE PRISE EN COMPTE DE LA MISE EN ÉCHEC ET MAT  */
      
      /* PRISE EN CPTE DES PIONS EN AVANT-DERNIÈRE RANGÉE : +900 ACCORDÉS COMME SI DÉJÀ PROMUS EN DAMES
      Échiquier orienté avec les Blancs en bas */
      if (sideJoueur == sideWhite) {
         for (int x = 0; x < 8; x ++) {
            Piece *pionB = board->pieceCase[x][6];  // Pion Blanc en rangée 6
            if ((pionB.type == Pion) && (pionB.side == sideWhite)) {
               evalDisplay += +900; /* Valeur positive car situation favorisant les Blancs */
               evalForAlgo += +900 * ((side == sideWhite)? 1 : -1);
            }
            Piece *pionN = board->pieceCase[x][1];  // Pion Noir en rangée 1
            if ((pionN.type == Pion) && (pionN.side == sideBlack)) {
               evalDisplay += -900; /* Valeur négative car situation favorisant les Noirs */
               evalForAlgo += +900 * ((side == sideBlack)? 1 : -1);
            }
         }
      }
      /* Échiquier orienté avec les Noirs en bas */
      if (sideJoueur == sideBlack) {
         for (int x = 0; x < 8; x ++) {
            Piece *pionB = board->pieceCase[x][1];  // Pion Blanc en rangée 1
            if ((pionB.type == Pion) && (pionB.side == sideWhite)){
               evalDisplay += +900 ; /* Valeur positive car situation favorisant les Blancs */
               evalForAlgo += +900 * ((side == sideWhite)? 1 : -1);
            }
            Piece *pionN = board->pieceCase[x][6];  // Pion Noir en rangée 6
            if ((pionN.type == Pion) && (pionN.side == sideBlack)){
               evalDisplay += -900; /* Valeur négative car situation favorisant les Noirs */
               evalForAlgo += +900 * ((side == sideBlack)? 1 : -1);
            }
         }
      }
      /* FIN DE PRISE EN COMPTE DES PIONS ARRIVÉS SUR LEUR AVANT DERNIÈRE RANGÉE */

      /* Mise en forme du 'lblEvalBoard' de l'interface, avec un '+' ajouté aux valeurs positives */
      if (evalDisplay > 0)
            monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : +%d", evalDisplay];
      else  monMCNControleur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : %d",  evalDisplay];
      
      
      /* Ultime traitement pour satisfaire le principe d'inverser l'évaluation quand c'est aux Noirs de
      jouer, imposé par le fonctionnement de l'algorithme Negamax */
      //if (side == sideWhite) evalDisplay = -evalDisplay;
      /* if (sideIA == sideWhite) evalDisplay = evalDisplay;
      else if (sideIA == sideBlack) evalDisplay = -evalDisplay; */
      /* if (sideIA==sideBlack && side==sideBlack) evalDisplay = +evalDisplay;
      if (sideIA==sideBlack && side==sideWhite) evalDisplay = -evalDisplay;
      if (sideIA==sideWhite && side==sideBlack) evalDisplay = -evalDisplay;
      if (sideIA==sideWhite && side==sideWhite) evalDisplay = +evalDisplay; */
      
      return evalForAlgo;
      
   } /* Fin de Méthode 'EvalBoardForSide' */

   

   //***************************************************************************************************
   // Méthode de classe 'PossibleMoveForSide'
   // Détermine tous les 'moves' possibles d'un 'side', à partir de l'ensemble des positions possibles de
   // toutes les pièces de cette couleur présentes sur le 'board'
   // MCN - AJOUT D'UNE VÉRIF SYSTÉMATIQUE SI POSITION D'ÉCHEC GÉNÉRÉE AVANT VALIDATION ET AJOUT D'UN MOVE
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
                     // On réalise le move (dans une copie du board) pour contrôler l'abs de pos d'échec
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



   //***************************************************************************************************
   // MCN - Méthode de Classe (inspirée de 'PossibleMoveForSide') - Détection positions d'Échec en FAVEUR
   // de 'Side' (càd Roi 'otherSide' en échec). La méthode vise à déterminer tous les 'moves' possibles
   // coté 'side' d'un 'board' et à examiner si à chaque destination de chacun de ces 'moves' on trouve le
   // Roi adverse, auquel cas cela signifie qu'il est en échec. Comparée à sa version lite 'TestEchecRoiSide'
   // cette méthode est à réserver aux besoins d'affichage de la chaine de description complète de l'échec.
   // C'est elle qui cherche les positions d'échec multiples et qui gère les messages d'alerte correspondant.
   // NOTER que le Mat est confirmé par un test supplémentaire vérifiant qu'un protagoniste ne dispose plus
   // d'aucun coup autorisé.
   +(NSString *)TestEchecFavSide:(Side)side Board:(ChessBoard *)board
   {
      NSString *strEchec = @"";
      checkCount = 0;
      Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      /* On s'arrête sur chaque case du 'board' courant, on regarde si on y trouve une pièce, et si cette
      pièce est de couleur 'side'...     Si oui, pour chacune de ses destinations possibles... */
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
                     
                     /* DÉTECTION MISE EN ÉCHEC  ...on regarde si sur chacune de ces cases destination
                     il y a une pièce de la couleur opposée dont le type est Roi... Si oui, il y a Echec */
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
         /* CODE REMPLACÉ POUR FAIRE APPEL À LA DÉLÉGATION ChessView --> MCNconnecteur
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
         FIN DE CODE REMPLACÉ */
         
         /* Appel à Méthode déléguée par ChessView à MCNconnecteur */
         [monMCNControleur.maChessView.delegate AlerteEchecRoiSide:otherSide];
         NSLog(@"\n\t\t\t\t\t\t\tLa chaine strEchec est : %@",strEchec );

         return strEchec;
         
         
      } // fin if (strEchec...)
      
      return strEchec;
      
   }  // fin méthode TestEchecFavSide



   // **************************************************************************************************
   // MCN - Méthode de Classe - Version "lite" de 'TestEchecFavSide' (renvoyant quant à elle une chaine
   // décrivant la situation vis-à-vis de l'échec) visant à répondre RAPIDEMENT à la question de savoir si
   // le Roi est en échec, sans se soucier de dire si l'échec est simple ou double et si mat est confirmé...
   // NOTER que la question posée et la réponse apportée par les deux méthodes en question sont inverses
   // Cette méthode est adaptée (c'est sa raison d'être) pour valider ou non un MovePossible...
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
                        
                     // DÉTECTION MISE EN ÉCHEC  >> et sur chacune de ces cases destinations on regarde
                     // si on trouve notre Roi, auquel cas nous sommes en situation d'Échec :-(
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
            /* range : à partir du car à l'indice 0 et sur une long de len-1 pour supp le dernier char */
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
