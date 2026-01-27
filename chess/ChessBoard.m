//  ChessBoard.m
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN in 2020


//  CLASSE DE DÉFINITION DE L'ÉCHIQUIER EN TERMES DE DONNÉES (couleur, nature, position des pièces...)
//  par opposition à la classe ChessView qui traite la représentation graphique du 'board'

#import "ChessBoard.h"


@implementation ChessBoard


   @synthesize lastMove; // Ajout MCN pour accéder à lastMove hors de sa classe, dans RuleBook
   


   // **************************************************************************************************
   // Méthode d'instance
   -(id)init
   {
      if (self=[super init]) {
         
         /* INITIALISATION DES VARIABLES D'INSTANCE : c'est dans une méthode 'init' qu'il faut faire les
         initialisations des variables dont on désire fixer une valeur initiale autre que '0/NULL/nil' */
         strRoque    = @"KQkq";
         strCibleEP  = @"-";
         nbDemis     = 0;
         //nbDemis     = 49; // pour tester NSAlert50coups
         nbEntiers   = 1;
      }
      return self;
   }

   
   // **************************************************************************************************
   // MCN - Méthode d'instance lançant une nouvelle partie, le JOUEUR choisissant LES BLANCS
   - (IBAction)NewPartieJoueurBlancs:(id)sender {
      
      // Effacement d'un éventuel précédent board déjà construit
      for (int x=0; x < 8; x ++) {
         self->pieceCase[x][0] = nil;   // effacement rangée 0
         self->pieceCase[x][1] = nil;   // effacement rangée 1
         self->pieceCase[x][2] = nil;   // effacement rangée 2
         self->pieceCase[x][3] = nil;   // effacement rangée 3
         self->pieceCase[x][4] = nil;   // effacement rangée 4
         self->pieceCase[x][5] = nil;   // effacement rangée 5
         self->pieceCase[x][6] = nil;   // effacement rangée 6
         self->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // RAZ indicateurs
      nbDemis   = 0;
      nbEntiers = 1;
      lastMove  = nil;

      // Réinitialisation de la liste des coups
      stringCoupsPartie = @"";
      numCoup = 2; // N° des coups joués, initialisé à 2 car le n°1 est intégré au 1er coup
      [monMCNControleur MaJtxtCoups];
      
      // Définition Couleurs Joueur et IA et MàJ repères de cases
      sideJoueur = sideWhite;    sideIA = sideBlack;
      [monMCNControleur MajReperesCases];
      
      // Les pièces sont créées sur le board, les BLANCS en BAS
      [self SetupPieces];
      
      // Chargement du board dans la vue active et rafraichissement
      monMCNControleur.maChessView->liveBoard = self;
      monMCNControleur.maChessView.needsDisplay = YES;
      
      //MàJ des menus
      monMCNControleur.menuPoursuivre.title = @"Poursuivre avec les Noirs";
      monMCNControleur.menuPoursuivre.enabled = YES;
      
   }

   
   // **************************************************************************************************
   // MCN - Méthode d'instance lançant une nouvelle partie, le JOUEUR choisissant LES NOIRS
   - (IBAction)NewPartieJoueurNoirs:(id)sender {
      
      // Effacement d'un éventuel précédent board déjà construit
      for (int x=0; x < 8; x ++) {
         self->pieceCase[x][0] = nil;   // effacement rangée 0
         self->pieceCase[x][1] = nil;   // effacement rangée 1
         self->pieceCase[x][2] = nil;   // effacement rangée 2
         self->pieceCase[x][3] = nil;   // effacement rangée 3
         self->pieceCase[x][4] = nil;   // effacement rangée 4
         self->pieceCase[x][5] = nil;   // effacement rangée 5
         self->pieceCase[x][6] = nil;   // effacement rangée 6
         self->pieceCase[x][7] = nil;   // effacement rangée 7
      }
      
      // RAZ indicateurs
      nbDemis   = 0;
      nbEntiers = 1;
      lastMove  = nil;
      
      // Réinitialisation de la liste des coups
      stringCoupsPartie = @"";
      numCoup = 2; // N° des coups joués, initialisé à 2 car le n°1 est intégré au 1er coup
      [monMCNControleur MaJtxtCoups];
      
      // Définition Couleurs Joueur et IA et MàJ repères de cases
      sideJoueur = sideBlack;    sideIA = sideWhite;
      [monMCNControleur MajReperesCases];
      
      // Les pièces sont créées sur le board, les NOIRS en BAS
      [self SetupPieces];
      
      // Chargement du board dans la vue active et rafraichissement
      monMCNControleur.maChessView->liveBoard = self;
      monMCNControleur.maChessView.needsDisplay = YES;
      
      // Affichage du 1er coup de l'IA qui joue les BLANCS
      [monMCNControleur InitialiseTxtCoups:stringCoupsPartie];
      
      //MàJ des menus
      monMCNControleur.menuPoursuivre.title = @"Poursuivre avec les Blancs";
      monMCNControleur.menuPoursuivre.enabled = YES;
      
   }

   
   // **************************************************************************************************
   // MCN IBAction vers Méthode inversant l'échiquier
   - (IBAction)RetournerBoard:(id)sender {
      
      // Recopie des pièces du boardA vers le boardB
      ChessBoard *boardA = monMCNControleur.maChessView->liveBoard;
      ChessBoard *boardB = [[ChessBoard alloc]init];
      for (int x=0; x<8; x++) {
         for (int y=0; y<8; y++){
            if (boardA->pieceCase[x][y])
               
               boardB->pieceCase[7-x][7-y] = [[Piece alloc] initWithType:boardA->pieceCase[x][y].type                                                                         side:boardA->pieceCase[x][y].side];
         }
      }
      
      // Récupération des variables d'instance du board d'origine
      boardB->strRoque   = boardA->strRoque;
      boardB->strCibleEP = @"-";             // car de toutes façons RAZ ou MàJ par prochain coup
      boardB->nbDemis    = boardA->nbDemis;
      boardB->nbEntiers  = boardA->nbEntiers;
      
      // Focus sur le nouveau board
      monMCNControleur.maChessView->liveBoard = boardB;
      monMCNControleur.maChessView.needsDisplay = YES;
      
      // Recalage de la partie
      if (sideJoueur == sideWhite) {
         sideJoueur = sideBlack;
         sideIA = sideWhite;
         [monMCNControleur.maChessView MakeIAMoveForSide:sideWhite Board:boardB];
         sideCourant = sideBlack;
      }
      else if (sideJoueur == sideBlack) {
         sideJoueur = sideWhite;
         sideIA = sideBlack;
         [monMCNControleur.maChessView MakeIAMoveForSide:sideBlack Board:boardB];
         sideCourant = sideWhite;
      }
      
      // MàJ repérage des cases et de la 'status bar'
      [monMCNControleur MajReperesCases];
      monMCNControleur.lblRoque.cell.stringValue   = [NSString stringWithFormat:@"Roque : %@",      boardB->strRoque];
      monMCNControleur.lblCibleEP.cell.stringValue = [NSString stringWithFormat:@"Cible e.p. : %@", boardB->strCibleEP];
      monMCNControleur.lbl50Coups.cell.stringValue = [NSString stringWithFormat:@"50 demis : %d",   boardB->nbDemis];
      monMCNControleur.lblNumCoup.cell.stringValue = [NSString stringWithFormat:@"Coup n° : %d",    boardB->nbEntiers];
      
      // MàJ menus
      if([monMCNControleur.menuPoursuivre.title isEqual:@"Poursuivre avec les Blancs"])
                monMCNControleur.menuPoursuivre.title = @"Poursuivre avec les Noirs";
      else      monMCNControleur.menuPoursuivre.title = @"Poursuivre avec les Blancs";
      //boardA = nil;
      
   } // Fin de Méthode 'RetournerBoard'


   // **************************************************************************************************
   // INITIALISATION DES PIECES SUR L'ECHIQUIER (AFFECTATION DE LEUR POSITION EN DEBUT DE PARTIE)
   // Cette METHODE est appelée dans ChessView.m
   -(void)SetupPieces
   {
      // Détermination des couleurs JOUEUR et IA, avant construction de l'échiquier
      //[self DefCouleurJoueur]; // La méthode d'instance est implémentée plus bas
      
      // Initialisation des éléments du tableau à 2 entrées représentant le positionnement des pièces
      // Première rangée (ligne 0) des pièces du JOUEUR en début de partie
      pieceCase[0][0] = [[Piece alloc] initWithType:Tour side:sideJoueur];
      pieceCase[1][0] = [[Piece alloc] initWithType:Cava side:sideJoueur];
      pieceCase[2][0] = [[Piece alloc] initWithType:Fou  side:sideJoueur];
      
      // MCN - Selon l'orientation de l'échiquier la ligne 0 reçoit les Blancs ou les Noirs
      // et les positions de la Reine et du Roi sont à adapter en conséquence
      pieceCase[3][0] = [[Piece alloc] initWithType:(sideJoueur == sideWhite)? Dame : Roi side:sideJoueur];
      pieceCase[4][0] = [[Piece alloc] initWithType:(sideJoueur == sideWhite)? Roi : Dame side:sideJoueur];
      pieceCase[5][0] = [[Piece alloc] initWithType:Fou  side:sideJoueur];
      pieceCase[6][0] = [[Piece alloc] initWithType:Cava side:sideJoueur];
      pieceCase[7][0] = [[Piece alloc] initWithType:Tour side:sideJoueur];
      
      // Balayage horizontal, de l'abcisse x=0 à l'abcisse x=7
      for (int x = 0; x < 8; x++)
      {
         // Pions JOUEUR en ligne 1
         pieceCase[x][1] = [[Piece alloc] initWithType:Pion  side:sideJoueur];
         // Pions IA en ligne 6
         pieceCase[x][6] = [[Piece alloc] initWithType:Pion  side:sideIA];
         
         // Puis recopie de la ligne 0 en ligne 7, pour les pièces de l'IA
         // Pas besoin de s'inquiéter de l'orientation de l'échiquier puisque les Dames et les Rois se font tjs face
         pieceCase[x][7] = [[Piece alloc] initWithType:pieceCase[x][0].type side:sideIA];
      }
      
      // MCN - FORCER L'IA À JOUER EN PREMIER QUAND ELLE A LES BLANCS
      // L'appel à la méthode idoine placé ici, anachroniquement, mais juste après initialisation de l'échiquier,
      // garantit qu'il ne sera fait qu'une seule fois dans la partie, et en tout début.
      if (sideJoueur == sideBlack) {
         [self PremCoupAIBlancs];
      } // Fin de Forcer l'IA à jouer
      
   }

   
   // **************************************************************************************************
   // Méthode d'instance - Jouant le role d'accesseur à pieceCase
   // Retourne la pièce positionnée en (x,y)
   -(Piece *)piece_colX:(int)x rangY:(int)y
   {
      if (x < 0 || y < 0 || x > 7 || y > 7) return nil;
      return pieceCase[x][y];
   }

   
   // **************************************************************************************************
   // Méthode d'instance
   // retourne la pièce positionnée en 'pos'
   -(Piece *)pieceAtPos:(Pos *)pos
   {
      int x = pos.x, y = pos.y;
      if (x < 0 || y < 0 || x > 7 || y > 7) return nil;
      return pieceCase[x][y];
   }

   
   // **************************************************************************************************
   // Méthode d'instance
   -(void)PerformMove:(Move *)move
   {
      // MCN - Sauvegarde du board avant le move, pour test de prise en passant un peu plus bas
      ChessBoard *boardEP = self.copy;
      enPassant = NO;
      
      /* DÉPLACEMENT DE PIÈCES DANS LE CAS GÉNÉRAL
      NB: 'MovePieceDeStart' déplace la pièce sur le nouvel emplacement et la supprime de l'ancien */
      Piece *piece = [self MovePieceDeStart:move.start ADest:move.dest];
      
      /* 1er Complément au 'move' ci avant, pour gérer le roque s'il y a lieu, car quand
      le Roi JOUEUR roque, la tour concernée se déplace également
      RAZ indicateurs de roque avant tests */
      petitRoque = NO;        grandRoque = NO;
      if (piece.type == Roi && abs(move.dest.x - move.start.x) > 1) {
         // if MCN : le joueur a les Blancs
         if (sideJoueur == sideWhite) {
            // si la dest du Roi est la case 2, c'est la Tour de G qui est concernée (grand roque)
            // sinon c'est la tour D qui est concernée (petit roque)
            int rookX = (move.dest.x == 2) ? 0 : 7; // rookX : case de départ de la Tour G (0) ou D (7)
            // la Tour de G bascule en case 3, ou la Tour de D bascule en case 5
            int rookDestX = (rookX == 0) ? 3 : 5; // rookDestX : case d'arrivée de la Tour G = 3, ou D = 5
            
            petitRoque = (rookX == 0) ? NO : YES;
            grandRoque = (rookX == 0) ? YES : NO;
            
            [self MovePieceDeStart:[Pos posWithX:rookX y:move.dest.y] ADest:[Pos posWithX:rookDestX y:move.dest.y]];
         } // Fin if MCN
         
         // Modif. MCN, second traitement gérant le cas du JOUEUR ayant les Noirs
         if (sideJoueur == sideBlack) {
            /* si la dest du Roi est la case 1 c'est la Tour de G qui est concernée (petit roque)
            sinon c'est la Tour D qui est concernée (grand roque) */
            int rookX = (move.dest.x == 1) ? 0 : 7;
            // la Tour de G bascule en case 2, ou la Tour de D bascule en case 4
            int rookDestX = (rookX == 0) ? 2 : 4;
            
            petitRoque = (rookX == 0) ? YES : NO;
            grandRoque = (rookX == 0) ? NO : YES;
            
            [self MovePieceDeStart:[Pos posWithX:rookX y:move.dest.y] ADest:[Pos posWithX:rookDestX y:move.dest.y]];
         }
      }
      
      /* MCN - PRISE E.P.
      2ème Complément au 'move' du cas général, pour gérer la prise en passant caractérisée par le fait
      que c'est le seul cas de figure où le pion avance en diagonale sans prise de pièce.
      Cette seule particularité de déplacement est suffisante pour caractériser la prise e.p.
      C'est donc l'objet du test ci-après
      On raisonne sur le boardEP, càd avant le move du pion...
      Si la pièce est un pion... */
      if (piece.type == Pion) {
         // qui se déplace en diagonale...
         if (abs(move.start.x - move.dest.x) == 1) {
            // pour atterrir sur une case où il n'y avait pas de pièce...
            if ([boardEP pieceAtPos:move.dest].type == Invalide) {
               /* ... alors on est bien dans le cas d'une prise e.p.
               on supprime alors le pion adverse (faire un croquis pour la compréhension des ordo visées ;-)
               NB : pour rappel 'pieceCase' est une variable d'instance de la classe 'ChessBoard' */
               pieceCase[move.dest.x][move.start.y] = nil;
               // et on positionne l'indicateur e.p. sur YES
               enPassant = YES;
            }
         }
      } // Fin de MCN PRISE E.P.
      
      
      // Sauvegarde du move comme étant le dernier du board
      self.lastMove = move;
      
   }

    
   // **************************************************************************************************
   // Méthode d'instance
   -(Piece *)MovePieceDeStart:(Pos *)start ADest:(Pos *)dest
   {
      // move in board
      pieceCase[(int)dest.x][(int)dest.y] = pieceCase[(int)start.x][(int)start.y];
      
      Piece *piece = pieceCase[(int)dest.x][(int)dest.y];
      piece.numMoves++; // increment number of moves
      
      // effacement de la pièce de la case de départ
      pieceCase[(int)start.x][(int)start.y] = nil;
      
      return piece;
   }

   
   // **************************************************************************************************
   // Méthode exigée par le Protocol NSCopying dont hérite la classe ChessBoard
   // Elle n'est pas directement appelée, mais est utilisée dès qu'on envoie un message copy sur un objet
   // ChessBoard
   -(id)copyWithZone:(NSZone *)zone
   {
      ChessBoard *newBoard = [[ChessBoard allocWithZone:zone] init];
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            if (pieceCase[x][y]) newBoard->pieceCase[x][y] = pieceCase[x][y].copy;
         }
      }
      newBoard.lastMove = self.lastMove.copy;
      return newBoard;
   }

   // **************************************************************************************************
   // 'description' est une @property existante de la classe NSObject retournant une NSString
   // Dans le cas de notre programme elle est sollicitée implicitement lors d'un affichage console
   // Dans cette perspective elle est surdéfinie ci-dessous en Méthode d'instance permettant l'affichage
   // d'une situation de l'échiquier sous forme de matrice
   -(NSString *)description
   {
      NSString *matrice = @"";
      for (int y = 7; y >= 0; y--)    // Balayage des ordonnées
      {
         for (int x = 0; x < 8; x++)  // Balayage des abcisses
         {
            matrice = [matrice stringByAppendingFormat:@"%d ",pieceCase[x][y].type];
         }
         
         matrice = [matrice stringByAppendingString:@"\n"]; // ajout retour chariot en fin de rangée
      }
      return matrice;
   }

   
   // **************************************************************************************************
   // MCN
   // Méthode d'instance permettant d'affecter la couleur de chacun des adversaires, Humain et Machine
   // MÉTHODE DÉSUETTE DEPUIS LA REFONTE DE L'UI DÉMARRANT SUR UN ÉCHIQUIER VIDE...
   -(void)DefCouleurJoueur
   {
      if ((sideJoueur == sideInvalid) || (sideIA == sideInvalid))
      {
         
         // Création d'une boite d'alerte pour le choix de la couleur
         NSAlert *alertChoixCouleur = [[NSAlert alloc] init];
         [alertChoixCouleur addButtonWithTitle:@"Les Blancs"];
         [alertChoixCouleur addButtonWithTitle:@"Les Noirs"];
         [alertChoixCouleur setMessageText:@"Choix de la couleur pour le Joueur"];
         [alertChoixCouleur setInformativeText:@"Avec quelle couleur souhaitez-vous affronter l'IA ?"];
         [alertChoixCouleur setAlertStyle:NSAlertStyleInformational];
         
         // Récupération du choix fait par le joueur et détermination de sideJoueur
         NSModalResponse boutonChoisi = [alertChoixCouleur runModal];
         if (boutonChoisi == NSAlertFirstButtonReturn) {
            sideJoueur = sideWhite;}
         else {
            sideJoueur = sideBlack;}
         
         /*  NB : La boite d'alerte est modale et interdit donc la poursuite du programme
          avant d'avoir choisi la couleur que l'on souhaite jouer dans cette partie.
          Lorsque la boite d'alerte se ferme et perd le focus de premier plan,
          la fenêtre de l'échiquier ne le récupère pas systématiquement et dans la
          négative il faut penser à aller chercher l'application qui tourne
          souvent dans l'arrière plan de X-Code lui-même                              */
         
         // sideIA prend la couleur laissée par le JOUEUR
         sideIA = (sideJoueur == sideWhite) ? sideBlack : sideWhite;
         
         NSLog(@"\nLe JOUEUR a les %@, l'IA les %@", (sideJoueur == sideWhite)? @"Blancs" : @"Noirs",
               (sideIA == sideWhite)? @"Blancs" : @"Noirs");
      }
      else{
         NSLog(@"\nLe JOUEUR a les %@, l'IA les %@", (sideJoueur == sideWhite)? @"Blancs" : @"Noirs",
               (sideIA == sideWhite)? @"Blancs" : @"Noirs");
      }
   } // Fin de DefCouleurJoueur

   

   // **************************************************************************************************
   // MCN
   // Méthode d'instance, appelée en fin d'initialisation du plateau quand l'IA a les blancs
   // LE TOUT PREMIER COUP DE LA PARTIE REVIENT À L'IA QUAND ELLE A LES BLANCS
   -(void)PremCoupAIBlancs
   {
      /* self fait référence à l'objet ChessBoard qui appelle la méthode PremCoupAIBlancs
      calcul du meilleur 1er coup IA  */
      Move* firstAImove = [maMinimax BestMoveForSide:sideWhite board:self];
      ChessBoard* boardAvantMove = self.copy;   // sauvegardé pour ConvertEnStringMove avant PerformMove
      
      [self PerformMove:firstAImove];           // réalisation graphique du coup

      /* Init de la liste des coups joués et traitement chaine du 1er coup, sachant qu'il ne peut y avoir
      à ce stade de la partie, de promotion de pion ou de position d'échec, d'où les paramètres fixés à @""
      Par ailleurs, inutile de gérer les infos de Roque car le premier coup ne peut consister à Roquer */
      
      NSMutableString* premMoveToStr = [MCNmoveToStr ConvertEnStringMove:firstAImove
                                                                PromPion:@""
                                                                StrEchec:@""
                                                                   Board:boardAvantMove];
      /* Edition  de la chaine 'stringCoupsPartie'
      RAZ de principe, avant affectation de la valeur souhaitée pour la chaine... */
      stringCoupsPartie = @"";
      /* ...puis ajout du 1er coup venant d'être réalisé par l'IA jouant les Blancs */
      stringCoupsPartie =[NSString stringWithFormat:@"1.\tIA : %@", premMoveToStr];
      /* À ce stade on n'a fait que la mise à jour de la chaine de caractères,
      mais c'est AppDelegate qui s'occupe de son affichage dans le contrôle de l'IU */
      
      
      
      // Le premier coup étant achevé on inverse sideCourant
      sideCourant = sideBlack;
   } // Fin de PremCoupAIBlancs


   // ********************************************************************************************
   // MCN - Méthode d'instance
   // Gérant la promotion d'un pion parvenant sur sa dernière rangée
   -(NSString *) SelectPromoPion:(Piece*)piece auRang:(int)rang
   {
      NSString *promoDTFC = @"";
      NSString *msgTitre  = @"";
      NSString *msgInfo   = @"";
      
      // Orientation classique Blancs en bas --> Pion blanc en rang 7 ou pion noir en rang 0 = promo
      if(sideJoueur == sideWhite) {
         if (rang == 7) {  // Pion Blanc Joueur
            msgTitre = @"Pion Blanc éligible à promotion";
            msgInfo  = @"Choisissez la promotion souhaitée pour votre Pion...";
         }
         if (rang == 0) {  // Pion Noir IA
            msgTitre = @"Pion Noir éligible à promotion";
            msgInfo  = @"Il vous revient de choisir en toute bonne foi, la promotion pour le Pion de l'IA...";
         }
      }
      
      // Orientation inversée Noirs en bas --> Pion blanc en rang 0 ou pion noir en rang 7 = promo
      if(sideJoueur == sideBlack) {
         if (rang == 7) {  // Pion Noir Joueur
            msgTitre = @"Pion Noir éligible à promotion";
            msgInfo  = @"Choisissez la promotion souhaitée pour votre Pion...";
         }
         if (rang == 0) {  // Pion Blanc IA
            msgTitre = @"Pion Blanc éligible à promotion";
            msgInfo  = @"Il vous revient de choisir en toute bonne foi, la promotion pour le Pion de l'IA...";
         }
      }
      
      NSAlert *promoPion = [[NSAlert alloc] init];
      [promoPion addButtonWithTitle:@"Dame"];
      [promoPion addButtonWithTitle:@"Tour"];
      [promoPion addButtonWithTitle:@"Fou"];
      [promoPion addButtonWithTitle:@"Cavalier"];
      [promoPion setMessageText:msgTitre];
      [promoPion setInformativeText:msgInfo];
      [promoPion setAlertStyle:NSAlertStyleInformational];
      
      /* Récupération du choix fait par le joueur
      Noter l'astuce utilisée pour disposer d'un véritable quadruple choix -sachant que NSAlert ne sait pas
      lire un retour au-delà du 'ThirdButton'- en utilisant un pseudo choix par défaut...  */
      NSModalResponse boutonChoisi = [promoPion runModal];
       switch (boutonChoisi) {
          case NSAlertFirstButtonReturn : piece.type = Dame;  promoDTFC=@"D";   break;
          case NSAlertSecondButtonReturn: piece.type = Tour;  promoDTFC=@"T";   break;
          case NSAlertThirdButtonReturn : piece.type = Fou;   promoDTFC=@"F";   break;
          default                       : piece.type = Cava;  promoDTFC=@"C";   break;
      } 
      
      return promoDTFC;
   } // Fin de Méthode SelectPromoPion


   // **************************************************************************************************
   // MCN - Méthode d'instance permettant de déterminer la chaine décrivant les possibilités de Roque
   -(void) CalculerStrRoque {
      
      /* La situation du Roque est dépendante de 6 pièces : les 2 rois et les 4 tours...
      Il est donc nécessaire de vérifier que ces pièces sont présentes sur leur position d'origine
      et qu'elles n'ont pas bougé entretemps
      On passe par une String provisoire   */
      
      /* Si, dans la partie, strRoque est déjà positionnée sur '-' c'est que plus aucun roque n'est autorisé
      Pas la peine alors de rééxécuter la méthode à chaque move...   */
      if (!([monMCNControleur.maChessView->liveBoard->strRoque isEqual:@"-"])) {
         
         NSString *strProvRoque = @"";
         
         if (sideJoueur == sideWhite) {
            if (([self piece_colX:4 rangY:0].numMoves == 0) && ([self piece_colX:7 rangY:0].numMoves == 0) &&
                ([self piece_colX:4 rangY:0].type == Roi)   && ([self piece_colX:7 rangY:0].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"K"];
            
            if (([self piece_colX:4 rangY:0].numMoves == 0) && ([self piece_colX:0 rangY:0].numMoves == 0) &&
                ([self piece_colX:4 rangY:0].type == Roi)   && ([self piece_colX:0 rangY:0].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"Q"];
            
            if (([self piece_colX:4 rangY:7].numMoves == 0) && ([self piece_colX:7 rangY:7].numMoves == 0) &&
                ([self piece_colX:4 rangY:7].type == Roi)   && ([self piece_colX:7 rangY:7].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"k"];
            
            if (([self piece_colX:4 rangY:7].numMoves == 0) && ([self piece_colX:0 rangY:7].numMoves == 0) &&
                ([self piece_colX:4 rangY:7].type == Roi)   && ([self piece_colX:0 rangY:7].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"q"];
            
            if ([strProvRoque isEqual:@""]) strProvRoque = [strProvRoque stringByAppendingString:@"-"];
         }
         else if (sideJoueur == sideBlack) {
            if (([self piece_colX:3 rangY:7].numMoves == 0) && ([self piece_colX:0 rangY:7].numMoves == 0) &&
                ([self piece_colX:3 rangY:7].type == Roi) && ([self piece_colX:0 rangY:7].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"K"];
            
            if (([self piece_colX:3 rangY:7].numMoves == 0) && ([self piece_colX:7 rangY:7].numMoves == 0) &&
                ([self piece_colX:3 rangY:7].type == Roi) && ([self piece_colX:7 rangY:7].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"Q"];
            
            if (([self piece_colX:3 rangY:0].numMoves == 0) && ([self piece_colX:0 rangY:0].numMoves == 0) &&
                ([self piece_colX:3 rangY:0].type == Roi) && ([self piece_colX:0 rangY:0].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"k"];
            
            if (([self piece_colX:3 rangY:0].numMoves == 0) && ([self piece_colX:7 rangY:0].numMoves == 0) &&
                ([self piece_colX:3 rangY:0].type == Roi) && ([self piece_colX:7 rangY:0].type == Tour))
               strProvRoque = [strProvRoque stringByAppendingString:@"q"];
            
            if ([strProvRoque isEqual:@""]) strProvRoque = [strProvRoque stringByAppendingString:@"-"];
         }
         
         // Affectation de la valeur trouvée à la variable d'instance ad-hoc
         monMCNControleur.maChessView->liveBoard->strRoque = strProvRoque;
      }
   }

   
   // **************************************************************************************************
   // MCN - Méthode d'instance permettant de déterminer la cible d'une prise en passant potentielle.
   // NB : La cible e.p. à laquelle il est fait référence, notamment dans un code FEN, correspond de fait
   // à la case traversée par le pion pris avançant de 2 cases, case qui sera occupée par le pion prenant
   // C'est donc cette case traversée qui est indiquée comme cible, qu'un pion adverse soit suffisamment
   // avancé pour exécuter la prise en passant ou pas...
   -(void) DeterminerCibleEP:(Move *)move {
      
      NSString *cibleEP;
      if (sideJoueur == sideWhite) {
         if (([self pieceAtPos:move.dest].type == Pion) && abs(move.start.y - move.dest.y) == 2) {
            switch (move.start.x) {
               case 0 : cibleEP=[NSString stringWithFormat:@"a%d", (move.start.y + move.dest.y)/2+1] ; break;
               case 1 : cibleEP=[NSString stringWithFormat:@"b%d", (move.start.y + move.dest.y)/2+1] ; break;
               case 2 : cibleEP=[NSString stringWithFormat:@"c%d", (move.start.y + move.dest.y)/2+1] ; break;
               case 3 : cibleEP=[NSString stringWithFormat:@"d%d", (move.start.y + move.dest.y)/2+1] ; break;
               case 4 : cibleEP=[NSString stringWithFormat:@"e%d", (move.start.y + move.dest.y)/2+1] ; break;
               case 5 : cibleEP=[NSString stringWithFormat:@"f%d", (move.start.y + move.dest.y)/2+1] ; break;
               case 6 : cibleEP=[NSString stringWithFormat:@"g%d", (move.start.y + move.dest.y)/2+1] ; break;
               case 7 : cibleEP=[NSString stringWithFormat:@"h%d", (move.start.y + move.dest.y)/2+1] ; break;
               default           :break;
            }
         }
         else cibleEP = @"-";
      }
      else if (sideJoueur == sideBlack) {
         if (([self pieceAtPos:move.dest].type == Pion) && abs(move.start.y - move.dest.y) == 2) {
            switch (move.start.x) {
               case 0 : cibleEP=[NSString stringWithFormat:@"h%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               case 1 : cibleEP=[NSString stringWithFormat:@"g%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               case 2 : cibleEP=[NSString stringWithFormat:@"f%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               case 3 : cibleEP=[NSString stringWithFormat:@"e%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               case 4 : cibleEP=[NSString stringWithFormat:@"d%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               case 5 : cibleEP=[NSString stringWithFormat:@"c%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               case 6 : cibleEP=[NSString stringWithFormat:@"b%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               case 7 : cibleEP=[NSString stringWithFormat:@"a%d", (7-(move.start.y + move.dest.y)/2+1)] ; break;
               default           :break;
            }
         }
         else cibleEP = @"-";
      }
      monMCNControleur.maChessView->liveBoard->strCibleEP = cibleEP;
      
   } // Fin de Méthode DeterminerCibleEP


   // **************************************************************************************************
   // MCN - Méthode d'instance permettant de compatiliser les demi-coups entre prise et/ou mvt de pion
   -(void) CompterDemiCoups:(Move *)move {
      
   if (([self pieceAtPos:move.dest].type != Invalide) || ([self pieceAtPos:move.start].type == Pion))
         monMCNControleur.maChessView->liveBoard->nbDemis = 0;
   else  monMCNControleur.maChessView->liveBoard->nbDemis ++;
      
   } // Fin de Méthode CompterDemiCoups

   
   // **************************************************************************************************
   -(void) ProposerNulle50Coups {

   // Boite de dialogne 1
   NSAlert *nulle50Coups = [[NSAlert alloc] init];
   [nulle50Coups setMessageText:@"Partie potentiellement nulle"];
   [nulle50Coups setInformativeText:
   @"L'absence de prise de pièce ou de mouvement de pion depuis 50 coups suggère la nullité de la partie !"];
   [nulle50Coups addButtonWithTitle:@"Demander la nullité et Quitter"];
   [nulle50Coups addButtonWithTitle:@"Ignorer la règle et Poursuivre"];
   // Récupération du choix fait par le joueur
   NSModalResponse boutonChoisi = [nulle50Coups runModal];
   switch (boutonChoisi) {
      case NSAlertFirstButtonReturn :
         stringCoupsPartie = [stringCoupsPartie stringByAppendingString:@"\n\t1/2-1/2"];
         [monMCNControleur MaJtxtCoups];
         [self AlertePartieNulle];
         stopMatOuPat = YES;
         break;
         
      case NSAlertSecondButtonReturn:
         self->nbDemis=0;
         monMCNControleur.lbl50Coups.cell.stringValue = [NSString stringWithFormat:@"50 demis : %d", self->nbDemis];
         break;
      }
   } // Fin de Méthode 'NotifieNulle50Coups'

   
   // **************************************************************************************************
   // MCN - Alerte partie Nulle
   // Boite d'alerte dans sa forme la plus simple, pouvant potentiellement servir de boite info de base
   -(void) AlertePartieNulle {
      NSAlert *partieNulle = [[NSAlert alloc] init];
      [partieNulle setMessageText:@"Partie déclarée Nulle"];
      [partieNulle setInformativeText:@"Requête d'annulation prise en compte"];
      [partieNulle addButtonWithTitle:@"OK"];
      [partieNulle setAlertStyle:NSAlertStyleInformational];
      [partieNulle runModal];
   }


   // **************************************************************************************************
   // Méthode d'instance 'makeMove' permettant de réaliser un move de test
   -(MoveState)makeMove:(Move *)m
   {
      MoveState state;
      
      // Sauvegarde état global
      state.lastMove   = self.lastMove;
      state.strRoque   = self->strRoque;
      state.strCibleEP = self->strCibleEP;
      state.nbDemis    = self->nbDemis;
      state.nbEntiers  = self->nbEntiers;

      int sx = m.start.x;
      int sy = m.start.y;
      int dx = m.dest.x;
      int dy = m.dest.y;

      Piece *moving = pieceCase[sx][sy];
      Piece *captured = pieceCase[dx][dy];

      state.capturedPiece = captured;
      state.wasPromotion = NO;

      pieceCase[dx][dy] = moving;
      pieceCase[sx][sy] = nil;

      if (moving.type == Pion &&
         ((moving.side == sideWhite && dy == 7) ||
          (moving.side == sideBlack && dy == 0))) {

         state.wasPromotion = YES;
         state.oldType = moving.type;
         moving.type = Dame;
      }
      
      self.lastMove = m;

      return state;
   }


   // **************************************************************************************************
   // Méthode d'instance 'unmakeMove' permettant d'annuler un move de test et de rétablir le board
   // initial en restaurant les positions et indicateurs d'avant move
   -(void)unmakeMove:(Move *)m state:(MoveState)state
   {
      int sx = m.start.x;
      int sy = m.start.y;
      int dx = m.dest.x;
      int dy = m.dest.y;

      Piece *moving = pieceCase[dx][dy];

      if (state.wasPromotion) {
         moving.type = state.oldType;
      }

      pieceCase[sx][sy] = moving;
      pieceCase[dx][dy] = state.capturedPiece;
      
      // Restauration état global
      self.lastMove    = state.lastMove;
      self->strRoque   = state.strRoque;
      self->strCibleEP = state.strCibleEP;
      self->nbDemis    = state.nbDemis;
      self->nbEntiers  = state.nbEntiers;
      
   }


@end
