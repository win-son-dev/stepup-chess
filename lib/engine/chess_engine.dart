import 'package:stepup_chess/engine/piece.dart';

/// Abstract base class for chess rule implementations.
///
/// Concrete engines (e.g. [DefaultChessEngine], a future KhmerChessEngine)
/// extend this class and supply the move generation, validation, and
/// board-state logic for their specific rule variant. [StepUpEngine] depends
/// only on [ChessEngine], making variants swappable without touching any other
/// code.
///
/// Shared stateless utilities ([pieceKindToChar], [charToPieceKind]) live here
/// so every subclass and caller can reach them without extra imports.
abstract class ChessEngine {
  // ---------------------------------------------------------------------------
  // Board state — subclasses must implement
  // ---------------------------------------------------------------------------

  /// Current board position as a FEN string.
  String get fen;

  /// Load a position from a FEN string.
  void loadFen(String fen);

  /// The piece at [square], or null if the square is empty.
  BoardPiece? pieceAt(String square);

  // ---------------------------------------------------------------------------
  // Move generation — subclasses must implement
  // ---------------------------------------------------------------------------

  /// All squares a piece on [from] can legally move to.
  ///
  /// Implementations must include enemy king squares to support the custom
  /// king-capture mechanic.
  Set<String> legalTargets(String from);

  // ---------------------------------------------------------------------------
  // Move execution — subclasses must implement
  // ---------------------------------------------------------------------------

  /// Attempt to make a move. Returns `true` if the board position changed.
  bool makeMove(String from, String to, {String? promotion});

  /// Directly capture the king: remove both pieces, place the attacker on
  /// [to]. Returns `true` on success.
  bool handleKingCapture(String from, String to);

  // ---------------------------------------------------------------------------
  // Game rules — subclasses must implement
  // ---------------------------------------------------------------------------

  /// Whether moving a pawn from [from] to [to] triggers promotion.
  bool isPromotion(String from, String to);

  /// The side currently in check, or `null` if neither side is.
  PieceColor? checkedSide();

  // ---------------------------------------------------------------------------
  // Move history — subclasses must implement
  // ---------------------------------------------------------------------------

  /// The last move in SAN notation, or `null` if no moves have been made.
  String? get lastSanMove;

  // ---------------------------------------------------------------------------
  // Lifecycle — subclasses must implement
  // ---------------------------------------------------------------------------

  /// Reset the board to the starting position.
  void reset();

  // ---------------------------------------------------------------------------
  // Shared utilities — inherited by all subclasses, no override needed
  // ---------------------------------------------------------------------------

  /// Convert a [PieceKind] to its uppercase FEN character (e.g. knight → 'N').
  static String pieceKindToChar(PieceKind kind) {
    switch (kind) {
      case PieceKind.pawn:
        return 'P';
      case PieceKind.knight:
        return 'N';
      case PieceKind.bishop:
        return 'B';
      case PieceKind.rook:
        return 'R';
      case PieceKind.queen:
        return 'Q';
      case PieceKind.king:
        return 'K';
    }
  }

  /// Convert a FEN piece character to [PieceKind]. Case-insensitive.
  /// Unknown characters default to [PieceKind.pawn].
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
