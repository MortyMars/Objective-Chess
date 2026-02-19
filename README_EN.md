Objective-Chess - Objective-C Chess Implementation (Negamax Alpha Beta)
-----------------------------------------------------------------------

This fork is a reworking of an attractive chess implementation, notable for being one of the few written for macOS in Objective-C, a language that remains undeniably elegant, although now somewhat outdated.

Added Features
--------------
The development of this version of the game consisted of adding various features.

Structural:
- It is possible to play with White or Black.
- A continuous sequence of moves, following the 'Reversible Algebraic Notation' naming convention, is displayed.
- Situations involving check, mate, and stalemate are detected and indicated by dialog boxes.
- The AI engine has been modified to conform to the most commonly used Negamax Alpha Beta pseudocodes, making it more efficient.
- Pawn promotion upon reaching its last rank is supported.
- The possibility of en passant capture for the pawn is implemented.
- The evaluation function now takes into account potential check and mate positions, as well as pawns threatening promotion.
- A situation diagram of a chessboard can be loaded and viewed in the interface via its description in FEN format.
- It is possible to change sides at any time during a game.
- The AI's playing level can be modified throughout the game. Game:
- The rule requiring a draw after 50 moves without a capture or pawn movement is implemented.
- It is possible to ask the AI to solve game situation diagrams.

Visual:
- The piece designs have been modified for a more aesthetically pleasing result.
- The chessboard colors have been modified for the same purpose.
- Square markers have been implemented, facilitating the reading and visualization of moves.
- The situation on the chessboard is evaluated throughout the game to highlight an emerging advantage for one side or the other.
- The application features a set of icons.
- The menus are customized and enhanced.
- A 'status bar' displays the board evaluation, the move, the castling status, the target status, etc. and counters, makes its appearance

Release Notes (02/2026)
------------------------------
- v0.9.0-beta: Initial version of the fork relaunch, functional but affected by some bugs
- v1.0.0-beta: First truly functional version, with the caveat that the program plays only within the rules and rather poorly
- v1.0.1-beta: Code cleaned up, methods renamed, some restructured, for better readability
- v1.0.2-beta: Promotion of a pawn reaching its last rank is implemented, the move notation is updated accordingly
- v1.0.3-beta: En passant capture is now supported, with updated move notation
- v1.0.4-beta: Implementation of unit tests, fix of a bug in determining the AI's best move, improvement of the evaluation function
- v1.0.5-beta : The evaluation takes into account a pawn reaching the penultimate rank; Negamax has been updated
- v1.0.8-beta: Ability to load a diagram in FEN format - Ability to modify the AI's skill level at any time - Added menus and created a 'status bar'
- v1.0.9-beta: Ability to ask the AI to solve a game situation diagram
- v1.1.0-beta: Refactoring of the game engine (Minimax, ChessBoard, RuleBook) for better performance - Added positional criteria to the evaluation function
- v1.1.0: Involutive makeMove/unmakeMove functionality achieved - Zobrist hashing implemented - Transposition tables implemented = These changes contribute to a very significant improvement in the engine's performance

What remains to be done (my TODO list)
-----------------------------------
- Fix some minor bugs or loss of secondary features that appeared during the deep engine refactoring
- Improve the game quality of AI regarding the most immediate moves and certain unnecessary sacrifices
- Implement the ability to record the progress of a game, board by board
- Offer the player the possibility of being suggested a good next move