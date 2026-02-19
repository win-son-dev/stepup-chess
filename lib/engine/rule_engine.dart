import 'package:stepup_chess/engine/piece.dart';

/// Abstract interface for chess rule implementations.
///
/// Concrete implementations (e.g. [StandardChessRules], a future KhmerChessRules)
/// provide the move generation, validation, and board-state logic for a
/// specific rule variant. [StepUpEngine] depends only on this interface, making
/// rule variants swappable via [RuleEngineFactory].
abstract class RuleEngine {
  /// Current board position as a FEN string.
  String get fen;

  /// Load a position from a FEN string.
  void loadFen(String fen);

  /// The piece at [square], or null if the square is empty.
  BoardPiece? pieceAt(String square);

  /// All squares a piece on [from] can move to (pseudo-legal — no check
  /// enforcement). Must include enemy king squares for the custom
  /// king-capture mechanic.
  Set<String> legalTargets(String from);

  /// Attempt to make a move. Returns true if the board position changed.
  bool makeMove(String from, String to, {String? promotion});

  /// Directly capture the king: remove both pieces and place the attacker on
  /// [to]. Returns true on success.
  bool handleKingCapture(String from, String to);

  /// Whether moving a pawn from [from] to [to] triggers promotion.
  bool isPromotion(String from, String to);

  /// The side currently in check, or null if neither side is in check.
  PieceColor? checkedSide();

  /// The last move in SAN notation, or null if no moves have been made.
  String? get lastSanMove;

  /// Reset the board to the starting position.
  void reset();
}