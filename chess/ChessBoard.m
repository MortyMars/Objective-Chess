// ChessBoard.m
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026

// CLASSE DE DÉFINITION DE L'ÉCHIQUIER EN TERMES DE DONNÉES (couleur, nature, position des pièces...)
// par opposition à la classe ChessView qui traite la représentation graphique du 'board'

#import "ChessBoard.h"
#import "ChessBoard+MakeMoves.h"
#import "ChessConfig.h"
#import "Zobrist.h"

#import <stdint.h>
#import <stdlib.h>


BOOL kVerboseMoveDebug = YES; // déclaré dans Util.h


@implementation ChessBoard

   @synthesize lastMove; // Ajout MCN pour accéder à lastMove hors de sa classe, dans RuleBook

   // ==================================================================================================
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
         
         // 🔴 Init pour Zobrist et état du jeu
         sideToMove = sideWhite;      // Les Blancs commencent toujours
         castlingRights = 0b1111;     // KQkq
         enPassantFile = -1;          // Pas d'EP en début de partie
         zobristKey = 0;              // Sera recalculé après SetupPieces
         
      }
      return self;
   }


   // ==================================================================================================
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
      
      // Ajouts pour séparation UI / moteur
      sideJoueur = sideWhite;
      sideIA     = sideBlack;
      monConnecteur.maChessView.uiFlipped  = NO;
      
      // RAZ indicateurs
      nbDemis   = 0;
      nbEntiers = 1;
      lastMove  = nil;
      
      // Réinitialisation de la liste des coups
      stringCoupsPartie = @"";
      numCoup = 2; // N° des coups joués, initialisé à 2 car le n°1 est intégré au 1er coup
      [monConnecteur MaJtxtCoups];
      
      // Définition Couleurs Joueur et IA et MàJ repères de cases
      sideJoueur = sideWhite;    sideIA = sideBlack;
      [monConnecteur MajReperesCases];
      
      // Les pièces sont créées sur le board, les BLANCS en BAS
      [self SetupPieces];
      NSLog(@"a1 = %@", pieceCase[0][0]);
      NSLog(@"h8 = %@", pieceCase[7][7]);
      
      /* Initialisation de la clé Zobrist -----------------------------------*/
      self->zobristKey = 0;
      
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Piece *p = self->pieceCase[x][y];
            if (p) {
               int sq = y * 8 + x;
               self->zobristKey ^= zobristPiece[p.side][p.type][sq];
            }
         }
      }
      
      self->zobristKey ^= zobristCastle[self->castlingRights];
      
      if (self->enPassantFile != -1)
         self->zobristKey ^= zobristEnPassant[self->enPassantFile];
      
      if (self->sideToMove == sideBlack)
         self->zobristKey ^= zobristSide;
      /* Fin d'initialisation de la clé Zobrist -----------------------------*/
      
      
      
      // Chargement du board dans la vue active et rafraichissement
      monConnecteur.maChessView->liveBoard = self;
      monConnecteur.maChessView.needsDisplay = YES;
      
      //MàJ des menus
      monConnecteur.menuPoursuivre.title = @"Poursuivre avec les Noirs";
      monConnecteur.menuPoursuivre.enabled = YES;
      
      // Déclarer la partie lancée (pour bouton de l'interface)
      partieLancee = YES;
      
      // DEBUG *********** Test d'involution ************ DEBUG
      engineIsBusy = YES;
      TestInvolution();
      engineIsBusy = NO;
      
      
   }


   // ==================================================================================================
   // MCN - Méthode d'instance lançant une nouvelle partie, le JOUEUR choisissant LES NOIRS
   - (IBAction)NewPartieJoueurNoirs:(id)sender {
      
      // Effacement d'un éventuel précédent board déjà construit
      for (int x=0; x < 8; x ++) {
         self->pieceCase[x][0] = nil;   // effacement rangée 0
         self->pieceCase[x][1] = nil;   // ...
         self->pieceCase[x][2] = nil;
         self->pieceCase[x][3] = nil;
         self->pieceCase[x][4] = nil;
         self->pieceCase[x][5] = nil;
         self->pieceCase[x][6] = nil;
         self->pieceCase[x][7] = nil;
      }
      
      // Ajouts pour séparation UI / moteur
      sideJoueur = sideBlack;
      sideIA     = sideWhite;
      monConnecteur.maChessView.uiFlipped  = YES;
      
      
      // RAZ indicateurs
      nbDemis   = 0;
      nbEntiers = 1;
      lastMove  = nil;
      
      // Réinitialisation de la liste des coups
      stringCoupsPartie = @"";
      numCoup = 2; // N° des coups joués, initialisé à 2 car le n°1 est intégré au 1er coup
      [monConnecteur MaJtxtCoups];
      
      // Définition Couleurs Joueur et IA et MàJ repères de cases
      sideJoueur = sideBlack;    sideIA = sideWhite;
      [monConnecteur MajReperesCases];
      
      // Les pièces sont créées sur le board, les NOIRS en BAS
      [self SetupPieces];
      NSLog(@"a1 = %@", pieceCase[0][0]);
      NSLog(@"h8 = %@", pieceCase[7][7]);
      
      // 🔴 DEBUG : vérifier l'état AVANT initialisation Zobrist
      #ifdef DEBUG_ZOBRIST
      NSLog(@"🔵 AVANT init Zobrist:");
      NSLog(@"   self = %p", self);
      NSLog(@"   sideToMove = %d", self->sideToMove);
      NSLog(@"   castlingRights = %d", self->castlingRights);
      NSLog(@"   enPassantFile = %d", self->enPassantFile);
      NSLog(@"   zobristKey = %llx", self->zobristKey);
      #endif
      
      /* Initialisation de la clé Zobrist -----------------------------------*/
      self->zobristKey = 0;
      
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Piece *p = self->pieceCase[x][y];
            if (p) {
               int sq = y * 8 + x;
               self->zobristKey ^= zobristPiece[p.side][p.type][sq];
            }
         }
      }
      
      self->zobristKey ^= zobristCastle[self->castlingRights];
      
      if (self->enPassantFile != -1)
         self->zobristKey ^= zobristEnPassant[self->enPassantFile];
      
      if (self->sideToMove == sideBlack)
         self->zobristKey ^= zobristSide;
      
      #ifdef DEBUG_ZOBRIST
         NSLog(@"🔵 APRÈS init Zobrist:");
         NSLog(@"   zobristKey = %llx", self->zobristKey);
         uint64_t recalc = recomputeZobrist(self);
         NSLog(@"   recalculé  = %llx", recalc);
         if (self->zobristKey != recalc) {
             NSLog(@"❌ INIT ZOBRIST A ÉCHOUÉ !");
         }
      #endif
      /* Fin d'initialisation de la clé Zobrist -----------------------------*/
      
      // Chargement du board dans la vue active et rafraichissement
      monConnecteur.maChessView->liveBoard = self;
      monConnecteur.maChessView.needsDisplay = YES;
      
      // 🔴 APRÈS INIT ZOBRIST, FORCER L'IA À JOUER LE PREMIER COUP !
      [self PremCoupAIBlancs];
      
      // Affichage du 1er coup de l'IA qui joue les BLANCS
      [monConnecteur InitialiseTxtCoups:stringCoupsPartie];
      
      //MàJ des menus
      monConnecteur.menuPoursuivre.title = @"Poursuivre avec les Blancs";
      monConnecteur.menuPoursuivre.enabled = YES;
      
      // Déclarer la partie lancée (pour bouton de l'interface)
      partieLancee = YES;
      
   }


   // ==================================================================================================
   // MCN IBAction vers Méthode inversant l'échiquier
   - (IBAction)RetournerBoard:(id)sender {
      
      // Recopie des pièces du boardA vers le boardB
      ChessBoard *boardA = monConnecteur.maChessView->liveBoard;
      ChessBoard *boardB = [[ChessBoard alloc]init];
      for (int x=0; x<8; x++) {
         for (int y=0; y<8; y++){
            if (boardA->pieceCase[x][y])
               
               boardB->pieceCase[7-x][7-y] =
               [[Piece alloc] initWithType:boardA->pieceCase[x][y].type                                                                          side:boardA->pieceCase[x][y].side];
         }
      }
      
      // Récupération des variables d'instance du board d'origine
      boardB->strRoque   = boardA->strRoque;
      boardB->strCibleEP = @"-";             // car de toutes façons RAZ ou MàJ par prochain coup
      boardB->nbDemis    = boardA->nbDemis;
      boardB->nbEntiers  = boardA->nbEntiers;
      
      // Focus sur le nouveau board
      monConnecteur.maChessView->liveBoard = boardB;
      monConnecteur.maChessView.needsDisplay = YES;
      
      // Recalage de la partie
      if (sideJoueur == sideWhite) {
         sideJoueur = sideBlack;
         sideIA = sideWhite;
         [monConnecteur.maChessView MakeIAMoveForSide:sideWhite Board:boardB];
         sideCourant = sideBlack;
      }
      else if (sideJoueur == sideBlack) {
         sideJoueur = sideWhite;
         sideIA = sideBlack;
         [monConnecteur.maChessView MakeIAMoveForSide:sideBlack Board:boardB];
         sideCourant = sideWhite;
      }
      
      // MàJ repérage des cases et de la 'status bar'
      [monConnecteur MajReperesCases];
      monConnecteur.lblRoque.cell.stringValue   = [NSString stringWithFormat:@"Roque : %@",      boardB->strRoque];
      monConnecteur.lblCibleEP.cell.stringValue = [NSString stringWithFormat:@"Cible e.p. : %@", boardB->strCibleEP];
      monConnecteur.lbl50Coups.cell.stringValue = [NSString stringWithFormat:@"50 demis : %d",   boardB->nbDemis];
      monConnecteur.lblNumCoup.cell.stringValue = [NSString stringWithFormat:@"Coup n° : %d",    boardB->nbEntiers];
      
      // MàJ menus
      if([monConnecteur.menuPoursuivre.title isEqual:@"Poursuivre avec les Blancs"])
         monConnecteur.menuPoursuivre.title = @"Poursuivre avec les Noirs";
      else      monConnecteur.menuPoursuivre.title = @"Poursuivre avec les Blancs";
      //boardA = nil;
      
   } // Fin de Méthode 'RetournerBoard'


   // ==================================================================================================
   // INITIALISATION DES PIECES SUR L'ECHIQUIER (AFFECTATION DE LEUR POSITION EN DEBUT DE PARTIE)
   // Cette METHODE est appelée dans ChessView.m
   -(void)SetupPieces
   {
      /* On est dans le périmètre moteur, les coordonnées x et y doivent
      respecter le caractère canonique du repère (0, x, y) de référence.
      Dans ce contexte, les Blancs -vus du moteur- sont en bas, TOUJOURS */
      pieceCase[0][0] = [[Piece alloc] initWithType:Tour side:sideWhite];
      pieceCase[1][0] = [[Piece alloc] initWithType:Cava side:sideWhite];
      pieceCase[2][0] = [[Piece alloc] initWithType:Fou  side:sideWhite];
      pieceCase[3][0] = [[Piece alloc] initWithType:Dame side:sideWhite];
      pieceCase[4][0] = [[Piece alloc] initWithType:Roi  side:sideWhite];
      pieceCase[5][0] = [[Piece alloc] initWithType:Fou  side:sideWhite];
      pieceCase[6][0] = [[Piece alloc] initWithType:Cava side:sideWhite];
      pieceCase[7][0] = [[Piece alloc] initWithType:Tour side:sideWhite];
      
      for (int x = 0; x < 8; x++) {
         pieceCase[x][1] = [[Piece alloc] initWithType:Pion side:sideWhite];
         pieceCase[x][6] = [[Piece alloc] initWithType:Pion side:sideBlack];
         pieceCase[x][7] = [[Piece alloc] initWithType:pieceCase[x][0].type side:sideBlack];
      }
   }


   // ==================================================================================================
   // Méthode d'instance - Jouant le role d'accesseur à pieceCase
   // Retourne la pièce positionnée en (x,y)
   -(Piece *)piece_colX:(int)x rangY:(int)y
   {
      if (x < 0 || y < 0 || x > 7 || y > 7) return nil;
      return pieceCase[x][y];
   }


   // ==================================================================================================
   // Méthode d'instance
   // retourne la pièce positionnée en 'pos'
   -(Piece *)pieceAtPos:(Pos *)pos
   {
       if (!pos) return nil;

       // garde ultra-importante
       if (![pos isKindOfClass:[Pos class]]) return nil;

       int x = pos.x, y = pos.y;
       if (x < 0 || y < 0 || x > 7 || y > 7) return nil;

       return pieceCase[x][y];
   }


   // ==================================================================================================
   // Méthode d'instance
   -(void)PerformMove:(Move *)move
   {
      /* DÉPLACEMENT DE PIÈCES DANS LE CAS GÉNÉRAL
       NB: 'MovePieceDeStart' déplace la pièce sur le nouvel emplacement et la supprime de l'ancien */
      //Piece *piece = [self MovePieceDeStart:move.start ADest:move.dest];
      [self MovePieceDeStart:move.start ADest:move.dest];
      
      // === GESTION DU ROQUE (nouveau moteur) ===============================
      if (move.isCastling) {
         
         int y = move.dest.y;          // rangée du Roi
         int rookStartX, rookDestX;
         
         // Petit roque : Roi se déplace vers la droite (e → g)
         if (move.dest.x > move.start.x) {
            rookStartX = 7;   // tour h
            rookDestX  = 5;   // tour → f
         }
         // Grand roque : Roi se déplace vers la gauche (e → c)
         else {
            rookStartX = 0;   // tour a
            rookDestX  = 3;   // tour → d
         }
         
         [self MovePieceDeStart:[Pos posWithX:rookStartX y:y]
                          ADest:[Pos posWithX:rookDestX  y:y]];
      }
      
      // Sauvegarde du move comme étant le dernier du board
      self.lastMove = move;
      
   }


   // ==================================================================================================
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


   // ==================================================================================================
   // Méthode exigée par le Protocol NSCopying dont hérite la classe ChessBoard
   // Elle n'est pas directement appelée, mais est utilisée dès qu'on envoie un message copy sur un objet
   // ChessBoard
   -(id)copyWithZone:(NSZone *)zone
   {
       ChessBoard *newBoard = [[ChessBoard alloc] init];
       
       // Copie des pièces
       for (int x = 0; x < 8; x++) {
           for (int y = 0; y < 8; y++) {
               if (pieceCase[x][y]) {
                   newBoard->pieceCase[x][y] = pieceCase[x][y].copy;
               } else {
                   newBoard->pieceCase[x][y] = nil;
               }
           }
       }
       
       // 🔴 CRITIQUE : Copier TOUS les états !
       newBoard->sideToMove = self->sideToMove;
       newBoard->castlingRights = self->castlingRights;
       newBoard->enPassantFile = self->enPassantFile;
       newBoard->zobristKey = self->zobristKey;  // ← ESSENTIEL !
       
       // Copier aussi les autres variables d'instance
       newBoard->strRoque = self->strRoque;
       newBoard->strCibleEP = self->strCibleEP;
       newBoard->nbDemis = self->nbDemis;
       newBoard->nbEntiers = self->nbEntiers;
       
       newBoard.lastMove = self.lastMove ? self.lastMove.copy : nil;
       
       return newBoard;
   }

   // ==================================================================================================
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


   // ==================================================================================================
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
         
         /* NB : La boite d'alerte est modale et interdit donc la poursuite du programme
          avant d'avoir choisi la couleur que l'on souhaite jouer dans cette partie.
          Lorsque la boite d'alerte se ferme et perd le focus de premier plan,
          la fenêtre de l'échiquier ne le récupère pas systématiquement et dans la
          négative il faut penser à aller chercher l'application qui tourne
          souvent dans l'arrière plan de X-Code lui-même                               */
         
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



   // ==================================================================================================
   // Méthode d'instance, appelée en fin d'initialisation du plateau quand l'IA a les blancs
   // LE TOUT PREMIER COUP DE LA PARTIE REVIENT À L'IA QUAND ELLE A LES BLANCS
   -(void)PremCoupAIBlancs
   {
      /* self fait référence à l'objet ChessBoard qui appelle la méthode PremCoupAIBlancs
       calcul du meilleur 1er coup IA  */
      Move* firstAImove = [maMinimax BestMoveForSide:sideWhite Board:self];
      ChessBoard* boardAvantMove = self.copy;   // sauvegardé pour ConvertEnStringMove avant PerformMove
      
      MoveState st = [self makeMove:firstAImove];           // réalisation graphique du coup
      
      /* Init de la liste des coups joués et traitement chaine du 1er coup, sachant qu'il ne peut y avoir
       à ce stade de la partie, de promotion de pion ou de position d'échec, d'où les paramètres fixés à @""
       Par ailleurs, inutile de gérer les infos de Roque car le premier coup ne peut consister à Roquer */
      
      NSMutableString* premMoveToStr = [MoveToStr ConvertEnStringMove:firstAImove
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


   // ============================================================================================
   // Méthode d'instance gérant le choix de promotion du joueur
   -(PieceType)SelectPromoPionForSide:(Side)side
   {
       NSString *msgTitre = (side == sideWhite)
           ? @"Pion Blanc éligible à promotion"
           : @"Pion Noir éligible à promotion";
       
       NSString *msgInfo = @"Choisissez la promotion souhaitée pour votre Pion...";
       
       NSAlert *promoPion = [[NSAlert alloc] init];
       [promoPion addButtonWithTitle:@"Dame"];
       [promoPion addButtonWithTitle:@"Tour"];
       [promoPion addButtonWithTitle:@"Fou"];
       [promoPion addButtonWithTitle:@"Cavalier"];
       [promoPion setMessageText:msgTitre];
       [promoPion setInformativeText:msgInfo];
       [promoPion setAlertStyle:NSAlertStyleInformational];
       
       NSModalResponse boutonChoisi = [promoPion runModal];
       
       switch (boutonChoisi) {
           case NSAlertFirstButtonReturn:  return Dame;
           case NSAlertSecondButtonReturn: return Tour;
           case NSAlertThirdButtonReturn:  return Fou;
           default:                        return Cava;
       }
   }


   // ==================================================================================================
   // Méthode permettant de déterminer la chaine décrivant les possibilités de Roque
   -(void) CalculerStrRoque {
      
      /* La situation du Roque est dépendante de 6 pièces : les 2 rois et les 4 tours...
      Il est donc nécessaire de vérifier que ces pièces sont présentes sur leur position d'origine
      et qu'elles n'ont pas bougé entretemps
      On passe par une String provisoire   */
      
      /* Si, dans la partie, strRoque est déjà positionnée sur '-' c'est que plus aucun roque n'est autorisé
      Pas la peine alors de rééxécuter la méthode à chaque move...   */
      if (!([monConnecteur.maChessView->liveBoard->strRoque isEqual:@"-"])) {
         
         NSString *strProvRoque = @"";
         
         //if (sideJoueur == sideWhite) {
         //if (!monConnecteur.maChessView.uiFlipped) {
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
         //}
         //else if (sideJoueur == sideBlack) {
         /*else {
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
         } */
         
         // Affectation de la valeur trouvée à la variable d'instance ad-hoc
         monConnecteur.maChessView->liveBoard->strRoque = strProvRoque;
      }
   }


   // ==================================================================================================
   // Méthode permettant de déterminer la cible d'une prise en passant potentielle.
   // NB : La cible e.p. à laquelle il est fait référence, notamment dans un code FEN, correspond de fait
   // à la case traversée par le pion pris avançant de 2 cases, case qui sera occupée par le pion prenant.
   // C'est donc cette case traversée qui est indiquée comme cible, qu'un pion adverse soit suffisamment
   // avancé pour exécuter la prise en passant ou pas.
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
               default : break;
            }
         }
         else cibleEP = @"-";
      }
      monConnecteur.maChessView->liveBoard->strCibleEP = cibleEP;
      
   } // !DeterminerCibleEP


   // ==================================================================================================
   // Méthode d'instance permettant de compatiliser les demi-coups entre prise et/ou mvt de pion
   -(void) CompterDemiCoups:(Move *)move {
      
      if (([self pieceAtPos:move.dest].type != Invalide) || ([self pieceAtPos:move.start].type == Pion))
         monConnecteur.maChessView->liveBoard->nbDemis = 0;
      else  monConnecteur.maChessView->liveBoard->nbDemis ++;
      
   } // !CompterDemiCoups


   // ==================================================================================================
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
            [monConnecteur MaJtxtCoups];
            [self AlertePartieNulle];
            stopMatOuPat = YES;
            break;
            
         case NSAlertSecondButtonReturn:
            self->nbDemis=0;
            monConnecteur.lbl50Coups.cell.stringValue = [NSString stringWithFormat:@"50 demis : %d", self->nbDemis];
            break;
      }
      
   } // !NotifieNulle50Coups


   // ==================================================================================================
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


   

   // ==================================================================================================
   // Nouvelle Méthode de construction d'un move complet (avec ses attributs)
   - (Move *)buildMoveFrom:(Pos *)start to:(Pos *)dest board:(ChessBoard *)board
   {
       Move *m = [[Move alloc] initWithStart:start Dest:dest];
       
       Piece *p = [board pieceAtPos:start];
       m.movingPiece = p;
       
       m.fromSquare = start.y * 8 + start.x;
       m.toSquare   = dest.y  * 8 + dest.x;
       
       // Roque
       if (p.type == Roi && abs(dest.x - start.x) == 2) {
           m.isCastling = YES;
       }
       
       // Promotion
       if (p.type == Pion && (dest.y == 0 || dest.y == 7)) {
           m.isPromotion = YES;
       }
       
       // Capture
       Piece *target = [board pieceAtPos:dest];
       if (target) {
           m.isCapture = YES;
           m.capturedPiece = target;
       }
       
       // 🔴 EN PASSANT - CORRECTION CRITIQUE !
      // C'est EP si :
      // 1. Le pion se déplace en diagonale (changement de colonne)
      // 2. La case destination est vide
      // 3. Il y a un enPassantFile défini
      if (p.type == Pion && !target) {  // Pion qui bouge sur case vide
          if (dest.x != start.x && board->enPassantFile == dest.x) {
              int expectedRank = (p.side == sideWhite) ? 5 : 2;
              if (dest.y == expectedRank) {
                  m.isEnPassant = YES;
                  // 🔴 IMPORTANT : définir aussi capturedPiece !
                  int captureY = (p.side == sideWhite) ? 4 : 3;
                  m.capturedPiece = [board pieceAtPos:[Pos posWithX:dest.x y:captureY]];
              }
          }
      }
       
       return m;
   }


   // ==================================================================================================
   // Méthode de recalcul des droits de Roque
   -(int) ComputeCastlingRights:(ChessBoard *) board {
      
      int NewCastlingRights = 15;
      Piece *rk, *rq, *k, *RK, *RQ, *K;
      
      /* Aux emplacements c-dessous ne se trouvent pas forcément les pièces attendues.
      Si c'est le cas pas de problème ; mais si ça n'est pas le cas, les pièces s'y trouvant
      auront forcément pris la place des pièces attendues et accuseront donc un nombre de moves
      différent de 0, ce que l'on regarde finalement dans les tests -------------------------*/
      rk = pieceCase[7][7];
      rq = pieceCase[0][7];
      k  = pieceCase[4][7];
      RK = pieceCase[7][0];
      RQ = pieceCase[0][0];
      K  = pieceCase[4][0];
      
      // Aucune pièce n'a bougé parmi les emplacements ciblés -> CastlingRights = "KQkq"
      if (rk.numMoves == 0 && rq.numMoves == 0 &&
          RK.numMoves == 0 && RQ.numMoves == 0 &&
          k.numMoves  == 0 && K.numMoves  == 0) {
         NewCastlingRights = 15;
         return NewCastlingRights;
      }
      
      // Bloc Roque Roi Noir
      if (rk.numMoves == 1 && k.numMoves == 0) NewCastlingRights -= 4;  // on retire 'k'
      if (rq.numMoves == 1 && k.numMoves == 0) NewCastlingRights -= 8;  // on retire 'q'
      if (k.numMoves == 1) NewCastlingRights -= 12;                     // on retire 'kq'
      
      // Bloc Roque Roi Blanc
      if (RK.numMoves == 1 && K.numMoves == 0) NewCastlingRights -= 1;  // on retire 'K'
      if (RQ.numMoves == 1 && K.numMoves == 0) NewCastlingRights -= 2;  // on retire 'Q'
      if (K.numMoves == 1) NewCastlingRights -= 3;                      // on retire 'KQ'
      
      return NewCastlingRights;
      
   }


   // Bouton "Hint" cliqué
   -(IBAction)onHintButtonClicked:(id)sender
   {
      NSString *message;
      Move *hint = nil;
      if (partieLancee) {
         // Calculer le meilleur coup pour le joueur
         hint = [maMinimax BestMoveForSide:sideJoueur Board:monConnecteur.maChessView->liveBoard];
         
         // Création du message à destination d'une zone de texte
         message = [NSString stringWithFormat:
                              @"✨ Suggestion de l'IA : %@ ✨\n"
                              @"Score : %+d centipawns\n",
                              hint,
                              hint.orderingScore  // ou le score retourné par BestMoveForSide
         ];
         
         
         
      } else {
         message = @"Merci de lancer d'abord une partie !\n"
         @"(Menu Partie -> Nouvelle Partie -> ...)";
      }
      
      // Remplissage du lbl associé
      monConnecteur.lblCoupProposed.cell.stringValue = message;
      
      // ✨ Surligner les cases
     [monConnecteur.maChessView highlightHintSquareStart:hint.start dest:hint.dest];
     
     // Optionnel : effacer après 3 secondes
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
         [monConnecteur.maChessView clearHintHighlight];
     });
      
      
      
   }




@end
