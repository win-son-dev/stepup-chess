import 'package:flutter/material.dart' hide Color;
import 'package:flutter/material.dart' as material;
import 'package:flutter_chess_board/flutter_chess_board.dart';

/// Callback when a piece attempts to capture a king.
typedef KingCaptureCallback = bool Function({
  required String from,
  required String to,
  required PieceType attackerType,
  required Color capturedKingColor,
});

/// Callback to check if a move can be afforded before executing it.
/// Returns true if the player has enough steps.
typedef CanAffordCallback = bool Function(PieceType pieceType);

/// Callback to charge steps after a move is made.
typedef ChargeMoveCallback = void Function(PieceType pieceType);

/// Callback to get the step cost for moving a piece type.
/// [capturingKing] is true when the target is an enemy king (double cost).
typedef GetCostCallback = int Function(PieceType pieceType, {bool capturingKing});

/// A chess board widget that removes turn enforcement and allows king captures.
class StepUpChessBoard extends StatefulWidget {
  final ChessBoardController controller;
  final double? size;
  final bool enableUserMoves;
  final BoardColor boardColor;
  final PlayerColor boardOrientation;
  final VoidCallback? onMove;
  final KingCaptureCallback? onKingCapture;
  final CanAffordCallback? canAfford;
  final ChargeMoveCallback? onChargeMove;
  final GetCostCallback? getCost;

  const StepUpChessBoard({
    super.key,
    required this.controller,
    this.size,
    this.enableUserMoves = true,
    this.boardColor = BoardColor.green,
    this.boardOrientation = PlayerColor.white,
    this.onMove,
    this.onKingCapture,
    this.canAfford,
    this.onChargeMove,
    this.getCost,
  });

  @override
  State<StepUpChessBoard> createState() => _StepUpChessBoardState();
}

const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

/// Asset path for a piece image.
String _pieceAssetPath(Color color, String pieceName) {
  final colorName = color == Color.WHITE ? 'White' : 'Black';
  return 'assets/chess_set/vector-chess-pieces/$colorName Wood/$pieceName $colorName Wood Outline 288px.png';
}

/// Map piece type character to display name used in asset filenames.
String _pieceTypeName(String typeChar) {
  switch (typeChar) {
    case 'P': return 'Pawn';
    case 'R': return 'Rook';
    case 'N': return 'Knight';
    case 'B': return 'Bishop';
    case 'Q': return 'Queen';
    case 'K': return 'King';
    default: return 'Pawn';
  }
}

class _StepUpChessBoardState extends State<StepUpChessBoard> {
  /// Set of squares the currently dragged piece can move to.
  Set<String> _legalMoveSquares = {};

  /// Step cost to display on legal move tiles during drag.
  int _moveCost = 0;

  /// Squares where moving would be a king capture (double cost).
  Set<String> _kingCaptureSquares = {};

  /// Build a FEN from the current position with [color] as the active side.
  /// Always clears en passant — StepUp Chess has no turn order, so en passant
  /// (which requires an immediate response) is never valid.
  static String _fenForColor(Chess game, Color color) {
    final parts = game.fen.split(' ');
    parts[1] = color == Color.WHITE ? 'w' : 'b';
    parts[3] = '-';
    return parts.join(' ');
  }

  /// Compute target squares for a piece on [from].
  /// Uses pseudo-legal moves (legal: false) so check doesn't restrict movement.
  /// Works on a copy to avoid mutating the live game.
  Set<String> _computeLegalMoves(Chess game, String from, Color pieceColor) {
    final testGame = Chess.fromFEN(_fenForColor(game, pieceColor));

    // legal: false → pseudo-legal moves, ignoring check constraints.
    // In StepUp Chess, check is just a warning — any piece can move.
    final moves = testGame.generate_moves({'legal': false});
    final targets = <String>{};
    for (final m in moves) {
      if (m.fromAlgebraic == from) {
        targets.add(m.toAlgebraic);
      }
    }

    // Also include enemy king squares (custom king-capture mechanic)
    for (final file in _files) {
      for (var rank = 1; rank <= 8; rank++) {
        final sq = '$file$rank';
        final piece = game.get(sq);
        if (piece != null &&
            piece.type == PieceType.KING &&
            piece.color != pieceColor) {
          if (_isValidKingCaptureMove(game, from, sq, pieceColor)) {
            targets.add(sq);
          }
        }
      }
    }

    return targets;
  }

