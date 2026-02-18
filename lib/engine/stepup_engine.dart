import 'package:chess/chess.dart' as chess;
import 'package:flutter_chess_board/flutter_chess_board.dart' hide BoardPiece;
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/engine/cost_calculator.dart';

const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

/// Central chess engine for StepUp Chess.
///
/// Wraps the `chess` engine and `ChessBoardController`, exposing a clean API
/// that hides all FEN manipulation, pseudo-legal move generation, king-capture
/// geometry, and manual-move fallbacks.
class StepUpEngine {
  ChessBoardController? _controller;
  CostCalculator costCalculator;

  StepUpEngine(this.costCalculator);

  // ---------------------------------------------------------------------------
  // Controller binding
  // ---------------------------------------------------------------------------

  void attachController(ChessBoardController controller) {
    _controller = controller;
  }

  ChessBoardController get controller => _controller!;
  chess.Chess get _game => _controller!.game;

  // ---------------------------------------------------------------------------
  // Cost calculator
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Board state
  // ---------------------------------------------------------------------------

  String get fen => _game.fen;

  BoardPiece? pieceAt(String square) {
    final p = _game.get(square);
    if (p == null) return null;
    return BoardPiece(_fromChessPieceType(p.type), _fromChessColor(p.color));
  }

  // ---------------------------------------------------------------------------
  // Move generation (pseudo-legal, no check enforcement)
  // ---------------------------------------------------------------------------

