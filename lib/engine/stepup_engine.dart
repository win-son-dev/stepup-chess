import 'package:flutter_chess_board/flutter_chess_board.dart' hide BoardPiece;
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/engine/cost_calculator.dart';
import 'package:stepup_chess/engine/rule_engine.dart';

/// Central chess engine for StepUp Chess.
///
/// Orchestrates a [RuleEngine] (pure move/board logic) and a
/// [ChessBoardController] (UI binding), keeping them in sync after every move.
/// Step-cost calculation is delegated to the injected [CostCalculator].
///
/// Swapping rule variants (e.g. Khmer chess) only requires passing a different
/// [RuleEngine] — no other code needs to change.
class StepUpEngine {
  final RuleEngine _rules;
  ChessBoardController? _controller;
  CostCalculator costCalculator;

  StepUpEngine(this._rules, this.costCalculator);

  // ---------------------------------------------------------------------------
  // Controller binding
  // ---------------------------------------------------------------------------

  void attachController(ChessBoardController controller) {
    _controller = controller;
  }

  ChessBoardController get controller => _controller!;

  // ---------------------------------------------------------------------------
  // Board state
  // ---------------------------------------------------------------------------

  String get fen => _rules.fen;

  BoardPiece? pieceAt(String square) => _rules.pieceAt(square);

  // ---------------------------------------------------------------------------
  // Move generation
  // ---------------------------------------------------------------------------

  Set<String> legalTargets(String from) => _rules.legalTargets(from);

  // ---------------------------------------------------------------------------
  // Move execution
  // ---------------------------------------------------------------------------

  /// Try to make a move. Returns true if the board position changed.
  bool makeMove(String from, String to, {String? promotion}) {
    final moved = _rules.makeMove(from, to, promotion: promotion);
    if (moved) _controller?.loadFen(_rules.fen);
    return moved;
  }

  /// Handle king capture — removes king, places attacker, syncs the UI.
  bool handleKingCapture(String from, String to) {
    final success = _rules.handleKingCapture(from, to);
    if (success) _controller?.loadFen(_rules.fen);
    return success;
  }

  // ---------------------------------------------------------------------------
  // Cost
  // ---------------------------------------------------------------------------

  int moveCost(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    return costCalculator.calculate(piece, from, to,
        capturingKing: capturingKing);
  }

  // ---------------------------------------------------------------------------
  // Check detection
  // ---------------------------------------------------------------------------

  PieceColor? checkedSide() => _rules.checkedSide();

  // ---------------------------------------------------------------------------
  // Game lifecycle
  // ---------------------------------------------------------------------------

  void startNewGame() {
    _rules.reset();
    _controller?.resetBoard();
  }

  /// Load [fen] into both the rule engine and the board controller.
  void loadPosition(String fen) {
    _rules.loadFen(fen);
    _controller?.loadFen(fen);
  }

  // ---------------------------------------------------------------------------
  // Move history
  // ---------------------------------------------------------------------------

  String? get lastSanMove => _rules.lastSanMove;

  // ---------------------------------------------------------------------------
  // Promotion detection
  // ---------------------------------------------------------------------------

  bool isPromotion(String from, String to) => _rules.isPromotion(from, to);

  // ---------------------------------------------------------------------------
  // Static utilities
  // ---------------------------------------------------------------------------

  /// Convert a [PieceKind] to its uppercase character (e.g. knight → 'N').
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
}
