import 'package:stepup_chess/models/step_cost_preset.dart';

enum GameStatus { active, kingCaptured, stalemate, draw, resigned }

class GameState {
  final String fen;
  final StepCostPreset preset;
  final GameStatus status;
  final List<String> moveHistory;

  const GameState({
    required this.fen,
    required this.preset,
    this.status = GameStatus.active,
    this.moveHistory = const [],
  });

  GameState copyWith({
    String? fen,
    StepCostPreset? preset,
    GameStatus? status,
    List<String>? moveHistory,
  }) {
    return GameState(
      fen: fen ?? this.fen,
      preset: preset ?? this.preset,
      status: status ?? this.status,
      moveHistory: moveHistory ?? this.moveHistory,
    );
  }
}
