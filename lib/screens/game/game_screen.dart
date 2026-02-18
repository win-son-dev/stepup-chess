import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stepup_chess/engine/piece.dart';
import 'package:stepup_chess/providers/chess_provider.dart';
import 'package:stepup_chess/providers/step_provider.dart';
import 'package:stepup_chess/models/game.dart';
import 'package:stepup_chess/widgets/step_counter_display.dart';
import 'package:stepup_chess/widgets/move_history_panel.dart';
import 'package:stepup_chess/widgets/stepup_chess_board.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ChessBoardController _boardController;

  @override
  void initState() {
    super.initState();
    _boardController = ChessBoardController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(chessGameProvider.notifier);
      notifier.attachBoardController(_boardController);
      // Restore board position if resuming a game
      final gameState = ref.read(chessGameProvider);
      if (gameState.fen != chess.Chess.DEFAULT_POSITION) {
        _boardController.loadFen(gameState.fen);
      }
    });
  }

  bool _canAfford(PieceKind piece, String from, String to) {
    final notifier = ref.read(chessGameProvider.notifier);
    final affordable = notifier.canAffordMove(piece, from, to);
    if (!affordable) {
      _showCantAffordSnackbar();
    }
    return affordable;
  }

  void _onChargeMove(PieceKind piece, String from, String to) {
    final notifier = ref.read(chessGameProvider.notifier);
    notifier.chargeAndRecordMove(piece, from, to);
  }

  int _getCost(PieceKind piece, String from, String to,
      {bool capturingKing = false}) {
    final notifier = ref.read(chessGameProvider.notifier);
    return notifier.moveCost(piece, from, to, capturingKing: capturingKing);
  }

  void _onMove() {}

  bool _onKingCapture({
    required String from,
    required String to,
    required PieceKind attackerKind,
    required PieceColor capturedKingColor,
  }) {
    final notifier = ref.read(chessGameProvider.notifier);
    final success = notifier.handleKingCapture(
      from: from,
      to: to,
      attackerKind: attackerKind,
      capturedKingColor: capturedKingColor,
    );

    if (!success) {
      _showCantAffordSnackbar(isKingCapture: true);
      return false;
    }

    // Show game over
    final winner =
        capturedKingColor == PieceColor.white ? 'Black' : 'White';
    _showGameEndDialog(GameStatus.kingCaptured, winner: winner);
    return true;
  }

  void _showCantAffordSnackbar({bool isKingCapture = false}) {
    final msg = isKingCapture
        ? 'Not enough steps for king capture!'
        : 'Not enough steps! Keep walking to earn more.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showGameEndDialog(GameStatus status, {String? winner}) {
    String title;
    String message;

    switch (status) {
      case GameStatus.kingCaptured:
        title = 'King Captured!';
        message = '${winner ?? "Someone"} wins by capturing the king!';
        break;
      case GameStatus.resigned:
        title = 'Resigned';
        message = 'Game over by resignation.';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(chessGameProvider.notifier).clearGame();
              context.go('/');
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  void _onResign() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(chessGameProvider.notifier).resign();
              _showGameEndDialog(GameStatus.resigned);
            },
            child: const Text('Resign', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _costModeLabel(CostMode mode) {
    return switch (mode) {
      CostMode.baseDistance => 'Base+Dist',
      CostMode.distance => 'Distance',
      CostMode.fixed => 'Fixed',
    };
  }

  void _addTestSteps() {
    ref.read(stepTrackerServiceProvider).addSteps(100);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(chessGameProvider);
    final notifier = ref.read(chessGameProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('StepUp Chess'),
            Text(
              '${gameState.preset.name} \u2022 ${_costModeLabel(gameState.costMode)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add 100 test steps',
            onPressed: _addTestSteps,
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Resign',
            onPressed: gameState.status == GameStatus.active ? _onResign : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step counter
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StepCounterDisplay(fontSize: 24),
            ),

            // Chess board
            Expanded(
              child: Center(
                child: StepUpChessBoard(
                  engine: notifier.engine,
                  controller: _boardController,
                  boardColor: BoardColor.green,
                  enableUserMoves: gameState.status == GameStatus.active,
                  canAfford: _canAfford,
                  onChargeMove: _onChargeMove,
                  getCost: _getCost,
                  onMove: _onMove,
                  onKingCapture: _onKingCapture,
                ),
              ),
            ),

            // Move history
            MoveHistoryPanel(moves: gameState.moveHistory),
          ],
        ),
      ),
    );
  }
}
