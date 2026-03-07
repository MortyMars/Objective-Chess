// ChessBoard.h
// chess
// Created by Andrew Wang on 15/07/2013
// Copyright (c) 2013 Andrew Wang. All rights reserved
// Optimized New Engine (makeMove/unmakeMove based) by MCN in 2026


#import "MoveToStr.h"
#import "Pos.h"
#import "Util.h"
#import "Minimax.h"


@class Piece, Move, Pos;

typedef struct
{
    Piece      *captured;     // pièce capturée lors du move (ou nil s'il n'y en a pas)
    PieceType  oldType;       // type de la pièce déplacée avant sa promotion
    BOOL       wasPromotion;
    BOOL       wasEnPassant;
    int        enPassantX;    // coordonnée X du pion capturé e.p.
    int        enPassantY;    // ---------- Y --------------------
   
    // ajouts TT - Zobrist
    uint8_t    oldCastleRights;  // anciens droits de roque
    int8_t     oldEnPassantFile; // ancienne colonne de prise en passant
   
} MoveState;


/* Déclaration de la Classe ChessBoard qui dérive de NSObject et qui adopte le protocole <NSCopying>,
ce qui permettra notamment de faire des copies d'objets ChessBoard, ...ce dont nous avons besoin  */
@interface ChessBoard : NSObject <NSCopying>
   {
      /* Variable d'instance (iVars) -tableau à 2 dimensions- désignant la pièce en case [x] [y]
       Déclarée publique pour pouvoir y accéder via l'opérateur '->' dans d'autres classes */
      @public Piece *pieceCase[8][8];
      
      /* Autres variables d'instances, créées pour stocker les valeurs liées à la 'Status Bar' */
      @public NSString *strRoque;
      @public NSString *strCibleEP;
      @public int       nbDemis;
      @public int       nbEntiers;
   
      // Ajout d'iVars pour Table de Transposition (TT)
      @public uint64_t  zobristKey;       // clé Zobrist 64 bits
      @public uint8_t   castlingRights;   // bit1 vaut 1 : K,bit2 vaut 2 : Q, bit3 vaut 4 : k et bit4 vaut 8 : q
                                          // 15 -> qkQK
      @public int8_t    enPassantFile;    // -1 ou 0..7
      @public Side      sideToMove;

   }

   // 'lastmove' est le dernier move réalisé, déclaré ici, mais défini dans 'PerformMove'
   @property (nonatomic, strong) Move *lastMove;
   
   /* 'currentEvaluation' détermine l'évaluation en cours, à partir de laquelle l'évaluation
    incrémentale démarre ; elle est utilisée dans 'PerformMove' */
   //@property int currentEvaluation;
   

   // Méthodes (d'instance)
   -(id)         init;
   -(void)       SetupPieces;
   -(Piece *)    piece_colX:(int)x rangY:(int)y;
   -(Piece *)    pieceAtPos:(Pos *)pos;
   -(Piece *)    MovePieceDeStart:(Pos *)start ADest:(Pos *)dest;
   -(void)       PerformMove:(Move *)move;
   -(id)         copyWithZone:(NSZone *)zone;
   -(NSString *) description;

   -(void)       PremCoupAIBlancs;
   -(PieceType)  SelectPromoPionForSide:(Side)side;
   -(void)       CalculerStrRoque;
   -(void)       DeterminerCibleEP:(Move *)move;
   -(void)       CompterDemiCoups:(Move *)move;
   -(void)       ProposerNulle50Coups;
   -(void)       AlertePartieNulle;

   -(Move *)buildMoveFrom:(Pos *)start
                       to:(Pos *)dest
                    board:(ChessBoard *)board;

   // Ajout des Méthodes IBAction liées à l'utilisation des menus et boutons
   // Modes de jeu
   -(IBAction)NewPartieJoueurBlancs:(id)sender;
   -(IBAction)NewPartieJoueurNoirs:(id)sender;
   -(IBAction)RetournerBoard:(id)sender;

   // Proposer un (bon) coup au Joueur
   -(IBAction)onHintButtonClicked:(id)sender;

   // Activer /Désactiver l'IA
   -(IBAction)PlayAutoOnOff:(id)sender;

   @property (weak) IBOutlet NSButton *buttonAuto;

@end
