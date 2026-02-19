import 'package:stepup_chess/models/step_cost_preset.dart';

enum GameStatus { notStarted, active, kingCaptured, stalemate, draw, resigned }

enum CostMode { baseDistance, distance, fixed }

/// The squares involved in the most recent move, used for board highlighting.
class LastMove {
  final String from;
  final String to;

  const LastMove(this.from, this.to);
}

class GameState {
  final String fen;
  final StepCostPreset preset;
  final CostMode costMode;
  final GameStatus status;
  final List<String> moveHistory;
  final LastMove? lastMove;

  /// Ordered list of FENs: index 0 = initial position, each subsequent entry
  /// is the position after that move was made.
  final List<String> fenHistory;

  /// Index into [fenHistory] currently displayed on the board.
  /// Normally equals `fenHistory.length - 1` (latest position).
  final int historyIndex;

  /// True when the player is browsing history (not at the latest position).
  bool get isReviewing =>
      fenHistory.isNotEmpty && historyIndex < fenHistory.length - 1;

  const GameState({
    required this.fen,
    required this.preset,
    this.costMode = CostMode.distance,
    this.status = GameStatus.active,
    this.moveHistory = const [],
    this.lastMove,
    this.fenHistory = const [],
    this.historyIndex = 0,
  });

  GameState copyWith({
    String? fen,
    StepCostPreset? preset,
    CostMode? costMode,
    GameStatus? status,
    List<String>? moveHistory,
    LastMove? lastMove,
    List<String>? fenHistory,
    int? historyIndex,
  }) {
    return GameState(
      fen: fen ?? this.fen,
      preset: preset ?? this.preset,
      costMode: costMode ?? this.costMode,
      status: status ?? this.status,
      moveHistory: moveHistory ?? this.moveHistory,
      lastMove: lastMove ?? this.lastMove,
      fenHistory: fenHistory ?? this.fenHistory,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }
}
