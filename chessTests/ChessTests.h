//  ChessTests.h
//  ChessTests
//  Created by MCN on 22/04/2022.
//  Copyright © 2022 MCN - All rights reserved.

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "Minimax.h"
#import "ChessBoard.h"
#import "ChessView.h"
#import "Move.h"
#import "Pos.h"
#import "RuleBook.h"
#import "MoveToStr.h"
#import "Piece.h"
#import "Util.h"


@interface ChessTests : XCTestCase

   //+(void) initBoardStd;

   -(void)testNegamaxFS;
   -(void)testCoupDuBerger;
   -(void)test1MatEn20CoupsMax;
   -(void)test2MatEn20CoupsMax;
   -(void)testPerformanceBestMoveFS;
   -(void)testPerformancePossibleMoveFS;
   -(void)testPerformancePerformMove;
   -(void)testPerformanceEvalBoardFS;
   -(void)testPerformanceNegamaxFS ;
   -(void)testFonctEvaluation;



@end
