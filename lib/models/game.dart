import 'package:stepup_chess/models/step_cost_preset.dart';

enum GameStatus { notStarted, active, kingCaptured, stalemate, draw, resigned }

enum CostMode { baseDistance, distance, fixed }

class GameState {
  final String fen;
  final StepCostPreset preset;
  final CostMode costMode;
  final GameStatus status;
  final List<String> moveHistory;

  const GameState({
    required this.fen,
    required this.preset,
    this.costMode = CostMode.distance,
    this.status = GameStatus.active,
    this.moveHistory = const [],
  });

  GameState copyWith({
    String? fen,
    StepCostPreset? preset,
    CostMode? costMode,
    GameStatus? status,
    List<String>? moveHistory,
  }) {
    return GameState(
      fen: fen ?? this.fen,
      preset: preset ?? this.preset,
      costMode: costMode ?? this.costMode,
      status: status ?? this.status,
      moveHistory: moveHistory ?? this.moveHistory,
    );
  }
}
