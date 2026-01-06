//
//  BoardsForTests.h
//  ChessTests
//
//  Created by MCN on 22/04/2022.
//  Copyright © 2022 MCN. All rights reserved.
//

#import "ChessTests.h"


@interface BoardsForTests : NSObject

   +(ChessBoard *)ConfigBoardCoupDuBerger;

   +(ChessBoard *)ConfigBoardMatEn3Cas1;

   +(ChessBoard *)ConfigBoardMatEn3Cas2;

   +(ChessBoard *)ConfigBoardMatEn3Cas3;

   +(ChessBoard *)ConfigBoardMatEn3Cas4;

   +(ChessBoard *)ConfigBoardMatEn3Fort;

   +(ChessBoard *)ConfigBoardMatEn7Demi;

   +(ChessBoard *)ConfigBoardMatEn3Zugzwang;

   +(ChessBoard *)ConfigBoardMatEn3Hard;


@end