  /// Check if a move from [from] to [to] is geometrically valid for king capture.
  /// Works on a COPY of the game.
  bool _isValidKingCaptureMove(
      Chess game, String from, String to, Color attackerColor) {
    final targetPiece = game.get(to);
    if (targetPiece == null) return false;

    // Replace king with a pawn so the engine allows capturing it
    final testGame = Chess.fromFEN(game.fen);
    testGame.remove(to);
    testGame.put(Piece(PieceType.PAWN, targetPiece.color), to);

    final testGame2 = Chess.fromFEN(_fenForColor(testGame, attackerColor));
    final moves = testGame2.generate_moves({'legal': false});
    return moves.any((m) => m.fromAlgebraic == from && m.toAlgebraic == to);
  }

  void _onDragStarted(Chess game, String from, Color pieceColor, PieceType pieceType) {
    final legalMoves = _computeLegalMoves(game, from, pieceColor);

    // Find which legal-move squares contain an enemy king
    final kingSquares = <String>{};
    for (final sq in legalMoves) {
      final piece = game.get(sq);
      if (piece != null &&
          piece.type == PieceType.KING &&
          piece.color != pieceColor) {
        kingSquares.add(sq);
      }
    }

    final cost = widget.getCost?.call(pieceType) ?? 0;

    setState(() {
      _legalMoveSquares = legalMoves;
      _moveCost = cost;
      _kingCaptureSquares = kingSquares;
    });
  }

