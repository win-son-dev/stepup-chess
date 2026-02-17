import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

/// Callback when a piece attempts to capture a king.
/// [from] source square, [to] king's square,
/// [attackerType] the piece type making the capture,
/// [capturedKingColor] the color of the king being captured.
/// Returns true if the capture was allowed (had enough steps).
typedef KingCaptureCallback = bool Function({
  required String from,
  required String to,
  required PieceType attackerType,
  required Color capturedKingColor,
});

/// A chess board widget that removes turn enforcement and allows king captures.
class StepUpChessBoard extends StatefulWidget {
  final ChessBoardController controller;
  final double? size;
  final bool enableUserMoves;
  final BoardColor boardColor;
  final PlayerColor boardOrientation;
  final VoidCallback? onMove;
  final KingCaptureCallback? onKingCapture;

  const StepUpChessBoard({
    super.key,
    required this.controller,
    this.size,
    this.enableUserMoves = true,
    this.boardColor = BoardColor.brown,
    this.boardOrientation = PlayerColor.white,
    this.onMove,
    this.onKingCapture,
  });

  @override
  State<StepUpChessBoard> createState() => _StepUpChessBoardState();
}

const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

class _StepUpChessBoardState extends State<StepUpChessBoard> {
  /// Swap the active turn in the FEN to match the piece color.
  void _alignTurn(Chess game, Color pieceColor) {
    if (game.turn != pieceColor) {
      final fen = game.fen;
      final parts = fen.split(' ');
      parts[1] = pieceColor == Color.WHITE ? 'w' : 'b';
      game.load(parts.join(' '));
    }
  }

  /// Check if a move from [from] to [to] is geometrically valid for [pieceType].
  /// We do this by temporarily removing the target king, aligning turns,
  /// and checking if the chess engine considers it a legal move.
  bool _isValidKingCaptureMove(
      Chess game, String from, String to, Color attackerColor) {
    // Save current state
    final savedFen = game.fen;

    // Remove the king at target square and align turn
    final targetPiece = game.get(to);
    if (targetPiece == null) return false;

    // Put a pawn of the same color as the king to replace it temporarily
    // (so we can test if the attacker can legally move there)
    game.remove(to);
    game.put(Piece(PieceType.PAWN, targetPiece.color), to);

    // Align turn
    final parts = game.fen.split(' ');
    parts[1] = attackerColor == Color.WHITE ? 'w' : 'b';
    game.load(parts.join(' '));

    // Check if the move is in legal moves
    final moves = game.moves({'asObjects': true}) as List<Move>;
    final isValid = moves.any((m) => m.fromAlgebraic == from && m.toAlgebraic == to);

    // Restore original state
    game.load(savedFen);
    return isValid;
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
                child: GridView.builder(
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

                    var piece = _BoardPiece(
                      squareName: squareName,
                      game: game,
                    );

                    var draggable = pieceOnSquare != null
                        ? Draggable<_PieceMoveData>(
                            feedback: piece,
                            childWhenDragging: const SizedBox(),
                            data: _PieceMoveData(
                              squareName: squareName,
                              pieceType: pieceOnSquare.type.toUpperCase(),
                              pieceColor: pieceOnSquare.color,
                            ),
                            child: piece,
                          )
                        : Container();

                    var dragTarget = DragTarget<_PieceMoveData>(
                      builder: (context, list, _) => draggable,
                      onWillAcceptWithDetails: (details) =>
                          widget.enableUserMoves,
                      onAcceptWithDetails: (details) async {
                        final pieceMoveData = details.data;
                        final targetPiece = game.get(squareName);

                        // Check if target square has a king (king capture!)
                        if (targetPiece != null &&
                            targetPiece.type == PieceType.KING &&
                            targetPiece.color != pieceMoveData.pieceColor) {
                          // Validate the move is geometrically legal
                          if (!_isValidKingCaptureMove(game,
                              pieceMoveData.squareName, squareName,
                              pieceMoveData.pieceColor)) {
                            return;
                          }
                          // Delegate to king capture handler
                          widget.onKingCapture?.call(
                            from: pieceMoveData.squareName,
                            to: squareName,
                            attackerType: _toPieceType(pieceMoveData.pieceType),
                            capturedKingColor: targetPiece.color,
                          );
                          return;
                        }

                        // Normal move — align turn so any color can move
                        _alignTurn(game, pieceMoveData.pieceColor);
                        final fenBefore = game.fen;

                        if (pieceMoveData.pieceType == "P" &&
                            ((pieceMoveData.squareName[1] == "7" &&
                                    squareName[1] == "8" &&
                                    pieceMoveData.pieceColor ==
                                        Color.WHITE) ||
                                (pieceMoveData.squareName[1] == "2" &&
                                    squareName[1] == "1" &&
                                    pieceMoveData.pieceColor ==
                                        Color.BLACK))) {
                          var val = await _promotionDialog(context);
                          if (val != null) {
                            widget.controller.makeMoveWithPromotion(
                              from: pieceMoveData.squareName,
                              to: squareName,
                              pieceToPromoteTo: val,
                            );
                          } else {
                            return;
                          }
                        } else {
                          widget.controller.makeMove(
                            from: pieceMoveData.squareName,
                            to: squareName,
                          );
                        }

                        if (game.fen != fenBefore) {
                          widget.onMove?.call();
                        }
                      },
                    );

                    return dragTarget;
                  },
                  itemCount: 64,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Image _getBoardImage(BoardColor color) {
    switch (color) {
      case BoardColor.brown:
        return Image.asset("images/brown_board.png",
            package: 'flutter_chess_board', fit: BoxFit.cover);
      case BoardColor.darkBrown:
        return Image.asset("images/dark_brown_board.png",
            package: 'flutter_chess_board', fit: BoxFit.cover);
      case BoardColor.green:
        return Image.asset("images/green_board.png",
            package: 'flutter_chess_board', fit: BoxFit.cover);
      case BoardColor.orange:
        return Image.asset("images/orange_board.png",
            package: 'flutter_chess_board', fit: BoxFit.cover);
    }
  }

  Future<String?> _promotionDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: WhiteQueen(),
                onTap: () => Navigator.of(context).pop("q"),
              ),
              InkWell(
                child: WhiteRook(),
                onTap: () => Navigator.of(context).pop("r"),
              ),
              InkWell(
                child: WhiteBishop(),
                onTap: () => Navigator.of(context).pop("b"),
              ),
              InkWell(
                child: WhiteKnight(),
                onTap: () => Navigator.of(context).pop("n"),
              ),
            ],
          ),
        );
      },
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

    String piece =
        (square.color == Color.WHITE ? 'W' : 'B') + square.type.toUpperCase();

    switch (piece) {
      case "WP": return WhitePawn();
      case "WR": return WhiteRook();
      case "WN": return WhiteKnight();
      case "WB": return WhiteBishop();
      case "WQ": return WhiteQueen();
      case "WK": return WhiteKing();
      case "BP": return BlackPawn();
      case "BR": return BlackRook();
      case "BN": return BlackKnight();
      case "BB": return BlackBishop();
      case "BQ": return BlackQueen();
      case "BK": return BlackKing();
      default: return WhitePawn();
    }
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
