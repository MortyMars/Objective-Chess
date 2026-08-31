// ChessView.h
// chess
// Initial code by Andrew Wang on 15/07/2013
// Refactoring by MortyMars in 2020


#import "Move.h"
#import "RuleBook.h"


@class ChessBoard, Pos;


@protocol ChessViewDelegate <NSObject>
   -(void)AlertMsgEchecSide:(Side)side;
@end


@interface ChessView : NSView
    
   // IVARS ET PROPERTIES ------------------------------------------------
   {
      // Déclaration des variables d'instance
      @public ChessBoard *liveBoard; // déclarée publique
      BOOL isThereTileSelected;
      Pos *selTile;
      NSSet *PosAcceptees;
   
      // iVar mémorisant les cases du 'Hint' à mettre en surbrillance
      Pos *hintStartSquare;   // Case de départ du hint
      Pos *hintDestSquare;    // Case d'arrivée du hint
      
      // iVars des cases d'un coup IA à 'surbriller'
      Pos *IaStartSquare;
      Pos *IaDestSquare;
   }

   @property (weak) id <ChessViewDelegate> delegate;

   @property BOOL uiFlipped;

   // Création de deux tableaux qui recevront les pièces capturées lors de la partie
   @property (nonatomic, strong) NSMutableArray<NSNumber *> *capturedByWhite; // pièces Noires capturées
   @property (nonatomic, strong) NSMutableArray<NSNumber *> *capturedByBlack; // pièces Blanches capturées

   
   // MÉTHODES -----------------------------------------------------------
   -(id)   initWithFrame:(NSRect)frame;

   // Méthodes de gestion de l'interface graphique
   -(void) drawBoard;
   -(void) drawRect:(NSRect)dirtyRect;
   -(void) mouseDown:(NSEvent *)theEvent;

   // Déclaration de méthodes de génération des coups
   -(void) MakeComputerMove;
   -(void) MakeJoueurMoveVersDest:(Pos *) dest;
   -(void) MakeIAMoveForSide:(Side)side Board:(ChessBoard *)board;

   // Méthodes gérant l'affichage des infos de partie
   -(void) MajStatusBarViaMove:(Move *)move
                     PrecBoard:(ChessBoard *)precBoard
                      StrCheck:(NSString *)strCheck;

   +(NSString *)VisualIndicator:(int)evalWhitePOV;

   // Méthodes de conversion pour retournement du board pour l'UI
   -(int)engineXFromUIX:(int)x;
   -(int)engineYFromUIY:(int)y ;

   // Méthodes gérant la surbrillance du 'Hint'
   -(void)highlightHintSquareStart:(Pos *)start dest:(Pos *)dest;
   -(void)clearHintHighlight;


@end

