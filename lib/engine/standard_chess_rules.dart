import 'package:chess/chess.dart' as chess;
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/engine/rule_engine.dart';

const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

/// Standard FIDE chess rules, implemented on top of the `chess` package.
///
/// This class owns all `chess`-package-specific logic — move generation,
/// check detection, FEN manipulation, and type conversions — keeping the rest
/// of the codebase free of that dependency.
class StandardChessRules implements RuleEngine {
  chess.Chess _game = chess.Chess();

  // ---------------------------------------------------------------------------
  // Board state
  // ---------------------------------------------------------------------------

  @override
  String get fen => _game.fen;

  @override
  void loadFen(String fen) {
    _game = chess.Chess.fromFEN(fen);
  }

  @override
  BoardPiece? pieceAt(String square) {
    final p = _game.get(square);
    if (p == null) return null;
    return BoardPiece(_fromChessPieceType(p.type), _fromChessColor(p.color));
  }

  // ---------------------------------------------------------------------------
  // Move generation
  // ---------------------------------------------------------------------------

  @override
  Set<String> legalTargets(String from) {
    final piece = _game.get(from);
    if (piece == null) return {};

    final pieceColor = piece.color;
    final testGame = chess.Chess.fromFEN(_fenForColor(_game, pieceColor));
    final moves = testGame.generate_moves({'legal': false});

    final targets = <String>{};
    for (final m in moves) {
      if (m.fromAlgebraic == from) targets.add(m.toAlgebraic);
    }

    // Include enemy king squares (custom king-capture mechanic).
    for (final file in _files) {
      for (var rank = 1; rank <= 8; rank++) {
        final sq = '$file$rank';
        final p = _game.get(sq);
        if (p != null &&
            p.type == chess.PieceType.KING &&
            p.color != pieceColor &&
            _isValidKingCaptureMove(from, sq, pieceColor)) {
          targets.add(sq);
        }
      }
    }

    return targets;
  }

  // ---------------------------------------------------------------------------
  // Move execution
  // ---------------------------------------------------------------------------

  @override
  bool makeMove(String from, String to, {String? promotion}) {
    final piece = _game.get(from);
    if (piece == null) return false;

    final readyFen = _fenForColor(_game, piece.color);
    _game = chess.Chess.fromFEN(readyFen);
    final fenBefore = _game.fen;

    if (promotion != null) {
      _game.move({'from': from, 'to': to, 'promotion': promotion});
    } else {
      _game.move({'from': from, 'to': to});
    }

    // Engine rejected the move (e.g. exposes own king to check) — try a
    // pseudo-legal fallback so StepUp's free-play mechanic still works.
    if (_game.fen == fenBefore) {
      final testGame = chess.Chess.fromFEN(readyFen);
      final pseudoMoves = testGame.generate_moves({'legal': false});
      final isPseudoLegal =
          pseudoMoves.any((m) => m.fromAlgebraic == from && m.toAlgebraic == to);
      if (isPseudoLegal) {
        _manualMove(from, to, piece.color, promotionPiece: promotion);
      }
    }

    return _game.fen != fenBefore;
  }

  @override
  bool handleKingCapture(String from, String to) {
    final attacker = _game.get(from);
    if (attacker == null) return false;

    _game.remove(from);
    _game.remove(to);
    _game.put(attacker, to);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Promotion
  // ---------------------------------------------------------------------------

  @override
  bool isPromotion(String from, String to) {
    final piece = _game.get(from);
    if (piece == null || piece.type != chess.PieceType.PAWN) return false;
    return piece.color == chess.Color.WHITE
        ? from[1] == '7' && to[1] == '8'
        : from[1] == '2' && to[1] == '1';
  }

  // ---------------------------------------------------------------------------
  // Check detection
  // ---------------------------------------------------------------------------

  @override
  PieceColor? checkedSide() {
    final parts = _game.fen.split(' ');
    final placement = parts[0];

    // Guard: if a king was captured the FEN won't have 'K' or 'k'.
    // Calling in_check on such a position crashes the chess engine.
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
  // Move history
  // ---------------------------------------------------------------------------

  @override
  String? get lastSanMove {
    final moves = _game.san_moves();
    return moves.isEmpty ? null : moves.last;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void reset() {
    _game = chess.Chess();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Returns a copy of the FEN with [color] as the active side and en passant
  /// cleared (no turn order in StepUp).
  static String _fenForColor(chess.Chess game, chess.Color color) {
    final parts = game.fen.split(' ');
    parts[1] = color == chess.Color.WHITE ? 'w' : 'b';
    parts[3] = '-';
    return parts.join(' ');
  }

  /// Returns true if the move geometry allows [from] to capture the king at
  /// [to] — checked by temporarily replacing the king with a pawn.
  bool _isValidKingCaptureMove(
      String from, String to, chess.Color attackerColor) {
    final targetPiece = _game.get(to);
    if (targetPiece == null) return false;

    final testGame = chess.Chess.fromFEN(_game.fen);
    testGame.remove(to);
    testGame.put(chess.Piece(chess.PieceType.PAWN, targetPiece.color), to);

    final testGame2 = chess.Chess.fromFEN(_fenForColor(testGame, attackerColor));
    final moves = testGame2.generate_moves({'legal': false});
    return moves.any((m) => m.fromAlgebraic == from && m.toAlgebraic == to);
  }

  /// Directly manipulate the board for pseudo-legal moves the engine rejects.
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
  }

  // ---------------------------------------------------------------------------
  // Type conversions (chess package ↔ app types)
  // ---------------------------------------------------------------------------

  static PieceKind _fromChessPieceType(chess.PieceType t) {
    if (t == chess.PieceType.PAWN) return PieceKind.pawn;
    if (t == chess.PieceType.KNIGHT) return PieceKind.knight;
    if (t == chess.PieceType.BISHOP) return PieceKind.bishop;
    if (t == chess.PieceType.ROOK) return PieceKind.rook;
    if (t == chess.PieceType.QUEEN) return PieceKind.queen;
    return PieceKind.king;
  }

  static PieceColor _fromChessColor(chess.Color c) =>
      c == chess.Color.WHITE ? PieceColor.white : PieceColor.black;

  static chess.PieceType _toChessPieceType(PieceKind kind) {
    switch (kind) {
      case PieceKind.pawn:
        return chess.PieceType.PAWN;
      case PieceKind.knight:
        return chess.PieceType.KNIGHT;
      case PieceKind.bishop:
        return chess.PieceType.BISHOP;
      case PieceKind.rook:
        return chess.PieceType.ROOK;
      case PieceKind.queen:
        return chess.PieceType.QUEEN;
      case PieceKind.king:
        return chess.PieceType.KING;
    }
  }

  static PieceKind charToPieceKind(String c) {
    switch (c.toUpperCase()) {
      case 'P':
        return PieceKind.pawn;
      case 'N':
        return PieceKind.knight;
      case 'B':
        return PieceKind.bishop;
      case 'R':
        return PieceKind.rook;
      case 'Q':
        return PieceKind.queen;
      case 'K':
        return PieceKind.king;
      default:
        return PieceKind.pawn;
    }
  }
}