  /// Returns the set of squares that a piece on [from] can move to,
  /// including enemy king squares (custom king-capture mechanic).
  Set<String> legalTargets(String from) {
    final piece = _game.get(from);
    if (piece == null) return {};

    final pieceColor = piece.color;
    final testGame = chess.Chess.fromFEN(_fenForColor(_game, pieceColor));
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
        final p = _game.get(sq);
        if (p != null &&
            p.type == chess.PieceType.KING &&
            p.color != pieceColor) {
          if (_isValidKingCaptureMove(from, sq, pieceColor)) {
            targets.add(sq);
          }
        }
      }
    }

    return targets;
  }

  // ---------------------------------------------------------------------------
  // Move execution
  // ---------------------------------------------------------------------------

  /// Try to make a move. Returns true if the board position changed.
  ///
  /// Tries the engine first; if rejected (e.g. due to check), falls back to
  /// manual piece manipulation for pseudo-legal moves.
  bool makeMove(String from, String to, {String? promotion}) {
    final piece = _game.get(from);
    if (piece == null) return false;

    final readyFen = _fenForColor(_game, piece.color);
    _controller!.loadFen(readyFen);
    final fenBefore = _game.fen;

    if (promotion != null) {
      _controller!.makeMoveWithPromotion(
        from: from,
        to: to,
        pieceToPromoteTo: promotion,
      );
    } else {
      _controller!.makeMove(from: from, to: to);
    }

    // If the engine rejected the move, try manual fallback
    if (_game.fen == fenBefore) {
      final testGame = chess.Chess.fromFEN(readyFen);
      final pseudoMoves = testGame.generate_moves({'legal': false});
      final isPseudoLegal = pseudoMoves.any(
          (m) => m.fromAlgebraic == from && m.toAlgebraic == to);
      if (isPseudoLegal) {
        _manualMove(from, to, piece.color, promotionPiece: promotion);
      }
    }

    return _game.fen != fenBefore;
  }

  /// Handle king capture — manually removes king, moves attacker.
  /// Returns true on success, false if the move geometry is invalid.
  bool handleKingCapture(String from, String to) {
    final attacker = _game.get(from);
    if (attacker == null) return false;

    _game.remove(from);
    _game.remove(to);
    _game.put(attacker, to);
    _controller!.loadFen(_game.fen);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Cost
  // ---------------------------------------------------------------------------

  /// Step cost for moving [piece] from [from] to [to].
  int moveCost(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    return costCalculator.calculate(piece, from, to,
        capturingKing: capturingKing);
  }

  // ---------------------------------------------------------------------------
  // Check detection
  // ---------------------------------------------------------------------------

  /// Returns the side that is in check, or null if neither.
  PieceColor? checkedSide() {
    if (_controller == null) return null;
    final parts = _game.fen.split(' ');
    final placement = parts[0];

    // If a king was captured, the FEN won't have 'K' or 'k'.
    // Calling in_check on such a position causes an index-out-of-range crash
    // because the chess engine tries to look up a king square that doesn't exist.
    if (!placement.contains('K') || !placement.contains('k')) return null;

    parts[1] = 'w';
    final testWhite = chess.Chess.fromFEN(parts.join(' '));
    if (testWhite.in_check) return PieceColor.white;

    parts[1] = 'b';
    final testBlack = chess.Chess.fromFEN(parts.join(' '));
    if (testBlack.in_check) return PieceColor.black;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Game lifecycle
  // ---------------------------------------------------------------------------

  void startNewGame() {
    _controller?.resetBoard();
  }

  void loadPosition(String fen) {
    _controller?.loadFen(fen);
  }

  /// The last SAN move from the engine's move list (for move history).
  String? get lastSanMove {
    final moves = _game.san_moves();
    if (moves.isEmpty) return null;
    return moves.last;
  }

  // ---------------------------------------------------------------------------
  // Promotion detection
  // ---------------------------------------------------------------------------

  /// Whether a move from [from] to [to] is a pawn promotion.
  bool isPromotion(String from, String to) {
    final piece = _game.get(from);
    if (piece == null || piece.type != chess.PieceType.PAWN) return false;
    if (piece.color == chess.Color.WHITE) {
      return from[1] == '7' && to[1] == '8';
    } else {
      return from[1] == '2' && to[1] == '1';
    }
  }

  // ---------------------------------------------------------------------------
  // Type conversions (chess package ↔ our types)
  // ---------------------------------------------------------------------------

  static PieceKind _fromChessPieceType(chess.PieceType t) {
    if (t == chess.PieceType.PAWN) return PieceKind.pawn;
    if (t == chess.PieceType.KNIGHT) return PieceKind.knight;
    if (t == chess.PieceType.BISHOP) return PieceKind.bishop;
    if (t == chess.PieceType.ROOK) return PieceKind.rook;
    if (t == chess.PieceType.QUEEN) return PieceKind.queen;
    if (t == chess.PieceType.KING) return PieceKind.king;
    return PieceKind.pawn;
  }

  static PieceColor _fromChessColor(chess.Color c) {
    return c == chess.Color.WHITE ? PieceColor.white : PieceColor.black;
  }

  static chess.PieceType _toChessPieceType(PieceKind kind) {
    switch (kind) {
      case PieceKind.pawn: return chess.PieceType.PAWN;
      case PieceKind.knight: return chess.PieceType.KNIGHT;
      case PieceKind.bishop: return chess.PieceType.BISHOP;
      case PieceKind.rook: return chess.PieceType.ROOK;
      case PieceKind.queen: return chess.PieceType.QUEEN;
      case PieceKind.king: return chess.PieceType.KING;
    }
  }

  /// Convert a PieceKind to its uppercase character (e.g. PieceKind.knight → 'N').
  static String pieceKindToChar(PieceKind kind) {
    switch (kind) {
      case PieceKind.pawn: return 'P';
      case PieceKind.knight: return 'N';
      case PieceKind.bishop: return 'B';
      case PieceKind.rook: return 'R';
      case PieceKind.queen: return 'Q';
      case PieceKind.king: return 'K';
    }
  }

  /// Convert a single uppercase char to PieceKind.
  static PieceKind charToPieceKind(String c) {
    switch (c.toUpperCase()) {
      case 'P': return PieceKind.pawn;
      case 'N': return PieceKind.knight;
      case 'B': return PieceKind.bishop;
      case 'R': return PieceKind.rook;
      case 'Q': return PieceKind.queen;
      case 'K': return PieceKind.king;
      default: return PieceKind.pawn;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Build a FEN with [color] as the active side and en passant cleared.
  static String _fenForColor(chess.Chess game, chess.Color color) {
    final parts = game.fen.split(' ');
    parts[1] = color == chess.Color.WHITE ? 'w' : 'b';
    parts[3] = '-'; // clear en passant — no turn order in StepUp
    return parts.join(' ');
  }

  /// Check if a move from [from] to [to] is geometrically valid for king capture.
  bool _isValidKingCaptureMove(
      String from, String to, chess.Color attackerColor) {
    final targetPiece = _game.get(to);
    if (targetPiece == null) return false;

    // Replace king with a pawn so the engine allows capturing it
    final testGame = chess.Chess.fromFEN(_game.fen);
    testGame.remove(to);
    testGame.put(chess.Piece(chess.PieceType.PAWN, targetPiece.color), to);

    final testGame2 =
        chess.Chess.fromFEN(_fenForColor(testGame, attackerColor));
    final moves = testGame2.generate_moves({'legal': false});
    return moves.any((m) => m.fromAlgebraic == from && m.toAlgebraic == to);
  }

  /// Manually move a piece when the engine rejects the move (e.g. due to check).
  void _manualMove(
    String from,
    String to,
    chess.Color pieceColor, {
    String? promotionPiece,
  }) {
    final piece = _game.get(from);
    if (piece == null) return;

    _game.remove(from);
    _game.remove(to);

    if (promotionPiece != null) {
      final promotedType = _toChessPieceType(charToPieceKind(promotionPiece));
      _game.put(chess.Piece(promotedType, pieceColor), to);
    } else {
      _game.put(piece, to);
    }

    _controller!.loadFen(_game.fen);
  }
}
