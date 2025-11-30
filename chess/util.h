//
//  util.h
//  chess
//
//  Created by Andrew Wang on 7/15/13.
//  Copyright (c) 2013 Andrew Wang. All rights reserved.
//

#ifndef chess_util_h
#define chess_util_h

typedef enum {
    PieceTypeInvalid, PieceTypePawn, PieceTypeKnight, PieceTypeBishop, PieceTypeRook, PieceTypeQueen, PieceTypeKing
} PieceType;

typedef enum {
    SideInvalid, SideBlack, SideWhite
} Side;

#endif
