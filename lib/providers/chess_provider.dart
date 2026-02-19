import 'package:chess/chess.dart' as chess;
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepup_chess/config/constants.dart';
import 'package:stepup_chess/config/service_locator.dart';
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/engine/cost_calculator.dart';
import 'package:stepup_chess/engine/rule_engine_factory.dart';
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
    engine = StepUpEngine(
      getIt<RuleEngineFactory>().create(RuleVariant.standard),
      _buildCalculator(gameState.costMode, gameState.preset),
    );
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
        fenHistory: [chess.Chess.DEFAULT_POSITION],
        historyIndex: 0,
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
    final fenHistory =
        _prefs.getStringList(gameFenHistoryKey) ?? [chess.Chess.DEFAULT_POSITION, fen];

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
      fenHistory: fenHistory,
      historyIndex: fenHistory.length - 1,
    );
  }

  void _persistGame() {
    _prefs.setString(gameFenKey, state.fen);
    _prefs.setString(gamePresetNameKey, state.preset.name);
    _prefs.setString(gameCostModeKey, state.costMode.name);
    _prefs.setString(gameStatusKey, state.status.name);
    _prefs.setStringList(gameMoveHistoryKey, state.moveHistory);
    _prefs.setStringList(gameFenHistoryKey, state.fenHistory);
  }

  void _clearPersistedGame() {
    _prefs.remove(gameFenKey);
    _prefs.remove(gamePresetNameKey);
    _prefs.remove(gameCostModeKey);
    _prefs.remove(gameStatusKey);
    _prefs.remove(gameMoveHistoryKey);
    _prefs.remove(gameFenHistoryKey);
  }

  void attachBoardController(ChessBoardController controller) {
    engine.attachController(controller);
    engine.loadPosition(state.fen);
  }

  void startNewGame(StepCostPreset preset,
      {CostMode costMode = CostMode.distance,
      RuleVariant variant = RuleVariant.standard}) {
    engine = StepUpEngine(
      getIt<RuleEngineFactory>().create(variant),
      _buildCalculator(costMode, preset),
    );
    engine.startNewGame();
    final initialFen = chess.Chess.DEFAULT_POSITION;
    state = GameState(
      fen: initialFen,
      preset: preset,
      costMode: costMode,
      status: GameStatus.active,
      moveHistory: [],
      fenHistory: [initialFen],
      historyIndex: 0,
    );
    _persistGame();
  }

  void clearGame() {
    _clearPersistedGame();
    state = GameState(
      fen: chess.Chess.DEFAULT_POSITION,
      preset: state.preset,
      status: GameStatus.notStarted,
      fenHistory: [chess.Chess.DEFAULT_POSITION],
      historyIndex: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // History navigation
  // ---------------------------------------------------------------------------

  void stepBack() {
    if (state.historyIndex <= 0) return;
    final newIndex = state.historyIndex - 1;
    final newFen = state.fenHistory[newIndex];
    engine.loadPosition(newFen);
    state = state.copyWith(fen: newFen, historyIndex: newIndex);
  }

  void stepForward() {
    if (state.historyIndex >= state.fenHistory.length - 1) return;
    final newIndex = state.historyIndex + 1;
    final newFen = state.fenHistory[newIndex];
    engine.loadPosition(newFen);
    state = state.copyWith(fen: newFen, historyIndex: newIndex);
  }

  // ---------------------------------------------------------------------------
  // Cost helpers
  // ---------------------------------------------------------------------------

  int moveCost(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    return engine.moveCost(piece, from, to, capturingKing: capturingKing);
  }

  PieceColor? getCheckedSide() => engine.checkedSide();

  bool canAffordMove(PieceKind piece, String from, String to) {
    final cost = engine.moveCost(piece, from, to);
    return _stepService.canAfford(cost);
  }

  // ---------------------------------------------------------------------------
  // Move execution
  // ---------------------------------------------------------------------------

  void chargeAndRecordMove(PieceKind piece, String from, String to) {
    final cost = engine.moveCost(piece, from, to);
    _stepService.spendSteps(cost);

    final lastSan = engine.lastSanMove ?? '';
    final newFen = engine.fen;
    final newFenHistory = [...state.fenHistory, newFen];

    state = state.copyWith(
      fen: newFen,
      moveHistory: [...state.moveHistory, lastSan],
      lastMove: LastMove(from, to),
      fenHistory: newFenHistory,
      historyIndex: newFenHistory.length - 1,
    );
    _persistGame();
  }

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

    final moveNotation = '${StepUpEngine.pieceKindToChar(attackerKind)}x$to#';
    final newFen = engine.fen;
    final newFenHistory = [...state.fenHistory, newFen];

    state = state.copyWith(
      fen: newFen,
      status: GameStatus.kingCaptured,
      moveHistory: [...state.moveHistory, moveNotation],
      lastMove: LastMove(from, to),
      fenHistory: newFenHistory,
      historyIndex: newFenHistory.length - 1,
    );
    _persistGame();

    return true;
  }

  // ---------------------------------------------------------------------------
  // Game outcomes
  // ---------------------------------------------------------------------------

  void resign() {
    state = state.copyWith(status: GameStatus.resigned);
    _clearPersistedGame();
  }

  void offerDraw() {
    state = state.copyWith(status: GameStatus.draw);
    _clearPersistedGame();
  }
}
