import 'package:chess/chess.dart' as chess;
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepup_chess/config/constants.dart';
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/engine/cost_calculator.dart';
import 'package:stepup_chess/engine/stepup_engine.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/models/step_cost_preset.dart';
import 'package:stepup_chess/services/step_tracker_service.dart';
import 'package:stepup_chess/providers/step_provider.dart';

final chessGameProvider =
    NotifierProvider<ChessGameNotifier, GameState>(ChessGameNotifier.new);

class ChessGameNotifier extends Notifier<GameState> {
  late StepUpEngine engine;

  StepTrackerService get _stepService => ref.read(stepTrackerServiceProvider);
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  GameState build() {
    final gameState = _loadPersistedGame();
    engine = StepUpEngine(_buildCalculator(gameState.costMode, gameState.preset));
    return gameState;
  }

  static CostCalculator _buildCalculator(CostMode mode, StepCostPreset preset) {
    switch (mode) {
      case CostMode.baseDistance:
        return BaseDistanceCostCalculator(preset);
      case CostMode.distance:
        return DistanceCostCalculator(preset);
      case CostMode.fixed:
        return FixedCostCalculator(preset);
    }
  }

  GameState _loadPersistedGame() {
    final savedStatus = _prefs.getString(gameStatusKey);
    if (savedStatus == null || savedStatus != 'active') {
      return GameState(
        fen: chess.Chess.DEFAULT_POSITION,
        preset: const StepCostPreset(
          name: 'Quick',
          pawn: 2,
          knight: 5,
          bishop: 5,
          rook: 7,
          queen: 10,
          king: 3,
        ),
        status: GameStatus.notStarted,
      );
    }

    final fen = _prefs.getString(gameFenKey) ?? chess.Chess.DEFAULT_POSITION;
    final presetName = _prefs.getString(gamePresetNameKey) ?? 'Quick';
    final moveHistory = _prefs.getStringList(gameMoveHistoryKey) ?? [];
    final costModeName = _prefs.getString(gameCostModeKey) ?? 'distance';
    final costMode = CostMode.values.firstWhere(
      (m) => m.name == costModeName,
      orElse: () => CostMode.distance,
    );

    final preset = presets.firstWhere(
      (p) => p.name == presetName,
      orElse: () => presets.first,
    );

    return GameState(
      fen: fen,
      preset: preset,
      costMode: costMode,
      status: GameStatus.active,
      moveHistory: moveHistory,
    );
  }

  void _persistGame() {
    _prefs.setString(gameFenKey, state.fen);
    _prefs.setString(gamePresetNameKey, state.preset.name);
    _prefs.setString(gameCostModeKey, state.costMode.name);
    _prefs.setString(gameStatusKey, state.status.name);
    _prefs.setStringList(gameMoveHistoryKey, state.moveHistory);
  }

  void _clearPersistedGame() {
    _prefs.remove(gameFenKey);
    _prefs.remove(gamePresetNameKey);
    _prefs.remove(gameCostModeKey);
    _prefs.remove(gameStatusKey);
    _prefs.remove(gameMoveHistoryKey);
  }

  void attachBoardController(ChessBoardController controller) {
    engine.attachController(controller);
  }

  void startNewGame(StepCostPreset preset, {CostMode costMode = CostMode.distance}) {
    engine.costCalculator = _buildCalculator(costMode, preset);
    engine.startNewGame();
    state = GameState(
      fen: chess.Chess.DEFAULT_POSITION,
      preset: preset,
      costMode: costMode,
      status: GameStatus.active,
      moveHistory: [],
    );
    _persistGame();
  }

  void clearGame() {
    _clearPersistedGame();
    state = GameState(
      fen: chess.Chess.DEFAULT_POSITION,
      preset: state.preset,
      status: GameStatus.notStarted,
    );
  }

  /// Step cost for moving [piece] from [from] to [to].
  int moveCost(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    return engine.moveCost(piece, from, to, capturingKing: capturingKing);
  }

  /// Check if either king is under attack (in check).
  PieceColor? getCheckedSide() {
    return engine.checkedSide();
  }

  /// Check if a move can be afforded.
  bool canAffordMove(PieceKind piece, String from, String to) {
    final cost = engine.moveCost(piece, from, to);
    return _stepService.canAfford(cost);
  }

  /// Charge steps and record the move AFTER it has been made on the board.
  void chargeAndRecordMove(PieceKind piece, String from, String to) {
    final cost = engine.moveCost(piece, from, to);
    _stepService.spendSteps(cost);

    final lastSan = engine.lastSanMove ?? '';

    state = state.copyWith(
      fen: engine.fen,
      moveHistory: [...state.moveHistory, lastSan],
    );
    _persistGame();
  }

  /// Handle king capture — called from the board widget when a piece
  /// is dropped on a king's square.
  bool handleKingCapture({
    required String from,
    required String to,
    required PieceKind attackerKind,
    required PieceColor capturedKingColor,
  }) {
    final cost = engine.moveCost(attackerKind, from, to, capturingKing: true);

    if (!_stepService.canAfford(cost)) return false;

    _stepService.spendSteps(cost);

    engine.handleKingCapture(from, to);

    final moveNotation =
        '${StepUpEngine.pieceKindToChar(attackerKind)}x$to#';

    state = state.copyWith(
      fen: engine.fen,
      status: GameStatus.kingCaptured,
      moveHistory: [...state.moveHistory, moveNotation],
    );
    _persistGame();

    return true;
  }

  void resign() {
    state = state.copyWith(status: GameStatus.resigned);
    _clearPersistedGame();
  }
}
