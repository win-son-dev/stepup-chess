import 'package:chess/chess.dart' as chess;
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stepup_chess/config/constants.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/models/step_cost_preset.dart';
import 'package:stepup_chess/services/step_tracker_service.dart';
import 'package:stepup_chess/providers/step_provider.dart';

final chessGameProvider =
    NotifierProvider<ChessGameNotifier, GameState>(ChessGameNotifier.new);

class ChessGameNotifier extends Notifier<GameState> {
  ChessBoardController? _boardController;

  StepTrackerService get _stepService => ref.read(stepTrackerServiceProvider);
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  chess.Chess get _game => _boardController!.game;

  @override
  GameState build() {
    return _loadPersistedGame();
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

    final preset = presets.firstWhere(
      (p) => p.name == presetName,
      orElse: () => presets.first,
    );

    return GameState(
      fen: fen,
      preset: preset,
      status: GameStatus.active,
      moveHistory: moveHistory,
    );
  }

  void _persistGame() {
    _prefs.setString(gameFenKey, state.fen);
    _prefs.setString(gamePresetNameKey, state.preset.name);
    _prefs.setString(gameStatusKey, state.status.name);
    _prefs.setStringList(gameMoveHistoryKey, state.moveHistory);
  }

  void _clearPersistedGame() {
    _prefs.remove(gameFenKey);
    _prefs.remove(gamePresetNameKey);
    _prefs.remove(gameStatusKey);
    _prefs.remove(gameMoveHistoryKey);
  }

  void attachBoardController(ChessBoardController controller) {
    _boardController = controller;
  }

  void startNewGame(StepCostPreset preset) {
    _boardController?.resetBoard();
    state = GameState(
      fen: chess.Chess.DEFAULT_POSITION,
      preset: preset,
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

  /// Get cost for a piece type. Double cost if capturing a king.
  int getCost(chess.PieceType pieceType, {bool capturingKing = false}) {
    final baseCost = state.preset.costFor(pieceType);
    return capturingKing ? baseCost * 2 : baseCost;
  }

  /// Check if either king is under attack (in check).
  /// Returns 'white', 'black', or null.
  String? getCheckedSide() {
    final fen = _game.fen;
    final parts = fen.split(' ');

    // in_check: true if the side to move is in check
    // To check if white is in check: set turn to white
    parts[1] = 'w';
    final testWhite = chess.Chess.fromFEN(parts.join(' '));
    if (testWhite.in_check) return 'white';

    parts[1] = 'b';
    final testBlack = chess.Chess.fromFEN(parts.join(' '));
    if (testBlack.in_check) return 'black';

    return null;
  }

  /// Check if a move can be afforded BEFORE making it.
  bool canAffordMove(chess.PieceType pieceType) {
    final cost = getCost(pieceType);
    return _stepService.canAfford(cost);
  }

  /// Charge steps and record the move AFTER it has been made on the board.
  void chargeAndRecordMove(chess.PieceType pieceType) {
    final cost = getCost(pieceType);
    _stepService.spendSteps(cost);

    final sanMoves = _game.san_moves();
    final lastSan = sanMoves.isNotEmpty ? sanMoves.last ?? '' : '';

    state = state.copyWith(
      fen: _game.fen,
      moveHistory: [...state.moveHistory, lastSan],
    );
    _persistGame();
  }

  /// Handle king capture — called from the board widget when a piece
  /// is dropped on a king's square. The chess engine can't do this move,
  /// so we manually update the board.
  bool handleKingCapture({
    required String from,
    required String to,
    required chess.PieceType attackerType,
    required chess.Color capturedKingColor,
  }) {
    final cost = getCost(attackerType, capturingKing: true);

    if (!_stepService.canAfford(cost)) return false;

    _stepService.spendSteps(cost);

    // Manually update the board: remove king, move attacker
    final attacker = _game.get(from);
    _game.remove(from);
    _game.remove(to);
    if (attacker != null) {
      _game.put(attacker, to);
    }

    final moveNotation = '${attackerType.toUpperCase()}x$to#';

    state = state.copyWith(
      fen: _game.fen,
      status: GameStatus.kingCaptured,
      moveHistory: [...state.moveHistory, moveNotation],
    );
    _persistGame();

    // Refresh the board display by loading the updated FEN
    _boardController?.loadFen(_game.fen);

    return true;
  }

  void resign() {
    state = state.copyWith(status: GameStatus.resigned);
    _clearPersistedGame();
  }
}
