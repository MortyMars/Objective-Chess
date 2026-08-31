// Move.m
// chess
// Initial code by Andrew Wang on 15/07/2013,
// Refactoring by MortyMars early 2026


#import "Move.h"
#import "Pos.h"
#import "ChessConfig.h"


@implementation Move

   // ==================================================================================================
   // Méthode d'instance retournant un Move sur la base d'une position de départ et d'une position de
   // destination
   - (id)initWithStart:(Pos *)start Dest:(Pos *)dest
   {
      self = [super init];
      if (self) {
         
         _start = start;
         _dest  = dest;

         _fromSquare = start.y * 8 + start.x;
         _toSquare   = dest.y  * 8 + dest.x;
         
         _promotionType = Dame;  // ✨ Promotion en Dame par défaut
         
         _movingPiece   = nil;
         _capturedPiece = nil;
         
         _isCapture     = NO;
         _isPromotion   = NO;
         _wasPromotion  = NO;
         _isCastling    = NO;
         _givesCheck    = NO;
         _isEnPassant   = NO;
         
         _oldType       = 0;
         _orderingScore = 0;
      }
      return self;
   }


   // ==================================================================================================
   // Implémentation Méthode de confort, plus lisible
   +(Move *)newMoveFromX:(int)x Y:(int)y ToNx:(int)nx Ny:(int)ny
   {
       Pos *s = [Pos posWithX:x y:y];
       Pos *d = [Pos posWithX:nx y:ny];

       return [[Move alloc] initWithStart:s Dest:d];
   }


   // ==================================================================================================
   // Méthode exigée par le Protocol NSCopying dont hérite la classe Move
   // Elle n'est pas formellement appelée dans le code, mais s'active dès l'envoi d'un msg copy sur un objet
   -(id)copyWithZone:(NSZone *)zone
   {
       Move *m = [[[self class] allocWithZone:zone] initWithStart:self.start Dest:self.dest];

       m.movingPiece   = self.movingPiece;
       m.capturedPiece = self.capturedPiece;
       m.isCapture     = self.isCapture;
       m.isCastling    = self.isCastling;
       m.isPromotion   = self.isPromotion;
       m.oldType       = self.oldType;
       m.promotionType = self.promotionType;  // ✨ NOUVEAU
       m.isEnPassant   = self.isEnPassant;
       m.orderingScore = self.orderingScore;

       return m;
   }


   // ==================================================================================================
   // 'description' est une @property de NSObbject, dont l'appel est implicite
   // Elle est surdéfinie ici pour nos besoins d'affichage dans la console
   // et c'est à partir de cette base, que l'on traduira les moves en 'a1-b2'
   -(NSString *)description
   {
      // la 'description' de Move est définie en tant que NSString au format 'Pos>Pos', par exemple : 'e2>e4'
      return [NSString stringWithFormat:@"%@>%@",self.start,self.dest];
   }


   // ==================================================================================================
   // Méthode permettant de déterminer le move opposé par rapport au centre du Board, nécessaire pour
   // afficher un move dans la liste des coups et dans le 'hint', lorsque le plateau est retourné
   +(Move *)opMove:(Move *) move {
      
      int opXs = 7 - move.start.x;
      int opYs = 7 - move.start.y;
      int opXd = 7 - move.dest.x;
      int opYd = 7 - move.dest.y;
      
      Move * opMove = [Move newMoveFromX:opXs Y:opYs ToNx:opXd Ny:opYd];
      
      return opMove;
   }


@end
