//  Diagramme.m
//  Chess
//  Created by MCN on 03/04/2022
//  Copyright © 2022 MCN. All rights reserved

#import "Diagramme.h"


//static NSString *strPieces;
NSMutableString *strPiecesProv;
NSString *strPieces;

@implementation Diagramme

   // Initialisation des instances
   -(instancetype) init {
      self = [super init];
      maFileSerie = [[NSOperationQueue alloc] init];
      maFileSerie.maxConcurrentOperationCount = 1;   // limiter nb opés à 1 à la fois pour forcer une queue série
      codeFenOK=false;
      return self;
   }


   // ==================================================================================================
   // Implémentation du lien entre menu 'Diagramme' et code
   - (IBAction)SaisieCodeFEN:(id)sender {
      
      /*NSString *maChaineFEN;
      maChaineFEN = [self RecupCodeFEN];
      
      NSLog(@"La chaine saisie est : %@", maChaineFEN);*/
      
      [self TradFenEnView:[self RecupCodeFEN]];
      
   } // Fin de 'SaisieCodeFen'


   // ==================================================================================================
   // Implémentation du lien entre menu 'Proposer à l'IA' et code
   - (IBAction)DiagrammeIAvsIA:(id)sender {
      
      // Boite de saisie du code FEN
      [self TradFenEnView:[self RecupCodeFEN]];
      
      // Si codeFenOK est false on sort (test nécessaire pour éviter un crash du jeu)
      if (codeFenOK==false) return;
      
      // Initialisation des variables
      ChessView  *viewEC  = monConnecteur.maChessView;
      ChessBoard *boardEC = monConnecteur.maChessView->liveBoard;
      /* définition (et init) de compteur pour qu'il soit accessible et assignable dans un bloc */
      __block int compteur = 1;
      
      // Cas du trait aux Blancs
      if ([monConnecteur.lblTrait.cell.stringValue isEqual:@"Trait : Blancs"]) {
         // Boite de dialogue, générant une interruption rendant possible l'affichage du board avant moves
         NSAlert *stop1 = [[NSAlert alloc] init];
         [stop1 setMessageText:    @"Résolution de Diagramme IA vs IA"];
         [stop1 setInformativeText:@"Voici le Diagramme proposé à l'IA, Trait aux BLANCS, 100 coups max"];
         [stop1 addButtonWithTitle:@"OK, c'est parti !"];
         [stop1 setAlertStyle:NSAlertStyleInformational];
         [stop1 runModal];
         /* Boucle des coups successifs, limitée à 10 coups, Blancs au trait
         Tant que Blancs non Pat ou Mat ET Noirs non Pat ou Mat ET compteur inférieur à 10
         (mais dès que l'un des trois, on sort de la boucle)   */
         
         // BLOC NSOPERATION
         /* Théorie à vérifier : on empile ici dans un thread dédié tous les coups blancs (et noirs) */
         [self->maFileSerie addOperationWithBlock:^{
            
            /* Boucle 'limitée' à 100 coups max */
            while (compteur < 101) {
               
               sleep(1);
               //sideIA = sideWhite; sideJoueur = sideBlack; /* pour éval cohérente */
               [self SilentMakeIAMoveForSide:sideWhite Board:boardEC];
               /* Test pour provoquer une sortie de boucle si nécessaire */
               if ([maMinimax PossibleMovesForSide:sideBlack board:boardEC].count == 0) compteur = 101;
               /* Forcement du thread principal pour MàJ ChessView et liste coups */
               dispatch_async(dispatch_get_main_queue(), ^{
                  [viewEC setNeedsDisplay:YES];
                  [monConnecteur MaJtxtCoups];
               }); // Fin Dispatch
            
               /* Si les Noirs ne se retrouvent pas Pat ou Mat après le coup Blancs ci-dessus... */
               if ([maMinimax PossibleMovesForSide:sideBlack board:boardEC].count!=0) {
                  sleep(1);
                  /* ...alors on joue un coup Noirs */
                  //sideIA = sideBlack; sideJoueur = sideWhite; /* pour éval cohérente */
                  [self SilentMakeIAMoveForSide:sideBlack Board:boardEC];
                  /* Test pour provoquer une sortie de boucle si nécessaire */
                  if ([maMinimax PossibleMovesForSide:sideWhite board:boardEC].count == 0) compteur = 101;
                  /* Forcement du thread principal pour MàJ ChessView et liste coups */
                  dispatch_async(dispatch_get_main_queue(), ^{
                     [viewEC setNeedsDisplay:YES];
                     [monConnecteur MaJtxtCoups];
                  }); // Fin Dispatch
               } // Fin if
            
               compteur ++;
            } // Fin de while
         }]; // fin de bloc NSOperation
         
      } // Fin de if Trait aux Blancs
      
      // Cas du trait aux Noirs
      else if ([monConnecteur.lblTrait.cell.stringValue isEqual:@"Trait : Noirs"]) {
         
          // Boite de dialogue, générant une interruption rendant possible l'affichage du board avant moves
          NSAlert *stop1 = [[NSAlert alloc] init];
          [stop1 setMessageText:    @"Résolution de Diagramme IA vs IA"];
          [stop1 setInformativeText:@"Voici le Diagramme proposé à l'IA, Trait aux NOIRS, 100 coups max"];
          [stop1 addButtonWithTitle:@"OK, c'est parti !"];
          [stop1 setAlertStyle:NSAlertStyleInformational];
          [stop1 runModal];
          /* Boucle des coups successifs, limitée à 10 coups, Noirs au trait
          Tant que Noirs non Pat ou Mat ET Blancs non Pat ou Mat ET compteur inférieur à 10
          (mais dès que l'un des trois, on sort de la boucle)   */
          
         // BLOC NSOPERATION
         /* Théorie à vérifier : on empile ici dans un thread dédié tous les coups noirs (et blancs) */
          [self->maFileSerie addOperationWithBlock:^{
             
             /* Boucle 'limitée' à 100 coups max */
             while (compteur < 101) {
                
                sleep(1);
                //sideIA = sideWhite; sideJoueur = sideBlack; /* pour éval cohérente */
                [self SilentMakeIAMoveForSide:sideBlack Board:boardEC];
                /* Test pour provoquer une sortie de boucle si nécessaire */
                if ([maMinimax PossibleMovesForSide:sideWhite board:boardEC].count == 0) compteur = 101;
                /* Forcement du thread principal pour MàJ ChessView et liste coups */
                dispatch_async(dispatch_get_main_queue(), ^{
                   [viewEC setNeedsDisplay:YES];
                   [monConnecteur MaJtxtCoups];
                }); // Fin Dispatch
             
                /* Si les Blancs ne se retrouvent pas Pat ou Mat après le coup Noirs ci-dessus... */
                if ([maMinimax PossibleMovesForSide:sideWhite board:boardEC].count!=0) {
                   sleep(1);
                   /* ...alors on joue un coup Blancs */
                   //sideIA = sideWhite; sideJoueur = sideBlack; /* pour éval cohérente */
                   [self SilentMakeIAMoveForSide:sideWhite Board:boardEC];
                   /* Test pour provoquer une sortie de boucle si nécessaire */
                   if ([maMinimax PossibleMovesForSide:sideBlack board:boardEC].count == 0) compteur = 101;
                   /* Forcement du thread principal pour MàJ ChessView et liste coups */
                   dispatch_async(dispatch_get_main_queue(), ^{
                      [viewEC setNeedsDisplay:YES];
                      [monConnecteur MaJtxtCoups];
                   }); // Fin Dispatch
                } // Fin if
             
                compteur ++;
             } // Fin de while
          }]; // fin de bloc NSOperation
          
       } // Fin de if Trait aux Noirs
      
   } // Fin de 'DiagrammeIAvsIA'


   // ==================================================================================================
   // Méthode de classe permettant de récupérer un code FEN valide
   -(NSString *)RecupCodeFEN {
      
      // Initialisation de codeFenOK
      codeFenOK = false;
      
      /* Pour rappel du format d'un code FEN valide, voici celui de la position initiale d'un échiquier :
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq 0 1'   (notation internationale anglaise)
      Le code est toujours vu de la position des Blancs (échiquier orienté Blancs en bas)
      La lecture se fait de G à D et de Haut en Bas, càd de la case A8 (0,7) à la case H1 (7,0)    */
      NSString *strFEN;
      
      // Boite de saisie
      NSAlert *saisieFEN = [[NSAlert alloc] init];
      [saisieFEN setMessageText:    @"Code FEN"];
      [saisieFEN setInformativeText:@"Veuillez saisir ou coller un Code FEN valide"];
      [saisieFEN addButtonWithTitle:@"Ok"];
      [saisieFEN addButtonWithTitle:@"Annuler"];
      
      NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 266, 60)];
      [input setStringValue:@""];
      
      [saisieFEN setAccessoryView:input];
      NSInteger button = [saisieFEN runModal];
      // Bouton 'OK' choisi
      if (button == NSAlertFirstButtonReturn) {
         strFEN = [input stringValue];
      }
      // Bouton 'Annuler' choisi
      else if (button == NSAlertSecondButtonReturn) return EXIT_SUCCESS;
      
      /* Vérification du code FEN fourni, sachant qu'on ne contrôle ici que la partie 'Pièces' du code
       sur la base des critères suivants :
       - les lettres correspondent à des types de pièces
       - les slash séparant chaque rangée décrites sont au nombre de 7
       - les 64 cases sont prises en compte, vides ou non
       Au premier espace rencontré -ce qui se produit en fin de lecture des pièces- le contrôle s'interrompt.
       La vérification des indicateurs de roques, prise e.p.,... sera faite plus loin ou indiquée comme ignorée... */
      BOOL chainInvalide = NO;
      int nbSlash = 0;
      int nbCase = 0;
      char carLu;
      long i;
      strPiecesProv = [NSMutableString string];
      // le 'i' de la boucle est typé 'long' pour qu'il accepte la valeur '(strFEN.lenght)-1'
      for (i = 0; i < strFEN.length; i ++) {
         carLu = [strFEN characterAtIndex:i];
         [strPiecesProv appendFormat:@"%c", carLu]; // au passage on créé 'strPieces' en lui ajoutant chaque 'carLu'
         switch (carLu) {
            case '/':   nbSlash += 1;           break;
            case '1':   nbCase +=1;             break;
            case '2':   nbCase +=2;             break;
            case '3':   nbCase +=3;             break;
            case '4':   nbCase +=4;             break;
            case '5':   nbCase +=5;             break;
            case '6':   nbCase +=6;             break;
            case '7':   nbCase +=7;             break;
            case '8':   nbCase +=8;             break;
            case 'p':   nbCase +=1;             break;
            case 'r':   nbCase +=1;             break;
            case 'n':   nbCase +=1;             break;
            case 'b':   nbCase +=1;             break;
            case 'q':   nbCase +=1;             break;
            case 'k':   nbCase +=1;             break;
            case 'P':   nbCase +=1;             break;
            case 'R':   nbCase +=1;             break;
            case 'N':   nbCase +=1;             break;
            case 'B':   nbCase +=1;             break;
            case 'Q':   nbCase +=1;             break;
            case 'K':   nbCase +=1;             break;
            case ' ':   i = (strFEN.length)-1;  break; // au 1er ' ' rencontré on assigne à 'i' une valeur qui nous fera
            default:    chainInvalide = YES;    break; // sortir de la boucle 'for' après incrément auto de sa valeur
         }
         /* Si un caractère n'est pas reconnu, ou si on arrive au premier 'espace', alors on sort du 'for'
          Pour rappel on ne vérifie ici que la partie position des pièces du code FEN                */
         if ((chainInvalide) || (carLu == ' ')) break; // interruption du for
      }
      // autre cas d'invalidité de la chaine lue : il y a 8 rangée, il faut donc 7 slash
      if (nbSlash != 7) chainInvalide = YES;
      
      // Commutation de la variable d'instance codeFenOK pour utilisation externe
      if ((!chainInvalide) && (nbSlash = 7) && (nbCase = 64)) codeFenOK=true;
      
      // On recommence si pas OK pour les 3 critères (appel récursif conditionnel ;-)
      if ((chainInvalide) || (nbSlash != 7) || (nbCase != 64)) {
         
         codeFenOK=false;
         NSAlert *pasOK = [[NSAlert alloc] init];
         [pasOK setMessageText:@"Code FEN invalide"];
         [pasOK setInformativeText:@"La chaîne saisie n'est pas conforme au format attendu. Vérifiez et recommencez..."];
         [pasOK addButtonWithTitle:@"OK"];
         [pasOK setAlertStyle:NSAlertStyleInformational];
         [pasOK runModal];
         
         [self RecupCodeFEN];
      }
      
      // Création de la sous-chaine 'strPieces' définitive en supprimant l'espace final
      strPieces = [strPiecesProv substringToIndex:[strPiecesProv length]-1];
      
      
      NSLog(@"\nCode FEN lu : %@",strFEN);
      monConnecteur.lblInfo.cell.stringValue = @"Info : Diagramme correctement chargé !";
      return strFEN;
   }



   // ==================================================================================================
   // Méthode d'instance traduisant une chaine FEN valide en Board et View
   // NOTER QUE COMME IL S'AGIT D'UN TRAITEMENT DE FEN, ON PLACE FORCÉMENT LES BLANCS EN BAS
   -(void)TradFenEnView:(NSString *) stringFEN {
      
      if (codeFenOK==false) return;
      
      // Effacement d'un éventuel précédent board déjà construit
      ChessBoard *fenBoard = monConnecteur.maChessView->liveBoard;
      [self EffaceBoardBlancsEnBas:fenBoard];
      
      NSString *strTraitEtRoque;
      char caracLu;
      int i = 0;
   
      /* Lecture des caractères de la chaine valide FEN
      Il est à observer que compte tenu de la construction des boucles for x et y à 8 indices chacunes,
      la lecture s'arrêtera lorsque les 64 cases de l'échiquier auront été balayées.
      Ainsi le "case ' '" (laissé pour mémoire) ne sera jamais exécuté puisqu'il ne peut se produire
      (dans une chaine valide) avant que la dernière case de l'échiquier ait été balayée...*/
      for (int y=7; y>-1; y--) {
         for (int x=0; x<8; x++) {
            if (i > stringFEN.length-1) break;
            caracLu = [stringFEN characterAtIndex:i];
            switch (caracLu) {
               case 'r': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Tour side:sideBlack];  i++; break;
               case 'R': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Tour side:sideWhite];  i++; break;
               case 'n': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Cava side:sideBlack];  i++; break;
               case 'N': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Cava side:sideWhite];  i++; break;
               case 'b': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Fou  side:sideBlack];  i++; break;
               case 'B': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Fou  side:sideWhite];  i++; break;
               case 'q': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Dame side:sideBlack];  i++; break;
               case 'Q': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Dame side:sideWhite];  i++; break;
               case 'k': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Roi  side:sideBlack];  i++; break;
               case 'K': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Roi  side:sideWhite];  i++; break;
               case 'p': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Pion side:sideBlack];  i++;
                         fenBoard->pieceCase[x][y].numMoves = 1;                                             break;
               case 'P': fenBoard->pieceCase[x][y] = [[Piece alloc] initWithType:Pion side:sideWhite];  i++;
                         fenBoard->pieceCase[x][y].numMoves = 1;                                             break;
               case '1': x += 0; i++; break; // ⋀
               case '2': x += 1; i++; break; // |                              2          1 +1
               case '3': x += 2; i++; break; // | on veut décaler l'abcisse de 3 ici, càd 2 +1 d'incrément
               case '4': x += 3; i++; break; // |                              4          3 +1
               case '5': x += 4; i++; break; // |
               case '6': x += 5; i++; break; // |
               case '7': x += 6; i++; break; // |
               case '8': x += 7; i++; break; // ⋁
               case '/': x=-1;   i++; break; // X forcé à -1 plus 1 d'incrément = 0, càd début de rangée
               case ' ':              break; // cas qui n'est jamais rencontré dans une chaine valide...
               default :              break;
            } // sortie switch
         } // for x suivant jusqu'à 7
      } // for y suivant jusqu'à 0
      
      /* Il faut réautoriser les pions n'ayant pas bougé à avancer de 2 cases s'ils le 'souhaitent', puisque
       par défaut on les avait tous pénalisé (cf. plus haut traitement des pions dans le 'switch'         */
      [self OkDeuxCasesPionsBoard:fenBoard];
      
      /* Récupération de la chaine indiquant à qui est le Trait, et comment sont positionnés les indicateurs de Roque
      TODO : implémenter l'exploitation de cette chaine pour renseigner le board en conséquence...*/
      strTraitEtRoque = [stringFEN substringWithRange:NSMakeRange(i+1,stringFEN.length-(i+1))];
      // Suppression des caractères vides en fin de chaine 'strTraitEtRoque' tant qu'il y en a
      while ([strTraitEtRoque characterAtIndex:(strTraitEtRoque.length-1)] == ' ')  {
         strTraitEtRoque = [strTraitEtRoque substringWithRange:NSMakeRange(0,strTraitEtRoque.length-1)];
      }
      
      
      // NSLog de contrôle
      NSLog(@"\nMatrice : \n%@",fenBoard);
      NSLog(@"Sous-chaîne des Pièces            : '%@'",strPieces);
      NSLog(@"Sous-chaîne de Partie             : '%@'",strTraitEtRoque);
      
      [self LireSecondPartStrFEN:strTraitEtRoque];
      
      // Réglages d'orientation et de trait
      sideJoueur = sideWhite; sideIA = sideBlack; sideCourant = sideWhite;
      
      // Calcul d'EvalBoard
      monConnecteur.lblEvalBoard.cell.stringValue = [NSString stringWithFormat:@"Éval : %d",
                                                       [maMinimax EvalBoardForSide:sideWhite board:fenBoard]];
      
      // Récupération du 'focus' sur le ChessView instancié par l'application
      ChessView *fenView = monConnecteur.maChessView;
      
      fenView.needsDisplay = YES;
      
   } // Fin de Méthode TradFenEnView



   // ==================================================================================================
   // Méthode d'instance effaçant un ancien Diagramme et repositionnant les Blancs en bas,
   // ce qui implique que sideJoueur = sideWhite
   -(void)EffaceBoardBlancsEnBas:(ChessBoard *) board {
      
      for (int x=0; x < 8; x ++) {
         board->pieceCase[x][0] = nil;   // effacement rangée 0
         board->pieceCase[x][1] = nil;   // effacement rangée 1
         board->pieceCase[x][2] = nil;   // effacement rangée 2
         board->pieceCase[x][3] = nil;   // effacement rangée 3
         board->pieceCase[x][4] = nil;   // effacement rangée 4
         board->pieceCase[x][5] = nil;   // effacement rangée 5
         board->pieceCase[x][6] = nil;   // effacement rangée 6
         board->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // Réinitialisation de la liste des coups
      stringCoupsPartie = @"";
      [monConnecteur MaJtxtCoups];
      
      // Définition Couleurs Joueur et IA et MàJ repères de cases
      sideJoueur = sideWhite;    sideIA = sideBlack;
      [monConnecteur MajReperesCases];
      
   } // Fin de Méthode EffaceBoardBlancsEnBas



   // ==================================================================================================
   // Méthode d'instance repositionnant l'indicateur de 1er déplacement pour les pions d'un board qui
   // n'ont pas encore été joués, ce qui les autorise donc à avancer de 2 cases pour leur premier coup
   // ATTENTION LA MÉTHODE EST IMPLÉMENTÉE POUR ÊTRE UTILISÉE EXCLUSIVEMENT SUR DES DIAGRAMMES,
   // CÀD POUR DES BOARDS AVEC LES BLANCS EN BAS
   -(void)OkDeuxCasesPionsBoard:(ChessBoard *)board {
      
      for (int x=0; x<8; x++) {
         // si un pion blanc est en rangée 1, c'est qu'il n'a pas encore avancé
         if ((board->pieceCase[x][1].type == Pion) && (board->pieceCase[x][1].side == sideWhite))
                           board->pieceCase[x][1].numMoves = 0;
         // si un pion noir est en rangée 6, c'est qu'il n'a pas encore avancé
         if ((board->pieceCase[x][6].type == Pion) && (board->pieceCase[x][6].side == sideBlack))
                           board->pieceCase[x][6].numMoves = 0;
      }
   } // Fin de Méthode OkDeuxCasesPionsBoard


   // ==================================================================================================
   // Méthode d'instance effectuant la lecture des 5 derniers champs d'un code FEN
   -(void)LireSecondPartStrFEN:(NSString *)secondStr {
      
      //récupération du Trait : tjs 1er caractère de la sous-chaine 'Partie'
      NSString *sTrait;
      if ([secondStr characterAtIndex:0] == 'w') {sTrait = @"Trait : Blancs"; sideCourant = sideWhite;}
      else if ([secondStr characterAtIndex:0] == 'b') {sTrait = @"Trait : Noirs"; sideCourant = sideBlack;}
      else {sTrait = @"Trait : incorrect, valeur par défaut retenue (Blancs)"; sideCourant = sideWhite;}
      // Il n'y a pas de variable d'instance pour le Trait...
      monConnecteur.lblTrait.cell.stringValue = sTrait;
      NSLog(@"Phrase de la sous-chaîne du Trait : '%@'", sTrait);
      
      // Récupération de l'emplacement des espaces dans la chaine pour décrypter la suite
      int e[4];   int x = 0;
      for(int i=0; i < secondStr.length; i ++)
      {
         if([secondStr characterAtIndex:i] == ' ')
         {
            e[x]=i;
            x++;
         }
      }
      //NSLog(@"Espaces en sous-chaîne de Partie  : %d, %d, %d, et %d", e[0],e[1],e[2],e[3]);
      
      // Récupération des 4 chaines unitaires suivantes
      // Roque
      NSString *sRoque = [secondStr substringWithRange:NSMakeRange(e[0]+1, e[1]-(e[0]+1))];
      monConnecteur.maChessView->liveBoard->strRoque = sRoque;
      monConnecteur.lblRoque.cell.stringValue = [NSString stringWithFormat:@"Roque : %@", sRoque];;
      NSLog(@"Sous-chaîne du Roque              : '%@'", sRoque);
      // CibleEP
      NSString *sCibleEP = [secondStr substringWithRange:NSMakeRange(e[1]+1, e[2]-(e[1]+1))];
      monConnecteur.maChessView->liveBoard->strCibleEP = sCibleEP;
      monConnecteur.lblCibleEP.cell.stringValue = [NSString stringWithFormat:@"Cible e.p. : %@",sCibleEP];
      NSLog(@"Sous-chaîne de la CibleEP         : '%@'", sCibleEP);
      // Demis
      NSString *sDemis = [secondStr substringWithRange:NSMakeRange(e[2]+1, e[3]-(e[2]+1))];
      monConnecteur.maChessView->liveBoard->nbDemis = [sDemis intValue];
      monConnecteur.lbl50Coups.cell.stringValue = [NSString stringWithFormat:@"50 demis : %@", sDemis];
      NSLog(@"Sous-chaîne du n° des Demis       : '%@'", sDemis);
      // Coup : tjs dernier caractère de la chaine
      NSString *sCoup = [secondStr substringWithRange:NSMakeRange(e[3]+1,secondStr.length-(e[3]+1))];
      monConnecteur.maChessView->liveBoard->nbEntiers = [sCoup intValue];
      monConnecteur.lblNumCoup.cell.stringValue = [NSString stringWithFormat:@"Coup n° : %@", sCoup];;
      NSLog(@"Sous-chaîne du n° du Coup         : '%@'\n", sCoup);
   
   } // Fin de Méthode 'LireSecondPartStrFEN'

   
   // ==================================================================================================
   // Méthode permettant d'accéder à MakeIAMoveForSide sans passer de params et donc de l'utiliser
   // dans un NSTimer
   -(void)LancerCoupNoirs {
      
      ChessView  *viewEC  = monConnecteur.maChessView;
      ChessBoard *boardEC = monConnecteur.maChessView->liveBoard;
      
      [viewEC MakeIAMoveForSide:sideBlack Board:boardEC];
   }

   
   // ==================================================================================================
   // REALISATION DES DEPLACEMENTS CALCULÉS PAR L'IA  -  Version silencieuse de 'MakeIAMoveForSide'
   // permettant à l'IA de jouer des deux côtés alternativement, tout en testant le 'moteur'
   -(void)SilentMakeIAMoveForSide:(Side)side Board:(ChessBoard *)board
   {
      sideCourant = side; // affectation nécessaire car MakeIAMoveFS peut être appelée à tout moment
      Move *aiMove = [maMinimax BestMoveForSide:side Board:board];
      ChessBoard* savedBoard = board.copy; // Sauvegardé pour usage dans 'ConvertEnStringMove' avt 'PerformMove'
      
      // Réalisation du move - NOTER : c'est 'PerformMove' qui positionne les indicateurs de roque
      [board PerformMove:aiMove];
      
      /* Sauvegarde des indic de roque  et de prise e.p. car RAZ plus loin par 'TestEchecFavSide' (???)
      avant de pouvoir les exploiter dans 'ConvertEnStringMove' */
      BOOL roque = petitRoque;         BOOL ROQUE = grandRoque;         BOOL ENPASS = enPassant;
      
      /* MCN - AJOUT DU COUP IA À LA LISTE DE CEUX DÉJÀ JOUÉS
      EXTRACTION ET TRANSFORMATION de la chaine contenue dans 'move' en notation plus standard
       
      Vérification s'il y a une promo de pion à réaliser
      Test à faire avant 'TestEchecFavSide' car la promo peut générer une mise en échec */
      Piece *pionPromo = [board pieceAtPos:aiMove.dest];       NSString *promPion = @"";
      if (pionPromo.type == Pion) {
         if (aiMove.dest.y == 0 || aiMove.dest.y == 7)
            promPion = [board SelectPromoPion:pionPromo auRang:aiMove.dest.y];
      }
      
      /* Récup info d'une mise en échec éventuelle et de Prise e.p. pour renseigner 'ConvertEnStringMove'
      Bizarrement 'TestEchecForSide' RAZ les indic de Roque et de Prise e.p., d'où la sauvegarde ci-avant */
      NSString *strEchec = [Diagramme SilentTestEchecFavSide:side Board:board];
      
      NSLog(@"\nLe Move effectué par les %@ est : %@", (sideCourant == 2)? @"Blancs":@"Noirs ", aiMove);
      if (![strEchec isEqual:@""]) NSLog(@"\nLa chaîne d'échec est : '%@'", strEchec);
      
      // Restauration des indicateurs de roque pour utilisation dans 'ConvertEnStringMove'
      petitRoque = roque;           grandRoque = ROQUE;           enPassant = ENPASS;
      
      NSMutableString* bestMoveIA = [MoveToStr ConvertEnStringMove:aiMove    PromPion:promPion
                                                             StrEchec:strEchec     Board:savedBoard];
      
      /* Ligne déplacée dans le Thread Principal ci dessous
      [MoveToStr MettreEnFormeChaine:bestMoveIA Protagoniste:(side == sideWhite)? @"B":@"N"]; */
      
      // Test examinant si le coup IA met le Joueur Mat...
      Side otherSide = (side == sideWhite)? sideBlack : sideWhite;
      NSSet *movesPossibles = [maMinimax PossibleMovesForSide:otherSide board:board];
      
      /* Ligne déplacée dans le thread principal
      if (movesPossibles.count == 0) [Diagramme SilentAlertMsgPatMatSide:otherSide onBoard:board]; */
      
      
      // MAIN THREAD POUR MàJ DE L'UI
      dispatch_async(dispatch_get_main_queue(), ^{
          
         // 1) Mise en forme de la chaîne (appelle MaJtxtCoups)
         [MoveToStr MettreEnFormeChaine:bestMoveIA Protagoniste:(side == sideWhite)? @"B":@"N"];
         
         // 2) Notification Pat/Mat si nécessaire
         if (movesPossibles.count == 0) {
            [Diagramme SilentAlertMsgPatMatSide:otherSide onBoard:board];
         }
         
         // 3) MISE À JOUR 'STATUS BAR' HORS EVAL ET TRAIT
         [self SilentMajStatusBarViaMove:aiMove PrecBoard:savedBoard StrCheck:strEchec];
          
         // 4) MISE À JOUR DE L'AFFICHAGE DE L'ÉVAL DU BOARD APRÈS LE COUP
         /* int finalEval = [Minimax EvalBoardForSide:sideWhite board:board];
         if (finalEval > 0)
            monConnecteur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : +%d", finalEval];
         else
            monConnecteur.lblEvalBoard.cell.title = [NSString stringWithFormat:@"Éval : %d", finalEval]; */
         NSLog(@"EvalWhitePOV = %d, Indicator = %@", evalWhitePOV, [ChessView VisualIndicator:evalWhitePOV]);
         monConnecteur.lblEvalBoard.cell.title = [ChessView VisualIndicator:evalWhitePOV];
          
         // 5) L'IA ayant joué on inverse sideCourant
         sideCourant = (sideCourant == sideWhite) ? sideBlack : sideWhite;
         monConnecteur.lblTrait.cell.stringValue = (sideCourant == sideWhite)? @"Trait : Blancs": @"Trait : Noirs";
         
      });
      
   } // Fin de SilentMakeIAMoveForSide


   // ==================================================================================================
   // MCN - Version silencieuse de 'TestEchecFavSide'
   // Détection des positions d'Échec en faveur du coté 'Side' (autrement dit Roi 'otherSide' en échec)
   +(NSString *)SilentTestEchecFavSide:(Side)side Board:(ChessBoard *)board
   {
      NSString *strEchec = @"";
      checkCount = 0;
      Side otherSide = (side == sideWhite)? sideBlack:sideWhite;
      // On s'arrête sur chaque case du 'board' courant, on regarde si on y trouve une pièce, et si
      // cette pièce est de couleur 'side'...     Si oui, pour chacune de ses destinations possibles...
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
                  NSSet *PosAcceptees = [RuleBook PosLegalesForPiece:piece atPos:pos inBoard:board];
                  for (Pos *possibleDest in PosAcceptees)
                  {
                     Move *moveSide = [[Move alloc] initWithStart:pos Dest:possibleDest];
                     
                     // DÉTECTION MISE EN ÉCHEC  ...on regarde si sur chacune de ces cases destination,
                     // il y a une pièce de la couleur opposée dont le type est Roi. Si oui, il y a Echec
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
      
      /*  Il est nécessaire de parcourir la boucle de détection d'ÉCHEC ci-avant jusqu'au bout sans en
       sortir à la première détection, ceci afin de pouvoir comptabiliser les échecs multiples. On peut
       ensuite afficher une boite de dialogue signifiant l'ÉCHEC quand il est effectivement avéré.     */
      
      return strEchec;
      
   }  // fin méthode SilentTestEchecFavSide


   // ==================================================================================================
   // Méthode MCN - Version silencieuse de MajStatusBarViaMove
   // Mettant à jour la majorité des champs de la 'Barre d'état'
   -(void) SilentMajStatusBarViaMove:(Move *)move PrecBoard:(ChessBoard *)precBoard StrCheck:(NSString *)strCheck {
      // lblTrait
      //monConnecteur.lblTrait.cell.stringValue = (sideCourant==sideWhite)? @"Trait : Blancs": @"Trait : Noirs";
      // lblRoque
      [monConnecteur.maChessView->liveBoard CalculerStrRoque];
      monConnecteur.lblRoque.cell.stringValue = [NSString stringWithFormat:@"Roque : %@",
                                                    monConnecteur.maChessView->liveBoard->strRoque];
      // lblCibleEP
      [monConnecteur.maChessView->liveBoard DeterminerCibleEP:move];
      monConnecteur.lblCibleEP.cell.stringValue = [NSString stringWithFormat:@"Cible EP : %@",
                                                      monConnecteur.maChessView->liveBoard->strCibleEP];
      //lbl50Coups
      [precBoard CompterDemiCoups:move];
      monConnecteur.lbl50Coups.cell.stringValue = [NSString stringWithFormat:@"50 demis : %d",
                                                      monConnecteur.maChessView->liveBoard->nbDemis];
      /* if (monConnecteur.maChessView->liveBoard->nbDemis == 50)
                     [monConnecteur.maChessView->liveBoard ProposerNulle50Coups]; */
      // lblCoup
      if (sideCourant == sideBlack) monConnecteur.maChessView->liveBoard->nbEntiers ++;
      monConnecteur.lblNumCoup.cell.stringValue = [NSString stringWithFormat:@"n° coup : %d",
                                                      monConnecteur.maChessView->liveBoard->nbEntiers];
      // lblEchec
      if ([strCheck isEqual:@"Echec"]) {
         if (checkCount >1) monConnecteur.lblEchec.cell.stringValue = @"Échec : ++";
         else               monConnecteur.lblEchec.cell.stringValue = @"Échec : +";
      }
      else                  monConnecteur.lblEchec.cell.stringValue = @"Échec :";
      /* lblInfo : traité par ailleurs et en dehors des seuls cas des moves exécutés, puisqu'il s'agit
       davantage de renseigner l'utilisateur sur le déroulement de la partie...*/
   } // Fin de Méthode 'SilentMajStatusBarViaMove'



   // ==================================================================================================
   // MCN - Méthode de classe pour assurer la gestion du Pat et du Mat - Version silencieuse
   // CETTE MÉTHODE NE DOIT ÊTRE APPELÉE QU'APRÈS QU'UN TEST SUR 'PossibleMovesForSide' AIT RÉVÉLÉ QUE LE
   // JEU DE MOVES EST VIDE, CAR C'EST BIEN CE TEST QUI CARACTÉRISE UNE SITUATION DE MAT OU DE PAT,
   // LA PRÉSENTE MÉTHODE NE FAIT QUE LA TRAITER...
   +(void)SilentAlertMsgPatMatSide:(Side)side
                             onBoard:(ChessBoard*)board
   {
      // MAT - Par définition, si on est ici c'est que 'side' n'a plus de move possible...
      // ...et si en plus 'side' est Échec sur le board actuel, c'est que 'side' est Mat
      if ([maMinimax TestEchecRoiSide:side inBoard:board])
      {
         // Traitement des chaines : liste des coups et messages
         NSString *msgTitre;
         NSString *msgInfo;
         // Suppression des caractères vides en fin de chaine 'stringCoupsPartie' tant qu'il y en a
         while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == ' ')  {
            // range : à partir du char à l'indice 0 et sur une longueur de len-1 pour supp le dernier char
            stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
         }
         // Suppression des caractères '+' en fin de chaine tant qu'il y en a
         while ([stringCoupsPartie characterAtIndex:(stringCoupsPartie.length-1)] == '+')  {
            stringCoupsPartie = [stringCoupsPartie substringWithRange:NSMakeRange(0,stringCoupsPartie.length-1)];
         }
         
         // Mise à jour 'Status Bar'
         monConnecteur.lblEchec.cell.stringValue = @"Échec et Mat !";
         
         // Boite de dialogue
         if (side == sideBlack)
         {  msgTitre = @"Les  NOIRS  sont Mat !";
            msgInfo = @"Partie terminée, Les BLANCS gagnent !";
            // Mise à jour de la liste des coups et du contrôle 'txtView'
            // on ajoute un '#' pour signifier mat, puis 1-0 pour "les Blancs gagnent"
            stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t1-0"];
            [monConnecteur MaJtxtCoups];
         }
         else if (side == sideWhite)
         {  msgTitre = @"Les  BLANCS  sont Mat !";
            msgInfo = @"Partie terminée, Les NOIRS gagnent !";
            // Mise à jour de la liste des coups et du contrôle 'txtView'
            // on ajoute un '#' pour signifier mat, puis 0-1 pour "les Noirs gagnent"
            stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"#\n\t0-1"];
            [monConnecteur MaJtxtCoups];
         }
         
         stopMatOuPat = YES;
         
      } // fin if de niv 1 et de MAT
      
      // PAT - Mais si au contraire il n'y a pas situation d'échec, c'est que 'side' est simplement Pat
      else
      {
         // Si pas de move possible mais pas de situation d'Échec alors 'Pat'
         // Mise à jour de la liste des coups et du contrôle 'textView'
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\n\t1/2-1/2"];
         [monConnecteur MaJtxtCoups];
         
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
         
         // Mise à jour 'Status Bar'
         monConnecteur.lblEchec.cell.stringValue = @"Pat !";
         
         stopMatOuPat = YES;
         
      } // fin else de niv 1 et de PAT
   } // Fin de Méthode 'SilentAlertMsgPatMatSide'



@end
