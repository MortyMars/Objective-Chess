//  ChessView.m
//  chess
//  Created by Andrew Wang on 15/07/2013
//  Copyright (c) 2013 Andrew Wang. All rights reserved
//  Updated by MCN on 2020

//  CLASSE DE DÉFINITION DE L'ÉCHIQUIER EN TERMES DE VUES (construction graphique de l'échiquier, des pièces...)
//  par opposition à la classe ChessBoard qui traite les données d'un 'board'

#import "ChessView.h"
#import "AppDelegate.h"
#import "Util.h"


BOOL engineIsBusy = NO;



@implementation ChessView


   @synthesize delegate;

   @synthesize uiFlipped;


   // ==================================================================================================
   // MÉTHODE AUTO EXÉCUTÉE À LA CREATION DE CHESSVIEW
   // Elle en initialise une instance, allouant la mémoire et initialisant des variables
   /* Pour rappel, le type 'id' représente un pointeur sur un objet générique, un type Objective-C
    représentant "tout objet". Une instance de n'importe quelle classe Objective-C peut être stockée dans
    une variable id. Un id et tout autre type de classe peuvent être assignés l'un à l'autre sans casting
    On utilise le type id quand on veut renvoyer un objet dont on ne connaît pas encore le type ou quand
    une méthode peut prendre n'importe quel type d'objet en argument. */
   -(id)initWithFrame:(NSRect)frame
   {
      self = [super initWithFrame:frame];
      if (self) {
         
         /* Corps de la méthode à compléter par notre propre code ci-dessous */
         
         // Appel de la méthode SetupPieces de la classe ChessBoard
         // Les pièces sont positionnées pour le début de partie
         liveBoard = [[ChessBoard alloc] init];
         //[board SetupPieces];
         
      }
      
      return self;
   } // Fin de méthode


   // ==================================================================================================
   // MÉTHODE DE CLASSE - DESSIN DE L'ÉCHIQUIER - APPELÉE PAR 'drawRect'
   // La Méthode est appelée automatiquement (en fait c'est 'drawRect' qui est appelée...) dès que notre
   // ChessView nécessite d'être dessinée ou mise à jour...
   -(void)drawBoard
   {
      if (engineIsBusy) return;

      
      /* 'self.bounds.size' pointe sur les dimensions de la vue ChessView contenant l'échiquier
       La vue ChessView est définie à 600x600 (cf. le fichier xib)
       Chaque case fait donc 600/8 de large et de haut, elle est donc au format 75x75 */
      float tileWidth  = self.bounds.size.width  / 8;
      float tileHeight = self.bounds.size.height / 8;
      
      CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
      
      /* CHARGEMENT DE L'IMAGE DE TOUTES LES PIÈCES - Pour que ça marche, l'image regroupant les pièces doit
       être au format de 360x120 avec une résolution de 72x72 - Chaque pièce a donc une taille de 60x60    */
      NSImage *piecesImage = [NSImage imageNamed:@"piecesMCN.png"];
      
      // Dessin de l'échiquier et des pièces par balayage des 64 cases, une à une
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            
            // Détermination des coordonnées moteur (ex et ey)
            int ex = self.uiFlipped ? 7 - x : x;
            int ey = self.uiFlipped ? 7 - y : y;

            
            // Dessin des cases de l'échiquier
            CGRect destRect = CGRectMake(x * tileWidth, y * tileHeight, tileWidth, tileHeight);
            
            if (isThereTileSelected && selTile.x == ex && selTile.y == ey) { // case de la pièce sélectionnée
               // (0.12, 0.63, 0.33, 1) = VERT opaque    (0.72, 0.12, 0.06, 1) = ROUGE opaque
               CGContextSetRGBFillColor(context, 0, 0, 1, 1);              // --> BLEU opaque
            }
            
            else if ([PosAcceptees containsObject:[Pos posWithX:ex y:ey]]) { // déplacts autorisés pour la pièce
               // (0.72, 0.12, 0.06, 1) = ROUGE opaque
               CGContextSetRGBFillColor(context, 0.12, 0.63, 0.33, 1);  // --> VERT opaque
            }
            
            else {                                                   // autres cases (cases ordinaires)
               if ((x + y) % 2 == 1) {                               // si abs+ordo n'est pas un mult. de 2
                  CGContextSetRGBFillColor(context, 1, 1, 1, 1);     // BLANC opaque
               }
               
               else {                                                // à l'inverse si c'est un multiple de 2
                  // (0, 0, 1, 1) = BLEU opaque remplacé par un gris que je trouve plus échiquéen
                  CGContextSetRGBFillColor(context, 0.5, 0.5, 0.5, 1);    // --> en GRIS opaque
               }
            }
            CGContextFillRect(context, destRect);
            
            // Dessin des pièces sur l'échiquier, tout au long de la partie
            Piece *piece = [liveBoard pieceAtPos:[Pos posWithX:ex y:ey]];
            Side side = piece.side;
            
            if (piece) {    // si une pièce (invisible à ce stade) existe sur la case active, alors on la dessine
               int index = 0;
               switch (piece.type) {
                  case Invalide:         break;
                  case Dame: index = 0;  break;   // La Dame est la pièce indexée 0 dans piecesMars.png
                  case Roi:  index = 1;  break;   // Le Roi                       1
                  case Tour: index = 2;  break;   // La Tour                      2
                  case Pion: index = 3;  break;   // Le Pion                      3
                  case Fou:  index = 4;  break;   // Le Fou                       4
                  case Cava: index = 5;  break;   // Le Cavalier                  5
                  default:                     break;
               }
               /* Le dessin de chaque pièce est un carré de 60x60 extrait de la planche piècesMCN de 360x120
                'index' sert à positionner le curseur de sélection sur l'abcisse 0, 60, 120, 180, 240 ou 300
                Si la pièce est Noire l'ordonnée = 0, sinon elle est = 60 pour atteindre les pièces blanches */
               CGRect sourceRect = CGRectMake(index * 60, (side == sideBlack) ? 0 : 60, 60, 60);
               [piecesImage drawInRect:destRect fromRect:sourceRect operation:NSCompositingOperationSourceOver fraction:1];
            }
         }
      }
   } // Fin de méthode DESSIN DE L'ECHIQUIER



   // ==================================================================================================
   // Méthode d'instance
   // LE JOUEUR JOUE, EN DESIGNANT (LA CASE DE) LA PIECE SELECTIONNEE ET LA CASE DESTINATION
   // GESTION DES CLICS DE SOURIS DESIGNANT LES CASES ORIGINE ET DESTINATION SUR L'ECHIQUIER
   // PUIS REACTION DE L'IA QUI REALISE SON COUP
   -(void)mouseDown:(NSEvent *)theEvent
   {
      // Comme vu plus haut, 'self.bounds.size' pointe sur les dimensions de la vue ChessView contenant l'échiquier
      float tileWidth  = self.bounds.size.width / 8;   // et ChessView est définie à 600x600 (cf. fichier xib)
      float tileHeight = self.bounds.size.height / 8; // Les cases font donc 600/8 de large et de haut --> 75x75
      
      /* Lorsque l'on décale ChessView dans la fenêtre de l'appli (ce qui a été le cas pour faire de la
       place pour les repères de cases qui ont été ajoutés), on décale les deux repères (O,x,y) superposés,
       de l'échiquier d'une part et du pointeur de la souris d'autre part.
       D'où la correction en ligne+5 faisant à nouveau correspondre la case cliquée avec la position curseur */
      CGPoint pos = [theEvent locationInWindow];
      int x = pos.x / tileWidth, y = pos.y / tileHeight;
      
      /* 'Pos *tilePos = [Pos posWithX:x y:y]' = Ancienne formule à modifier car, ayant décalé l'échiquier
       de 75x75, càd d'1 case complète, il faut corriger la position du curseur de -1 case en x et en y   */
      //Pos *tilePos = [Pos posWithX:x -1 y:y -1];
      
      Pos *uiPos = [Pos posWithX:x -1 y:y -1];

      // Conversion UI → moteur
      int ex = self.uiFlipped ? 7 - uiPos.x : uiPos.x;
      int ey = self.uiFlipped ? 7 - uiPos.y : uiPos.y;

      Pos *enginePos = [Pos posWithX:ex y:ey];
      
      // Initialisation de variables
      Piece *selPiece = [liveBoard pieceAtPos:enginePos]; // selPiece est la pièce sélectionnée
      
      /* Modif. MCN - sideCourant, déclaré dans Util.h, prend la valeur de la couleur de la dernière pièce
       valide sélectionnée. Si selPiece est nil, sideCourant sera sideInvalid et le move de AI sera shunté */
      
      /* SI UNE CASE (DESTINATION) N'EST PAS SÉLECTIONNÉE : C'EST LE CAS AU PREMIER CLIC
       (pour que l'expression soit Vraie il faut que le basculeur logique 'isThereTileSelected' soit Faux) */
      if (!isThereTileSelected) {
         // S'il y a une pièce sur la case où on a cliqué
         if ([liveBoard pieceAtPos:enginePos]) {
            selTile = enginePos;         // la case sélectionnée devient la case cliquée
            isThereTileSelected = YES; // le BOOL notant la sélection de case est placé sur YES pour la suite
            
            // puis on calcule les position acceptées pour la pièce à partir de son emplacement
            PosAcceptees = [RuleBook PosLegalesForPiece:selPiece atPos:enginePos inBoard:liveBoard];
         }
      } // Fin de if --> on file sur 'self.needsDisplay=YES' en ligne 258
      
      // AU CONTRAIRE, SI UNE CASE (DESTINATION) EST SÉLECTIONNÉE : C'EST LE CAS AU SECOND CLIC
      else {
         // le mouvement demandé doit figurer dans les mouvements autorisés
         if (enginePos.x != selTile.x || enginePos.y != selTile.y)
         {
            if ([PosAcceptees containsObject:enginePos]) // le test ne marche pas sur un NSMutableSet...
            {
               [self MakeJoueurMoveVersDest:enginePos];
               [maMinimax EvalBoardForSide:sideJoueur board:liveBoard];
               self.needsDisplay = YES;
               
               // TODO REVOIR
               /* [monConnecteur InverserIndicQuiJoue];     self.needsDisplay=YES; */
               
               /* ON NE CONTINUE QUE SI MAT NON DÉTECTÉ (seule façon trouvée pour stopper le déroult auto du prog) */
               if (!stopMatOuPat)
               {
                  /* NSTimer permet de programmer un appel différé (de 2/100 de seconde ici) à
                   'MakeComputerMove' tout en permettant la poursuite du programme.
                   Ainsi, la position choisie par le JOUEUR pour son coup est prise en compte et dessinée
                   tout de suite sur l'échiquier, ce qui est visuellement parlant plus acceptable que de
                   voir les coups Joueur et IA se matérialiser simultanément sur l'échiquier comme le ferait
                   un banal '[Minimax MakeComputerMove]' */
                  [NSTimer scheduledTimerWithTimeInterval:0.02         target:self
                                                 selector:@selector(MakeComputerMove)
                                                 userInfo:nil         repeats:NO];
               }
            }
         }
         
         // RAZ variables
         isThereTileSelected = NO;     // Le basculeur (BOOL) est repositionné sur NO
         PosAcceptees = nil;
         stopMatOuPat = NO;
      } // Fin de Else --> on passe ensuite, là encore, sur 'self.needsDisplay=YES'
      
      /* On force enfin le rafraichissement de l'affichage de ChessView, ce qui provoque l'apparition des
       positions acceptées (en vert) au premier clic, et le déplact graphique de la pièce lors du second */
      self.needsDisplay = YES;
   } // Fin de gestion des clics de souris



   // ==================================================================================================
   // REALISATION DU DEPLACEMENT CALCULE PAR L'AI
   // Dans la version initiale on ne pouvait jouer contre l'ordinateur qu'avec les Blancs, l'AI ne
   // réalisait donc que des mouvements pour les Noirs.
   // La présente méthode permet à l'AI de jouer les Noirs ou les Blancs
   -(void) MakeComputerMove
   {
      // AVANT TOUT MVT ON MET À JOUR L'AFFICHAGE DE L'ÉVAL POUR VALORISER LE MOVE JOUEUR QUI VIENT D'ÊTRE RÉALISÉ
      int liveEvalWhitePOV;
      NSString *liveStrEvalBoard;
      
      liveEvalWhitePOV = [maMinimax EvalBoardForSide:sideWhite board:liveBoard]; // Recalcul d'EvalBoard, base liveBoard
      liveStrEvalBoard =[ChessView VisualIndicator:liveEvalWhitePOV];
      monConnecteur.lblEvalBoard.cell.title = liveStrEvalBoard;
      NSLog(@"#### Coup Joueur => liveEvalWhitePOV = %d, Indicator = %@\n", liveEvalWhitePOV, liveStrEvalBoard);
      
      // Mise à jour de la Vue dans le thread ppal (si on n'y est pas déjà le cas) pour rendre visible la MàJ
      // de la status barre
      dispatch_async(dispatch_get_main_queue(), ^{
         self.needsDisplay = YES;
      });
      
      // Véritable début de réalisation du move AI
      Move *aiMove = [maMinimax BestMoveForSide:sideIA Board:liveBoard];   // Version MCN
      ChessBoard* savedBoard = liveBoard.copy; // Sauvegardé pour ConvertEnStringMove avant PerformMove
      
      // Réalisation du move - NOTER : c'est PerformMove qui positionne les indicateurs de roque
      [liveBoard PerformMove:aiMove];
      
      /* Sauvegarde des indicateurs de roque car RAZ plus loin par 'TestEchecFavSide' (???)
       avant de pouvoir les exploiter dans 'ConvertEnStringMove' */
      BOOL roque = petitRoque;         BOOL ROQUE = grandRoque;         BOOL ENPASS = enPassant;
      
      /* MCN - AJOUT DU COUP IA À LA LISTE DE CEUX DÉJÀ JOUÉS
       EXTRACTION ET TRANSFORMATION de la chaine contenue dans 'move' en notation plus standard
       
       Vérification s'il y a une promo de pion à réaliser
       Test à faire avant 'TestEchecFavSide' car la promo peut générer une mise en échec */
      Piece *pionPromo = [liveBoard pieceAtPos:aiMove.dest];          NSString *promPion = @"";
      if (pionPromo.type == Pion) {
         if (aiMove.dest.y == 0 || aiMove.dest.y == 7)
            promPion = [liveBoard SelectPromoPion:pionPromo auRang:aiMove.dest.y];
      }
      
      /* Récup info d'une mise en échec éventuelle et de Prise e.p. pour renseigner 'ConvertEnStringMove'
       Bizarrement 'TestEchecForSide' RAZ les indic de Roque et de Prise e.p., d'où la sauvegarde ci-avant */
      NSString * strEchec = [maMinimax TestEchecFavSide:sideCourant Board:liveBoard];
      
      // Restauration des indicateurs de roque pour utilisation dans 'ConvertEnStringMove'
      petitRoque = roque;        grandRoque = ROQUE;         enPassant = ENPASS;
      
      NSMutableString* bestMoveIA = [MoveToStr ConvertEnStringMove:aiMove  PromPion:promPion
                                                             StrEchec:strEchec   Board:savedBoard];
      
      [MoveToStr MettreEnFormeChaine:bestMoveIA Protagoniste:@"IA"];
      
      
      // MISE À JOUR 'STATUS BAR' HORS EVAL ET TRAIT
      [self MajStatusBarViaMove:aiMove PrecBoard:savedBoard StrCheck:strEchec];
      
      // ON MET FINALEMENT À JOUR L'AFFICHAGE POUR VALORISER LE MOVE IA QUI VIENT D'ÊTRE RÉALISÉ
      liveEvalWhitePOV = [maMinimax EvalBoardForSide:sideWhite board:liveBoard]; // Recalcul de EvalBoard, base liveBoard
      liveStrEvalBoard = [ChessView VisualIndicator:liveEvalWhitePOV];
      monConnecteur.lblEvalBoard.cell.title = liveStrEvalBoard;
      NSLog(@"#### Coup IA     => liveEvalWhitePOV = %d, Indicator = %@\n", liveEvalWhitePOV, liveStrEvalBoard);
      
      // L'IA ayant joué on inverse sideCourant
      sideCourant = (sideCourant == sideWhite) ? sideBlack : sideWhite;
      monConnecteur.lblTrait.cell.stringValue =
      (sideCourant == sideWhite)? @"Trait : Blancs": @"Trait : Noirs";
      
      
      // Test si le coup IA met en échec ou Pat ou Mat le Joueur et message ad-hoc
      if ([maMinimax IsKingInCheck:sideJoueur board:liveBoard]){
         // Message Echec
         [monConnecteur AlertMsgEchecSide:sideJoueur];
         NSSet *movesPossibles = [maMinimax PossibleMovesForSide:sideJoueur board:liveBoard];
         if (movesPossibles.count == 0) {
            [monConnecteur AlertMsgPatMatSide:sideJoueur onBoard:liveBoard];
         }
      }
      
      // Mise à jour de la Vue dans le thread ppal si on n'y est pas déjà le cas
      dispatch_async(dispatch_get_main_queue(), ^{
         self.needsDisplay = YES;
      });
   } // Fin de MakeComputerMove


   // ==================================================================================================
   // MCN - Méthode d'instance
   // Création d'une méthode Joueur symétrique à celle déjà existante pour réaliser le move de l'IA
   // L'idée première est d'homogénéiser la structure du code et d'en simplifier la lecture...
   -(void) MakeJoueurMoveVersDest:(Pos *) dest
   {
      /* Le paramètre attendu par la méthode est la case sélectionnée par le second clic
      Elle a été controlée comme appartenant ou non aux déplacements autorisés
      Si OK on peut alors préparer et réaliser le 'Move' Joueur */
      //Move *moveJoueur = [[Move alloc] initWithStart:selTile Dest:dest];
      Move *moveJoueur =
      [liveBoard buildMoveFrom:selTile to:dest board:liveBoard];
      
      /* Sauvegarde du board avant PerformMove, pour que ConvertEnStringMove (Modif00EnA1 en fait) puisse
       déterminer la pièce jouée et la pièce éventuellement prise */
      ChessBoard* savedBoard = liveBoard.copy;
      
      /* Réalisation du move - NOTER que PerformMove positionne les indicateurs petitRoque, grandRoque,
       et prise e.p. */
      [liveBoard PerformMove:moveJoueur];
      
      /* Sauvegarde des indicateurs de Roque et de Prise e.p., car -bizarement- [Minimax TestEchecFavSide]
       les RAZ avant d'avoir pu les exploiter dans ConvertEnStringMove */
      BOOL roque = petitRoque;          BOOL ROQUE = grandRoque;          BOOL ENPASS = enPassant;
      
      /* AJOUT DU COUP JOUEUR À LA LISTE DE CEUX DÉJÀ JOUÉS
      EXTRACTION ET TRANSFORMATION de la chaine contenue dans 'move' en notation plus standard
       
      Vérification s'il y a une promo de pion à réaliser
      Test à faire avant 'TestEchecFavSide' car la promo peut générer un échec */
      Piece *pionPromo = [liveBoard pieceAtPos:moveJoueur.dest];      NSString *promPion = @"";
      if (pionPromo.type == Pion) {
         if (moveJoueur.dest.y == 0 || moveJoueur.dest.y == 7)
            promPion = [liveBoard SelectPromoPion:pionPromo auRang:moveJoueur.dest.y];
      }
      
      // Récup de l'info sur une mise en échec éventuelle pour renseigner ensuite ConvertEnStringMove
      NSString *strEchecMat = [maMinimax TestEchecFavSide:sideCourant Board:liveBoard];
      
      /* // Mise à jour 'Status Bar'
      if ([strEchecMat isEqual:@"Echec"]) {
      if (checkCount >1) monConnecteur.lblEchec.cell.stringValue = @"Échec : ++";
      else               monConnecteur.lblEchec.cell.stringValue = @"Échec : +";
      }
      else monConnecteur.lblEchec.cell.stringValue = @"Échec :"; */
      
      // Restauration des indicateurs de Roque et de Prise e.p.
      petitRoque = roque;        grandRoque = ROQUE;        enPassant = ENPASS;
      
      // Transformation de la chaine du move
      NSMutableString* myMoveMCN = [MoveToStr ConvertEnStringMove:moveJoueur  PromPion:promPion
                                                            StrEchec:strEchecMat    Board:savedBoard];
      // Mise en forme de la chaine
      [MoveToStr MettreEnFormeChaine:myMoveMCN Protagoniste:@"J"];
      
      
      // MISE À JOUR 'STATUS BAR' HORS EVAL ET TRAIT
      [self MajStatusBarViaMove:moveJoueur PrecBoard:savedBoard StrCheck:strEchecMat];
      
      // Joueur ayant joué, on inverse sideCourant avant de sortir de la méthode et de passer la main à l'IA
      sideCourant = (sideCourant == sideWhite) ? sideBlack : sideWhite;
      monConnecteur.lblTrait.cell.stringValue = (sideCourant == sideWhite)? @"Trait : Blancs": @"Trait : Noirs";
      
      // Test si le coup IA met en échec ou Pat ou Mat le Joueur et message ad-hoc
      if ([maMinimax IsKingInCheck:sideIA board:liveBoard]){
         // Message Echec
         [monConnecteur AlertMsgEchecSide:sideIA];
         NSSet *movesPossibles = [maMinimax PossibleMovesForSide:sideIA board:liveBoard];
         if (movesPossibles.count == 0) {
            [monConnecteur AlertMsgPatMatSide:sideIA onBoard:liveBoard];
         }
      }
      
      // Mise à jour de la Vue dans le thread ppal si on n'y est pas déjà
      dispatch_async(dispatch_get_main_queue(), ^{
         self.needsDisplay = YES;
      });
      
   } // Fin de MakeJoueurMoveVersDest


   // ==================================================================================================
   // REALISATION DES DEPLACEMENTS CALCULÉS PAR L'IA  -  Méthode, directement dérivée de 'MakeComputerMove'
   // permettant à l'IA de jouer des deux côtés alternativement, et de tester le 'moteur' dans son ensemble
   -(void)MakeIAMoveForSide:(Side)side Board:(ChessBoard *)board
   {
      sideCourant = side; // affect nécessaire car MakeIAMoveFS peut être appelée à tout moment de la partie
      Move *aiMove = [maMinimax BestMoveForSide:side Board:board];
      ChessBoard* savedBoard = board.copy; // Sauvegardé pour usage dans 'ConvertEnStringMove' avt le move
      
      // Réalisation du move - NOTER : c'est 'PerformMove' qui positionne les indicateurs de roque
      [board PerformMove:aiMove];
      
      /* Sauvegarde des indicateurs de roque  et de prise e.p. car RAZ plus loin par 'TestEchecFavSide' (???)
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
      NSString *strEchec = [maMinimax TestEchecFavSide:side Board:board];
      
      /* // Mise à jour 'Status Bar'
       if ([strEchec isEqual:@"Echec"]) {
       if (checkCount >1) monConnecteur.lblEchec.cell.stringValue = @"Échec : ++";
       else               monConnecteur.lblEchec.cell.stringValue = @"Échec : +";
       }
       else monConnecteur.lblEchec.cell.stringValue = @"Échec :"; */
      
      NSLog(@"\nLe Move effectué par les %@ est : %@", (sideCourant == 2)? @"Blancs":@"Noirs ", aiMove);
      if (![strEchec isEqual:@""]) NSLog(@"\n La chaine d'échec est : '%@'", strEchec);
      
      // Restauration des indicateurs de roque pour utilisation dans 'ConvertEnStringMove'
      petitRoque = roque;           grandRoque = ROQUE;           enPassant = ENPASS;
      
      NSMutableString* bestMoveIA = [MoveToStr ConvertEnStringMove:aiMove    PromPion:promPion
                                                             StrEchec:strEchec     Board:savedBoard];
      
      [MoveToStr MettreEnFormeChaine:bestMoveIA Protagoniste:(side == sideWhite)? @"B":@"N"];
      
      
      // MISE À JOUR 'STATUS BAR' HORS EVAL ET TRAIT
      [self MajStatusBarViaMove:aiMove PrecBoard:savedBoard StrCheck:strEchec];
      
      
      // REVOIR MISE À JOUR DE L'AFFICHAGE DE L'ÉVAL
      NSLog(@"EvalWhitePOV = %d, Indicator = %@", evalWhitePOV, [ChessView VisualIndicator:evalWhitePOV]);
      monConnecteur.lblEvalBoard.cell.title = [ChessView VisualIndicator:evalWhitePOV];
      
      
      // L'IA ayant joué on inverse sideCourant
      //sideCourant = (sideIA == sideWhite) ? sideBlack : sideWhite;
      sideCourant = (sideCourant == sideWhite) ? sideBlack : sideWhite;
      monConnecteur.lblTrait.cell.stringValue = (sideCourant == sideWhite)? @"Trait : Blancs": @"Trait : Noirs";
      
      
      // Test si le coup IA met en échec ou Pat ou Mat le Joueur et message ad-hoc
      Side otherSide = (side == sideWhite)? sideBlack : sideWhite;
      if ([maMinimax IsKingInCheck:otherSide board:liveBoard]){
         // Message Echec
         [monConnecteur AlertMsgEchecSide:otherSide];
         NSSet *movesPossibles = [maMinimax PossibleMovesForSide:otherSide board:liveBoard];
         if (movesPossibles.count == 0) {
            [monConnecteur AlertMsgPatMatSide:otherSide onBoard:liveBoard];
         }
      }
      
      self.needsDisplay = YES; // MàJ affichage board
      
   } // Fin de MakeIAMoveForSide


   // ==================================================================================================
   // MCN Méthode d'instance mettant à jour la majorité des champs de la 'Barre d'état'
   // lblTrait et lblInfo font l'objet d'un traitement spécifique hors de la présent méthode
   -(void) MajStatusBarViaMove:(Move *)move PrecBoard:(ChessBoard *)precBoard StrCheck:(NSString *)strCheck {
      
      /* lblTrait */
      //monConnecteur.lblTrait.cell.stringValue = (sideCourant==sideWhite)? @"Trait : Blancs": @"Trait : Noirs";
      
      /* lblRoque : déterminé par Méthode ad-hoc */
      [liveBoard CalculerStrRoque];
      monConnecteur.lblRoque.cell.stringValue = [NSString stringWithFormat:@"Roque : %@", liveBoard->strRoque];
      
      /* lblCibleEP : déterminé par Méthode ad-hoc */
      [liveBoard DeterminerCibleEP:move];
      monConnecteur.lblCibleEP.cell.stringValue = [NSString stringWithFormat:@"Cible EP : %@", liveBoard->strCibleEP];
      
      /* lbl50Coups : déterminé par Méthode ad-hoc */
      [precBoard CompterDemiCoups:move];
      monConnecteur.lbl50Coups.cell.stringValue = [NSString stringWithFormat:@"50 demis : %d", liveBoard->nbDemis];
      if (liveBoard->nbDemis == 50) [liveBoard ProposerNulle50Coups]; //appel règle des 50 coups si nécessaire
      
      /* lblCoup : incrémenté dès que c'est aux Noirs de jouer */
      if (sideCourant == sideBlack) liveBoard->nbEntiers ++;
      monConnecteur.lblNumCoup.cell.stringValue = [NSString stringWithFormat:@"n° coup : %d", liveBoard->nbEntiers];
      
      /* lblEchec : déterminé ci-dessous */
      if ([strCheck isEqual:@"Echec"]) {
         if (checkCount >1) monConnecteur.lblEchec.cell.stringValue = @"Échec : ++";
         else               monConnecteur.lblEchec.cell.stringValue = @"Échec : +";
      }
      else                  monConnecteur.lblEchec.cell.stringValue = @"Échec :";
      
      /* lblInfo : traité par ailleurs et en dehors des seuls cas des moves exécutés, puisqu'il s'agit
       davantage de renseigner l'utilisateur sur le déroulement de la partie...*/
      
   } // Fin de Méthode 'MajStatusBarViaMove'


   // ==================================================================================================
   // MÉTHODE D'INSTANCE GÉNÉRÉE À LA CREATION DE CHESSVIEW (CODE ET OBJET DE L'UI) QUI DÉRIVE DE NSVIEW
   // C'EST DONC LÀ QU'ON PLACE LE CODE DE TOUT CE QUI DÉFINIT NOTRE CUSTOM NSVIEW
   // La méthode est appelée automatiquement dès que la vue nécessite d'être dessinée ou mise à jour
   // On y a judicieusement inséré la méthode 'drawBoard' qui définit le dessin de l'échiquier
   // On note au passage que 'drawRect' est une méthode d'instance de NSView, dont dérive ChessView.
   // Quant à 'dirtyRect' il désigne la partie 'sale' du rectangle, càd celle nécessitant une mise à jour.
   -(void)drawRect:(NSRect)dirtyRect
   {
      /* Corps de la méthode à compléter par notre propre code ci-dessous */
      [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
      [self drawBoard];
   }


   // ==================================================================================================
   // Méthode pour détermination d'une NSString pour l'affichage de l'évaluation
   +(NSString *)VisualIndicator:(int)evalWhitePOV
   {
      // Convertir en pions, arrondis au dixième le plus proche
      float pawns = round(evalWhitePOV/10.0)/10.0;
      
      /* // Limiter entre -5 et +5
       if (roundedPawns > 5) roundedPawns = 5;
       if (roundedPawns < -5) roundedPawns = -5; */
      
      // Préparation de la NSString d'affichage
      NSString *evalString;
      if (pawns > 0)    evalString = [NSString stringWithFormat:@"Eval : +%.1f", pawns];
      else              evalString = [NSString stringWithFormat:@"Eval : %.1f", pawns];
      
      /* // Construire la barre
       NSMutableString *visual = [NSMutableString string];
       if (roundedPawns >= 0) {
       // Avantage Blancs : remplir de gauche
       for (int i = 0; i < 5; i++) {
       [visual appendString:(i < roundedPawns) ? @"●" : @"○"];
       }
       // Partie droite vide
       [visual appendString:@"○○○○○"];
       } else {
       // Avantage Noirs : partie gauche vide
       [visual appendString:@"○○○○○"];
       // Remplir de droite
       int filledRight = -roundedPawns;  // Convertir en positif
       for (int i = 0; i < 5; i++) {
       [visual appendString:(i < filledRight) ? @"●" : @"○"];
       }
       } */
      
      return evalString;
   }

   // Ajout méthodes de retourne des coordonnées pour l'UI
   - (int)engineXFromUIX:(int)x {
       return uiFlipped ? 7 - x : x;
   }

   - (int)engineYFromUIY:(int)y {
       return uiFlipped ? 7 - y : y;
   }


@end


static inline int engineX(int uiX, BOOL flipped) {
    return flipped ? 7 - uiX : uiX;
}

static inline int engineY(int uiY, BOOL flipped) {
    return flipped ? 7 - uiY : uiY;
}
