import 'package:flutter/material.dart' hide Color;
import 'package:flutter/material.dart' as material;
import 'package:flutter_chess_board/flutter_chess_board.dart' hide BoardPiece;
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/engine/stepup_engine.dart';
import 'package:stepup_chess/models/game.dart';

/// Callback when a piece attempts to capture a king.
typedef KingCaptureCallback = bool Function({
  required String from,
  required String to,
  required PieceKind attackerKind,
  required PieceColor capturedKingColor,
});

/// Callback to check if a move can be afforded before executing it.
typedef CanAffordCallback = bool Function(
    PieceKind piece, String from, String to);

/// Callback to charge steps after a move is made.
typedef ChargeMoveCallback = void Function(
    PieceKind piece, String from, String to);

/// Callback to get the step cost for a specific move.
typedef GetCostCallback = int Function(
    PieceKind piece, String from, String to, {bool capturingKing});

/// A chess board widget that supports both drag-and-drop and tap-to-move.
class StepUpChessBoard extends StatefulWidget {
  final StepUpEngine engine;
  final ChessBoardController controller;
  final double? size;
  final bool enableUserMoves;
  final BoardColor boardColor;
  final PlayerColor boardOrientation;
  final LastMove? lastMove;
  final VoidCallback? onMove;
  final KingCaptureCallback? onKingCapture;
  final CanAffordCallback? canAfford;
  final ChargeMoveCallback? onChargeMove;
  final GetCostCallback? getCost;

