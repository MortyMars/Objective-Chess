// ChessBoard+MakeMoves.m
// chess
// Created by MCN on 16/02/2026 for optimized New Engine
// Copyright (c) 2026 MCN. All rights reserved


#import "ChessBoard+MakeMoves.h"
#import "ChessConfig.h"



@implementation ChessBoard (MakeMoves)    // Extension de la Classe ChessBoard

   // ==================================================================================================
   // Méthode d'instance 'makeMove' permettant de réaliser un move fictif ou réel
   -(MoveState)makeMove:(Move *)m
   {
      NSAssert(m.fromSquare == m.start.y * 8 + m.start.x, @"Move incohérent: fromSquare");
      NSAssert(m.toSquare   == m.dest.y  * 8 + m.dest.x, @"Move incohérent: toSquare");
      
      #ifdef DEBUG_ZOBRIST
         uint64_t hashAnteMove = zobristKey;
         uint64_t hashRecalcAnteMove = recomputeZobrist(self);
         if (hashAnteMove != hashRecalcAnteMove) {
            NSLog(@"⚠️ ZOBRIST DÉJÀ CORROMPU AVANT makeMove %@", m);
            NSLog(@"   Hash actuel: %llx, recalculé: %llx", hashAnteMove, hashRecalcAnteMove);
         }
      #endif
      
      
      MoveState st = {0};
      st.oldCastleRights   = castlingRights;
      st.oldEnPassantFile  = enPassantFile;
      
      int fx = SQ_X(m.fromSquare);
      int fy = SQ_Y(m.fromSquare);
      int tx = SQ_X(m.toSquare);
      int ty = SQ_Y(m.toSquare);
      
      int fromSq = m.fromSquare;
      int toSq   = m.toSquare;
      
      Piece *moving = pieceCase[fx][fy];
      NSAssert(moving, @"makeMove: pas de pièce à déplacer");
      
      /*----------------------- ZOBRIST — EP ancien -------------------------------*/
      #ifdef DEBUG_ZOBRIST
         NSLog(@"🔵 MAKE EP ancien:");
         NSLog(@"   enPassantFile avant = %d", enPassantFile);
      #endif
      
      if (enPassantFile != -1) {
         #ifdef DEBUG_ZOBRIST
               NSLog(@"   → XOR retire ancien EP [%d]", enPassantFile);
         #endif
         zobristKey ^= zobristEnPassant[enPassantFile];
      }
      enPassantFile = -1;
      
      #ifdef DEBUG_ZOBRIST
         NSLog(@"   → enPassantFile réinitialisé à -1");
      #endif
      
      /*----------------------- ZOBRIST — retirer pièce source --------------------*/
      zobristKey ^= zobristPiece[moving.side][moving.type][fromSq];
      
      /*----------------------- CAPTURE / EN PASSANT ------------------------------*/
      if (m.isEnPassant) {
         st.wasEnPassant = YES;
         
         int cx = tx;
         int cy = fy;
         
         #ifdef DEBUG_ZOBRIST
               NSLog(@"🟡 EP makeMove: start=(%d,%d) dest=(%d,%d) capture=(%d,%d)",
                     fx, fy, tx, ty, cx, cy);
               NSLog(@"   fromSq=%d toSq=%d capSq=%d", fromSq, toSq, cy*8+cx);
               NSLog(@"   Pièce capturée: %@", pieceCase[cx][cy]);
               NSLog(@"   m.capturedPiece: %@", m.capturedPiece);
               if (pieceCase[cx][cy] != m.capturedPiece) {
                  NSLog(@"❌ INCOHÉRENCE: pièce sur board != m.capturedPiece !");
               }
         #endif
         
         st.enPassantX = cx;
         st.enPassantY = cy;
         
         st.captured = pieceCase[cx][cy];
         
         // 🔴 XOR AVANT de retirer physiquement
         int capSq = cy * 8 + cx;
         zobristKey ^= zobristPiece[st.captured.side][st.captured.type][capSq];
         
         // Retirer physiquement
         pieceCase[cx][cy] = nil;
         
         
         // Mode verbeux Prise EP ---------------------------------------*
         LOG_EP(@"%@ pawn from (%d,%d) captures pawn at (%d,%d)",
                (moving.side == sideWhite ? @"White" : @"Black"),
                m.start.x, m.start.y,
                cx, cy);
         // Fin de mode verbeux -----------------------------------------*
      } else {
         st.captured = pieceCase[tx][ty];
         if (st.captured) {
            zobristKey ^= zobristPiece[st.captured.side][st.captured.type][toSq];
         }
      }
      
      // LOG DE DEBUG E.P.
      if (m.isEnPassant) {
          NSLog(@"🟡 EP détecté dans makeMove:");
          NSLog(@"   Move: %@", m);
          NSLog(@"   isEnPassant: %d", m.isEnPassant);
          
          st.wasEnPassant = YES;
          
      }
      else {
          // ✅ Ajouter ce log pour voir si on passe par ici
          if (moving.type == Pion && monConnecteur.maChessView->liveBoard->enPassantFile == tx) {
              NSLog(@"⚠️ Pion capture en (%d,%d) mais isEnPassant=NO !", tx, ty);
              NSLog(@"   enPassantFile=%d, tx=%d, ty=%d", monConnecteur.maChessView->liveBoard->enPassantFile, tx, ty);
             
             // ✅ STACKTRACE pour voir d'où vient cet appel
             NSLog(@"📍 Call stack:");
             for (NSString *line in [NSThread callStackSymbols]) {
                NSLog(@"   %@", line);
             }
         }
      } // FIN DE LOG DE DEBUG E.P.
      
      /*----------------------- DÉPLACEMENT PRINCIPAL -----------------------------*/
      pieceCase[tx][ty] = moving;
      pieceCase[fx][fy] = nil;
      
      zobristKey ^= zobristPiece[moving.side][moving.type][toSq];
      
      /*----------------------- EN PASSANT (double pas) ---------------------------*/
      if (moving.type == Pion && abs(ty - fy) == 2) {
         enPassantFile = fx;
         #ifdef DEBUG_ZOBRIST
               NSLog(@"🔵 MAKE EP nouveau: double pas détecté, enPassantFile = %d", enPassantFile);
         #endif
         zobristKey ^= zobristEnPassant[enPassantFile];
      }
      
      /*----------------------- ROQUE (tour) --------------------------------------*/
      if (m.isCastling) {
         // Recherche bug Roque Roi Noir IA
         NSLog(@"🏰 ROQUE makeMove:");
         NSLog(@"   Roi : (%d,%d) → (%d,%d)", fx, fy, tx, ty);
         NSLog(@"   kingSide = %d", (tx == 6));
         NSLog(@"   rookFromX = %d, y = %d", (tx==6)?7:0, fy);
         NSLog(@"   pieceCase[%d][%d] = %@", (tx==6)?7:0, fy,
                   pieceCase[(tx==6)?7:0][fy]);
         NSLog(@"   Tour numMoves = %d",
                   pieceCase[(tx==6)?7:0][fy].numMoves);
         
         int y = fy;
         BOOL kingSide = (tx == 6);
         
         int rookFromX = kingSide ? 7 : 0;
         int rookToX   = kingSide ? 5 : 3;
         
         Piece *rook = pieceCase[rookFromX][y];
         // ✅ DIAGNOSTIC détaillé au lieu d'un simple assert
         if (!rook || rook.type != Tour) {
            NSLog(@"❌ ROQUE IMPOSSIBLE:");
            NSLog(@"   Roi: (%d,%d) → (%d,%d), side=%@, kingSide=%d",
                    fx, fy, tx, ty,
                    (moving.side == sideWhite ? @"White" : @"Black"),
                    kingSide);
            NSLog(@"   rookFromX=%d, y=%d", rookFromX, y);
            NSLog(@"   pieceCase[%d][%d] = %@", rookFromX, y, rook);
            NSLog(@"   Move: %@", m);
            NSLog(@"   isCastling=%d", m.isCastling);
              
            // Afficher tout le board
            for (int yy = 7; yy >= 0; yy--) {
               NSMutableString *line = [NSMutableString stringWithFormat:@"   y=%d: ", yy];
               for (int xx = 0; xx < 8; xx++) {
                     Piece *p = pieceCase[xx][yy];
                     if (p) {
                          [line appendFormat:@"%@%c ",
                           (p.side == sideWhite ? @"W" : @"B"),
                           "?PNBRKQ"[p.type]];
                     } else {
                          [line appendString:@".. "];
                     }
               }
               NSLog(@"%@", line);
            }
              
            NSAssert(NO, @"Roque: tour absente ou incorrecte");
         }
         
         int rookFromSq = y * 8 + rookFromX;
         int rookToSq   = y * 8 + rookToX;
         
         // 🔴 XOR AVANT le déplacement physique !
         zobristKey ^= zobristPiece[rook.side][Tour][rookFromSq];
         
         pieceCase[rookToX][y]   = rook;
         pieceCase[rookFromX][y] = nil;
         
         // 🔴 XOR APRÈS le déplacement physique
         zobristKey ^= zobristPiece[rook.side][Tour][rookToSq];
         
         rook.numMoves++;  // ✅ FIX : Tour a bougé !
         
         LOG_CASTLE(@"%@ castles %@ side (king %d,%d → %d,%d)",
                    (moving.side == sideWhite ? @"White" : @"Black"),
                    kingSide ? @"KING" : @"QUEEN",
                    m.start.x, m.start.y,
                    m.dest.x, m.dest.y);
      }
      
      /*----------------------- PROMOTION -----------------------------------------*/
      if (moving.type == Pion &&
          ((moving.side == sideWhite && ty == 7) ||
           (moving.side == sideBlack && ty == 0)))
      {
         st.wasPromotion = YES;
         st.oldType = moving.type;
         
         zobristKey ^= zobristPiece[moving.side][Pion][toSq];
         moving.type = m.promotionType; // ✅ Utiliser m.promotionType
         zobristKey ^= zobristPiece[moving.side][Dame][toSq];
         
         LOG_PROMO(@"%@ pawn promotes at (%d,%d)",
                   (moving.side == sideWhite ? @"White" : @"Black"),
                   m.dest.x, m.dest.y);
         
         // ✅ LOG DE DIAGNOSTIC
         NSLog(@"🔵 PROMOTION dans makeMove:");
         NSLog(@"   m.promotionType = %d (%@)", m.promotionType,
                  @[@"?", @"Pion", @"Cavalier", @"Fou", @"Tour", @"Dame"][m.promotionType]);
         NSLog(@"   moving.type après = %d (%@)", moving.type,
                  @[@"?", @"Pion", @"Cavalier", @"Fou", @"Tour", @"Dame"][moving.type]);
         
      }
      
      /*----------------------- DROITS DE ROQUE -----------------------------------*/
      #ifdef DEBUG_ZOBRIST
            uint8_t oldRights = castlingRights;
      #endif
            
      zobristKey ^= zobristCastle[st.oldCastleRights];
      
      // 🔴 Mise à jour de castlingRights
      castlingRights = [self updateCastlingRights:castlingRights
                                          forMove:m
                                    capturedPiece:st.captured];
      
      #ifdef DEBUG_ZOBRIST
            if (castlingRights != oldRights) {
               NSLog(@"🔵 MAKE Castle rights changé: %d → %d", oldRights, castlingRights);
            }
      #endif
      
      zobristKey ^= zobristCastle[castlingRights];
      
      /*----------------------- SIDE TO MOVE --------------------------------------*/
      zobristKey ^= zobristSide;
      sideToMove = (sideToMove == sideWhite) ? sideBlack : sideWhite;
      
      #ifdef DEBUG_ZOBRIST
            if (moving.type == Roi && abs(m.dest.x - m.start.x) == 2) {
               NSLog(@"👀 ROQUE détecté implicitement : %@", m);
            }
      #endif
      
      moving.numMoves++;
      return st;
      
   } // !makeMove

   // ==================================================================================================
   // Méthode d'instance 'unmakeMove' permettant d'annuler un move de test et de rétablir le board
   // initial en restaurant les positions et indicateurs d'avant move
   -(void)unmakeMove:(Move *)m state:(MoveState)st
   {
      
      #ifdef DEBUG_ZOBRIST
            LOG_UNMAKE(@"moving back from toSq=%d (%d,%d) start=(%d,%d) dest=(%d,%d)",
                       m.toSquare,
                       m.dest.x, m.dest.y,
                       m.start.x, m.start.y,
                       m.dest.x, m.dest.y);
      #endif
      
      int fx = SQ_X(m.fromSquare);
      int fy = SQ_Y(m.fromSquare);
      int tx = SQ_X(m.toSquare);
      int ty = SQ_Y(m.toSquare);
      
      int fromSq = m.fromSquare;
      int toSq   = m.toSquare;
      

      Piece *moving = pieceCase[tx][ty];
      
      #ifdef DEBUG_ZOBRIST
            NSLog(@"UNMAKE moving at toSq=%d (%d,%d) start=(%d,%d) dest=(%d,%d)",
                  m.toSquare, tx, ty,
                  m.start.x, m.start.y,
                  m.dest.x, m.dest.y);
            NSAssert(moving, @"unmakeMove: pièce absente");
      #endif
      
      
      /*----------------------- SIDE TO MOVE --------------------------------------*/
      sideToMove = (sideToMove == sideWhite) ? sideBlack : sideWhite;
      zobristKey ^= zobristSide;
      
      /*----------------------- DROITS DE ROQUE -----------------------------------*/
      #ifdef DEBUG_ZOBRIST
         NSLog(@"🔵 UNMAKE Castle: actuel=%d, old=%d", castlingRights, st.oldCastleRights);
      #endif
      
      zobristKey ^= zobristCastle[castlingRights];
      castlingRights = st.oldCastleRights;
      zobristKey ^= zobristCastle[castlingRights];
      
      /*----------------------- PROMOTION -----------------------------------------*/
      if (st.wasPromotion) {
         zobristKey ^= zobristPiece[moving.side][m.promotionType][toSq];
         moving.type = st.oldType;
         zobristKey ^= zobristPiece[moving.side][Pion][toSq];
         
         LOG_PROMO(@"UNMAKE promotion at (%d,%d) restoring pawn",
                   m.dest.x, m.dest.y);
      }
      
      /*----------------------- ROQUE (tour) --------------------------------------*/
      if (m.isCastling) {
         int y = fy;
         BOOL kingSide = (tx == 6);
         
         int rookFromX = kingSide ? 5 : 3;  // Position actuelle
         int rookToX   = kingSide ? 7 : 0;  // Position d'origine
         
         Piece *rook = pieceCase[rookFromX][y];
         NSAssert(rook && rook.type == Tour, @"Unroque: tour absente");
         
         int rookFromSq = y * 8 + rookFromX;
         int rookToSq   = y * 8 + rookToX;
         
         // 🔴 XOR AVANT le déplacement physique !
         zobristKey ^= zobristPiece[rook.side][Tour][rookFromSq];
         
         pieceCase[rookToX][y]   = rook;
         pieceCase[rookFromX][y] = nil;
         
         // 🔴 XOR APRÈS le déplacement physique
         zobristKey ^= zobristPiece[rook.side][Tour][rookToSq];
         
         rook.numMoves--;  // ✅ FIX : Restaurer numMoves de la tour
         
         LOG_CASTLE(@"UNMAKE roque %@ side for %@",
                    kingSide ? @"KING" : @"QUEEN",
                    (moving.side == sideWhite ? @"White" : @"Black"));
      }
      
      /*----------------------- ZOBRIST — retirer pièce de toSq -------------------*/
      zobristKey ^= zobristPiece[moving.side][moving.type][toSq];
      
      /*----------------------- DÉPLACEMENT PRINCIPAL -----------------------------*/
      pieceCase[fx][fy] = moving;
      
      /*----------------------- ZOBRIST — ajouter pièce sur fromSq ----------------*/
      zobristKey ^= zobristPiece[moving.side][moving.type][fromSq];
      
      
      
      /*----------------------- CAPTURE / EN PASSANT ------------------------------*/
      if (st.wasEnPassant) {
         pieceCase[tx][ty] = nil;
         pieceCase[st.enPassantX][st.enPassantY] = st.captured;
         
         int capSq = st.enPassantY * 8 + st.enPassantX;
         zobristKey ^= zobristPiece[st.captured.side][st.captured.type][capSq];
         
         LOG_EP(@"UNMAKE EP: restoring pawn at (%d,%d)",
                st.enPassantX, st.enPassantY);
      }
      else {
         pieceCase[tx][ty] = st.captured;
         if (st.captured) {
            zobristKey ^= zobristPiece[st.captured.side][st.captured.type][toSq];
         }
      }
      
      /*----------------------- EN PASSANT FILE -----------------------------------*/
      #ifdef DEBUG_ZOBRIST
         NSLog(@"🔵 UNMAKE EP section:");
         NSLog(@"   enPassantFile actuel = %d", enPassantFile);
         NSLog(@"   st.oldEnPassantFile = %d", st.oldEnPassantFile);
      #endif
      
      // Retirer l'EP actuel s'il existe
      if (enPassantFile != -1) {
         #ifdef DEBUG_ZOBRIST
               NSLog(@"   → XOR retire EP actuel [%d]", enPassantFile);
         #endif
         zobristKey ^= zobristEnPassant[enPassantFile];
      }
      
      // Restaurer l'ancien EP
      enPassantFile = st.oldEnPassantFile;
      
      #ifdef DEBUG_ZOBRIST
         NSLog(@"   → Restauré enPassantFile = %d", enPassantFile);
      #endif
      
      // Ajouter l'ancien EP s'il existait
      if (enPassantFile != -1) {  // ✅ Tester enPassantFile après restauration !
         #ifdef DEBUG_ZOBRIST
               NSLog(@"   → XOR ajoute ancien EP [%d]", enPassantFile);
         #endif
         zobristKey ^= zobristEnPassant[enPassantFile];
      }
      
      #ifdef DEBUG_ZOBRIST
         NSLog(@"   → EP section terminée, enPassantFile final = %d", enPassantFile);
      #endif
      
      /*-----------------------------------------------------------------------------*/
      
      moving.numMoves--;
      
      if (pieceCase[m.dest.x][m.dest.y] &&
          pieceCase[m.dest.x][m.dest.y] == moving) {
         NSLog(@"❌ ERREUR: pièce encore présente sur dest après unmake %@", m);
      }
      
      // New DEBUG_ZOBRIST
      #ifdef DEBUG_ZOBRIST
         uint64_t hashAfterUnmake = zobristKey;
         uint64_t hashRecalc = recomputeZobrist(self);
         if (hashAfterUnmake != hashRecalc) {
            NSLog(@"💥 UNMAKE a corrompu le hash pour %@", m);
            NSLog(@"   Hash après unmake=%llx, recalculé=%llx, diff=%llx",
                  hashAfterUnmake, hashRecalc, hashAfterUnmake ^ hashRecalc);
            NSLog(@"   Était promo=%d capture=%d EP=%d roque=%d",
                  m.wasPromotion, m.isCapture, m.isEnPassant, m.isCastling);
         }
         else NSLog(@"👉 DEBUG_ZOBRIST DE FIN d'unmakeMove ATTEINT SANS SIGNALEMENT");
      #endif
      
      
   } // !unmakeMove


   // Méthode déterminant les droits de roque
   -(uint8_t)updateCastlingRights:(uint8_t)rights
                           forMove:(Move *)m
                     capturedPiece:(Piece *)captured
   {
       uint8_t newRights = rights;
       Piece *moving = m.movingPiece;
       
       // Roi bouge
       if (moving.type == Roi) {
           newRights &= (moving.side == sideWhite) ? ~0b0011 : ~0b1100;
       }
       
       // Tour bouge (comparaison sur square linéaire)
       if (moving.type == Tour) {
           int fromSq = m.fromSquare;
           if (fromSq == 0)  newRights &= ~0b0010; // a1
           if (fromSq == 7)  newRights &= ~0b0001; // h1
           if (fromSq == 56) newRights &= ~0b1000; // a8
           if (fromSq == 63) newRights &= ~0b0100; // h8
       }
       
       // Tour capturée
       if (captured && captured.type == Tour) {
           int toSq = m.toSquare;
           if (toSq == 0)  newRights &= ~0b0010;
           if (toSq == 7)  newRights &= ~0b0001;
           if (toSq == 56) newRights &= ~0b1000;
           if (toSq == 63) newRights &= ~0b0100;
       }
       
       return newRights;
   }


@end
