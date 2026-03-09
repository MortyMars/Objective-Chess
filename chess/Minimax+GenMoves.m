// Minimax+GenMoves.m
// chess
// Created by MCN on 16/02/2026 for optimized New Engine
// Copyright (c) 2026 MCN. All rights reserved


#import "Minimax+GenMoves.h"
#import "ChessConfig.h"



@implementation Minimax (GenMoves) // Extension de la Classe Minimax


   // ================================================================================================
   // Méthode générant tous les coups des pièces présentes sur l'échiquier
   // (contrairement à 'generateCaptures...' qui ne génère que les captures possibles
   -(void)GenMovesForSide:(Side)side
                    board:(ChessBoard *)board
                     into:(NSMutableArray<Move *> *)moves
   {
      // 1️⃣ On vide la liste existante
      [moves removeAllObjects];
      
      // 2️⃣ On parcourt l’échiquier
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            
            Piece *p = board->pieceCase[x][y];
            
            if (!p || p.side != side) continue;
            
            switch (p.type) {
                  
               case Pion: [self GenPawnMovesFromX:x y:y piece:p board:board into:moves]; break;
                  
               case Cava: [self GenKnightMovesFromX:x y:y piece:p board:board into:moves]; break;
                  
               case Fou:  [self GenSlideMovesFromX:x y:y piece:p board:board
                                              dirs:bishopDirs dirCount:4 into:moves]; break;
                  
               case Tour: [self GenSlideMovesFromX:x y:y piece:p board:board
                                              dirs:rookDirs dirCount:4 into:moves]; break;
                  
               case Dame: [self GenSlideMovesFromX:x y:y piece:p  board:board
                                              dirs:queenDirs   dirCount:8 into:moves]; break;
                  
               case Roi:  [self GenKingMovesFromX:x y:y piece:p board:board into:moves]; break;
                  
               default: break;
            }
         }
      }
   } // !generatePseudoMoves


   // ================================================================================================
   // Méthode déterminant les déplacements légaux du Pion
   -(void)GenPawnMovesFromX:(int)x y:(int)y
                      piece:(Piece *)p
                      board:(ChessBoard *)board
                       into:(NSMutableArray<Move *> *)moves
   {
      /* RAPPEL : SEULE L'UI (CHESSVIEW) EST CONCERNÉE PAR UN RETOURNEMENT DU BOARD ET EST SEULE À LE GÉRER
      Le moteur canonique basé sur make/unmake est désynchronisé de l'UI quant aux déplacements des pièces.
      Il est toujours calé sur l'orientation classique 'Blancs en bas' ----------------------------------*/
      
      int dir = (p.side == sideWhite) ? 1 : -1;
      int startRank = (p.side == sideWhite) ? 1 : 6;
      int promRank  = (p.side == sideWhite) ? 7 : 0;  // ✨ NOUVEAU : rang de promotion
      
      
      // 1️⃣ Avance simple
      int ny = y + dir;
      if (ny >= 0 && ny <= 7 && !board->pieceCase[x][ny]) {
         
         // ✨ Vérifier si c'est une promotion
         if (ny == promRank) {
            // ASYMÉTRIE : Joueur = 1 coup, IA = 4 coups
            if (p.side == sideJoueur) {
               Move *m = [Move newMoveFromX:x Y:y ToNx:x Ny:ny];
               m.movingPiece   = p;
               m.isPromotion   = YES;
               m.promotionType = Dame;
               m.fromSquare    = SQ(x,y);
               m.toSquare      = SQ(x,ny);
               [moves addObject:m];
            }
            else {
               PieceType promotions[] = {Dame, Tour, Fou, Cava};
               for (int i = 0; i < 4; i++) {
                  Move *m = [Move newMoveFromX:x Y:y ToNx:x Ny:ny];
                  m.movingPiece   = p;
                  m.isPromotion   = YES;
                  m.promotionType = promotions[i];
                  m.fromSquare    = SQ(x,y);
                  m.toSquare      = SQ(x,ny);
                  [moves addObject:m];
               }
            }
         }
         else {
            // Coup normal (non-promotion)
            Move *m = [Move newMoveFromX:x Y:y ToNx:x Ny:ny];
            m.movingPiece = p;
            m.fromSquare  = SQ(x,y);
            m.toSquare    = SQ(x,ny);
            [moves addObject:m];
            
            // Avance double
            if (y == startRank && !board->pieceCase[x][y + 2*dir]) {
               Move *m2 = [Move newMoveFromX:x Y:y ToNx:x Ny:y + 2*dir];
               m2.movingPiece = p;
               m2.fromSquare  = SQ(x,y);
               m2.toSquare    = SQ(x,y + 2*dir);
               [moves addObject:m2];
            }
         }
      }
      
      // 2️⃣ Captures diagonales NORMALES
      for (int dx = -1; dx <= 1; dx += 2) {
         
         int nx = x + dx;
         ny = y + dir;
         
         if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;
         
         Piece *target = board->pieceCase[nx][ny];
         if (target && target.side != p.side && target.type != Roi) {
            
            // ✨ Vérifier si c'est une promotion-capture
            if (ny == promRank) {
               // ASYMÉTRIE : Joueur = 1 coup, IA = 4 coups
               if (p.side == sideJoueur) {
                  Move *m = [Move newMoveFromX:x Y:y ToNx:nx Ny:ny];
                  m.movingPiece   = p;
                  m.isCapture     = YES;
                  m.isPromotion   = YES;
                  m.promotionType = Dame;
                  m.capturedPiece = target;
                  m.fromSquare    = SQ(x,y);
                  m.toSquare      = SQ(nx,ny);
                  [moves addObject:m];
               }
               else {
                  PieceType promotions[] = {Dame, Tour, Fou, Cava};
                  for (int i = 0; i < 4; i++) {
                     Move *m = [Move newMoveFromX:x Y:y ToNx:nx Ny:ny];
                     m.movingPiece   = p;
                     m.isCapture     = YES;
                     m.isPromotion   = YES;
                     m.promotionType = promotions[i];
                     m.capturedPiece = target;
                     m.fromSquare    = SQ(x,y);
                     m.toSquare      = SQ(nx,ny);
                     [moves addObject:m];
                  }
               }
            }
            else {
               // Capture normale (non-promotion)
               Move *m = [Move newMoveFromX:x Y:y ToNx:nx Ny:ny];
               m.movingPiece   = p;
               m.isCapture     = YES;
               m.capturedPiece = target;
               m.fromSquare    = SQ(x,y);
               m.toSquare      = SQ(nx,ny);
               [moves addObject:m];
            }
         }
      }
      
      // 3️⃣ PRISE EN PASSANT
      /* Noter que l'organisation du code ci-dessous, basée sur de multiples cas de sortie de la méthode -par des 'return'
      successifs, fonctionne uniquement parce que le traitement de la prise en passant est le dernier de la méthode et qu'ainsi,
      une sortie forcée à ce stade ne concerne que la possibilité de prise e.p., sans interagir sur les cas 1️⃣ et 2️⃣ ci-dessus
      générant leurs propres moves indépendamment --------------------------------------------------------------------------- */
      
      // L'indicateur 'enPassantFile' doit être actif
      if (board->enPassantFile == -1)     return;  // Indicateur non positionné
      
      // Le pion doit être sur le bon rang
      int epRank = (p.side == sideWhite) ? 4 : 3;  // 5ème rang pour Blancs, 4ème pour Noirs
      if (y != epRank)                    return;  // Pion pas sur le bon rang
      
      // Le pion doit être sur une colonne adjacente à la colonne EP
      int epFile = board->enPassantFile;
      if (abs(x - epFile) != 1)           return;  // Pion pas sur une colonne adjacente
      
      // Case destination EP
      int epX = epFile;
      int epY = y + dir;
      
      // Case où se trouve le pion adverse à capturer
      int captureY = y;  // Case sur le même rang que notre pion
      
      // 🔴 Vérifier qu'un pion adverse est bien là !
      Piece *capturedPawn = board->pieceCase[epX][captureY];
      if (!capturedPawn)                  return;  // Pas de pion à capturer
      if (capturedPawn.type != Pion)      return;  // La pièce n'est pas un pion
      if (capturedPawn.side == p.side)    return;  // Le pion est du même camp
      
      // Tous les tests précédents ayant été satisfaits, on peut créer un move e.p.
      Move *ep = [Move newMoveFromX:x Y:y ToNx:epX Ny:epY];
      ep.movingPiece   = p;
      ep.isCapture     = YES;
      ep.isEnPassant   = YES;
      ep.capturedPiece = capturedPawn;
      ep.fromSquare    = SQ(x,y);
      ep.toSquare      = SQ(epX,epY);
      
      // NSLog(@"   ✅ Coup EP créé: %@ (isEnPassant=%d)", ep, ep.isEnPassant);
      
      [moves addObject:ep];
      
   } // !GenPawnMovesFromX


   // ================================================================================================
   // Méthode déterminant les déplacements légaux du Cavalier
   -(void)GenKnightMovesFromX:(int)x y:(int)y
                        piece:(Piece *)p
                        board:(ChessBoard *)board
                         into:(NSMutableArray *)moves
   {
      for (int i = 0; i < 8; i++) {
         int nx = x + knightOffsets[i][0];
         int ny = y + knightOffsets[i][1];
         
         if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;
         
         Piece *target = board->pieceCase[nx][ny];
         
         if (!target || (target.side != p.side && target.type != Roi)) {
            Pos *start = [Pos posWithX:x y:y];
            Pos *dest  = [Pos posWithX:nx y:ny];
            Move *m = [[Move alloc] initWithStart:start Dest:dest];
            
            m.movingPiece = p;
            m.fromSquare  = SQ(x, y);
            m.toSquare    = SQ(nx, ny);
            
            if (target) {
               m.isCapture = YES;
               m.capturedPiece = target;
            }
            
            [moves addObject:m];
         }
      }
   }


   // ================================================================================================
   // Méthode déterminant les déplacements légaux des pièces glissantes ; Fou, Tour, Dame
   -(void)GenSlideMovesFromX:(int)x y:(int)y
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
               Move *m = [[Move alloc] initWithStart:start Dest:dest];
               
               m.movingPiece = p;
               m.fromSquare  = SQ(x, y);
               m.toSquare    = SQ(nx, ny);
               
               if (target) {
                  m.isCapture = YES;
                  m.capturedPiece = target;
               }
               
               [moves addObject:m];
               
            }
            else {
               if (target.side != p.side && target.type != Roi) {
                  Move *m = [[Move alloc] initWithStart:start Dest:dest];
                  
                  m.movingPiece = p;
                  m.fromSquare  = SQ(x, y);
                  m.toSquare    = SQ(nx, ny);
                  
                  if (target) {
                     m.isCapture = YES;
                     m.capturedPiece = target;
                  }
                  
                  [moves addObject:m];
                  
               }
               break; // 🛑 toute pièce bloque, y compris le roi
            }
            
            nx += dx;
            ny += dy;
         }
      }
   }



   // ================================================================================================
   // Génération des coups légaux du Roi (déplacements normaux + roque)
   -(void)GenKingMovesFromX:(int)x y:(int)y
                      piece:(Piece *)p
                      board:(ChessBoard *)board
                       into:(NSMutableArray *)moves
   {
      // 1️⃣ Déplacements normaux du Roi (8 cases autour)
      for (int dx = -1; dx <= 1; dx++) {
         for (int dy = -1; dy <= 1; dy++) {
            
            if (dx == 0 && dy == 0)
               continue;   // pas de déplacement nul
            
            int nx = x + dx;
            int ny = y + dy;
            
            // Hors échiquier
            if (nx < 0 || nx > 7 || ny < 0 || ny > 7)
               continue;
            
            Piece *target = board->pieceCase[nx][ny];
            
            // Case libre ou occupée par une pièce adverse (sauf Roi adverse)
            if (!target || (target.side != p.side && target.type != Roi)) {
               
               Move *m = [Move newMoveFromX:x Y:y ToNx:nx Ny:ny];
               
               m.movingPiece = p;
               m.fromSquare  = SQ(x, y);
               m.toSquare    = SQ(nx, ny);
               
               if (target) {
                  m.isCapture = YES;
                  m.capturedPiece = target;
               }
               
               [moves addObject:m];
            }
         }
      }
      
      // 2️⃣ Roque (ajouté hors des boucles de déplacement)
      if (p.type != Roi || p.numMoves != 0 || [self IsKingInCheck:p.side board:board])
         return;  // Si la pièce n'est pas un roi, ou qu'elle a déjà bougé, ou que le Roi est en échec, pas de Roque légal --> on sort
      
      
      // Positions des Rois, sachant que du point de vue du moteur, les Blancs sont tjs en bas
      // et que la case de coordonnées col x=0 et rang y=0 est tjs en bas à gauche de l'écran
      int xRoi = 4;                                // La colonne des rois est tjs 4 en plateau canonique
      int yRoi = (p.side == sideWhite) ? 0 : 7;    // Roi Blanc en bas (rang 0), Roi Noir en haut (rang 7)
      
      // Sécurité minimale : on doit être bien sur la case de départ
      if (x != xRoi || y != yRoi) return;
      
      Side sideEnemy = (p.side == sideWhite)? sideBlack:sideWhite;
      
      // Petit roque (côté Roi) -------------------------------------------------------------------
      Piece *rookH = board->pieceCase[7][yRoi];
      if (rookH &&
          rookH.type == Tour &&
          rookH.side == p.side &&
          rookH.numMoves == 0) {
         
         // Les 2 cases entre Roi et Tour doivent être vides
         // Ces cases ne doivent pas être sous le coup d'un échec potentiel...
         if (!board->pieceCase[5][yRoi] &&
             !board->pieceCase[6][yRoi] &&
             ![self IsSquareAttackedAtX:5 Y:yRoi bySide:sideEnemy Board:board] &&
             ![self IsSquareAttackedAtX:6 Y:yRoi bySide:sideEnemy Board:board]) {
            
            Move *m = [Move newMoveFromX:4 Y:yRoi ToNx:6 Ny:yRoi];
            m.isCastling  = YES;
            m.movingPiece = p;
            m.fromSquare  = SQ(4, yRoi);
            m.toSquare    = SQ(6, yRoi);
            
            [moves addObject:m];
         }
      } // !Petit Roque ---------------------------------------------------------------------------
      
      // Grand roque (côté Dame) ------------------------------------------------------------------
      Piece *rookA = board->pieceCase[0][yRoi];
      if (rookA &&
          rookA.type == Tour &&
          rookA.side == p.side &&
          rookA.numMoves == 0) {
         
         // Les 3 cases entre Roi et Tour doivent être vides
         // Les 2 cases parcourues par le Roi ne doivent pas être sous le coup d'un échec potentiel...
         if (!board->pieceCase[1][yRoi] &&
             !board->pieceCase[2][yRoi] &&
             !board->pieceCase[3][yRoi] &&
             ![self IsSquareAttackedAtX:2 Y:yRoi bySide:sideEnemy Board:board] &&
             ![self IsSquareAttackedAtX:3 Y:yRoi bySide:sideEnemy Board:board]) {
            
            Move *m = [Move newMoveFromX:4 Y:yRoi ToNx:2 Ny:yRoi];
            m.isCastling  = YES;
            m.movingPiece = p;
            m.fromSquare  = SQ(4, yRoi);
            m.toSquare    = SQ(2, yRoi);
            
            [moves addObject:m];
         }
      } // !Grand Roque ---------------------------------------------------------------------------
      
   } // !GenKingMovesFromX


   // ================================================================================================
   // Méthode générant uniquement les coups bruyants (captures) des pièces présentes sur l'échiquier,
   // contrairement à 'GenMoves...' qui génère tous les déplacements les possibles.
   - (void)GenCapturForSide:(Side)side
                      board:(ChessBoard *)board
                       into:(NSMutableArray<Move *> *)moves
   {
      [moves removeAllObjects];
      
      for (int x = 0; x < 8; x++) {
         for (int y = 0; y < 8; y++) {
            Piece *p = board->pieceCase[x][y];
            if (!p || p.side != side)
               continue;
            
            switch (p.type) {
                  
               case Pion: [self GenPawnCapturFromX:x y:y piece:p board:board into:moves]; break;
                  
               case Cava: [self GenKnightCapturFromX:x y:y piece:p board:board into:moves]; break;
                  
               case Fou: [self GenSlideCapturFromX:x y:y piece:p board:board
                                              dirs:bishopDirs dirCount:4 into:moves]; break;
                  
               case Tour: [self GenSlideCapturFromX:x y:y piece:p board:board
                                               dirs:rookDirs dirCount:4 into:moves]; break;
                  
               case Dame: [self GenSlideCapturFromX:x y:y piece:p board:board
                                               dirs:queenDirs dirCount:8 into:moves]; break;
                  
               case Roi: [self GenKingCapturFromX:x y:y piece:p board:board into:moves]; break;
                  
               default: break;   // Pièce invalide ou futur type
                  
            }
         }
      }
   }


   // ================================================================================================
   // Méthode déterminant les captures réalisables par le Pion
   -(void)GenPawnCapturFromX:(int)x y:(int)y
                       piece:(Piece *)p
                       board:(ChessBoard *)board
                        into:(NSMutableArray<Move *> *)moves
   {
      /* RAPPEL : SEULE L'UI (CHESSVIEW) EST CONCERNÉE PAR UN RETOURNEMENT DU BOARD ET EST SEULE À LE GÉRER
      Le moteur canonique basé sur make/unmake est désynchronisé de l'UI quant aux déplacements des pièces.
      Il est toujours calé sur l'orientation classique 'Blancs en bas' -----------------------------------*/
      
      int dir = (p.side == sideWhite) ? 1 : -1;
      
      int ny = y + dir;
      
      if (ny < 0 || ny >= 8) return;
      
      for (int dx = -1; dx <= 1; dx += 2) {
         int nx = x + dx;
         if (nx < 0 || nx >= 8) continue;
         
         Piece *target = board->pieceCase[nx][ny];
         if (target && target.side != p.side && target.type != Roi) {
            Pos *start = [Pos posWithX:x y:y];
            Pos *dest  = [Pos posWithX:nx y:ny];
            Move *m = [[Move alloc] initWithStart:start Dest:dest];
            
            m.movingPiece = p;
            m.fromSquare  = SQ(x, y);        // ou équivalent chez toi
            m.toSquare    = SQ(nx, ny);
            
            if (target) {
               m.isCapture = YES;
               m.capturedPiece = target;
            }
            
            if ((p.side == sideWhite && ny == 7) ||
                (p.side == sideBlack && ny == 0)) {
               m.isPromotion = YES;
            }
            [moves addObject:m];
         }
      }
      
      // 3️⃣ PRISE EN PASSANT
      Move *lm = board.lastMove;
      if (lm &&
          lm.movingPiece.type == Pion &&
          lm.movingPiece.side != p.side &&
          abs(lm.start.y - lm.dest.y) == 2 &&
          lm.dest.y == y &&
          abs(lm.dest.x - x) == 1)
      {
         
         int epX = lm.dest.x;
         int epY = y + dir;
         
         Move *ep = [Move newMoveFromX:x Y:y ToNx:epX Ny:epY];
         ep.movingPiece   = p;
         ep.isCapture     = YES;
         ep.isEnPassant   = YES;
         ep.capturedPiece = board->pieceCase[epX][y]; // pion pris
         ep.fromSquare    = SQ(x,y);
         ep.toSquare      = SQ(epX,epY);
         [moves addObject:ep];
      }
      
   }


   // ================================================================================================
   // Méthode déterminant les captures réalisables par le Cavalier
   -(void)GenKnightCapturFromX:(int)x y:(int)y
                         piece:(Piece *)p
                         board:(ChessBoard *)board
                          into:(NSMutableArray<Move *> *)moves
   {
      static const int kMoves[8][2] = {
         {-2,-1},{-2,1},{-1,-2},{-1,2},
         {1,-2},{1,2},{2,-1},{2,1}
      };
      
      for (int i = 0; i < 8; i++) {
         int nx = x + kMoves[i][0];
         int ny = y + kMoves[i][1];
         
         if (nx < 0 || nx >= 8 || ny < 0 || ny >= 8) continue;
         
         Piece *target = board->pieceCase[nx][ny];
         
         if (target && target.side != p.side && target.type != Roi) {
            Pos *start = [Pos posWithX:x y:y];
            Pos *dest  = [Pos posWithX:nx y:ny];
            Move *m = [[Move alloc] initWithStart:start Dest:dest];
            
            m.movingPiece = p;
            m.fromSquare  = SQ(x, y);        // ou équivalent chez toi
            m.toSquare    = SQ(nx, ny);
            
            if (target) {
               m.isCapture = YES;
               m.capturedPiece = target;
            }
            
            [moves addObject:m];
            
         }
      }
   }


   // ================================================================================================
   // Méthode déterminant les captures réalisables par les pièces glissantes : Fou, Tour, Dame
   -(void)GenSlideCapturFromX:(int)x y:(int)y
                        piece:(Piece *)p
                        board:(ChessBoard *)board
                         dirs:(const int (*)[2])dirs
                     dirCount:(int)dirCount
                         into:(NSMutableArray<Move *> *)moves
   {
      // Pour chaque direction possible
      for (int d = 0; d < dirCount; d++) {
         
         int dx = dirs[d][0];
         int dy = dirs[d][1];
         
         int nx = x + dx;
         int ny = y + dy;
         
         // On avance dans la direction tant qu'on est sur l'échiquier
         while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
            
            Piece *target = board->pieceCase[nx][ny];
            
            if (target) {
               // Une pièce bloque toujours
               
               if (target.side != p.side && target.type != Roi) {
                  // Capture légale
                  Pos *start = [Pos posWithX:x y:y];
                  Pos *dest  = [Pos posWithX:nx y:ny];
                  Move *m = [[Move alloc] initWithStart:start Dest:dest];
                  
                  m.movingPiece = p;
                  m.fromSquare  = SQ(x, y);        // ou équivalent chez toi
                  m.toSquare    = SQ(nx, ny);
                  
                  if (target) {
                     m.isCapture = YES;
                     m.capturedPiece = target;
                  }
                  
                  [moves addObject:m];
                  
               }
               
               break; // 🛑 on s'arrête à la première pièce rencontrée
            }
            
            // Case vide → on continue à glisser
            nx += dx;
            ny += dy;
         }
      }
   }


   // ================================================================================================
   // Méthode déterminant les captures réalisables par le Roi
   -(void)GenKingCapturFromX:(int)x y:(int)y
                       piece:(Piece *)p
                       board:(ChessBoard *)board
                        into:(NSMutableArray<Move *> *)moves
   {
      for (int dx = -1; dx <= 1; dx++) {
         for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            
            int nx = x + dx;
            int ny = y + dy;
            
            if (nx < 0 || nx >= 8 || ny < 0 || ny >= 8) continue;
            
            Piece *target = board->pieceCase[nx][ny];
            
            if (target && target.side != p.side && target.type != Roi) {
               Pos *start = [Pos posWithX:x y:y];
               Pos *dest  = [Pos posWithX:nx y:ny];
               Move *m = [[Move alloc] initWithStart:start Dest:dest];
               
               m.movingPiece = p;
               m.fromSquare  = SQ(x, y);        // ou équivalent chez toi
               m.toSquare    = SQ(nx, ny);
               
               if (target) {
                  m.isCapture = YES;
                  m.capturedPiece = target;
               }
               
               [moves addObject:m];
               
            }
         }
      }
   }


   // ================================================================================================
   // Méthode détectant si une pièce est défendue
   - (BOOL)IsSquareDefended:(Square)sq bySide:(Side)side board:(ChessBoard *)board
   {
      NSMutableArray<Move *> *caps = [NSMutableArray arrayWithCapacity:8];
      [self GenCapturForSide:side board:board into:caps];
      
      for (Move *m in caps) {
         if (m.toSquare == sq)
            return YES;
      }
      return NO;
   }


   // ================================================================================================
   // Méthode détectant si une case est attaquée, nécessaire pour vérifier les conditions du roque
   -(BOOL)IsSquareAttackedAtX:(int)x
                            Y:(int)y
                       bySide:(Side)attackingSide
                        Board:(ChessBoard *)board
   {
      // 1️⃣ Attaque par Cavalier
      static const int knightMoves[8][2] = {
         {1,2},{2,1},{-1,2},{-2,1},
         {1,-2},{2,-1},{-1,-2},{-2,-1}
      };
      
      for (int i = 0; i < 8; i++) {
         int nx = x + knightMoves[i][0];
         int ny = y + knightMoves[i][1];
         if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;
         
         Piece *p = board->pieceCase[nx][ny];
         if (p && p.side == attackingSide && p.type == Cava)
            return YES;
      }
      
      // 2️⃣ Attaque par Pion
      // Direction d'attaque du pion dépend de son camp ET de l'orientation du plateau
      int pawnDir;
      if (sideJoueur == sideWhite) {
         pawnDir = (attackingSide == sideWhite) ? 1 : -1;
      } else {
         pawnDir = (attackingSide == sideWhite) ? -1 : 1;
      }
      
      for (int dx = -1; dx <= 1; dx += 2) {
         int px = x + dx;
         int py = y - pawnDir;  // Position d'où le pion attaquerait
         if (px < 0 || px > 7 || py < 0 || py > 7) continue;
         
         Piece *p = board->pieceCase[px][py];
         if (p && p.side == attackingSide && p.type == Pion)
            return YES;
      }
      
      // 3️⃣ Attaque par Fou/Dame (diagonales)
      static const int bishopDirs[4][2] = {{1,1},{1,-1},{-1,1},{-1,-1}};
      
      for (int d = 0; d < 4; d++) {
         int dx = bishopDirs[d][0];
         int dy = bishopDirs[d][1];
         int nx = x + dx;
         int ny = y + dy;
         
         while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
            Piece *p = board->pieceCase[nx][ny];
            if (p) {
               if (p.side == attackingSide && (p.type == Fou || p.type == Dame))
                  return YES;
               break;
            }
            nx += dx;
            ny += dy;
         }
      }
      
      // 4️⃣ Attaque par Tour/Dame (lignes droites)
      static const int rookDirs[4][2] = {{1,0},{-1,0},{0,1},{0,-1}};
      
      for (int d = 0; d < 4; d++) {
         int dx = rookDirs[d][0];
         int dy = rookDirs[d][1];
         int nx = x + dx;
         int ny = y + dy;
         
         while (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
            Piece *p = board->pieceCase[nx][ny];
            if (p) {
               if (p.side == attackingSide && (p.type == Tour || p.type == Dame))
                  return YES;
               break;
            }
            nx += dx;
            ny += dy;
         }
      }
      
      // 5️⃣ Attaque par Roi adverse (cases adjacentes)
      for (int dx = -1; dx <= 1; dx++) {
         for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            int nx = x + dx;
            int ny = y + dy;
            if (nx < 0 || nx > 7 || ny < 0 || ny > 7) continue;
            
            Piece *p = board->pieceCase[nx][ny];
            if (p && p.side == attackingSide && p.type == Roi)
               return YES;
         }
      }
      
      return NO;
   }

@end