  const StepUpChessBoard({
    super.key,
    required this.engine,
    required this.controller,
    this.size,
    this.enableUserMoves = true,
    this.boardColor = BoardColor.green,
    this.boardOrientation = PlayerColor.white,
    this.lastMove,
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
String _pieceAssetPath(PieceColor color, String pieceName) {
  final colorName = color == PieceColor.white ? 'White' : 'Black';
  return 'assets/chess_set/vector-chess-pieces/$colorName Wood/$pieceName $colorName Wood Outline 288px.png';
}

/// Map PieceKind to display name used in asset filenames.
String _pieceKindName(PieceKind kind) {
  switch (kind) {
    case PieceKind.pawn:
      return 'Pawn';
    case PieceKind.rook:
      return 'Rook';
    case PieceKind.knight:
      return 'Knight';
    case PieceKind.bishop:
      return 'Bishop';
    case PieceKind.queen:
      return 'Queen';
    case PieceKind.king:
      return 'King';
  }
}

/// Convert a chess package piece to our BoardPiece.
BoardPiece? _toBoardPiece(Piece? p) {
  if (p == null) return null;
  PieceKind kind;
  if (p.type == PieceType.PAWN) {
    kind = PieceKind.pawn;
  } else if (p.type == PieceType.KNIGHT) {
    kind = PieceKind.knight;
  } else if (p.type == PieceType.BISHOP) {
    kind = PieceKind.bishop;
  } else if (p.type == PieceType.ROOK) {
    kind = PieceKind.rook;
  } else if (p.type == PieceType.QUEEN) {
    kind = PieceKind.queen;
  } else {
    kind = PieceKind.king;
  }
  final color =
      p.color == Color.WHITE ? PieceColor.white : PieceColor.black;
  return BoardPiece(kind, color);
}

class _StepUpChessBoardState extends State<StepUpChessBoard> {
  /// Set of squares the selected/dragged piece can move to.
  Set<String> _legalMoveSquares = {};

  /// The square of the selected/dragged piece.
  String? _selectedFrom;

  /// The piece that is selected/dragged.
  BoardPiece? _selectedPiece;

  /// Squares where moving would be a king capture.
  Set<String> _kingCaptureSquares = {};

  void _selectPiece(String from, BoardPiece piece) {
    final legalMoves = widget.engine.legalTargets(from);

    // Find which legal-move squares contain an enemy king
    final kingSquares = <String>{};
    for (final sq in legalMoves) {
      final p = widget.engine.pieceAt(sq);
      if (p != null && p.kind == PieceKind.king && p.color != piece.color) {
        kingSquares.add(sq);
      }
    }

    setState(() {
      _legalMoveSquares = legalMoves;
      _selectedFrom = from;
      _selectedPiece = piece;
      _kingCaptureSquares = kingSquares;
    });
  }

  void _clearSelection() {
    setState(() {
      _legalMoveSquares = {};
      _selectedFrom = null;
      _selectedPiece = null;
      _kingCaptureSquares = {};
    });
  }

  /// Handle tapping a square — either select a piece or move to a target.
  void _onSquareTap(String squareName) {
    if (!widget.enableUserMoves) return;

    final tappedPiece = widget.engine.pieceAt(squareName);

    // If a piece is already selected...
    if (_selectedFrom != null && _selectedPiece != null) {
      // Tapping the same piece → deselect
      if (squareName == _selectedFrom) {
        _clearSelection();
        return;
      }

      // Tapping a legal target → execute the move
      if (_legalMoveSquares.contains(squareName)) {
        _executeMove(_selectedFrom!, _selectedPiece!, squareName);
        _clearSelection();
        return;
      }

      // Tapping a different friendly piece → select that piece instead
      if (tappedPiece != null && tappedPiece.color == _selectedPiece!.color) {
        _selectPiece(squareName, tappedPiece);
        return;
      }

      // Tapping elsewhere → deselect
      _clearSelection();
      return;
    }

    // No piece selected — tap a piece to select it
    if (tappedPiece != null) {
      _selectPiece(squareName, tappedPiece);
    }
  }

  /// Execute a move from [from] to [targetSquare] — shared by tap and drag.
  Future<void> _executeMove(
      String from, BoardPiece piece, String targetSquare) async {
    // Validate legality — prevents illegal king captures via drag path
    final legal = widget.engine.legalTargets(from);
    if (!legal.contains(targetSquare)) return;

    final targetPiece = widget.engine.pieceAt(targetSquare);

    // King capture
    if (targetPiece != null &&
        targetPiece.kind == PieceKind.king &&
        targetPiece.color != piece.color) {
      _clearSelection();
      widget.onKingCapture?.call(
        from: from,
        to: targetSquare,
        attackerKind: piece.kind,
        capturedKingColor: targetPiece.color,
      );
      return;
    }

    // Check affordability
    if (widget.canAfford != null &&
        !widget.canAfford!(piece.kind, from, targetSquare)) {
      return;
    }

    // Detect promotion
    String? promotionPiece;
    if (widget.engine.isPromotion(from, targetSquare)) {
      final chessPieceColor =
          piece.color == PieceColor.white ? Color.WHITE : Color.BLACK;
      promotionPiece = await _promotionDialog(context, chessPieceColor);
      if (promotionPiece == null) return;
    }

    // Execute the move through the engine
    final moved =
        widget.engine.makeMove(from, targetSquare, promotion: promotionPiece);

    if (moved) {
      _clearSelection();
      widget.onChargeMove?.call(piece.kind, from, targetSquare);
      widget.onMove?.call();
    }
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
                        var boardPiece = _toBoardPiece(game.get(squareName));
                        final isLegalTarget =
                            _legalMoveSquares.contains(squareName);
                        final isSelected = squareName == _selectedFrom;

                        // Check highlight: find the checked king's square
                        final checkedSide = widget.engine.checkedSide();
                        bool isCheckedKing = false;
                        if (checkedSide != null && boardPiece != null &&
                            boardPiece.kind == PieceKind.king &&
                            boardPiece.color == checkedSide) {
                          isCheckedKing = true;
                        }

                        var pieceWidget = _BoardPiece(
                          squareName: squareName,
                          piece: boardPiece,
                        );

                        var draggable = boardPiece != null
                            ? Draggable<_PieceMoveData>(
                                feedback: SizedBox(
                                  width: squareSize * 1.5,
                                  height: squareSize * 1.5,
                                  child: pieceWidget,
                                ),
                                childWhenDragging: const SizedBox(),
                                onDragStarted: () =>
                                    _selectPiece(squareName, boardPiece),
                                onDragEnd: (_) => _clearSelection(),
                                onDraggableCanceled: (_, _) =>
                                    _clearSelection(),
                                data: _PieceMoveData(
                                  squareName: squareName,
                                  pieceKind: boardPiece.kind,
                                  pieceColor: boardPiece.color,
                                ),
                                child: pieceWidget,
                              )
                            : Container();

                        // Build the square content
                        Widget squareContent;

                        final isLastMove = widget.lastMove != null &&
                            (squareName == widget.lastMove!.from ||
                                squareName == widget.lastMove!.to);

                        if (isLegalTarget) {
                          final isKingCapture =
                              _kingCaptureSquares.contains(squareName);

                          // Calculate cost for this specific target
                          int displayCost = 0;
                          if (_selectedFrom != null &&
                              _selectedPiece != null) {
                            displayCost = widget.getCost?.call(
                                    _selectedPiece!.kind,
                                    _selectedFrom!,
                                    squareName,
                                    capturingKing: isKingCapture) ??
                                0;
                          }

                          squareContent = Stack(
                            children: [
                              _tappableSquare(
                                squareName: squareName,
                                child: dragTarget(squareName, draggable),
                              ),
                              // Move indicator (dot or capture ring)
                              IgnorePointer(
                                child: Center(
                                  child: boardPiece != null
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
                                      padding:
                                          EdgeInsets.all(squareSize * 0.05),
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
                        } else if (isSelected) {
                          // Highlight the selected piece's square
                          squareContent = Stack(
                            children: [
                              _tappableSquare(
                                squareName: squareName,
                                child: dragTarget(squareName, draggable),
                              ),
                              IgnorePointer(
                                child: Container(
                                  color: material.Colors.yellow
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          );
                        } else if (isCheckedKing) {
                          squareContent = Stack(
                            children: [
                              _tappableSquare(
                                squareName: squareName,
                                child: dragTarget(squareName, draggable),
                              ),
                              IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        material.Colors.red.withValues(alpha: 0.85),
                                        material.Colors.red.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.3, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else if (isLastMove) {
                          squareContent = Stack(
                            children: [
                              _tappableSquare(
                                squareName: squareName,
                                child: dragTarget(squareName, draggable),
                              ),
                              IgnorePointer(
                                child: Container(
                                  color: material.Colors.amber
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          );
                        } else {
                          squareContent = _tappableSquare(
                            squareName: squareName,
                            child: dragTarget(squareName, draggable),
                          );
                        }

                        return squareContent;
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

  /// Wraps a square's child in a GestureDetector for tap-to-move.
  Widget _tappableSquare({
    required String squareName,
    required Widget child,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _onSquareTap(squareName),
      child: child,
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

  Widget dragTarget(String squareName, Widget child) {
    return DragTarget<_PieceMoveData>(
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return Stack(
          children: [
            child,
            if (isHovered)
              IgnorePointer(
                child: Container(
                  color: material.Colors.black.withValues(alpha: 0.35),
                ),
              ),
          ],
        );
      },
      onWillAcceptWithDetails: (details) => widget.enableUserMoves,
      onAcceptWithDetails: (details) async {
        final moveData = details.data;
        final piece = BoardPiece(moveData.pieceKind, moveData.pieceColor);
        await _executeMove(moveData.squareName, piece, squareName);
      },
    );
  }

  Future<String?> _promotionDialog(
      BuildContext context, Color pieceColor) async {
    final color =
        pieceColor == Color.WHITE ? PieceColor.white : PieceColor.black;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _promotionOption(context, color, 'Queen', 'q'),
              _promotionOption(context, color, 'Rook', 'r'),
              _promotionOption(context, color, 'Bishop', 'b'),
              _promotionOption(context, color, 'Knight', 'n'),
            ],
          ),
        );
      },
    );
  }

  Widget _promotionOption(
      BuildContext context, PieceColor color, String pieceName, String value) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(
          _pieceAssetPath(color, pieceName),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _BoardPiece extends StatelessWidget {
  final String squareName;
  final BoardPiece? piece;

  const _BoardPiece({required this.squareName, required this.piece});

  @override
  Widget build(BuildContext context) {
    if (piece == null) return Container();

    final pieceName = _pieceKindName(piece!.kind);
    return Image.asset(
      _pieceAssetPath(piece!.color, pieceName),
      fit: BoxFit.contain,
    );
  }
}

class _PieceMoveData {
  final String squareName;
  final PieceKind pieceKind;
  final PieceColor pieceColor;

  _PieceMoveData({
    required this.squareName,
    required this.pieceKind,
    required this.pieceColor,
  });
}