  void _onDragEnd() {
    setState(() {
      _legalMoveSquares = {};
      _moveCost = 0;
      _kingCaptureSquares = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Chess>(
      valueListenable: widget.controller,
      builder: (context, game, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: _getBoardImage(widget.boardColor),
              ),
              AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final squareSize = constraints.maxWidth / 8;
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8),
                      itemBuilder: (context, index) {
                        var row = index ~/ 8;
                        var column = index % 8;
                        var boardRank =
                            widget.boardOrientation == PlayerColor.black
                                ? '${row + 1}'
                                : '${(7 - row) + 1}';
                        var boardFile =
                            widget.boardOrientation == PlayerColor.white
                                ? _files[column]
                                : _files[7 - column];

                        var squareName = '$boardFile$boardRank';
                        var pieceOnSquare = game.get(squareName);
                        final isLegalTarget =
                            _legalMoveSquares.contains(squareName);

                        var piece = _BoardPiece(
                          squareName: squareName,
                          game: game,
                        );

                        var draggable = pieceOnSquare != null
                            ? Draggable<_PieceMoveData>(
                                feedback: SizedBox(
                                  width: squareSize * 1.5,
                                  height: squareSize * 1.5,
                                  child: piece,
                                ),
                                childWhenDragging: const SizedBox(),
                                onDragStarted: () => _onDragStarted(
                                    game,
                                    squareName,
                                    pieceOnSquare.color,
                                    pieceOnSquare.type),
                                onDragEnd: (_) => _onDragEnd(),
                                onDraggableCanceled: (_, __) => _onDragEnd(),
                                data: _PieceMoveData(
                                  squareName: squareName,
                                  pieceType:
                                      pieceOnSquare.type.toUpperCase(),
                                  pieceColor: pieceOnSquare.color,
                                ),
                                child: piece,
                              )
                            : Container();

                        // Move indicator overlay with step cost
                        Widget child;
                        if (isLegalTarget) {
                          final isKingCapture =
                              _kingCaptureSquares.contains(squareName);
                          final displayCost =
                              isKingCapture ? _moveCost * 2 : _moveCost;

                          child = Stack(
                            children: [
                              dragTarget(game, squareName, draggable),
                              // Move indicator (dot or capture ring)
                              IgnorePointer(
                                child: Center(
                                  child: pieceOnSquare != null
                                      ? Container(
                                          width: squareSize,
                                          height: squareSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: material.Colors.black
                                                  .withValues(alpha: 0.3),
                                              width: squareSize * 0.08,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: squareSize * 0.3,
                                          height: squareSize * 0.3,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: material.Colors.black
                                                .withValues(alpha: 0.25),
                                          ),
                                        ),
                                ),
                              ),
                              // Step cost label in bottom-right corner
                              if (displayCost > 0)
                                Positioned(
                                  right: 1,
                                  bottom: 1,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: EdgeInsets.all(squareSize * 0.05),
                                      decoration: BoxDecoration(
                                        color: isKingCapture
                                            ? material.Colors.red.shade700
                                            : material.Colors.black87,
                                        borderRadius: BorderRadius.circular(
                                            squareSize * 0.1),
                                      ),
                                      child: Text(
                                        '$displayCost',
                                        style: TextStyle(
                                          color: material.Colors.white,
                                          fontSize: squareSize * 0.28,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        } else {
                          child = dragTarget(game, squareName, draggable);
                        }

                        return child;
                      },
                      itemCount: 64,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Image _getBoardImage(BoardColor color) {
    switch (color) {
      case BoardColor.brown:
        return Image.asset(
            "assets/chess_set/vector-chess-pieces/Board Brown 288px.png",
            fit: BoxFit.cover);
      case BoardColor.green:
        return Image.asset(
            "assets/chess_set/vector-chess-pieces/Board Green 288px.png",
            fit: BoxFit.cover);
      case BoardColor.darkBrown:
        return Image.asset("images/dark_brown_board.png",
            package: 'flutter_chess_board', fit: BoxFit.cover);
      case BoardColor.orange:
        return Image.asset("images/orange_board.png",
            package: 'flutter_chess_board', fit: BoxFit.cover);
    }
  }

  Widget dragTarget(Chess game, String squareName, Widget child) {
    return DragTarget<_PieceMoveData>(
      builder: (context, list, _) => child,
      onWillAcceptWithDetails: (details) => widget.enableUserMoves,
      onAcceptWithDetails: (details) async {
        final pieceMoveData = details.data;
        final targetPiece = game.get(squareName);
        final movingPieceType = _toPieceType(pieceMoveData.pieceType);

        // Check if target square has a king (king capture!)
        if (targetPiece != null &&
            targetPiece.type == PieceType.KING &&
            targetPiece.color != pieceMoveData.pieceColor) {
          if (!_isValidKingCaptureMove(
              game,
              pieceMoveData.squareName,
              squareName,
              pieceMoveData.pieceColor)) {
            return;
          }
          widget.onKingCapture?.call(
            from: pieceMoveData.squareName,
            to: squareName,
            attackerType: movingPieceType,
            capturedKingColor: targetPiece.color,
          );
          return;
        }

        // Check affordability BEFORE making the move
        if (widget.canAfford != null &&
            !widget.canAfford!(movingPieceType)) {
          return;
        }

        // Set active color to the moving piece's color so the engine accepts it
        final readyFen = _fenForColor(game, pieceMoveData.pieceColor);
        widget.controller.loadFen(readyFen);
        final fenBefore = game.fen;

        final isPromotion = pieceMoveData.pieceType == "P" &&
            ((pieceMoveData.squareName[1] == "7" &&
                    squareName[1] == "8" &&
                    pieceMoveData.pieceColor == Color.WHITE) ||
                (pieceMoveData.squareName[1] == "2" &&
                    squareName[1] == "1" &&
                    pieceMoveData.pieceColor == Color.BLACK));

        String? promotionPiece;
        if (isPromotion) {
          promotionPiece = await _promotionDialog(context, pieceMoveData.pieceColor);
          if (promotionPiece == null) {
            widget.controller.loadFen(fenBefore);
            return;
          }
        }

        // Try the engine move first
        if (isPromotion) {
          widget.controller.makeMoveWithPromotion(
            from: pieceMoveData.squareName,
            to: squareName,
            pieceToPromoteTo: promotionPiece!,
          );
        } else {
          widget.controller.makeMove(
            from: pieceMoveData.squareName,
            to: squareName,
          );
        }

        // If the engine rejected the move, check if it's a valid piece
        // movement that was only blocked due to check. In StepUp Chess,
        // check is just a warning — not a forced constraint.
        if (game.fen == fenBefore) {
          final testGame = Chess.fromFEN(readyFen);
          final pseudoMoves = testGame.generate_moves({'legal': false});
          final isPseudoLegal = pseudoMoves.any((m) =>
              m.fromAlgebraic == pieceMoveData.squareName &&
              m.toAlgebraic == squareName);
          if (isPseudoLegal) {
            _manualMove(
              game,
              pieceMoveData.squareName,
              squareName,
              pieceMoveData.pieceColor,
              promotionPiece: promotionPiece,
            );
          }
        }

        if (game.fen != fenBefore) {
          widget.onChargeMove?.call(movingPieceType);
          widget.onMove?.call();
        }
      },
    );
  }

  /// Manually move a piece when the engine rejects the move (e.g. due to check).
  /// Directly manipulates the board position and reloads the FEN.
  void _manualMove(
    Chess game,
    String from,
    String to,
    Color pieceColor, {
    String? promotionPiece,
  }) {
    final piece = game.get(from);
    if (piece == null) return;

    game.remove(from);
    game.remove(to);

    if (promotionPiece != null) {
      // Place promoted piece instead of the pawn
      final promotedType = _toPieceType(promotionPiece.toUpperCase());
      game.put(Piece(promotedType, pieceColor), to);
    } else {
      game.put(piece, to);
    }

    widget.controller.loadFen(game.fen);
  }

  PieceType _toPieceType(String s) {
    switch (s.toUpperCase()) {
      case 'P': return PieceType.PAWN;
      case 'N': return PieceType.KNIGHT;
      case 'B': return PieceType.BISHOP;
      case 'R': return PieceType.ROOK;
      case 'Q': return PieceType.QUEEN;
      case 'K': return PieceType.KING;
      default: return PieceType.PAWN;
    }
  }

  Future<String?> _promotionDialog(
      BuildContext context, Color pieceColor) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _promotionOption(context, pieceColor, 'Queen', 'q'),
              _promotionOption(context, pieceColor, 'Rook', 'r'),
              _promotionOption(context, pieceColor, 'Bishop', 'b'),
              _promotionOption(context, pieceColor, 'Knight', 'n'),
            ],
          ),
        );
      },
    );
  }

  Widget _promotionOption(
      BuildContext context, Color pieceColor, String pieceName, String value) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(
          _pieceAssetPath(pieceColor, pieceName),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _BoardPiece extends StatelessWidget {
  final String squareName;
  final Chess game;

  const _BoardPiece({required this.squareName, required this.game});

  @override
  Widget build(BuildContext context) {
    var square = game.get(squareName);
    if (square == null) return Container();

    final pieceName = _pieceTypeName(square.type.toUpperCase());
    return Image.asset(
      _pieceAssetPath(square.color, pieceName),
      fit: BoxFit.contain,
    );
  }
}

class _PieceMoveData {
  final String squareName;
  final String pieceType;
  final Color pieceColor;

  _PieceMoveData({
    required this.squareName,
    required this.pieceType,
    required this.pieceColor,
  });
}
